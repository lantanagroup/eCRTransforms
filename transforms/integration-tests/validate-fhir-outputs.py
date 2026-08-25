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

Corpus mode (layer 3b) - 20260824 Claude
----------------------------------------
--corpus turns this script on the SNAPSHOT corpus (snapshot-corpus.txt) instead
of the fixture bundles: every corpus document is transformed with saxonche
through NativeUUIDGen-cda2fhir.xslt into --corpus-output (default
./output-corpus, gitignore it like ./output), ALL outputs are validated in one
validator invocation, and the raw validator JSON is saved to
<corpus-output>/validator-output.json so gating can be re-run without paying
for validation again.

    python validate-fhir-outputs.py --corpus                   gate against known issues
    python validate-fhir-outputs.py --corpus --update-known    rewrite the known-issues file
    python validate-fhir-outputs.py --corpus --gate-only       re-gate from the saved JSON
    python validate-fhir-outputs.py --corpus --corpus-filter testRR   subset by filename

Because the real documents carry known-open conformance defects, corpus mode
gates against conformance-known-issues.txt (same TAB format and philosophy as
corpus-known-issues.txt) and FAILS ONLY ON NEW OR WORSENED problems; IMPROVED
lines mean the baseline should be regenerated so the ratchet tightens.

Issue identity in corpus mode is deliberately COARSER than fixture mode:
severity + normalised issue.details.text, with urn:uuid values masked to
<uuid> and [n] indexes stripped from any embedded expressions. Location is NOT
part of the identity - the pipeline mints fresh UUIDs every run and the corpus
documents are messy enough that expression paths jitter; message text keyed per
document is the stable unit. Only error/fatal severities gate; environmental
issues (see above) are excluded from both the gate and the baseline.

Known flakiness: the validator occasionally emits (or omits) a LONE
Reference_REF_CantMatchChoice error on an otherwise stable document. If a run
differs from the baseline by exactly one such line, re-run before concluding
anything - and re-run before baselining one.
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
    # 20260824 Claude: newer validator builds phrase terminology-server failures
    # "Error from https://tx.fhir.org/r4: ..." rather than "Error from server:" -
    # both are environmental, not content defects, and must not enter the
    # conformance baseline (they vanish/mutate on a cold cache).
    r"Read timed out|Unable to connect|SocketException|Error from server:|Error from http",
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
# corpus mode (layer 3b) - see the module docstring
# --------------------------------------------------------------------------

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent                      # transforms/integration-tests -> transforms -> repo
STYLESHEET = HERE.parent / "cda2fhir-r4" / "NativeUUIDGen-cda2fhir.xslt"
CORPUS = HERE / "snapshot-corpus.txt"
CORPUS_RAW_JSON = "validator-output.json"      # deterministic, inside --corpus-output
CORPUS_MANIFEST = "corpus-manifest.json"       # output filename -> repo-relative source doc

INDEX_RE = re.compile(r"\[\d+\]")


def load_corpus() -> list[Path]:
    """Same loader shape as snapshot-regression.py: one glob per line, repo-relative."""
    if not CORPUS.exists():
        raise SystemExit(f"corpus file not found: {CORPUS}")
    docs: list[Path] = []
    for raw in CORPUS.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        matches = sorted(REPO.glob(line))
        if not matches:
            print(f"  ! corpus pattern matched nothing: {line}", file=sys.stderr)
        docs.extend(m for m in matches if m.is_file())
    seen, out = set(), []
    for d in docs:
        if d not in seen:
            seen.add(d)
            out.append(d)
    return out


def corpus_rel(doc: Path) -> str:
    try:
        return doc.resolve().relative_to(REPO).as_posix()
    except ValueError:
        return doc.name


def flatten_name(relpath: str) -> str:
    """Flatten the repo-relative path so outputs from different directories cannot
    collide (several corpus documents share a filename) - same convention as
    snapshot-regression.py's snapshot names."""
    return relpath.replace("/", "__").replace("\\", "__")


