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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:uuid="http://www.uuid.org" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!--
  <xsl:import href="fhir2cda-utility.xslt" />
  -->
    <xsl:import href="native-xslt-uuid.xslt" />

    <xsl:template match="fhir:identifier | fhir:masterIdentifier">
        <xsl:param name="pElementName" select="'id'" />
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->

        <xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig" />
        </xsl:variable>

        <!-- SG 20240306: Updating for case where there is no system - using guidance here: https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html
                          "introspect steward organization OID" (SG: if this is missing use author.identifier.system) -->
        <xsl:variable name="vConvertedSystem">
            <xsl:choose>
                <xsl:when test="fhir:system/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">NULLFLAVOR</xsl:when>
                <xsl:when test="fhir:system/@value">
                    <xsl:call-template name="convertURI">
                        <xsl:with-param name="uri" select="fhir:system/@value" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vCustodianReference" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:Composition[1]/fhir:custodian/fhir:reference/@value" />
                    <xsl:variable name="vAuthorReference" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:Composition[1]/fhir:author[1]/fhir:reference/@value" />
                    <xsl:choose>
                        <xsl:when test="//fhir:entry[fhir:fullUrl/@value = $vCustodianReference]/fhir:resource/fhir:*/fhir:identifier/fhir:system/@value">
                            <xsl:call-template name="convertURI">
                                <xsl:with-param name="uri" select="//fhir:entry[fhir:fullUrl/@value = $vCustodianReference]/fhir:resource/fhir:*/fhir:identifier/fhir:system/@value" />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="//fhir:entry[fhir:fullUrl/@value = $vAuthorReference]/fhir:resource/fhir:*/fhir:identifier/fhir:system/@value">
                            <xsl:call-template name="convertURI">
                                <xsl:with-param name="uri" select="//fhir:entry[fhir:fullUrl/@value = $vAuthorReference]/fhir:resource/fhir:*/fhir:identifier/fhir:system/@value" />
                            </xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:variable name="vConvertedValue">
            <xsl:choose>
                <xsl:when test="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">NULLFLAVOR</xsl:when>
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
                <xsl:when test="$vConvertedSystem = 'NULLFLAVOR' and $vConvertedValue = 'NULLFLAVOR'">
                    <xsl:apply-templates select="fhir:system/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                </xsl:when>
                <xsl:when test="starts-with(fhir:value/@value, 'urn:uuid:') and not(fhir:system/@value)">
                    <xsl:attribute name="root" select="substring-after(fhir:value/@value, 'urn:uuid:')" />
                </xsl:when>
                <xsl:when test="fhir:system/@value = 'urn:ietf:rfc:3986'">
                    <xsl:choose>
                        <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                            <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                        <xsl:when test="starts-with($vConvertedValue, 'urn:oid:')">
                            <xsl:attribute name="root" select="substring-after($vConvertedValue, 'urn:oid:')" />
                        </xsl:when>
                        <xsl:when test="starts-with($vConvertedValue, 'urn:uuid:')">
                            <xsl:attribute name="root" select="substring-after($vConvertedValue, 'urn:uuid:')" />
                        </xsl:when>
                        <xsl:when test="starts-with($vConvertedValue, 'urn:hl7ii:')">
                            <xsl:variable name="vSystemAfter">
                                <xsl:value-of select="substring-after($vConvertedValue, 'urn:hl7ii:')" />
                            </xsl:variable>
                            <xsl:choose>
                                <xsl:when test="contains($vSystemAfter, ':')">
                                    <xsl:attribute name="root" select="substring-before($vSystemAfter, ':')" />
                                    <xsl:attribute name="extension" select="substring-after($vSystemAfter, ':')" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="root" select="$vSystemAfter" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>TODO: System is urn:ietf:rfc:3986 but did not start with urn:oid or urn:uuid. Need to handle other URI types.</xsl:message>
                            <xsl:attribute name="root" select="$vConvertedValue" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- SG 20240306: Add check to make sure OID is valid -->
                <xsl:when test="starts-with(fhir:system/@value, 'urn:oid:') and matches(fhir:system/@value, 'urn:oid:[0-2](.[1-9]\d*)+')">
                    <xsl:attribute name="root" select="substring-after(fhir:system/@value, 'urn:oid:')" />
                    <xsl:choose>
                        <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                            <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="extension" select="$vConvertedValue" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:oid:') and not(matches(fhir:system/@value, 'urn:oid:[0-2](.[1-9]\d*)+'))">
                    <xsl:attribute name="root" select="'2.16.840.1.113883.4.873'" />
                    <!--<xsl:attribute name="extension" select="$vConvertedValue" />-->
                    <xsl:choose>
                        <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                            <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="extension" select="concat('urn:', substring-after(fhir:system/@value, 'urn:oid:'), ':', $vConvertedValue)" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:uuid:')">
                    <xsl:attribute name="root" select="substring-after(fhir:system/@value, 'urn:uuid:')" />
                    <xsl:choose>
                        <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                            <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="extension" select="$vConvertedValue" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="starts-with(fhir:system/@value, 'urn:hl7ii:')">
                    <xsl:variable name="vSystemAfter">
                        <xsl:value-of select="substring-after(fhir:system/@value, 'urn:hl7ii:')" />
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($vSystemAfter, ':')">
                            <xsl:attribute name="root" select="substring-before($vSystemAfter, ':')" />
                            <xsl:attribute name="extension" select="substring-after($vSystemAfter, ':')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="root" select="$vSystemAfter" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- SG 2023-11-15: Updating the below based on the rules here: 
                    https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html (see: FHIR identifier ↔ CDA id with Example Mapping table) -->
                <xsl:when test="$vConvertedSystem">
                    <xsl:choose>
                        <xsl:when test="starts-with($vConvertedSystem, 'http')">
                            <!-- Did not find an entry in the oid uri mapping file, so use 2.16.840.1.113883.4.873 (OID for urn:ietf:rfc:3986) for root
                                 and concatenate system and extension for extension-->
                            <xsl:attribute name="root" select="'2.16.840.1.113883.4.873'" />
                            <xsl:choose>
                                <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                                    <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="extension" select="concat($vConvertedSystem, '/', $vConvertedValue)" />
                                </xsl:otherwise>
                            </xsl:choose>

                            <!--<!-\- Did not find an entry in the oid uri mapping file, so use a UUID for the root and store the URI in assigning authority -\->
                            <xsl:attribute name="root" select="lower-case(uuid:get-uuid())" />
                            <xsl:attribute name="assigningAuthorityName" select="$vConvertedSystem" />-->
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="root" select="$vConvertedSystem" />
                            <xsl:choose>
                                <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                                    <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="extension" select="$vConvertedValue" />
                                </xsl:otherwise>
                            </xsl:choose>

                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                    <xsl:if test="$vConvertedValue">
                        <xsl:choose>
                            <xsl:when test="$vConvertedValue = 'NULLFLAVOR'">
                                <xsl:apply-templates select="fhir:value/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="extension" select="$vConvertedValue" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <xsl:if test="fhir:system">
                        <xsl:attribute name="assigningAuthorityName" select="fhir:system/@value" />
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:valueUri" mode="make-ii">
        <xsl:variable name="vSystem" select="substring-before(substring-after(@value, 'hl7ii:'), ':')" />
        <xsl:variable name="vValue" select="substring-after(substring-after(@value, 'hl7ii:'), ':')" />
        <xsl:choose>
            <xsl:when test="$vSystem and $vValue">
                <id extension="{$vValue}" root="{$vSystem}" />
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
