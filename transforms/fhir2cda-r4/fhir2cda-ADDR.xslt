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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- (Generic) Addr -->
    <xsl:template match="fhir:address | fhir:valueAddress">
        <xsl:param name="elementName" select="'addr'" />
        <xsl:element name="{$elementName}">
            <xsl:choose>
                <xsl:when test="fhir:use">
                    <xsl:attribute name="use">
                        <xsl:choose>
                            <xsl:when test="fhir:use/@value = 'home'">H</xsl:when>
                            <xsl:when test="fhir:use/@value = 'work'">WP</xsl:when>
                            <xsl:when test="fhir:use/@value = 'mobile'">MC</xsl:when>
                            <xsl:when test="fhir:use/@value = 'temp'">TMP</xsl:when>
                            <!-- default to work -->
                            <xsl:otherwise>WP</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            
            <!-- Setting order for consistency and easier testing/compares -->
            <!-- Ming fix any missing elements and data-absent-reason -->
            <xsl:choose>
                <xsl:when test="fhir:line">
                    <xsl:apply-templates mode="address" select="fhir:line">
                        <xsl:with-param name="pElementName" select="'streetAddressLine'" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <streetAddressLine nullFlavor="UNK"/>
                </xsl:otherwise>
            </xsl:choose>
             
            <xsl:choose>    
                <xsl:when test="fhir:city">
                    <xsl:apply-templates mode="address" select="fhir:city" />
                </xsl:when>
                <xsl:otherwise>
                    <city nullFlavor="UNK"/> 
                </xsl:otherwise>
            </xsl:choose>
                
            <xsl:choose>
                <xsl:when test="fhir:state">
                    <xsl:apply-templates mode="address" select="fhir:state" />
                </xsl:when>
                <xsl:otherwise>
                    <state nullFlavor="UNK"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:choose>
                <xsl:when test="fhir:district">
                    <xsl:apply-templates mode="address" select="fhir:district">
                        <xsl:with-param name="pElementName" select="'county'" />
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
            
             <xsl:choose>
                 <xsl:when test="fhir:postalCode">
                     <xsl:apply-templates mode="address" select="fhir:postalCode" />
                 </xsl:when>
                 <xsl:otherwise>
                     <postalCode nullFlavor="UNK"/>
                 </xsl:otherwise>
             </xsl:choose> 
            
            <xsl:choose>
                <xsl:when test="fhir:country">
                    <xsl:apply-templates mode="address" select="fhir:country" />
                </xsl:when>
                <!--<xsl:otherwise>
                    <country nullFlavor="UNK"/>
                </xsl:otherwise>-->
            </xsl:choose>
                       
            <xsl:apply-templates select="fhir:period">
                <xsl:with-param name="pElementName" select="'useablePeriod'"/>
                <xsl:with-param name="pXSIType" select="'IVL_TS'"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:city" mode="address">
        <xsl:param name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="fhir:state" mode="address">
        <xsl:param name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="fhir:postalCode" mode="address">
        <xsl:param name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="fhir:district" mode="address">
        <xsl:param name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="fhir:country" mode="address">
        <xsl:param name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="fhir:line" mode="address">
        <xsl:param name="pElementName" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:value-of select="@value" />
                </xsl:when>
                <xsl:when test="fhir:extension[@url='http://hl7.org/fhir/StructureDefinition/data-absent-reason']/fhir:valueCode/@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <!-- 
    <xsl:template match="fhir:*" mode="address">
        <xsl:param name="pElementName">
            <xsl:value-of select="local-name(.)" />
        </xsl:param>
        <xsl:element name="{$pElementName}">
            <xsl:value-of select="@value" />
        </xsl:element>
    </xsl:template>
    -->

</xsl:stylesheet>
