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
    xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid">

    <xsl:import href="fhir2cda-utility.xslt" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />

    <!-- eICR Encounter Activities (Encounter) -->
    <!-- The Encounters Section and in turn Encounter Activities for eICR is created from 
       Composition.encounter - there isn't a section in the Composition, so we need to 
       manually create the Section and encounter -->
    <xsl:template match="fhir:Encounter" mode="encounter">
        <entry typeCode="DRIV">
            <encounter classCode="ENC" moodCode="EVN">
                <xsl:comment select="' [C-CDA R1.1] Encounter Activities '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.49" />
                <xsl:comment select="' [C-CDA R2.1] Encounter Activities (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.49" extension="2015-08-01" />
                <!-- We don't have an id to use here so generate one -->
                <id root="{lower-case(uuid:get-uuid())}" />
                
                <!-- Merging class and type into one data element, and FHIR allows multiple types - merge them into a variable and process -->
                <xsl:variable name="vMergedTypes">
                    <code xmlns="http://hl7.org/fhir">
                        <xsl:copy-of select="fhir:class/fhir:coding" />
                        <xsl:copy-of select="fhir:type/fhir:coding" />
                        <xsl:if test="fhir:class/fhir:text or fhir:type/fhir:text">
                            <text xmlns="http://hl7.org/fhir">
                                <xsl:attribute name="value" select="string-join(fhir:class/fhir:text/@value | fhir:type/fhir:text/@value, ', ')" />
                            </text>
                        </xsl:if>
                    </code>
                </xsl:variable>
                <xsl:apply-templates select="$vMergedTypes/fhir:code" />
                
                <!--<xsl:apply-templates select="fhir:type" />-->
                <xsl:apply-templates select="fhir:period" />

                <xsl:apply-templates select="fhir:diagnosis" />
            </encounter>
        </entry>
    </xsl:template>

    <!-- fhir:diagnosis -> get referenced resource entry url and process -->
    <xsl:template match="fhir:diagnosis">
        <xsl:for-each select="fhir:condition/fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>

            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry-relationship">
                    <xsl:with-param name="pTypeCode" select="'COMP'" />
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="create-encounters-section">
        <section>
            <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries optional) (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.2.22" extension="2015-08-01" />
            <id root="{lower-case(uuid:get-uuid())}" />
            <code code="46240-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="History of encounters" />

            <title>Encounters</title>
            <xsl:choose>
                <xsl:when test="fhir:text">
                    <text>
                        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                            <xsl:apply-templates select="fhir:text" mode="narrative" />
                        </xsl:if>
                    </text>
                </xsl:when>
            </xsl:choose>

            <!-- for now we only handle the encounter reference in the ServiceRequest. In the future we may do for other resources -->
            <xsl:for-each-group select="//fhir:ServiceRequest/fhir:encounter/fhir:reference" group-by="@value">
                <xsl:variable name="vTest" select="@value" />
                <entry>
                    <encounter moodCode="INT" classCode="ENC">
                        <xsl:comment select="' Planned  Encounter V2 '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.40" extension="2014-06-09" />
                        <!-- <templateId root="2.16.840.1.113883.11.20.9.23" extension="2014-09-01"/> -->
                        <id root="{lower-case(uuid:get-uuid())}" />

                        <xsl:variable name="referenceURI">
                            <xsl:call-template name="resolve-to-full-url">
                                <xsl:with-param name="referenceURI" select="@value" />
                                <!--  select="//fhir:ServiceRequest/fhir:encounterfhir/fhir:reference/@value" />-->
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                        <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="serviceRequest" />
                        </xsl:for-each>

                    </encounter>

                </entry>

            </xsl:for-each-group>
        </section>

    </xsl:template>

    <xsl:template match="fhir:Encounter" mode="serviceRequest">
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />

        <!-- code -->
        <!-- Merging class and type into one data element, and FHIR allows multiple types - merge them into a variable and process -->
        <xsl:variable name="vMergedTypes">
            <code xmlns="http://hl7.org/fhir">
                <xsl:copy-of select="fhir:class/fhir:coding" />
                <xsl:copy-of select="fhir:type/fhir:coding" />
                <xsl:if test="fhir:class/fhir:text or fhir:type/fhir:text">
                    <text xmlns="http://hl7.org/fhir">
                        <xsl:attribute name="value" select="string-join(fhir:class/fhir:text/@value | fhir:type/fhir:text/@value, ', ')" />
                    </text>
                </xsl:if>
            </code>
        </xsl:variable>
        <xsl:apply-templates select="$vMergedTypes/fhir:code" />

        <statusCode>
            <xsl:attribute name="code" select="fhir:status/@value" />
        </statusCode>

        <effectiveTime>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="fhir:period/fhir:start/@value" />
                    <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
            </xsl:attribute>
        </effectiveTime>

        <priorityCode>
            <xsl:attribute name="code">
                <xsl:value-of select="fhir:priority/fhir:coding/fhir:code/@value" />
            </xsl:attribute>
            <xsl:variable name="vCodeSystemUri" select="fhir:priority/fhir:coding/fhir:system/@value" />
            <xsl:choose>
                <xsl:when test="$mapping/map[@uri = $vCodeSystemUri]">
                    <xsl:attribute name="codeSystem">
                        <xsl:value-of select="$mapping/map[@uri = $vCodeSystemUri][1]/@oid" />
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="fhir:priority/fhir:coding/fhir:display" mode="display" />
        </priorityCode>
    </xsl:template>

    <!-- Generic Questionnaire Item Encounters -->
    <!-- SG 20220209: Add HAI LTC First Admission Encounter in a Lab Identified Report LTCF -->
    <xsl:template match="fhir:item[fhir:linkId/@value = ('date-of-first-admission-to-facility')][fhir:answer]">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <encounter classCode="ENC" moodCode="EVN">
            <xsl:call-template name="get-template-id" />
            <id nullFlavor="NA" />
            <code code="1373-0" displayName="Date first admitted to facility" codeSystem="2.16.840.1.113883.6.277" codeSystemName="cdcNHSN" />
            <effectiveTime>
                <low>
                    <xsl:attribute name="value">
                        <xsl:call-template name="Date2TS">
                            <xsl:with-param name="date" select="fhir:answer/fhir:valueDate/@value" />
                            <xsl:with-param name="includeTime" select="true()" />
                        </xsl:call-template>
                    </xsl:attribute>
                </low>
            </effectiveTime>
        </encounter>
    </xsl:template>

    <!-- Specific Questionnaire Item Encounters -->
    <!-- SG 20220213: Summary Encounter LTCF -->
    <xsl:template match="fhir:item[fhir:linkId/@value = ('facility-id')][fhir:answer]">
        <xsl:param name="pEntryRelationships" />
        <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
        <encounter classCode="ENC" moodCode="EVN">
            <xsl:call-template name="get-template-id" />
            <participant typeCode="LOC">
                <participantRole classCode="SDLOC">
                    <!-- In-facility locations, Facwidein require the root with an extension and code element. -->
                    <xsl:apply-templates select="fhir:answer" />
                    <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = ('facility-location-code')][fhir:answer]" />
                </participantRole>
            </participant>

            <xsl:for-each select="$pEntryRelationships">
                <entryRelationship typeCode="COMP">
                    <xsl:apply-templates select="." />
                </entryRelationship>
            </xsl:for-each>


        </encounter>
    </xsl:template>

</xsl:stylesheet>
