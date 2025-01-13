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
<xsl:stylesheet exclude-result-prefixes="sdtc lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="native-xslt-uuid.xslt" />

    <!-- ********************************************************************* -->
    <!-- Generic Observation Processing                                        -->
    <!-- There are 3 different options (modes) for processing Observations:
        - entry (contained in a section)
        - entryRelationship (contained in another ClinicalStatement)
        - component (contained in an Organizer)
       Observations from FHIR can have contained hasMember elements: these
       will become Organizers in CDA                                         -->
    <!-- ********************************************************************* -->
    <!-- Generic Observation entry (no contained hasMember - if contained hasMember then Organizer)-->
    <!-- These are contained in a Section-->
    <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
    <xsl:template match="fhir:Observation[count(fhir:hasMember) = 0][not(fhir:category[1]/fhir:coding[fhir:code/@value = 'laboratory'])]" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <!-- Vital Signs -->
                <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
                <xsl:when test="fhir:category[1]/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/observation-category']/fhir:code/@value = 'vital-signs'">
                    <xsl:choose>
                        <!-- PCP creates the vital signs in a Health Concern -->
                        <xsl:when test="$gvCurrentIg = 'PCP'">
                            <xsl:call-template name="make-vitalsign-in-health-concern" />
                        </xsl:when>
                        <!-- All others are going to be standalone inside an Organizer -->
                        <xsl:otherwise>
                            <!-- <xsl:call-template name="make-vitalsign" /> -->
                            <xsl:variable name="vTest" select="fhir:code/fhir:coding/fhir:code/@value" />
                            <xsl:choose>
                                <!-- MD: fix drop blood pressure value us core has fix value 85354-9 for blood pressure -->
                                <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '85354-9'">
                                    <xsl:call-template name="make-blood-pressure-cluster" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="make-vitalsign" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- Everything other than Vital Signs -->
                <xsl:otherwise>
                    <xsl:call-template name="make-generic-observation" />
                </xsl:otherwise>
            </xsl:choose>
        </entry>
    </xsl:template>

    <!-- Generic Observation entryRelationship (no contained hasMember - if contained hasMember then Organizer)-->
    <!-- These are contained in another ClinicalStatement -->
    <xsl:template match="fhir:Observation[count(fhir:hasMember) = 0]" mode="entry-relationship">
        <xsl:param name="pTypeCode" select="'COMP'" />
        <entryRelationship typeCode="{$pTypeCode}">
            <xsl:call-template name="make-generic-observation" />
        </entryRelationship>
    </xsl:template>

    <!-- Generic Observation component (no contained hasMember - if contained hasMember then Organizer)-->
    <!-- These are contained in an Organizer -->
    <!-- MD: split into three part, since the blood pressure has its own component -->
    <xsl:template match="fhir:Observation[count(fhir:hasMember) = 0]" mode="component">
        <xsl:choose>
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="fhir:category[1]/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/observation-category']/fhir:code/@value = 'vital-signs'">
                <xsl:choose>
                    <!-- LOINC code for Blood pressure panel with all children optional -->
                    <xsl:when test="
                            fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org'] and
                            fhir:code/fhir:coding[fhir:code/@value = '85354-9']">
                        <xsl:for-each select="fhir:component">
                            <component>
                                <xsl:call-template name="make-blood-pressure" />
                            </component>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <component>
                            <xsl:call-template name="make-vitalsign" />
                        </component>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <component>
                    <xsl:call-template name="make-generic-observation" />
                </component>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Generic Component -->
    <xsl:template match="fhir:component">
        <observation classCode="OBS" moodCode="EVN">
            <!-- templateId -->
            <xsl:call-template name="get-template-id" />
            <!-- id -->
            <!-- Components don't have an id -->
            <id nullFlavor="NI" />
            <!-- code -->
            <xsl:apply-templates select="fhir:code" />
            <!-- statusCode -->
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/date-determined-extension']">
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/date-determined-extension']/fhir:valueDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- value -->
            <xsl:for-each select="fhir:valueCodeableConcept">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:for-each select="fhir:valueString">
                <value xsi:type="ST">
                    <xsl:value-of select="@value" />
                </value>
            </xsl:for-each>
            <xsl:apply-templates select="fhir:valueQuantity" />
            <xsl:apply-templates select="fhir:valueDateTime">
                <xsl:with-param name="pElementName" select="'value'" />
                <xsl:with-param name="pXSIType" select="'TS'" />
            </xsl:apply-templates>
            <!-- interpretationCode -->
            <xsl:for-each select="fhir:interpretation">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">interpretationCode</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>

            <xsl:for-each select="fhir:component">
                <entryRelationship> </entryRelationship>
            </xsl:for-each>
            <!-- reference -->
        </observation>
    </xsl:template>

    <!-- Named template: make-generic-observation -->
    <!-- This should cover most cases - there are still missing elements, but
       add them as we need them 
       Need to refactor - too big! -->
    <xsl:template name="make-generic-observation">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <observation classCode="OBS" moodCode="EVN">
            <!-- templateId -->
            <xsl:call-template name="get-template-id">
                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
            </xsl:call-template>
            <!-- id -->
            <xsl:call-template name="get-id" />
            <!-- code -->
            <!-- Catch any templates that need to be assertions -->
            <xsl:choose>
                <!-- Pregnancy, add others as needed -->
                <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '82810-3'">
                    <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
                </xsl:when>
                <!-- SG 20240307: Catch any social history observations that don't have a LOINC code and add a empty LOINC code -->
                <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
                <xsl:when test="fhir:category[1]/fhir:coding/fhir:code/@value = 'social-history' and not(fhir:code/fhir:coding/fhir:system/@value = 'http://loinc.org')">
                    <xsl:variable name="vCodeWithLOINC">
                        <code xmlns="http://hl7.org/fhir">
                            <xsl:for-each select="fhir:code/fhir:coding">
                                <xsl:copy-of select="." />
                            </xsl:for-each>
                            <coding xmlns="http://hl7.org/fhir">
                                <system xmlns="http://hl7.org/fhir" value="http://loinc.org" />
                            </coding>
                        </code>
                    </xsl:variable>
                    <xsl:apply-templates select="$vCodeWithLOINC/fhir:code">
                        <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="fhir:code">
                        <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            <!-- negationInd -->
            <!-- derivationExpr -->
            <!-- text -->
            <!-- statusCode -->
            <xsl:apply-templates select="fhir:status" />
            <!-- effectiveTime -->
            <!-- MD: add fhir:issued -->
            <xsl:choose>
                <xsl:when test="fhir:effectiveDateTime | fhir:effectivePeriod | fhir:effectiveTime | fhir:effectiveInstant">
                    <xsl:apply-templates select="fhir:effectiveDateTime | fhir:effectivePeriod | fhir:effectiveTime | fhir:effectiveInstant" />
                </xsl:when>
                <xsl:when test="fhir:issued">
                    <xsl:apply-templates select="fhir:issued" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- priorityCode -->
            <!-- repeatNumber -->
            <!-- languageCode -->
            <!-- value -->

            <!-- Ming to handle the value is missing -->
            <xsl:choose>
                <!-- Check and apply templates for valueCodeableConcept -->
                <xsl:when test="fhir:valueCodeableConcept">
                    <xsl:for-each select="fhir:valueCodeableConcept">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pElementName" select="'value'" />
                            <xsl:with-param name="pXSIType" select="'CD'" />
                            <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:when>

                <!-- Check and process valueBoolean -->
                <xsl:when test="fhir:valueBoolean">
                    <xsl:for-each select="fhir:valueBoolean">
                        <value xsi:type="BL">
                            <xsl:choose>
                                <xsl:when test="fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="@value" />
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>
                        </value>
                    </xsl:for-each>
                </xsl:when>

                <!-- Check and process valueString -->
                <xsl:when test="fhir:valueString">
                    <xsl:for-each select="fhir:valueString">
                        <xsl:choose>
                            <xsl:when test="fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                                <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                            </xsl:when>
                            <xsl:otherwise>
                                <value xsi:type="ST">
                                    <xsl:value-of select="@value" />
                                </value>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>

                <!-- Check and apply templates for valueQuantity -->
                <xsl:when test="fhir:valueQuantity">
                    <xsl:apply-templates select="fhir:valueQuantity" />
                </xsl:when>

                <!-- Check and apply templates for valueDateTime -->
                <xsl:when test="fhir:valueDateTime">
                    <xsl:apply-templates select="fhir:valueDateTime">
                        <xsl:with-param name="pElementName" select="'value'" />
                        <xsl:with-param name="pXSIType" select="'TS'" />
                    </xsl:apply-templates>
                </xsl:when>

                <xsl:when test="fhir:dataAbsentReason">
                    <value xsi:type="CD">
                        <xsl:apply-templates select="fhir:dataAbsentReason" mode="data-absent-reason" />
                    </value>
                </xsl:when>

                <!-- Default case: none of the expected elements are present -->
                <xsl:otherwise>
                    <value xsi:type="CD" nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- interpretationCode -->
            <xsl:apply-templates select="fhir:interpretation">
                <xsl:with-param name="pElementName">interpretationCode</xsl:with-param>
            </xsl:apply-templates>
            <!-- if this is a trigger code template and the value is a string and there is no interpretation, add interpretationCode -->
            <xsl:if test="$vTriggerExtension and fhir:valueString and not(fhir:interpretation)">
                <interpretationCode nullFlavor="NI" />
            </xsl:if>

            <!-- methodCode -->
            <xsl:apply-templates select="fhir:method">
                <xsl:with-param name="pElementName" select="'methodCode'" />
            </xsl:apply-templates>
            <!-- targetSiteCode -->
            <!-- precondition -->
            <!-- performer -->
            <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/date-determined-extension']">
                <performer>
                    <xsl:comment select="' Pregnancy Status Determination Date '" />
                    <xsl:apply-templates select="fhir:valueDateTime">
                        <xsl:with-param name="pElementName" select="'time'" />
                    </xsl:apply-templates>
                    <assignedEntity>
                        <id nullFlavor="NA" />
                    </assignedEntity>
                </performer>
            </xsl:for-each>
            <!-- MD add this for now, need to know there is any difference between 
                date-determined-extension with us-ph-date-determined-extension -->
            <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-date-determined-extension']">
                <performer>
                    <xsl:comment select="' Pregnancy Status Determination Date '" />
                    <xsl:apply-templates select="fhir:valueDateTime">
                        <xsl:with-param name="pElementName" select="'time'" />
                    </xsl:apply-templates>
                    <assignedEntity>
                        <id nullFlavor="NA" />
                    </assignedEntity>
                </performer>
            </xsl:for-each>
            <!-- author -->
            <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/date-recorded-extension']">
                <author>
                    <xsl:comment select="' Pregnancy Status Recorded Date '" />
                    <xsl:apply-templates select="fhir:valueDateTime">
                        <xsl:with-param name="pElementName" select="'time'" />
                    </xsl:apply-templates>
                    <assignedAuthor>
                        <id nullFlavor="NA" />
                    </assignedAuthor>
                </author>
            </xsl:for-each>
            <!-- MD add this for now, need to know there is any difference between 
                date-recorded-extension with us-ph-date-recorded-extension -->
            <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-date-recorded-extension']">
                <author>
                    <xsl:comment select="' Pregnancy Status Recorded Date '" />
                    <xsl:apply-templates select="fhir:valueDateTime">
                        <xsl:with-param name="pElementName" select="'time'" />
                    </xsl:apply-templates>
                    <assignedAuthor>
                        <id nullFlavor="NA" />
                    </assignedAuthor>
                </author>
            </xsl:for-each>
            <!-- informant -->
            <!-- subject -->
            <!-- specimen -->
            <!-- participant -->
            <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/odh/StructureDefinition/odh-Employer-extension']/fhir:valueReference">
                <!-- Put the Organization into a variable -->
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="vOrganization" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:*" />
                <participant typeCode="IND">
                    <participantRole classCode="ROL">
                        <!-- id -->
                        <xsl:call-template name="get-id" />
                        <xsl:apply-templates select="$vOrganization/fhir:address" />
                        <xsl:apply-templates select="$vOrganization/fhir:telecom" />
                        <playingEntity>
                            <xsl:apply-templates mode="data-type-ON" select="$vOrganization/fhir:name" />
                        </playingEntity>
                    </participantRole>
                </participant>
            </xsl:for-each>
            <xsl:for-each select="fhir:component">
                <xsl:choose>
                    <!-- Ingore birth order -->
                    <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '73771-8'" />
                    <!-- These are participants not entryRelationships - this code will work for Travel History only -->
                    <!-- Travel History isn't an Observation, it's an ACT - moved code to ACT processing file -->
                    <!--<xsl:when test="fhir:code/fhir:coding/fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-ParticipationType'">
                        <participant typeCode="{fhir:code/fhir:coding/fhir:code/@value}">
                            <participantRole classCode="TERR">
                                <xsl:choose>
                                    <xsl:when test="fhir:extension/@url='http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-address-extension'">
                                        <xsl:apply-templates select="fhir:extension/fhir:valueAddress"/>
                                    </xsl:when>
                                    <xsl:when test="fhir:valueCodeableConcept">
                                        <xsl:apply-templates select="fhir:valueCodeableConcept"/>
                                    </xsl:when>
                                </xsl:choose>
                            </participantRole>
                        </participant>
                    </xsl:when>-->
                    <!-- MD -->
                    <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '53691-2'">
                        <entryRelationship typeCode="REFR">
                            <observation classCode="OBS" moodCode="EVN">
                                <xsl:comment select="' [C-CDA PREG] Estimated Gestational Age of Pregnancy '" />
                                <templateId extension="2020-04-01" root="2.16.840.1.113883.10.20.22.4.280" />
                                <id root="{lower-case(uuid:get-uuid())}" />
                                <xsl:apply-templates select="fhir:code" />
                                <statusCode code="completed" />
                                <xsl:apply-templates select="fhir:extension/fhir:valueDateTime">
                                    <xsl:with-param name="pElementName" select="'effectiveTime'" />
                                </xsl:apply-templates>
                                <xsl:apply-templates select="fhir:valueQuantity" />
                            </observation>
                        </entryRelationship>
                    </xsl:when>
                    <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '57064-8'">
                        <entryRelationship typeCode="REFR">
                            <observation classCode="OBS" moodCode="EVN">
                                <xsl:comment select="' [C-CDA EDD] Delivery date Estimated from date fundal height reaches umb '" />
                                <templateId extension="2020-04-01" root="2.16.840.1.113883.10.20.22.4.297" />
                                <xsl:call-template name="get-id" />
                                <xsl:apply-templates select="fhir:code" />
                                <statusCode code="completed" />
                                <xsl:apply-templates select="fhir:valueDateTime" />
                            </observation>
                        </entryRelationship>
                    </xsl:when>
                    <xsl:otherwise>
                        <entryRelationship>
                            <xsl:choose>
                                <!-- These 3 ODH componenents are REFR - going to make the default COMP -->
                                <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '87729-0' or fhir:code/fhir:coding/fhir:code/@value = '86188-0' or fhir:code/fhir:coding/fhir:code/@value = '21844-6'">
                                    <xsl:attribute name="typeCode" select="'REFR'" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="typeCode" select="'COMP'" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:apply-templates select="." />
                        </entryRelationship>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <!-- If this is eICR and this is a Result Observation Trigger Code template -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:if test="$vTriggerExtension and fhir:category[1]/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/observation-category']/fhir:code/@value = 'laboratory'">
                <entryRelationship typeCode="COMP">
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' [C-CDA ID] Laboratory Observation Result Status (ID) '" />
                        <templateId extension="2018-09-01" root="2.16.840.1.113883.10.20.22.4.419" />
                        <code code="92236-9" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Laboratory Observation Result Status" />
                        <xsl:apply-templates mode="map-lab-obs-status" select="fhir:status" />
                    </observation>
                </entryRelationship>
            </xsl:if>
            <!-- If this is a Pregnancy Observation add a matching Pregnancy Outcome Observation -->
            <xsl:if test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-status-observation'">
                <xsl:variable name="vPregnancyStatusFullUrl" select="../../fhir:fullUrl/@value" />
                <xsl:for-each select="//fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-outcome-observation']">
                    <xsl:variable name="vRelatedPregnancyStatusFullUrl" select="fhir:focus/fhir:reference/@value" />
                    <xsl:if test="$vPregnancyStatusFullUrl = $vRelatedPregnancyStatusFullUrl">
                        <entryRelationship typeCode="COMP">
                            <sequenceNumber value="{fhir:component[fhir:code/fhir:coding/fhir:code/@value='73771-8']/fhir:valueInteger/@value}" />
                            <xsl:call-template name="make-generic-observation" />
                        </entryRelationship>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <!-- reference -->
            <!-- referenceRange -->
            <xsl:for-each select="fhir:referenceRange">
                <xsl:call-template name="get-reference-range" />
            </xsl:for-each>
        </observation>
    </xsl:template>

    <!-- Generic Questionnaire Item Observation -->
    <!--<xsl:template
        match="fhir:item[fhir:linkId/@value = ('risk-factor-birth-weight', 'risk-factor-gestational-age', 'inborn-outborn-observation', 'criteria-used', 'died', 'los-contributed-to-death')][fhir:answer]">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <!-\- @negationInd -\->
            <xsl:attribute name="negationInd" select="'false'" />
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <id nullFlavor="NA" />
            <code>
                <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
                <!-\-        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />-\->
            </code>
            <statusCode code="completed" />
            <effectiveTime nullFlavor="NA" />
            <xsl:apply-templates select="fhir:answer" />
        </observation>
    </xsl:template>-->

    <!-- Assertion Pattern Questionnaire Item Observation -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = ('risk-factor-central-line', 'event-type')][fhir:answer]">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <!-\- @negationInd -\->
            <xsl:choose>
                <xsl:when test="fhir:answer/fhir:valueBoolean/@value = 'true'">
                    <xsl:attribute name="negationInd" select="'false'" />
                </xsl:when>
                <xsl:when test="fhir:answer/fhir:valueBoolean/@value = 'false'">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:when>
            </xsl:choose>
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <!-\- id -\->
            <xsl:choose>
                <xsl:when test="$vLinkId = ('event-type')">
                    <xsl:call-template name="get-id">
                        <xsl:with-param name="pNoNullAllowed" select="true()" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NA" />
                </xsl:otherwise>
            </xsl:choose>
            <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
            <statusCode code="completed" />
            <effectiveTime nullFlavor="NA" />
            <xsl:choose>
                <xsl:when test="$vLinkId = ('event-type')">
                    <xsl:apply-templates select="fhir:answer" />
                </xsl:when>
                <xsl:otherwise>
                    <value xsi:type="CD">
                        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
                    </value>
                </xsl:otherwise>
            </xsl:choose>
        </observation>
    </xsl:template>-->

    <!-- ********************************************************************* -->
    <!-- Suppress Questionnaire Item Processing                                -->
    <!-- ********************************************************************* -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'gestational-age-known'][fhir:answer/fhir:valueBoolean/@value = 'true']" />-->

    <!-- Suppress item discharge-date - used in EncompassingEncounter -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'discharge-date']" />-->

    <!-- ********************************************************************* -->
    <!-- Specific Observation Processing                                       -->
    <!-- ********************************************************************* -->

    <!-- Gestational Age Known -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'gestational-age-known'][fhir:answer/fhir:valueBoolean/@value = 'false']">
        <!-\- Special processing for this item - if this item is false then the next item (risk-factor-gestational-age) is not enabled
         But if this is false, then the Gestataional Age at Birth template needs to be created wtih a value/@nullFlavor='UNK'
         So we are going to set our linkId='risk-factor-gestational-age' and build that template-\->
        <xsl:variable name="vLinkId" select="'risk-factor-gestational-age'" />
        <observation classCode="OBS" moodCode="EVN">
            <xsl:attribute name="negationInd" select="'false'" />
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <id nullFlavor="NA" />
            <code>
                <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
            </code>
            <statusCode code="completed" />
            <value nullFlavor="UNK" />
        </observation>
    </xsl:template>-->

    <!-- SG 20220213: Added for HAI LTC -->
    <!-- Transfer From Acute Care Facility -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'transfer-from-acute-care-facility']">
        <xsl:param name="pEntryRelationships" />
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <xsl:variable name="vTransferred" select="fhir:answer/fhir:valueBoolean/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <id nullFlavor="NA" />
            <xsl:choose>
                <xsl:when test="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code">
                    <code>
                        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
                    </code>
                </xsl:when>
                <xsl:otherwise>
                    <code>
                        <xsl:apply-templates select="$questionnaire-mapping/fhir:map[@linkId = $vLinkId]/fhir:coding" />
                    </code>
                </xsl:otherwise>
            </xsl:choose>
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="$vTransferred = 'true'">
                    <effectiveTime>
                        <low>
                            <xsl:attribute name="value">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="//fhir:item[fhir:linkId/@value = ('date-of-last-transfer')]/fhir:answer/fhir:valueDate/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:attribute>
                        </low>
                    </effectiveTime>
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NA" />
                </xsl:otherwise>
            </xsl:choose>
            <value value="{fhir:answer/fhir:valueBoolean/@value}" xsi:type="BL" />
            <xsl:if test="$vTransferred = 'true'">
                <xsl:for-each select="$pEntryRelationships">
                    <entryRelationship typeCode="REFR">
                        <xsl:apply-templates select="." />
                    </entryRelationship>
                </xsl:for-each>
            </xsl:if>
        </observation>
    </xsl:template>
    <xsl:template match="fhir:item[fhir:linkId/@value = 'antibiotic-at-time-of-transfer']">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <xsl:choose>
                <xsl:when test="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code">
                    <code>
                        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
                    </code>
                </xsl:when>
                <xsl:otherwise>
                    <code>
                        <xsl:apply-templates select="$questionnaire-mapping/fhir:map[@linkId = $vLinkId]/fhir:coding" />
                    </code>
                </xsl:otherwise>
            </xsl:choose>
            <statusCode code="completed" />
            <!-\- Resident was on antibiotic therapy for this organism at the time of transfer 
            set value="true" if this resident was on antibiotic therapy for this organism at the time of transfer.
            set value="false" if this resident was not on antibiotic therapy for this organism at the time of transfer -\->
            <value value="true" xsi:type="BL" />
        </observation>
    </xsl:template>-->

    <!-- SG 20220206: Added for HAI LTC -->
    <!-- Specific Organism Type -->
    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'specific-organism-type']">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <!-\- templateId -\->
            <xsl:call-template name="get-template-id" />
            <id nullFlavor="NA" />
            <xsl:choose>
                <xsl:when test="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code">
                    <code>
                        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
                    </code>
                </xsl:when>
                <xsl:otherwise>
                    <code>
                        <xsl:apply-templates select="$questionnaire-mapping/fhir:map[@linkId = $vLinkId]/fhir:coding" />
                    </code>
                </xsl:otherwise>
            </xsl:choose>
            <statusCode code="completed" />
            <effectiveTime nullFlavor="NA" />
            <xsl:comment select="' Specific Organism Type '" />
            <value xsi:type="CD">
                <xsl:apply-templates select="fhir:answer/fhir:valueCoding" />
            </value>
            <entryRelationship typeCode="COMP">
                <xsl:apply-templates mode="questionnaire-observation" select="//fhir:item[fhir:linkId/@value = 'findings-group']" />
            </entryRelationship>
        </observation>
    </xsl:template>-->

    <!--<xsl:template match="fhir:item[fhir:linkId/@value = ('resident-days', 'resident-admissions', 'number-admissions-on-c-diff-treatment', 'number-c-diff-treatment-starts')]">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <observation classCode="OBS" moodCode="EVN">
            <xsl:call-template name="get-template-id" />
            <code>
                <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
            </code>
            <statusCode code="completed" />
            <value unit="d" value="{fhir:answer/fhir:valueInteger/@value}" xsi:type="PQ" />
        </observation>
    </xsl:template>-->

    <!-- fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension'] -> Reportability Response Priority (Observation) -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension']">
        <entry typeCode="DRIV">
            <observation classCode="OBS" moodCode="EVN">
                <xsl:call-template name="get-template-id" />
                <xsl:comment select="' Reportability Response Priority '" />
                <xsl:call-template name="get-id">
                    <xsl:with-param name="pNoNullAllowed" select="true()" />
                </xsl:call-template>
                <code code="RR9" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Reportability response priority" />
                <xsl:apply-templates select="fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
            </observation>
        </entry>
    </xsl:template>

    <!-- Gender Identity -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity']" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <observation classCode="OBS" moodCode="EVN">
                <xsl:comment select="' [NHCS R1D3] Gender Identity Observation '" />
                <templateId extension="2019-04-01" root="2.16.840.1.113883.10.20.34.3.45" />
                <id nullFlavor="NI" />
                <code code="76691-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Gender identity" />
                <statusCode code="completed" />
                <xsl:apply-templates select="//fhir:Composition/fhir:date">
                    <xsl:with-param name="pElementName" select="'effectiveTime'" />
                </xsl:apply-templates>
                <xsl:apply-templates select="fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
            </observation>
        </entry>
    </xsl:template>

    <!-- MD: Add PH Gender Identity for social history section-->
    <!-- SG 2023-04 eCR updated to add date and fixed value -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-genderidentity-extension']" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <observation classCode="OBS" moodCode="EVN">
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.38" />
                <xsl:comment select="' [C-CDA R2.1 Companion Guide] Gender Identity Observation (V3) '" />
                <templateId extension="2022-06-01" root="2.16.840.1.113883.10.20.34.3.45" />
                <id nullFlavor="NI" />
                <code code="76691-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Gender identity" />
                <statusCode code="completed" />
                <xsl:choose>
                    <xsl:when test="fhir:extension[@url = 'period']/fhir:valuePeriod">
                        <xsl:apply-templates select="fhir:extension[@url = 'period']/fhir:valuePeriod">
                            <xsl:with-param name="pElementName" select="'effectiveTime'" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <effectiveTime>
                            <low nullFlavor="NI" />
                        </effectiveTime>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:apply-templates select="fhir:extension[@url = 'value']/fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
            </observation>
        </entry>
    </xsl:template>

    <!-- Birth Sex -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex']" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <observation classCode="OBS" moodCode="EVN">
                <xsl:comment select="' [C-CDA R2.1 Companion Guide] Birth Sex Observation '" />
                <templateId extension="2016-06-01" root="2.16.840.1.113883.10.20.22.4.200" />
                <code code="76689-9" codeSystem="2.16.840.1.113883.6.1" displayName="Sex Assigned At Birth" />
                <statusCode code="completed" />
                <xsl:apply-templates select="parent::*/fhir:birthDate">
                    <xsl:with-param name="pElementName" select="'effectiveTime'" />
                </xsl:apply-templates>
                <xsl:choose>
                    <xsl:when test="fhir:valueCode/@value = 'F'">
                        <value code="F" codeSystem="2.16.840.1.113883.5.1" codeSystemName="AdministrativeGender" displayName="Female" xsi:type="CD" />
                    </xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'M'">
                        <value code="M" codeSystem="2.16.840.1.113883.5.1" codeSystemName="AdministrativeGender" displayName="Male" xsi:type="CD" />
                    </xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'UNK'">
                        <value nullFlavor="UNK" xsi:type="CD" />
                    </xsl:when>
                </xsl:choose>
            </observation>
        </entry>
    </xsl:template>

    <!-- SG 2023-04 eCR (moved from fhir2cda-SubstanceAdministration) -->
    <xsl:template
        match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/therapeutic-medication-response-extension'] | fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension']"
        mode="entryRelationship">
        <entryRelationship typeCode="CAUS">
            <observation classCode="OBS" moodCode="EVN">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R2] Therapeutic Medication Response Observation '" />
                <templateId extension="2019-04-01" root="2.16.840.1.113883.10.20.15.2.3.37" />
                <id nullFlavor="NI" />
                <code code="67540-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Response to medication" />
                <!-- MD: not hard code <statusCode code="completed" />-->
                <xsl:apply-templates select="../fhir:status" />
                <!-- MD: if effectivePeriod used -->
                <xsl:apply-templates select="../fhir:effectivePeriod" />
                <xsl:apply-templates select="../fhir:effectiveDateTime" />
                <xsl:apply-templates select="fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
            </observation>
        </entryRelationship>
    </xsl:template>

    <!-- MD: Tribal Affiliation extension  -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-tribal-affiliation-extension']" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <observation classCode="OBS" moodCode="EVN">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R2 STU3] Tribal Affiliation Observation  '" />
                <templateId extension="2021-01-01" root="2.16.840.1.113883.10.20.15.2.3.48" />
                <id nullFlavor="NI" />
                <xsl:for-each select="fhir:extension[@url = 'TribeName']">
                    <xsl:apply-templates select="." />
                    <!--<xsl:call-template name="CodeableConcept2CD" />-->
                </xsl:for-each>
                <statusCode code="completed" />
                <effectiveTime nullFlavor="NI" />
                <xsl:for-each select="fhir:extension[@url = 'EnrolledTribeMember']">
                    <value xsi:type="BL">
                        <xsl:attribute name="value">
                            <xsl:value-of select="fhir:valueBoolean/@value" />
                        </xsl:attribute>
                    </value>
                </xsl:for-each>
            </observation>
        </entry>
    </xsl:template>

    <xsl:key match="fhir:Goal[fhir:outcomeReference]" name="outcome-references" use="fhir:outcomeReference/fhir:reference/@value" />

    <xsl:template match="fhir:Observation[ancestor::fhir:entry/fhir:fullUrl/@value = //fhir:Goal/fhir:outcomeReference/fhir:reference/@value]" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:comment>Outcome Observation</xsl:comment>
        <entry>
            <xsl:if test="$generated-narrative = 'generated'">
                <xsl:attribute name="typeCode">DRIV</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="make-outcome-observation" />
        </entry>
    </xsl:template>

    <xsl:template name="make-outcome-observation">
        <observation classCode="OBS" moodCode="EVN">
            <!-- [CCDA R2.0] Outcome Observation -->
            <templateId root="2.16.840.1.113883.10.20.22.4.144" />
            <!-- [PCP R1 STU1] Outcome Observation -->
            <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.16" />
            <xsl:call-template name="get-id" />
            <xsl:for-each select="fhir:code">
                <xsl:apply-templates select="." />
                <!--<xsl:call-template name="CodeableConcept2CD" />-->
            </xsl:for-each>
            <statusCode code="completed" />
            <effectiveTime>
                <xsl:choose>
                    <xsl:when test="fhir:effectiveDateTime/@value">
                        <low>
                            <xsl:attribute name="value">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:effectiveDateTime/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:attribute>
                        </low>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="nullFlavor">NI</xsl:attribute>
                        <low nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
            </effectiveTime>
        </observation>
    </xsl:template>

    <!--<xsl:template match="fhir:item[fhir:linkId/@value = 'event-type']" mode="infection">
        <observation classCode="OBS" moodCode="EVN" negationInd="false">
            <!-\- [C-CDA R1.1] Problem Observation -\->
            <templateId root="2.16.840.1.113883.10.20.22.4.4" />
            <!-\- [HAI R2N1] Infection-Type Observation -\->
            <templateId root="2.16.840.1.113883.10.20.5.6.139" />
            <id extension="{$infection-id}" root="{$docId}" />
            <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
            <statusCode code="completed" />
            <effectiveTime>
                <low value="20180102" />
            </effectiveTime>
            <xsl:message>Outputting infection-type observation</xsl:message>
            <xsl:for-each select="fhir:answer[fhir:valueCoding]">
                <!-\-<xsl:call-template name="CodeableConcept2CD">-\->
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">value</xsl:with-param>
                    <xsl:with-param name="pXSIType">CD</xsl:with-param>
                </xsl:apply-templates>
                <!-\-</xsl:call-template>-\->
            </xsl:for-each>
            <xsl:apply-templates mode="diagnosis" select="//fhir:item[fhir:linkId[@value = 'criteria-used']]" />
            <xsl:apply-templates mode="condition" select="//fhir:item[fhir:linkId[@value = 'infection-condition']]" />
        </observation>
    </xsl:template>-->

    <!-- The below is specific to PCP usually Vital Signs are in Organizers, not Health Concern Act... 
       changed name and added logic so that only PCP uses this code-->

    <xsl:template name="make-vitalsign-in-health-concern">
        <act classCode="ACT" moodCode="EVN">
            <!-- [C-CDA R2.1] Health Concern Act (V2) -->
            <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.132" />
            <!-- [PCP R1 STU1] Health Concern Act (Pharmacist Care Plan) -->
            <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.8" />
            <id nullFlavor="NI" />
            <code code="75310-3" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Health Concern" />
            <statusCode code="active" />
            <entryRelationship typeCode="REFR">
                <xsl:apply-templates select="." />
                <!--<xsl:call-template name="make-vitalsign" />-->
            </entryRelationship>
        </act>
    </xsl:template>

    <!-- Pulled the actual vital sign obs out of make-vitalsign-in-health-concern to make it 
       standalone so we can use in other use cases-->

    <!-- A Vital Sign Observation from FHIR translates to an Observation if it doesn't contain hasMember 
      (if it does contain hasMember it's an Organizer) -->
    <xsl:template name="make-vitalsign">
        <observation classCode="OBS" moodCode="EVN">
            <xsl:apply-templates mode="map-resource-to-template" select="." />
            <xsl:call-template name="get-id" />
            <xsl:apply-templates select="fhir:code" />
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="fhir:effectiveDateTime">
                    <xsl:apply-templates select="fhir:effectiveDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- SG 20240307: C-CDA Vital Signs Observation does not allow value with no unit, updated to deal with that case
                 Deal with case where Vital Sign has a code -->
            <xsl:choose>
                <xsl:when test="fhir:valueQuantity">
                    <value xsi:type="PQ">
                        <xsl:choose>
                            <xsl:when test="fhir:valueQuantity/fhir:unit/@value">
                                <xsl:attribute name="unit" select="fhir:valueQuantity/fhir:unit/@value" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="unit" select="'no_unit'" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:attribute name="value" select="fhir:valueQuantity/fhir:value/@value" />
                    </value>
                </xsl:when>
                <!-- SG 20240307: C-CDA Vital Signs Observation can only have a data type of PQ so have to get this in there
                     PQ can have a translation for a code-->
                <xsl:when test="fhir:valueCodeableConcept">
                    <value xsi:type="PQ" unit="no_unit" nullFlavor="OTH">
                        <xsl:for-each select="fhir:valueCodeableConcept">
                            <xsl:for-each select="fhir:coding">
                                <translation>
                                    <xsl:attribute name="code">
                                        <xsl:value-of select="fhir:code/@value" />
                                    </xsl:attribute>
                                    <xsl:variable name="codeSystem">
                                        <xsl:call-template name="convertURI">
                                            <xsl:with-param name="uri" select="fhir:system/@value" />
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:attribute name="codeSystem">
                                        <xsl:value-of select="$codeSystem" />
                                    </xsl:attribute>
                                    <xsl:if test="fhir:display">
                                        <xsl:attribute name="displayName">
                                            <xsl:value-of select="fhir:display/@value" />
                                        </xsl:attribute>
                                    </xsl:if>
                                    <xsl:for-each select="following-sibling::fhir:text">
                                        <originalText>
                                            <xsl:value-of select="@value" />
                                        </originalText>
                                    </xsl:for-each>
                                </translation>
                            </xsl:for-each>
                        </xsl:for-each>
                    </value>
                </xsl:when>
                <xsl:otherwise>
                    <value xsi:type="PQ" unit="no_unit" nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="fhir:component/fhir:valueQuantity">
                <value xsi:type="PQ">
                    <xsl:choose>
                        <xsl:when test="fhir:unit/@value">
                            <xsl:attribute name="unit" select="fhir:unit/@value" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="unit" select="'no_unit'" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="value" select="fhir:value/@value" />
                </value>
            </xsl:for-each>
            <xsl:for-each select="fhir:interpretation">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">interpretationCode</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </observation>
    </xsl:template>

    <!-- MD: -->
    <xsl:template name="make-blood-pressure">
        <observation classCode="OBS" moodCode="EVN">
            <templateId root="2.16.840.1.113883.10.20.22.4.27" />
            <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.27" />
            <xsl:call-template name="get-id" />
            <xsl:apply-templates select="fhir:code" />
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="../fhir:effectiveDateTime">
                    <xsl:apply-templates select="../fhir:effectiveDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="fhir:valueQuantity">
                <value unit="{fhir:unit/@value}" value="{fhir:value/@value}" xsi:type="PQ" />
            </xsl:for-each>
        </observation>
    </xsl:template>

    <!-- MD: add template for blood-pressure -->
    <xsl:template name="make-blood-pressure-cluster">
        <organizer classCode="CLUSTER" moodCode="EVN">
            <xsl:comment select="' [C-CDA R2.0] Vital sign organizer '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.26" />
            <xsl:comment select="' [C-CDA R2.0] Vital sign organizer '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.26" extension="2015-08-01" />
            <xsl:call-template name="get-id" />
            <code code="46680005" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Vital Signs">
                <translation code="74728-7" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Vital signs, weight, height, head circumference, oximetry, BMI, and BSA panel " />
            </code>
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="fhir:effectiveDateTime">
                    <xsl:apply-templates select="fhir:effectiveDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="fhir:component">
                <component>
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' [C-CDA R2.0] Vital sign observation '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.27" />
                        <xsl:comment select="' [C-CDA R2.0] Vital sign observation '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.27" extension="2014-06-09" />
                        <xsl:call-template name="get-id" />
                        <xsl:apply-templates select="fhir:code" />
                        <statusCode code="completed" />
                        <xsl:choose>
                            <xsl:when test="../fhir:effectiveDateTime">
                                <xsl:apply-templates select="../fhir:effectiveDateTime" />
                            </xsl:when>
                            <xsl:otherwise>
                                <effectiveTime nullFlavor="NI" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:for-each select="fhir:valueQuantity">
                            <value unit="{fhir:unit/@value}" value="{fhir:value/@value}" xsi:type="PQ" />
                        </xsl:for-each>
                    </observation>
                </component>
            </xsl:for-each>
        </organizer>
    </xsl:template>

    <!-- Planned Observation (Observation) fhir:ServiceRequest -->
    <xsl:template match="fhir:ServiceRequest" mode="entry">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
        <!-- MD: if fhir ServiceRequest is a procedure, transform it to cda planned procedure  
        if fhir ServiceRequsst is an observation, transform it to cda planned observation 
        all others may transform it to cda planned act. 
        not use  <xsl:call-template name="get-template-id"> for now since it is mapping to OBS only. we should think a more common approach
        -->
        <xsl:choose>
            <xsl:when test="fhir:code/fhir:coding/fhir:system/@value = 'https://ada.org/en/publications/cdt'">
                <entry>
                    <procedure classCode="PROC">
                        <xsl:choose>
                            <xsl:when test="fhir:intent/@value = 'plan'">
                                <xsl:attribute name="moodCode">
                                    <xsl:value-of select="'INT'" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:when test="fhir:intent/@value = 'order'">
                                <xsl:attribute name="moodCode">
                                    <xsl:value-of select="'RQO'" />
                                </xsl:attribute>
                            </xsl:when>
                        </xsl:choose>
                        <templateId root="2.16.840.1.113883.10.20.22.4.41" />
                        <xsl:comment select="' Planned Procedure '" />
                        <id root="{lower-case(uuid:get-uuid())}" />
                        <code>
                            <xsl:attribute name="code">
                                <xsl:value-of select="fhir:code/fhir:coding/fhir:code/@value" />
                            </xsl:attribute>
                            <xsl:variable name="vCodeSystemUri" select="fhir:code/fhir:coding/fhir:system/@value" />
                            <xsl:choose>
                                <xsl:when test="$mapping/map[@uri = $vCodeSystemUri]">
                                    <xsl:attribute name="codeSystem">
                                        <xsl:value-of select="$mapping/map[@uri = $vCodeSystemUri][1]/@oid" />
                                    </xsl:attribute>
                                </xsl:when>
                            </xsl:choose>
                            <xsl:apply-templates mode="display" select="fhir:code/fhir:coding/fhir:display" />
                        </code>
                        <xsl:apply-templates mode="text" select="fhir:code/fhir:text" />
                        <xsl:apply-templates select="fhir:status" />
                        <xsl:for-each select="fhir:bodySite/fhir:coding">
                            <targetSiteCode>
                                <xsl:attribute name="code">
                                    <xsl:value-of select="./fhir:code/@value" />
                                </xsl:attribute>
                                <xsl:variable name="vBodySiteSystemUri" select="./fhir:system/@value" />
                                <xsl:choose>
                                    <xsl:when test="$mapping/map[@uri = $vBodySiteSystemUri]">
                                        <xsl:attribute name="codeSystem">
                                            <xsl:value-of select="$mapping/map[@uri = $vBodySiteSystemUri][1]/@oid" />
                                        </xsl:attribute>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:apply-templates mode="display" select="./fhir:display" />
                            </targetSiteCode>
                        </xsl:for-each>
                        <xsl:choose>
                            <xsl:when test="fhir:encounter">
                                <entryRelationship typeCode="RSON">
                                    <encounter classCode="ENC" moodCode="INT">
                                        <xsl:comment select="' Planned  Encounter V2 '" />
                                        <templateId root="2.16.840.1.113883.10.20.22.4.40" />
                                        <id root="{lower-case(uuid:get-uuid())}" />
                                        <xsl:variable name="referenceURI">
                                            <xsl:call-template name="resolve-to-full-url">
                                                <xsl:with-param name="referenceURI" select="fhir:encounter/fhir:reference/@value" />
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                        <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                            <xsl:apply-templates mode="serviceRequest" select="fhir:resource/fhir:*" />
                                        </xsl:for-each>
                                    </encounter>
                                </entryRelationship>
                            </xsl:when>
                        </xsl:choose>
                    </procedure>
                </entry>
            </xsl:when>
            <xsl:otherwise>
                <!-- Planned Observation -->
                <entry typeCode="DRIV">
                    <observation classCode="OBS" moodCode="RQO">
                        <!-- templateId -->
                        <xsl:call-template name="get-template-id">
                            <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                        </xsl:call-template>
                        <xsl:call-template name="get-id" />

                        <xsl:apply-templates select="fhir:code">
                            <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                        </xsl:apply-templates>
                        <!-- move statusCode after code -->
                        <!-- MD: Do not hard code the statusCode 
                            <statusCode code="active" /> only for the value is completed 
                        -->
                        <xsl:choose>
                            <xsl:when test="fhir:status/@value = 'completed'">
                                <statusCode code="active" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="fhir:status" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- SG 20231123: Updated effective time processing to occurenceDateTime -->
                        <xsl:call-template name="get-effective-time">
                            <xsl:with-param name="pElement" select="fhir:occurrenceDateTime" />
                        </xsl:call-template>
                        <!-- SG 20231124: Added bodySite (targetSiteCode) -->
                        <xsl:for-each select="fhir:bodySite/fhir:coding">
                            <targetSiteCode>
                                <xsl:attribute name="code">
                                    <xsl:value-of select="./fhir:code/@value" />
                                </xsl:attribute>
                                <xsl:variable name="vBodySiteSystemUri" select="./fhir:system/@value" />
                                <xsl:choose>
                                    <xsl:when test="$mapping/map[@uri = $vBodySiteSystemUri]">
                                        <xsl:attribute name="codeSystem">
                                            <xsl:value-of select="$mapping/map[@uri = $vBodySiteSystemUri][1]/@oid" />
                                        </xsl:attribute>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:apply-templates mode="display" select="./fhir:display" />
                            </targetSiteCode>
                        </xsl:for-each>

                        <!-- SG 20231124: ServiceRequest.performer -->
                        <xsl:for-each select="fhir:performer">
                            <xsl:for-each select="fhir:reference">
                                <xsl:variable name="referenceURI">
                                    <xsl:call-template name="resolve-to-full-url">
                                        <xsl:with-param name="referenceURI" select="@value" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:comment>Performer <xsl:value-of select="$referenceURI" /></xsl:comment>
                                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/*">
                                    <xsl:call-template name="make-performer" />
                                </xsl:for-each>
                            </xsl:for-each>
                        </xsl:for-each>
                        <!-- author (C-CDA Author Participation template) -->
                        <!--<xsl:if test="fhir:authoredOn">
                            <!-\-<xsl:variable name="time">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:authoredOn/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:variable>
                            <time value="{$time}" />-\->

                            <!-\- SG 20231124: This comes from ServiceRequest.requester -\->
                            <xsl:choose>
                                <xsl:when test="fhir:requester">
                                    <xsl:apply-templates select="fhir:requester" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <id nullFlavor="NI" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>-->
                        <!-- author -->
                        <xsl:apply-templates select="fhir:requester" />
                    </observation>
                </entry>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- <xsl:template match="//fhir:item[fhir:linkId[@value = 'pathogen-identified']]" mode="pathogen-identified">
        <observation classCode="OBS" moodCode="EVN">
            <templateId root="2.16.840.1.113883.10.20.22.4.2" />
            <templateId root="2.16.840.1.113883.10.20.5.6.145" />
            <id nullFlavor="NA" />
            <code code="41852-5" codeSystem="2.16.840.1.113883.6.1" displayName="Microogranism identified" />
            <statusCode code="completed" />
            <effectiveTime nullFlavor="NA" />
            <xsl:for-each select="fhir:answer[fhir:valueCoding]">
                <!-\-<xsl:call-template name="CodeableConcept2CD">-\->
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">value</xsl:with-param>
                    <xsl:with-param name="pXSIType">CD</xsl:with-param>
                </xsl:apply-templates>
                <!-\-</xsl:call-template>-\->
            </xsl:for-each>
        </observation>
    </xsl:template>-->

    <!--<xsl:template match="//fhir:item[fhir:linkId[@value = 'pathogen-ranking']]" mode="pathogen-ranking">
        <observation classCode="OBS" moodCode="EVN">
            <!-\- Problem Observation -\->
            <templateId root="2.16.840.1.113883.10.20.22.4.4" />
            <!-\- Pathogen Ranking Observation -\->
            <templateId root="2.16.840.1.113883.10.20.5.6.147" />
            <id nullFlavor="NA" />
            <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
            <statusCode code="completed" />
            <xsl:for-each select="fhir:answer[fhir:valueCoding]">
                <!-\-<xsl:call-template name="CodeableConcept2CD">-\->
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">value</xsl:with-param>
                    <xsl:with-param name="pXSIType">CD</xsl:with-param>
                </xsl:apply-templates>
                <!-\-</xsl:call-template>-\->
            </xsl:for-each>
        </observation>
    </xsl:template>-->

    <!--<xsl:template name="no-pathogens-found">
        <!-\- Not sure how to show that no pathogens were found -\->
    </xsl:template>-->

    <!-- Problem Observation -->
    <xsl:template name="make-problem-observation">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <observation>
            <xsl:attribute name="classCode" select="'OBS'" />
            <xsl:attribute name="moodCode" select="'EVN'" />
            <!-- SG 2024-02-05: Updated Problem Observation negationInd handling for a trigger code Condition with verificationStatus of 'entered-in-error' -->
            <xsl:choose>
                <xsl:when test="$vTriggerExtension and fhir:verificationStatus/fhir:coding/fhir:code[@value = 'entered-in-error']">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:when>
                <xsl:when test="$vTriggerExtension">
                    <xsl:attribute name="negationInd" select="'false'" />
                </xsl:when>
            </xsl:choose>

            <!-- templateId -->
            <xsl:call-template name="get-template-id">
                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
            </xsl:call-template>
            <!-- id -->
            <xsl:call-template name="get-id" />
            <!-- code -->
            <!-- Should have already wrapped this with an encounter diagnosis, hard code that one or deal with the others -->
            <xsl:choose>
                <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
                <xsl:when test="fhir:category[1][fhir:coding/fhir:code/@value = 'encounter-diagnosis']">
                    <code code="282291009" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Diagnosis interpretation">
                        <translation code="29308-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Diagnosis" />
                    </code>
                </xsl:when>
                <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
                <xsl:when test="fhir:category[1][fhir:coding/fhir:code/@value = 'problem-list-item']">
                    <code code="75326-9" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Problem HL7.CCDAR2">
                        <translation code="55607006" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Problem" />
                    </code>
                </xsl:when>
                <xsl:otherwise>
                    <code code="75315-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Condition family member HL7.CCDAR2">
                        <translation code="64572001" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Condition" />
                    </code>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="fhir:note">
                <text>
                    <xsl:value-of select="fhir:note/fhir:text/@value" />
                </text>
            </xsl:if>
            <statusCode code="completed" />
            <effectiveTime>
                <xsl:choose>
                    <xsl:when test="fhir:onsetDateTime/@value">
                        <low>
                            <xsl:attribute name="value">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:onsetDateTime/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:attribute>
                        </low>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="nullFlavor">NI</xsl:attribute>
                        <low nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="fhir:abatementDateTime">
                    <high>
                        <xsl:attribute name="value">
                            <xsl:call-template name="Date2TS">
                                <xsl:with-param name="date" select="fhir:abatementDateTime/@value" />
                                <xsl:with-param name="includeTime" select="true()" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </high>
                </xsl:if>
            </effectiveTime>
            <xsl:apply-templates select="fhir:code">
                <xsl:with-param name="pElementName" select="'value'" />
                <xsl:with-param name="pXSIType" select="'CD'" />
                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
            </xsl:apply-templates>
        </observation>
    </xsl:template>

    <!-- RR processing status reason -->
    <xsl:template match="fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-reason-observation']" mode="rr">
        <entryRelationship typeCode="RSON">
            <observation classCode="OBS" moodCode="EVN">
                <xsl:call-template name="get-template-id" />
                <xsl:call-template name="get-id" />
                <xsl:apply-templates select="fhir:code" />
                <xsl:apply-templates select="fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
                <!-- eICR Processing Status Reason Details -->
                <xsl:for-each select="fhir:component">
                    <entryRelationship typeCode="RSON">
                        <observation classCode="OBS" moodCode="EVN">
                            <xsl:comment select="' [RR R1S1] eICR Processing Status Reason Details '" />
                            <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.32" />
                            <xsl:apply-templates select="fhir:code" />
                            <value xsi:type="ST">
                                <xsl:value-of select="fhir:valueString/@value" />
                            </value>
                        </observation>
                    </entryRelationship>
                </xsl:for-each>
            </observation>
        </entryRelationship>
    </xsl:template>
    <xsl:template match="fhir:extension[@url = 'eICRValidationOutput']" mode="rr">
        <entryRelationship typeCode="SPRT">
            <observation classCode="OBS" moodCode="EVN">
                <xsl:call-template name="get-template-id" />
                <id nullFlavor="NI" />
                <code code="RR10" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="eICR Validation Output" />
                <value mediaType="text/xhtml" xsi:type="ED">
                    <html xmlns="http://www.w3.org/1999/xhtml">
                        <xsl:variable name="vValidationString">
                            <xsl:value-of disable-output-escaping="yes" select="replace(replace(fhir:valueString/@value, '&lt;html&gt;', ''), '&lt;/html&gt;', '')" />
                        </xsl:variable>
                        <xsl:value-of disable-output-escaping="yes" select="replace($vValidationString, '&lt;html&gt;', '')" />
                    </html>
                </value>
            </observation>
        </entryRelationship>
    </xsl:template>

    <!-- RR Reportable Condition Observation -->
    <!-- SG 202112: This whole template is too big needs breaking up and refactoring -->
    <xsl:template match="fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-observation']">
        <component>
            <observation classCode="OBS" moodCode="EVN">
                <xsl:call-template name="get-template-id" />
                <xsl:call-template name="get-id" />
                <xsl:apply-templates select="fhir:code" />
                <xsl:apply-templates select="fhir:valueCodeableConcept">
                    <xsl:with-param name="pElementName" select="'value'" />
                    <xsl:with-param name="pXSIType" select="'CD'" />
                </xsl:apply-templates>
                <!-- This is an Organizer and probably should be in the Organizer code - need to refactor -->
                <!-- Reportability Information Organizer -->
                <xsl:for-each select="fhir:hasMember/fhir:reference">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Observation">
                        <entryRelationship typeCode="COMP">
                            <organizer classCode="CLUSTER" moodCode="EVN">
                                <xsl:comment select="' [RR R1S1] Reportability Information Organizer '" />
                                <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.13" />
                                <!-- Location Relevance (home, work, etc.) -->
                                <xsl:apply-templates select="fhir:code" />
                                <statusCode code="completed" />
                                <!-- Responsible Agency, Rules Authoring Agency, Routing Entity -->
                                <xsl:for-each select="fhir:performer/fhir:reference">
                                    <xsl:variable name="referenceURI">
                                        <xsl:call-template name="resolve-to-full-url">
                                            <xsl:with-param name="referenceURI" select="@value" />
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:apply-templates mode="rr" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />
                                </xsl:for-each>
                                <!-- Determination of Reportability -->
                                <component typeCode="COMP">
                                    <observation classCode="OBS" moodCode="EVN">
                                        <xsl:comment select="' [RR R1S1] Determination of Reportability '" />
                                        <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.19" />
                                        <id nullFlavor="NI" />
                                        <code code="RR1" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability" />
                                        <xsl:apply-templates
                                            select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-extension']/fhir:valueCodeableConcept">
                                            <xsl:with-param name="pElementName" select="'value'" />
                                            <xsl:with-param name="pXSIType" select="'CD'" />
                                        </xsl:apply-templates>
                                        <!-- Determination of Reportability Reason -->
                                        <entryRelationship typeCode="RSON">
                                            <observation classCode="OBS" moodCode="EVN">
                                                <xsl:comment select="' [RR R1S1] Determination of Reportability Reason '" />
                                                <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.26" />
                                                <id nullFlavor="NI" />
                                                <code code="RR2" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability reason" />
                                                <value xsi:type="ST">
                                                    <xsl:value-of
                                                        select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-reason-extension']/fhir:valueString/@value"
                                                     />
                                                </value>
                                            </observation>
                                        </entryRelationship>
                                        <!-- Determination of Reportability Rule -->
                                        <entryRelationship typeCode="RSON">
                                            <observation classCode="OBS" moodCode="EVN">
                                                <xsl:comment select="' [RR R1S1] Determination of Reportability Rule '" />
                                                <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.27" />
                                                <id nullFlavor="NI" />
                                                <code code="RR3" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability rule" />
                                                <value xsi:type="ST">
                                                    <xsl:value-of
                                                        select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-rule-extension']/fhir:valueString/@value"
                                                     />
                                                </value>
                                            </observation>
                                        </entryRelationship>
                                    </observation>
                                </component>
                                <!-- Reporting Timeframe -->
                                <component typeCode="COMP">
                                    <observation classCode="OBS" moodCode="EVN">
                                        <xsl:comment select="' [RR R1S1] Reporting Timeframe '" />
                                        <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.14" />
                                        <id nullFlavor="NI" />
                                        <code code="RR4" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Timeframe to report (urgency)" />
                                        <xsl:apply-templates select="fhir:component[fhir:code/fhir:coding/fhir:code[@value = 'RR4']]/fhir:valueQuantity">
                                            <xsl:with-param name="pElementName" select="'value'" />
                                            <xsl:with-param name="pIncludeDatatype" select="true()" />
                                        </xsl:apply-templates>
                                    </observation>
                                </component>
                                <!-- External Resources -->
                                <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-extension']/fhir:valueReference/fhir:reference">
                                    <xsl:variable name="referenceURI">
                                        <xsl:call-template name="resolve-to-full-url">
                                            <xsl:with-param name="referenceURI" select="@value" />
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:DocumentReference">
                                        <component typeCode="COMP">
                                            <act classCode="ACT" moodCode="EVN">
                                                <xsl:comment select="'  [RR R1S1] External Resource  '" />
                                                <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.20" />
                                                <id nullFlavor="NI" />
                                                <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
                                                <xsl:apply-templates select="fhir:category[1]" />
                                                <xsl:apply-templates
                                                    select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-type-extension']/fhir:valueCodeableConcept" />
                                                <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension']/fhir:valueCodeableConcept">
                                                    <xsl:with-param name="pElementName" select="'priorityCode'" />
                                                </xsl:apply-templates>
                                                <reference typeCode="REFR">
                                                    <externalDocument classCode="DOC" moodCode="EVN">
                                                        <xsl:comment select="'  [RR R1 STU1] External Reference  '" />
                                                        <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.15.2.3.17" />
                                                        <xsl:if test="fhir:description/@value">
                                                            <code nullFlavor="OTH">
                                                                <originalText>
                                                                    <xsl:value-of select="fhir:description/@value" />
                                                                </originalText>
                                                            </code>
                                                        </xsl:if>
                                                        <xsl:if test="fhir:content/fhir:attachment/fhir:url/@value">
                                                            <text>
                                                                <xsl:attribute name="mediaType">
                                                                    <xsl:choose>
                                                                        <xsl:when test="fhir:content/fhir:attachment/fhir:contentType/@value">
                                                                            <xsl:value-of select="fhir:content/fhir:attachment/fhir:contentType/@value" />
                                                                        </xsl:when>
                                                                        <xsl:otherwise>text/html</xsl:otherwise>
                                                                    </xsl:choose>
                                                                </xsl:attribute>
                                                                <reference>
                                                                    <xsl:attribute name="value" select="fhir:content/fhir:attachment/fhir:url/@value" />
                                                                </reference>
                                                            </text>
                                                        </xsl:if>
                                                    </externalDocument>
                                                </reference>
                                            </act>
                                        </component>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </organizer>
                        </entryRelationship>
                    </xsl:for-each>
                </xsl:for-each>
            </observation>
        </component>
    </xsl:template>

    <xsl:template match="*" mode="debug">
        <xsl:comment>
      <xsl:value-of select="local-name(.)" />
    </xsl:comment>
    </xsl:template>
</xsl:stylesheet>
