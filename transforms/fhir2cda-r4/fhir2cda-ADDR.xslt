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

  <!-- (Generic) Addr -->
  <xsl:template match="fhir:address | fhir:valueAddress">
    <xsl:param name="elementName" select="'addr'" />
    <xsl:element name="{$elementName}">
      <xsl:choose>
        <xsl:when test="fhir:use">
          <xsl:attribute name="use">
            <xsl:choose>
              <xsl:when test="fhir:use/@value = 'home'">H</xsl:when>
              <xsl:when test="fhir:use/@value = 'work'">WP</xsl:when>
              <xsl:when test="fhir:use/@value = 'mobile'">MC</xsl:when>
              <xsl:when test="fhir:use/@value = 'temp'">TMP</xsl:when>
              <!-- default to work -->
              <xsl:otherwise>WP</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="use">
            <xsl:value-of select="'WP'"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <!-- Setting order for consistency and easier testing/compares -->
      <xsl:apply-templates select="fhir:line" mode="address">
        <xsl:with-param name="pElementName" select="'streetAddressLine'" />
      </xsl:apply-templates>
      <xsl:apply-templates select="fhir:city" mode="address" />
      <xsl:apply-templates select="fhir:district" mode="address">
        <xsl:with-param name="pElementName" select="'county'" />
      </xsl:apply-templates>
      <xsl:apply-templates select="fhir:state" mode="address" />
      <xsl:apply-templates select="fhir:postalCode" mode="address" />
      <xsl:apply-templates select="fhir:country" mode="address" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="fhir:*" mode="address">
    <xsl:param name="pElementName">
      <xsl:value-of select="local-name(.)" />
    </xsl:param>
    <xsl:element name="{$pElementName}">
      <xsl:value-of select="@value" />
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
