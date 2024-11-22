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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" exclude-result-prefixes="lcg xsl cda fhir" version="2.0">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-SubstanceAdministration.xslt" />

    <!-- fhir:MedicationDispense -> Medication Dispense (supply) -->
    <xsl:template match="fhir:MedicationDispense" mode="entry-relationship">
        <xsl:param name="typeCode" />
        <entryRelationship>
            <xsl:if test="$typeCode">
                <xsl:attribute name="typeCode" select="$typeCode" />
            </xsl:if>
            <xsl:call-template name="make-medication-dispense">
                <xsl:with-param name="moodCode">EVN</xsl:with-param>
            </xsl:call-template>
        </entryRelationship>
    </xsl:template>

    <xsl:template name="make-medication-dispense">
        <xsl:param name="moodCode">EVN</xsl:param>
        <supply classCode="SPLY" moodCode="{$moodCode}">
            <templateId root="2.16.840.1.113883.10.20.22.4.18" extension="2014-06-09" />
            <templateId root="2.16.840.1.113883.10.20.37.3.11" extension="2017-08-01" />
            <xsl:choose>
                <xsl:when test="fhir:identifer">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:status">
                    <xsl:apply-templates select="fhir:status" mode="medication-dispense" />
                </xsl:when>
                <xsl:otherwise>
                    <statusCode nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:whenPrepared">
                    <effectiveTime>
                        <xsl:attribute name="value">
                            <xsl:call-template name="Date2TS">
                                <xsl:with-param name="date" select="fhir:whenPrepared/@value" />
                                <xsl:with-param name="includeTime" select="true()" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </effectiveTime>
                </xsl:when>
                <xsl:when test="fhir:whenHandedOver">
                    <effectiveTime>
                        <xsl:attribute name="value">
                            <xsl:call-template name="Date2TS">
                                <xsl:with-param name="date" select="fhir:whenHandedOver/@value" />
                                <xsl:with-param name="includeTime" select="true()" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </effectiveTime>
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="fhir:quantity">
                <xsl:with-param name="pElementName">quantity</xsl:with-param>
                <xsl:with-param name="include-datatype">false</xsl:with-param>
            </xsl:apply-templates>
            <xsl:for-each select="fhir:medicationCodeableConcept">
                <product>
                    <manufacturedProduct classCode="MANU">
                        <!-- [C-CDA R2.0] Medication information (V2) -->
                        <templateId root="2.16.840.1.113883.10.20.22.4.23" extension="2014-06-09" />
                        <id root="4b355395-790c-405d-826f-f5a8e242db89" />
                        <manufacturedMaterial>
                            <xsl:apply-templates select="." />
                            <!--<xsl:call-template name="CodeableConcept2CD" />-->
                        </manufacturedMaterial>
                    </manufacturedProduct>
                </product>
            </xsl:for-each>
            <xsl:for-each select="fhir:performer">
                <xsl:for-each select="fhir:actor">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                        <xsl:apply-templates select="fhir:resource/fhir:*" mode="event-performer" />
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </supply>
    </xsl:template>

    <xsl:template match="fhir:status" mode="medication-dispense">
        <statusCode>
            <xsl:choose>
                <xsl:when test="@value = 'completed'">
                    <xsl:attribute name="code">completed</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'not-done'">
                    <xsl:attribute name="code">aborted</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'entered-in-error'">
                    <xsl:attribute name="code">aborted</xsl:attribute>
                </xsl:when>
                <xsl:when test="@value = 'stopped'">
                    <xsl:attribute name="code">aborted</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="nullFlavor">OTH</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </statusCode>
    </xsl:template>

    <xsl:template match="fhir:entry/fhir:resource/fhir:Practitioner" mode="medication-dispense">
        <xsl:call-template name="make-performer" />
    </xsl:template>

</xsl:stylesheet>
