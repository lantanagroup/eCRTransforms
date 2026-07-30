# Conformance validation layer (testing suite step 3)

Sits on top of `run-integration-tests.py`. That harness checks *structural*
invariants Claude/we defined (references resolve, required elements present,
status values in range). This layer checks conformance against the **published
IGs** — the FHIR validator with the eCR FHIR IG for cda2fhir output, and CDA
schema + eICR Schematron for fhir2cda output.

| script | pipeline | checks | gates on |
|---|---|---|---|
| `validate-fhir-outputs.py` | cda2fhir-r4 | `validator_cli.jar` + `hl7.fhir.us.ecr#2.1.2` | `error` / `fatal` |
| `validate-cda-outputs.py` | fhir2cda-r4 | `CDA_SDTC.xsd` + eICR Schematron → SVRL | SHALL failures |

Both diff against a checked-in baseline and exit `1` only on **new** problems,
`0` on clean, `2` on harness failure.

---

## Running

```bash
# 1. produce the FHIR bundles
python run-integration-tests.py --output output/

# 2. conformance-check them (first run downloads validator_cli.jar, ~180 MB)
python validate-fhir-outputs.py --input output/

# 3. the CDA direction, once you have fhir2cda output
python validate-cda-outputs.py --input output-cda/ \
    --schema        /path/to/CDA_SDTC.xsd \
    --schematron-xsl /path/to/eicr_validator.xsl
```

Paths can live in the environment instead: `ECR_VALIDATOR_JAR`,
`ECR_CDA_SCHEMA`, `ECR_CDA_SCHEMATRON_XSL`, `ECR_SAXON_JAR`.

Prerequisites: Java 17/21/25 for the FHIR side; `saxonche` (already a dependency
of `run-integration-tests.py`) or a Saxon jar for the Schematron side; `xmllint`
if present, otherwise lxml does the schema pass.

Add to `.gitignore`:

```
transforms/integration-tests/validator_cli.jar
transforms/integration-tests/.txcache/
transforms/integration-tests/.svrl/
```

### Baseline discipline

The baselines (`fhir-validation-baseline.json`, `cda-validation-baseline.json`)
are the list of violations we *knowingly tolerate*. Each entry has an empty
`note` field — fill it in with why, otherwise the file rots into "errors we
stopped looking at".

`--update-baseline` rewrites the file from the current run, which silently
accepts anything new. Always read the diff before committing.

`--no-baseline` ignores the file entirely: every error fails. Useful when you
want the unvarnished picture.

---

## What the first run turned up

Before pointing this at transform output I ran it over the **eCR IG's own
published examples** (`Bundle-bundle-eicr-document-zika.json` and
`Bundle-bundle-rr-document-one-cond-one-pha.json` from `hl7.fhir.us.ecr#2.1.2`),
as a control. Validator 6.9.12 (2026-07-15), FHIR 4.0.1, `tx.fhir.org`.

| file | error | warning | information |
|---|---|---|---|
| `Bundle-bundle-rr-document-one-cond-one-pha.json` | 0 | 34 | 52 |
| `Bundle-bundle-eicr-document-zika.json` | **6** | 23 | 61 |

The RR example is clean. The eICR example is not, and the six errors are worth
understanding before they show up in our output.

### Finding 1 — stale LOINC section displays (5 of the 6 errors)

The eICR Composition carries section code displays that LOINC has since
retired. LOINC renamed the document-section terms from `... Narrative` to
`... note`; the IG example still has the old strings.

| code | in the IG example | current LOINC display |
|---|---|---|
| 30954-2 | Relevant diagnostic tests/laboratory data Narrative | Relevant diagnostic tests/laboratory data note |
| 11369-6 | History of Immunization Narrative | History of Immunization note |
| 8716-3  | Vital signs | Vital signs note |
| 29762-2 | Social history Narrative | Social history note |
| 11348-0 | History of Past illness Narrative | History of Past illness note |

Current displays confirmed by `$lookup` against `tx.fhir.org` (LOINC **2.82**).
`loinc.org` term pages are JS-rendered and won't fetch from a script, so this is
one hop from the primary source — worth a spot-check in the LOINC search UI
before anything gets hard-coded on the strength of it.

**Why this matters for us.** Two places in the codebase emit section code
displays and are candidates for exactly the same drift:

* `cda2fhir-Composition.xslt` — synthesises the 7 required eICR sections when
  missing, with LOINC codes and hard-coded displays.
* `code-display-mapping.xml` (95 rows) — the display-correction table, keyed on
  bare code across all code systems.

