<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:template match="cda:encompassingEncounter" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />

    <xsl:apply-templates select="cda:responsibleParty[not(@nullFlavor)]/cda:assignedEntity[not(@nullFlavor)]" mode="bundle-entry" />
    <xsl:apply-templates select="cda:dataEnterer" mode="bundle-entry" />
    <xsl:apply-templates select="cda:encounterParticipant" mode="bundle-entry" />
    <!-- 20260729 Claude: Fix - the Encounter body emits a participant/individual reference for each author (see the
         author for-each below), but no bundle entry was ever created for them, leaving dangling references -->
    <xsl:apply-templates select="cda:author" mode="bundle-entry" />
    <xsl:apply-templates select="cda:location[not(@nullFlavor)]" mode="bundle-entry" />
    <xsl:apply-templates select="cda:location/cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]" mode="bundle-entry" />

    <!-- Provenance -->
    <xsl:apply-templates select="cda:dataEnterer" mode="provenance" />
    <xsl:apply-templates select="cda:encounterParticipant" mode="provenance" />
  </xsl:template>

  <!-- 20260730 Claude: 4.40 removed from this match and the body match below - Planned Encounter now has
       dedicated templates (see below, per SG's mapping decision). This shared pair keeps 4.49 semantics. -->
  <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']" mode="bundle-entry">
    <!-- Don't want a second encounter if this is eICR -->
    <xsl:if test="$gvCurrentIg != 'eICR'">
      <xsl:call-template name="create-bundle-entry" />
      <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
    </xsl:if>
    <!-- Encounter Diagnosis/Problem Observation -->
    <!-- 20260730 Claude: was a single-level path (entryRelationship/act[4.80]/entryRelationship/observation[4.4]),
         but Encounter Diagnosis acts can NEST (act[4.80]/entryRelationship/act[4.80]/...), and the diagnosis
         REFERENCE side walks //cda:act[4.80] document-deep - so a nested diagnosis observation was referenced but
         its Condition never created (dangling Encounter.diagnosis.condition; found on the 2026-04 Pertussis
         eICRs). Applying bundle-entry to the 4.80 act itself hands descent to the wrapper-unwrap template in
         c-to-fhir-utility.xslt, which recurses through entryRelationship children and reaches every depth. -->
    <xsl:apply-templates
      select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']"
      mode="bundle-entry" />
  </xsl:template>

  <!-- 20260730 Claude: reference-mode counterpart of the eICR skip in the bundle-entry template above. For eICR
       no resource is created for a 4.49 Encounter Activity (the document's Encounter comes from
       encompassingEncounter, and the Encounters section is skipped wholesale), but Composition's section-entry
       hoisting would still emit a reference wherever one appears outside that section - leaving a dangling
       entry. Suppressing the reference here keeps the emit-reference / create-resource pair in step at a single
       point. 4.40 Planned Encounter is deliberately NOT listed: per SG's mapping decision (2026-07-30) it now
       produces an Encounter with status=planned in every IG - see the dedicated templates below. -->
  <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']" mode="reference">
    <xsl:param name="wrapping-elements" />
    <xsl:param name="pElementName">reference</xsl:param>
    <xsl:if test="$gvCurrentIg != 'eICR'">
      <xsl:next-match>
        <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
        <xsl:with-param name="pElementName" select="$pElementName" />
      </xsl:next-match>
    </xsl:if>
  </xsl:template>

  <!-- 20260730 Claude: Planned Encounter (4.40) -> Encounter with status=planned, per SG's mapping decision.
       Rationale (researched against FHIR R4, C-CDA, and the eCR IG):
       - FHIR draws the boundary at booking-vs-care: Appointment models the scheduling process; "Encounter
         instances may exist before the actual encounter takes place to convey pre-admission information" with
         status=planned. C-CDA 4.40's moodCode value set is INT/ARQ/APT/PRMS/PRP - eCR content carries INT
         (intent), which is planned-Encounter semantics, not a booking. APT/ARQ documents could justify an
         Appointment mapping later; none exist in the corpus.
       - Neither the eCR IG nor US Core profiles Appointment; fhir2cda already derives 4.40 FROM Encounter
         resources, so this keeps the round trip symmetric.
       - No meta.profile is claimed: eicr-encounter/us-ph-encounter describe THE eICR encounter (the
         encompassingEncounter's), not a future planned visit. The eicr-document-bundle entry slicing is open.
       These templates take priority over the shared 4.49|4.40 ones and produce a lean planned Encounter for
       every IG (previously: none for eICR - the reference dangled until suppressed earlier today - and a
       misshapen "current encounter"-style resource for other IGs).
       NOT mapped (deliberately, to avoid re-creating the dangling-reference class): the SDLOC location
       participant (no Location resource is created for a bare participantRole here) - candidate for a future
       Encounter.location mapping if the Location side is wired up first. -->
  <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']" mode="bundle-entry" priority="1">
    <xsl:call-template name="create-bundle-entry" />
    <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
    <!-- Planned encounters can still carry Encounter Diagnosis wrappers; unwrap recursively as for 4.49 -->
    <xsl:apply-templates
      select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']"
      mode="bundle-entry" />
  </xsl:template>

  <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']" priority="1">
    <Encounter>
      <xsl:comment>Planned Encounter</xsl:comment>
      <xsl:apply-templates select="cda:id" />
      <!-- moodCode INT/PRMS/PRP/ARQ/APT all describe an encounter that has not started -->
      <status value="planned" />
      <xsl:choose>
        <!-- ActCode / ActEncounterCode codes are class; anything else (e.g. SNOMED) is type, class falls back -->
        <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.5.4'] or cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <!-- 20260804 Claude (CDAFHIR-016 residual): this value path was missed by the 20260804 sweep,
                 which only covered the encompassingEncounter choose below. It selected cda:code/@code with
                 neither the codeSystem filter its own when-test uses nor the (...)[1] positional guard its
                 sibling translation path already has - the exact space-joining shape 016 set out to
                 eliminate. cda:encounter/code is 1..1 in C-CDA so no corpus document trips it today; fixed
                 for shape, and expected to be a no-op on every snapshot. -->
            <code value="{(cda:code[@codeSystem = ('2.16.840.1.113883.5.4', '2.16.840.1.113883.1.11.13955')])[1]/@code}" />
          </class>
        </xsl:when>
        <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4'] or cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{cda:code/cda:translation[@codeSystem = ('2.16.840.1.113883.5.4', '2.16.840.1.113883.1.11.13955')][1]/@code}" />
          </class>
        </xsl:when>
        <xsl:otherwise>
          <!-- 20260804 Claude (CDAFHIR-051): was a v3-NullFlavor NI coding. Encounter.class is 1..1 with a
               REQUIRED binding to ActEncounterCode, and a required binding admits no code outside the value
               set - so NI was a hard conformance failure, not a null (and class is a plain Coding, so there
               is no CodeableConcept.text escape hatch either). Live on the Planned Encounter of a COVID
               corpus document whose 4.40 code is SNOMED 270427003: the SNOMED code is correctly routed to
               Encounter.type just below, so class genuinely has no source. Emitting the data-absent-reason
               extension instead, per the convention used for Location.name (item 42). DAR code "unknown"
               matches what c-to-fhir-utility maps NI to, so the intended semantics are preserved. -->
          <class>
            <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
              <valueCode value="unknown" />
            </extension>
          </class>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:for-each select="cda:code[not(@codeSystem = ('2.16.840.1.113883.5.4', '2.16.840.1.113883.1.11.13955'))]">
        <xsl:call-template name="newCreateCodableConcept">
          <xsl:with-param name="pElementName" select="'type'" />
          <xsl:with-param name="pIncludeCoding" select="true()" />
          <xsl:with-param name="includeTranslations" select="true()" />
        </xsl:call-template>
      </xsl:for-each>
      <xsl:call-template name="subject-reference" />
      <xsl:if test="cda:effectiveTime[@value | cda:low/@value]">
        <period>
          <xsl:choose>
            <xsl:when test="cda:effectiveTime/@value">
              <start value="{lcg:cdaTS2date(cda:effectiveTime/@value)}" />
            </xsl:when>
            <xsl:otherwise>
              <start value="{lcg:cdaTS2date(cda:effectiveTime/cda:low/@value)}" />
              <xsl:if test="cda:effectiveTime/cda:high/@value">
                <end value="{lcg:cdaTS2date(cda:effectiveTime/cda:high/@value)}" />
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </period>
      </xsl:if>
      <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
        <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
          <diagnosis>
            <condition>
              <xsl:apply-templates select="." mode="reference" />
            </condition>
          </diagnosis>
        </xsl:for-each>
      </xsl:for-each>
    </Encounter>
  </xsl:template>

  <xsl:template
    match="cda:encompassingEncounter[not(@nullFlavor)] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']">
    <Encounter>
      <xsl:choose>
        <xsl:when test="$gvCurrentIg = 'eICR'">
          <xsl:call-template name="add-participant-meta" />
          <!-- For eICR we need to grab the Encounter section text -->
          <text>
            <xsl:choose>
              <xsl:when
                test="count(//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:entry) = count(//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:entry[@typeCode = 'DRIV'])">
                <status value="generated" />
              </xsl:when>
              <xsl:otherwise>
                <status value="additional" />
              </xsl:otherwise>
            </xsl:choose>
            <div xmlns="http://www.w3.org/1999/xhtml">
              <xsl:apply-templates select="//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:text" />
              <p>...</p>
            </div>
          </text>
        </xsl:when>
        <xsl:otherwise>
          <!-- set meta profile based on Ig -->
          <xsl:choose>
            <xsl:when test="$gvCurrentIg = 'NA'">
              <xsl:call-template name="add-meta" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="vProfileValue">
                <xsl:call-template name="get-profile-for-ig">
                  <xsl:with-param name="pIg" select="$gvCurrentIg" />
                  <xsl:with-param name="pResource" select="'Encounter'" />
                </xsl:call-template>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$vProfileValue ne 'NA'">
                  <meta>
                    <profile>
                      <xsl:attribute name="value">
                        <xsl:value-of select="$vProfileValue" />
                      </xsl:attribute>
                    </profile>
                  </meta>
                </xsl:when>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:otherwise>
      </xsl:choose>

      <!-- SG 20260629: Removing code that limits this to one encounter id
           2026 version of eICR Encounter has been updated to allow multiple identifiers
           eICR Validation will fail if using an earlier version -->
      <!-- Note, there are also ids on the other Encounters.
        If this is eCR get the id from other encounters in the CDA-->
      <!-- 20260824 Claude (per SG): the encompassingEncounter and the Encounter Activity (4.49) /
           Encounter Diagnosis act (4.80) routinely carry the SAME id (seen live in the TN eICR:
           root 2.16.840.1.113883.19.1614.88 / extension 9044494381677, once bare and once with
           assigningAuthorityName EPIC), which emitted two DUPLICATE identifiers. Identifiers are
           duplicates when their mapped (system, value) match - i.e. same @root (case-blind; uuid
           roots are lowercased by the id template) and same @extension (case-SENSITIVE, item 002).
           One identifier is emitted per unique pair. The assigner does not distinguish duplicates,
           but survives the merge: within a group, the first id that carries an
           assigningAuthorityName is the one transformed (so its assigner is kept; when several
           disagree, the first wins - SG's rule); with no assigner anywhere, the first id wins.
           TRULY distinct identifiers still all emit: the profile's max-1 error on those is
           tolerated until the balloting IG version (which allows multiples) lands. -->
      <xsl:comment select="'INFO: Ids from encompassingEncounter + Encounter Activity / Encounter Diagnosis acts, deduplicated by (system, value)'" />
      <xsl:variable name="vBodyEncounterIds"
        select="(//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'] | //cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80'])/cda:id" />
      <xsl:variable name="vEncounterIds" select="cda:id | $vBodyEncounterIds[$gvCurrentIg = 'eICR']" />
      <xsl:for-each-group select="$vEncounterIds" group-by="concat(lower-case(@root), '||', @extension)">
        <xsl:apply-templates select="(current-group()[@assigningAuthorityName][1], .)[1]" />
      </xsl:for-each-group>

      <xsl:if test="local-name(.) eq 'encounter'">
        <xsl:choose>
          <xsl:when test="@moodCode = 'EVN'">
            <status value="finished" />
          </xsl:when>
          <xsl:when test="@moodCode = 'INT' or @moodCode = 'RQO'">
            <status value="planned" />
          </xsl:when>
          <xsl:otherwise>
            <status value="unknown" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <!-- Added to deal with status of encompassingEncounter -->
      <xsl:if test="local-name(.) eq 'encompassingEncounter'">
        <!-- Use times to find out the status of the encounter -->
        <xsl:choose>
          <xsl:when test="not(cda:effectiveTime)">
            <status value="unknown" />
          </xsl:when>
          <!-- 20260803 Claude (item 44/CDAFHIR-017): was cda:effectiveTime/cda:high (existence) -
               a <high nullFlavor="UNK"/> means the end is UNKNOWN, not that the encounter finished.
               Now requires an actual @value; the nullFlavor case falls through to in-progress. -->
          <xsl:when test="cda:effectiveTime/cda:high/@value">
            <status value="finished" />
          </xsl:when>
          <xsl:otherwise>
            <status value="in-progress" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <!-- RG: If any code or translation is from the ActCode code system, use that to populate class, otherwise make it a nullFlavor -->
      <!-- 20260803 Claude (CDAFHIR-016): three repairs to this choose, behavior preserved for the
           single-encounter documents that dominate the corpus:
           1. Encounter.class is 1..1 - every value path is now wrapped (...)[1]. The old paths selected
              EVERY matching code and the attribute value template space-joined them into one invalid
              code when a document carried several Encounter Activities.
           2. The translation value paths now carry the same codeSystem filter as their tests - the old
              paths took every translation, so a code with a second non-ActCode translation joined both.
           3. The document-wide Encounter Activity fallbacks are now gated on eICR. In eICR the 4.49
              activities are deduplicated INTO this encounter (the 2026-07-30 mapping decision, same
              model as SG's 20260629 identifier merge), so borrowing their class is intentional there.
              In any other document type the 4.49s are separate Encounter resources, and borrowing one
              encounter's class for another was a data leak. -->
      <xsl:choose>
        <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.5.4']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(cda:code[@codeSystem = '2.16.840.1.113883.5.4'])[1]/@code}" />
          </class>
        </xsl:when>
        <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4'])[1]/@code}" />
          </class>
        </xsl:when>
        <!-- also check encounter -->
        <xsl:when test="$gvCurrentIg = 'eICR' and //cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955'])[1]/@code}" />
          </class>
        </xsl:when>
        <xsl:when test="$gvCurrentIg = 'eICR' and //cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4'])[1]/@code}" />
          </class>
        </xsl:when>
        <!-- MD: add for ambulatory encounter-->
        <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955'])[1]/@code}" />
          </class>
        </xsl:when>
        <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955'])[1]/@code}" />
          </class>
        </xsl:when>
        <!-- Also check encounter -->
        <xsl:when test="$gvCurrentIg = 'eICR' and //cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
          <class>
            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
            <code value="{(//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955'])[1]/@code}" />
          </class>
        </xsl:when>
        <xsl:otherwise>
          <!-- 20260804 Claude (CDAFHIR-051): was a v3-NullFlavor NI coding (the 20260729 note below fixed
               the display spelling but left the underlying violation). Encounter.class is 1..1 with a
               REQUIRED binding to ActEncounterCode, so NI was a conformance failure rather than a null.
               Live on the eICR External Encounter shape: encompassingEncounter/code PHC2237 is a PHIN VS
               local code with no translations and no ActEncounterCode anywhere in the document - the
               absence of a class is the entire point of an External Encounter, so every document using
               PHC2237 lands here. Data-absent-reason instead, per the Location.name convention (item 42);
               "unknown" is what c-to-fhir-utility already maps NI to. ("not-applicable" is arguably
               better for PHC2237 specifically, but distinguishing it would mean special-casing that code
               and "unknown" is defensible for both paths - noted as an open question, not a residual.) -->
          <class>
            <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
              <valueCode value="unknown" />
            </extension>
          </class>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:for-each select="cda:code[not(@codeSystem = '2.16.840.1.113883.1.11.13955')]">
        <xsl:call-template name="newCreateCodableConcept">
          <xsl:with-param name="pElementName" select="'type'" />
          <xsl:with-param name="pIncludeCoding" select="true()" />
          <xsl:with-param name="includeTranslations" select="true()" />
        </xsl:call-template>
      </xsl:for-each>

      <!-- Also get any encounter codes -->
      <!-- 20260803 Claude (CDAFHIR-016): gated on eICR - there the 4.49 activities ARE this encounter
           (dedup model, same as the identifier merge above), so absorbing their codes as type is
           intentional. In other document types the 4.49s are separate resources and this leaked one
           encounter's codes into another. Encounter.type is 0..*, so the multi-activity merge stays. -->
      <xsl:for-each select="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'][$gvCurrentIg = 'eICR']/cda:code[not(@codeSystem = '2.16.840.1.113883.1.11.13955')]">
        <xsl:call-template name="newCreateCodableConcept">
          <xsl:with-param name="pElementName" select="'type'" />
          <xsl:with-param name="pIncludeCoding" select="true()" />
          <xsl:with-param name="includeTranslations" select="true()" />
        </xsl:call-template>
      </xsl:for-each>

      <xsl:call-template name="subject-reference" />

      <xsl:for-each select="cda:responsibleParty[not(@nullFlavor)]">
        <participant>
          <type>
            <coding>
              <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
              <code value="ATND" />
            </coding>
          </type>
          <!--<xsl:apply-templates select="cda:assignedEntity/cda:code">
                        <xsl:with-param name="pElementName">type</xsl:with-param>
                    </xsl:apply-templates>-->
          <individual>
            <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
          </individual>
        </participant>
      </xsl:for-each>
      <xsl:for-each select="cda:encounterParticipant[not(@nullFlavor)] | cda:performer[not(@nullFlavor)]">
        <participant>
          <!--<type>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                            <code value="PPRF" />
                        </coding>
                    </type>-->

          <!--<xsl:apply-templates select="cda:assignedEntity/cda:code">
                        <xsl:with-param name="pElementName">type</xsl:with-param>
                    </xsl:apply-templates>-->
          <individual>
            <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
          </individual>
        </participant>
      </xsl:for-each>

      <!--<xsl:choose>
                
                <xsl:when test="
                        cda:author/cda:assignedAuthor/cda:assignedPerson or
                        ancestor::cda:section[1]/cda:author[1]/cda:assignedAuthor or
                        /cda:ClinicalDocument/cda:author[1]/cda:assignedAuthor/cda:assignedPerson or
                        /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty">-->
      <!-- 20260729 Claude: Fix - cda:assignedPerson was applied in mode="rename-reference-participant", which has no
           matching template (it matches cda:author | cda:performer), so XSLT built-in rules copied the person's name
           text into the output instead of emitting a reference. Now the author itself is applied in that mode, which
           resolves to the assignedAuthor's uuid (the PractitionerRole resource) -->
      <xsl:for-each select="cda:author[cda:assignedAuthor/cda:assignedPerson]">
        <participant>
          <xsl:apply-templates select="." mode="rename-reference-participant">
            <xsl:with-param name="pElementName">individual</xsl:with-param>
          </xsl:apply-templates>
        </participant>
      </xsl:for-each>
      <!--</xsl:when>
            </xsl:choose>-->
      <xsl:for-each select="/cda:ClinicalDocument/cda:participant/cda:associatedEntity[@classCode = 'NOK']">
        <participant>
          <individual>
            <xsl:apply-templates select="." mode="reference" />
          </individual>
        </participant>
      </xsl:for-each>
      <xsl:apply-templates select="cda:effectiveTime" mode="period" />
      <xsl:choose>
        <xsl:when test="local-name(.) = 'encompassingEncounter'">
          <xsl:apply-templates select="/cda:ClinicalDocument/cda:documentationOf/cda:serviceEvent/cda:code">
            <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="cda:entryRelationship[@typeCode = 'RSON']/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
            <xsl:apply-templates select="cda:value[@xsi:type = 'CD']">
              <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <!-- When this is an eICR and we are inside the encompassingEncounter we want to put the encounter diagnoses in this encounter -->
        <xsl:when test="local-name(.) = 'encompassingEncounter' and $gvCurrentIg = 'eICR'">
          <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
              <diagnosis>
                <xsl:apply-templates select="self::node()" mode="entry-extension" />
                <condition>
                  <xsl:apply-templates select="." mode="reference" />
                </condition>
              </diagnosis>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="local-name(.) = 'encompassingEncounter'">
          <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80'][not(ancestor::cda:encounter)]">
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
              <diagnosis>
                <condition>
                  <xsl:apply-templates select="." mode="reference" />
                </condition>
              </diagnosis>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
              <diagnosis>
                <condition>
                  <xsl:apply-templates select="." mode="reference" />
                </condition>
              </diagnosis>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>

      <!-- Can only have one dischargeDisposition use the one in the encompassingEncounter first,
                 otherwise use the body encounter one-->
      <xsl:choose>
        <xsl:when test="cda:dischargeDispositionCode">
          <hospitalization>
            <xsl:apply-templates select="cda:dischargeDispositionCode">
              <xsl:with-param name="pElementName" select="'dischargeDisposition'" />
              <xsl:with-param name="pIncludeCoding" select="true()" />
            </xsl:apply-templates>
          </hospitalization>
        </xsl:when>
        <!-- 20260803 Claude (CDAFHIR-016): gated on eICR (dedup model - see class above) and limited
             to the first activity's code: dischargeDisposition is 0..1, so applying templates to every
             activity's sdtc code emitted repeated elements on multi-activity documents. -->
        <xsl:when test="$gvCurrentIg = 'eICR' and //cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/sdtc:dischargeDispositionCode">
          <hospitalization>
            <xsl:apply-templates select="(//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/sdtc:dischargeDispositionCode)[1]">
              <xsl:with-param name="pElementName" select="'dischargeDisposition'" />
              <xsl:with-param name="pIncludeCoding" select="true()" />
            </xsl:apply-templates>
          </hospitalization>
        </xsl:when>
      </xsl:choose>


      <!--<sdtc:dischargeDispositionCode code="1" codeSystem="1.2.840.114350.1.13.671.3.7.4.698084.18888" codeSystemName="EPC" displayName="DISCHARGED TO HOME OR SELF CARE (ROUTINE DISCHARGE)">
                    <originalText>DISCHARGED TO HOME OR SELF CARE (ROUTINE DISCHARGE)</originalText>
                </sdtc:dischargeDispositionCode>-->

      <xsl:if test="cda:location[not(@nullFlavor)]">
        <location>
          <location>
            <reference value="urn:uuid:{cda:location/@lcg:uuid}" />
          </location>
        </location>
      </xsl:if>
      <xsl:if test="cda:location/cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]">
        <serviceProvider>
          <reference value="urn:uuid:{cda:location/cda:healthCareFacility/cda:serviceProviderOrganization/@lcg:uuid}" />
        </serviceProvider>
      </xsl:if>

    </Encounter>
  </xsl:template>

  <!-- 20260729 Claude: removed dead template match="cda:code" mode="encounter" - a repo-wide search confirms nothing
       invokes mode="encounter"; Encounter.type is built inline in the main template above -->

</xsl:stylesheet>
