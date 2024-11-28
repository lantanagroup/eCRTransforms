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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xhtml" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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

            <xsl:if test="$gvCurrentIg = 'eICR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <xsl:if test="$gvCurrentIg = 'RR'">
                <xsl:call-template name="get-template-id" />
            </xsl:if>
            <!-- generate a new ID for this document. Save the FHIR document id in parentDocument with a type of XFRM -->
            <id root="{$docId}" />

            <xsl:for-each select="fhir:type">
                <xsl:apply-templates select="." />
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

            <!-- relatedDocument/parentDocument -->
            <relatedDocument typeCode="XFRM">
                <parentDocument>
                    <xsl:choose>
                        <xsl:when test="//fhir:Bundle[fhir:type/@value = 'document']/fhir:identifier">
                            <xsl:apply-templates select="//fhir:Bundle[fhir:type/@value = 'document']/fhir:identifier" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
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
                        <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value">
                            <versionNumber value="{fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber']/fhir:valueString/@value}" />
                        </xsl:when>
                        <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value">
                            <versionNumber value="{fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber']/fhir:valueInteger/@value}" />
                        </xsl:when>
                    </xsl:choose>
                </parentDocument>
            </relatedDocument>
            
            <xsl:for-each select="fhir:relatesTo[fhir:code/@value='replaces']">
                <relatedDocument typeCode="RPLC">
                    <parentDocument>
                        <xsl:choose>
                            <xsl:when test="fhir:targetIdentifier">
                                <xsl:apply-templates select="fhir:targetIdentifier" />
                            </xsl:when>
                            <xsl:otherwise>
                                <id nullFlavor="NI" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </parentDocument>
                </relatedDocument>
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

</xsl:stylesheet>
