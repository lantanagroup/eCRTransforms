<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:import href="c-to-fhir-utility.xslt" />

  <xsl:template match="cda:informationRecipient[cda:intendedRecipient] | cda:author | cda:legalAuthenticator | cda:authenticator | cda:performer | cda:participant" mode="bundle-entry">
    <xsl:apply-templates select="cda:intendedRecipient | cda:assignedAuthor | cda:assignedEntity | cda:participantRole" mode="bundle-entry" />
  </xsl:template>

  <!-- Super confusing because the structure is informationRecipient/intendedRecipient/informationRecipient (yes, double...) -->
  <xsl:template match="cda:intendedRecipient | cda:assignedAuthor | cda:assignedEntity | cda:participantRole" mode="bundle-entry">
    <!-- Need to create up to 3 resources, PractitionerRole, Practitioner, and optionally Organization -->
    <!-- PractitionerRole? -->
    <xsl:call-template name="create-bundle-entry" />
    <!-- Practitioner -->
    <xsl:for-each select="cda:informationRecipient[parent::cda:intendedRecipient] | cda:assignedPerson | cda:associatedPerson">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
    <!-- Organization -->
    <xsl:for-each select="cda:receivedOrganization | cda:representedOrganization | cda:scopingOrganization">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
    <xsl:apply-templates select="cda:assignedAuthoringDevice" mode="bundle-entry"/>
    <!--
    <xsl:for-each select="cda:assignedAuthoringDevice">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
    -->
  </xsl:template>

  <!-- participantRole of locations are being matched here to PractitionerRole, need to omit -->
  <xsl:template match="cda:intendedRecipient | cda:assignedAuthor[not(cda:assignedAuthoringDevice)] | cda:assignedEntity | cda:participantRole[not(@classCode = 'TERR')]">
    <PractitionerRole>

      <!-- SG 20191204: Add meta.profile -->
      <!-- <xsl:call-template name="add-participant-meta" /> -->
      
      <!-- Check current Ig -->
      <xsl:variable name="vCurrentIg">
        <xsl:apply-templates select="/" mode="currentIg"/>
      </xsl:variable>
      
      <!-- Set profiles based on Ig and Resource if it is needed -->
      <xsl:choose>
        <xsl:when test="$vCurrentIg='NA'">
          <xsl:call-template name="add-meta"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="vProfileValue">
            <xsl:call-template name="get-profile-for-ig">
              <xsl:with-param name="pIg" select="$vCurrentIg"/>
              <xsl:with-param name="pResource" select="'PractitionerRole'"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$vProfileValue ne 'NA'">
              <meta>
                <profile>
                  <xsl:attribute name="value">
                    <xsl:value-of select="$vProfileValue"/>
                  </xsl:attribute>
                </profile>
              </meta>
            </xsl:when>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="breadcrumb-comment" />
      
      <xsl:apply-templates select="cda:id" />
      <xsl:for-each select="cda:informationRecipient[parent::cda:intendedRecipient] | cda:assignedPerson | cda:associatedPerson">
        <practitioner>
          <xsl:apply-templates select="." mode="reference" />
        </practitioner>
      </xsl:for-each>
      <xsl:for-each select="cda:receivedOrganization | cda:representedOrganization | cda:scopingOrganization">
        <organization>
          <xsl:apply-templates select="." mode="reference" />
        </organization>
      </xsl:for-each>
      <xsl:if test="@classCode">
        <code>
          <coding>
            <system value="http://hl7.org/fhir/v3/RoleClass" />
            <code value="{@classCode}" />
          </coding>
        </code>
      </xsl:if>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName">code</xsl:with-param>
      </xsl:apply-templates>
      <xsl:apply-templates select="cda:telecom" />
    </PractitionerRole>
  </xsl:template>

  <xsl:template match="cda:informationRecipient[parent::cda:intendedRecipient] | cda:assignedPerson | cda:associatedPerson">
    <xsl:call-template name="make-practitioner">
      <xsl:with-param name="id" select="../cda:id" />
      <xsl:with-param name="name" select="cda:name" />
      <xsl:with-param name="telecom" select="../cda:telecom" />
      <xsl:with-param name="address" select="../cda:addr" />
    </xsl:call-template>
  </xsl:template>


  <xsl:template name="make-practitioner">
    <xsl:param name="id" />
    <xsl:param name="name" />
    <xsl:param name="telecom" />
    <xsl:param name="address" />
    <Practitioner>
      <xsl:call-template name="breadcrumb-comment" />
      <meta>
        <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner" />
      </meta>
      <text>
        <status value="generated" />
        <div xmlns="http://www.w3.org/1999/xhtml">
          <xsl:for-each select="$name">
            <xsl:choose>
              <xsl:when test="cda:family">
                <p>
                  <xsl:text>Name: </xsl:text>
                  <xsl:value-of select="cda:family" />
                  <xsl:text>, </xsl:text>
                  <xsl:value-of select="cda:given" />
                </p>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>
          <p>---TODO: ID info---</p>
          <p>Telephone: <xsl:value-of select="$telecom/@value" /></p>
        </div>
      </text>
      <xsl:apply-templates select="$id" />
      <xsl:apply-templates select="$name" />
      <xsl:apply-templates select="$telecom" />
      <xsl:apply-templates select="$address" />
      <!-- Qualification -->
      <xsl:choose>
        <xsl:when test="cda:participantRole">
          <xsl:apply-templates select="cda:participantRole/cda:code" mode="practitioner" />
        </xsl:when>
        <xsl:when test="cda:assignedAuthor">
          <xsl:apply-templates select="cda:assignedAuthor/cda:code" mode="practitioner" />
        </xsl:when>
      </xsl:choose>
    </Practitioner>
  </xsl:template>

  <xsl:template match="cda:code" mode="practitioner">
    <qualification>
      <xsl:call-template name="newCreateCodableConcept">
        <xsl:with-param name="pElementName">code</xsl:with-param>
      </xsl:call-template>
    </qualification>
  </xsl:template>
</xsl:stylesheet>
