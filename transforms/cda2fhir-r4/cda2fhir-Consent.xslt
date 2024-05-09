<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:authorization" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:authorization">
        <Consent xmlns="http://hl7.org/fhir">
            <!-- id -->
            <xsl:apply-templates select="cda:consent/cda:id" />
            <!-- status -->
            <status value="active"/>
            <!-- scope -->
            <xsl:apply-templates select="cda:consent/cda:code">
                <xsl:with-param name="pElementName">scope</xsl:with-param>
            </xsl:apply-templates>
            <!-- category -->
            <xsl:apply-templates select="cda:consent/cda:code">
                <xsl:with-param name="pElementName">category</xsl:with-param>
            </xsl:apply-templates>
            <!-- patient -->
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <policyRule>
                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                    <valueCode value="unknown" />
                </extension>
            </policyRule>
        </Consent>
    </xsl:template>

</xsl:stylesheet>
