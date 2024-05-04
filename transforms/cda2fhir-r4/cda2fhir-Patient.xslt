<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <xsl:template match="cda:recordTarget" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:recordTarget">
        <Patient>

            <!--MD: Check current Ig -->
            <xsl:variable name="vCurrentIg">
                <xsl:apply-templates select="/" mode="currentIg" />
            </xsl:variable>

            <!--MD: set meta profile based on Ig -->
            <xsl:choose>
                <xsl:when test="$vCurrentIg = 'NA'">
                    <xsl:call-template name="add-meta" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$vCurrentIg" />
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
            <xsl:choose>
                <xsl:when test="cda:patientRole/cda:patient/cda:ethnicGroupCode/@nullFlavor" />
                <xsl:otherwise>
                    <xsl:call-template name="add-ethnicity-codes" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="add-birthtime-extension" />
            <xsl:call-template name="add-birth-sex-extension" />
            <xsl:call-template name="add-birthplace-extension" />
            <xsl:call-template name="add-gender-identity-extension" />
            <xsl:call-template name="add-tribal-affiliation-extension" />
            <xsl:apply-templates select="cda:patientRole/cda:id" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:id" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:name" />
            <xsl:apply-templates select="cda:patientRole/cda:telecom" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:administrativeGenderCode" />
            <xsl:apply-templates select="cda:patientRole/cda:patient/cda:birthTime" />

            <!-- Updating from ifs allowing both boolean and time - only one allowed
                Will check date first and use that otherwise will use boolean-->
            <!-- Update to handle nullFlavor -->
            <xsl:choose>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedTime[@nullFlavor]">
                    <deceasedDateTime>
                        <xsl:apply-templates select="cda:patientRole/cda:patient/sdtc:deceasedTime/@nullFlavor" mode="data-absent-reason-extension" />
                    </deceasedDateTime>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedTime">
                    <deceasedDateTime>
                        <xsl:attribute name="value" select="cda:patientRole/cda:patient/sdtc:deceasedTime/lcg:cdaTS2date(@value)" />
                    </deceasedDateTime>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient/sdtc:deceasedInd/@value">
                    <deceasedBoolean>
                        <xsl:attribute name="value" select="cda:patientRole/cda:patient/sdtc:deceasedInd/@value" />
                    </deceasedBoolean>
                </xsl:when>
                <xsl:when test="cda:patientRole/cda:patient[not(sdtc:deceasedTime) and not(sdtc:deceasedInd)]">
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

            <!-- Add Communication -->
            <!-- SG 20240402: Update to allow for multiple languageCommunication -->
            <xsl:for-each select="cda:patientRole/cda:patient/cda:languageCommunication">
                <communication>
                    <language>
                        <coding>
                            <!-- Hard coding system because it's not in the CDA -->
                            <system value="urn:ietf:bcp:47" />
                            <code value="{cda:languageCode/@code}" />
                            <!-- **TODO** Add a mapping here to get the display -->
                        </coding>
                    </language>
                    <xsl:if test="cda:preferenceInd">
                        <preferred>
                            <xsl:attribute name="value" select="cda:preferenceInd/@value" />
                        </preferred>
                    </xsl:if>
                </communication>
            </xsl:for-each>

            <!-- MD: Add transform RelatedPerson -->
            <xsl:choose>
                <xsl:when test="
                        //cda:section/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.15']/
                        following-sibling::cda:entry/cda:organizer/cda:subject/cda:relatedSubject[@classCode = 'PRS']">
                    <link>
                        <other>
                            <reference value="urn:uuid:{//cda:section/cda:templateId[@root='2.16.840.1.113883.10.20.22.2.15']/
                following-sibling::cda:entry/cda:organizer/cda:subject/cda:relatedSubject[@classCode='PRS']/@lcg:uuid}"> </reference>
                        </other>
                        <type value="seealso" />
                    </link>
                </xsl:when>
            </xsl:choose>



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
                    <xsl:variable name="text">
                        <xsl:choose>
                            <xsl:when test="@displayName">
                                <xsl:value-of select="@displayName" />
                            </xsl:when>
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

                    <extension url="ombCategory">
                        <valueCoding>
                            <system value="{$codeSystemUri}" />
                            <xsl:choose>
                                <xsl:when test="$code = 'NI'">
                                    <code value="UNK" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <code value="{$code}" />
                                </xsl:otherwise>
                            </xsl:choose>

                            <xsl:if test="@displayName">
                                <display value="{@displayName}" />
                            </xsl:if>
                        </valueCoding>
                    </extension>
                    <!--MD: this only work if patient has only one race. only one <extension url="text"> is allowed
          <extension url="text">
            <valueString value="{$text}" />
          </extension>
           -->

                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/sdtc:raceCode[not(@nullFlavor)]">

                    <xsl:variable name="text">
                        <xsl:choose>
                            <xsl:when test="@displayName">
                                <xsl:value-of select="@displayName" />
                            </xsl:when>
                            <xsl:when test="@nullFlavor">
                                <xsl:value-of select="@nullFlavor" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@code" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
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
                        <!--MD: for file OMB category race code must use extension ombCategory -->
                        <xsl:when test="$code = '1002-5' or $code = '2028-9' or $code = '2054-5' or $code = '2076-8' or $code = '2106-3'">
                            <extension url="ombCategory">
                                <valueCoding>
                                    <system value="{$codeSystemUri}" />
                                    <code value="{$code}" />
                                    <xsl:if test="@displayName">
                                        <display value="{@displayName}" />
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
                                        <display value="{@displayName}" />
                                    </xsl:if>
                                </valueCoding>
                            </extension>
                        </xsl:otherwise>
                    </xsl:choose>


                    <!--MD  only one <extension url="text"> is allowed
          <extension url="text">
            <valueString value="{$text}" />
          </extension>
          -->
                </xsl:for-each>

                <!--MD: if patient has more than one race set the text as Mixed  -->
                <xsl:choose>
                    <xsl:when test="//cda:patientRole/cda:patient/sdtc:raceCode[not(@nullFlavor)]">
                        <extension url="text">
                            <valueString value="'Mixed'" />
                        </extension>
                    </xsl:when>
                    <xsl:otherwise>
                        <extension url="text">
                            <valueString>
                                <xsl:attribute name="value">
                                    <xsl:choose>
                                        <xsl:when test="//cda:patientRole/cda:patient/cda:raceCode[@nullFlavor]">
                                            <xsl:value-of select="//cda:patientRole/cda:patient/cda:raceCode/@nullFlavor" />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="cda:patientRole/cda:patient/cda:raceCode/@displayName" />
                                        </xsl:otherwise>
                                    </xsl:choose>

                                </xsl:attribute>
                            </valueString>
                        </extension>
                    </xsl:otherwise>
                </xsl:choose>
            </extension>
        </xsl:if>
    </xsl:template>

    <xsl:template name="add-ethnicity-codes">
        <!-- Ethnicity -->
        <xsl:if test="cda:patientRole/cda:patient/cda:ethnicGroupCode or cda:patientRole/cda:patient/sdtc:ethnicGroupCode">
            <extension url="http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity">
                <xsl:for-each select="cda:patientRole/cda:patient/cda:ethnicGroupCode">
                    <xsl:variable name="text">
                        <xsl:choose>
                            <xsl:when test="@displayName">
                                <xsl:value-of select="@displayName" />
                            </xsl:when>
                            <xsl:when test="@nullFlavor">
                                <xsl:value-of select="@nullFlavor" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@code" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
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
                    <extension url="ombCategory">
                        <valueCoding>
                            <system value="{$codeSystemUri}" />
                            <xsl:choose>
                                <xsl:when test="$code = 'NI'">
                                    <code value="UNK" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <code value="{$code}" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@displayName">
                                <display value="{@displayName}" />
                            </xsl:if>
                        </valueCoding>
                    </extension>
                    <extension url="text">
                        <valueString value="{$text}" />
                    </extension>

                </xsl:for-each>
                <xsl:for-each select="cda:patientRole/cda:patient/sdtc:ethnicGroupCode">
                    <xsl:variable name="text">
                        <xsl:choose>
                            <xsl:when test="@displayName">
                                <xsl:value-of select="@displayName" />
                            </xsl:when>
                            <xsl:when test="@nullFlavor">
                                <xsl:value-of select="@nullFlavor" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@code" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
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
                    <extension url="detailed">
                        <valueCoding>
                            <system value="{$codeSystemUri}" />
                            <code value="{$code}" />
                            <xsl:if test="@displayName">
                                <display value="{@displayName}" />
                            </xsl:if>
                        </valueCoding>
                    </extension>
                    <extension url="text">
                        <valueString value="{$text}" />
                    </extension>
                </xsl:for-each>
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
        <xsl:for-each select="/cda:ClinicalDocument/descendant::cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.200']">
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

    <!-- SG 20240321: added -->
    <xsl:template name="add-birthplace-extension">
        <xsl:for-each select="cda:patientRole/cda:patient/cda:birthplace/cda:place">
            <extension url="http://hl7.org/fhir/StructureDefinition/patient-birthPlace">
                <xsl:apply-templates select="cda:addr">
                    <xsl:with-param name="pElementName" select="'valueAddress'" />
                </xsl:apply-templates>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="add-gender-identity-extension">
        <xsl:for-each select="/cda:ClinicalDocument/descendant::cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.34.3.45']">
            <extension url="http://hl7.org/fhir/StructureDefinition/patient-genderIdentity">
                <xsl:apply-templates select="cda:value" />
            </extension>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: US Public Health Tribal Affiliation Extension -->
    <xsl:template name="add-tribal-affiliation-extension">
        <xsl:for-each select="//cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.48']">
            <xsl:comment>US Public Health Tribal Affiliation Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-tribal-affiliation-extension">
                <extension url="TribeName">
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName" select="'valueCoding'" />
                        <xsl:with-param name="pIncludeCoding" select="false()" />
                    </xsl:apply-templates>
                </extension>
                <extension url="EnrolledTribeMember">
                    <xsl:apply-templates select="cda:value">
                        <xsl:with-param name="pElementName" select="'valueBoolean'" />
                    </xsl:apply-templates>
                </extension>
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
                <xsl:for-each select="cda:patientRole/cda:patient/cda:languageCommunication/cda:languageCode[not(@nullFlavor)]">
                    <p>Language: <xsl:value-of select="@code" /></p>
                </xsl:for-each>
            </div>
        </text>
    </xsl:template>


</xsl:stylesheet>