If either carries the `Narrative` spelling, every bundle we emit inherits five
errors. Grep for `Narrative` in both before the first real run.

Note the trap in hard-coding *any* display: it pins us to one LOINC version.
The durable options are to omit `display` (it is optional), or to accept the
churn and re-check whenever the terminology moves.

### Finding 2 — the sixth error is a cascade, not a real one

```
Slice 'Bundle.entry:slicePublicHealthComposition': a matching slice is
required, but not found
```

Read literally this says the bundle has no Composition. It has one, in
`entry[0]`. The slice discriminator is `{"type": "profile", "path": "resource"}`
against `eicr-composition`, and a **profile discriminator only matches if the
candidate resource fully conforms**. The five display errors make the
Composition non-conformant, so it stops matching its own slice, and the
Bundle-level minimum-slice check fires.

Verified: re-running with `-display-issues-are-warnings` drops the display
errors *and* the slice error — 6 errors → 0.

So any single error inside the Composition will produce a phantom "missing
Composition" error alongside it. `validate-fhir-outputs.py` annotates these
`[probable cascade]` when other errors exist in the same file, so nobody spends
an afternoon looking for a Composition that was there the whole time.

`--display-issues-are-warnings` is available as a flag. I'd suggest **not**
using it by default — the display drift is a real defect worth fixing at source
— but it's the right switch when triaging a run where displays are drowning out
everything else.

### Finding 3 — some "errors" are the machine, not the document

One run out of three produced an extra error on the same input:

```
TYPE_SPECIFIC_CHECKS_DT_PRIMITIVE_REGEX_EXCEPTION
Exception evaluating regex '^[\s\S]+$' on type string:
Regex evaluation timed out after ...
```

That is the validator's own regex check timing out on a long narrative string
under CPU pressure, reported at `error` severity and otherwise indistinguishable
from a content error. On a strict baseline diff it would fail CI at random, and
`--update-baseline` would bake a phantom into the file.

The harness classifies these (message id plus a text match on `timed out`,
`OutOfMemory`, connection failures, tx errors) as **environmental**: reported in
their own section, excluded from the baseline, and non-gating unless
`--fail-on-environmental` is passed. Worth knowing when the eventual CI runner
is a small container — narrative-heavy eICRs are exactly the shape that trips it.

---

## The first run against real transform output (2026-07-29)

Nine bundles from `run-integration-tests.py --output output/`, validator 6.9.12, FHIR
4.0.1, `hl7.fhir.us.ecr#2.1.2`, `tx.fhir.org`.

| run | errors | what changed |
|---|---|---|
| baseline | **48** | as-is |
| after two transform fixes | 7 | Composition displays, Location identifier/type/profile |
| after fixture corrections | **0** | fixtures made conformant |

**Two genuine transform defects**, both invisible to the structural harness because the
output was well-formed and fully wired — only the IG knew it was wrong:

1. *Stale LOINC section displays.* Exactly as predicted in Finding 1 below, and exactly two
   of the seven synthesised sections had drifted: `30954-2` and `29762-2` both moved from
   `... Narrative` to `... note`. 18 of the 48 errors, plus most of the phantom
   "no matching Composition slice" cascades. The other five synthesised displays, and the
   four `Narrative` rows in `code-display-mapping.xml`, are still current in LOINC 2.82 —
   worth knowing that the grep-for-`Narrative` heuristic over-selects.

2. *Service Delivery Location (4.32) participants.* `us-ph-location` requires
   `identifier` 1..\* and `type` 1..\*; the participant body template in
   `cda2fhir-Location.xslt` mapped neither, and called `add-meta` on the participant, whose
   templateId actually sits on the `participantRole` — so the Location came out with no
   `meta.profile` and a "No profiles found" comment listing nothing. The knock-on: because
   `eicr-encounter` constrains `Encounter.location.location` to `us-ph-location`, the
   Encounter's own reference failed to match, which in turn cost the Encounter its
   `eicr-encounter` match, which cost `Composition.encounter` *its* match. One dropped
   element, four errors. Profile resolution now goes through `get-profile-for-ig`, since
   4.32 is a plain C-CDA template that should map to `us-core-location` outside eCR.

**The other 41 errors were the fixtures, not the pipeline** — which is its own finding. The
documents had no `encompassingEncounter` at all (so no `Composition.encounter`, required
1..1), facility locations with neither `code` nor `addr`, an OID of `9.8.7.6`, Australian
addresses, and `displayName` strings that did not match their codes. The transform was
faithfully carrying all of it through. A conformance gate is only as good as its fixtures;
see "Fixture realism" in `README.md`.

