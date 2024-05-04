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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:uuid="http://www.uuid.org" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3"
    xmlns:fhir="http://hl7.org/fhir" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="native-xslt-uuid.xslt" />

    <xsl:template match="fhir:extension" mode="inFulfillmentOf">
        <xsl:variable name="vCompositionOrderExtension" select="'http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension'" />
        <xsl:choose>
            <xsl:when test="fhir:valueReference/fhir:reference">
                <xsl:variable name="vEntryFullUrl" select="
                        //fhir:entry[fhir:resource/fhir:Composition/fhir:extension/@url = $vCompositionOrderExtension]/
                        fhir:fullUrl/@value" />

                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:valueReference/fhir:reference/@value" />
                        <xsl:with-param name="entryFullUrl" select="
                                //fhir:entry[fhir:resource/fhir:Composition/fhir:extension/@url = $vCompositionOrderExtension]/
                                fhir:fullUrl/@value" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:apply-templates select="
                        //fhir:entry[fhir:fullUrl/@value = $referenceURI]/
                        fhir:resource/fhir:*" mode="inFulfillmentOf" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhir:resource/fhir:*" mode="inFulfillmentOf">
        <inFulfillmentOf>

            <xsl:attribute name="typeCode">
                <xsl:value-of select="'FLFS'" />
            </xsl:attribute>

            <order>
                <xsl:choose>
                    <xsl:when test="fhir:status/@value = 'active'">
                        <xsl:attribute name="classCode">
                            <xsl:value-of select="'ACT'" />
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>
                <!-- fhir:intent could have the value propsal, plan, directive, order, original-order, reflex-order, filler-order instance-order, option
        not sure there is a mapping between fhir and cda. for now just hard code as RQO -->
                <xsl:attribute name="moodCode">
                    <xsl:value-of select="'RQO'" />
                </xsl:attribute>

                <!-- MD: using the referral order identifier to link the referral note to the consult note -->
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <code>
                    <xsl:attribute name="code">
                        <xsl:value-of select="fhir:code/fhir:coding/fhir:code/@value" />
                    </xsl:attribute>
                    <xsl:attribute name="displayName">
                        <xsl:value-of select="fhir:code/fhir:coding/fhir:display/@value" />
                    </xsl:attribute>

                    <xsl:variable name="vSystemUri" select="fhir:code/fhir:coding/fhir:system/@value" />
                    <xsl:choose>
                        <xsl:when test="$vSystemUri = 'http://snomed.info/sct'">
                            <xsl:attribute name="codeSystemName">
                                <xsl:value-of select="'SNOMED CT'" />
                            </xsl:attribute>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
                    <xsl:choose>
                        <xsl:when test="$mapping/map[@uri = $vSystemUri]">
                            <xsl:attribute name="codeSystem">
                                <xsl:value-of select="$mapping/map[@uri = $vSystemUri][1]/@oid" />
                            </xsl:attribute>
                        </xsl:when>
                    </xsl:choose>
                </code>
                <xsl:if test="fhir:priority">
                    <priorityCode>
                        <xsl:choose>
                            <xsl:when test="fhir:priority/@value = 'asap'">
                                <xsl:attribute name="code">
                                    <xsl:value-of select="'A'" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:when test="fhir:priority/@value = 'stat'">
                                <xsl:attribute name="code">
                                    <xsl:value-of select="'S'" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:when test="fhir:priority/@value = 'urgent'">
                                <xsl:attribute name="code">
                                    <xsl:value-of select="'UR'" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:when test="fhir:priority/@value = 'routine'">
                                <xsl:attribute name="code">
                                    <xsl:value-of select="'R'" />
                                </xsl:attribute>
                            </xsl:when>
                        </xsl:choose>
                    </priorityCode>
                </xsl:if>
            </order>
        </inFulfillmentOf>
    </xsl:template>

</xsl:stylesheet>
