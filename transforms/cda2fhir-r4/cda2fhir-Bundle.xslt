<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0" xmlns="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/" mode="convert">
    <Bundle>
      <!-- Generates an id that is unique for the node. It will always be the same for the same id. Should be unique across 
           documents as the CDA document id should be unique-->
      <id value="{concat($gvCurrentIg, '-bundle-', generate-id(cda:ClinicalDocument/cda:id))}" />
      <!-- Adding meta for eICR - needs to conform to eICR document bundle profile -->
      <xsl:variable as="xs:string" name="vBundleProfile">
        <xsl:choose>
          <xsl:when test="$gvCurrentIg = 'eICR'">
            <xsl:text>http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-document-bundle</xsl:text>
          </xsl:when>
          <xsl:when test="$gvCurrentIg = 'RR'">
            <xsl:text>http://hl7.org/fhir/us/ecr/StructureDefinition/rr-document-bundle</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="$vBundleProfile != ''">
        <meta>
          <profile value="{$vBundleProfile}" />
        </meta>
      </xsl:if>
      <!--  identifier -->
      <!-- 20260424 SG: Update identifier - add assigner -->
      <identifier>
        <system value="urn:ietf:rfc:3986" />
        <value value="{concat('urn:uuid:', cda:ClinicalDocument/cda:id/@lcg:uuid)}" />
        <assigner>
          <display value="ecr-cda-fhir-transform" />
        </assigner>
      </identifier>
      <type value="document" />
      <timestamp>
        <xsl:attribute name="value">
          <xsl:choose>
            <xsl:when test="cda:ClinicalDocument/cda:effectiveTime/@value">
              <xsl:value-of select="lcg:cdaTS2date(cda:ClinicalDocument/cda:effectiveTime/@value)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'NI'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </timestamp>
      <xsl:apply-templates mode="bundle-entry" select="cda:ClinicalDocument" />
      <xsl:for-each select="//descendant::cda:entry">
        <xsl:apply-templates mode="bundle-entry" select="cda:*[not(@nullFlavor)]" />
      </xsl:for-each>
      <!-- Organization resources from participants of type LOC -->
      <xsl:for-each
        select="//descendant::cda:participant[@typeCode = 'LOC'][not(cda:participantRole/@classCode = 'TERR') and not(cda:participantRole/@classCode = 'SDLOC')][not(@nullFlavor)][not(parent::cda:substanceAdministration)]">
        <xsl:apply-templates mode="bundle-entry" select="." />
      </xsl:for-each>
      <!-- SG 202402: Added -->
      <!-- Device resources from [C-CDA R1.1] Product Instances in procedures -->
      <xsl:for-each select="//cda:participant/cda:participantRole[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.37']">
        <xsl:apply-templates mode="bundle-entry" select="." />
      </xsl:for-each>
      <!-- 20260803 Claude (item 41): identifier-only Practitioner resources for hollow authors whose id
           matched no complete participation (flagged lcg:unmatched="true" by the
           update-referenced-actor-uuids phase in the SaxonPE/NativeUUIDGen entry points). This is a
           global pass like the LOC pass above because the local author fan-outs can't be relied on to
           reach every hollow author: several Observation fan-outs filter authors on having grandchildren,
           which an id-only author never has. Templates live in cda2fhir-Practitioner.xslt. -->
      <xsl:for-each select="//cda:assignedAuthor[@lcg:unmatched = 'true']">
        <xsl:apply-templates select="." mode="unmatched-participation-entry" />
      </xsl:for-each>
    </Bundle>
  </xsl:template>
</xsl:stylesheet>
