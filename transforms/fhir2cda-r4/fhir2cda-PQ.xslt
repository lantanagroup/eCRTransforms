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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:lcg="http://www.lantanagroup.com"
   xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

  <xsl:template match="fhir:quantity | fhir:dose | fhir:valueQuantity | fhir:doseQuantity | fhir:low | fhir:high | fhir:timingDuration">
    <xsl:param name="pElementName">value</xsl:param>
    <xsl:param name="pIncludeDatatype" select="true()"/>
    <xsl:element name="{$pElementName}">
      <xsl:if test="$pIncludeDatatype=true()">
        <!-- PQ means physical quantity valid attribute for PQ are value and unit -->
        <xsl:attribute name="xsi:type">PQ</xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="fhir:value">
          <xsl:attribute name="value" select="fhir:value/@value" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="nullFlavor">NI</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="fhir:unit">
          <xsl:attribute name="unit" select="fhir:unit/@value" />
        </xsl:when>
        <xsl:when test="fhir:system/@value ='http://unitsofmeasure.org'">
          <xsl:attribute name="unit" select="fhir:code/@value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="unit" select="'no_unit'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
