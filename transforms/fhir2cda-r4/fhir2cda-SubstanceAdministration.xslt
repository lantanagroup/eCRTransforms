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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />

    <!-- MD: MedicationStatement -->
    <xsl:template match="fhir:MedicationStatement" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="make-medication-administration">
                <xsl:with-param name="moodCode">INT</xsl:with-param>
            </xsl:call-template>
        </entry>
    </xsl:template>

    <!-- fhir:MedicationDispense -> Medication Activity (cda:substanceAdministration) - entry -->
    <xsl:template match="fhir:MedicationDispense" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="make-medication-activity">
                <xsl:with-param name="moodCode">INT</xsl:with-param>
            </xsl:call-template>
        </entry>
    </xsl:template>

    <!-- fhir:MedicationAdministration -> Admission Medication (cda:substanceAdministration)-->
    <xsl:template match="fhir:MedicationAdministration" mode="entryAdmissionMedication">
        <xsl:param name="generated-narrative">additional</xsl:param>

        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>
        <!-- SG 20240119: Added this processing back in - had been changed to medication administration which is different -->
        <entry>
            <xsl:call-template name="make-admission-medication" />
        </entry>
    </xsl:template>

    <!-- fhir:MedicationAdministration -> Medication Administration (cda:substanceAdministration)-->
    <xsl:template match="fhir:MedicationAdministration" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>
        <entry>
            <xsl:call-template name="make-medication-administration" />
        </entry>
    </xsl:template>

    <!-- fhir:MedicationRequest: Medication Activity - entry -->
    <xsl:template match="fhir:MedicationRequest" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>

        <entry>
            <xsl:call-template name="make-medication-activity">
                <xsl:with-param name="moodCode">INT</xsl:with-param>
            </xsl:call-template>
        </entry>
    </xsl:template>

    <!-- fhir:MedicationRequest: Medication Activity - entryRelationship -->
    <xsl:template match="fhir:MedicationRequest" mode="entry-relationship">
        <xsl:param name="typeCode" select="'COMP'" />
        <entryRelationship>
            <xsl:attribute name="typeCode" select="$typeCode" />
            <xsl:call-template name="make-medication-activity">
                <xsl:with-param name="moodCode">INT</xsl:with-param>
            </xsl:call-template>
        </entryRelationship>
    </xsl:template>

    <!-- fhir:Immunization: Immunization Activity - entry -->
    <xsl:template match="fhir:Immunization" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>

        <entry>
            <xsl:call-template name="make-immunization-activity">
                <xsl:with-param name="moodCode">EVN</xsl:with-param>
            </xsl:call-template>
        </entry>
    </xsl:template>

    <!-- Create substanceAdministration: Immunization Activity -->
    <xsl:template name="make-immunization-activity">
        <xsl:param name="moodCode">EVN</xsl:param>

        <substanceAdministration classCode="SBADM" moodCode="{$moodCode}">
            <xsl:choose>
                <xsl:when test="fhir:status/@value = 'not-done'">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="negationInd" select="'false'" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- templateId -->
            <xsl:apply-templates mode="map-resource-to-template" select="." />
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:status">
                    <xsl:apply-templates mode="medication-activity" select="fhir:status" />
                </xsl:when>
                <xsl:otherwise>
                    <statusCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- SG 20240107: Added logic to capture Immunization.statusReason into Immunization Refusal Reason template -->
            <xsl:if test="fhir:statusReason">
                <entryRelationship typeCode="RSON">
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' Immunization Refusal Reason '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.53" />
                        <xsl:call-template name="get-id" />
                        <xsl:apply-templates select="fhir:statusReason" />
                        <!--<code displayName="patient objection" code="PATOBJ"
                            codeSystemName="HL7 ActNoImmunizationReason" codeSystem="2.16.840.1.113883.5.8"/>-->
                        <statusCode code="completed" />
                    </observation>
                </entryRelationship>

            </xsl:if>
            <xsl:choose>
                <xsl:when test="fhir:occurrenceDateTime">
                    <xsl:apply-templates select="fhir:occurrenceDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="fhir:route">
                <xsl:with-param name="pElementName" select="'routeCode'" />
            </xsl:apply-templates>
            <xsl:choose>
                <xsl:when test="fhir:doseQuantity">
                    <xsl:apply-templates select="fhir:doseQuantity">
                        <xsl:with-param name="pElementName" select="'doseQuantity'" />
                        <xsl:with-param name="pIncludeDatatype" select="false()" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <doseQuantity nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <consumable>
                <xsl:call-template name="make-immunization-medication-information" />
            </consumable>
        </substanceAdministration>
    </xsl:template>

    <!-- Create manufacturedProduct: Immunization Activity -->
    <xsl:template name="make-immunization-medication-information">

        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />

        <manufacturedProduct classCode="MANU">
            <!-- templateId -->
            <xsl:choose>
                <xsl:when test="$vTriggerExtension">
                    <xsl:apply-templates mode="map-trigger-resource-to-template" select="." />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="map-resource-to-template" select="fhir:vaccineCode" />
                </xsl:otherwise>
            </xsl:choose>
            <manufacturedMaterial>
                <xsl:apply-templates select="fhir:vaccineCode">
                    <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                </xsl:apply-templates>
                <xsl:if test="fhir:lotNumber/@value">
                    <lotNumberText>
                        <xsl:value-of select="fhir:lotNumber/@value" />
                    </lotNumberText>
                </xsl:if>
            </manufacturedMaterial>
            <xsl:for-each select="fhir:manufacturer/fhir:reference">
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="manufacturer" />
                </xsl:for-each>
            </xsl:for-each>
        </manufacturedProduct>
    </xsl:template>

    <xsl:template match="fhir:Organization" mode="manufacturer">
        <manufacturerOrganization>
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="fhir:name">
                <xsl:call-template name="get-org-name" />
            </xsl:if>
            <!--<xsl:apply-templates select="fhir:name" />-->
            <xsl:apply-templates select="fhir:telecom" />

            <xsl:choose>
                <xsl:when test="fhir:address">
                    <xsl:apply-templates select="fhir:address" />
                </xsl:when>
                <xsl:otherwise>
                    <addr nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

        </manufacturerOrganization>
    </xsl:template>

    <xsl:template name="make-admission-medication">
        <act classCode="ACT" moodCode="EVN">
            <xsl:comment select="' Admission Medication (V2) '" />
            <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.36" />
            <code code="42346-7" codeSystem="2.16.840.1.113883.6.1" displayName="Medications on admission (narrative)" />
            <entryRelationship typeCode="SUBJ">
                <substanceAdministration classCode="SBADM" moodCode="EVN">
                    <xsl:comment select="' MEDICATION ACTIVITY V2  '" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                    <xsl:choose>
                        <xsl:when test="fhir:identifier">
                            <xsl:apply-templates select="fhir:identifier" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- SG 20240119: Added processing for text -->
                    <xsl:if test="fhir:dosage/fhir:text">
                        <text>
                            <xsl:value-of select="fhir:dosage/fhir:text/@value" />
                        </text>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="fhir:status">
                            <xsl:apply-templates mode="medication-activity" select="fhir:status" />
                        </xsl:when>
                        <xsl:otherwise>
                            <statusCode nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:apply-templates select="fhir:effectivePeriod">
                        <xsl:with-param name="pXSIType" select="'IVL_TS'" />
                    </xsl:apply-templates>

                    <!--<xsl:choose>
        <xsl:when test="fhir:dosage/fhir:route/fhir:coding">
          <xsl:apply-templates select="fhir:dosage/fhir:route">
            <xsl:with-param name="pElementName" select="'routeCode'" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <routeCode nullFlavor="NI" />
        </xsl:otherwise>
      </xsl:choose>-->

                    <!-- SG 20230216: An issue here is that C-CDA specifies that routeCode has to come from SPL Drug Route of Administration Terminology
                 and that the translation if it's present needs to come from SNOMED  
                 Checking to see what code system is provided by FHIR and dealing with
                 Could create (or find) a mapping table between SNOMED and NCI at some point -->
                    <!--  If system is NCI (http://ncimeta.nci.nih.gov)(2.16.840.1.113883.3.26.1.1) process normally 
                 If system is SNOMED or anything else, put code translation and nullFlavor code
                 Assuming for now that there aren't other code systems being used here -->
                    <xsl:choose>
                        <xsl:when test="fhir:dosage/fhir:route/fhir:coding">
                            <xsl:choose>
                                <xsl:when test="fhir:dosage/fhir:route/fhir:coding/fhir:system/@value = 'http://ncimeta.nci.nih.gov'">
                                    <xsl:apply-templates select="fhir:dosage/fhir:route">
                                        <xsl:with-param name="pElementName" select="'routeCode'" />
                                    </xsl:apply-templates>
                                </xsl:when>
                                <!-- Takes care of SNOMED case and any others -->
                                <xsl:otherwise>
                                    <routeCode nullFlavor="OTH">
                                        <xsl:apply-templates select="fhir:dosage/fhir:route">
                                            <xsl:with-param name="pElementName" select="'translation'" />
                                        </xsl:apply-templates>
                                    </routeCode>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <routeCode nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>


                    <xsl:choose>
                        <xsl:when test="fhir:dosage/fhir:method/fhir:coding">
                            <xsl:apply-templates select="fhir:dosage/fhir:method">
                                <xsl:with-param name="pElementName" select="'approachSiteCode'" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <routeCode nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:choose>
                        <xsl:when test="fhir:dosage/fhir:dose">
                            <xsl:apply-templates select="fhir:dosage/fhir:dose">
                                <xsl:with-param name="pElementName" select="'doseQuantity'" />
                                <xsl:with-param name="pIncludeDatatype" select="false()" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <doseQuantity nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <consumable>
                        <xsl:call-template name="make-medication-information" />
                    </consumable>
                    <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/therapeutic-medication-response-extension']" />
                    <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension']" />
                    <!-- SG 2023-04 Moved this code into fhir2cda-Observation and called above (keeping the old ecr name for now - can remove later) -->
                    <!--<xsl:choose>
        <xsl:when test="
            fhir:extension[@url
            = 'http://hl7.org/fhir/us/ecr/StructureDefinition/therapeutic-medication-response-extension'] or fhir:extension[@url
            = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension']">
          <entryRelationship typeCode="CAUS">
            <observation classCode="OBS" moodCode="EVN">
              <xsl:comment select="' [eICR R2] Therapeutic Medication Response Observation '" />
              <templateId root="2.16.840.1.113883.10.20.15.2.3.37" extension="2019-04-01" />
              <id nullFlavor="NI" />
              <code code="67540-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Response to medication" />
              <statusCode code="completed" />
              <xsl:apply-templates select="fhir:effectivePeriod">
                <xsl:with-param name="pElementName" select="'effectiveTime'" />
              </xsl:apply-templates>
              <value xsi:type="CD">
                <xsl:attribute name="code" select="fhir:extension/fhir:valueCodeableConcept/fhir:coding/fhir:code/@value" />
                <xsl:attribute name="codeSystem" select="'2.16.840.1.113883.6.96'" />
                <xsl:attribute name="codeSystemName" select="'SNOMED CT'" />
                <xsl:attribute name="displayName" select="fhir:extension/fhir:valueCodeableConcept/fhir:coding/fhir:display/@value" />
              </value>

            </observation>
          </entryRelationship>
        </xsl:when>
      </xsl:choose>-->
                </substanceAdministration>

            </entryRelationship>
        </act>
    </xsl:template>

    <xsl:template name="make-medication-administration">
        <xsl:param name="moodCode">EVN</xsl:param>
        <substanceAdministration classCode="SBADM" moodCode="{$moodCode}">
            <!-- templateId -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'PCP'">
                    <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.10" />
                    <xsl:comment select="' MEDICATION ACTIVITY V2  '" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                </xsl:when>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <xsl:comment select="' [C-CDA R1.1] Medication Activity '" />
                    <templateId root="2.16.840.1.113883.10.20.22.4.16" />
                    <xsl:comment select="' [C-CDA R2.0] Medication Activity (V2)  '" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                </xsl:when>
                <xsl:otherwise>
                    <!--<xsl:apply-templates select="." mode="map-resource-to-template" />  -->
                    <xsl:comment select="' MEDICATION ACTIVITY V2  '" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- SG 20240119: Added processing for text -->
            <xsl:if test="fhir:dosage/fhir:text">
                <text>
                    <xsl:value-of select="fhir:dosage/fhir:text/@value" />
                </text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="fhir:status">
                    <xsl:apply-templates mode="medication-activity" select="fhir:status" />
                </xsl:when>
                <xsl:otherwise>
                    <statusCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- effective timing -->
            <!-- TODO: xsi:type="IVL_TS and null-->
            <xsl:apply-templates select="fhir:effectiveDateTime"/>

            <xsl:apply-templates select="fhir:effectivePeriod">
                <xsl:with-param name="pXSIType" select="'IVL_TS'" />
            </xsl:apply-templates>

            <xsl:apply-templates select="fhir:dateAsserted" />

            <!-- SG 20230216: An issue here is that C-CDA specifies that routeCode has to come from SPL Drug Route of Administration Terminology
                 and that the translation if it's present needs to come from SNOMED  
                 Checking to see what code system is provided by FHIR and dealing with
                 Could create (or find) a mapping table between SNOMED and NCI at some point -->
            <!--  If system is NCI (http://ncimeta.nci.nih.gov)(2.16.840.1.113883.3.26.1.1) process normally 
                 If system is SNOMED or anything else, put code translation and nullFlavor code
                 Assuming for now that there aren't other code systems being used here -->
            <xsl:choose>
                <xsl:when test="fhir:dosage/fhir:route/fhir:coding">
                    <xsl:choose>
                        <xsl:when test="fhir:dosage/fhir:route/fhir:coding/fhir:system/@value = 'http://ncimeta.nci.nih.gov'">
                            <xsl:apply-templates select="fhir:dosage/fhir:route">
                                <xsl:with-param name="pElementName" select="'routeCode'" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <!-- Takes care of SNOMED case and any others -->
                        <xsl:otherwise>
                            <routeCode nullFlavor="OTH">
                                <xsl:apply-templates select="fhir:dosage/fhir:route">
                                    <xsl:with-param name="pElementName" select="'translation'" />
                                </xsl:apply-templates>
                            </routeCode>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <routeCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- MD: add handle dosage.method to approachSiteCode -->
            <xsl:choose>
                <xsl:when test="fhir:dosage/fhir:method">
                    <xsl:choose>
                        <xsl:when test="fhir:dosage/fhir:method/fhir:coding">
                            <xsl:apply-templates select="fhir:dosage/fhir:method">
                                <xsl:with-param name="pElementName" select="'approachSiteCode'" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <approachSiteCode nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="fhir:dosage/fhir:dose">
                    <xsl:apply-templates select="fhir:dosage/fhir:dose">
                        <xsl:with-param name="pElementName" select="'doseQuantity'" />
                        <xsl:with-param name="pIncludeDatatype" select="false()" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <doseQuantity nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- Ming handle both medicationReference and medicationCodeableConcept -->
            <consumable>
                <xsl:call-template name="make-medication-information" />
            </consumable>

            <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/therapeutic-medication-response-extension']" />
            <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension']" />
        </substanceAdministration>
    </xsl:template>

    <xsl:template name="make-medication-information">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:choose>
                <xsl:when test="fhir:medicationReference">
                    <xsl:variable name="vReferenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="fhir:medicationReference/fhir:reference/@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $vReferenceURI]/fhir:resource/fhir:Medication">
                        <xsl:call-template name="check-for-trigger" />
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="fhir:medicationCodeableConcept">
                    <xsl:call-template name="check-for-trigger" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <!-- deal with both medicationReference and medicationCodeableConcept -->
        <manufacturedProduct classCode="MANU">
            <!-- templateId -->
            <xsl:choose>
                <xsl:when test="$vTriggerExtension">
                    <xsl:apply-templates mode="map-trigger-resource-to-template" select="." />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="fhir:medicationReference">
                            <xsl:apply-templates mode="map-resource-to-template" select="fhir:medicationReference" />
                        </xsl:when>
                        <xsl:when test="fhir:medicationCodeableConcept">
                            <xsl:apply-templates mode="map-resource-to-template" select="fhir:medicationCodeableConcept" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <!-- id -->
            <xsl:apply-templates select="fhir:identifier" />

            <xsl:choose>
                <xsl:when test="fhir:medicationReference">

                    <manufacturedMaterial>
                        <!-- MD: Add handle medication reference -->
                        <xsl:variable name="referenceURI">
                            <xsl:call-template name="resolve-to-full-url">
                                <xsl:with-param name="referenceURI" select="fhir:medicationReference/fhir:reference/@value" />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:comment>Medication <xsl:value-of select="$referenceURI" /></xsl:comment>
                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                            <xsl:apply-templates mode="medication-activity" select="fhir:resource/fhir:*">
                                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                            </xsl:apply-templates>
                        </xsl:for-each>
                    </manufacturedMaterial>
                </xsl:when>
                <xsl:when test="fhir:medicationCodeableConcept">
                    <!-- manufacturedMaterial -->
                    <manufacturedMaterial>
                        <xsl:apply-templates select="fhir:medicationCodeableConcept">
                            <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                        </xsl:apply-templates>
                    </manufacturedMaterial>
                </xsl:when>
            </xsl:choose>
        </manufacturedProduct>
    </xsl:template>

    <xsl:template name="make-medication-activity">
        <xsl:param name="moodCode">EVN</xsl:param>
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition'">eICR</xsl:when>
                <xsl:when test="//fhir:Communication/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-communication'">RR</xsl:when>
                <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Care-Plan'">PCP</xsl:when>
                <!-- Not sure if we will need to distinguish between HAI, HAI LTCF, single person, summary - for now, putting them all in the same bucket-->
                <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-single-person-report-questionnaireresponse'">HAI</xsl:when>
                <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-population-summary-questionnaireresponse'">HAI</xsl:when>
                <!-- MD: Add dental data exchange IG -->
                <xsl:when test="
                        //fhir:Composition/fhir:meta/fhir:profile/@value =
                        'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-referral-note'">DentalReferalNote</xsl:when>
                <xsl:when test="
                        //fhir:Composition/fhir:meta/fhir:profile/@value =
                        'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-consult-note'">DentalConsultNote</xsl:when>
                <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '57134-9'">DentalReferalNote</xsl:when>
                <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '34756-7'">DentalConsultNote</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <substanceAdministration classCode="SBADM" moodCode="{$moodCode}">

            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'DentalConsultNote' or $gvCurrentIg = 'DentalReferalNote'">
                    <xsl:comment select="' Medication Activity (V2) '" />
                    <templateId root="2.16.840.1.113883.10.20.22.4.16" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                </xsl:when>
                <xsl:when test="$gvCurrentIg = 'PCP'">
                    <xsl:comment select="' Medication Activity (V2) '" />
                    <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.10" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment select="' Medication Activity (V2) '" />
                    <templateId root="2.16.840.1.113883.10.20.22.4.16" />
                    <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.16" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- MD: add text since fhir:dosageInstruction/fhir:text needed to be supported -->
            <xsl:choose>
                <xsl:when test="fhir:dosageInstruction/fhir:text">
                    <text>
                        <xsl:value-of select="fhir:dosageInstruction/fhir:text/@value" />
                    </text>
                </xsl:when>
            </xsl:choose>

            <xsl:if test="$gvCurrentIg = 'PCP'">
                <code code="16076005" codeSystem="2.16.840.1.113883.6.96" displayName="Prescription" />
            </xsl:if>
            <xsl:choose>
                <xsl:when test="fhir:status">
                    <xsl:apply-templates mode="medication-activity" select="fhir:status" />
                </xsl:when>
                <xsl:otherwise>
                    <statusCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:dosageInstruction/fhir:timing">
                    <xsl:apply-templates mode="medication-activity" select="fhir:dosageInstruction/fhir:timing" />
                </xsl:when>
                <xsl:when test="fhir:authoredOn">
                    <xsl:apply-templates mode="medication-activity" select="fhir:authoredOn" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" xsi:type="IVL_TS" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- MD: add route -->
            <xsl:choose>
                <xsl:when test="fhir:dosageInstruction/fhir:route">
                    <xsl:apply-templates select="fhir:dosageInstruction/fhir:route">
                        <xsl:with-param name="pElementName" select="'routeCode'" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <routeCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- SG 20230216: MedicationRequest and MedicationDispense use the Dosage structure and 
            have fhir:doseAndRate in the path which was missing -->
            <xsl:choose>
                <!--<xsl:when test="fhir:dosageInstruction/fhir:doseQuantity/fhir:value/@value">-->
                <xsl:when test="fhir:dosageInstruction/fhir:doseAndRate/fhir:doseQuantity">
                    <!--<doseQuantity value="{fhir:dosageInstruction/fhir:doseQuantity/fhir:value/@value}" />-->
                    <xsl:apply-templates select="fhir:dosageInstruction/fhir:doseAndRate/fhir:doseQuantity">
                        <xsl:with-param name="pElementName" select="'doseQuantity'" />
                        <xsl:with-param name="pIncludeDatatype" select="false()" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <doseQuantity nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="fhir:medicationCodeableConcept">
                <consumable>
                    <manufacturedProduct classCode="MANU">
                        <xsl:comment select="' [C-CDA R2.0] Medication information (V2) '" />
                        <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.23" />
                        <id root="4b355395-790c-405d-826f-f5a8e242db89" />
                        <manufacturedMaterial>
                            <xsl:apply-templates select="." />
                            <!--<xsl:call-template name="CodeableConcept2CD" />-->
                        </manufacturedMaterial>
                    </manufacturedProduct>
                </consumable>
            </xsl:for-each>
            <xsl:for-each select="fhir:medicationReference">
                <consumable>
                    <manufacturedProduct classCode="MANU">
                        <xsl:comment select="' [C-CDA R2.0] Medication information (V2) '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.23" />
                        <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.23" />
                        <id root="4b355395-790c-405d-826f-f5a8e242db89" />
                        <manufacturedMaterial>
                            <!-- TODO: handle medication reference -->
                            <!-- MD: Add handle medication reference -->
                            <xsl:variable name="referenceURI">
                                <xsl:call-template name="resolve-to-full-url">
                                    <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:comment>Medication <xsl:value-of select="$referenceURI" /></xsl:comment>
                            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                <xsl:apply-templates mode="medication-activity" select="fhir:resource/fhir:*" />
                            </xsl:for-each>
                        </manufacturedMaterial>
                    </manufacturedProduct>
                </consumable>
            </xsl:for-each>
            <!-- SG 2023-04 Added for eCR (keeping the old ecr name for now - can remove later) -->
            <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/therapeutic-medication-response-extension']" />
            <xsl:apply-templates mode="entryRelationship" select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension']" />
        </substanceAdministration>
    </xsl:template>

    <xsl:template match="fhir:Medication" mode="medication-activity">
        <xsl:param name="pTriggerExtension" />
        <!-- code -->
        <xsl:apply-templates select="fhir:code">
            <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
        </xsl:apply-templates>
        <!-- manufacturerOrganization (Medication.manufacturer.reference(Organization)-->
    </xsl:template>

    <xsl:template match="fhir:status" mode="medication-activity">
        <statusCode>
            <xsl:choose>
                <xsl:when test="@value = 'active'">
                    <xsl:attribute name="code">active</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'completed'">
                    <xsl:attribute name="code">completed</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'cancelled'">
                    <xsl:attribute name="code">cancelled</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'unknown'">
                    <xsl:attribute name="nullFlavor">UNK</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </statusCode>
    </xsl:template>

    <xsl:template match="fhir:timing" mode="medication-activity">
        <xsl:for-each select="fhir:event">
            <effectiveTime>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="@value" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </effectiveTime>
        </xsl:for-each>
        <xsl:for-each select="fhir:repeat">
            <xsl:choose>
                <xsl:when test="fhir:boundsPeriod">
                    <xsl:for-each select="fhir:boundsPeriod">
                        <effectiveTime xsi:type="IVL_TS">
                            <xsl:choose>
                                <xsl:when test="fhir:start">
                                    <xsl:apply-templates mode="medication-start" select="fhir:start" />
                                    <xsl:choose>
                                        <xsl:when test="fhir:end">
                                            <xsl:apply-templates mode="medication-end" select="fhir:end" />
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:when>
                            </xsl:choose>
                        </effectiveTime>
                        <!-- 
                        <effectiveTime xsi:type="IVL_TS">
                            <low>
                                <xsl:attribute name="value">
                                    <xsl:call-template name="Date2TS">
                                        <xsl:with-param name="date" select="fhir:start/@value" />
                                        <xsl:with-param name="includeTime" select="true()" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </low>
                            <xsl:if test="fhir:end">
                                <high>
                                    <xsl:attribute name="value">
                                        <xsl:call-template name="Date2TS">
                                            <xsl:with-param name="date" select="fhir:end/@value" />
                                            <xsl:with-param name="includeTime" select="true()" />
                                        </xsl:call-template>
                                    </xsl:attribute>
                                </high>
                            </xsl:if>
                        </effectiveTime>
                         -->
                    </xsl:for-each>

                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime xsi:type="IVL_TS">
                        <low nullFlavor="NI" />
                    </effectiveTime>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="fhir:period and fhir:periodUnit">
                <effectiveTime operator="A" xsi:type="PIVL_TS">
                    <period unit="{fhir:periodUnit/@value}" value="{fhir:period/@value}" xsi:type="PQ" />
                </effectiveTime>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:start" mode="medication-start">
        <low>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="@value" />
                    <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
            </xsl:attribute>
        </low>
    </xsl:template>

    <xsl:template match="fhir:end" mode="medication-end">
        <high>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="@value" />
                    <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
            </xsl:attribute>
        </high>
    </xsl:template>

    <xsl:template match="fhir:authoredOn" mode="medication-activity">
        <effectiveTime xsi:type="IVL_TS">
            <low>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="@value" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </low>
            <high>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="@value" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </high>
        </effectiveTime>
    </xsl:template>

</xsl:stylesheet>
