<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:import href="c-to-fhir-utility.xslt" />

  <xsl:template match="cda:custodian" mode="bundle-entry">
    <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
      <xsl:apply-templates select="." mode="bundle-entry" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="cda:representedCustodianOrganization | cda:representedOrganization | cda:receivedOrganization | cda:serviceProviderOrganization | cda:participant[@typeCode = 'LOC']" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>
  
  <!-- Participant inside an [ODH R1] Past or Present Occupation Observation  -->
  <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']/cda:participant[@typeCode='IND']" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <xsl:template match="cda:custodian" mode="reference">
    <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
      <xsl:apply-templates select="." mode="reference" />
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="cda:custodian">
    <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
      <xsl:apply-templates select="." />
      <!--
            <xsl:call-template name="create-organization"/>
            -->
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="cda:representedCustodianOrganization | cda:representedOrganization | cda:scopingOrganization | cda:receivedOrganization | cda:serviceProviderOrganization">
    <xsl:call-template name="create-organization" />
  </xsl:template>

  <!-- Organization from participant of type LOC -->
  <xsl:template
    match="cda:participant[@typeCode = 'LOC'][cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.1' or cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.2' or cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.3']">
    <Organization>

      <xsl:choose>
        <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.1'">
          <meta>
            <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-routing-entity-organization" />
          </meta>
        </xsl:when>
        <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.2'">
          <meta>
            <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-responsible-agency-organization" />
          </meta>
        </xsl:when>
        <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.3'">
          <meta>
            <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-rules-authoring-agency-organization" />
          </meta>
        </xsl:when>
        <xsl:otherwise>
          <!-- SG 20191211: Add meta.profile -->
          <xsl:call-template name="add-participant-meta" />
        </xsl:otherwise>

      </xsl:choose>
      <xsl:comment>participant[LOC]</xsl:comment>
      <xsl:choose>
        <xsl:when test="cda:participantRole/cda:id">
          <xsl:apply-templates select="cda:participantRole/cda:id" />
        </xsl:when>
        <xsl:otherwise>
          <identifier>
            <system value="urn:ietf:rfc:3986" />
            <value value="urn:uuid:{@lcg:uuid}" />
          </identifier>
        </xsl:otherwise>
      </xsl:choose>
      <active value="true" />

      <!-- Adding type -->
      <xsl:apply-templates select="cda:participantRole/cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>


      <xsl:if test="cda:participantRole/cda:playingEntity/cda:name/text()">
        <name value="{cda:participantRole/cda:playingEntity/cda:name}" />
      </xsl:if>
      <xsl:apply-templates select="cda:participantRole/cda:telecom" />
      <xsl:apply-templates select="cda:participantRole/cda:addr" />
    </Organization>
  </xsl:template>
  
    <!-- Organization from Participant inside an [ODH R1] Past or Present Occupation Observation  -->
  <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']/cda:participant[@typeCode='IND']">
    <Organization>
      <xsl:choose>
        <xsl:when test="cda:participantRole/cda:id">
          <xsl:apply-templates select="cda:participantRole/cda:id" />
        </xsl:when>
        <xsl:otherwise>
          <identifier>
            <system value="urn:ietf:rfc:3986" />
            <value value="urn:uuid:{@lcg:uuid}" />
          </identifier>
        </xsl:otherwise>
      </xsl:choose>
      <active value="true" />
      
      <!-- Adding type -->
      <xsl:apply-templates select="cda:participantRole/cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      
      
      <xsl:if test="cda:participantRole/cda:playingEntity/cda:name/text()">
        <name value="{cda:participantRole/cda:playingEntity/cda:name}" />
      </xsl:if>
      <xsl:apply-templates select="cda:participantRole/cda:telecom" />
      <xsl:apply-templates select="cda:participantRole/cda:addr" />
    </Organization>
  </xsl:template>

  <!-- standard Organization from representedCustodianOrganization, representedOrganization, etc -->
  <xsl:template name="create-organization">
    <Organization>

      <!-- SG 20191204: Add meta.profile -->
      <xsl:call-template name="add-participant-meta" />

      <xsl:choose>
        <xsl:when test="cda:id">
          <xsl:apply-templates select="cda:id" />
        </xsl:when>
        <xsl:otherwise>
          <identifier>
            <system value="urn:ietf:rfc:3986" />
            <value value="urn:uuid:{@lcg:uuid}" />
          </identifier>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName">type</xsl:with-param>
      </xsl:apply-templates>
      <active value="true" />
      <xsl:for-each select="cda:standardIndustryClassCode">
        <xsl:call-template name="newCreateCodableConcept">
          <xsl:with-param name="pElementName">type</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:if test="cda:name/text()">
        <name>
          <xsl:attribute name="value">
            <xsl:value-of select="cda:name" />
          </xsl:attribute>
        </name>
      </xsl:if>
      <!-- SG: US Core Organization needs a telecom so if this is a organization that
            doesn't have a telecom, check to see if it's containing role has telecom(s) that
            we can use -->
      <xsl:choose>
        <!-- If the organization has a telecom, use it -->
        <xsl:when test="cda:telecom">
          <xsl:apply-templates select="cda:telecom" />
        </xsl:when>
        <!-- If the parent role has a telcom, use that -->
        <xsl:when test="parent::*/cda:telecom">
          <xsl:apply-templates select="parent::*/cda:telecom" />
        </xsl:when>
      </xsl:choose>
      <!-- SG: US Core Organization needs an address so if this is a organization that
            doesn't have a address, check to see if it's containing role has an address(s) that
            we can use -->
      <xsl:choose>
        <!-- If the organization has an address, use it -->
        <xsl:when test="cda:addr">
          <xsl:apply-templates select="cda:addr" />
        </xsl:when>
        <!-- else if the parent role has an address, use that -->
        <xsl:when test="parent::*/cda:addr">
          <xsl:apply-templates select="parent::*/cda:addr" />
        </xsl:when>
      </xsl:choose>
    </Organization>
  </xsl:template>
</xsl:stylesheet>
