<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:template match="cda:location" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20260729 Claude: added priority="1" to the Location participant templates (here and the body template below) so
       they beat cda2fhir-PractitionerRole.xslt's generic cda:participant[cda:participantRole] match (equal default
       priority; include order previously decided the winner) -->
  <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.4']]" mode="bundle-entry" priority="1">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20260729 Claude: Fix - matched cda:participant[cda:templateId 4.32], but the Service Delivery Location templateId
       is on the participantRole (the body template below already uses the participantRole axis, as does
       cda2fhir-Procedure.xslt), so this bundle-entry never fired and the Location entry referenced from
       Procedure.location was never created -->
  <xsl:template match="cda:participant[cda:participantRole/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.32']]" mode="bundle-entry" priority="1">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>


  <xsl:template match="cda:location">

    <Location>
      <xsl:call-template name="add-participant-meta" />

      <xsl:apply-templates select="cda:healthCareFacility/cda:id" />
      <xsl:choose>
        <xsl:when test="cda:healthCareFacility/cda:location/cda:name/text()">
          <name value="{cda:healthCareFacility/cda:location/cda:name}" />
        </xsl:when>
        <xsl:when test="cda:healthCareFacility/cda:serviceProviderOrganization/cda:name/text()">
          <name value="{cda:healthCareFacility/cda:serviceProviderOrganization/cda:name}" />
        </xsl:when>
      </xsl:choose>

      <!-- Adding type -->
      <!-- Added parameter elementName -->
      <xsl:apply-templates select="cda:healthCareFacility/cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <!-- If this is eICR let's see if there is another type in the Encounter Activities -->
      <xsl:if test="$gvCurrentIg = 'eICR'">
        <xsl:for-each select="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:participant[@typeCode = 'LOC']/cda:participantRole[@classCode = 'SDLOC']/cda:code">
          <xsl:apply-templates select=".">
            <xsl:with-param name="pElementName" select="'type'" />
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:if>

      <!-- Adding telecom -->
      <xsl:apply-templates select="cda:healthCareFacility/cda:serviceProviderOrganization/cda:telecom" />

      <xsl:variable name="vLocationAddr" select="cda:healthCareFacility/cda:location/cda:addr" />

      <!-- SG 2023-06-05 If there is no non-null address in location, check in serviceProviderOrganization -->
      <xsl:choose>
        <xsl:when test="$vLocationAddr/cda:postalCode[not(@nullFlavor)] or $vLocationAddr/cda:streetAddressLine[not(@nullFlavor)]">
          <xsl:apply-templates select="cda:healthCareFacility/cda:location/cda:addr" />
        </xsl:when>
        <xsl:when test="cda:healthCareFacility/cda:serviceProviderOrganization/cda:addr">
          <xsl:apply-templates select="cda:healthCareFacility/cda:serviceProviderOrganization/cda:addr" />
        </xsl:when>
      </xsl:choose>
    </Location>
  </xsl:template>

  <xsl:template match="cda:assignedAuthor[cda:assignedAuthoringDevice]">
    <!-- 20260423 SG: Unless there is data, do not create a location -->
    <xsl:if test="cda:representedOrganization/cda:name/text() or cda:telecom[not(@nullFlavor='NA')] or cda:addr[not(@nullFlavor='NA')]">
      <entry>
        <fullUrl value="urn:uuid:{@lcg:uuid}" />
        <resource>
          <Location>
            <xsl:call-template name="add-participant-meta" />
            <xsl:if test="cda:representedOrganization/cda:name/text()">
              <name value="{cda:representedOrganization/cda:name}" />
            </xsl:if>
            <xsl:apply-templates select="cda:telecom" />
            <xsl:apply-templates select="cda:addr" />
          </Location>
        </resource>
      </entry>
    </xsl:if>
  </xsl:template>

  <!-- (eICR) Location Participant to US Core Location -->
  <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.4']] | cda:participant[cda:participantRole/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.32']]" priority="1">
    <Location>
      <xsl:call-template name="add-meta" />
      <!-- 20260729 Claude: Fix - added participantRole/playingEntity/name (the actual location name in a Service
           Delivery Location) ahead of the preceding-sibling value fallbacks; previously procedure SDL participants
           always fell through to the hard-coded 'Unknown' -->
      <name>
        <xsl:choose>
          <xsl:when test="cda:participantRole/cda:playingEntity/cda:name/text()">
            <xsl:attribute name="value" select="cda:participantRole/cda:playingEntity/cda:name[1]" />
          </xsl:when>
          <xsl:when test="preceding-sibling::cda:value/cda:originalText">
            <xsl:attribute name="value" select="preceding-sibling::cda:value/cda:originalText" />
          </xsl:when>
          <xsl:when test="preceding-sibling::cda:value/@displayName">
            <xsl:attribute name="value" select="preceding-sibling::cda:value/@displayName" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="value" select="'Unknown'" />
          </xsl:otherwise>
        </xsl:choose>
      </name>
      <xsl:apply-templates select="cda:participantRole/cda:telecom" />
      <xsl:apply-templates select="cda:participantRole/cda:addr" />
    </Location>
  </xsl:template>
</xsl:stylesheet>
