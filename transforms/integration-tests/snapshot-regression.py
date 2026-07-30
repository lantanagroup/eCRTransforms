#!/usr/bin/env python3
"""
snapshot-regression.py - layer 4 of the eCRTransforms testing suite.

20260729 Claude: Created. Runs a corpus of CDA documents through the cda2fhir-r4 pipeline,
normalises the parts of the output that legitimately vary between runs, and compares the
result against committed snapshots. Any difference is reported as a unified diff plus a
resource-inventory delta, and exits 1.

    python snapshot-regression.py                 # compare against committed snapshots
    python snapshot-regression.py --update        # rewrite snapshots from this run
    python snapshot-regression.py --filter testRR # only documents whose name contains this

Where this fits
---------------
The other three layers each answer a *specific* question:

    XSpec              does this template still do what I said it does?
    run-integration    is the Bundle structurally sound (references resolve, required
                       elements present, statuses in range)?
    validate-fhir      does the Bundle conform to the published eCR IG?

This layer answers the one they cannot: **did anything change that I did not intend?**
It has no opinion about correctness. That is the point - it catches the changes nobody
thought to write an assertion for, which is exactly the class of thing that bit us on
2026-07-29 (widening a template match silently altered an unrelated document).

It earns its keep on the real documents in samples/, which are far messier than the
synthetic fixtures and exercise combinations nobody would think to write by hand.

Normalisation
-------------
Two things vary without the output meaning anything different.

1. **Minted UUIDs.** NativeUUIDGen mints RFC-4122 v1 timestamp UUIDs, so every `urn:uuid`
   differs on every execution. Replaced with sequential labels (UUID000, UUID001, ...) in
   order of first appearance, which is stable because document order is stable.

2. **`generate-id()` output**, in two places: `Bundle.id` (`{IG}-bundle-{generate-id(...)}`)
   and the narrative section-title anchors `<a name="{generate-id($title)}">` (RR only, since
   structuredBody narrative is rendered only for RR).
   Saxon's `generate-id()` is stable for a given stylesheet and input, but the value shifts
   whenever the *stylesheet* changes, because it derives from the node's position in the
   compiled document pool. Left alone, every edit to any XSLT file would produce phantom
   diffs in every document and bury the real signal. Both are masked.

   (The narrative anchor is currently unreferenced - nothing links to it - so removing it from
   cda2fhir-Narrative.xslt would eliminate the volatility at source. Left in place as the more
   conservative choice; masking it here costs nothing.)

Both were established empirically, and the second one the hard way: two consecutive runs of
the same input differ by 136 lines (small fixture) and 532 lines (236 KB real eICR) raw, and
by zero after UUID normalisation - but that test used an unchanged stylesheet, so it missed
`Bundle.id` entirely. The negative control (revert a fix, confirm the diff is detected) is
what exposed it, by flagging eleven documents that had nothing to do with the reverted fix.
The narrative anchor then surfaced the same way on the second attempt.

If phantom diffs ever reappear, widen `normalise()` - do not relax the comparison. And be
suspicious of a negative control that changes *more* than the fix could plausibly touch;
that is the signature of a normalisation gap rather than a real regression.

Note the useful side effect: because the labels are assigned in document order, inserting a
new resource renumbers everything after it. That makes the diff noisier but is honest - a
new bundle entry IS a change to the document.

The corpus
----------
`snapshot-corpus.txt`, one glob per line, relative to the repo root; `#` comments ignored.
Add real documents from samples/ freely - the messier the better. Snapshots live in
`snapshots/` and MUST be committed; they are the baseline.

Discipline
----------
`--update` accepts whatever the pipeline currently emits. Read the diff first. A snapshot
diff is not a failure, it is a question: "you changed 40 lines of an eICR you were not
working on - did you mean to?" Most of the time the answer is yes and you update. The one
time it is no, this script has paid for itself.
"""
import argparse
import difflib
import re
import sys
from collections import Counter
from pathlib import Path

try:
    from saxonche import PySaxonProcessor
except ImportError:
    sys.exit("saxonche is required:  pip install saxonche")

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent                      # transforms/integration-tests -> transforms -> repo
STYLESHEET = HERE.parent / "cda2fhir-r4" / "NativeUUIDGen-cda2fhir.xslt"
SNAPSHOTS = HERE / "snapshots"
CORPUS = HERE / "snapshot-corpus.txt"

UUID_RE = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)
# Two generate-id() sites. Saxon's generate-id() is stable for a given stylesheet+input but
# shifts whenever the STYLESHEET changes, so both must be masked or every XSLT edit produces
# phantom diffs. Output looks like "d744e168".
#   1. <id value="eICR-bundle-d193e5"/>          cda2fhir-Bundle.xslt
#   2. <a name="d744e168">                       cda2fhir-Narrative.xslt section titles (RR only)
# Keep the IG prefix on the Bundle id - that part is a genuine signal.
BUNDLE_ID_RE = re.compile(r'(<id value="[A-Za-z]*-bundle-)[^"]*(")')
GENERATED_ANCHOR_RE = re.compile(r'(<a name=")d\d+e\d+(")')
RESOURCE_RE = re.compile(r"<resource>\s*(?:<!--.*?-->\s*)*<(\w+)[ >]", re.S)


