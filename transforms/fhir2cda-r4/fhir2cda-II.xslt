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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:uuid="http://www.uuid.org" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

    <!--
  <xsl:import href="fhir2cda-utility.xslt" />
  -->
    <xsl:import href="native-xslt-uuid.xslt" />

    <xsl:template match="fhir:identifier | fhir:masterIdentifier">
        <xsl:param name="pElementName" select="'id'" />
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        
        <!-- MD: Begin uncomment identification of IG -->
       <xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig"/>
        </xsl:variable>
        <!-- MD: end uncomment identification of IG -->
        
        <xsl:variable name="vConvertedSystem">
            <xsl:call-template name="convertURI">
                <xsl:with-param name="uri" select="fhir:system/@value" />
            </xsl:call-template>
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
        
        <!-- MD: begin check IG for set comments -->
        <xsl:choose>
            <xsl:when test="$vCurrentIg = 'eICR'" >  
                <xsl:comment>
                    <xsl:text>Globally unique document ID (extension) is scoped by vendor/software</xsl:text>
                </xsl:comment>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>Converting identifier <xsl:value-of select="$vConvertedSystem" /></xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
        <!-- MD: end -->
        
       
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
                                <xsl:when test="$vCurrentIg = 'eICR'" >                             
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
                <xsl:when test="starts-with(fhir:system/@value, 'urn:oid:')">
                    <xsl:attribute name="root" select="substring-after(fhir:system/@value, 'urn:oid:')" />
                    <xsl:attribute name="extension" select="$vValue" />
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
                <xsl:when test="$vConvertedSystem">
                    <xsl:choose>
                        <xsl:when test="starts-with($vConvertedSystem, 'http')">
                            <!-- Did not find an entry in the oid uri mapping file, so use a UUID for the root and store the URI in assigning authority -->
                            <xsl:attribute name="root" select="lower-case(uuid:get-uuid())" />
                            <xsl:attribute name="assigningAuthorityName" select="$vConvertedSystem" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="root" select="$vConvertedSystem" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:attribute name="extension" select="$vValue" />
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
                <id root="{$system}" extension="{$value}" />
            </xsl:when>
            <xsl:otherwise>
                <id nullFlavor="NI">
                    <xsl:comment>valueUri/@value was <xsl:value-of select="@value" /></xsl:comment>
                </id>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhir:valueUri">
        <xsl:variable name="vIdentifier" as="node()*">
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
