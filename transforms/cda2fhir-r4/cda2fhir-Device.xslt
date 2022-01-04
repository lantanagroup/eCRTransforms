<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:import href="c-to-fhir-utility.xslt" />

  <xsl:template match="cda:assignedAuthoringDevice">
      <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
      <xsl:variable name="vCurrentIg">
          <xsl:choose>
              <!--<xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
              <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>-->
              <xsl:when test="cda:assignedAuthoringDevice">NA</xsl:when>
              <xsl:otherwise>NA</xsl:otherwise>
          </xsl:choose>
      </xsl:variable>
    <Device>
      <xsl:apply-templates select="../cda:id" />
      <xsl:comment>cda:assignedAuthoringDevice</xsl:comment>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <xsl:apply-templates select="cda:manufacturerModelName" mode="device" />
      <xsl:apply-templates select="cda:softwareName" mode="device" />
      <xsl:if test="$vCurrentIg='RR'">
        <owner>
          <reference value="urn:uuid:{//cda:representedCustodianOrganization/@lcg:uuid}" />
        </owner>
      </xsl:if>
      <location>
        <reference value="urn:uuid:{../@lcg:uuid}" />
      </location>
      <!-- TODO: Handle asMaintainedEntity -->
    </Device>
  </xsl:template>

  <xsl:template match="cda:manufacturerModelName" mode="device">

    <xsl:if test="@displayName">
      <modelNumber value="{@displayName}" />
    </xsl:if>

  </xsl:template>
  <!-- SG 20191204 - uncommented this and updated to use @displayName - not sure why it was commented out? -->
  <xsl:template match="cda:softwareName" mode="device">
    <version>
      <!-- MD: if @displayName not present set NI -->
      <xsl:choose>
        <xsl:when test="@dispLayName">
          <value value="{@displayName}" />
        </xsl:when>
        <xsl:otherwise>
          <value value="NI" />
        </xsl:otherwise>
      </xsl:choose>
      
    </version>
  </xsl:template>

  <xsl:template match="cda:assignedAuthor[cda:assignedAuthoringDevice]" mode="reference">
    <xsl:param name="wrapping-elements" />
    <xsl:param name="pElementName">reference</xsl:param>
    <xsl:if test="not(@nullFlavor)">
      <xsl:variable name="this" select="." />
      <xsl:variable name="templateId" select="cda:templateId[1]/@root" />
      <xsl:if test="$templateId">
        <xsl:comment>
          <xsl:value-of select="$templateId" />
        </xsl:comment>
      </xsl:if>
      <!-- Reference the UUID of the device, not the location -->
      <xsl:element name="{$pElementName}">
        <xsl:attribute name="value">urn:uuid:<xsl:value-of select="cda:assignedAuthoringDevice/@lcg:uuid" /></xsl:attribute>
      </xsl:element>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
