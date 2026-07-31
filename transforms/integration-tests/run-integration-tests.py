#!/usr/bin/env python3
"""eCRTransforms CDA->FHIR integration tests.

20260729 Claude: Created - full-pipeline integration tests. Each document in documents/
is run through the complete cda2fhir pipeline (NativeUUIDGen entry point, so it works on
Saxon-HE with no license) and the output Bundle is checked against structural invariants
that must hold for ANY input:

  1. Output is well-formed XML and contains at least one bundle entry.
  2. Every urn:uuid reference resolves to a fullUrl in the same Bundle (no dangling refs).
  3. No empty references (reference value="urn:uuid:" or value="").
  4. Required elements are present per resource type (status, intent, subject, ...).
  5. FHIR invariant con-5: no Condition carries clinicalStatus together with
     verificationStatus entered-in-error.

Requirements:  pip install saxonche
Usage:         python run-integration-tests.py                    (run all documents)
               python run-integration-tests.py testB              (run matching documents)
               python run-integration-tests.py --output output/   (also write the Bundles)
Exit code 0 = all pass, 1 = failures.

20260729 Claude: added --output. The structural invariants below are self-contained, but the
conformance layer (validate-fhir-outputs.py) needs the Bundles on disk to hand to
validator_cli. Bundles are written even for documents that fail their invariants, so the
validator can be run over a failing document to see whether the IG agrees.

To add a regression document: drop a synthetic eICR .xml into documents/. Keep documents
small and targeted - one section/scenario each - and give resources fixed ids so failures
are easy to trace. The invariants below apply automatically; add resource types to
REQUIRED_ELEMENTS if a new resource kind appears in your document.

20260730 Claude: added --corpus. Runs the same invariants over the SNAPSHOT corpus
(snapshot-corpus.txt) - the real documents, which is where structural defects actually
hide: the ad hoc sweep that this mode systematizes found defect items 38-41 on adoption
day, and the first --corpus run immediately surfaced item 42 (17 documents emitting a
Location with no <name>). Because real documents carry known-open defects, corpus mode
gates against corpus-known-issues.txt and FAILS ONLY ON NEW OR WORSENED problems - the
same philosophy as the conformance layer's baseline. Problem strings are normalised
(minted uuids masked) so the baseline is stable across runs, and documents are keyed by
repo-relative path (several corpus documents share a filename).

    python run-integration-tests.py --corpus                  compare against known issues
    python run-integration-tests.py --corpus --update-known   rewrite the known-issues file

Corpus globs that match nothing (gitignored real samples on CI) are skipped with a note,
exactly like snapshot-regression.py. An IMPROVED line means a known issue disappeared -
re-run with --update-known and commit, so the ratchet only ever tightens.
"""
import re
import sys
from pathlib import Path

try:
    from saxonche import PySaxonProcessor
except ImportError:
    sys.exit("saxonche is required:  pip install saxonche")

HERE = Path(__file__).resolve().parent
STYLESHEET = HERE.parent / "cda2fhir-r4" / "NativeUUIDGen-cda2fhir.xslt"
DOCS = HERE / "documents"
REPO = HERE.parent.parent
CORPUS = HERE / "snapshot-corpus.txt"
KNOWN_ISSUES = HERE / "corpus-known-issues.txt"

UUID_RE = re.compile(r"urn:uuid:[0-9a-fA-F-]+")

# Required-element presence per resource type (FHIR R4 base + US Core requirements that
# this pipeline is expected to satisfy). Checked for every instance in every Bundle.
REQUIRED_ELEMENTS = {
    "AllergyIntolerance": ["patient"],
    "CareTeam": ["status", "subject"],
    "Communication": ["status", "subject"],
    "Composition": ["status", "type", "date", "author", "title"],
    "Condition": ["subject"],
    "Coverage": ["status", "beneficiary"],
    "Encounter": ["status", "class"],
    "FamilyMemberHistory": ["status", "patient"],
    "Goal": ["lifecycleStatus", "subject"],
    "Location": ["name"],
    "MedicationAdministration": ["status", "subject"],
    "MedicationDispense": ["status"],
    "MedicationRequest": ["status", "intent", "subject"],
    "Observation": ["status", "code"],
    "Procedure": ["status", "subject"],
    "RequestGroup": ["status", "intent"],
    "ServiceRequest": ["status", "intent", "subject"],
    "Specimen": ["subject"],
}

