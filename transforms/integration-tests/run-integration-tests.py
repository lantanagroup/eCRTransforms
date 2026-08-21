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

20260804 Claude: added the element-level invariants (check_elements). Motivation: the
2026-08-03 external review found 29 defects, and NONE of the structural ones were caught by
the reference/required-element/value-set checks above - they were malformed VALUES and empty
ELEMENTS, which those checks do not look at. The three invariants parked in the triage doc as
"cheap candidates" are now implemented, generalised from the instances that motivated them to
the defect CLASSES:

  6. ele-1  - every element must carry @value or have children. Catches empty primitives
     (value=""), bare elements (<address/>), and extensions with neither value nor
     sub-extensions (also ext-1). CDAFHIR-015 was one instance of this class.
  7. code/uri primitive syntax - the FHIR code regex is [^\s]+(\s[^\s]+)*, so leading or
     trailing whitespace is invalid, and uri types admit no whitespace at all. Internal
     whitespace in a code is reported separately: it is the signature of an XSLT value path
     that space-joined a multi-node selection into a 1..1 element (CDAFHIR-016).
  8. house-convention violations - a v3-NullFlavor coding where this pipeline's convention is
     a data-absent-reason extension, and literal placeholder strings ("Unknown") in
     ContactPoint.value (CDAFHIR-005).

These run over an ElementTree parse rather than the regexes used above, because they need to
distinguish FHIR elements from the XHTML inside Composition.text.div - narrative legitimately
contains hundreds of empty <br/> and <td/> elements, and every one of them would be a false
positive. The whole XHTML subtree is skipped.

