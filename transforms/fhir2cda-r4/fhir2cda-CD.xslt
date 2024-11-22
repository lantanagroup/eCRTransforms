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

<!--
      FHIR CodeableConcept information: https://hl7.org/fhir/R4/datatypes.html#CodeableConcept
      A CodeableConcept represents a value that is usually supplied by providing a reference to one or more terminologies 
      or ontologies but may also be defined by the provision of text. This is a common pattern in healthcare data.
      
      More than one code may be used in CodeableConcept. The concept may be coded multiple times in different code systems 
      (or even multiple times in the same code systems, where multiple forms are possible, such as with SNOMED CT). 
      Each coding (also referred to as a 'translation') is a representation of the concept as described above and may 
      have slightly different granularity due to the differences in the definitions of the underlying codes. 
      There is no meaning associated with the ordering of coding within a CodeableConcept. A typical use of CodeableConcept is to 
      send the local code that the concept was coded with, and also one or more translations to publicly defined code systems such 
      as LOINC or SNOMED CT. Sending local codes is useful and important for the purposes of debugging and integrity auditing. 
      
      Using Text in CodeableConcept
      The text is the representation of the concept as entered or chosen by the user, and which most closely represents the intended 
      meaning of the user or concept. Very often the text is the same as a display of one of the codings. One or more of the codings may 
      be flagged as the user selected code - the code or concept that the user actually selected directly. Note that in all but a few cases, 
      only one of the codings may be flagged as the coding.userSelected = true - the code or concept that the user actually selected directly. 
      If more than one code is marked as user selected, this means the user explicitly chose multiple codes. When none of the 
      coding elements is marked as user selected, the text (if present) is the preferred source of meaning. 
      
      A free text only representation of the concept without any coding elements is permitted if there is no appropriate 
      code and only free text is available (and not prohibited by the implementation).
      
      See: https://hl7.org/fhir/R4/terminologies.html#4.1
    -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sdtc="urn:hl7-org:sdtc" version="2.0" exclude-result-prefixes="lcg xsl cda fhir sdtc">

    <!--    <xsl:import href="fhir2cda-utility.xslt" />-->

    <!--<xsl:template name="CodeableConcept2CD">
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
    </xsl:template>-->

    <!-- Creating a match template similar to the above for more flexibility -->
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
                    <xsl:if test="$pXSIType">
                        <xsl:attribute name="xsi:type" select="$pXSIType" />
                    </xsl:if>
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
            <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">
                <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="codeSystem">
                    <xsl:call-template name="convertURI">
                        <xsl:with-param name="uri" select="fhir:system/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="fhir:code/@value">
                        <xsl:attribute name="code">
                            <xsl:value-of select="fhir:code/@value" />
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="nullFlavor" select="'OTH'" />
                    </xsl:otherwise>
                </xsl:choose>

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
                            <!-- SG 20241118: Added to deal with non-oid values (having non-oid values is wrong and not in the spec, but it's what is coming from eCR Now -->
                            <xsl:choose>
                                <xsl:when test="fhir:extension[@url = 'triggerCodeValueSet']/fhir:valueString">
                                    <xsl:call-template name="convertURI">
                                        <xsl:with-param name="uri" select="fhir:extension[@url = 'triggerCodeValueSet']/fhir:valueString/@value" />
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="substring-after(fhir:extension[@url = 'triggerCodeValueSet']/fhir:valueOid/@value, 'urn:oid:')" />
                                </xsl:otherwise>
                            </xsl:choose>
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
