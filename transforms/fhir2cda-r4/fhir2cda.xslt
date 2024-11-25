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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:sdtc="urn:hl7-org:sdtc" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid sdtc">

    <xsl:include href="fhir2cda-includes.xslt" />

    <xsl:param name="gParamCDAeICRVersion" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />

    <xsl:template match="/">
        <xsl:message>Beginning transform</xsl:message>
        <xsl:choose>
            <xsl:when test="fhir:Bundle[fhir:type[@value = 'document' or @value = 'collection']] or 
                            fhir:Bundle[fhir:type[@value = 'message']]/fhir:entry/fhir:resource/fhir:Bundle[fhir:type[@value = 'document']]">
                <xsl:apply-templates select="fhir:Bundle[fhir:type[@value = 'document' or @value = 'collection']] | fhir:Bundle[fhir:type[@value = 'message']]/fhir:entry/fhir:resource/fhir:Bundle[fhir:type[@value = 'document']]" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">This transform can only be run on a FHIR Bundle resource where type = document or type =
                    collection or type = message with a contained Document Bundle.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="fhir:Bundle[fhir:type[@value = 'document']]">
        <xsl:apply-templates select="fhir:entry[1]/fhir:resource/fhir:*" />
    </xsl:template>

    <xsl:template match="fhir:Bundle[fhir:type[@value = 'collection']]">
        <xsl:apply-templates select="fhir:entry[1]/fhir:resource/fhir:*" />
        <xsl:message>Running collection bundle using root resource <xsl:value-of select="local-name(fhir:entry[1]/fhir:resource/fhir:*)"
             /></xsl:message>
    </xsl:template>
    
    <!--<xsl:template match="fhir:Bundle[fhir:type[@value = 'message']]/fhir:entry/fhir:resource/fhir:Bundle[fhir:type[@value = 'document']]">
        <xsl:apply-templates select="fhir:entry[1]/fhir:resource/fhir:*" />
        <xsl:message>Running message bundle using contained Document Bundle <xsl:value-of select="local-name(fhir:entry[1]/fhir:resource/fhir:*)"
        /></xsl:message>
    </xsl:template>-->

    <xsl:template match="fhir:*" mode="entry" priority="-10">
        <xsl:comment>
      <xsl:text>TODO: unmapped entry </xsl:text>
      <xsl:value-of select="local-name(.)" />
      <xsl:text> </xsl:text>
      <xsl:if test="fhir:meta/fhir:profile/@value">
        <xsl:value-of select="fhir:meta/fhir:profile/@value" />
      </xsl:if>
    </xsl:comment>
    </xsl:template>

    <xsl:template match="fhir:*" mode="entry-relationship" priority="-10">
        <xsl:comment>
      <xsl:text>TODO: unmapped entryRelationship </xsl:text>
      <xsl:value-of select="local-name(.)" />
      <xsl:text> </xsl:text>
      <xsl:if test="fhir:meta/fhir:profile/@value">
        <xsl:value-of select="fhir:meta/fhir:profile/@value" />
      </xsl:if>
    </xsl:comment>
    </xsl:template>

</xsl:stylesheet>
