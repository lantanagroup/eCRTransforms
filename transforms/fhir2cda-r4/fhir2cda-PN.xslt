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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:xslt="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

    <!-- (Generic) Name -->
    <xsl:template match="fhir:name">
        <xsl:param name="elementName" select="'name'" />
        <xsl:element name="{$elementName}">
            <xsl:choose>
                <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="fhir:use">
                        <xsl:attribute name="use">
                            <xsl:choose>
                                <xsl:when test="fhir:use/@value = 'usual'">L</xsl:when>
                                <xsl:when test="fhir:use/@value = 'official'">L</xsl:when>
                                <xsl:when test="fhir:use/@value = 'nickname'">P</xsl:when>
                                <!-- Not sure of the exact condition of when to use this label -->
                                <xsl:when test="fhir:use/@value = 'maiden'">BR</xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                    </xsl:if>
                    <!-- Setting order for consistency and easier testing/compares -->
                    <xsl:apply-templates select="fhir:prefix" mode="name" />
                    <xsl:apply-templates select="fhir:given" mode="name" />
                    <xsl:apply-templates select="fhir:family" mode="name" />
                    <xsl:apply-templates select="fhir:suffix" mode="name" />
                    <xsl:apply-templates select="fhir:period">
                        <xsl:with-param name="pElementName" select="'validTime'"/>
                        <xsl:with-param name="pXSIType" select="'IVL_TS'"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:*" mode="name">
        <xsl:param name="pElementName">
            <xsl:value-of select="local-name(.)" />
        </xsl:param>
        <xsl:element name="{$pElementName}">
            <xsl:value-of select="@value" />
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
