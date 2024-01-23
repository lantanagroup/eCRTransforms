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

    <xsl:template match="fhir:Organization" mode="rr">

        <participant typeCode="LOC">
            <xsl:call-template name="get-template-id" />

            <participantRole>
                <xsl:apply-templates select="fhir:identifier" />
                <xsl:apply-templates select="fhir:type">
                    <xsl:with-param name="pElementName" select="'code'" />
                </xsl:apply-templates>
                <xsl:call-template name="get-addr" />
                <xsl:call-template name="get-telecom" />

                <playingEntity>
                    <xsl:call-template name="get-org-name" />
                </playingEntity>
            </participantRole>
        </participant>
    </xsl:template>
    
    <!--<template match="fhir:Device">
        <participant typeCode="DEV">
            <participantRole classCode="MANU">
                <xsl:call-template name="get-template-id">
                    <xsl:with-param name="pElementType" select="'participant'"/>
                </xsl:call-template>
                <!-\- Hard-coding this templateId for now -\->
                <!-\-<xsl:comment select="' [C-CDA R1.1] Product Instance'" />
                <templateId root="2.16.840.1.113883.10.20.22.4.37" />-\->
                <xsl:choose>
                    <!-\- If this is a UDI then the FDA OID 2.16.840.1.113883.3.3719 must be used -\->
                    <xsl:when test="$vDevice/fhir:udiCarrier">
                        <id root="2.16.840.1.113883.3.3719" assigningAuthorityName="FDA" extension="{$vDevice/fhir:udiCarrier/fhir:carrierHRF/@value}" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <!-\-<xsl:apply-templates select="$vDevice/fhir:address" />
                        <xsl:apply-templates select="$vDevice/fhir:telecom" />-\->
                <playingDevice>
                    <xsl:apply-templates select="$vDevice/fhir:type" />
                    <xsl:for-each select="$vDevice/fhir:manufacturer">
                        <manufacturerModelName>
                            <xsl:value-of select="@value" />
                        </manufacturerModelName>
                    </xsl:for-each>
                </playingDevice>
                <scopingEntity>
                    <xsl:choose>
                        <!-\- If this is a UDI then the FDA OID 2.16.840.1.113883.3.3719 must be used here also -\->
                        <xsl:when test="$vDevice/fhir:udiCarrier">
                            <id root="2.16.840.1.113883.3.3719" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                </scopingEntity>
            </participantRole>
        </participant>
    </template>-->
</xsl:stylesheet>
