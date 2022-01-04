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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

  <xsl:import href="fhir2cda-TS.xslt" />
  <xsl:import href="fhir2cda-CD.xslt" />

  <!-- fhir:DocumentReference -> eICR External Document Reference (ExternalDocument) -->
  <xsl:template match="fhir:DocumentReference" mode="reference">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <reference typeCode="REFR">
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>
      <!-- Add choice here for new use cases -->
      <xsl:call-template name="make-external-document-eicr" />
    </reference>

  </xsl:template>

  <!-- fhir:DocumentReference -> eICR External Document Reference (ExternalDocument) -->
  <xsl:template name="make-external-document-eicr">
    <externalDocument classCode="DOCCLIN" moodCode="EVN">
      <xsl:call-template name="get-template-id" />
      <xsl:apply-templates select="fhir:masterIdentifier" />
      <code code="55751-2" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Public Health Case Report (eICR)" />
      <xsl:choose>

        <xsl:when test="fhir:identifier">
        <xsl:apply-templates select="fhir:identifier">
          <xsl:with-param name="pElementName" select="'setId'" />
        </xsl:apply-templates>
        <versionNumber value="{substring-after(fhir:identifier/fhir:value/@value, '#')}" />
        </xsl:when>
        <xsl:otherwise>
          <setId nullFlavor='NI'/>
          <versionNumber nullFlavor='NI'/>
        </xsl:otherwise>
      </xsl:choose>
    </externalDocument>
  </xsl:template>
</xsl:stylesheet>
