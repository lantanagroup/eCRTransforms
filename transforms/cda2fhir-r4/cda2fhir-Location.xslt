<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:import href="c-to-fhir-utility.xslt" />

  <xsl:template match="cda:location" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <xsl:template match="cda:location">
      <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
      <xsl:variable name="vCurrentIg">
          <xsl:choose>
              <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
              <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
              <xsl:otherwise>NA</xsl:otherwise>
          </xsl:choose>
      </xsl:variable>
    <Location>
      <!-- SG 20191211: Add meta.profile -->
      <xsl:call-template name="add-participant-meta" />

      <xsl:apply-templates select="cda:healthCareFacility/cda:id" />
      <!-- SG 20191211: The original if statements here could potentially produce 2 names
           (if you had both location/name and serviceProviderOrganization/name
           when the Location resource only allows one name 
           Changing to a choose-->
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
        <xsl:apply-templates select="cda:healthCareFacility/cda:code" >
          <xsl:with-param name="pElementName" select="'type'"/>
        </xsl:apply-templates>
        <!-- If this is eICR let's see if there is another type in the Encounter Activities -->
        <xsl:if test="$vCurrentIg='eICR'">
          <xsl:for-each select="//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:participant[@typeCode='LOC']/cda:participantRole[@classCode='SDLOC']/cda:code">
            <xsl:apply-templates select="." >
              <xsl:with-param name="pElementName" select="'type'"/>
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:if>
      
      <!-- Adding telecom -->
      <xsl:apply-templates select="cda:healthCareFacility/cda:serviceProviderOrganization/cda:telecom" />
      <xsl:apply-templates select="cda:healthCareFacility/cda:location/cda:addr" />
    </Location>
  </xsl:template>

  <!-- SG 20191204: Commenting this out - think this should be creating a location for the authoringDevice as there is an address on it in the CDA -->
  <!--<xsl:template
    match="cda:assignedAuthor[cda:assignedAuthoringDevice][ancestor::cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']]"
    priority="1">
    <!-\- Supressing assignedAuthoringDevice for eICR Location, as it's a Device (not Location) -\->
  </xsl:template>-->

  <xsl:template match="cda:assignedAuthor[cda:assignedAuthoringDevice]">
    <!-- SG 20191204: Need to research further - but I think the below warning is incorrect - this creates a location inside an author for the address -->
    <!-- WARNING: This template needs to be fixed in the future, as it incorrectly turns all assignedAuthor elements with an assignedAuthoringDevice 
      into a Location, which may have been correct for a single CDA template, but not for all -->
    <Location>

      <!-- SG 20191211: Add meta.profile -->
      <xsl:call-template name="add-participant-meta" />

      <xsl:comment>cda:assignedAuthor[cda:assignedAuthoringDevice]</xsl:comment>
      <xsl:if test="cda:representedOrganization/cda:name/text()">
        <name value="{cda:representedOrganization/cda:name}" />
      </xsl:if>
      <xsl:apply-templates select="cda:telecom" />
      <xsl:apply-templates select="cda:addr" />
    </Location>
  </xsl:template>

</xsl:stylesheet>
