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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0"
    exclude-result-prefixes="lcg xsl cda fhir xhtml">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="native-xslt-uuid.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-EncompassingEncounter.xslt" />
    <xsl:import href="fhir2cda-inFulfillmentOf.xslt"/>

    <xsl:variable name="docId" select="lower-case(uuid:get-uuid())" />

    <!-- FHIR Composition -> CDA ClinicalDocument -->
    <xsl:template match="fhir:Composition">
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig"/>
        </xsl:variable>
        <xsl:variable name="docId" select="lower-case(uuid:get-uuid())" />
        <ClinicalDocument>
            <realmCode code="US" />
            <typeId root="2.16.840.1.113883.1.3" extension="POCD_HD000040" />
            <xsl:if test="$vCurrentIg = 'PCP'">
                <templateId root="2.16.840.1.113883.10.20.22.1.1" extension="2015-08-01" />
                <templateId root="2.16.840.1.113883.10.20.22.1.15" extension="2015-08-01" />
            </xsl:if>
            
            <!-- MD: add dental template Id -->
            <xsl:if test="$vCurrentIg = 'DentalConsultNote'">
                <xsl:comment select="' [C-CDA R1.1] US Realm Header '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" extension="2015-08-01" />
                <xsl:comment select="' Consultation Note (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.4" extension="2015-08-01"/>
                <xsl:comment select="' Dental Consultation Note template ID '" />
                <templateId root="2.16.840.1.113883.10.20.40.1.1.2" extension="2020-08-01"/>
            </xsl:if>
            <xsl:if test="$vCurrentIg = 'DentalReferalNote'">
                <xsl:comment select="' [C-CDA R1.1] US Realm Header '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" extension="2015-08-01" />
                <xsl:comment select="' Referral Note (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.14" extension="2015-08-01"/>
                <xsl:comment select="' Dental Referral Note template ID '" />
                <templateId root="2.16.840.1.113883.10.20.40.1.1.1" extension="2020-08-01"/>
            </xsl:if>
            
            <xsl:if test="$vCurrentIg = 'eICR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <xsl:if test="$vCurrentIg = 'RR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <!-- generate a new ID for this document. Save the FHIR document id in parentDocument with a type of XFRM -->
            <!-- MD:   -->
            <xsl:choose>
                <xsl:when test="/fhir:Bundle/fhir:type/@value='document' and /fhir:Bundle/fhir:identifier">
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
                <xsl:call-template name="CodeableConcept2CD" />
            </xsl:for-each>
            <!-- SG 20210701: Where are the other IG titles? Added a choice around this -->
            <xsl:choose>
                <xsl:when test="$vCurrentIg = 'eICR'">
                    <title>Initial Public Health Case Report</title>
                </xsl:when>
                <xsl:when test="$vCurrentIg = 'RR'">
                    <title>Reportability Response</title>
                </xsl:when>
                <xsl:when test="$vCurrentIg = 'PCP'">
                    <title>Pharmacist Care Plan</title>
                </xsl:when>
                <xsl:otherwise>
                    <!-- add handle for <fhir:title> -->
                    <xsl:choose>
                        <xsl:when test="//fhir:Composition/fhir:title">
                            <title>
                                <xsl:value-of select="fhir:title/@value"/>
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
                    <confidentialityCode codeSystem="2.16.840.1.113883.5.25" code="{fhir:confidentiality/@value}" />
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
                        <xsl:with-param name="pElementName" select="'setId'"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose> 
            <xsl:choose>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value">
                    <versionNumber value="{fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value}" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value">
                    <versionNumber value="{fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value}" />
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
                    <xsl:apply-templates select="fhir:author" mode="custodian" />
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:choose>
                <!-- fhir:recipient -> cda:informationRecipient -->
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension'] or fhir:extension[@url='http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension']">
                    <xsl:for-each select="fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension'] | fhir:extension[@url='http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension']">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pPosition" select="position()" />
                        </xsl:apply-templates>
                    </xsl:for-each>    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$vCurrentIg = 'DentalReferalNote'">
                           <informationRecipient>
                              <intendedRecipient>
                                  <xsl:call-template  name="get-addr"/>
                                  <xsl:call-template name="get-telecom"/>
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
           
           <!-- fhir:attester -> cda:legalAuthenticator -->
            <xsl:apply-templates select="fhir:attester" />
            
            <!-- fhir:extension  -->
            <!-- be aware a Composition can have multiple extensions to ensure in correct context -->
            <!-- MD: OrderExtension -> cda:inFulfillmentOf -->
            <xsl:variable name="vCompositionOrderExtension" 
                select="'http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension'"/>
            <xsl:apply-templates select="fhir:extension[@url=$vCompositionOrderExtension]" 
                mode="inFulfillmentOf">      
            </xsl:apply-templates>
                    
            <xsl:apply-templates select="fhir:event" />
            <xsl:apply-templates select="fhir:encounter" />
            <component>
                <structuredBody>
                    <!-- If this is eICR we need to manually add an Encounters section -->
                    <xsl:choose>
                        <xsl:when test="$vCurrentIg = 'eICR'">
                            <component>
                                <xsl:for-each select="//fhir:Encounter">
                                    <xsl:call-template name="create-eicr-encounters-section" />
                                </xsl:for-each>
                            </component>
                        </xsl:when>
                        <!-- If this is an RR we don't want an Encounters section -->
                        <xsl:when test="$vCurrentIg = 'RR'"/>
                        <xsl:otherwise>
                            <!-- MD: to create encounters section based on the encounter reference in the resources -->
                            <xsl:choose>
                                <xsl:when test="//fhir:*/fhir:encounter/fhir:reference">
                                    <component>
                                        <xsl:call-template name="create-encounters-section"/>                                     
                                    </component>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>  
                    
                    
                    <xsl:for-each select="fhir:section">
                        <component>
                            <!-- Commenting the below out - let's leave the output in the same order as it is -->
                            <!--<xsl:sort select="fhir:title/@value" />-->
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="title" select="fhir:title/@value" />
                            </xsl:apply-templates>
                        </component>
                    </xsl:for-each>
                </structuredBody>
            </component>
        </ClinicalDocument>
    </xsl:template>

    <!-- This code is obsolete, RR is now a Composition rather than a Communication so processing with the other Compositions -->
    <!-- (RR) Initial Public Health Case Report Reportability Response Document (ClinicalDocument) -->
   <!-- <xsl:template match="fhir:Communication[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-communication']">
        <ClinicalDocument xmlns="urn:hl7-org:v3">
            <realmCode code="US" />
            <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
            <xsl:call-template name="get-template-id" />
            <xsl:call-template name="get-id">
                <xsl:with-param name="pNoNullAllowed" select="true()" />
            </xsl:call-template>
            <!-\- Document Code -\->
            <code code="88085-6" codeSystem="2.16.840.1.113883.6.1" displayName="Reportability response report Document Public health" />
            <title>Reportability Response</title>

            <!-\- fhir:sent -> cda:effectiveTime -\->
            <xsl:call-template name="get-effective-time">
                <xsl:with-param name="pElement" select="fhir:sent" />
            </xsl:call-template>

            <xsl:choose>
                <xsl:when test="fhir:meta/fhir:security">
                    <xsl:apply-templates select="fhir:meta/fhir:security" />
                </xsl:when>
                <xsl:otherwise>
                    <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" displayName="Normal" />
                </xsl:otherwise>
            </xsl:choose>

            <languageCode code="en-US" />

            <!-\- fhir:subject -> cda:recordTarget -\->
            <xsl:apply-templates select="fhir:subject" />

            <!-\- fhir:sender -> cda:author -\->
            <xsl:apply-templates select="fhir:sender" />
            <!-\- fhir:sender -> cda:custodian -\->
            <xsl:apply-templates select="fhir:sender" mode="custodian" />

            <!-\- fhir:recipient -> cda:informationRecipient -\->
            <xsl:for-each select="fhir:recipient">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pPosition" select="position()" />
                </xsl:apply-templates>
            </xsl:for-each>

            <!-\- fhir:encounter -> cda:componentOf/encompassingEncounter -\->
            <xsl:apply-templates select="fhir:encounter" />

            <component>
                <structuredBody>
                    <!-\- fhir:topic -> (RR) Reportability Response Subject Section (this whole section is the text that is in fhir:topic) -\->
                    <xsl:apply-templates select="fhir:topic" />
                    <!-\- fhir:payload[eicr-information-payload] -> (RR) Electronic Initial Case Report Section -\->
                    <xsl:apply-templates select="fhir:payload[@id = 'eicr-information']" mode="rr" />
                    <!-\- fhir:payload[relevant-reportable-condition] -> Reportability Response Summary Section 
               Create ONE Reportability Response Summary Section and fill it with multiple relevant-reportable-condition payloads = PlanDefinitionand 
               But not if the eICR was not processed (RRVS22)-\->
                    <xsl:if
                        test="//fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-observation'][fhir:code/fhir:coding/fhir:code[@value != 'RRVS22']]">
                        <xsl:call-template name="make-reportability-response-summary-section" />
                    </xsl:if>

                </structuredBody>
            </component>
        </ClinicalDocument>
    </xsl:template>-->

    <!-- fhir:extension[rr-eicr-processing-status-extension] -> (RR) RR eICR Processing Status (Act) and eICR Validation Output (Observation) -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension']" mode="rr">
        <!-- fhir:extension[eICRProcessingStatus] -> (RR) eICR Processing Status (Act)  -->
        <xsl:apply-templates select="fhir:extension[@url = 'eICRProcessingStatus']" mode="rr" />
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
            <xsl:apply-templates select="." mode="rr" />
        </xsl:for-each>
    </xsl:template>

    <!-- QUESTIONNAIRE RESPONSE -->
    <!-- SG: Dave, this is a global variable - wondering if this is what you really meant to do here or should this be inside a template? -->
    <xsl:variable name="infection-id" select="generate-id(//fhir:item[fhir:linkId/@value = 'event-type'][1])" />
    <!--  <xsl:template match="fhir:QuestionnaireResponse[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-single-person-report-questionnaire-response']">-->

    <xsl:template match="fhir:QuestionnaireResponse">
        <ClinicalDocument xmlns="urn:hl7-org:v3">
            <realmCode code="US" />
            <typeId extension="POCD_HD000040" root="2.16.840.1.113883.1.3" />
            <!-- templateId -->
            <xsl:call-template name="get-template-id" />
            <!-- id -->
            <xsl:call-template name="get-id">
                <xsl:with-param name="pNoNullAllowed" select="true()" />
            </xsl:call-template>
            <!-- code -->
            <xsl:apply-templates select="." mode="map-profile-to-code" />
            <!-- title -->
            <xsl:apply-templates select="." mode="map-to-title" />
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
            <setId nullFlavor="1" />
            <versionNumber>
                <xsl:attribute name="value"> </xsl:attribute>
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
            <xsl:call-template name="make-encompassing-encounter-hai" />
            <component>
                <structuredBody>
                    <!--<component>
            <xsl:call-template name="infection-details-section" />
          </component>
          <component>
            <xsl:call-template name="risk-factors-section" />
          </component>
          <component>
            <xsl:call-template name="findings-section" />
          </component>
          <!-\- DD adding optional nhsn comments section -\->
          <xsl:if test="fhir:item[fhir:linkId[@value = 'nhsn-comment']]">
            <component>
              <xsl:call-template name="nhsn-comments-section" />
            </component>
          </xsl:if>-->
                    <!-- Any item that doesn't have a value should be a section -->
                    <component>
                        <xsl:apply-templates select="fhir:item[not(fhir:answer)]" />
                    </component>
                </structuredBody>
            </component>
        </ClinicalDocument>
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
                            <xsl:call-template name="CodeableConcept2CD">
                                <xsl:with-param name="pElementName">value</xsl:with-param>
                                <xsl:with-param name="pXSIType">CD</xsl:with-param>
                            </xsl:call-template>
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
            <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" code="86468-6" displayName="Report comment Section" />
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
                    <templateId root="2.16.840.1.113883.10.20.5.6.243" extension="2017-04-01" />
                    <code code="86467-8" displayName="Report comment Narrative" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" />
                    <text>
                        <xsl:value-of select="fhir:item/fhir:answer/fhir:valueString/@value" />
                    </text>
                </act>
            </entry>
        </section>
    </xsl:template>
</xsl:stylesheet>