On the corpus they immediately found 39 live violations in 9 documents that the pre-existing
invariants called clean, including 4 instances of CDAFHIR-015 surviving at three sites the
2026-08-03 fix did not touch. See the codebase notes, items 046-052.
"""
import re
import sys
import xml.etree.ElementTree as ET
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

    check_elements(xml, problems)


# --- element-level invariants (20260804) -------------------------------------------------
FHIR_NS = "{http://hl7.org/fhir}"
XHTML_NS = "{http://www.w3.org/1999/xhtml}"
DAR_URL = "http://hl7.org/fhir/StructureDefinition/data-absent-reason"
NULLFLAVOR_SYSTEM = "http://terminology.hl7.org/CodeSystem/v3-NullFlavor"

# Elements whose FHIR type is the `code` primitive (regex [^\s]+(\s[^\s]+)*), or a Coding.code.
# Deliberately a short, high-confidence list: a false positive here would land in the
# known-issues baseline and erode trust in the gate.
CODE_PRIMITIVES = {"code", "valueCode", "status", "intent", "gender", "use",
                   "priority", "contentType", "language", "lifecycleStatus"}
# Elements whose FHIR type is uri/url/canonical - no whitespace is legal anywhere in them.
URI_PRIMITIVES = {"system", "url", "reference", "profile", "valueUri", "valueUrl",
                  "valueCanonical", "fullUrl"}
# Literal strings that mean "we had nothing" - the house convention is a data-absent-reason
# extension, never an invented value. Checked only where a placeholder has actually been seen
# or is plausible; ContactPoint.value is the CDAFHIR-005 case.
SENTINEL_VALUES = {"unknown", "unk", "n/a", "na", "none", "no information",
                   "null", "nil", "tbd", "not available", "not applicable"}
SENTINEL_PATHS = {"telecom.value", "address.text"}

# xhtml content models the FHIR validator enforces inside narrative (item 053): these
# elements accept ONLY the listed children, and no bare text. Production CDA narratives
# (refiner footnotes, vendor quirks) can carry inline elements in these positions; the
# transform must re-home them, so any hit here is a transform defect, not input noise.
NARRATIVE_TABLE_CHILDREN = {
    "table": {"caption", "col", "colgroup", "thead", "tfoot", "tbody", "tr"},
    "thead": {"tr"}, "tfoot": {"tr"}, "tbody": {"tr"},
    "colgroup": {"col"}, "tr": {"td", "th"},
}


def check_narrative(div, where, problems):
    """Table-structure legality inside one narrative div (item 053).

    check_elements deliberately skips the XHTML subtree for its ele-1 checks - narrative
    is full of legitimately empty elements - but table STRUCTURE is still ours to get
    right: "Elements of type table at div/table cannot have the following children: span"
    is exactly what the production validator raised. Problem strings carry element names
    only, so they stay stable in the known-issues baseline.
    """
    for el in div.iter():
        if not el.tag.startswith(XHTML_NS):
            continue
        name = el.tag.split("}")[-1]
        allowed = NARRATIVE_TABLE_CHILDREN.get(name)
        if allowed is None:
            continue
        seen = set()
        for child in el:
            cname = child.tag.split("}")[-1]
            if (not child.tag.startswith(XHTML_NS) or cname not in allowed) and cname not in seen:
                seen.add(cname)
                problems.append(
                    f"invalid narrative xhtml: {where} has <{cname}> as a child of <{name}>")
        if any(t and t.strip() for t in [el.text] + [c.tail for c in el]):
            problems.append(f"invalid narrative xhtml: {where} has bare text inside <{name}>")


def check_elements(xml: str, problems: list):
    """ele-1, primitive syntax and house-convention checks over the parsed Bundle.

    Everything here needs to tell a FHIR element from the XHTML inside Composition.text.div,
    so it walks an ElementTree and skips the XHTML namespace entirely. Narrative contains
    hundreds of legitimately empty <br/> and <td/> elements; treating those as ele-1
    violations would bury the real findings.

    Problem strings are shaped ResourceType.path so they stay stable in the known-issues
    baseline - no values that vary run to run.
    """
    try:
        root = ET.fromstring(xml)
    except ET.ParseError as e:  # the regex checks above already ran; report and move on
        problems.append(f"bundle is not well-formed XML: {e}")
        return

    def label(rtype: str, path: list) -> str:
        return f"{rtype or 'Bundle'}.{'.'.join(path)}" if path else (rtype or "Bundle")

    def walk(elem, rtype, path):
        for child in elem:
            if child.tag.startswith(XHTML_NS):
                # narrative - not FHIR elements, so the ele-1 checks skip the subtree,
                # but its table structure is still checked (item 053)
                check_narrative(child, label(rtype, path + [child.tag.split("}")[-1]]),
                                problems)
                continue
            name = child.tag.split("}")[-1]
            # entering a resource: <entry><resource><Patient> -> rtype becomes Patient, and the
            # path restarts so problem strings read Patient.contact.address, not
            # Bundle.entry.resource.Patient.contact.address
            if rtype is None and elem.tag == FHIR_NS + "resource":
                child_rtype, child_path = name, []
            else:
                child_rtype, child_path = rtype, path + [name]
            where = label(child_rtype, child_path)
            value = child.get("value")
            has_children = len(child) > 0
            has_text = bool((child.text or "").strip())

            # --- ele-1: every element must have @value or children ---------------------
            if value == "":
                problems.append(f"empty primitive value: {where} has value=\"\"")
            elif value is None and not has_children and not has_text:
                if name == "extension":
                    # ext-1 as well: an extension must have value[x] or sub-extensions
                    problems.append(
                        f"empty extension: {where} url={child.get('url')} has no value[x] "
                        f"and no sub-extensions")
                elif not child.attrib:
                    problems.append(f"empty element: {where} has no value and no children")

            if value:
                # --- code primitive syntax --------------------------------------------
                if name in CODE_PRIMITIVES:
                    if value != value.strip():
                        problems.append(
                            f"invalid code primitive: {where} value has leading/trailing "
                            f"whitespace (FHIR code regex forbids it)")
                    elif re.search(r"\s\s|\t|\n", value):
                        problems.append(
                            f"invalid code primitive: {where} value contains repeated or "
                            f"non-space whitespace")
                    elif " " in value:
                        # legal per the regex, but in this pipeline it is the signature of a
                        # value path that space-joined a multi-node selection (CDAFHIR-016)
                        problems.append(
                            f"suspect code primitive: {where} value contains a space - "
                            f"possible space-joined multi-node selection")
                # --- uri primitive syntax ---------------------------------------------
                if name in URI_PRIMITIVES and re.search(r"\s", value):
                    problems.append(f"invalid uri primitive: {where} value contains whitespace")
                # --- placeholder strings where DAR is the convention ------------------
                tail = ".".join(child_path[-2:]) if child_path else ""
                if tail in SENTINEL_PATHS and value.strip().lower() in SENTINEL_VALUES:
                    problems.append(
                        f"placeholder value: {where} is the literal string '{value}' - "
                        f"the convention for absent data is a data-absent-reason extension")

            # --- v3-NullFlavor coding where DAR is the convention ---------------------
            if name == "system" and value == NULLFLAVOR_SYSTEM:
                parent = label(child_rtype, child_path[:-1])
                problems.append(
                    f"v3-NullFlavor coding: {parent} carries a NullFlavor code - the "
                    f"convention for absent data is a data-absent-reason extension")

            walk(child, child_rtype, child_path)

    walk(root, None, [])


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
