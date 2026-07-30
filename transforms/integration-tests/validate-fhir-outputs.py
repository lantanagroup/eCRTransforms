#!/usr/bin/env python3
"""
validate-fhir-outputs.py — layer 3a of the eCRTransforms testing suite.

Runs the HL7 FHIR validator (validator_cli.jar) with the eCR FHIR IG package over
the FHIR bundles produced by run-integration-tests.py (the cda2fhir-r4 pipeline),
then diffs the results against a checked-in baseline so that CI fails only on NEW
problems.

    python validate-fhir-outputs.py --input output/
    python validate-fhir-outputs.py --input output/ --update-baseline

Requirements: Java 17/21/25 on PATH. The validator jar is downloaded on first run
(~180 MB) unless --jar / $ECR_VALIDATOR_JAR points at an existing copy.

Design notes
------------
* All files are validated in ONE validator invocation. Package loading costs
  ~60 s; per-file validation costs ~1-20 s. Batching is worth ~1 min per file.
* Single input  -> validator emits a bare OperationOutcome.
  Multiple inputs -> a Bundle(type=collection) of OperationOutcomes, each tagged
  with an `operationoutcome-file` extension. Both shapes are handled.
* Issue identity for baselining is (file, severity, message-id, normalised
  location). The `operationoutcome-message-id` extension is a stable machine code
  (e.g. Validation_VAL_Profile_Minimum_SLICE); the human text is not stable
  across validator releases and is carried for display only.
* Locations are normalised because the pipeline mints fresh UUIDs on every run
  (NativeUUIDGen / cda-add-uuid): urn:uuid values, the /*Type/id*/ annotations
  the validator injects, and bare UUIDs in message text are all masked.
* Known validator/IG interaction: a profile-discriminated slice only matches if
  the candidate resource fully conforms. One bad code display inside the
  Composition therefore ALSO produces
  "Slice 'Bundle.entry:slicePublicHealthComposition': a matching slice is
  required, but not found" at Bundle level. Those secondary errors are annotated
  as probable cascades so nobody goes hunting for a missing Composition.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

VALIDATOR_URL = (
    "https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar"
)
DEFAULT_IG = "hl7.fhir.us.ecr#2.1.2"
DEFAULT_FHIR_VERSION = "4.0.1"

EXT_BASE = "http://hl7.org/fhir/StructureDefinition/"
EXT_FILE = EXT_BASE + "operationoutcome-file"
EXT_MSGID = EXT_BASE + "operationoutcome-message-id"
EXT_LINE = EXT_BASE + "operationoutcome-issue-line"
EXT_COL = EXT_BASE + "operationoutcome-issue-col"

SEVERITY_ORDER = ["fatal", "error", "warning", "information"]
FAIL_SEVERITIES = {"fatal", "error"}

SLICE_CASCADE_MSGIDS = {
    "Validation_VAL_Profile_Minimum_SLICE",
    "Validation_VAL_Profile_Maximum_SLICE",
}

# Issues that reflect the machine or the network rather than the instance. These
# come and go between runs on the same input, so they must not enter the baseline
# and must not gate CI. Observed in practice: the validator's own regex check
# times out on long narrative strings when the box is CPU-starved, which is
# reported as a plain "error" indistinguishable from a content error.
ENVIRONMENTAL_MSGIDS = {
    "TYPE_SPECIFIC_CHECKS_DT_PRIMITIVE_REGEX_EXCEPTION",
}
ENVIRONMENTAL_TEXT_RE = re.compile(
    r"timed out|timeout|OutOfMemory|Connection reset|connection refused|"
    r"Read timed out|Unable to connect|SocketException|Error from server:",
    re.IGNORECASE,
)

UUID_RE = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)
# The validator annotates locations as .../*Composition/composition-eicr-zika*/...
RESOURCE_ANNOTATION_RE = re.compile(r"/\*([A-Za-z]+)/[^*]*\*/")


# --------------------------------------------------------------------------
# validator invocation
# --------------------------------------------------------------------------


def ensure_jar(path: Path) -> Path:
    if path.exists():
        return path
    print(f"validator jar not found at {path}; downloading (~180 MB)...", file=sys.stderr)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".part")
    with urllib.request.urlopen(VALIDATOR_URL) as resp, open(tmp, "wb") as fh:
        shutil.copyfileobj(resp, fh)
    tmp.rename(path)
    print(f"downloaded {path} ({path.stat().st_size / 1e6:.0f} MB)", file=sys.stderr)
    return path


def collect_inputs(input_dir: Path, patterns: list[str]) -> list[Path]:
    files: list[Path] = []
    for pat in patterns:
        files.extend(sorted(input_dir.glob(pat)))
    return [f for f in files if f.is_file()]


def run_validator(args, files: list[Path], out_path: Path) -> int:
    cmd = [
        args.java,
        f"-Xmx{args.heap}",
        "-jar",
        str(args.jar),
        *[str(f) for f in files],
        "-version",
        args.fhir_version,
        "-output-style",
        "json",
        "-output",
        str(out_path),
    ]
    for ig in args.ig:
        cmd += ["-ig", ig]
    if args.tx:
        cmd += ["-tx", args.tx]
    if args.tx_cache:
        cmd += ["-txCache", str(args.tx_cache)]
    if args.display_issues_are_warnings:
        cmd.append("-display-issues-are-warnings")
    if args.best_practice:
        cmd += ["-best-practice", args.best_practice]
    cmd += args.extra

    if args.verbose:
        print("+ " + " ".join(cmd), file=sys.stderr)
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=args.timeout)
    if args.verbose or proc.returncode not in (0, 1):
        sys.stderr.write(proc.stdout[-4000:])
        sys.stderr.write(proc.stderr[-4000:])
    # validator_cli exits 1 when it found errors, which is not a harness failure.
    if not out_path.exists():
        sys.stderr.write(proc.stdout[-8000:])
        sys.stderr.write(proc.stderr[-8000:])
        raise SystemExit("validator produced no output file - see log above")
    return proc.returncode


# --------------------------------------------------------------------------
# result parsing
# --------------------------------------------------------------------------


def ext_value(node: dict, url: str):
    for e in node.get("extension", []) or []:
        if e.get("url") == url:
            for k, v in e.items():
                if k.startswith("value"):
                    return v
    return None


def normalise_location(loc: str) -> str:
    if not loc:
        return ""
    loc = UUID_RE.sub("<uuid>", loc)
    loc = RESOURCE_ANNOTATION_RE.sub(r"/*\1*/", loc)
    return loc


def normalise_text(text: str) -> str:
    return UUID_RE.sub("<uuid>", text or "")


def issue_records(outcome: dict, filename: str) -> list[dict]:
    out = []
    for issue in outcome.get("issue", []) or []:
        expr = (issue.get("expression") or issue.get("location") or [""])[0]
        out.append(
            {
                "file": filename,
                "severity": issue.get("severity", "information"),
                "code": issue.get("code"),
                "message_id": ext_value(issue, EXT_MSGID) or "",
                "location": normalise_location(expr),
                "raw_location": expr,
                "line": ext_value(issue, EXT_LINE),
                "col": ext_value(issue, EXT_COL),
                "text": normalise_text((issue.get("details") or {}).get("text", "")),
            }
        )
    for rec in out:
        rec["environmental"] = is_environmental(rec)
    return out


def is_environmental(rec: dict) -> bool:
    if rec["severity"] not in FAIL_SEVERITIES:
        return False
    if rec["message_id"] in ENVIRONMENTAL_MSGIDS and ENVIRONMENTAL_TEXT_RE.search(rec["text"]):
        return True
    return bool(ENVIRONMENTAL_TEXT_RE.search(rec["text"]))


def parse_output(out_path: Path, base_dir: Path) -> list[dict]:
    data = json.loads(out_path.read_text(encoding="utf-8"))
    records: list[dict] = []
    if data.get("resourceType") == "OperationOutcome":
        name = ext_value(data, EXT_FILE) or "<single-input>"
        records += issue_records(data, rel(name, base_dir))
    elif data.get("resourceType") == "Bundle":
        for entry in data.get("entry", []) or []:
            res = entry.get("resource") or {}
            if res.get("resourceType") != "OperationOutcome":
                continue
            name = ext_value(res, EXT_FILE) or "<unknown>"
            records += issue_records(res, rel(name, base_dir))
    else:
        raise SystemExit(f"unexpected validator output resourceType: {data.get('resourceType')}")
    return records


def rel(name: str, base_dir: Path) -> str:
    try:
        return Path(name).resolve().relative_to(base_dir.resolve()).as_posix()
    except (ValueError, OSError):
        return Path(name).name


# --------------------------------------------------------------------------
# baseline handling
# --------------------------------------------------------------------------


def key_of(rec: dict) -> str:
    return "|".join([rec["file"], rec["severity"], rec["message_id"], rec["location"]])


def load_baseline(path: Path) -> dict:
    if not path.exists():
        return {"accepted": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    data.setdefault("accepted", {})
    return data


def write_baseline(path: Path, records: list[dict], meta: dict) -> None:
    accepted = {}
    for rec in records:
        if rec["severity"] in FAIL_SEVERITIES and not rec.get("environmental"):
            accepted[key_of(rec)] = {
                "file": rec["file"],
                "severity": rec["severity"],
                "message_id": rec["message_id"],
                "location": rec["location"],
                "text": rec["text"],
                "note": "",
            }
    payload = {
        "_comment": (
            "Accepted FHIR validation errors for eCRTransforms integration outputs. "
            "Each entry is an error that is known and consciously tolerated. Add a 'note' "
            "explaining WHY. Regenerate with --update-baseline; review the diff before "
            "committing, since regenerating silently accepts new regressions."
        ),
        "meta": meta,
        "accepted": accepted,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return len(accepted)


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------


def annotate_cascades(records: list[dict]) -> None:
    """Flag slice-minimum errors that are probably downstream of another error."""
    per_file_other_errors = defaultdict(int)
    for rec in records:
        if rec["severity"] in FAIL_SEVERITIES and rec["message_id"] not in SLICE_CASCADE_MSGIDS:
            per_file_other_errors[rec["file"]] += 1
    for rec in records:
        rec["cascade"] = bool(
            rec["message_id"] in SLICE_CASCADE_MSGIDS
            and rec["severity"] in FAIL_SEVERITIES
            and per_file_other_errors[rec["file"]]
        )


def print_report(records: list[dict], new_errors: list[dict], baseline: dict,
                 seen_keys: set[str], show_warnings: bool) -> None:
    files = sorted({r["file"] for r in records})
    print()
    print("=" * 78)
    print("FHIR validation summary")
    print("=" * 78)
    width = max((len(f) for f in files), default=10)
    print(f"{'file'.ljust(width)}  {'error':>6} {'warn':>6} {'info':>6}")
    for f in files:
        counts = Counter(r["severity"] for r in records if r["file"] == f)
        errs = counts["error"] + counts["fatal"]
        print(f"{f.ljust(width)}  {errs:>6} {counts['warning']:>6} {counts['information']:>6}")

    if show_warnings:
        warn_ids = Counter(
            r["message_id"] or r["code"] for r in records if r["severity"] == "warning"
        )
        if warn_ids:
            print("\nWarnings by message id (not gating):")
            for mid, n in warn_ids.most_common():
                print(f"  {n:>4}  {mid}")

    env = [r for r in records if r.get("environmental")]
    if env:
        print(f"\n--- {len(env)} issue(s) classified as ENVIRONMENTAL (not gating, not baselined) ---")
        print("    These vary between runs on identical input - CPU/memory pressure or a")
        print("    terminology-server hiccup. Re-run on a quieter box before trusting them.")
        for rec in env:
            print(f"  {rec['file']}: {rec['message_id']} at {rec['raw_location']}")
            print(f"    {rec['text'][:200]}")

    accepted_still_seen = [k for k in baseline["accepted"] if k in seen_keys]
    stale = [k for k in baseline["accepted"] if k not in seen_keys]

    if new_errors:
        print(f"\n--- NEW errors not in baseline: {len(new_errors)} ---")
        for rec in new_errors:
            tag = "  [probable cascade]" if rec.get("cascade") else ""
            print(f"\n  {rec['file']}{tag}")
            print(f"    id   : {rec['message_id']}")
            print(f"    at   : {rec['raw_location']}")
            if rec["line"]:
                print(f"    line : {rec['line']}:{rec['col']}")
            print(f"    text : {rec['text']}")
    else:
        print("\nNo new errors.")

    if accepted_still_seen:
        print(f"\nBaselined errors still present: {len(accepted_still_seen)}")
    if stale:
        print(f"\nBaseline entries NOT reproduced ({len(stale)}) - fixed, or the location moved:")
        for k in stale:
            print(f"  {k}")


# --------------------------------------------------------------------------


def main() -> int:
    here = Path(__file__).resolve().parent
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", type=Path, default=here / "output",
                   help="directory of FHIR resources to validate (default: ./output)")
    p.add_argument("--pattern", action="append", default=None,
                   help="glob(s) within --input (default: *.json and *.xml)")
    p.add_argument("--jar", type=Path,
                   default=Path(os.environ.get("ECR_VALIDATOR_JAR", here / "validator_cli.jar")),
                   help="path to validator_cli.jar (downloaded if absent)")
    p.add_argument("--java", default=os.environ.get("JAVA", "java"))
    p.add_argument("--heap", default="4g", help="JVM max heap (default 4g)")
    p.add_argument("--ig", action="append", default=None,
                   help=f"IG package(s) to load (default: {DEFAULT_IG})")
    p.add_argument("--fhir-version", default=DEFAULT_FHIR_VERSION)
    p.add_argument("--tx", default=None,
                   help="terminology server URL, or 'n/a' to disable terminology checking")
    p.add_argument("--tx-cache", type=Path, default=here / ".txcache",
                   help="terminology cache dir (speeds up reruns; gitignore it)")
    p.add_argument("--display-issues-are-warnings", action="store_true",
                   help="downgrade 'wrong display name' errors to warnings (see VALIDATION.md)")
    p.add_argument("--best-practice", default=None, choices=["ignore", "hint", "warning", "error"])
    p.add_argument("--baseline", type=Path, default=here / "fhir-validation-baseline.json")
    p.add_argument("--update-baseline", action="store_true",
                   help="rewrite the baseline from this run instead of diffing against it")
    p.add_argument("--no-baseline", action="store_true",
                   help="ignore the baseline; any error fails")
    p.add_argument("--json", type=Path, default=None, help="write the parsed issue list here")
    p.add_argument("--raw", type=Path, default=None, help="keep the raw validator OperationOutcome here")
    p.add_argument("--fail-on-environmental", action="store_true",
                   help="also gate on issues classified as environmental (regex timeouts, tx errors)")
    p.add_argument("--show-warnings", action="store_true")
    p.add_argument("--timeout", type=int, default=3600)
    p.add_argument("--verbose", action="store_true")
    p.add_argument("extra", nargs="*", help="extra args passed through to validator_cli")
    args = p.parse_args()

    args.ig = args.ig or [DEFAULT_IG]
    args.pattern = args.pattern or ["*.json", "*.xml"]

    if not args.input.is_dir():
        print(f"input directory not found: {args.input}", file=sys.stderr)
        print("run run-integration-tests.py first to produce the FHIR bundles.", file=sys.stderr)
        return 2

    files = collect_inputs(args.input, args.pattern)
    if not files:
        print(f"no files matching {args.pattern} in {args.input}", file=sys.stderr)
        return 2
    print(f"validating {len(files)} file(s) from {args.input} against {', '.join(args.ig)}")

    ensure_jar(args.jar)
    if args.tx_cache:
        args.tx_cache.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as td:
        out_path = Path(td) / "validator-output.json"
        run_validator(args, files, out_path)
        if args.raw:
            shutil.copy(out_path, args.raw)
        records = parse_output(out_path, args.input)

    annotate_cascades(records)

    if args.json:
        args.json.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")

    baseline = {"accepted": {}} if args.no_baseline else load_baseline(args.baseline)
    seen_keys = {key_of(r) for r in records}

    if args.update_baseline:
        meta = {
            "ig": args.ig,
            "fhir_version": args.fhir_version,
            "display_issues_are_warnings": args.display_issues_are_warnings,
            "input": str(args.input),
        }
        n = write_baseline(args.baseline, records, meta)
        skipped = sum(1 for r in records if r.get("environmental"))
        print(f"baseline written to {args.baseline} ({n} accepted error(s)"
              + (f", {skipped} environmental issue(s) excluded)" if skipped else ")"))
        print("REVIEW THE DIFF before committing - regenerating accepts regressions silently.")
        return 0

    new_errors = [
        r for r in records
        if r["severity"] in FAIL_SEVERITIES
        and key_of(r) not in baseline["accepted"]
        and not (r.get("environmental") and not args.fail_on_environmental)
    ]
    print_report(records, new_errors, baseline, seen_keys, args.show_warnings)

    if new_errors:
        print(f"\nFAIL: {len(new_errors)} new error(s).")
        return 1
    print("\nPASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
