# CDA → FHIR integration tests

Full-pipeline tests for the cda2fhir-r4 transforms. Each synthetic eICR document in
`documents/` runs through the complete pipeline (`NativeUUIDGen-cda2fhir.xslt`, so
Saxon-HE works — no license needed) and the output Bundle is checked against structural
invariants that must hold for **any** input:

1. Well-formed output with at least one bundle entry.
2. Every `urn:uuid:` reference resolves to a `fullUrl` in the Bundle (no dangling references).
3. No empty references.
4. Required elements present per resource type (status, intent, subject, …).
5. Status-like elements only carry values from their FHIR value sets
   (catches raw CDA ActStatus codes leaking through).
6. FHIR invariant con-5 (no Condition with clinicalStatus + verificationStatus entered-in-error).

These complement the XSpec unit tests (`../cda2fhir-r4/xspec-unit-tests/`): XSpec pins
individual template behavior; these catch cross-file wiring bugs — dangling references,
bundle-entry fan-out gaps, template-priority collisions — that only appear when the whole
pipeline runs. Several 2026-07 defects (dangling Encounter author references, empty
`urn:uuid:` refs, Product Instances emitted as PractitionerRole, RR agencies dropped
entirely) were found exactly this way.

This layer is also the only place some fixes *can* be tested. Anything that depends on
`$gvCurrentIg` — every `get-profile-for-ig` profile choice, the RR-only narrative paths — needs
a whole ClinicalDocument to resolve, so it is out of reach of a bare-fragment XSpec scenario.
When a fix is IG-dependent, the regression test belongs here rather than in XSpec.

## Running

```
pip install saxonche          (once)
python run-integration-tests.py                  # all documents
python run-integration-tests.py testMed          # documents matching a substring
python run-integration-tests.py --output output/ # also write the Bundles for VALIDATION.md
```

Exit code 0 = all pass. History: created 2026-07-29 (Claude); all 9 documents pass
against the transforms as of that date.

`--output` writes each Bundle to `<dir>/<document-stem>.xml`. That directory is what
`validate-fhir-outputs.py` consumes — see `VALIDATION.md` for the conformance layer that
sits on top of these structural checks.

### Fixture realism

These documents are synthetic, but they are checked against the published eCR IG, so they
have to be *conformant* synthetic — a fixture that is itself invalid makes the conformance
gate meaningless. Concretely (all corrected 2026-07-29 after the first real validator run):
every document carries a `componentOf/encompassingEncounter` (eICR requires one, and
`eicr-composition` requires `Composition.encounter` 1..1); facility locations carry a
`code` and an `addr` (`us-ph-location` requires `type` and `address`); addresses are US
addresses with USPS state codes; and `displayName` strings match the terminology, since the
pipeline passes source displays straight through. Keep new fixtures to that standard.

## The documents

Small, targeted synthetic eICRs — one or two scenarios each, fixed resource ids so
failures are traceable:

| Document | Exercises |
|---|---|
| test-cda.xml | Baseline eICR: header participants, Patient (race/ethnicity/birthplace), encounters |
| testB.xml | Patient extensions, birth sex / gender identity, deceased handling, ODH occupation → employer Organization (odh-Employer-extension must resolve) |
| testCT.xml | Care Team organizer (statuses, participant roles), PractitionerRole |
| testCond.xml | Problem section, Condition statuses, trigger-code observation, Family History |
| testSR.xml | Planned procedure/observation → ServiceRequest (status + intent mapping), orders |
| testProc.xml | Procedures (status fallback), SDL Locations, Product Instance 4.37 → Device |
| testMed.xml | Medication activities EVN/INT → MedicationAdministration/Request/Dispense |
| testCov.xml | Payers section → Coverage (status mapping, subscriberId) |
| testFinal.xml | Allergies (clinicalStatus map), Goals (lifecycleStatus, Entry Reference), Interventions (RequestGroup actions, nested Instruction → Communication partOf), FMH |
| testRR.xml | **Reportability Response (RR R1.1)** — the three RR agency LOC participants → `rr-*-organization`, Reportability Information Organizer tree (determination + reason + rule, reporting timeframe, external resources), eICR Processing Status with reason and reason-details components, Received eICR → DocumentReference, RR Summary act, information-recipient extension, and an unrecognised LOC participant exercising the generic LOC → Organization fallback |

## Snapshot regression (layer 4)

`snapshot-regression.py` runs a corpus of CDA documents through the pipeline, normalises the
parts of the output that vary without meaning, and compares against committed snapshots in
`snapshots/`. It has no opinion about correctness — it answers the question the other layers
cannot: **did anything change that I did not intend?**

```
python snapshot-regression.py            # compare; exit 1 on any difference
python snapshot-regression.py --update   # rewrite snapshots (READ THE DIFF FIRST)
python snapshot-regression.py --filter testRR
```

The corpus is `snapshot-corpus.txt` — globs relative to the repo root, `#` comments ignored.
It is seeded with the fixtures plus three real documents from `samples/`; **adding more real
samples is the single highest-value thing you can do to this layer**, since they exercise
combinations nobody would write by hand. Adding a line costs one `--update` and the disk
space of the snapshot.

`snapshots/` is committed on purpose — it *is* the baseline. This is the one generated
artefact in the repo that belongs in git (unlike the XSpec result HTML, which does not).

Two things are normalised, both established empirically: minted `urn:uuid` values, and
`generate-id()` output (`Bundle.id`, and the RR narrative section-title anchors).
`generate-id()` is stable for a given stylesheet but shifts whenever the *stylesheet*
changes — leave it unmasked and every XSLT edit produces phantom diffs in every document.
See the module docstring; if phantom diffs appear, widen `normalise()` rather than relaxing
the comparison.

A snapshot diff is a question, not a verdict: "you changed 40 lines of an eICR you were not
working on — did you mean to?" Usually yes, and you update. The one time it is no, the layer
has paid for itself.

## Adding a regression document

Reproduce the bug in a *minimal* synthetic eICR, drop it in `documents/`, and confirm the
runner fails before your fix and passes after. If the document introduces a resource type
not yet listed in `REQUIRED_ELEMENTS` / `STATUS_VALUE_SETS` in the runner, add it there.
Document-level wiring fixes that XSpec can't cover (RelatedPerson/Patient pairing,
Encounter author bundle entries, DocumentReference setId handling, the
encompassingEncounter-reference guard) belong here.
