#!/usr/bin/env python3
"""
validate-cda-outputs.py — layer 3b of the eCRTransforms testing suite.

Validates the CDA documents produced by the fhir2cda-r4 pipeline in two passes:

  1. W3C schema     - CDA_SDTC.xsd (xmllint, or lxml if xmllint is absent)
  2. Schematron     - the eICR IG Schematron, applied as compiled XSLT via Saxon,
                      with the SVRL output parsed and split into SHALL / SHOULD /
                      MAY buckets

Only SHALL failures gate: they are IG conformance violations. SHOULD and MAY are
reported for review. Results are diffed against a checked-in baseline so CI fails
only on NEW violations.

    python validate-cda-outputs.py --input output-cda/ \
        --schema ../../schemas/CDA_SDTC.xsd \
        --schematron-xsl ../../schematron/eicr_validator.xsl

Paths can also come from the environment:
    ECR_CDA_SCHEMA, ECR_CDA_SCHEMATRON_XSL, ECR_SAXON_JAR

Notes
-----
* The SHALL/SHOULD split uses the assertion text, not @role/@flag: the eICR
  Schematron encodes conformance verbs in the message. The rule is "contains
  SHALL and does not also contain SHOULD" - an assertion mentioning both is
  treated as the weaker SHOULD so it cannot fail the build on an ambiguity.
* Schematron is applied with Saxon via the `saxonche` Python binding (Saxon-HE,
  no licence needed) when available, otherwise by shelling out to a Saxon jar.
* The fhir2cda pipeline mints fresh UUIDs on every run, so UUIDs are masked
  before an issue becomes a baseline key.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

from lxml import etree

SVRL_NS = "http://purl.oclc.org/dsdl/svrl"
UUID_RE = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)

SEV_SHALL = "SHALL"
SEV_SHOULD = "SHOULD"
SEV_MAY = "MAY"
SEV_OTHER = "OTHER"
GATING = {SEV_SHALL}


# --------------------------------------------------------------------------
# pass 1: W3C schema
# --------------------------------------------------------------------------


def schema_validate(files: list[Path], schema: Path, verbose: bool) -> list[dict]:
    issues: list[dict] = []
    if shutil.which("xmllint"):
        for f in files:
            proc = subprocess.run(
                ["xmllint", "--noout", "--schema", str(schema), str(f)],
                capture_output=True,
                text=True,
            )
            if proc.returncode != 0:
                for line in proc.stderr.splitlines():
                    line = line.strip()
                    if not line or line.endswith("validates"):
                        continue
                    issues.append(
                        {
                            "file": f.name,
                            "pass": "schema",
                            "severity": SEV_SHALL,
                            "test": "CDA_SDTC.xsd",
                            "location": "",
                            "text": normalise(line),
                        }
                    )
    else:
        if verbose:
            print("xmllint not found; falling back to lxml XMLSchema", file=sys.stderr)
        xsd = etree.XMLSchema(etree.parse(str(schema)))
        for f in files:
            doc = etree.parse(str(f))
            if not xsd.validate(doc):
                for err in xsd.error_log:
                    issues.append(
                        {
                            "file": f.name,
                            "pass": "schema",
                            "severity": SEV_SHALL,
                            "test": "CDA_SDTC.xsd",
                            "location": f"line {err.line}",
                            "text": normalise(err.message),
                        }
                    )
    return issues


# --------------------------------------------------------------------------
# pass 2: Schematron -> SVRL
# --------------------------------------------------------------------------


def apply_schematron_saxonche(xsl: Path, files: list[Path], out_dir: Path) -> list[Path]:
    from saxonche import PySaxonProcessor  # noqa: PLC0415

    svrls = []
    with PySaxonProcessor(license=False) as proc:
        xslt = proc.new_xslt30_processor()
        executable = xslt.compile_stylesheet(stylesheet_file=str(xsl))
        for f in files:
            target = out_dir / (f.stem + ".svrl")
            executable.transform_to_file(source_file=str(f), output_file=str(target))
            svrls.append(target)
    return svrls


def apply_schematron_jar(jar: Path, xsl: Path, files: list[Path], out_dir: Path,
                         java: str) -> list[Path]:
    svrls = []
    for f in files:
        target = out_dir / (f.stem + ".svrl")
        proc = subprocess.run(
            [java, "-jar", str(jar), f"-s:{f}", f"-xsl:{xsl}", f"-o:{target}"],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            sys.stderr.write(proc.stdout + proc.stderr)
            raise SystemExit(f"Saxon failed on {f}")
        svrls.append(target)
    return svrls


def classify(text: str) -> str:
    """Conformance verb of a Schematron assertion message."""
    upper = text.upper()
    has_shall = "SHALL" in upper
    has_should = "SHOULD" in upper
    if has_shall and not has_should:
        return SEV_SHALL
    if has_should:
        return SEV_SHOULD
    if "MAY" in upper:
        return SEV_MAY
    return SEV_OTHER


def normalise(text: str) -> str:
    return UUID_RE.sub("<uuid>", " ".join((text or "").split()))


def parse_svrl(path: Path, source_name: str) -> list[dict]:
    tree = etree.parse(str(path))
    issues = []
    for el in tree.iter(f"{{{SVRL_NS}}}failed-assert", f"{{{SVRL_NS}}}successful-report"):
        text_el = el.find(f"{{{SVRL_NS}}}text")
        text = normalise(text_el.text if text_el is not None else "")
        kind = etree.QName(el).localname
        issues.append(
            {
                "file": source_name,
                "pass": "schematron",
                "severity": classify(text),
                "kind": kind,
                "test": el.get("test", ""),
                "role": el.get("role", ""),
                "id": el.get("id", ""),
                "location": normalise(el.get("location", "")),
                "text": text,
            }
        )
    return issues


# --------------------------------------------------------------------------
# baseline
# --------------------------------------------------------------------------


def key_of(rec: dict) -> str:
    return "|".join(
        [rec["file"], rec["pass"], rec["severity"], rec.get("id", ""), rec["location"],
         rec["text"][:120]]
    )


def load_baseline(path: Path) -> dict:
    if not path.exists():
        return {"accepted": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    data.setdefault("accepted", {})
    return data


def write_baseline(path: Path, records: list[dict], meta: dict) -> None:
    accepted = {
        key_of(r): {**{k: r[k] for k in ("file", "pass", "severity", "location", "text")},
                    "id": r.get("id", ""), "note": ""}
        for r in records
        if r["severity"] in GATING
    }
    payload = {
        "_comment": (
            "Accepted CDA SHALL violations for eCRTransforms fhir2cda outputs. Each entry "
            "is a known, tolerated violation - add a 'note' saying why. Regenerate with "
            "--update-baseline and review the diff before committing."
        ),
        "meta": meta,
        "accepted": accepted,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return len(accepted)


# --------------------------------------------------------------------------


def print_report(records: list[dict], new_violations: list[dict], baseline: dict,
                 seen: set[str], show_should: bool) -> None:
    files = sorted({r["file"] for r in records})
    print()
    print("=" * 78)
    print("CDA validation summary")
    print("=" * 78)
    width = max((len(f) for f in files), default=10)
    print(f"{'file'.ljust(width)}  {'SHALL':>6} {'SHOULD':>7} {'MAY':>5} {'other':>6}")
    for f in files:
        c = Counter(r["severity"] for r in records if r["file"] == f)
        print(f"{f.ljust(width)}  {c[SEV_SHALL]:>6} {c[SEV_SHOULD]:>7} "
              f"{c[SEV_MAY]:>5} {c[SEV_OTHER]:>6}")

    if show_should:
        shoulds = [r for r in records if r["severity"] == SEV_SHOULD]
        if shoulds:
            print(f"\nSHOULD findings ({len(shoulds)}, not gating):")
            for r in shoulds:
                print(f"  {r['file']}: {r['text'][:150]}")

    if new_violations:
        print(f"\n--- NEW SHALL violations not in baseline: {len(new_violations)} ---")
        for r in new_violations:
            print(f"\n  {r['file']}  [{r['pass']}]")
            if r.get("id"):
                print(f"    rule : {r['id']}")
            if r.get("test"):
                print(f"    test : {r['test'][:160]}")
            if r["location"]:
                print(f"    at   : {r['location'][:200]}")
            print(f"    text : {r['text'][:300]}")
    else:
        print("\nNo new SHALL violations.")

    stale = [k for k in baseline["accepted"] if k not in seen]
    if stale:
        print(f"\nBaseline entries NOT reproduced ({len(stale)}) - fixed, or the wording moved:")
        for k in stale:
            print(f"  {k[:160]}")


def main() -> int:
    here = Path(__file__).resolve().parent
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", type=Path, default=here / "output-cda",
                   help="directory of CDA documents to validate")
    p.add_argument("--pattern", default="*.xml")
    p.add_argument("--schema", type=Path,
                   default=Path(os.environ["ECR_CDA_SCHEMA"]) if os.environ.get("ECR_CDA_SCHEMA") else None,
                   help="path to CDA_SDTC.xsd")
    p.add_argument("--schematron-xsl", type=Path,
                   default=Path(os.environ["ECR_CDA_SCHEMATRON_XSL"]) if os.environ.get("ECR_CDA_SCHEMATRON_XSL") else None,
                   help="compiled Schematron stylesheet, e.g. eicr_validator.xsl")
    p.add_argument("--saxon-jar", type=Path,
                   default=Path(os.environ["ECR_SAXON_JAR"]) if os.environ.get("ECR_SAXON_JAR") else None,
                   help="Saxon jar to use if the saxonche binding is unavailable")
    p.add_argument("--java", default=os.environ.get("JAVA", "java"))
    p.add_argument("--svrl-dir", type=Path, default=here / ".svrl",
                   help="where to keep the SVRL output (gitignore it)")
    p.add_argument("--baseline", type=Path, default=here / "cda-validation-baseline.json")
    p.add_argument("--update-baseline", action="store_true")
    p.add_argument("--no-baseline", action="store_true")
    p.add_argument("--json", type=Path, default=None, help="write the parsed issue list here")
    p.add_argument("--show-should", action="store_true")
    p.add_argument("--verbose", action="store_true")
    args = p.parse_args()

    if not args.input.is_dir():
        print(f"input directory not found: {args.input}", file=sys.stderr)
        return 2
    files = sorted(f for f in args.input.glob(args.pattern) if f.is_file())
    if not files:
        print(f"no files matching {args.pattern} in {args.input}", file=sys.stderr)
        return 2
    print(f"validating {len(files)} CDA document(s) from {args.input}")

    records: list[dict] = []
    ran_any = False

    if args.schema and args.schema.exists():
        print(f"  schema     : {args.schema}")
        records += schema_validate(files, args.schema, args.verbose)
        ran_any = True
    else:
        print("  schema     : SKIPPED (pass --schema /path/to/CDA_SDTC.xsd)")

    if args.schematron_xsl and args.schematron_xsl.exists():
        print(f"  schematron : {args.schematron_xsl}")
        args.svrl_dir.mkdir(parents=True, exist_ok=True)
        try:
            svrls = apply_schematron_saxonche(args.schematron_xsl, files, args.svrl_dir)
        except ImportError:
            if not (args.saxon_jar and args.saxon_jar.exists()):
                print("saxonche not installed and no --saxon-jar given "
                      "(pip install saxonche)", file=sys.stderr)
                return 2
            svrls = apply_schematron_jar(args.saxon_jar, args.schematron_xsl, files,
                                         args.svrl_dir, args.java)
        for svrl, src in zip(svrls, files):
            records += parse_svrl(svrl, src.name)
        ran_any = True
    else:
        print("  schematron : SKIPPED (pass --schematron-xsl /path/to/eicr_validator.xsl)")

    if not ran_any:
        print("\nNothing to do: neither the schema nor the Schematron was available.",
              file=sys.stderr)
        return 2

    if args.json:
        args.json.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")

    if args.update_baseline:
        n = write_baseline(args.baseline, records,
                           {"schema": str(args.schema), "schematron": str(args.schematron_xsl),
                            "input": str(args.input)})
        print(f"baseline written to {args.baseline} ({n} accepted SHALL violation(s))")
        print("REVIEW THE DIFF before committing.")
        return 0

    baseline = {"accepted": {}} if args.no_baseline else load_baseline(args.baseline)
    seen = {key_of(r) for r in records}
    new_violations = [
        r for r in records
        if r["severity"] in GATING and key_of(r) not in baseline["accepted"]
    ]
    print_report(records, new_violations, baseline, seen, args.show_should)

    if new_violations:
        print(f"\nFAIL: {len(new_violations)} new SHALL violation(s).")
        return 1
    print("\nPASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