def transform_corpus(docs: list[Path], out_dir: Path) -> dict:
    """Transform every corpus doc into out_dir; return the manifest dict
    {"outputs": {output filename: repo-relative source}, "transform_errors": {...}}."""
    try:
        from saxonche import PySaxonProcessor
    except ImportError:
        raise SystemExit("saxonche is required for --corpus:  pip install saxonche")
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"outputs": {}, "transform_errors": {}}
    with PySaxonProcessor(license=False) as proc:
        exe = proc.new_xslt30_processor().compile_stylesheet(stylesheet_file=str(STYLESHEET))
        for doc in docs:
            relpath = corpus_rel(doc)
            try:
                out = exe.transform_to_string(source_file=str(doc))
            except Exception as e:  # noqa: BLE001 - a transform error must gate, not crash
                print(f"transform ERROR  {relpath}: {e}", file=sys.stderr)
                manifest["transform_errors"][relpath] = normalise_text(str(e))
                continue
            name = flatten_name(relpath)
            (out_dir / name).write_text(out, encoding="utf-8")
            manifest["outputs"][name] = relpath
            print(f"transformed      {relpath}")
    (out_dir / CORPUS_MANIFEST).write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def corpus_identity(rec: dict) -> str:
    """severity + normalised message text; see the module docstring for why
    location is deliberately not part of the identity in corpus mode."""
    text = INDEX_RE.sub("", rec["text"])       # rec["text"] already has uuids masked
    text = text.replace("\t", " ").replace("\n", " ").strip()
    return f"{rec['severity']}: {text}"


def corpus_counts(records: list[dict], manifest: dict) -> dict:
    """{repo-relative doc: {identity: count}} over gating severities only.

    Every transformed document gets an entry (possibly empty) so that improved /
    fixed baseline lines are detected; transform errors gate as a fatal identity."""
    counts: dict[str, dict] = {relpath: {} for relpath in manifest["outputs"].values()}
    for rec in records:
        relpath = manifest["outputs"].get(rec["file"])
        if relpath is None:                    # not a corpus output (shouldn't happen)
            relpath = rec["file"]
            counts.setdefault(relpath, {})
        if rec["severity"] not in FAIL_SEVERITIES or rec.get("environmental"):
            continue
        ident = corpus_identity(rec)
        counts[relpath][ident] = counts[relpath].get(ident, 0) + 1
    for relpath, msg in manifest.get("transform_errors", {}).items():
        ident = f"fatal: transform error: {INDEX_RE.sub('', msg)}"
        counts.setdefault(relpath, {})[ident] = counts[relpath].get(ident, 0) + 1
    return counts


def load_known_issues(path: Path) -> dict:
    """{relpath: {identity: count}} from conformance-known-issues.txt.

    Unlike corpus-known-issues.txt, only FULL-LINE comments are recognised -
    validator message text can legitimately contain '#' (IG ids like
    hl7.fhir.us.ecr#2.1.2), so inline comment stripping would corrupt entries."""
    known: dict[str, dict] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        relpath, count, ident = raw.rstrip("\n").split("\t", 2)
        known.setdefault(relpath, {})[ident] = int(count)
    return known


def write_known_issues(path: Path, counts: dict) -> int:
    lines = [
        "# conformance-known-issues.txt - baseline for validate-fhir-outputs.py --corpus.",
        "# One line per known problem: <repo-relative path> TAB <count> TAB <identity>,",
        "# where <identity> is severity + normalised issue.details.text (uuids masked to",
        "# <uuid>, [n] indexes stripped). Only error/fatal severities are recorded.",
        "# Only full-line comments ('#' first) are recognised - message text may contain '#'.",
        "# Regenerate with --corpus --update-known AFTER REVIEWING what changed -",
        "# this file is the list of accepted open conformance defects, and it should",
        "# only shrink.",
        "#",
        "# FLAKINESS: the validator occasionally emits (or omits) a LONE",
        "# Reference_REF_CantMatchChoice error on an otherwise stable document. If a run",
        "# differs from this baseline by exactly one such line, re-run before trusting",
        "# it - and never baseline a lone one without a confirming re-run.",
    ]
    n = 0
    for relpath in sorted(counts):
        for ident, c in sorted(counts[relpath].items()):
            lines.append(f"{relpath}\t{c}\t{ident}")
            n += 1
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return n


