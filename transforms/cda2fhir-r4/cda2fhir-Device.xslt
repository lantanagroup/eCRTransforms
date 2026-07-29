<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0" xmlns="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="cda:assignedAuthoringDevice" mode="bundle-entry">
    <xsl:comment>INFO: cda:assignedAuthoringDevice</xsl:comment>
    <xsl:call-template name="create-bundle-entry" />
    <xsl:apply-templates select="parent::cda:assignedAuthor" />
  </xsl:template>
  <xsl:template match="cda:participantRole[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.37']" mode="bundle-entry">
    <xsl:comment>INFO: cda:participant/cda:participantRole [C-CDA R1.1] Product Instance</xsl:comment>
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>
  <xsl:template match="cda:assignedAuthoringDevice">
    <!-- 20260729 Claude: removed dead $vCurrentIg variable - both branches returned 'NA' and it was never referenced -->
    <Device>
      <xsl:apply-templates select="../cda:id" />
      <xsl:comment>INFO: cda:assignedAuthoringDevice</xsl:comment>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <xsl:apply-templates mode="device" select="cda:manufacturerModelName" />
      <xsl:apply-templates mode="device" select="cda:softwareName" />
      <xsl:if test="../cda:representedOrganization">
        <owner>
          <reference value="urn:uuid:{../cda:representedOrganization/@lcg:uuid}" />
        </owner>
      </xsl:if>
      <xsl:if test="../cda:representedOrganization/cda:name/text() or ../cda:telecom[not(@nullFlavor = 'NA')] or ../cda:addr[not(@nullFlavor = 'NA')]">
        <location>
          <reference value="urn:uuid:{../@lcg:uuid}" />
        </location>
      </xsl:if>
      <!-- TODO: Handle asMaintainedEntity -->
    </Device>
  </xsl:template>
  <!-- 20260729 Claude: added priority="1" - this template is ambiguous with cda2fhir-PractitionerRole.xslt's generic
       cda:participantRole body template (equal default priority), and include order made PractitionerRole win, so a
       Product Instance produced a PractitionerRole resource (with dangling references) instead of a Device -->
  <xsl:template match="cda:participantRole[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.37']" priority="1">
    <Device>
      <xsl:apply-templates select="cda:id" />
      <xsl:comment>INFO: cda:participant/cda:participantRole [C-CDA R1.1] Product Instance</xsl:comment>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <xsl:apply-templates mode="device" select="cda:playingDevice/cda:manufacturerModelName" />
      <xsl:apply-templates mode="device" select="cda:playingDevice/cda:softwareName" />
      <!--<xsl:if test="../cda:representedOrganization">
                <owner>
                    <reference value="urn:uuid:{../cda:representedOrganization/@lcg:uuid}" />
                </owner>
            </xsl:if>-->
      <!--<location>
                <reference value="urn:uuid:{../@lcg:uuid}" />
            </location>-->
    </Device>
  </xsl:template>
  <!-- 20260427 SG: update for data augmentation -->
  <xsl:template match="cda:manufacturerModelName" mode="device">
    <deviceName>
      <xsl:choose>
        <xsl:when test="text()">
          <name value="{text()}" />
        </xsl:when>
        <xsl:when test="@displayName">
          <name value="{@displayName}" />
        </xsl:when>
      </xsl:choose>
      <type value="model-name" />
    </deviceName>
    <xsl:if test="@displayName">
      <modelNumber value="{@displayName}" />
    </xsl:if>
  </xsl:template>
  <!-- 20260427 SG: update for data augmentation -->
  <xsl:template match="cda:softwareName" mode="device">
    <version>
      <xsl:if test="@code">
        <xsl:apply-templates select=".">
          <xsl:with-param name="pElementName" select="'type'" />
        </xsl:apply-templates>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="text()">
          <value value="{text()}" />
        </xsl:when>
        <xsl:when test="@displayName">
          <value value="{@displayName}" />
        </xsl:when>
      </xsl:choose>
      <!--<xsl:choose>
        <xsl:when test="@displayName">
          <value value="{@displayName}" />
        </xsl:when>
        <xsl:otherwise>
          <value value="NI" />
        </xsl:otherwise>
      </xsl:choose>-->
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