# Value sets for status-like elements (catches raw CDA ActStatus codes leaking through).
STATUS_VALUE_SETS = {
    "AllergyIntolerance/clinicalStatus": {"active", "inactive", "resolved"},
    "CareTeam/status": {"proposed", "active", "suspended", "inactive", "entered-in-error"},
    "Communication/status": {"preparation", "in-progress", "not-done", "on-hold",
                             "stopped", "completed", "entered-in-error", "unknown"},
    "FamilyMemberHistory/status": {"partial", "completed", "entered-in-error", "health-unknown"},
    "Goal/lifecycleStatus": {"proposed", "planned", "accepted", "active", "on-hold",
                             "completed", "cancelled", "entered-in-error", "rejected"},
    "MedicationDispense/status": {"preparation", "in-progress", "cancelled", "on-hold",
                                  "completed", "entered-in-error", "stopped", "declined", "unknown"},
    "RequestGroup/status": {"draft", "active", "on-hold", "revoked", "completed",
                            "entered-in-error", "unknown"},
    "ServiceRequest/status": {"draft", "active", "on-hold", "revoked", "completed",
                              "entered-in-error", "unknown"},
}


def check_bundle(xml: str, problems: list):
    entries = len(re.findall(r"<entry>", xml))
    if entries == 0:
        problems.append("no bundle entries produced")
        return

    full_urls = set(re.findall(r'<fullUrl value="(urn:uuid:[^"]+)"', xml))
    refs = re.findall(r'<reference value="([^"]*)"', xml)
    for r in refs:
        if r in ("", "urn:uuid:"):
            problems.append("empty reference")
        elif r.startswith("urn:uuid:") and r not in full_urls:
            problems.append(f"dangling reference {r}")

    # per-resource required elements + status value sets
    for m in re.finditer(r"<resource>\s*(?:<!--.*?-->\s*)*<(\w+)[ >]", xml, re.S):
        rtype = m.group(1)
        # capture the resource element body
        body_match = re.search(r"<%s[ >].*?</%s>" % (rtype, rtype), xml[m.start():], re.S)
        if not body_match:
            continue
        body = body_match.group(0)
        for el in REQUIRED_ELEMENTS.get(rtype, []):
            if not re.search(r"<%s[ />]" % el, body):
                problems.append(f"{rtype} missing required <{el}>")
        for key, allowed in STATUS_VALUE_SETS.items():
            t, el = key.split("/")
            if t != rtype:
                continue
            if el == "clinicalStatus":
                vals = re.findall(r"<clinicalStatus>.*?<code value=\"([^\"]+)\"", body, re.S)
            else:
                vals = re.findall(r"<%s value=\"([^\"]+)\"" % el, body)
            for v in vals:
                if v not in allowed:
                    problems.append(f"{rtype}.{el} value '{v}' not in value set")

    # con-5: Condition may not have clinicalStatus when verificationStatus is entered-in-error
    for cm in re.finditer(r"<Condition[ >].*?</Condition>", xml, re.S):
        c = cm.group(0)
        if "entered-in-error" in c and "<clinicalStatus>" in c and \
           re.search(r"<verificationStatus>.*?entered-in-error", c, re.S):
            problems.append("con-5 violation: Condition has clinicalStatus with "
                            "verificationStatus entered-in-error")


def load_corpus() -> list:
    """Same loader shape as snapshot-regression.py: one glob per line, repo-relative."""
    if not CORPUS.exists():
        sys.exit(f"corpus file not found: {CORPUS}")
    docs = []
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


def rel(doc: Path) -> str:
    try:
        return doc.resolve().relative_to(REPO).as_posix()
    except ValueError:
        return doc.name


def normalise_problems(problems: list) -> dict:
    """Multiset of problem strings with minted uuids masked (they change every run)."""
    counts = {}
    for p in problems:
        p = UUID_RE.sub("urn:uuid:<uuid>", p)
        counts[p] = counts.get(p, 0) + 1
    return counts


def load_known() -> dict:
    """{relpath: {problem: count}} from corpus-known-issues.txt."""
    known = {}
    if not KNOWN_ISSUES.exists():
        return known
    for raw in KNOWN_ISSUES.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        path, count, problem = line.split("\t", 2)
        known.setdefault(path, {})[problem] = int(count)
    return known