def gate_corpus(counts: dict, known: dict, baseline_missing: bool) -> int:
    new_fail, improved, with_known = 0, 0, 0
    for relpath in sorted(counts):
        current = counts[relpath]
        baseline = known.get(relpath, {})
        worse = {p: c for p, c in current.items() if c > baseline.get(p, 0)}
        better = {p: c for p, c in baseline.items() if current.get(p, 0) < c}
        if worse:
            new_fail += 1
            print(f"FAIL   {relpath}  (new or worsened problems)")
            for p, c in sorted(worse.items()):
                print(f"      - NEW {p}  (x{c}, known {baseline.get(p, 0)})")
        elif better:
            improved += 1
            print(f"IMPROVED {relpath}  - re-run with --update-known and commit")
            for p, c in sorted(better.items()):
                print(f"      - {p}  (known x{c} -> now x{current.get(p, 0)})")
        else:
            print(("known  " if current else "ok     ") + relpath)
        if current and not worse:
            with_known += 1

    clean = sum(1 for v in counts.values() if not v)
    print(f"\n{clean}/{len(counts)} documents conformance-clean; "
          f"{with_known} with known issues; {new_fail} with NEW/worsened problems"
          + (f"; {improved} improved" if improved else ""))
    if baseline_missing and new_fail:
        print("\nNo baseline file exists yet, so EVERY error above is reported as NEW.")
        print("Review the list, then run  --corpus --update-known  to record it as the baseline.")
    elif new_fail:
        print("\nIf a document differs by exactly one lone Reference_REF_CantMatchChoice,")
        print("re-run before concluding anything - that error is known to be flaky.")
    return 1 if new_fail else 0


def run_corpus_mode(args) -> int:
    out_dir = args.corpus_output
    raw_json = out_dir / CORPUS_RAW_JSON
    manifest_path = out_dir / CORPUS_MANIFEST
    filters = args.corpus_filter or []

    def wanted(name: str) -> bool:
        return not filters or any(f in name for f in filters)

    if args.gate_only:
        if not raw_json.exists() or not manifest_path.exists():
            print(f"--gate-only needs a previous --corpus run: missing {raw_json} "
                  f"or {manifest_path}", file=sys.stderr)
            return 2
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    else:
        docs = [d for d in load_corpus() if wanted(corpus_rel(d))]
        if not docs:
            raise SystemExit(f"no corpus documents matching {filters}")
        print(f"transforming {len(docs)} corpus document(s) -> {out_dir}")
        manifest = transform_corpus(docs, out_dir)
        outputs = sorted(out_dir / name for name in manifest["outputs"])
        if not outputs:
            raise SystemExit("no corpus document transformed successfully - nothing to validate")
        print(f"\nvalidating {len(outputs)} output(s) against {', '.join(args.ig)} "
              f"(one invocation; expect ~1 min/doc)")
        ensure_jar(args.jar)
        if args.tx_cache:
            args.tx_cache.mkdir(parents=True, exist_ok=True)
        run_validator(args, outputs, raw_json)
        print(f"raw validator output saved: {raw_json}  (re-gate any time with --gate-only)")

    records = parse_output(raw_json, out_dir)
    if args.json:
        args.json.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    counts = corpus_counts(records, manifest)
    if filters:
        counts = {p: v for p, v in counts.items() if wanted(p)}

    if args.update_known:
        n = write_known_issues(args.known_issues, {p: v for p, v in counts.items() if v})
        print(f"\nknown-issues baseline written: {n} problem line(s) -> {args.known_issues.name}")
        print("REVIEW THE DIFF before committing - this accepts current defects as known.")
        return 0

    baseline_missing = not args.known_issues.exists()
    if baseline_missing:
        print(f"! baseline file not found: {args.known_issues} - every error will be NEW",
              file=sys.stderr)
    known = {} if baseline_missing else load_known_issues(args.known_issues)
    print()
    return gate_corpus(counts, known, baseline_missing)


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
    p.add_argument("--corpus", action="store_true",
                   help="layer 3b: transform+validate the snapshot corpus and gate against "
                        "conformance-known-issues.txt (see the module docstring)")
    p.add_argument("--update-known", action="store_true",
                   help="with --corpus: rewrite conformance-known-issues.txt from this run")
    p.add_argument("--gate-only", action="store_true",
                   help="with --corpus: skip transform+validation, re-gate from the saved "
                        "validator JSON in --corpus-output")
    p.add_argument("--corpus-filter", action="append", default=None,
                   help="with --corpus: only process corpus documents whose repo-relative "
                        "path contains this substring (like snapshot-regression.py "
                        "--filter, but matching the path so directories work too; "
                        "repeatable - a document matching ANY given substring is kept)")
    p.add_argument("--corpus-output", type=Path, default=here / "output-corpus",
                   help="with --corpus: dir for transformed bundles + saved validator JSON "
                        "(default: ./output-corpus; gitignore it)")
    p.add_argument("--known-issues", type=Path, default=here / "conformance-known-issues.txt",
                   help="with --corpus: the known-issues baseline file")
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

    if (args.update_known or args.gate_only or args.corpus_filter) and not args.corpus:
        print("--update-known/--gate-only/--corpus-filter only make sense with --corpus",
              file=sys.stderr)
        return 2
    if args.corpus:
        return run_corpus_mode(args)

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
