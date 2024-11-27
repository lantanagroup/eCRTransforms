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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:xslt="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

    <xsl:import href="fhir2cda-utility.xslt" />

    <!-- fhir:sender[parent::fhir:Communication] -> get referenced resource entry url and process -->
    <xsl:template match="fhir:sender[parent::fhir:Communication] | fhir:author | fhir:location" mode="custodian">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <!-- If sender is a device we need more - get the location information -->
                <xsl:choose>
                    <xsl:when test="fhir:resource/fhir:*/local-name() = 'Device'">
                        <xsl:apply-templates select="fhir:resource/fhir:Device/fhir:location" mode="custodian" />
                    </xsl:when>
                    <xslt:otherwise>
                        <xsl:apply-templates select="fhir:resource/fhir:*" mode="custodian" />
                    </xslt:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- fhir:custodian -> get referenced resource entry url and process -->
    <xsl:template match="fhir:custodian">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <!-- there are instances of data where there are multiple matches (i.e. duplicates) -->
                <xsl:if test="position() = 1">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="custodian" />
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- fhir:organization -> get referenced resource entry url and process -->
    <xsl:template match="fhir:organization" mode="custodian">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="custodian" />
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- fhir:Organization -> cda:custodian -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Organization" mode="custodian">
        <xsl:call-template name="make-custodian" />
    </xsl:template>

    <!-- fhir:Location -> cda:custodian -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Location" mode="custodian">
        <xsl:call-template name="make-custodian" />
    </xsl:template>

    <!-- fhir:PractitionerRole/fhir:organization -> cda:custodian -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:PractitionerRole" mode="custodian">
        <xsl:apply-templates select="fhir:organization" mode="custodian" />
    </xsl:template>


    <xsl:template name="make-custodian">
        <custodian>
            <assignedCustodian>
                <representedCustodianOrganization>
                    <xsl:choose>
                        <xsl:when test="fhir:identifier">
                            <xsl:apply-templates select="fhir:identifier" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="fhir:name">
                            <name>
                                <xsl:value-of select="fhir:name/@value" />
                            </name>
                        </xsl:when>
                        <xsl:otherwise>
                            <name nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <!-- only allowed 1 telecom -->
                        <xsl:when test="fhir:telecom">
                            <xsl:apply-templates select="fhir:telecom[1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <telecom nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="fhir:address">
                            <xsl:apply-templates select="fhir:address[1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <addr nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                </representedCustodianOrganization>
            </assignedCustodian>
        </custodian>
    </xsl:template>

</xsl:stylesheet>
