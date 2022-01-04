<?xml version="1.0" encoding="UTF-8"?>
<!-- 

Copyright 2020 Lantana Consulting Group

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
  exclude-result-prefixes="lcg xsl cda fhir">

  <xsl:import href="fhir2cda-utility.xslt" />
  <xsl:import href="fhir2cda-TS.xslt" />


    <!-- C-CDA and eCR Information Recipient extensions (Composition)-> get referenced resource entry url and process -->
    <xsl:template match="fhir:extension[@url='http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension'] | fhir:extension[@url='http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension']">
        <xsl:param name="pPosition"/>
        <xsl:for-each select="fhir:valueReference/fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" >
                    <xsl:with-param name="pPosition" select="$pPosition"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Obsolete code from old RR Communication -->
  <!-- fhir:recipient (Communication)-> get referenced resource entry url and process -->
  <!--<xsl:template match="fhir:recipient">
    <xsl:param name="pPosition"/>
    <xsl:for-each select="fhir:reference">
      <xsl:variable name="referenceURI">
        <xsl:call-template name="resolve-to-full-url">
          <xsl:with-param name="referenceURI" select="@value" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
        <xsl:apply-templates select="fhir:resource/fhir:*" >
          <xsl:with-param name="pPosition" select="$pPosition"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>-->

  <xsl:template match="fhir:entry/fhir:resource/fhir:PractitionerRole">
    <xsl:param name="pPosition" />
    <xsl:call-template name="make-information-recipient" >
      <xsl:with-param name="pPosition" select="$pPosition"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="make-information-recipient">
    <xsl:param name="pPosition" select="1"/>
    <!-- Put the Practitioner into a variable -->
    <xsl:variable name="referenceURI">
      <xsl:call-template name="resolve-to-full-url">
        <xsl:with-param name="referenceURI" select="fhir:practitioner/fhir:reference/@value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="vPractitioner" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />

    <!-- Put the organization into a variable -->
    <xsl:variable name="referenceURI">
      <xsl:call-template name="resolve-to-full-url">
        <xsl:with-param name="referenceURI" select="fhir:organization/fhir:reference/@value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="vOrganization" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

    <informationRecipient typeCode="PRCP">
      <xsl:choose>
        <xsl:when test="$pPosition=1">
          <xsl:attribute name="typeCode" select="'PRCP'"></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="typeCode" select="'TRC'"></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <!-- Provider -->
      <intendedRecipient>
        <xsl:call-template name="get-id" />
        <xsl:call-template name="get-addr">
          <xsl:with-param name="pElement" select="$vPractitioner/fhir:address" />
        </xsl:call-template>
        <xsl:call-template name="get-telecom">
          <xsl:with-param name="pElement" select="$vPractitioner/fhir:telecom" />
        </xsl:call-template>
        <informationRecipient>
          <xsl:call-template name="get-person-name">
            <xsl:with-param name="pElement" select="$vPractitioner/fhir:name" />
          </xsl:call-template>
        </informationRecipient>
        <receivedOrganization>
          <xsl:call-template name="get-id">
            <xsl:with-param name="pElement" select="$vOrganization/fhir:identifier" />
          </xsl:call-template>
          <xsl:call-template name="get-org-name">
            <xsl:with-param name="pElement" select="$vOrganization/fhir:name" />
          </xsl:call-template>
          <xsl:call-template name="get-telecom">
            <xsl:with-param name="pElement" select="$vOrganization/fhir:telecom" />
          </xsl:call-template>
          <xsl:call-template name="get-addr">
            <xsl:with-param name="pElement" select="$vOrganization/fhir:address" />
          </xsl:call-template>
        </receivedOrganization>
      </intendedRecipient>
    </informationRecipient>
  </xsl:template>
</xsl:stylesheet>
