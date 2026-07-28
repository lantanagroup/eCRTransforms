<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:recordTarget" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:patientRole/cda:providerOrganization" mode="bundle-entry" />

        <!-- 20260727 Claude: Fix - create the Patient/RelatedPerson entries for Family History-style related subjects
             (section 2.16.840.1.113883.10.20.22.2.15). The mode="relatedPerson-entry" template in cda2fhir-RelatedPerson.xslt
             was never invoked from anywhere, so the Patient.link references emitted below were dangling.
             Guarded so it only runs once even when there are multiple recordTargets. -->
        <xsl:if test="not(preceding::cda:recordTarget)">
            <xsl:apply-templates select="//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.15']" mode="relatedPerson-entry" />
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:recordTarget">
        <Patient>

            <!--MD: set meta profile based on Ig -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'NA'">
                    <xsl:call-template name="add-meta" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$gvCurrentIg" />
                            <xsl:with-param name="pResource" select="'Patient'" />
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

            <xsl:call-template name="generate-text-patient" />
            <xsl:call-template name="add-race-codes" />
            <xsl:call-template name="add-ethnicity-codes" />

            <xsl:call-template name="add-birthtime-extension" />
            <xsl:call-template name="add-birth-sex-extension" />
            <xsl:call-template name="add-birthplace-extension" />
            <xsl:call-template name="add-gender-identity-extension" />
            <xsl:call-template name="add-tribal-affiliation-extension" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:religiousAffiliationCode" mode="extension" />
            <xsl:apply-templates select="cda:patientRole/cda:id" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:id" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:name" />
            <xsl:apply-templates select="cda:patientRole/cda:telecom" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:administrativeGenderCode" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:birthTime" />

            <!-- Updating from ifs allowing both boolean and time - only one allowed
                Will check date first and use that otherwise will use boolean-->
            <!-- Update to handle nullFlavor -->
            <!-- 20260727 Claude: Fixes - (1) sdtc:deceasedInd with a nullFlavor (no @value) previously matched no branch and
                 emitted nothing; (2) sdtc:deceasedTime with neither @value nor nullFlavor previously passed an empty sequence
                 to lcg:cdaTS2date (runtime type error); restructured so every input shape produces a deceased[x] -->
            <xsl:choose>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedTime[@nullFlavor]">
                    <deceasedDateTime>
                        <xsl:apply-templates select="cda:patientRole/cda:patient/sdtc:deceasedTime/@nullFlavor" mode="data-absent-reason-extension" />
                    </deceasedDateTime>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedTime[@value]">
                    <deceasedDateTime>
                        <xsl:attribute name="value" select="lcg:cdaTS2date(cda:patientRole/cda:patient/sdtc:deceasedTime[@value][1]/@value)" />
                    </deceasedDateTime>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedInd/@value">
                    <deceasedBoolean>
                        <xsl:attribute name="value" select="cda:patientRole/cda:patient/sdtc:deceasedInd/@value" />
                    </deceasedBoolean>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedInd[@nullFlavor]">
                    <deceasedBoolean>
                        <xsl:apply-templates select="cda:patientRole/cda:patient/sdtc:deceasedInd/@nullFlavor" mode="data-absent-reason-extension" />
                    </deceasedBoolean>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient">
                    <deceasedBoolean>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </deceasedBoolean>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="cda:patientRole/cda:addr" />

            <xsl:choose>
                <xsl:when test="cda:patientRole/cda:patient/cda:maritalStatusCode">
                    <xsl:apply-templates select="cda:patientRole/cda:patient/cda:maritalStatusCode">
                        <xsl:with-param name="pElementName">maritalStatus</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>

            <xsl:for-each select="cda:patientRole/cda:patient/cda:guardian">
                <contact>
                    <relationship>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-RoleClass" />
                            <code value="GUARD" />
                        </coding>
                    </relationship>
                    <xsl:apply-templates select="cda:guardianPerson/cda:name" />
                    <xsl:apply-templates select="cda:telecom" />
                    <xsl:apply-templates select="cda:addr" />
                </contact>
            </xsl:for-each>

            <!-- SG 20240321: Add emergency contact -->
            <xsl:for-each select="/cda:ClinicalDocument/cda:participant[@typeCode = 'IND']/cda:associatedEntity[@classCode = 'ECON']">
                <contact>
                    <relationship>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v2-0131" />
                            <code value="C" />
                        </coding>
                    </relationship>
                    <xsl:apply-templates select="cda:associatedPerson/cda:name" />
                    <xsl:apply-templates select="cda:telecom" />
                    <xsl:apply-templates select="cda:addr" />
                </contact>
            </xsl:for-each>

            <!-- Communication:  TODO - add extension patient-proficiency modeCode -> proficieny.type, proficiency.level -->
            <xsl:for-each select="cda:patientRole/cda:patient/cda:languageCommunication">
                <communication>
                    <language>
                        <coding>
                            <!-- Hard coding system because it's not in CDA -->
                            <system value="urn:ietf:bcp:47" />
                            <!-- eng is not allowed in FHIR - map to en -->
                            <xsl:choose>
                                <xsl:when test="cda:languageCode/@code = 'eng'">
                                    <code value="en" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <code value="{cda:languageCode/@code}" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </coding>
                    </language>
                    <xsl:if test="cda:preferenceInd">
                        <preferred>
                            <xsl:attribute name="value" select="cda:preferenceInd/@value" />
                        </preferred>
                    </xsl:if>
                </communication>
            </xsl:for-each>

            <!-- managingOrganization -->
            <xsl:if test="cda:patientRole/cda:providerOrganization">
                <managingOrganization>
                    <reference value="urn:uuid:{cda:patientRole/cda:providerOrganization/@lcg:uuid}" />
                </managingOrganization>
            </xsl:if>

            <!-- link (related Patient or RelatedPerson) -->
            <!-- 20260727 Claude: REMOVED (SG approved) - a seealso link previously pointed from the record patient to the
                 Family History-style related subjects' RelatedPerson resources. Patient.link is defined as concerning the
                 "same actual person", so linking the record patient to a *different* person's RelatedPerson was semantically
                 incorrect (and originally also malformed/dangling). The related subjects' Patient/RelatedPerson entries are
                 still created via mode="relatedPerson-entry" (invoked from the bundle-entry template above), and each
                 related subject's own Patient carries the proper seealso link to its RelatedPerson - see
                 cda2fhir-RelatedPerson.xslt. -->
        </Patient>
    </xsl:template>

    <xsl:template name="add-race-codes">
        <!-- Race -->
        <xsl:if test="cda:patientRole/cda:patient/cda:raceCode or cda:patientRole/cda:patient/sdtc:raceCode">
            <extension url="http://hl7.org/fhir/us/core/StructureDefinition/us-core-race">

                <xsl:for-each select="cda:patientRole/cda:patient/cda:raceCode">
                    <xsl:variable name="code">
                        <xsl:choose>
                            <xsl:when test="@nullFlavor">
                                <xsl:value-of select="@nullFlavor" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@code" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- 20260727 Claude: removed unused $text variable (computed but never referenced) -->
                    <xsl:variable name="codeSystemUri">
                        <xsl:choose>
                            <xsl:when test="@nullFlavor">
                                <xsl:text>http://terminology.hl7.org/CodeSystem/v3-NullFlavor</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>urn:oid:2.16.840.1.113883.6.238</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <extension url="ombCategory">
                        <valueCoding>
                            <system value="{$codeSystemUri}" />
                            <!-- 20260727 Claude: Fix - the us-core-race ombCategory slice only allows the five OMB codes
                                 plus UNK/ASKU; previously only NI was remapped, so other nullFlavors (OTH, MSK, NAV, ...)
                                 passed through as invalid codings -->
                            <xsl:choose>
                                <xsl:when test="@nullFlavor = 'ASKU'">
                                    <code value="ASKU" />
                                </xsl:when>
                                <xsl:when test="@nullFlavor">
                                    <code value="UNK" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <code value="{$code}" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@displayName">
                                <display>
                                    <xsl:attribute name="value">
                                        <xsl:apply-templates select="@displayName" />
                                    </xsl:attribute>
                                </display>
                            </xsl:if>
                        </valueCoding>
                    </extension>
                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/sdtc:raceCode[not(@nullFlavor)]">
                    <!-- 20260727 Claude: removed unused $text variable (computed but never referenced) -->
                    <xsl:variable name="code">
                        <xsl:choose>
                            <xsl:when test="@nullFlavor">
                                <xsl:value-of select="@nullFlavor" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@code" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="codeSystemUri">
                        <xsl:choose>
                            <xsl:when test="@nullFlavor">
                                <xsl:text>http://terminology.hl7.org/CodeSystem/v3-NullFlavor</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>urn:oid:2.16.840.1.113883.6.238</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <!--For file OMB category race code must use extension ombCategory -->
                        <xsl:when test="$code = '1002-5' or $code = '2028-9' or $code = '2054-5' or $code = '2076-8' or $code = '2106-3'">
                            <extension url="ombCategory">
                                <valueCoding>
                                    <system value="{$codeSystemUri}" />
                                    <code value="{$code}" />

                                    <xsl:if test="@displayName">
                                        <display>
                                            <xsl:attribute name="value">
                                                <xsl:apply-templates select="@displayName" />
                                            </xsl:attribute>
                                        </display>
                                    </xsl:if>
                                </valueCoding>
                            </extension>
                        </xsl:when>
                        <xsl:otherwise>
                            <extension url="detailed">
                                <valueCoding>
                                    <system value="{$codeSystemUri}" />
                                    <code value="{$code}" />
                                    <xsl:if test="@displayName">
                                        <display>
                                            <xsl:attribute name="value">
                                                <xsl:apply-templates select="@displayName" />
                                            </xsl:attribute>
                                        </display>
                                    </xsl:if>
                                </valueCoding>
                            </extension>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <!--MD: if patient has more than one race set the text as Mixed  -->
                <!-- 20260727 Claude: Fixes - (1) valueString was "'Mixed'" with the quote characters inside the attribute;
                     (2) "Mixed" fired whenever ANY sdtc:raceCode existed, not when more than one race is recorded: only
                     distinct OMB category codes count as separate races - a detailed code alongside its OMB category
                     (e.g. White + European) is one race, not mixed; (3) the fallback could emit an empty valueString when
                     raceCode had a code but no displayName (us-core-race requires a non-empty text); (4) replaced
                     document-wide //cda:patientRole paths with context-relative ones -->
                <xsl:variable name="vOmbRaceCodes"
                    select="distinct-values((cda:patientRole/cda:patient/cda:raceCode[not(@nullFlavor)]/@code, cda:patientRole/cda:patient/sdtc:raceCode[@code = ('1002-5', '2028-9', '2054-5', '2076-8', '2106-3')]/@code))" />
                <xsl:variable name="vDetailedRaceCodes"
                    select="cda:patientRole/cda:patient/sdtc:raceCode[not(@nullFlavor)][not(@code = ('1002-5', '2028-9', '2054-5', '2076-8', '2106-3'))]" />
                <extension url="text">
                    <xsl:choose>
                        <xsl:when test="count($vOmbRaceCodes) > 1">
                            <valueString value="Mixed" />
                        </xsl:when>
                        <xsl:when test="count($vOmbRaceCodes) = 1">
                            <xsl:variable name="vPrimaryRace"
                                select="(cda:patientRole/cda:patient/cda:raceCode[not(@nullFlavor)] | cda:patientRole/cda:patient/sdtc:raceCode[not(@nullFlavor)])[@code = $vOmbRaceCodes[1]][1]" />
                            <valueString>
                                <xsl:attribute name="value">
                                    <xsl:choose>
                                        <xsl:when test="$vPrimaryRace/@displayName">
                                            <xsl:apply-templates select="$vPrimaryRace/@displayName" />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$vPrimaryRace/@code" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                            </valueString>
                        </xsl:when>
                        <xsl:when test="count($vDetailedRaceCodes) > 0">
                            <valueString value="{string-join($vDetailedRaceCodes/(if (@displayName) then @displayName else @code), ', ')}" />
                        </xsl:when>
                        <xsl:when test="cda:patientRole/cda:patient/cda:raceCode/@nullFlavor | cda:patientRole/cda:patient/sdtc:raceCode/@nullFlavor">
                            <valueString value="{(cda:patientRole/cda:patient/cda:raceCode/@nullFlavor | cda:patientRole/cda:patient/sdtc:raceCode/@nullFlavor)[1]}" />
                        </xsl:when>
                        <xsl:otherwise>
                            <valueString value="Unknown" />
                        </xsl:otherwise>
                    </xsl:choose>
                </extension>
            </extension>
        </xsl:if>
    </xsl:template>

    <xsl:template name="add-ethnicity-codes">
        <!-- Ethnicity -->
        <xsl:if test="cda:patientRole/cda:patient/cda:ethnicGroupCode or cda:patientRole/cda:patient/sdtc:ethnicGroupCode">
            <extension url="http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity">
                <xsl:for-each select="cda:patientRole/cda:patient/cda:ethnicGroupCode">

                    <xsl:choose>
                        <xsl:when test="@nullFlavor">
                            <extension url="ombCategory">
                                <valueCoding>
                                    <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                                </valueCoding>
                            </extension>
                        </xsl:when>
                        <!-- Check to make sure there is a valid ethnicGroupCode (there are only 2 valid codes here) -->
                        <xsl:when test="@code = '2135-2' or @code = '2186-5'">
                            <extension url="ombCategory">
                                <valueCoding>
                                    <system value="urn:oid:2.16.840.1.113883.6.238" />
                                    <code value="{@code}" />
                                    <xsl:if test="@displayName">
                                        <display>
                                            <xsl:attribute name="value">
                                                <xsl:apply-templates select="@displayName" />
                                            </xsl:attribute>
                                        </display>
                                    </xsl:if>
                                </valueCoding>
                            </extension>
                        </xsl:when>
                        <!--<xsl:otherwise>
                                    <system value="urn:oid:2.16.840.1.113883.6.238" />
                                    <code value="{@code}" />
                                </xsl:otherwise>-->
                    </xsl:choose>

                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/sdtc:ethnicGroupCode">
                    <xsl:choose>
                        <xsl:when test="@nullFlavor" />
                        <xsl:when test="key('detailed-ethnicity-codes-key', @code)">
                            <extension url="detailed">
                                <valueCoding>
                                    <system value="urn:oid:2.16.840.1.113883.6.238" />
                                    <code value="{@code}" />
                                    <xsl:if test="@displayName">
                                        <display>
                                            <xsl:attribute name="value">
                                                <xsl:apply-templates select="@displayName" />
                                            </xsl:attribute>
                                        </display>
                                    </xsl:if>
                                </valueCoding>
                            </extension>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- 20260727 Claude: Fix - codes not found in detailed-ethnicity-codes.xml were previously
                                 dropped with no trace; now flagged so missing table entries are visible -->
                            <xsl:comment>WARNING: sdtc:ethnicGroupCode <xsl:value-of select="@code" /> not in detailed-ethnicity-codes.xml - not mapped to detailed ethnicity</xsl:comment>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <xsl:variable name="vOMBText">
                    <xsl:choose>
                        <xsl:when test="cda:patientRole/cda:patient/cda:ethnicGroupCode/@displayName">
                            <xsl:value-of select="cda:patientRole/cda:patient/cda:ethnicGroupCode/@displayName" />
                        </xsl:when>
                        <xsl:when test="cda:patientRole/cda:patient/cda:ethnicGroupCode/@nullFlavor">
                            <xsl:value-of select="cda:patientRole/cda:patient/cda:ethnicGroupCode/@nullFlavor" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="cda:patientRole/cda:patient/cda:ethnicGroupCode/@code" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="vDetailedText">
                    <xsl:choose>
                        <xsl:when test="cda:patientRole/cda:patient/sdtc:ethnicGroupCode/@displayName">
                            <xsl:value-of select="cda:patientRole/cda:patient/sdtc:ethnicGroupCode/@displayName" separator=", " />
                        </xsl:when>
                        <xsl:when test="cda:patientRole/cda:patient/sdtc:ethnicGroupCode[1]/@nullFlavor">
                            <!-- 20260727 Claude: Fix - path selected the nonexistent sdtc:patient element, so this branch
                                 always produced an empty string -->
                            <xsl:value-of select="cda:patientRole/cda:patient/sdtc:ethnicGroupCode[1]/@nullFlavor" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="cda:patientRole/cda:patient/sdtc:ethnicGroupCode/@code" separator=", " />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <extension url="text">
                    <xsl:choose>
                        <xsl:when test="string-length($vOMBText) > 0 and string-length($vDetailedText) > 0">
                            <valueString value="{concat($vOMBText, ', ', $vDetailedText)}" />
                        </xsl:when>
                        <xsl:when test="string-length($vOMBText) > 0">
                            <valueString value="{$vOMBText}" />
                        </xsl:when>
                        <xsl:when test="string-length($vDetailedText) > 0">
                            <valueString value="{$vDetailedText}" />
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- 20260727 Claude: Fix - previously the wrapper extension was emitted with no value at all
                                 when both text variables were empty (invalid FHIR extension; us-core-ethnicity requires text) -->
                            <valueString value="Unknown" />
                        </xsl:otherwise>
                    </xsl:choose>
                </extension>

            </extension>
        </xsl:if>
    </xsl:template>


    <xsl:template name="add-birthtime-extension">
        <xsl:for-each select="cda:patientRole/cda:patient/cda:birthTime[string-length(@value) > 8]">
            <extension url="http://hl7.org/fhir/StructureDefinition/patient-birthTime">
                <valueDateTime value="{lcg:cdaTS2date(@value)}" />
            </extension>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-birth-sex-extension">
        <!-- 20260727 Claude: Fixes - (1) exclude observations recorded about a related subject (e.g. inside a family
             history organizer), which previously would have been attributed to the patient; (2) us-core-birthsex is 0..1,
             so only the first matching observation is used (previously one extension per observation) -->
        <xsl:for-each select="(/cda:ClinicalDocument/descendant::cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.200'][not(ancestor::*[cda:subject/cda:relatedSubject])])[1]">
            <extension url="http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex">
                <xsl:choose>
                    <xsl:when test="cda:value/@code">
                        <valueCode value="{cda:value/@code}" />
                    </xsl:when>
                    <xsl:otherwise>
                        <valueCode value="UNK" />
                    </xsl:otherwise>
                </xsl:choose>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <!-- birthplace -->
    <xsl:template name="add-birthplace-extension">
        <!-- 20260727 Claude: Fixes - (1) $vName previously selected cda:name AND its child elements, so any name with
             children had its text included twice; (2) a place with a name but no addr previously emitted an empty
             patient-birthPlace extension (invalid FHIR) - the name-only case now emits a valueAddress with just text -->
        <xsl:variable name="vName">
            <xsl:value-of select="normalize-space(string-join(cda:patientRole/cda:patient/cda:birthplace/cda:place/cda:name, ' '))" />
        </xsl:variable>
        <xsl:for-each select="cda:patientRole/cda:patient/cda:birthplace/cda:place">
            <xsl:choose>
                <xsl:when test="cda:addr[* or @nullFlavor]">
                    <extension url="http://hl7.org/fhir/StructureDefinition/patient-birthPlace">
                        <xsl:apply-templates select="cda:addr">
                            <xsl:with-param name="pElementName" select="'valueAddress'" />
                            <xsl:with-param name="pExtraText" select="$vName" />
                        </xsl:apply-templates>
                    </extension>
                </xsl:when>
                <xsl:when test="string-length($vName) > 0">
                    <extension url="http://hl7.org/fhir/StructureDefinition/patient-birthPlace">
                        <valueAddress>
                            <text value="{$vName}" />
                        </valueAddress>
                    </extension>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-gender-identity-extension">
        <!-- 20260727 Claude: Fixes - (1) exclude observations recorded about a related subject; (2) require cda:value
             (previously an observation without a value produced an empty sub-extension, which is invalid FHIR); (3) the
             period sub-extension is only emitted when the effectiveTime has content (previously an empty extension);
             (4) the eCR us-ph extension URL is only used for eICR/RR - other documents get the standard
             patient-genderIdentity extension (plain valueCodeableConcept), mirroring the fhir2cda direction -->
        <xsl:for-each select="/cda:ClinicalDocument/descendant::cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.34.3.45'][not(ancestor::*[cda:subject/cda:relatedSubject])][cda:value]">
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR' or $gvCurrentIg = 'RR'">
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-genderidentity-extension">
                        <extension url="value">
                            <xsl:apply-templates select="cda:value">
                                <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
                            </xsl:apply-templates>
                        </extension>
                        <xsl:if test="cda:effectiveTime[@value or cda:low or cda:high]">
                            <extension url="period">
                                <xsl:apply-templates select="cda:effectiveTime" mode="period">
                                    <xsl:with-param name="pElementName">valuePeriod</xsl:with-param>
                                </xsl:apply-templates>
                            </extension>
                        </xsl:if>
                    </extension>
                </xsl:when>
                <xsl:otherwise>
                    <extension url="http://hl7.org/fhir/StructureDefinition/patient-genderIdentity">
                        <xsl:apply-templates select="cda:value">
                            <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
                        </xsl:apply-templates>
                    </extension>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: US Public Health Tribal Affiliation Extension -->
    <xsl:template name="add-tribal-affiliation-extension">
        <!-- 20260727 Claude: Fixes - (1) exclude observations recorded about a related subject; (2) require cda:code
             (TribeName) so an empty sub-extension is never emitted; (3) EnrolledTribeMember only emitted when a boolean
             value is present (previously a missing or non-BL value produced an empty sub-extension, invalid FHIR) -->
        <xsl:for-each select="//cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.48'][not(ancestor::*[cda:subject/cda:relatedSubject])][cda:code]">
            <xsl:comment>US Public Health Tribal Affiliation Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-tribal-affiliation-extension">
                <extension url="TribeName">
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName" select="'valueCoding'" />
                        <xsl:with-param name="pIncludeCoding" select="false()" />
                    </xsl:apply-templates>
                </extension>
                <xsl:if test="cda:value[@xsi:type = 'BL'][@value]">
                    <extension url="EnrolledTribeMember">
                        <xsl:apply-templates select="cda:value">
                            <xsl:with-param name="pElementName" select="'valueBoolean'" />
                        </xsl:apply-templates>
                    </extension>
                </xsl:if>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="generate-text-patient">
        <text>
            <status value="generated" />
            <div xmlns="http://www.w3.org/1999/xhtml">
                <xsl:for-each select="cda:patientRole/cda:patient/cda:name[not(@nullFlavor)]">
                    <xsl:choose>
                        <xsl:when test="position() = 1">
                            <h1><xsl:value-of select="cda:family" />, <xsl:value-of select="cda:given" /></h1>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>Alternate name: <xsl:value-of select="cda:family" />, <xsl:value-of select="cda:given" /></p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:telecom[not(@nullFlavor)]">
                    <p>Telecom: <xsl:value-of select="@value" /></p>
                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:addr[not(@nullFlavor)]">
                    <p>
                        <xsl:text>Address: </xsl:text>
                        <xsl:for-each select="* | text()">
                            <xsl:value-of select="." />
                            <xsl:if test="not(position() = last())">
                                <br />
                            </xsl:if>
                        </xsl:for-each>
                    </p>
                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/cda:administrativeGenderCode[not(@nullFlavor)]">
                    <p>Gender: <xsl:value-of select="@code" /></p>
                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/cda:birthTime[not(@nullFlavor)]">
                    <p>Birthdate: <xsl:value-of select="lcg:cdaTS2date(@value)" /></p>
                </xsl:for-each>
                <!-- communication -->
                <xsl:for-each select="cda:patientRole/cda:patient/cda:languageCommunication/cda:languageCode[not(@nullFlavor)]">
                    <p>Language: <xsl:value-of select="@code" /></p>
                </xsl:for-each>
            </div>
        </text>
    </xsl:template>


</xsl:stylesheet>
