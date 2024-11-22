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
    xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid">

    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />

    <xsl:template match="fhir:Coverage" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>

        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />

        <entry typeCode="DRIV">
            <!-- moodCode ? EVN or DEF -->
            <act classCode="ACT" moodCode="EVN">
                <xsl:comment select="' Coverage Activity (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.60" extension="2015-08-01" />
                <id root="{lower-case(uuid:get-uuid())}" />
                <code code="48768-6" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Payment sources" />
                <statusCode code="completed" />

                <entryRelationship typeCode="COMP">
                    <act classCode="ACT" moodCode="EVN">
                        <xsl:comment select="' Policy Activity (V3) '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.61" extension="2015-08-01" />

                        <xsl:choose>
                            <xsl:when test="fhir:identifier">
                                <xsl:apply-templates select="fhir:identifier" />
                            </xsl:when>
                            <xsl:otherwise>
                                <id nullFlavor="NI" />
                            </xsl:otherwise>
                        </xsl:choose>

                        <code>
                            <xsl:apply-templates select="fhir:type">
                                <xsl:with-param name="pElementName" select="'translation'" />
                            </xsl:apply-templates>
                        </code>

                        <statusCode code="completed" />

                        <!-- insurance company information -->
                        <performer typeCode="PRF">
                            <xsl:comment select="' Payer Performer (insurance company information) '" />
                            <templateId root="2.16.840.1.113883.10.20.22.4.87" />

                            <time>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:start">
                                        <low>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:start/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </low>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:end">
                                        <high>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:end/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </high>
                                    </xsl:when>
                                </xsl:choose>
                            </time>

                            <assignedEntity>
                                <id root="{lower-case(uuid:get-uuid())}" />
                                <code code="PAYOR" codeSystem="2.16.840.1.113883.5.110" codeSystemName="HL7 RoleCode" />

                                <xsl:variable name="referenceURI">
                                    <xsl:call-template name="resolve-to-full-url">
                                        <xsl:with-param name="referenceURI" select="fhir:payor/fhir:reference/@value" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="insurance" />
                                </xsl:for-each>
                            </assignedEntity>
                        </performer>

                        <!-- Gurantor information (the person responsible for the final bill)
        this is an optional performer-->
                        <performer typeCode="PRF">
                            <xsl:comment select="' Gurantor Performer (the person responsible for the final bill ) '" />
                            <templateId root="2.16.840.1.113883.10.20.22.4.88" />
                            <time>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:start">
                                        <low>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:start/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </low>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:end">
                                        <high>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:end/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </high>
                                    </xsl:when>
                                </xsl:choose>
                            </time>

                            <assignedEntity>
                                <id root="{lower-case(uuid:get-uuid())}" />
                                <code code="GUAR" codeSystem="2.16.840.1.113883.5.111" codeSystemName="HL7 RoleCode" />

                                <xsl:variable name="referenceURI">
                                    <xsl:call-template name="resolve-to-full-url">
                                        <xsl:with-param name="referenceURI" select="fhir:subscriber/fhir:reference/@value" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="insurance-performer-gura" />
                                </xsl:for-each>
                            </assignedEntity>
                        </performer>

                        <participant typeCode="COV">
                            <templateId root="2.16.840.1.113883.10.20.22.4.89" />
                            <time>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:start">
                                        <low>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:start/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </low>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:choose>
                                    <xsl:when test="fhir:period/fhir:end">
                                        <high>
                                            <xsl:attribute name="value">
                                                <xsl:call-template name="Date2TS">
                                                    <xsl:with-param name="date" select="fhir:period/fhir:end/@value" />
                                                    <xsl:with-param name="includeTime" select="false()" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                        </high>
                                    </xsl:when>
                                </xsl:choose>
                            </time>

                            <participantRole classCode="PAT">
                                <id root="{lower-case(uuid:get-uuid())}">
                                    <xsl:attribute name="extension">
                                        <xsl:value-of select="fhir:subscriberId/@value" />
                                    </xsl:attribute>
                                </id>

                                <xsl:for-each select="fhir:relationship">
                                    <xsl:apply-templates select="." />
                                    <!--<xsl:call-template name="CodeableConcept2CD" />-->
                                </xsl:for-each>


                                <xsl:variable name="referenceURI">
                                    <xsl:call-template name="resolve-to-full-url">
                                        <xsl:with-param name="referenceURI" select="fhir:beneficiary/fhir:reference/@value" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="insurance-participant-cov" />
                                </xsl:for-each>

                            </participantRole>
                        </participant>

                        <xsl:variable name="vSubscriberSelfHld">
                            <xsl:apply-templates select="fhir:relationship" mode="insurance-subscriberHld" />
                        </xsl:variable>

                        <!-- Policy holder -->
                        <xsl:choose>
                            <xsl:when test="$vSubscriberSelfHld = false()">
                                <participant typeCode="HLD">
                                    <templateId root="2.16.840.1.113883.10.20.22.4.90" />
                                    <participantRole>

                                        <!-- root value must be uuid 
                     extension contains health plan ID for patient 
                -->
                                        <id root="{lower-case(uuid:get-uuid())}">
                                            <xsl:attribute name="extension">
                                                <xsl:value-of select="fhir:subscriberId/@value" />
                                            </xsl:attribute>
                                        </id>

                                        <xsl:variable name="referenceURI">
                                            <xsl:call-template name="resolve-to-full-url">
                                                <xsl:with-param name="referenceURI" select="fhir:subscriber/fhir:reference/@value" />
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                        <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                            <xsl:apply-templates select="fhir:resource/fhir:*" mode="insurance-participant-hld" />
                                        </xsl:for-each>

                                    </participantRole>
                                </participant>
                            </xsl:when>
                        </xsl:choose>
                        <entryRelationship typeCode="REFR">
                            <!-- description of the coverage plan -->
                            <act classCode="ACT" moodCode="EVN">
                                <templateId root="2.16.840.1.113883.10.20.1.19" />
                                <id nullFlavor="NI" />
                                <code nullFlavor="NA" />
                                <entryRelationship typeCode="SUBJ">
                                    <act classCode="ACT" moodCode="EVN">
                                        <id root="{lower-case(uuid:get-uuid())}">
                                            <xsl:attribute name="extension">
                                                <xsl:value-of select="fhir:class/fhir:value/@value" />
                                            </xsl:attribute>
                                        </id>
                                        <xsl:for-each select="fhir:class/fhir:type">
                                            <xsl:apply-templates select="." />
                                            <!--<xsl:call-template name="CodeableConcept2CD" />-->
                                        </xsl:for-each>
                                        <xsl:choose>
                                            <xsl:when test="fhir:class/fhir:name">
                                                <text>
                                                    <xsl:value-of select="fhir:class/fhir:name/@value" />
                                                </text>
                                            </xsl:when>
                                        </xsl:choose>
                                    </act>
                                </entryRelationship>

                            </act>

                        </entryRelationship>
                    </act>
                </entryRelationship>
            </act>
        </entry>
    </xsl:template>

    <xsl:template match="fhir:relationship" mode="insurance-subscriberHld">
        <xsl:choose>
            <xsl:when test="
                    fhir:coding/fhir:system/@value =
                    'http://terminology.hl7.org/CodeSystem/subscriber-relationship'">
                <xsl:choose>
                    <xsl:when test="fhir:coding/fhir:code/@value = 'self'">
                        <xsl:value-of select="true()" />
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fhir:Organization" mode="insurance">

        <xsl:choose>
            <xsl:when test="fhir:address">
                <xsl:call-template name="get-addr" />
            </xsl:when>
        </xsl:choose>
        <xsl:call-template name="get-telecom" />

        <representedOrganization>
            <xsl:choose>
                <xsl:when test="fhir:name">
                    <name>
                        <xsl:value-of select="fhir:name/@value" />
                    </name>
                </xsl:when>
            </xsl:choose>
            <xsl:call-template name="get-telecom" />
            <xsl:call-template name="get-addr" />
        </representedOrganization>

    </xsl:template>

    <xsl:template match="fhir:Patient" mode="insurance-performer-gura">
        <xsl:choose>
            <xsl:when test="fhir:address">
                <xsl:call-template name="get-addr" />
            </xsl:when>
        </xsl:choose>
        <xsl:call-template name="get-telecom" />

        <assignedPerson>
            <xsl:choose>
                <xsl:when test="fhir:name">
                    <xsl:apply-templates select="fhir:name" />
                </xsl:when>
            </xsl:choose>
        </assignedPerson>
    </xsl:template>

    <xsl:template match="fhir:Patient" mode="insurance-participant-cov">
        <xsl:choose>
            <xsl:when test="fhir:address">
                <xsl:call-template name="get-addr" />
            </xsl:when>
        </xsl:choose>

        <playingEntity>
            <xsl:choose>
                <xsl:when test="fhir:name">
                    <xsl:apply-templates select="fhir:name" />
                </xsl:when>
            </xsl:choose>

            <xsl:variable name="vName" select="'sdtc:birthTime'" />
            <xsl:choose>
                <xsl:when test="fhir:birthDate">
                    <xsl:element name="{$vName}">
                        <xsl:attribute name="value">
                            <xsl:call-template name="Date2TS">
                                <xsl:with-param name="date" select="fhir:birthDate/@value" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="{$vName}">
                        <xsl:attribute name="value">
                            <xsl:value-of select="NI" />
                        </xsl:attribute>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </playingEntity>
    </xsl:template>

    <xsl:template match="fhir:RelatedPerson" mode="insurance-participant-hld">
        <xsl:choose>
            <xsl:when test="fhir:address">
                <xsl:call-template name="get-addr" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>



</xsl:stylesheet>