Negative control: reverting the two fixes and re-running takes the gate from exit 0 to exit
1 with the same three errors it originally reported, so the gate demonstrably bites.

### One caveat found while confirming the green run

Re-running the identical inputs produced, once in three, a single extra error:

```
Reference_REF_CantMatchChoice  at Bundle.entry[13].resource.subject
Unable to find a profile match for urn:uuid:... among choices: .../us-core-patient
```

It did not reproduce on the next run. The mechanism is the cascade described in Finding 2:
a profile-discriminated *reference* only matches if the target validates cleanly, and
whether the Patient validates cleanly depends on terminology lookups. A slow or partial `tx`
response can therefore turn into what reads as a structural reference error.

This is deliberately **not** added to `ENVIRONMENTAL_MSGIDS`. `Reference_REF_CantMatchChoice`
is exactly how the Service Delivery Location defect above announced itself; suppressing it
would have hidden a real bug to silence a rare flake. The right discipline is the cheaper
one: **re-run once before believing a lone `CantMatchChoice` failure**, and treat it as real
if it survives. A warm `--tx-cache` makes it markedly less likely.

## Extending it to RR (2026-07-29, same day)

Every fixture up to this point was an eICR, so the RR half of cda2fhir had never been through
either gate. Running `samples/cda/RR-R1_1/RR-CDA-001_R1_1.xml` through the pipeline as a
control turned up **four defects**, three of them silent data loss.

| # | defect | symptom |
|---|---|---|
| 1 | RR agency participants dropped | the three `rr-*-organization` resources never emitted |
| 2 | `15.2.3.32` missing from `templates-to-suppress.xml` | 2 dangling section-entry references |
| 3 | `href="#toc"` in section-title narrative | 3 unresolvable hyperlinks in `Composition.text.div` |
| 4 | information-recipient extension referenced a resource that may not exist | dangling reference, and `rr-composition`'s required extension slice unmatched |

Defect 1 is the one worth reading about. The three agency participants (Routing Entity
`15.2.4.1`, Responsible Agency `15.2.4.2`, Rules Authoring Agency `15.2.4.3`) are LOC
participants that also carry a `participantRole`, so in `bundle-entry` mode they matched two
templates at equal default priority: `cda2fhir-Organization.xslt`'s LOC template, which builds
them correctly, and `cda2fhir-PractitionerRole.xslt`'s generic
`cda:participant[cda:participantRole]`, which forwards to a template that emits a
PractitionerRole *only if there is a person*. An agency has no person. Saxon reported
`XTDE0540` and resolved the tie by declaration order, PractitionerRole won, and the agencies
vanished — surviving only as narrative text, which is exactly why nobody noticed. This was
predicted in the codebase notes back on 2026-07-27 ("regression-test RR samples") and sat
unverified until there was an RR fixture.

Defects 3 and 4 are both *conditional* — 3 needs a document with more than one titled section,
4 needs an organization-only information recipient. The real sample has neither, so both were
found by the synthetic fixture being *different* from the sample rather than smaller than it.
Worth remembering when writing fixtures: coverage comes from varying the shape, not just
shrinking it.

Result: real RR sample 2 errors → **0**; new `testRR.xml` fixture **0**; all 9 eICR documents
unchanged at 0. Each fix has a negative control that reverts it and reproduces the original
symptom.

## Finishing the template-priority problem (2026-07-29)

Fixing the RR agencies with a templateId-specific `priority="1"` escape left the underlying
ambiguity in place, so it was worth going back and doing properly. Two things came out of it.

**The fan-out matters as much as the priority.** A LOC participant is only ever *reached* in
`bundle-entry` mode via `cda2fhir-Bundle.xslt`'s global dispatch — which already filters out
`participantRole/@classCode` `SDLOC` and `TERR` — or via a generic `cda:participant` fan-out in
CareTeam / Communication / Observation / RequestGroup. `cda2fhir-Procedure.xslt` fans out to
`4.32` *specifically*, so priority is irrelevant there. Two of my first three probe shapes
emitted nothing not because of the tie but because nothing ever visited them. Worth checking
the fan-out before concluding a priority is at fault.

**Precedence is now explicit** instead of resting on include order:

| priority | file | matches |
|---|---|---|
| 2 | `cda2fhir-Location.xslt` | `15.2.4.4`, and `4.32` on the participantRole |
| 1 | `cda2fhir-Organization.xslt` | any `participant[@typeCode='LOC']` — generic fallback |
| 0 | `cda2fhir-PractitionerRole.xslt` | generic `participant[participantRole]` — no longer reached for LOC |

