<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:manufacturedProduct" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:manufacturedProduct">
        <Medication>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication" />
            </meta>
            <xsl:apply-templates select="cda:manufacturedMaterial/cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            
            <xsl:for-each select="parent::cda:consumable/following-sibling::cda:participant[@typeCode = 'CSM']">
                <xsl:apply-templates select="cda:participantRole/cda:playingEntity/cda:code">
                    <xsl:with-param name="pElementName">form</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </Medication>
    </xsl:template>

</xsl:stylesheet>