def run_corpus(update_known: bool) -> int:
    docs = load_corpus()
    if not docs:
        sys.exit("corpus matched no documents at all")
    known = {} if update_known else load_known()
    new_fail, improved, results = 0, 0, {}
    with PySaxonProcessor(license=False) as proc:
        exe = proc.new_xslt30_processor().compile_stylesheet(stylesheet_file=str(STYLESHEET))
        for doc in docs:
            problems = []
            try:
                check_bundle(exe.transform_to_string(source_file=str(doc)), problems)
            except Exception as e:  # noqa: BLE001
                problems.append(f"transform error: {e}")
            counts = normalise_problems(problems)
            results[rel(doc)] = counts
            baseline = known.get(rel(doc), {})
            worse = {p: c for p, c in counts.items() if c > baseline.get(p, 0)}
            better = {p: c for p, c in baseline.items() if counts.get(p, 0) < c}
            if update_known:
                print(("known " if counts else "ok    ") + rel(doc))
            elif worse:
                new_fail += 1
                print(f"FAIL   {rel(doc)}  (new or worsened problems)")
                for p, c in sorted(worse.items()):
                    print(f"      - {p}  (x{c}, known {baseline.get(p, 0)})")
            elif better:
                improved += 1
                print(f"IMPROVED {rel(doc)}  - re-run with --update-known and commit")
                for p, c in sorted(better.items()):
                    print(f"      - {p}  (known x{c} -> now x{counts.get(p, 0)})")
            else:
                print(("known " if counts else "ok    ") + rel(doc))

    if update_known:
        lines = [
            "# corpus-known-issues.txt - baseline for run-integration-tests.py --corpus.",
            "# One line per known problem: <repo-relative path> TAB <count> TAB <problem>.",
            "# Regenerate with --corpus --update-known AFTER REVIEWING what changed -",
            "# this file is the list of accepted open defects, and it should only shrink.",
            "# Each entry should correspond to an open defect item in the project's",
            "# codebase notes.",
        ]
        for path in sorted(results):
            for p, c in sorted(results[path].items()):
                lines.append(f"{path}\t{c}\t{p}")
        KNOWN_ISSUES.write_text("\n".join(lines) + "\n", encoding="utf-8")
        n = sum(len(v) for v in results.values() if v)
        print(f"\nknown-issues baseline written: {n} problem line(s) -> {KNOWN_ISSUES.name}")
        print("REVIEW THE DIFF before committing - this accepts current defects as known.")
        return 0

    clean = sum(1 for v in results.values() if not v)
    print(f"\n{clean}/{len(results)} documents clean; "
          f"{sum(1 for v in results.values() if v)} with known issues; "
          f"{new_fail} with NEW problems" + (f"; {improved} improved" if improved else ""))
    return 1 if new_fail else 0


def main():
    argv = sys.argv[1:]
    out_dir = None
    corpus_mode = "--corpus" in argv
    update_known = "--update-known" in argv
    argv = [a for a in argv if a not in ("--corpus", "--update-known")]
    if update_known and not corpus_mode:
        sys.exit("--update-known only makes sense with --corpus")
    if "--output" in argv:
        i = argv.index("--output")
        try:
            out_dir = Path(argv[i + 1])
        except IndexError:
            sys.exit("--output needs a directory")
        del argv[i:i + 2]
    if corpus_mode:
        sys.exit(run_corpus(update_known))
    pattern = argv[0] if argv else ""
    docs = sorted(p for p in DOCS.glob("*.xml") if pattern in p.name)
    if not docs:
        sys.exit(f"no documents matching '{pattern}' in {DOCS}")
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)

    failed = 0
    with PySaxonProcessor(license=False) as proc:
        xslt = proc.new_xslt30_processor()
        exe = xslt.compile_stylesheet(stylesheet_file=str(STYLESHEET))
        for doc in docs:
            problems = []
            try:
                out = exe.transform_to_string(source_file=str(doc))
                if out_dir:
                    (out_dir / (doc.stem + ".xml")).write_text(out, encoding="utf-8")
                check_bundle(out, problems)
            except Exception as e:  # noqa: BLE001 - report any pipeline error as a failure
                problems.append(f"transform error: {e}")
            status = "PASS" if not problems else "FAIL"
            if problems:
                failed += 1
            print(f"{status}  {doc.name}")
            for p in sorted(set(problems)):
                n = problems.count(p)
                print(f"      - {p}" + (f"  (x{n})" if n > 1 else ""))

    print(f"\n{len(docs) - failed}/{len(docs)} documents passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
