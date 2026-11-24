<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0" xmlns="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- 20261124 Claude (SG decision 2026-11-24, re-trace findings RT-C19, RT-C16, RT-C17): the Bundle is now
       built into a variable (mode convert-build, the template that used to be mode convert) and passed
       through one clean-up pass before it is output. The Composition writes a section entry reference for
       every CDA entry it sees, but some entries match no bundle-entry template and so produce no resource:
       an Immunization Activity in INT mood, a Planned Medication Activity in EVN mood, a Specimen Collection
       Procedure placed outside a Result Organizer. Their references pointed at nothing. Rather than teach the
       Composition which entries each stylesheet will or will not turn into a resource (two lists that drift
       apart), the pass compares what was actually produced: a Composition.section.entry whose urn:uuid
       reference matches no Bundle.entry.fullUrl is replaced by a WARNING comment. Everything else is copied
       unchanged. -->
  <xsl:key name="bundle-fullUrl-key" match="fhir:Bundle/fhir:entry/fhir:fullUrl" use="@value" />

  <xsl:template match="/" mode="convert">
    <xsl:variable name="vBundle">
      <xsl:apply-templates select="." mode="convert-build" />
    </xsl:variable>
    <xsl:apply-templates select="$vBundle" mode="drop-unresolved-section-entries" />
  </xsl:template>

  <xsl:template match="@* | node()" mode="drop-unresolved-section-entries">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="drop-unresolved-section-entries" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fhir:Composition//fhir:section/fhir:entry[starts-with(fhir:reference/@value, 'urn:uuid:')][not(key('bundle-fullUrl-key', fhir:reference/@value))]" mode="drop-unresolved-section-entries">
    <xsl:comment>WARNING: Composition.section.entry omitted - no resource was created for the CDA entry it referred to</xsl:comment>
  </xsl:template>

  <xsl:template match="/" mode="convert-build">
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
      <!-- 20260803 Claude (item 43/CDAFHIR-006): a missing or null-flavored ClinicalDocument
           effectiveTime used to emit timestamp value="NI", which is not a valid FHIR instant.
           Absent-in-source now follows the house convention: data-absent-reason extension, no value. -->
      <xsl:choose>
        <xsl:when test="cda:ClinicalDocument/cda:effectiveTime/@value">
          <timestamp>
            <xsl:attribute name="value">
              <xsl:value-of select="lcg:cdaTS2date(cda:ClinicalDocument/cda:effectiveTime/@value)" />
            </xsl:attribute>
          </timestamp>
        </xsl:when>
        <xsl:otherwise>
          <timestamp>
            <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
              <valueCode value="unknown" />
            </extension>
          </timestamp>
        </xsl:otherwise>
      </xsl:choose>
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
      <!-- 20261124 Claude (RT-C1): hollow performers (assignedEntity) are flagged the same way and need the same pass -->
      <!-- 20261124 Claude (RT-A10): and hollow document-level legalAuthenticator / authenticator / dataEnterer /
           informant. Only the update-referenced-actor-uuids phase sets the flag, so any flagged assignedEntity is one. -->
      <xsl:for-each select="//cda:assignedAuthor[@lcg:unmatched = 'true'] | //cda:assignedEntity[@lcg:unmatched = 'true']">
        <xsl:apply-templates select="." mode="unmatched-participation-entry" />
      </xsl:for-each>
    </Bundle>
  </xsl:template>
</xsl:stylesheet>
