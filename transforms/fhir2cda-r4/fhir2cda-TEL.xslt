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

    <xsl:template match="fhir:telecom | fhir:contact">
        <xsl:param name="elementName" select="'telecom'" />
        <xsl:variable name="uri-prefix">
            <xsl:choose>
                <xsl:when test="fhir:system/@value = 'phone'">tel:</xsl:when>
                <xsl:when test="fhir:system/@value = 'email'">mailto:</xsl:when>
                <xsl:when test="fhir:system/@value = 'fax'">fax:</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$elementName}">
            <xsl:choose>
                <xsl:when
                    test="fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason' or fhir:value/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                    <xsl:choose>
                        <xsl:when test="fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                        <xsl:when test="fhir:value/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                            <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$uri-prefix" />
                        <xsl:value-of select="fhir:value/@value" />
                    </xsl:attribute>
                    <xsl:call-template name="telecomUse" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="fhir:period">
                <xsl:with-param name="pElementName" select="'useablePeriod'"/>
                <xsl:with-param name="pXSIType" select="'IVL_TS'"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <xsl:template name="telecomUse">
        <xsl:param name="use" />
        <xsl:if test="fhir:use">
            <xsl:attribute name="use">
                <xsl:choose>
                    <xsl:when test="fhir:use/@value = 'home'">HP</xsl:when>
                    <xsl:when test="fhir:use/@value = 'work'">WP</xsl:when>
                    <xsl:when test="fhir:use/@value = 'mobile'">MC</xsl:when>
                    <!-- default to work -->
                    <xsl:otherwise>WP</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
