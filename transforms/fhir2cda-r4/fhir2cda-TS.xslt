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
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sdtc="urn:hl7-org:sdtc" version="2.0" exclude-result-prefixes="lcg xsl cda fhir sdtc">

    <xsl:template match="fhir:valueDate">
        <xsl:param name="pElementName">effectiveTime</xsl:param>
        <xsl:param name="pXSIType" />
        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="@value" />
                    <xsl:with-param name="includeTime" select="false()" />
                </xsl:call-template>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    
    <!--<xsl:template match="fhir:collectedDateTime">
        <xsl:param name="pElementName">effectiveTime</xsl:param>
        <xsl:param name="pXSIType" />
        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="@value" />
                    <xsl:with-param name="includeTime" select="false()" />
                </xsl:call-template>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>-->

    <xsl:template
        match="fhir:collectedDateTime | fhir:effectiveDateTime | fhir:effectiveInstant | fhir:dateAsserted | fhir:valueDateTime | fhir:occurrenceDateTime | fhir:birthDate | fhir:deceasedDateTime | fhir:date | fhir:authored | fhir:sent | fhir:timestamp | fhir:time | fhir:authoredOn | fhir:performedDateTime | fhir:issued">
        <!-- CDA element effectiveTime unless specified something else -->
        <xsl:param name="pElementName" select="'effectiveTime'" />
        <!-- This might be cast to a specific xsi-type in the cda -->
        <xsl:param name="pXSIType" />
        <xsl:param name="pOperator" />

        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:if test="$pOperator">
                <xsl:attribute name="operator" select="$pOperator" />
            </xsl:if>
            <xsl:choose>
                <xsl:when test="fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                    <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value">
                        <xsl:call-template name="Date2TS">
                            <xsl:with-param name="date" select="@value" />
                            <xsl:with-param name="includeTime" select="true()" />
                        </xsl:call-template>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template name="Date2TS">
        <xsl:param name="date" />
        <xsl:param name="includeTime" select="true()" />

        <xsl:variable name="date-part">
            <xsl:choose>
                <xsl:when test="contains($date, 'T')">
                    <xsl:value-of select="substring-before($date, 'T')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$date" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="time-and-offset-part" select="substring-after($date, 'T')" />
        <xsl:variable name="time-part">
            <xsl:choose>
                <xsl:when test="contains($time-and-offset-part, '-')">
                    <xsl:value-of select="substring-before($time-and-offset-part, '-')" />
                </xsl:when>
                <xsl:when test="contains($time-and-offset-part, '+')">
                    <xsl:value-of select="substring-before($time-and-offset-part, '+')" />
                </xsl:when>
                <xsl:when test="contains($time-and-offset-part, 'Z')">
                    <xsl:value-of select="substring-before($time-and-offset-part, 'Z')" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="offset-part">
            <xsl:if test="contains($time-and-offset-part, '-')">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="substring-after($time-and-offset-part, '-')" />
            </xsl:if>
            <xsl:if test="contains($time-and-offset-part, '+')">
                <xsl:text>+</xsl:text>
                <xsl:value-of select="substring-after($time-and-offset-part, '+')" />
            </xsl:if>
            <xsl:if test="contains($time-and-offset-part, 'Z')">+0000</xsl:if>
        </xsl:variable>
        <xsl:if test="$date-part">
            <xsl:value-of select="translate($date-part, '-', '')" />
        </xsl:if>
        <xsl:if test="$time-part and $includeTime">
            <xsl:value-of select="translate($time-part, ':', '')" />
        </xsl:if>
        <xsl:if test="$offset-part">
            <xsl:value-of select="translate($offset-part, ':', '')" />
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
