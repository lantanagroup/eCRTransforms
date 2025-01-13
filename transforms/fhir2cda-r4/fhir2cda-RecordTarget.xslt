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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir sdtc" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
                <xsl:apply-templates mode="record-target" select="fhir:resource/fhir:*" />
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
                <xsl:choose>
                    <!-- Check to see that at least one of the identifier isn't a DAR -->
                    <xsl:when test="fhir:identifier/fhir:value">
                        <xsl:apply-templates select="fhir:identifier[fhir:value]" />

                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:variable name="vNoNullAllowed">
                    <xsl:choose>
                        <xsl:when test="$gvCurrentIg = 'HAI'">true</xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>

                </xsl:variable>
                <!-- SG NOTE: Address isn't required for HAI IGs like it is for US Realm Header based IGs and US Core only has address as MS -->
                <xsl:call-template name="get-addr">
                    <xsl:with-param name="pNoNullAllowed" select="$vNoNullAllowed" />
                </xsl:call-template>
                <!-- SG NOTE: Telecom isn't required for HAI IGs like it is for US Realm Header based IGs and US Core only has address as MS -->
                <xsl:call-template name="get-telecom">
                    <xsl:with-param name="pNoNullAllowed" select="$vNoNullAllowed" />
                </xsl:call-template>


                <patient>
                    <xsl:call-template name="get-person-name" />

                    <xsl:choose>
                        <xsl:when test="fhir:gender/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                            <administrativeGenderCode>
                                <xsl:apply-templates select="fhir:gender/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                            </administrativeGenderCode>
                        </xsl:when>
                        <xsl:otherwise>
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
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:call-template name="get-time">
                        <xsl:with-param name="pElement" select="fhir:birthDate" />
                        <xsl:with-param name="pElementName" select="'birthTime'" />
                    </xsl:call-template>

                    <!-- SG 2023-06-05 update to deal with data-absent-reason -->
                    <xsl:choose>
                        <xsl:when test="fhir:deceasedDateTime">
                            <sdtc:deceasedInd value="true" />
                            <xsl:choose>
                                <xsl:when test="fhir:deceasedDateTime/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">
                                    <sdtc:deceasedTime>
                                        <xsl:apply-templates select="fhir:deceasedDateTime/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" />
                                    </sdtc:deceasedTime>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="get-time">
                                        <xsl:with-param name="pElement" select="fhir:deceasedDateTime" />
                                        <xsl:with-param name="pElementName" select="'sdtc:deceasedTime'" />
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- When deceasedDateTime isn't present and deceasedBoolean is present set deceasedInd to true and deceasedTime to a nullFlavor of NI -->
                        <xsl:when test="fhir:deceasedBoolean">
                            <sdtc:deceasedInd value="true" />
                            <sdtc:deceasedTime nullFlavor="NI" />
                        </xsl:when>
                        <!-- Assume when deceasedDateTime isn't present and when deceasedBoolean isn't present that the patient is still alive -->
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
                    <xsl:if test="not(fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'])">
                        <raceCode nullFlavor="NI" />
                    </xsl:if>
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity']" />
                    <xsl:if test="not(fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity'])">
                        <ethnicGroupCode nullFlavor="NI" />
                    </xsl:if>


                    <!-- Check for guardian information -->
                    <!-- Added Cerner local code (1156) for Guardian -->
                    <!-- Added http://hl7.org/fhir/R4/v2/0131/index.html code for Next of kin (N) -->
                    <xsl:for-each select="fhir:contact[fhir:relationship/fhir:coding/fhir:code[@value = 'GUARD' or @value = '1156' or @value = 'N']]">
                        <guardian>
                            <xsl:apply-templates select="fhir:address" />
                            <xsl:apply-templates select="fhir:telecom" />
                            <xsl:choose>
                                <xsl:when test="fhir:name">
                                    <guardianPerson>
                                        <xsl:apply-templates select="fhir:name" />
                                    </guardianPerson>
                                </xsl:when>
                                <!-- guardianOrganization not allowed in C-CDA (only guardianPerson) -->
                                <!--<xsl:when test="fhir:organization">
                                    <!-\- guardianOrganization -\->
                                    <xsl:for-each select="fhir:organization/fhir:reference">
                                        <xsl:variable name="referenceURI">
                                            <xsl:call-template name="resolve-to-full-url">
                                                <xsl:with-param name="referenceURI" select="@value" />
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="guardianOrganization" />
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </xsl:when>-->
                            </xsl:choose>
                        </guardian>
                    </xsl:for-each>

                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-birthPlace']" />

                    <xsl:choose>
                        <xsl:when test="fhir:communication">
                            <!-- SG 20210802: Added for-each - there can be multiple languages unfortunately some of them are going to be in local code systems - if they 
                                 are translations then need to only get the proper code 
                                 Maybe we can do some mapping with the display later if this causes problems (i.e. they don't have a proper code) -->
                            <xsl:for-each select="fhir:communication[fhir:language/fhir:coding/fhir:system/@value = 'urn:ietf:bcp:47']">
                                <languageCommunication>
                                    <languageCode>
                                        <xsl:choose>
                                            <xsl:when test="fhir:language/fhir:coding/fhir:code/not(@value = '')">
                                                <xsl:attribute name="code" select="fhir:language/fhir:coding/fhir:code/@value" />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:attribute name="nullFlavor" select="'NI'" />
                                            </xsl:otherwise>
                                        </xsl:choose>

                                    </languageCode>
                                    <xsl:if test="fhir:preferred/@value = 'true'">
                                        <preferenceInd value="true" />
                                    </xsl:if>
                                    <!-- SG 20240402: This is a boolean and can have both true and false -->
                                    <xsl:if test="fhir:preferred/@value = 'false'">
                                        <preferenceInd value="false" />
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
                <!-- providerOrganization -->
                <xsl:for-each select="fhir:managingOrganization/fhir:reference">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                        <xsl:apply-templates select="fhir:resource/fhir:*" mode="providerOrganization" />
                    </xsl:for-each>
                </xsl:for-each>
            </patientRole>
        </recordTarget>
    </xsl:template>

    <xsl:template match="fhir:Organization" mode="providerOrganization">
        <providerOrganization>
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

            <xsl:call-template name="get-telecom" />

            <xsl:choose>
                <xsl:when test="fhir:address">
                    <xsl:apply-templates select="fhir:address" />
                </xsl:when>
                <xsl:otherwise>
                    <addr nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

        </providerOrganization>
    </xsl:template>

    <!--<xsl:template match="fhir:Organization" mode="guardianOrganization">
        <guardianOrganization>
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

            <xsl:call-template name="get-telecom" />

            <xsl:choose>
                <xsl:when test="fhir:address">
                    <xsl:apply-templates select="fhir:address" />
                </xsl:when>
                <xsl:otherwise>
                    <addr nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>

        </guardianOrganization>
    </xsl:template>-->

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

    <!-- birthplace -->
    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-birthPlace']">
        <xsl:for-each select="fhir:valueAddress">
            <birthplace>
                <place>
                    <xsl:call-template name="get-addr">
                        <xsl:with-param name="pElement" select="." />
                    </xsl:call-template>
                </place>
            </birthplace>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
