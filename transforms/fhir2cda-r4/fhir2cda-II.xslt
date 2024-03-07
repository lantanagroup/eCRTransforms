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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:uuid="http://www.uuid.org" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!--
  <xsl:import href="fhir2cda-utility.xslt" />
  -->
    <xsl:import href="native-xslt-uuid.xslt" />

    <xsl:template match="fhir:identifier | fhir:masterIdentifier">
        <xsl:param name="pElementName" select="'id'" />
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->

        <!-- MD: Begin uncomment identification of IG -->
        <xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig" />
        </xsl:variable>
        <!-- MD: end uncomment identification of IG -->

        <!-- SG 20240306: Updating for case where there is no system - using guidance here: https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html -->
        <xsl:variable name="vConvertedSystem">
            <xsl:choose>
                <xsl:when test="fhir:system/@value">
                    <xsl:call-template name="convertURI">
                        <xsl:with-param name="uri" select="fhir:system/@value" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="resolve-to-full-url"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:variable>

        <xsl:variable name="vValue">
            <xsl:choose>
                <!--<xsl:when test="$vCurrentIg = 'RR' and contains(fhir:value/@value, '#')">-->
                <xsl:when test="contains(fhir:value/@value, '#')">
                    <xsl:value-of select="substring-before(fhir:value/@value, '#')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="fhir:value/@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:comment>Converting identifier <xsl:value-of select="fhir:system/@value" /></xsl:comment>
        
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="fhir:system/@value = 'urn:ietf:rfc:3986'">
                    <xsl:choose>
                        <xsl:when test="starts-with($vValue, 'urn:oid:')">
                            <xsl:attribute name="root" select="substring-after($vValue, 'urn:oid:')" />
                        </xsl:when>
                        <xsl:when test="starts-with($vValue, 'urn:uuid:')">
                            <!-- MD: Begin -->
                            <xsl:choose>
                                <xsl:when test="$vCurrentIg = 'eICR'">
                                    <xsl:attribute name="root">2.16.840.1.113883.9.9.9.9.9</xsl:attribute>
                                    <xsl:attribute name="extension" select="substring-after($vValue, 'urn:uuid:')" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="root" select="substring-after($vValue, 'urn:uuid:')" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- MD: end -->

                        </xsl:when>
                        <xsl:when test="starts-with($vValue, 'urn:hl7ii:')">
                            <xsl:variable name="val">
                                <xsl:value-of select="substring-after($vValue, 'urn:hl7ii:')" />
                            </xsl:variable>
                            <xsl:choose>
                                <xsl:when test="contains($val, ':')">
                                    <xsl:attribute name="root" select="substring-before($val, ':')" />
                                    <xsl:attribute name="extension" select="substring-after($val, ':')" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="root" select="$val" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>TODO: System is urn:ietf:rfc:3986 but did not start with urn:oid or urn:uuid. Need to handle other URI types.</xsl:message>
                            <xsl:attribute name="root" select="$vValue" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <!-- SG 20240306: Add check to make sure OID is valid -->
                <xsl:when test="starts-with(fhir:system/@value, 'urn:oid:') and matches(fhir:system/@value, 'urn:oid:[0-2](.[1-9]\d*)+')">
                    <xsl:attribute name="root" select="substring-after(fhir:system/@value, 'urn:oid:')" />
                    <xsl:attribute name="extension" select="$vValue" />
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:oid:') and not(matches(fhir:system/@value, 'urn:oid:[0-2](.[1-9]\d*)+'))">
                    <xsl:attribute name="root" select="'2.16.840.1.113883.4.873'" />
                    <xsl:attribute name="extension" select="$vValue" />
                    <xsl:attribute name="extension" select="concat('urn:',substring-after(fhir:system/@value, 'urn:oid:'), ':', $vValue)" />
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:uuid:')">
                    <xsl:attribute name="root" select="substring-after(fhir:system/@value, 'urn:uuid:')" />
                    <xsl:attribute name="extension" select="$vValue" />
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:hl7ii:')">
                    <xsl:variable name="val">
                        <xsl:value-of select="substring-after(fhir:system/@value, 'urn:hl7ii:')" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($val, ':')">
                            <xsl:attribute name="root" select="substring-before($val, ':')" />
                            <xsl:attribute name="extension" select="substring-after($val, ':')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="root" select="$val" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- <id root="{lower-case(uuid:get-uuid())}" /> -->
                <!-- SG 2023-11-15: Updating the below based on the rules here: 
                    https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html (see: FHIR identifier ↔ CDA id with Example Mapping table) -->
                <xsl:when test="$vConvertedSystem">
                    <xsl:choose>
                        <xsl:when test="starts-with($vConvertedSystem, 'http')">
                            <!-- Did not find an entry in the oid uri mapping file, so use 2.16.840.1.113883.4.873 (OID for urn:ietf:rfc:3986) for root
                                 and concatenate system and extension for extension-->
                            <xsl:attribute name="root" select="'2.16.840.1.113883.4.873'" />
                            <xsl:attribute name="extension" select="concat($vConvertedSystem, '/', $vValue)" />
                            <!--<!-\- Did not find an entry in the oid uri mapping file, so use a UUID for the root and store the URI in assigning authority -\->
                            <xsl:attribute name="root" select="lower-case(uuid:get-uuid())" />
                            <xsl:attribute name="assigningAuthorityName" select="$vConvertedSystem" />-->
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="root" select="$vConvertedSystem" />
                            <xsl:attribute name="extension" select="$vValue" />
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                    <xsl:if test="$vValue">
                        <xsl:attribute name="extension" select="$vValue" />
                    </xsl:if>
                    <xsl:if test="fhir:system">
                        <xsl:attribute name="assigningAuthorityName" select="fhir:system/@value" />
                    </xsl:if>
                    <xsl:comment>TODO: map other known URIs to OIDs</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:valueUri" mode="make-ii">
        <xsl:variable name="system" select="substring-before(substring-after(@value, 'hl7ii:'), ':')" />
        <xsl:variable name="value" select="substring-after(substring-after(@value, 'hl7ii:'), ':')" />
        <xsl:choose>
            <xsl:when test="$system and $value">
                <id extension="{$value}" root="{$system}" />
            </xsl:when>
            <xsl:otherwise>
                <id nullFlavor="NI">
                    <xsl:comment>valueUri/@value was <xsl:value-of select="@value" /></xsl:comment>
                </id>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhir:valueUri">
        <xsl:variable as="node()*" name="vIdentifier">
            <fhir:identifier>
                <fhir:system>
                    <xsl:attribute name="value" select="@value" />
                </fhir:system>
            </fhir:identifier>
        </xsl:variable>
        <xsl:call-template name="get-id">
            <xsl:with-param name="pElement" select="$vIdentifier" />
        </xsl:call-template>
    </xsl:template>
    
</xsl:stylesheet>
