<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <!-- SubstanceAdministration inside an Admission Medication -->
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN'][ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44']]">
        <xsl:variable name="dateAsserted">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::cda:*/cda:author/cda:time/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:author/cda:time/@value][1]/cda:author/cda:time/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/@value][1]/cda:effectiveTime/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/cda:low/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/cda:low/@value][1]/cda:effectiveTime/cda:low/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/cda:ClinicalDocument/cda:effectiveTime/@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <MedicationAdministration>
            <xsl:call-template name="add-meta" />
            <!-- Therapeutic Response to Medication -->
            <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
            <xsl:apply-templates select="cda:id" />
            <status value="completed" />

            <xsl:apply-templates select="cda:consumable" mode="medication-administration" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>
            <performer>
                <xsl:call-template name="author-reference">
                    <xsl:with-param name="pElementName">actor</xsl:with-param>
                </xsl:call-template>
            </performer>
            <dosage>
                <xsl:apply-templates select="cda:routeCode">
                    <xsl:with-param name="pElementName">route</xsl:with-param>
                </xsl:apply-templates>

                <xsl:apply-templates select="cda:approachSiteCode">
                    <xsl:with-param name="pElementName">method</xsl:with-param>
                </xsl:apply-templates>

                <xsl:apply-templates select="cda:doseQuantity">
                    <xsl:with-param name="pElementName">dose</xsl:with-param>
                    <xsl:with-param name="pSimpleQuantity" select="true()" />
                </xsl:apply-templates>
            </dosage>
            <xsl:call-template name="get-dosage" />
        </MedicationAdministration>
    </xsl:template>

    <!-- SG: Match if this is a substanceAdministration inside a Medication Administered section -->
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN'][ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18']]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
    </xsl:template>

    <!-- SG: Match if this is a substanceAdministration inside a Medication Administered section -->
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN'][ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38']]">
        <xsl:variable name="dateAsserted">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::cda:*/cda:author/cda:time/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:author/cda:time/@value][1]/cda:author/cda:time/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/@value][1]/cda:effectiveTime/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/cda:low/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/cda:low/@value][1]/cda:effectiveTime/cda:low/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/cda:ClinicalDocument/cda:effectiveTime/@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <MedicationAdministration>
            <xsl:call-template name="add-meta" />
            <!-- Therapeutic Response to Medication -->
            <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
            <xsl:apply-templates select="cda:id" />
            <status value="completed" />

            <xsl:apply-templates select="cda:consumable" mode="medication-administration" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>
            <performer>
                <xsl:call-template name="author-reference">
                    <xsl:with-param name="pElementName">actor</xsl:with-param>
                </xsl:call-template>
            </performer>
            <xsl:call-template name="get-dosage" />
        </MedicationAdministration>
    </xsl:template>

    <xsl:template name="get-dosage">

        <xsl:choose>
            <xsl:when test="cda:routeCode/@code or cda:doseQuantity/@value or cda:approachSiteCode/@code">
                <dosage>
                    <xsl:apply-templates select="cda:routeCode">
                        <xsl:with-param name="pElementName">route</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:approachSiteCode">
                        <xsl:with-param name="pElementName">method</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:doseQuantity">
                        <xsl:with-param name="pElementName">dose</xsl:with-param>
                        <xsl:with-param name="pSimpleQuantity" select="true()" />
                    </xsl:apply-templates>
                </dosage>
            </xsl:when>
            <xsl:when test="not(cda:routeCode) and not(cda:approachSiteCode) and not(cda:doseQuantity)" />
            <xsl:when test="cda:doseQuanity/@nullFlavor and not(cda:routeCode) and not(cda:approachSiteCode)">
                <dosage>
                    <xsl:apply-templates select="cda:doseQuantity/@nullFlavor" mode="data-absent-reason-extension" />
                </dosage>
            </xsl:when>
            <xsl:when test="cda:routeCode/@nullFlavor and cda:approachSiteCode/@nullFlavor">
                <dosage>
                    <route>
                    <xsl:apply-templates select="cda:routeCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </route>
                    <method>
                        <xsl:apply-templates select="cda:approachSiteCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </method>
                </dosage>
            </xsl:when>
            <xsl:when test="cda:routeCode/@nullFlavor">
                <dosage>
                    <route>
                        <xsl:apply-templates select="cda:routeCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </route>
                </dosage>
            </xsl:when>
            <xsl:when test="cda:approachSiteCode/@nullFlavor">
                <dosage>
                    <method>
                        <xsl:apply-templates select="cda:approachSiteCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </method>
                </dosage>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-administration">
        <xsl:element name="effectiveDateTime">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:attribute name="value" select="lcg:cdaTS2date(@value)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="cda:low[not(@nullFlavor)]">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high[not(@nullFlavor)]">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:consumable" mode="medication-administration">

        <medicationCodeableConcept>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
                <xsl:variable name="vCode" select="@code" />
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this 
                        isn't going to catch everything, but will clean up testing errors -->
                    <xsl:choose>
                        <xsl:when test="$code-display-mapping/map[@code = $vCode]">
                            <display>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="$code-display-mapping/map[@code = $vCode]/@display" />
                                </xsl:attribute>
                            </display>
                        </xsl:when>
                        <xsl:when test="@displayName">
                            <display value="{@displayName}" />
                        </xsl:when>
                    </xsl:choose>
                </coding>
            </xsl:for-each>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
                <xsl:variable name="vTranslationCode" select="@code" />
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this 
                        isn't going to catch everything, but will clean up testing errors -->
                    <xsl:choose>
                        <xsl:when test="$code-display-mapping/map[@code = $vTranslationCode]">
                            <display>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="$code-display-mapping/map[@code = $vTranslationCode]/@display" />
                                </xsl:attribute>
                            </display>
                        </xsl:when>
                        <xsl:when test="@displayName">
                            <display value="{@displayName}" />
                        </xsl:when>
                    </xsl:choose>
                </coding>
            </xsl:for-each>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@nullFlavor]">
                <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
            </xsl:for-each>
        </medicationCodeableConcept>
    </xsl:template>

</xsl:stylesheet>