def normalise(xml: str) -> str:
    """Mask the parts of the output that vary without meaning (see module docstring)."""
    seen: dict[str, str] = {}

    def label(m):
        return seen.setdefault(m.group(0), "UUID%03d" % len(seen))

    xml = UUID_RE.sub(label, xml)
    xml = BUNDLE_ID_RE.sub(r"\1GENID\2", xml)
    return GENERATED_ANCHOR_RE.sub(r"\1GENID\2", xml)


def load_corpus() -> list[Path]:
    if not CORPUS.exists():
        sys.exit(f"corpus file not found: {CORPUS}")
    docs: list[Path] = []
    for raw in CORPUS.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        matches = sorted(REPO.glob(line))
        if not matches:
            print(f"  ! corpus pattern matched nothing: {line}", file=sys.stderr)
        docs.extend(m for m in matches if m.is_file())
    # de-duplicate, keep order
    seen, out = set(), []
    for d in docs:
        if d not in seen:
            seen.add(d)
            out.append(d)
    return out


def snapshot_path(doc: Path) -> Path:
    """Flatten the repo-relative path so snapshots from different directories cannot collide."""
    try:
        rel = doc.resolve().relative_to(REPO)
    except ValueError:
        rel = Path(doc.name)
    return SNAPSHOTS / (str(rel).replace("/", "__").replace("\\", "__"))


def inventory_delta(old: str, new: str) -> list[str]:
    """Resource-type counts that changed - the most readable summary of a diff."""
    a, b = Counter(RESOURCE_RE.findall(old)), Counter(RESOURCE_RE.findall(new))
    return [
        "%s %d -> %d" % (k, a[k], b[k]) for k in sorted(set(a) | set(b)) if a[k] != b[k]
    ]


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--update", action="store_true",
                   help="rewrite snapshots from this run instead of comparing")
    p.add_argument("--filter", default="",
                   help="only process documents whose filename contains this substring")
    p.add_argument("--context", type=int, default=2, help="diff context lines (default 2)")
    p.add_argument("--max-diff-lines", type=int, default=40,
                   help="truncate each document's diff after this many lines (0 = unlimited)")
    args = p.parse_args()

    docs = [d for d in load_corpus() if args.filter in d.name]
    if not docs:
        sys.exit(f"no corpus documents matching '{args.filter}'")
    SNAPSHOTS.mkdir(parents=True, exist_ok=True)

    changed, new, failed = [], [], []
    with PySaxonProcessor(license=False) as proc:
        xslt = proc.new_xslt30_processor()
        exe = xslt.compile_stylesheet(stylesheet_file=str(STYLESHEET))
        for doc in docs:
            snap = snapshot_path(doc)
            try:
                out = normalise(exe.transform_to_string(source_file=str(doc)))
            except Exception as e:  # noqa: BLE001 - a transform error is a regression too
                failed.append((doc.name, str(e)))
                print(f"ERROR    {doc.name}: {e}")
                continue

            if args.update:
                snap.write_text(out, encoding="utf-8")
                continue

            if not snap.exists():
                new.append(doc.name)
                print(f"NEW      {doc.name}  (no snapshot yet - run --update to record it)")
                continue

            before = snap.read_text(encoding="utf-8")
            if before == out:
                print(f"ok       {doc.name}")
                continue

            changed.append(doc.name)
            print(f"CHANGED  {doc.name}")
            for line in inventory_delta(before, out):
                print(f"           resources: {line}")
            diff = list(difflib.unified_diff(
                before.splitlines(), out.splitlines(),
                fromfile="snapshot", tofile="current", n=args.context, lineterm=""))
            shown = diff if args.max_diff_lines == 0 else diff[: args.max_diff_lines]
            for line in shown:
                print("           " + line[:160])
            if len(diff) > len(shown):
                print(f"           ... {len(diff) - len(shown)} more diff lines "
                      f"(--max-diff-lines 0 for all)")

    if args.update:
        print(f"\nsnapshots written for {len(docs)} document(s) -> {SNAPSHOTS}")
        print("REVIEW THE DIFF before committing - --update accepts regressions silently.")
        return 0

    print(f"\n{len(docs) - len(changed) - len(new) - len(failed)}/{len(docs)} unchanged")
    if failed:
        print(f"{len(failed)} document(s) failed to transform")
    if new:
        print(f"{len(new)} document(s) have no snapshot yet")
    if changed:
        print(f"{len(changed)} document(s) changed: {', '.join(changed)}")
        print("\nIf these changes are intended, re-run with --update and commit the snapshots.")
    return 1 if (changed or failed or new) else 0


if __name__ == "__main__":
    sys.exit(main())
