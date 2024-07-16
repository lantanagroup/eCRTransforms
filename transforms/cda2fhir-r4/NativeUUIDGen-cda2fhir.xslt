<?xml version="1.0" encoding="UTF-8"?>
<!-- 
   
Copyright 2017 Lantana Consulting Group

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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:uuid="java:java.util.UUID" version="2.0" exclude-result-prefixes="lcg cda uuid fhir">

    <xsl:import href="cda2fhir-includes.xslt" />
    <xsl:import href="cda-add-uuid-native.xslt" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:strip-space elements="*" />

    <xsl:template match="/">
        <xsl:variable name="element-count" select="count(//cda:*)" />
        <xsl:comment>Element count: <xsl:value-of select="$element-count" /></xsl:comment>
        <!-- Preprocesses the CDA document, adding UUIDs where needed to generate resources and references later -->
        <xsl:variable name="pre-pre-processed-cda">
            <xsl:apply-templates select="." mode="add-uuids" />
        </xsl:variable>
        <!-- There are author cases where the author isn't a complete author and is referencing
            a complete participation (doesn't have to be another author) elsewhere in the document by id
            Find any of these authors and replace their @lcg:uuid with the matched complete author @lcg:uuid -->
        <xsl:variable name="pre-processed-cda">
            <xsl:apply-templates select="$pre-pre-processed-cda" mode="update-referenced-actor-uuids" />
        </xsl:variable>
        <!-- This is where processing actually starts -->
        <xsl:apply-templates select="$pre-processed-cda" mode="convert" />
    </xsl:template>
    
    <xsl:template match="@* | node()" mode="update-referenced-actor-uuids">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="update-referenced-actor-uuids" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="cda:assignedAuthor[cda:id][not(descendant::node()/descendant::node())]/@lcg:uuid" mode="update-referenced-actor-uuids">
        <!-- get author id we need to match -->
        <xsl:variable name="vAuthorIdRoot">
            <!-- can only match one -->
            <xsl:value-of select="parent::cda:assignedAuthor/cda:id[1]/@root" />
        </xsl:variable>
        <xsl:variable name="vAuthorIdExtension">
            <!-- can only match one -->
            <xsl:value-of select="parent::cda:assignedAuthor/cda:id[1]/@extension" />
        </xsl:variable>
        <!-- get the first instance of that author/patient id match (because there could be multiple) and
                     grab the @lcg:uuid value-->
        <xsl:variable name="vLcgUuid">
            <xsl:choose>
                <xsl:when test="string-length($vAuthorIdRoot) > 0 and string-length($vAuthorIdExtension) > 0">
                    <xsl:for-each select="//cda:*[cda:id/@root = $vAuthorIdRoot][cda:id/@extension = $vAuthorIdExtension][descendant::node()/descendant::node()]">
                        <xsl:if test="position() = 1">
                            <!-- if this is patient need to go up one level to recordTarget -->
                            <xsl:choose>
                                <xsl:when test="parent::cda:recordTarget">
                                    <xsl:value-of select="parent::cda:recordTarget/@lcg:uuid" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@lcg:uuid" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="string-length($vAuthorIdRoot) > 0">
                    <xsl:for-each select="//cda:*[cda:id/@root = $vAuthorIdRoot][descendant::node()/descendant::node()]">
                        <xsl:if test="position() = 1">
                            <!-- if this is patient need to go up one level to recordTarget -->
                            <xsl:choose>
                                <xsl:when test="parent::cda:recordTarget">
                                    <xsl:value-of select="parent::cda:recordTarget/@lcg:uuid" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@lcg:uuid" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="string-length($vAuthorIdExtension) > 0">
                    <xsl:for-each select="//cda:*[cda:id/@extension = $vAuthorIdExtension][descendant::node()/descendant::node()]">
                        <xsl:if test="position() = 1">
                            <!-- if this is patient need to go up one level to recordTarget -->
                            <xsl:choose>
                                <xsl:when test="parent::cda:recordTarget">
                                    <xsl:value-of select="parent::cda:recordTarget/@lcg:uuid" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@lcg:uuid" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="lcg:uuid">
            <xsl:value-of select="$vLcgUuid" />
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
