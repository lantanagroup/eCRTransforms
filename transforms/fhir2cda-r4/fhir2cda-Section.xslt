<?xml version="1.0" encoding="UTF-8"?>
<!-- 

Copyright 2020 Lantana Consulting Group

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid">

    <xsl:import href="fhir2cda-utility.xslt" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />

    <!-- fhir:section -> cda:section (Generic) -->
    <xsl:template match="fhir:section">
        <xsl:param name="title" />
        <section>
            <!-- SG 20240307: Check to see if this is a section that requires an entry if there is no nullFlavor
                Sections: Emergency Outbreak Information Section, Encounters Section (entries required), Immunizations Section (entries required),
                          Medications Section (entries required), Problem Section (entries required), Procedures Section (entries required), 
                          Reportability Response Information Section, Results Section (entries required), Vital Signs Section (entries required)-->
            <xsl:if test="not(fhir:entry) and fhir:code/fhir:coding/fhir:code/@value = ('83910-0', '46240-8', '11369-6', '10160-0', '11450-4', '47519-4', '88085-6', '30954-2', '8716-3')">
                <xsl:attribute name="nullFlavor">NI</xsl:attribute>
            </xsl:if>
            <xsl:variable name="generated-narrative" select="fhir:text/fhir:status/@value" />

            <!-- templateId -->
            <xsl:call-template name="get-template-id" />

            <xsl:apply-templates select="fhir:code" />
            <title>
                <xsl:value-of select="$title" />
            </title>

            <xsl:choose>
                <xsl:when test="fhir:entry">
                    <text>
                        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                            <xsl:apply-templates select="fhir:text" mode="narrative" />
                        </xsl:if>
                    </text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <!-- Health Concern Section -->
                        <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '75310-3'">
                            <text>
                                <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                                    <xsl:apply-templates select="fhir:text" mode="narrative-footnote" />
                                </xsl:if>
                            </text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="fhir:entry">
                    <xsl:variable name="sectionCodeforEntry" select="fhir:code/fhir:coding/fhir:code/@value" />
                    <xsl:for-each select="fhir:entry">
                        <xsl:for-each select="fhir:reference">
                            <xsl:variable name="referenceURI">
                                <xsl:call-template name="resolve-to-full-url">
                                    <xsl:with-param name="referenceURI" select="@value" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                <!-- Process for all entry elements other than Pregnancy Outcome - it's an entryRelationship of Pregnancy Observation in CDA -->
                                <xsl:if test="not(fhir:resource/fhir:Observation/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-outcome-observation')">
                                    <xsl:choose>
                                        <xsl:when test="$sectionCodeforEntry = '46264-8'">
                                            <!-- MD: a procedure can be an entry for procedure section or for medical equipment -->
                                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entryMedicalEquipment">
                                                <xsl:with-param name="generated-narrative" />
                                            </xsl:apply-templates>
                                        </xsl:when>
                                        <xsl:when test="$sectionCodeforEntry = '42346-7'">
                                            <!-- MD: Admission Medication Administration is different from Medication Administration -->
                                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entryAdmissionMedication">
                                                <xsl:with-param name="generated-narrative" />
                                            </xsl:apply-templates>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry">
                                                <xsl:with-param name="generated-narrative" />
                                            </xsl:apply-templates>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="section-no-entry" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- fhir:entry -> get referenced resource entry url and process -->


            <!-- If this is the Social History Section (29762-2) -->
            <xsl:if test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '29762-2'">
                <!-- we need to process Birth Sex and Gender Identity (extensions on fhir Composition) as Observations onto CDA Social history Section-->
                <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex']" mode="entry" />

                <!-- MD: eICR using different genderidentity extension -->
                <xsl:choose>
                    <xsl:when test="$gvCurrentIg = 'eICR'">
                        <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-genderidentity-extension']" mode="entry" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity']" mode="entry" />
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity']" mode="entry" />

                <!-- MD: we need to process tribal affiliation (extension on fhir Patient) as Observation onto CDA Social history Section -->
                <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-tribal-affiliation-extension']" mode="entry" />
            </xsl:if>
        </section>
    </xsl:template>

    <xsl:template name="section-no-entry">
        <xsl:choose>

            <!--Reason for Visit -->
            <!-- If there is Encounter.reasonCode narrative, add this here as well -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '29299-5'">
                <text>
                    <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
                    <!--Condition.code.coding.display
                    Condition.code.text
                    Procedure.code.coding.display
                    Procedure.code.text
                    ImmunizationRecommendation.recommendation.*.coding.display
                    ImmunizationRecommendation.recommendation.*.text
                    Observation.code.coding.display
                    Observation.code.text-->
                    <xsl:for-each select="//fhir:Encounter/fhir:reasonReference/fhir:reference">
                        <xsl:variable name="referenceURI">
                            <xsl:call-template name="resolve-to-full-url">
                                <xsl:with-param name="referenceURI" select="@value" />
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/*">


                            <xsl:variable name="vCode">
                                <xsl:for-each select="fhir:code">
                                    <xsl:value-of select="concat(local-name(), ': ')" />
                                    <xsl:for-each select="descendant-or-self::*/@value">
                                        <xsl:value-of select="concat(., ' | ')" />
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:variable>

                            <xsl:variable name="vValue">

                                <xsl:for-each
                                    select="fhir:valueQuantity | fhir:valueCodeableConcept | fhir:valueString | fhir:valueBoolean | fhir:valueInteger | fhir:valueRange | fhir:valueRatio | fhir:valueSampledData | fhir:valueTime | fhir:valueDateTime | fhir:valuePeriod">
                                    <xsl:value-of select="concat(local-name(), ': ')" />
                                    <xsl:for-each select="descendant-or-self::*/@value">
                                        <xsl:value-of select="concat(., ' | ')" />
                                    </xsl:for-each>
                                </xsl:for-each>

                            </xsl:variable>

                            <xsl:variable name="vLocalName">
                                <xsl:value-of select="local-name()" />
                            </xsl:variable>

                            <xsl:choose>
                                <xsl:when test="$vCode and $vValue">
                                    <paragraph>
                                        <xsl:value-of select="$vLocalName" />: <xsl:value-of select="$vCode" />
                                        <xsl:value-of select="$vValue" />
                                    </paragraph>
                                </xsl:when>
                                <xsl:when test="$vCode">
                                    <paragraph>
                                        <xsl:value-of select="$vLocalName" />: <xsl:value-of select="$vCode" />
                                    </paragraph>
                                </xsl:when>
                                <xsl:when test="$vValue">
                                    <paragraph>
                                        <xsl:value-of select="$vLocalName" />: <xsl:value-of select="$vValue" />
                                    </paragraph>
                                </xsl:when>
                            </xsl:choose>
                            <!--<xsl:choose>
                                <xsl:when test="local-name() = 'Condition'">
                                    <xsl:for-each select="fhir:code/fhir:coding/fhir:display | fhir:code/fhir:text">
                                        <paragraph>Condition: <xsl:value-of select="@value" /></paragraph>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="local-name() = 'Procedure'">
                                    <xsl:for-each select="fhir:code/fhir:coding/fhir:display | fhir:code/fhir:text">
                                        <paragraph>Procedure: <xsl:value-of select="@value" /></paragraph>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="local-name() = 'ImmunizationRecommendation'">
                                    <xsl:for-each select="fhir:*/fhir:coding/fhir:display | fhir:code/fhir:text">
                                        <paragraph>Immunization Recommendation: <xsl:value-of select="@value" /></paragraph>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="local-name() = 'Observation'">
                                    <!-\-<xsl:variable name="vCodeText">
                                        <xsl:call-template name="get-codeable-concept-text">
                                            <xsl:with-param name="pCodeableConcept" select="fhir:code" />
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:variable name="vValueText">

                                        <xsl:choose>
                                            <xsl:when test="fhir:valueCodeableConcept">
                                                <xsl:call-template name="get-codeable-concept-text">
                                                    <xsl:with-param name="pCodeableConcept" select="fhir:valueCodeableConcept" />
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:when>
                                                <xsl:call-template name="get-value-text">
                                                    <xsl:with-param name="pValue" select="fhir:valueQuantity | fhir:valueString | valueBoolean " />
                                                </xsl:call-template>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:variable>-\->

                                    <xsl:for-each select="fhir:code">
                                        <xsl:choose>
                                            <xsl:when test="fhir:coding/fhir:display and fhir:text">
                                                <paragraph> Observation: <xsl:value-of select="fhir:coding/fhir:display/@value" /> | <xsl:value-of select="fhir:text/@value" />: <xsl:value-of
                                                        select="fhir:valueCodeableConcept/@value" />
                                                </paragraph>
                                            </xsl:when>
                                            <xsl:when test="fhir:coding/fhir:display">
                                                <paragraph>Observation: <xsl:value-of select="fhir:coding/fhir:display/@value" /></paragraph>
                                            </xsl:when>
                                            <xsl:when test="fhir:coding/fhir:text">
                                                <paragraph>Observation: <xsl:value-of select="fhir:text/@value" /></paragraph>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:for-each>-->
                        </xsl:for-each>
                    </xsl:for-each>
                    <xsl:for-each select="//fhir:Encounter/fhir:reasonCode/fhir:coding/fhir:display">
                        <paragraph>
                            <xsl:value-of select="@value" />
                        </paragraph>
                    </xsl:for-each>
                    <xsl:for-each select="//fhir:Encounter/fhir:reasonCode/fhir:text">
                        <paragraph>
                            <xsl:value-of select="@value" />
                        </paragraph>
                    </xsl:for-each>
                </text>
            </xsl:when>
            <xsl:otherwise>
                <text>
                    <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
                </text>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="get-codeable-concept-text">
        <xsl:param name="pCodeableConcept" />

        <xsl:variable name="vLocalName">
            <xsl:value-of select="local-name(parent::*)" />
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="fhir:coding/fhir:display and fhir:text">
                <paragraph>
                    <xsl:value-of select="$vLocalName" /> :<xsl:value-of select="fhir:coding/fhir:display/@value" /> | <xsl:value-of select="fhir:text/@value" />
                </paragraph>
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding/fhir:display">
                <paragraph>
                    <xsl:value-of select="$vLocalName" /> : <xsl:value-of select="fhir:coding/fhir:display/@value" />
                </paragraph>
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding/fhir:text">
                <paragraph>
                    <xsl:value-of select="$vLocalName" /> : <xsl:value-of select="fhir:text/@value" />
                </paragraph>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- fhir:Composition/fhir:encounter -> eICR Encounters Section (Section) -->
    <!-- The Encounters Section for eICR is created from Composition.encounter - there isn't a 
        section in the Composition, so we need to manually create the Section -->
    <xsl:template name="create-eicr-encounters-section">
        <section>
            <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries optional) '" />
            <templateId root="2.16.840.1.113883.10.20.22.2.22" />
            <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries optional) (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.2.22" extension="2015-08-01" />
            <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries required) '" />
            <templateId root="2.16.840.1.113883.10.20.22.2.22.1" />
            <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries required) (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.2.22.1" extension="2015-08-01" />
            <code code="46240-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="History of encounters" />
            <title>Encounters</title>
            <text>
                <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                    <xsl:apply-templates select="fhir:text" mode="narrative" />
                </xsl:if>
            </text>
            <xsl:apply-templates select="." mode="encounter" />
        </section>
    </xsl:template>

    <!-- Create the Reportability Response Subject Section - this is basically just some text -->
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '88084-9']]">
        <section>
            <xsl:call-template name="get-template-id">
                <xsl:with-param name="pElementType" select="'section'" />
            </xsl:call-template>
            <code code="88084-9" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Reportable condition response information and summary Document" />
            <text>
                <xsl:apply-templates select="fhir:text" mode="narrative" />
            </text>
            <!-- Create the Reportability Response Subject act -->
            <xsl:apply-templates select="." mode="entry" />
        </section>
    </xsl:template>

    <!-- [RR R1S1] Electronic Initial Case Report Section -->
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '88082-3']]">
        <section>
            <!-- templateId -->
            <xsl:call-template name="get-template-id" />

            <code code="88082-3" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Initial case report processing information Document" />
            <xsl:if test="fhir:text">
                <text>
                    <xsl:apply-templates select="fhir:text" mode="narrative" />
                </text>
            </xsl:if>
            <xsl:apply-templates select="fhir:entry[fhir:reference][fhir:identifier]" mode="rr" />
            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension']" mode="rr" />
            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension']" mode="rr" />
        </section>
    </xsl:template>

    <!-- Reportability Response Information Section (from eICR) -->
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '88085-6']]">
        <xsl:param name="title" />
        <section>

            <xsl:comment select="' [eICR R2 STU3] Reportability Response Information Section '" />
            <templateId root="2.16.840.1.113883.10.20.15.2.2.5" extension="2021-01-01" />
            <code code="88085-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Reportability response report Document Public health" />

            <title>
                <xsl:value-of select="$title" />
            </title>

            <text>
                <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                    <xsl:apply-templates select="fhir:text" mode="narrative" />
                </xsl:if>
            </text>

            <!-- Create the Reportability Response Coded Information Organizer [1..1] -->
            <xsl:call-template name="make-reportability-response-coded-information-organizer" />
        </section>
    </xsl:template>

    <!-- Reportability Response Summary Section -->
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '55112-7']]">
        <section>
            <xsl:comment select="' [RR R1S1] Reportability Response Summary Section '" />
            <templateId root="2.16.840.1.113883.10.20.15.2.2.2" extension="2017-04-01" />
            <code code="55112-7" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Document Summary" />
            <text>
                <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                    <xsl:apply-templates select="fhir:text" mode="narrative" />
                </xsl:if>
            </text>

            <xsl:apply-templates select="//fhir:Observation[fhir:code/fhir:coding/fhir:code[@value = '304561000']]" mode="rr" />

            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension']" />

            <!-- Create the Reportability Response Coded Information Organizer [1..1] -->
            <xsl:call-template name="make-reportability-response-coded-information-organizer" />
        </section>
    </xsl:template>


</xsl:stylesheet>