Widening Organization's LOC match also activated an `<xsl:otherwise>` branch in its body
template that had been unreachable — it already called `add-participant-meta` for the
non-agency case. The code had anticipated this; only the match pattern was too narrow.

**A second defect fell out of the same analysis.** The ODH employer participant
(`observation[4.217]/participant[@typeCode='IND']`) had the identical tie, and Organization is
included *before* PractitionerRole, so PractitionerRole won and no Organization was emitted —
leaving `odh-Employer-extension`'s reference dangling. It was the only dangling reference in
`samples/cda/xspec-test-files/XSPEC_eICR-CDA-001_R3_1.xml`. Also fixed with `priority="1"`, and
now covered by an ODH social-history section in `testB.xml`.

`cda2fhir-RelatedPerson.xslt`'s two participant templates had the same tie but were winning
anyway, purely because that file is included after PractitionerRole. Given explicit priorities
so correctness no longer depends on include order — a deliberate no-op.

**Evidence.** 14 documents (10 fixtures, 3 real samples, 1 probe) transformed before and after
with UUIDs normalised. All XTDE0540 warnings gone (4 → 0). Every document byte-identical except
the probe and the real eICR sample, whose only change is `Organization 8 → 9` — the ODH
employer that was previously dropped. Dangling references across the three real samples: 1 → 0.
Negative control: reverting either priority makes `testB` and `testRR` fail on dangling
references.

### Remaining warnings (eICR: 25 per run; RR: 56 — non-gating)

Nothing here is being treated as a defect, but two are worth a decision rather than a shrug:

* `Encounter.type` is populated from `encompassingEncounter/code`, the same ActCode that
  fills `Encounter.class`. ActCode isn't in `us-core-encounter-type`, so every encounter
  warns. Whether an eICR should carry `Encounter.type` at all is a mapping question.
* `Location.type` carries HSLOC codes, but `us-core-location` binds type to
  `v3-ServiceDeliveryLocationRoleType`. The binding is extensible and HSLOC is what the CDA
  side actually says, so passing it through looks right — but it will always warn.

The rest are `dom-6` (no narrative on contained-style resources),
`BUNDLE_BUNDLE_ENTRY_REVERSE_R4` (entries reachable only backwards from the Composition —
the RelatedPerson/Patient pairing noted in the codebase notes), and best-practice hints
about Observation performer/effective.

---

## Performance

Package loading dominates: **~60 s** per invocation (2 min the very first time,
while ~20 dependency packages download), against **~1–20 s** per file to
validate. Both scripts therefore validate the whole directory in a **single**
invocation. Validating 9 documents one at a time would cost 9 minutes of
loading to do 3 minutes of work.

`--tx-cache` (default `.txcache/`) persists terminology responses between runs
and is worth keeping warm. `--tx n/a` disables terminology entirely: much
faster, but it also silences display checks, code-system membership, and value
set binding — most of what the eCR IG actually constrains. Fine for a smoke
test, not for a gate.

Heap: `--heap` defaults to `4g`. The validator wants ~2 GB for a document bundle
plus the eCR dependency graph.

---

## Not done yet

* **The FHIR side is now green and baselined at zero.** `fhir-validation-baseline.json`
  contains no accepted errors, which is the right starting position: anything that appears
  from here is a regression, not inherited debt. Keep it that way rather than baselining
  the next failure.
* **The CDA side has not been run against real output.** The script is tested
  end-to-end (schema pass via xmllint, Schematron via saxonche, SVRL parsing,
  SHALL/SHOULD split, baseline round-trip, negative control) but against
  synthetic fixtures — I don't have `CDA_SDTC.xsd` or `eicr_validator.xsl` here.
  First real run may need the `--pattern` or SVRL assumptions adjusted.
* **No fhir2cda output directory exists yet.** `run-integration-tests.py` only
  drives cda2fhir. The reverse direction needs its own runner before
  `validate-cda-outputs.py` has anything to chew on — that pairs naturally with
  step 4 (snapshot regression over `samples/`).
* **eCR IG 3.0.0-ballot is published.** Worth a run with
  `--ig hl7.fhir.us.ecr#3.0.0-ballot` to see what's coming, kept out of the gate.
* **CI (step 5)** — both scripts are exit-code clean and take a `--input`, so
  they drop into a workflow as-is once step 4 lands.
