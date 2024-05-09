<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- SG: Match if this is a substanceAdministration inside a Medication Administered, Admission Medication, or Procedures section -->
    <xsl:template match="
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']] |
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>


    <xsl:template match="
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']] |
            cda:manufacturedProduct[../../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]">
        <Medication>
            <code>
                <xsl:for-each select="cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
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
                <xsl:for-each select="cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
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
                <xsl:for-each select="cda:manufacturedMaterial/cda:code[@nullFlavor]">
                    <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                </xsl:for-each>
            </code>
        </Medication>
    </xsl:template>

</xsl:stylesheet>
