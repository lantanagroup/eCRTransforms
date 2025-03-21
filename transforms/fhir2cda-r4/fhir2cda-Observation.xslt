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
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml">
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
            <xsl:choose>
                <xsl:when test="fhir:valueCodeableConcept">
                    <xsl:for-each select="fhir:valueCodeableConcept">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pElementName" select="'value'" />
                            <xsl:with-param name="pXSIType" select="'CD'" />
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="fhir:valueString">
                    <xsl:for-each select="fhir:valueString">
                        <value xsi:type="ST">
                            <xsl:value-of select="@value" />
                        </value>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="fhir:valueQuantity">
                    <xsl:apply-templates select="fhir:valueQuantity" />
                </xsl:when>
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
            </xsl:choose>
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
            <xsl:call-template name="get-text" />
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

                <!-- Check and apply templates for valuePeriod -->
                <xsl:when test="fhir:valuePeriod">
                    <xsl:apply-templates select="fhir:valuePeriod">
                        <xsl:with-param name="pElementName" select="'value'" />
                        <xsl:with-param name="pXSIType" select="'IVL_TS'" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- Check and apply templates for valueInteger -->
                <xsl:when test="fhir:valueInteger/@value">
                    <value xsi:type="INT" value="{fhir:valueInteger/@value}" />
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
            <xsl:apply-templates select="fhir:bodySite" />
            <!-- subject/relatedSubject/subjectPerson -->
            <!-- Only check if this is an ODH Past or Present Job profile, must be a relatedPerson and only allowed one (it's possible to have multiple in FHIR) just take the first one -->
            <xsl:if test="fhir:code/fhir:coding/fhir:code/@value = '11341-5' and fhir:focus">

                <xsl:for-each select="fhir:focus[1]">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:variable name="vFocusReference" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:*" />

                    <xsl:if test="$vFocusReference/local-name() = 'RelatedPerson'">
                        <subject>
                            <relatedSubject classCode="PRS">
                                <!-- code -->
                                <xsl:apply-templates select="$vFocusReference/fhir:relationship" />
                                <!-- addr -->
                                <xsl:apply-templates select="$vFocusReference/fhir:address" />
                                <!-- telecom -->
                                <xsl:apply-templates select="$vFocusReference/fhir:telecom" />
                                <subjectPerson>
                                    <!-- name -->
                                    <xsl:apply-templates select="$vFocusReference/fhir:name" />
                                    <!-- administrativeGenderCode -->
                                    <xsl:apply-templates select="$vFocusReference/fhir:gender" />
                                    <!-- birthTime -->
                                    <xsl:apply-templates select="$vFocusReference/fhir:birthDate">
                                        <xsl:with-param name="pElement" select="fhir:birthDate" />
                                    </xsl:apply-templates>
                                </subjectPerson>
                            </relatedSubject>
                        </subject>

                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <!-- specimen -->
            <!-- performer -->
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
            <xsl:choose>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/date-recorded-extension']">
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
                </xsl:when>
                <!-- MD add this for now, need to know there is any difference between 
                date-recorded-extension with us-ph-date-recorded-extension -->
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-date-recorded-extension']">
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
                </xsl:when>
                <xsl:when test="fhir:issued">
                    <author>
                        <xsl:comment select="' Issued Date '" />
                        <xsl:apply-templates select="fhir:issued">
                            <xsl:with-param name="pElementName" select="'time'" />
                        </xsl:apply-templates>
                        <assignedAuthor>
                            <id nullFlavor="NA" />
                        </assignedAuthor>
                    </author>
                </xsl:when>
            </xsl:choose>

            <!-- informant -->
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
                <xsl:for-each
                    select="//fhir:Observation[fhir:code/fhir:coding/fhir:code/@value = '63893-2'] | //fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-outcome-observation']">
                    <xsl:variable name="vRelatedPregnancyStatusUrl" select="fhir:focus/fhir:reference/@value" />
                    <xsl:if test="ends-with($vPregnancyStatusFullUrl, $vRelatedPregnancyStatusUrl)">
                        <entryRelationship typeCode="COMP">
                            <sequenceNumber value="{fhir:component[fhir:code/fhir:coding/fhir:code/@value='73771-8']/fhir:valueInteger/@value}" />
                            <xsl:call-template name="make-generic-observation" />
                        </entryRelationship>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <!-- If this is an Emergency Outbreak Information Observation and there are hasMembers -->
            <xsl:if test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-emergency-outbreak-information' and fhir:hasMember">
                <!--<xsl:for-each select="fhir:hasMember">
                    <entryRelationship typeCode="REFR">-->
                <xsl:for-each select="fhir:hasMember/fhir:reference">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:*">
                        <entryRelationship typeCode="REFR">
                            <xsl:call-template name="make-generic-observation" />
                        </entryRelationship>
                        <!--<xsl:apply-templates select="fhir:resource/fhir:*" mode="component">
                            <xsl:with-param name="generated-narrative" />
                        </xsl:apply-templates>-->
                    </xsl:for-each>
                </xsl:for-each>
                <!--</entryRelationship>
                </xsl:for-each>-->
            </xsl:if>
            <!-- reference -->
            <!-- precondition -->
            <!-- referenceRange -->
            <xsl:for-each select="fhir:referenceRange">
                <xsl:call-template name="get-reference-range" />
            </xsl:for-each>

        </observation>
    </xsl:template>



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
            <!-- text -->
            <xsl:call-template name="get-text" />
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
            <!-- text -->
            <xsl:call-template name="get-text" />
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
            <!-- text -->
            <xsl:call-template name="get-text" />
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

    <!-- fhir:ServiceRequest -->
    <xsl:template match="fhir:ServiceRequest" mode="entry">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />

        <xsl:variable name="vMapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />

        <xsl:variable name="vCategoryValue" select="fhir:category/fhir:coding/fhir:code/@value" />
        <xsl:variable name="vCodeValue" select="fhir:code/fhir:coding/fhir:code/@value" />
        <xsl:variable name="vCodeSystem" select="fhir:code/fhir:coding/fhir:system/@value" />

        <xsl:choose>
            <!-- Trigger Code extension exists: the only triggers that can happen on a serviceRequest are lab orders because that is the only RCTC value set>
                 Map to Template: Initial Case Report Trigger Code Lab Test Order  -->
            <xsl:when test="$vTriggerExtension">
                <!-- Initial Case Report Trigger Code Lab Test Order -->
                <xsl:call-template name="make-trigger-lab-test-order">
                    <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                    <!--<xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:when>

            <!-- Trigger Code extension does not exist and ServiceRequest.code.system = CDT or ICD 10 procedures -->
            <xsl:when test="$vCodeSystem = 'https://ada.org/en/publications/cdt' or $vCodeSystem = 'http://www.cms.gov/Medicare/Coding/ICD10'">
                <!-- Planned Procedure -->
                <xsl:call-template name="make-planned-procedure">
                    <!--<xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:when>

            <!-- Trigger code extension does not exist AND ServiceRequest.category = sdoh, functional-status, disability-status, congnitive-status, 386053000, 108252007, 363679005
                Map to template: Planned Observation -->
            <xsl:when
                test="$vCategoryValue = 'sdoh' or $vCategoryValue = 'functional-status' or $vCategoryValue = 'disability-status' or $vCategoryValue = 'cognitive-status' or $vCategoryValue = '386053000' or $vCategoryValue = '108252007' or $vCategoryValue = '363679005'">
                <!-- Planned Observation -->
                <xsl:call-template name="make-planned-observation">
                    <!--<xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:when>

            <!-- Trigger code extension does not exist AND ServiceRequest.category = 387713003, 410606002, 409063005, 409073007  
                 Map to template: Planned Procedure-->
            <xsl:when test="$vCategoryValue = '387713003' or $vCategoryValue = '410606002' or $vCategoryValue = '409063005' or $vCategoryValue = '409073007'">
                <!-- Planned Procedure -->
                <xsl:call-template name="make-planned-procedure">
                    <!--<xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:when>

            <!-- Trigger Code extension does not exist and ServiceRequest.code.system = LOINC
                 Map to template: Planned Observation-->
            <xsl:when test="$vCodeSystem = 'http://loinc.org'">
                <!-- Planned Observation -->
                <xsl:call-template name="make-planned-observation">
                    <!--                    <xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Planned Observation -->
                <xsl:call-template name="make-planned-observation">
                    <!--<xsl:with-param name="pMapping" select="$vMapping" />-->
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="make-trigger-lab-test-order">
        <xsl:param name="pTriggerExtension" />
        <!--        <xsl:param name="pMapping" />-->

        <entry typeCode="DRIV">
            <observation classCode="OBS" moodCode="RQO">
                <xsl:if test="fhir:doNotPerform/@value = 'true'">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:if>
                <!-- templateId -->
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Lab Test Order (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.4" extension="2019-04-01" />
                <xsl:call-template name="get-id" />
                <!-- code -->
                <xsl:apply-templates select="fhir:code">
                    <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
                </xsl:apply-templates>
                <!-- text -->
                <xsl:call-template name="get-text" />
                <!-- statusCode is hard coded to "active" in C-CDA Planned Observation -->
                <statusCode code="active" />
                <!-- effectiveTime SG 20231123: Updated effective time processing to occurenceDateTime -->
                <xsl:call-template name="get-effective-time">
                    <xsl:with-param name="pElement" select="fhir:occurrenceDateTime" />
                </xsl:call-template>
                <!-- targetSiteCode SG 20231124: Added bodySite (targetSiteCode) -->
                <xsl:apply-templates select="fhir:bodySite" />
                <!-- performer -->
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
                <xsl:choose>
                    <xsl:when test="fhir:authoredOn and not(fhir:requester)">
                        <author>
                            <templateId root="2.16.840.1.113883.10.20.22.4.119" />
                            <time>
                                <xsl:attribute name="value">
                                    <xsl:call-template name="Date2TS">
                                        <xsl:with-param name="date" select="fhir:authoredOn/@value" />
                                        <xsl:with-param name="includeTime" select="true()" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </time>
                            <assignedAuthor>
                                <id nullFlavor="NI" />
                            </assignedAuthor>
                        </author>
                    </xsl:when>
                    <xsl:when test="fhir:requester">
                        <xsl:apply-templates select="fhir:requester" />
                    </xsl:when>
                </xsl:choose>
            </observation>
        </entry>
    </xsl:template>

    <xsl:template name="make-planned-observation">
        <xsl:param name="pTriggerExtension" />
        <!--        <xsl:param name="pMapping" />-->

        <xsl:variable name="vMoodCode">
            <xsl:apply-templates select="fhir:intent" />
        </xsl:variable>

        <entry typeCode="DRIV">
            <observation classCode="OBS" moodCode="{$vMoodCode}">
                <xsl:if test="fhir:doNotPerform/@value = 'true'">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:if>
                <!-- templateId -->
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />

                <xsl:if test="$pTriggerExtension">
                    <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Planned Observation '" />
                    <templateId root="2.16.840.1.113883.10.20.15.2.3.43" extension="2021-01-01" />
                </xsl:if>

                <xsl:call-template name="get-id" />

                <xsl:apply-templates select="fhir:code">
                    <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
                </xsl:apply-templates>
                <!-- C-CDA Planned Observation statusCode is hard coded to 'active' -->
                <statusCode code="active" />
                <!-- SG 20231123: Updated effective time processing to occurenceDateTime -->
                <xsl:call-template name="get-effective-time">
                    <xsl:with-param name="pElement" select="fhir:occurrenceDateTime" />
                </xsl:call-template>
                <!-- SG 20231124: Added bodySite (targetSiteCode) -->
                <xsl:apply-templates select="fhir:bodySite" />

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
                <xsl:choose>
                    <xsl:when test="fhir:authoredOn and not(fhir:requester)">
                        <author>
                            <templateId root="2.16.840.1.113883.10.20.22.4.119" />
                            <time>
                                <xsl:attribute name="value">
                                    <xsl:call-template name="Date2TS">
                                        <xsl:with-param name="date" select="fhir:authoredOn/@value" />
                                        <xsl:with-param name="includeTime" select="true()" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </time>
                            <assignedAuthor>
                                <id nullFlavor="NI" />
                            </assignedAuthor>
                        </author>
                    </xsl:when>
                    <xsl:when test="fhir:requester">
                        <xsl:apply-templates select="fhir:requester" />
                    </xsl:when>
                </xsl:choose>
            </observation>
        </entry>

    </xsl:template>

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
            <!-- text -->
            <xsl:call-template name="get-text" />
            <!-- statusCode -->
            <statusCode code="completed" />
            <!-- effectiveTime -->
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
            <!-- value -->
            <xsl:apply-templates select="fhir:code">
                <xsl:with-param name="pElementName" select="'value'" />
                <xsl:with-param name="pXSIType" select="'CD'" />
                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
            </xsl:apply-templates>
            <!-- author (C-CDA Author Participation template) -->
            <xsl:choose>
                <xsl:when test="fhir:recordedDate and not(fhir:recorder)">
                    <author>
                        <templateId root="2.16.840.1.113883.10.20.22.4.119" />
                        <time>
                            <xsl:attribute name="value">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:recordedDate/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:attribute>
                        </time>
                        <assignedAuthor>
                            <id nullFlavor="NI" />
                        </assignedAuthor>
                    </author>
                </xsl:when>
                <xsl:when test="fhir:recorder">
                    <xsl:apply-templates select="fhir:recorder" />
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="fhir:clinicalStatus" />

        </observation>
    </xsl:template>

    <xsl:template match="fhir:clinicalStatus[fhir:coding]">
        <entryRelationship typeCode="REFR">
            <observation classCode="OBS" moodCode="EVN">
                <!-- templateId -->
                <xsl:call-template name="get-template-id" />

                <code code="33999-4" displayName="Status" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" />
                <statusCode code="completed" />
                <effectiveTime>
                    <low nullFlavor="UNK" />
                </effectiveTime>
                <value>
                    <xsl:choose>
                        <xsl:when test="fhir:code/@value = 'resolved'">
                            <xsl:attribute name="code">413322009</xsl:attribute>
                            <xsl:attribute name="displayName">Problem resolved (finding)</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="fhir:code/@value = 'recurrence'">
                            <xsl:attribute name="code">246455001</xsl:attribute>
                            <xsl:attribute name="displayName">Recurrence (qualifier value)</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="fhir:code/@value = 'relapse'">
                            <xsl:attribute name="code">263855007</xsl:attribute>
                            <xsl:attribute name="displayName">Relapse phase (qualifier value)</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="fhir:code/@value = 'remission'">
                            <xsl:attribute name="code">277022003</xsl:attribute>
                            <xsl:attribute name="displayName">Remission phase (qualifier value)</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="fhir:code/@value = 'active'">
                            <xsl:attribute name="code">55561003</xsl:attribute>
                            <xsl:attribute name="displayName">Active (qualifier value)</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="fhir:code/@value = 'inactive'">
                            <xsl:attribute name="code">73425007</xsl:attribute>
                            <xsl:attribute name="displayName">Inactive (qualifier value)</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="code">55561003</xsl:attribute>
                            <xsl:attribute name="displayName">Active (qualifier value)</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="codeSystem">2.16.840.1.113883.6.96</xsl:attribute>
                    <xsl:attribute name="codeSystemName">SNOMED CT</xsl:attribute>
                    <xsl:attribute name="xsi:type">CD</xsl:attribute>
                </value>

            </observation>
        </entryRelationship>
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

    <xsl:template name="get-text">
        <xsl:choose>
            <xsl:when test="fhir:note and fhir:text">
                <text>
                    <xsl:value-of select="concat(fhir:note/fhir:text/@value, '; ', fhir:text/xhtml:div)" />
                </text>
            </xsl:when>
            <xsl:when test="fhir:note">
                <text>
                    <xsl:value-of select="fhir:note/fhir:text/@value" />
                </text>
            </xsl:when>
            <xsl:when test="fhir:text">
                <text>
                    <xsl:value-of select="fhir:text/xhtml:div" />
                </text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="debug">
        <xsl:comment>
      <xsl:value-of select="local-name(.)" />
    </xsl:comment>
    </xsl:template>
</xsl:stylesheet>
