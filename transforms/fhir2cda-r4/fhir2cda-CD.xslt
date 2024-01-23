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

<!--    <xsl:import href="fhir2cda-utility.xslt" />-->

    <xsl:template name="CodeableConcept2CD">
        <xsl:param name="pElementName">code</xsl:param>
        <xsl:param name="pXSIType" />
        <xsl:choose>
            <xsl:when test="fhir:coding | fhir:valueCoding | fhir:valueQuantity">
                <xsl:element name="{$pElementName}">
                    <xsl:if test="$pXSIType">
                        <xsl:attribute name="xsi:type" select="$pXSIType" />
                    </xsl:if>
                    <xsl:for-each select="fhir:coding | fhir:valueCoding | fhir:valueQuantity">
                        <xsl:choose>
                            <xsl:when test="position() = 1">
                                <xsl:apply-templates select="." />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select=".">
                                    <xsl:with-param name="pElementName" select="'translation'" />
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{$pElementName}">
                    <xsl:choose>
                        <xsl:when test="fhir:text">
                            <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                            <originalText>
                                <xsl:value-of select="fhir:text/@value" />
                            </originalText>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="nullFlavor">NI</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Creating a match template similar to the above for more flexibility -->
    <!--  <xsl:template match="fhir:code[fhir:coding] | fhir:category[fhir:coding] | fhir:type[fhir:coding] | fhir:code[fhir:coding] | fhir:valueCodeableConcept | fhir:medicationCodeableConcept | fhir:route | fhir:vaccineCode">-->
    <xsl:template match="fhir:*[fhir:coding] | fhir:*[fhir:valueCoding] | fhir:code[fhir:text] | fhir:valueCodeableConcept | fhir:medicationCodeableConcept | fhir:route | fhir:vaccineCode">

        <xsl:param name="pElementName">code</xsl:param>
        <xsl:param name="pXSIType" />
        <xsl:param name="pTriggerExtension" />
        <xsl:choose>
            <xsl:when test="fhir:coding | fhir:valueCoding">
                <xsl:element name="{$pElementName}">
                    <xsl:if test="$pXSIType">
                        <xsl:attribute name="xsi:type" select="$pXSIType" />
                    </xsl:if>
                    <xsl:for-each select="fhir:coding | fhir:valueCoding">
                        <xsl:choose>
                            <!-- This is the first code - which will be code in CDA -->
                            <xsl:when test="position() = 1">
                                <xsl:apply-templates select=".">
                                    <xsl:with-param name="pElementName" select="$pElementName" />
                                    <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
                                </xsl:apply-templates>
                                <!-- Need to catch the text here for the cases where there is only one code -->
                                <xsl:for-each select="following-sibling::fhir:text">
                                    <originalText>
                                        <xsl:value-of select="@value" />
                                    </originalText>
                                </xsl:for-each>
                            </xsl:when>
                            <!-- All others are translations in CDA -->
                            <xsl:otherwise>
                                <!-- We will never get in here if there is only one code (i.e. no translation) -->
                                <!--<xsl:for-each select="following-sibling::fhir:text">
                                    <originalText>
                                        <xsl:value-of select="@value" />
                                    </originalText>
                                </xsl:for-each>-->
                                <xsl:element name="translation">
                                    <xsl:apply-templates select=".">
                                        <xsl:with-param name="pElementName" select="'translation'" />
                                        <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
                                    </xsl:apply-templates>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{$pElementName}">
                    <xsl:choose>
                        <xsl:when test="fhir:text">
                            <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                            <originalText>
                                <xsl:value-of select="fhir:text/@value" />
                            </originalText>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="nullFlavor">NI</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhir:coding | fhir:valueCoding | fhir:class | fhir:item/fhir:code | fhir:dischargeDisposition">
        <xsl:param name="pElementName" />
        <xsl:param name="pTriggerExtension" />
        <xsl:call-template name="debug-element-stack" />
        <xsl:choose>
            <!-- If this is a nullFlavor we need to process differently -->
            <xsl:when test="fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'">
                <xsl:if test="$pElementName = 'value'">
                    <xsl:attribute name="xsi:type" select="'CD'" />
                </xsl:if>
                <xsl:attribute name="nullFlavor" select="fhir:code/@value" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="codeSystem">
                    <xsl:call-template name="convertURI">
                        <xsl:with-param name="uri" select="fhir:system/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:attribute name="code">
                    <xsl:value-of select="fhir:code/@value" />
                </xsl:attribute>
                <xsl:attribute name="codeSystem">
                    <xsl:value-of select="$codeSystem" />
                </xsl:attribute>
                <xsl:if test="fhir:display">
                    <xsl:attribute name="displayName">
                        <xsl:value-of select="fhir:display/@value" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:if test="$pTriggerExtension">
                    <xsl:variable name="vCodeValue" select="fhir:code/@value" />
                    <xsl:for-each select="$pTriggerExtension[fhir:extension[@url = 'triggerCode']/fhir:valueCoding/fhir:code/@value = $vCodeValue]">
                        <xsl:attribute name="sdtc:valueSet">
                            <xsl:value-of select="substring-after(fhir:extension[@url = 'triggerCodeValueSet']/fhir:valueOid/@value, 'urn:oid:')" />
                        </xsl:attribute>
                        <xsl:attribute name="sdtc:valueSetVersion">
                            <xsl:value-of select="fhir:extension[@url = 'triggerCodeValueSetVersion']/fhir:valueString/@value" />
                        </xsl:attribute>
                    </xsl:for-each>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
