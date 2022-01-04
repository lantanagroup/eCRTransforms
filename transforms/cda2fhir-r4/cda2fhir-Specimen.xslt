<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:import href="c-to-fhir-utility.xslt" />

  <!-- Specimen Collection Procedure -> FHIR Specimen -->
  <xsl:template match="cda:organizer/cda:component/cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.415']]" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <xsl:template match="cda:organizer/cda:component/cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.415']]">
    <Specimen xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
      <xsl:call-template name="add-meta" />
      <xsl:apply-templates select="cda:participant/cda:participantRole/cda:id" />
      <xsl:apply-templates select="cda:statusCode" />
      <xsl:apply-templates select="cda:participant/cda:participantRole/cda:playingEntity/cda:code">
        <xsl:with-param name="pElementName">type</xsl:with-param>
      </xsl:apply-templates>
      <xsl:if test="cda:effectiveTime or cda:targetSiteCode">
        <collection>
          <xsl:apply-templates select="cda:effectiveTime">
            <xsl:with-param name="pStartElementName" select="'collected'" />
          </xsl:apply-templates>
          <xsl:apply-templates select="cda:targetSiteCode">
            <xsl:with-param name="pElementName" select="'bodySite'" />
          </xsl:apply-templates>
        </collection>
      </xsl:if>

    </Specimen>
  </xsl:template>

</xsl:stylesheet>
