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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xhtml" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="native-xslt-uuid.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-EncompassingEncounter.xslt" />
    <xsl:import href="fhir2cda-inFulfillmentOf.xslt" />

    <xsl:variable name="docId" select="lower-case(uuid:get-uuid())" />

    <!-- FHIR Composition -> CDA ClinicalDocument -->
    <xsl:template match="fhir:Composition">
        <xsl:variable name="docId" select="lower-case(uuid:get-uuid())" />
        <ClinicalDocument>
            <realmCode code="US" />
            <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
            <xsl:if test="$gvCurrentIg = 'PCP'">
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.1" />
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.15" />
            </xsl:if>

            <!-- MD: add dental template Id -->
            <xsl:if test="$gvCurrentIg = 'DentalConsultNote'">
                <xsl:comment select="' [C-CDA R1.1] US Realm Header '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' Consultation Note (V3) '" />
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.4" />
                <xsl:comment select="' Dental Consultation Note template ID '" />
                <templateId extension="2020-08-01" root="2.16.840.1.113883.10.20.40.1.1.2" />
            </xsl:if>
            <xsl:if test="$gvCurrentIg = 'DentalReferalNote'">
                <xsl:comment select="' [C-CDA R1.1] US Realm Header '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' Referral Note (V2) '" />
                <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.14" />
                <xsl:comment select="' Dental Referral Note template ID '" />
                <templateId extension="2020-08-01" root="2.16.840.1.113883.10.20.40.1.1.1" />
            </xsl:if>

            <xsl:if test="$gvCurrentIg = 'eICR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <xsl:if test="$gvCurrentIg = 'RR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <!-- generate a new ID for this document. Save the FHIR document id in parentDocument with a type of XFRM -->
            <!-- MD:   -->
            <xsl:choose>
                <xsl:when test="/fhir:Bundle/fhir:type/@value = 'document' and /fhir:Bundle/fhir:identifier">
                    <xsl:choose>
                        <xsl:when test="/fhir:Bundle/fhir:identifier">
                            <xsl:apply-templates select="/fhir:Bundle/fhir:identifier" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <id root="{$docId}" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:for-each select="fhir:type">
                <xsl:apply-templates select="."/>
                <!--<xsl:call-template name="CodeableConcept2CD" />-->
            </xsl:for-each>
            <!-- SG 20210701: Where are the other IG titles? Added a choice around this -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <title>Initial Public Health Case Report</title>
                </xsl:when>
                <xsl:when test="$gvCurrentIg = 'RR'">
                    <title>Reportability Response</title>
                </xsl:when>
                <xsl:when test="$gvCurrentIg = 'PCP'">
                    <title>Pharmacist Care Plan</title>
                </xsl:when>
                <xsl:otherwise>
                    <!-- add handle for <fhir:title> -->
                    <xsl:choose>
                        <xsl:when test="//fhir:Composition/fhir:title">
                            <title>
                                <xsl:value-of select="fhir:title/@value" />
                            </title>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="get-effective-time">
                <xsl:with-param name="pElement" select="fhir:date" />
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="fhir:confidentiality">
                    <confidentialityCode code="{fhir:confidentiality/@value}" codeSystem="2.16.840.1.113883.5.25" />
                </xsl:when>
                <xsl:otherwise>
                    <confidentialityCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:language">
                    <languageCode code="{fhir:language/@value}" />
                </xsl:when>
                <xsl:otherwise>
                    <languageCode code="en-US" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- 
            <xsl:apply-templates select="../../../fhir:identifier">
                <xsl:with-param name="pElementName" select="'setId'" />
            </xsl:apply-templates>  -->

            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier">
                        <xsl:with-param name="pElementName" select="'setId'" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when
                    test="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value">
                    <versionNumber
                        value="{fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value}"
                     />
                </xsl:when>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value">
                    <versionNumber
                        value="{fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value}" />
                </xsl:when>
            </xsl:choose>

            <xsl:apply-templates select="fhir:subject" />
            <xsl:apply-templates select="fhir:author" />

            <xsl:choose>
                <xsl:when test="fhir:custodian">
                    <xsl:apply-templates select="fhir:custodian" />
                </xsl:when>
                <xsl:otherwise>
                    <!-- fhir:author -> cda:custodian -->
                    <xsl:apply-templates mode="custodian" select="fhir:author" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <!-- fhir:recipient -> cda:informationRecipient -->
                <xsl:when
                    test="fhir:extension[@url = 'http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension'] or fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension']">
                    <xsl:for-each
                        select="fhir:extension[@url = 'http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension'] | fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension']">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pPosition" select="position()" />
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$gvCurrentIg = 'DentalReferalNote'">
                            <informationRecipient>
                                <intendedRecipient>
                                    <xsl:call-template name="get-addr" />
                                    <xsl:call-template name="get-telecom" />
                                    <informationRecipient>
                                        <name>
                                            <given>NI</given>
                                            <family>NI</family>
                                        </name>
                                    </informationRecipient>
                                </intendedRecipient>
                            </informationRecipient>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <!-- fhir:attester -> cda:legalAuthenticator or cda:Authenticator-->
            <xsl:apply-templates select="fhir:attester" />
                        
            <!-- SG 20231126: Check for Emergency Contact -->
            <xsl:for-each select="//fhir:Patient/fhir:contact[fhir:relationship/fhir:coding/fhir:code[@value = 'C']]">
                <participant typeCode="IND">
                    <associatedEntity classCode="ECON">
                        <xsl:call-template name="get-addr" />
                        <xsl:call-template name="get-telecom" />
                        <associatedPerson>
                            <xsl:call-template name="get-person-name" />
                        </associatedPerson>
                    </associatedEntity>
                </participant>
            </xsl:for-each>

            <!-- fhir:extension  -->
            <!-- be aware a Composition can have multiple extensions to ensure in correct context -->
            <!-- MD: OrderExtension -> cda:inFulfillmentOf -->
            <xsl:variable name="vCompositionOrderExtension" select="'http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension'" />
            <xsl:apply-templates mode="inFulfillmentOf" select="fhir:extension[@url = $vCompositionOrderExtension]"> </xsl:apply-templates>

            <xsl:apply-templates select="fhir:event" />
            <xsl:apply-templates select="fhir:encounter" />


            <component>
                <structuredBody>
                    <!-- If this is eICR we need to manually add an Encounters section -->
                    <xsl:choose>
                        <xsl:when test="$gvCurrentIg = 'eICR'">
                            <component>
                                <xsl:for-each select="//fhir:Encounter">
                                    <xsl:call-template name="create-eicr-encounters-section" />
                                </xsl:for-each>
                            </component>
                        </xsl:when>
                        <!-- If this is an RR we don't want an Encounters section -->
                        <xsl:when test="$gvCurrentIg = 'RR'" />
                        <xsl:otherwise>
                            <!-- MD: to create encounters section based on the encounter reference in the resources -->
                            <xsl:choose>
                                <xsl:when test="//fhir:*/fhir:encounter/fhir:reference">
                                    <component>
                                        <xsl:call-template name="create-encounters-section" />
                                    </component>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="fhir:section">
                        <component>
                            <!-- SG 20240307: Sometimes the FHIR Sections don't have titles -->
                            <xsl:variable name="vTitle">
                                <xsl:choose>
                                    <xsl:when test="fhir:title">
                                        <xsl:value-of select="fhir:title/@value" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="fhir:code" mode="map-section-title" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="title" select="$vTitle" />
                            </xsl:apply-templates>
                        </component>
                    </xsl:for-each>
                </structuredBody>
            </component>
        </ClinicalDocument>
    </xsl:template>

    <!-- fhir:extension[rr-eicr-processing-status-extension] -> (RR) RR eICR Processing Status (Act) and eICR Validation Output (Observation) -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension']" mode="rr">
        <!-- fhir:extension[eICRProcessingStatus] -> (RR) eICR Processing Status (Act)  -->
        <xsl:apply-templates mode="rr" select="fhir:extension[@url = 'eICRProcessingStatus']" />
    </xsl:template>

    <!-- fhir:extension[3 different organization types] -> (RR) Rules Authoring Agency, Routing Entity, Responsible Agency (Organization) -->
    <xsl:template
        match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-rules-authoring-agency-organization-extension'] | fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-routing-entity-organization-extension'] | fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-responsible-agency-organization-extension']"
        mode="rr">

        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:valueReference/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <!-- (RR) Rules Authoring Agency, Routing Entity, Responsible Agency (Organization) -->
        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization">
            <xsl:apply-templates mode="rr" select="." />
        </xsl:for-each>
    </xsl:template>

    <!-- QUESTIONNAIRE RESPONSE -->
    <!-- SG: Dave, this is a global variable - wondering if this is what you really meant to do here or should this be inside a template? -->
    <xsl:variable name="infection-id" select="generate-id(//fhir:item[fhir:linkId/@value = 'event-type'][1])" />

    <xsl:template match="fhir:QuestionnaireResponse">
        <xsl:variable name="vFHIR2CDAResult">
            <ClinicalDocument xmlns="urn:hl7-org:v3">
                <realmCode code="US" />
                <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
                <!-- templateId -->
                <xsl:call-template name="get-template-id" />
                <!-- id: Bundle.identifier -->
                <xsl:call-template name="get-id">
                    <xsl:with-param name="pElement" select="//fhir:Bundle/fhir:identifier" />
                    <xsl:with-param name="pNoNullAllowed" select="true()" />
                </xsl:call-template>
                <!-- code -->
                <xsl:apply-templates mode="map-profile-to-code" select="." />
                <!-- title -->
                <xsl:apply-templates mode="map-to-title" select="." />
                <!-- fhir:QuestionnaireResponse/fhir:authored OR fhir:Bundle/fhir:timestamp  -> effectiveTime -->
                <!-- Because currently in HAI fhir:QuestionnaireResponse/fhir:authored isn't required, it might not be there, if it isn't 
           use fhir:Bundle:timestamp instead-->
                <!-- effectiveTime -->
                <xsl:choose>
                    <xsl:when test="fhir:authored">
                        <xsl:call-template name="get-effective-time">
                            <xsl:with-param name="pElement" select="fhir:authored" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-effective-time">
                            <xsl:with-param name="pElement" select="ancestor::fhir:Bundle/fhir:timestamp" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- confidentialityCode -->
                <xsl:choose>
                    <xsl:when test="fhir:meta/fhir:security">
                        <xsl:apply-templates select="fhir:meta/fhir:security" />
                    </xsl:when>
                    <xsl:otherwise>
                        <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" displayName="Normal" />
                    </xsl:otherwise>
                </xsl:choose>
                <languageCode code="en-US" />
                <!-- setId: QuestionnaireResponse.identifier -->
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier">
                            <xsl:with-param name="pElementName" select="'setId'" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <!--<setId>
          <xsl:attribute name="value" select="fhir:identifier/fhir:value/@value" />
        </setId>-->
                <versionNumber>
                    <xsl:attribute name="value">1</xsl:attribute>
                </versionNumber>
                <!-- recordTarget -->
                <xsl:apply-templates select="fhir:subject" />
                <!-- author -->
                <xsl:apply-templates select="fhir:author" />
                <!-- The custodian of the CDA document is NHSN -->
                <custodian>
                    <assignedCustodian>
                        <representedCustodianOrganization>
                            <id root="2.16.840.1.114222.4.3.2.11" />
                        </representedCustodianOrganization>
                    </assignedCustodian>
                </custodian>
                <!-- legalAuthenticator - missing in FHIR - this is just a SHOULD in the CDA IG though -->
                <!--<legalAuthenticator>
          <time value="20190201"/>
          <signatureCode code="S"/>
          <assignedEntity>
            <id root="2.16.840.1.113883.3.117.1.1.5.1.1.2" extension="aLegalAuthenticatorID"/>
          </assignedEntity>
        </legalAuthenticator>-->
                <!-- SG 20220213: Only want an encompassingEncounter if this is an event report -->
                <xsl:if test="//fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event'">
                    <xsl:call-template name="make-encompassing-encounter-hai" />
                </xsl:if>

                <!-- SG 20220213: Only want an serviceEvent if this is a summary report -->
                <xsl:if test="//fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary'">
                    <xsl:call-template name="make-service-event-hai" />
                </xsl:if>
                <component>
                    <structuredBody>

                        <!-- SG 20220209: Put the working document into a variable -->
                        <xsl:variable name="vQuestionnaireResponse" select="." />

                        <!-- SG 20220209: Iterate through the sections -->
                        <xsl:for-each
                            select="$questionnaire-mapping/fhir:map[@type = ('section')][@linkId = ($vQuestionnaireResponse//fhir:linkId/@value)]">
                            <component>
                                <xsl:variable name="vLinkId">
                                    <xsl:value-of select="@linkId" />
                                </xsl:variable>

                                <!-- Grab the entry linkIds for this section and put into variable -->
                                <xsl:variable name="vSectionEntryLinkIds"
                                    select="$questionnaire-mapping/fhir:map[@location = $vLinkId][@type = 'entry']/@linkId" />

                                <!-- Get any matching entry items and put into variable -->
                                <xsl:variable name="vSectionEntries"
                                    select="$vQuestionnaireResponse//fhir:item[fhir:linkId/@value = $vSectionEntryLinkIds]" />

                                <!-- Grab the entryRelationship linkIds for this section and put into variable -->
                                <xsl:variable name="vSectionEntryRelationshipLinkIds"
                                    select="$questionnaire-mapping/fhir:map[@location = $vLinkId][@type = 'entryRelationship']/@linkId" />

                                <!-- Get any matching entryRelationship items and put into variable -->
                                <xsl:variable name="vSectionEntryRelationships"
                                    select="$vQuestionnaireResponse//fhir:item[fhir:linkId/@value = $vSectionEntryRelationshipLinkIds]" />

                                <!-- Create the sections and their entries -->
                                <xsl:apply-templates mode="section" select="$vQuestionnaireResponse//fhir:item[fhir:linkId/@value = $vLinkId]">
                                    <!-- Pass through the entries for this section to process inside the section -->
                                    <xsl:with-param name="pSectionEntries" select="$vSectionEntries" />
                                    <!-- Pass through the entryRelationship for this section to process inside the section -->
                                    <xsl:with-param name="pSectionEntryRelationships" select="$vSectionEntryRelationships" />
                                </xsl:apply-templates>
                            </component>
                        </xsl:for-each>
                    </structuredBody>
                </component>
            </ClinicalDocument>
        </xsl:variable>

        <!-- Generate narrative using the hai ltc generate narrative transform -->
        <xsl:apply-templates mode="gen-hai-narrative" select="$vFHIR2CDAResult" />

        <!--    <xsl:copy-of select="$vFHIR2CDAResult"/>-->
    </xsl:template>

    <!-- fhir:item[criteria-used] -> (HAI) Criterial of Diagnosis Organizer (Organizer) -->
    <xsl:template match="fhir:item[fhir:linkId[@value = 'criteria-used']]" mode="diagnosis">
        <entryRelationship typeCode="SPRT">
            <organizer classCode="CLUSTER" moodCode="EVN">
                <!-- [HAI R2N1] Criteria of Diagnosis Organizer -->
                <templateId root="2.16.840.1.113883.10.20.5.6.180" />
                <statusCode code="completed" />
                <component>
                    <observation classCode="OBS" moodCode="EVN" negationInd="false">
                        <templateId root="2.16.840.1.113883.10.20.22.4.19" />
                        <templateId root="2.16.840.1.113883.10.20.5.6.119" />
                        <id nullFlavor="NA" />
                        <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
                        <statusCode code="completed" />
                        <xsl:for-each select="fhir:answer[fhir:valueCoding]">
                            <!--<xsl:call-template name="CodeableConcept2CD">-->
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="pElementName">value</xsl:with-param>
                                <xsl:with-param name="pXSIType">CD</xsl:with-param>
                            </xsl:apply-templates>
                            <!--</xsl:call-template>-->
                        </xsl:for-each>
                    </observation>
                </component>
            </organizer>
        </entryRelationship>
    </xsl:template>

    <!-- fhir:item -->
    <xsl:template match="fhir:item" mode="questionnaireresponse-reference">
        <xsl:message>Processing QuestionnareResponse.item of type reference</xsl:message>
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:answer/fhir:valueReference/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
            <xsl:apply-templates select="fhir:resource/fhir:*" />
        </xsl:for-each>
    </xsl:template>

    <!-- DD adding NHSN Comments Section -->
    <xsl:template name="nhsn-comments-section">
        <section>
            <!-- NHSN Comment Section Generic Constraints -->
            <templateId root="2.16.840.1.113883.10.20.5.4.26" />
            <!-- [HAI R3D2] NHSN Comment Section -->
            <templateId root="2.16.840.1.113883.10.20.5.5.61" />
            <code code="86468-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Report comment Section" />
            <title>Comments</title>
            <text>
                <table>
                    <tbody>
                        <tr>
                            <td>Comment</td>
                            <td>
                                <xsl:value-of select="fhir:item/fhir:answer/fhir:valueString/@value" />
                            </td>
                        </tr>
                    </tbody>
                </table>
            </text>
            <entry typeCode="DRIV">
                <act classCode="ACT" moodCode="EVN">
                    <!-- [HAI R3D2] NHSN Comment -->
                    <templateId extension="2017-04-01" root="2.16.840.1.113883.10.20.5.6.243" />
                    <code code="86467-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Report comment Narrative" />
                    <text>
                        <xsl:value-of select="fhir:item/fhir:answer/fhir:valueString/@value" />
                    </text>
                </act>
            </entry>
        </section>
    </xsl:template>


    <!-- MeasureReport support. Added 2022-04-08 by RG -->

    <xsl:template match="fhir:MeasureReport">
        <ClinicalDocument xmlns="urn:hl7-org:v3">
            <realmCode code="US" />
            <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
            <xsl:choose>
                <xsl:when test="fhir:type/@value = 'individual'">
                    <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.1.1" />
                    <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.24.1.1" />
                    <templateId extension="2019-12-01" root="2.16.840.1.113883.10.20.24.1.2" />
                    <templateId extension="2020-02-01" root="2.16.840.1.113883.10.20.24.1.3" />
                    <xsl:call-template name="get-id">
                        <xsl:with-param name="pNoNullAllowed" select="true()" />
                    </xsl:call-template>
                    <code code="55182-0" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Quality Measure Report" />
                </xsl:when>
                <xsl:otherwise>
                    <templateId extension="2017-06-01" root="2.16.840.1.113883.10.20.27.1.1" />
                    <templateId extension="2021-07-01" root="2.16.840.1.113883.10.20.27.1.2" />
                    <xsl:call-template name="get-id">
                        <xsl:with-param name="pNoNullAllowed" select="true()" />
                    </xsl:call-template>
                    <code code="55184-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC"
                        displayName="Quality Reporting Document Architecture Calculated Summary Report" />
                </xsl:otherwise>
            </xsl:choose>
            <title>Quality Measure Report Converted from FHIR MeasureReport</title>
            <!-- effectiveTime -->
            <xsl:choose>
                <xsl:when test="fhir:date">
                    <xsl:call-template name="get-effective-time">
                        <xsl:with-param name="pElement" select="fhir:date" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="get-effective-time">
                        <xsl:with-param name="pElement" select="ancestor::fhir:Bundle/fhir:timestamp" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <!-- confidentialityCode -->
            <xsl:choose>
                <xsl:when test="fhir:meta/fhir:security">
                    <xsl:apply-templates select="fhir:meta/fhir:security" />
                </xsl:when>
                <xsl:otherwise>
                    <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" displayName="Normal" />
                </xsl:otherwise>
            </xsl:choose>
            <languageCode code="en-US" />
            <setId nullFlavor="NI" />
            <versionNumber>
                <xsl:attribute name="value">1</xsl:attribute>
            </versionNumber>
            <!-- recordTarget -->
            <xsl:choose>
                <xsl:when test="fhir:type/@value = 'individual'">
                    <xsl:apply-templates select="fhir:subject" />
                </xsl:when>
                <xsl:otherwise>
                    <recordTarget>
                        <patientRole>
                            <id nullFlavor="NA" />
                        </patientRole>
                    </recordTarget>
                </xsl:otherwise>
            </xsl:choose>
            <!-- author -->
            <xsl:apply-templates select="fhir:reporter" />
            <xsl:if test="not(fhir:reporter)">
                <author nullFlavor="NI">
                    <time nullFlavor="NI" />
                    <assignedAuthor nullFlavor="NI">
                        <id nullFlavor="NI" />
                    </assignedAuthor>

                </author>
            </xsl:if>
            <!-- The custodian of the CDA document is NHSN -->
            <custodian>
                <assignedCustodian>
                    <representedCustodianOrganization>
                        <id root="2.16.840.1.114222.4.3.2.11" />
                    </representedCustodianOrganization>
                </assignedCustodian>
            </custodian>
            <component>
                <structuredBody>
                    <component>
                        <section>
                            <templateId root="2.16.840.1.113883.10.20.24.2.2" />
                            <templateId extension="2017-06-01" root="2.16.840.1.113883.10.20.27.2.1" />
                            <templateId extension="2019-05-01" root="2.16.840.1.113883.10.20.27.2.3" />
                            <code code="55186-1" codeSystem="2.16.840.1.113883.6.1" displayName="measure section" />
                            <title>Measure Section</title>
                            <text>TBD</text>
                            <entry>
                                <organizer classCode="CLUSTER" moodCode="EVN">
                                    <templateId root="2.16.840.1.113883.10.20.24.3.98" />
                                    <templateId extension="2016-09-01" root="2.16.840.1.113883.10.20.27.3.1" />
                                    <templateId extension="2019-05-01" root="2.16.840.1.113883.10.20.27.3.17" />
                                    <id root="95944FB9-241B-11E5-1027-09173F13E4C5" />
                                    <statusCode code="completed" />
                                    <reference typeCode="REFR">
                                        <externalDocument classCode="DOC" moodCode="EVN">
                                            <!-- TODO: Will need to map FHIR measure URLs to OIDs -->
                                            <id root="{fhir:measure/@value}" />
                                        </externalDocument>
                                    </reference>
                                    <xsl:apply-templates select="fhir:group" />

                                </organizer>
                            </entry>
                        </section>
                    </component>
                    <component>
                        <section>
                            <!-- Reporting Parameters section -->
                            <templateId root="2.16.840.1.113883.10.20.17.2.1" />
                            <!-- Reporting Parameters section CMS -->
                            <templateId extension="2016-03-01" root="2.16.840.1.113883.10.20.17.2.1.1" />
                            <code code="55187-9" codeSystem="2.16.840.1.113883.6.1" />
                            <title>Reporting Parameters</title>
                            <text>
                                <list>
                                    <item>Reporting period: 01 Jan 2022 - 31 Mar 2022</item>
                                </list>
                            </text>
                            <entry typeCode="DRIV">
                                <act classCode="ACT" moodCode="EVN">
                                    <!-- Reporting Parameters Act -->
                                    <templateId root="2.16.840.1.113883.10.20.17.3.8" />
                                    <!-- Reporting Parameters Act CMS -->
                                    <templateId extension="2016-03-01" root="2.16.840.1.113883.10.20.17.3.8.1" />
                                    <id root="daf49616-5212-49b4-bebb-1273d6c5a97d" />
                                    <code code="252116004" codeSystem="2.16.840.1.113883.6.96" displayName="Observation Parameters" />
                                    <xsl:apply-templates select="fhir:period" />
                                </act>
                            </entry>
                        </section>
                    </component>
                    <xsl:choose>
                        <xsl:when test="fhir:type/@value = 'individual'">
                            <!-- QRDA I sections -->
                            <component>
                                <section>
                                    <!-- Patient Data Section -->
                                    <templateId root="2.16.840.1.113883.10.20.17.2.4" />
                                    <!-- Patient Data Section QDM (V7) -->
                                    <templateId extension="2019-12-01" root="2.16.840.1.113883.10.20.24.2.1" />
                                    <!-- Patient Data Section QDM (V7) - CMS -->
                                    <templateId extension="2020-02-01" root="2.16.840.1.113883.10.20.24.2.1.1" />
                                    <code code="55188-7" codeSystem="2.16.840.1.113883.6.1" />
                                    <title>Patient Data</title>
                                    <xsl:for-each select="fhir:evaluatedResource">
                                        <entry>
                                            <xsl:call-template name="resolve-reference" />
                                        </entry>
                                    </xsl:for-each>
                                </section>
                            </component>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- QRDA Iii sections -->
                        </xsl:otherwise>
                    </xsl:choose>
                </structuredBody>
            </component>
        </ClinicalDocument>
    </xsl:template>

    <xsl:template match="fhir:MeasureReport/fhir:group">
        <xsl:apply-templates select="fhir:population" />
    </xsl:template>

    <xsl:template match="fhir:MeasureReport/fhir:group/fhir:population">
        <component>
            <observation classCode="OBS" moodCode="EVN">
                <templateId extension="2016-09-01" root="2.16.840.1.113883.10.20.27.3.5" />
                <templateId extension="2019-05-01" root="2.16.840.1.113883.10.20.27.3.16" />
                <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" codeSystemName="ActCode" displayName="Assertion" />
                <statusCode code="completed" />
                <value code="IPOP" codeSystem="2.16.840.1.113883.5.4" codeSystemName="ActCode" xsi:type="CD" />
                <!--IPOP Count-->
                <entryRelationship inversionInd="true" typeCode="SUBJ">
                    <observation classCode="OBS" moodCode="EVN">
                        <!-- Aggregate Count -->
                        <templateId root="2.16.840.1.113883.10.20.27.3.3" />
                        <xsl:apply-templates select="fhir:code" />
                        <value value="{fhir:count/@value}" xsi:type="INT" />
                        <methodCode code="COUNT" codeSystem="2.16.840.1.113883.5.84" codeSystemName="ObservationMethod" displayName="Count" />
                    </observation>
                </entryRelationship>
                <xsl:apply-templates select="fhir:subjectResults" />
            </observation>
        </component>
    </xsl:template>

    <xsl:template match="fhir:subjectResults">
        <xsl:message>In subjectResults</xsl:message>
        <xsl:if test="fhir:reference">
            <!-- Assume contained resource for now, but in the future fix so it handles bundle entries too (see resolve-resource in fhir2cda-utility.xslt -->
            <xsl:variable name="id" select="substring-after(fhir:reference/@value, '#')" />
            <xsl:apply-templates mode="subject-list" select="ancestor::fhir:entry[1]/fhir:resource/fhir:*/fhir:contained/fhir:*[fhir:id/@value = $id]"
             />
        </xsl:if>
    </xsl:template>

    <xsl:template match="fhir:List" mode="subject-list">
        <xsl:for-each select="fhir:entry/fhir:item">
            <xsl:message>Processing <xsl:value-of select="fhir:reference/@value" /></xsl:message>
            <xsl:variable name="fullUrl">
                <xsl:call-template name="resolve-to-full-url" />
            </xsl:variable>
            <xsl:apply-templates mode="external-document" select="//fhir:entry[fhir:fullUrl/@value = $fullUrl]/fhir:resource/fhir:*" />
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:MeasureReport" mode="external-document">
        <xsl:message>Reference to QRDA-I individual patient report</xsl:message>
        <xsl:variable name="qrda1-name">
            <xsl:value-of select="fhir:id/@value" />
            <xsl:text>-qrda1.xml</xsl:text>
        </xsl:variable>
        <xsl:for-each select="fhir:identifier[fhir:system/@value = 'urn:ietf:rfc:3986']">
            <xsl:message>Outputting external document reference</xsl:message>
            <reference typeCode="REFR">
                <externalDocument>
                    <xsl:choose>
                        <xsl:when test="starts-with(fhir:value/@value, 'urn:uuid:')">
                            <id root="{substring-after(fhir:value/@value,'urn:uuid:')}" />
                        </xsl:when>
                        <xsl:when test="starts-with(fhir:value/@value, 'urn:oid:')">
                            <id root="{substring-after(fhir:value/@value,'urn:oid:')}" />
                        </xsl:when>
                    </xsl:choose>
                </externalDocument>
            </reference>
        </xsl:for-each>
        <xsl:result-document href="{$qrda1-name}" method="xml">
            <xsl:apply-templates mode="#default" select="." />
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
