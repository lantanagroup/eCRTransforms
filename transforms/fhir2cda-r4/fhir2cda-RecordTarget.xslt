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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    version="2.0" exclude-result-prefixes="lcg xsl cda fhir sdtc">

    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />

    <!-- fhir:subject[parent::fhir:Composition or parent::fhir:Communication or parent::fhir:QuestionnaireResponse] -> get referenced resource entry url and process -->
    <!-- **TODO** Do we really need the parents - wouldn't we want to process all subjects here? -->
    <xsl:template match="fhir:subject[parent::fhir:Composition or parent::fhir:Communication or parent::fhir:QuestionnaireResponse]">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="record-target" />
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:Patient" mode="record-target">
        <xsl:message>Converting Patient into record-target</xsl:message>
        <xsl:call-template name="make-record-target" />
    </xsl:template>

    <xsl:template match="fhir:Group" mode="record-target">
        <xsl:message>Converting Group into record-target</xsl:message>
        <xsl:call-template name="make-record-target-from-group" />
    </xsl:template>

    <xsl:template name="make-record-target">
        <recordTarget>
            <patientRole>

                <xsl:call-template name="get-id" />
                <xsl:call-template name="get-addr" />
                <xsl:call-template name="get-telecom" />

                <patient>
                    <xsl:call-template name="get-person-name" />

                    <administrativeGenderCode codeSystem="2.16.840.1.113883.5.1" codeSystemName="AdministrativeGender">
                        <xsl:choose>
                            <xsl:when test="lower-case(fhir:gender/@value) = 'female'">
                                <xsl:attribute name="code">F</xsl:attribute>
                                <xsl:attribute name="displayName">Female</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="lower-case(fhir:gender/@value) = 'male'">
                                <xsl:attribute name="code">M</xsl:attribute>
                                <xsl:attribute name="displayName">Male</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="lower-case(fhir:gender/@value) = 'undifferentiated'">
                                <xsl:attribute name="code">UN</xsl:attribute>
                                <xsl:attribute name="displayName">Undifferentiated</xsl:attribute>
                            </xsl:when>
                        </xsl:choose>
                    </administrativeGenderCode>
                    
                    <xsl:call-template name="get-time">
                        <xsl:with-param name="pElement" select="fhir:birthDate" />
                        <xsl:with-param name="pElementName" select="'birthTime'" />
                    </xsl:call-template>
                    
                    <xsl:choose>
                        <xsl:when test="fhir:deceasedDateTime">
                            <sdtc:deceasedInd value="true" />
                            <xsl:call-template name="get-time">
                                <xsl:with-param name="pElement" select="fhir:deceasedDateTime" />
                                <xsl:with-param name="pElementName" select="'sdtc:deceasedTime'" />
                            </xsl:call-template>
                        </xsl:when>
                        <!-- Assume when deceasedDateTime isn't present that the patient is still alive -->
                        <xsl:otherwise>
                            <sdtc:deceasedInd value="false" />
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:choose>
                        <xsl:when test="fhir:maritalStatus">
                            <xsl:apply-templates select="fhir:maritalStatus">
                                <xsl:with-param name="pElementName">maritalStatusCode</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                    
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race']" />
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity']" />
                    <!-- Check for guardian information -->
                    <xsl:for-each select="fhir:contact[fhir:relationship/fhir:coding/fhir:code/@value = 'GUARD']">
                        <guardian>
                            <xsl:apply-templates select="fhir:address" />
                            <xsl:apply-templates select="fhir:telecom" />
                            <guardianPerson>
                                <xsl:apply-templates select="fhir:name" />
                            </guardianPerson>
                        </guardian>
                    </xsl:for-each>
                    <xsl:choose>
                        <xsl:when test="fhir:communication">
                            <!-- SG 20210802: Added for-each - there can be multiple languages unfortunately some of them are going to be in local code systems - if they 
                                 are translations then need to only get the proper code 
                                 Maybe we can do some mapping with the display later if this causes problems (i.e. they don't have a proper code) -->
                            <xsl:for-each select="fhir:communication/fhir:language/fhir:coding[fhir:system/@value = 'urn:ietf:bcp:47']">
                                <languageCommunication>
                                    <languageCode>
                                        <xsl:attribute name="code" select="fhir:code/@value" />
                                    </languageCode>
                                    <xsl:if test="fhir:preferred/@value = 'true'">
                                        <preferenceInd value="true" />
                                    </xsl:if>
                                </languageCommunication>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <languageCommunication>
                                <languageCode nullFlavor="NI" />
                            </languageCommunication>
                        </xsl:otherwise>
                    </xsl:choose>
                </patient>
            </patientRole>
        </recordTarget>
    </xsl:template>

    <xsl:template name="make-record-target-from-group">
        <recordTarget>
            <patientRole>
                <id nullFlavor="NA" />
            </patientRole>
        </recordTarget>
    </xsl:template>

    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race']">
        <xsl:for-each select="fhir:extension[@url = 'ombCategory']">
            <xsl:choose>
                <xsl:when test="position() = 1">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'raceCode'" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'sdtc:raceCode'" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="fhir:extension[@url = 'detailed']">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pElementName" select="'sdtc:raceCode'" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity']">
        <xsl:for-each select="fhir:extension[@url = 'ombCategory']">
            <xsl:choose>
                <xsl:when test="position() = 1">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'ethnicGroupCode'" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'sdtc:ethnicGroupCode'" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="fhir:extension[@url = 'detailed']">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pElementName" select="'sdtc:ethnicGroupCode'" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
