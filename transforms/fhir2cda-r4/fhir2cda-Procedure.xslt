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
<xsl:stylesheet exclude-result-prefixes="sdtc lcg xsl cda fhir" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />


    <!-- ********************************************************************* -->
    <!-- Generic Procedure Processing                                        -->
    <!-- ********************************************************************* -->

    <!-- This is a FHIR Specimen that is going to be a Procedure in CDA-->
    <!-- These are contained in an Organizer -->
    <xsl:template match="fhir:Specimen" mode="component">
        <component>
            <xsl:call-template name="make-specimen-collection-procedure" />
        </component>
    </xsl:template>

    <xsl:template match="fhir:Procedure" mode="entry">
        <xsl:call-template name="make-generic-procedure" />
    </xsl:template>

    <xsl:template name="make-planned-procedure">
        <xsl:param name="pTriggerExtension" />
        <!--<xsl:param name="pMapping" />-->
        
        <xsl:variable name="vMoodCode">
            <xsl:apply-templates select="fhir:intent" />
        </xsl:variable>
        
        <entry>
            <procedure classCode="PROC" moodCode="{$vMoodCode}">
                <xsl:if test="fhir:doNotPerform/@value = 'true'">
                    <xsl:attribute name="negationInd" select="'true'" />
                </xsl:if>
                <!-- templateId -->
                <xsl:comment select="' [C-CDA R2.1] Planned Procedure (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.41" extension="2014-06-09" />

                <xsl:if test="$pTriggerExtension">
                    <xsl:comment select="' [eCR R2D3] Initial Case Report Trigger Code Planned Procedure '" />
                    <templateId root="2.16.840.1.113883.10.20.15.2.3.42" extension="2021-01-01" />
                </xsl:if>

                <id root="{lower-case(uuid:get-uuid())}" />
                <xsl:apply-templates select="fhir:code">
                    <xsl:with-param name="pTriggerExtension" select="$pTriggerExtension" />
                </xsl:apply-templates>

                <xsl:apply-templates mode="text" select="fhir:code/fhir:text" />
                <!-- C-CDA Planned Procedure has statusCode hard coded to 'active' -->
                <statusCode code="active" />
                <xsl:for-each select="fhir:bodySite/fhir:coding">
                    <targetSiteCode>
                        <xsl:attribute name="code">
                            <xsl:value-of select="./fhir:code/@value" />
                        </xsl:attribute>
                        <xsl:variable name="vBodySiteSystemUri" select="./fhir:system/@value" />
                        <xsl:choose>
                            <xsl:when test="$gvMapping/map[@uri = $vBodySiteSystemUri]">
                                <xsl:attribute name="codeSystem">
                                    <xsl:value-of select="$gvMapping/map[@uri = $vBodySiteSystemUri][1]/@oid" />
                                </xsl:attribute>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:apply-templates mode="display" select="./fhir:display" />
                    </targetSiteCode>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="fhir:encounter">
                        <entryRelationship typeCode="RSON">
                            <encounter classCode="ENC" moodCode="INT">
                                <xsl:comment select="' Planned  Encounter V2 '" />
                                <templateId root="2.16.840.1.113883.10.20.22.4.40" />
                                <id root="{lower-case(uuid:get-uuid())}" />
                                <xsl:variable name="referenceURI">
                                    <xsl:call-template name="resolve-to-full-url">
                                        <xsl:with-param name="referenceURI" select="fhir:encounter/fhir:reference/@value" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                                <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]" />
                                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                    <xsl:apply-templates mode="serviceRequest" select="fhir:resource/fhir:*" />
                                </xsl:for-each>
                            </encounter>
                        </entryRelationship>
                    </xsl:when>
                </xsl:choose>
                <!-- ServiceRequest.performer -->
                <xsl:for-each select="fhir:performer">
                    <xsl:for-each select="fhir:reference">
                        <xsl:variable name="referenceURI">
                            <xsl:call-template name="resolve-to-full-url">
                                <xsl:with-param name="referenceURI" select="@value" />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:comment>Performer <xsl:value-of select="$referenceURI" /></xsl:comment>
                        <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/*">
                            <xsl:call-template name="make-performer" />
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
                <!-- author (C-CDA Author Participation template) -->
                <xsl:choose>
                    <xsl:when test="fhir:authoredOn and not(fhir:requester)">
                        <author>
                            <templateId root="2.16.840.1.113883.10.20.22.4.119" />
                            <xsl:variable name="vAuthoredOn">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:authoredOn/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:variable>
                            <time>
                                <xsl:attribute name="value">
                                    <xsl:call-template name="Date2TS">
                                        <xsl:with-param name="date" select="fhir:authoredOn/@value" />
                                        <xsl:with-param name="includeTime" select="true()" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </time>
                            <assignedAuthor>
                                <id nullFlavor="NI" />
                            </assignedAuthor>
                        </author>
                    </xsl:when>
                    <xsl:when test="fhir:requester">
                        <xsl:apply-templates select="fhir:requester" />
                    </xsl:when>
                </xsl:choose>
            </procedure>
        </entry>

    </xsl:template>

    <!-- MD: handle procedure entry in Medical Equipment Section -->
    <xsl:template match="fhir:Procedure" mode="entryMedicalEquipment">
        <xsl:call-template name="make-medical-equipment-procedure" />
    </xsl:template>

    <xsl:template name="make-medical-equipment-procedure">
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <entry>
            <procedure classCode="PROC" moodCode="EVN">
                <!-- Procedure Activity Procedure V2-->
                <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.14" />
                <xsl:comment select="' Procedure Activity Procedure template '" />
                <!-- templateId -->
                <xsl:call-template name="get-template-id">
                    <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                </xsl:call-template>
                <xsl:call-template name="get-id" />
                <!-- code -->
                <xsl:apply-templates select="fhir:code">
                    <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                </xsl:apply-templates>
                <xsl:apply-templates select="fhir:status" />

                <xsl:choose>
                    <xsl:when test="fhir:performedDateTime">
                        <effectiveTime>
                            <xsl:attribute name="value">
                                <xsl:call-template name="Date2TS">
                                    <xsl:with-param name="date" select="fhir:performedDateTime/@value" />
                                    <xsl:with-param name="includeTime" select="true()" />
                                </xsl:call-template>
                            </xsl:attribute>
                        </effectiveTime>
                    </xsl:when>
                </xsl:choose>
            </procedure>
        </entry>
    </xsl:template>


    <!-- Named template: make-generic-procedure -->
    <xsl:template name="make-generic-procedure">

        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />
        <!-- procedure should be under <section> <entry> -->

        <entry>
            <procedure classCode="PROC" moodCode="EVN">
                <!-- templateId -->
                <xsl:choose>
                    <xsl:when test="fhir:meta/fhir:profile">
                        <xsl:call-template name="get-template-id">
                            <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- MD: hard coded procedure activity procedure template id, if no meta.profile                       
                    without templatedId, cda2fhir transform drops the procedure -->
                        <templateId extension="2014-06-09" root="2.16.840.1.113883.10.20.22.4.14" />
                        <xsl:comment select="' Procedure Activity Procedure template '" />
                    </xsl:otherwise>
                </xsl:choose>


                <!-- id -->
                <xsl:call-template name="get-id" />
                <!-- code -->
                <xsl:apply-templates select="fhir:code">
                    <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
                </xsl:apply-templates>
                <!-- statusCode -->
                <xsl:apply-templates select="fhir:status" />
                <!-- effectiveTime -->
                <xsl:apply-templates select="fhir:performedPeriod" />
                <xsl:apply-templates select="fhir:performedDateTime" />
                <!-- priorityCode -->
                <!-- value (nullFlavor as FHIR doesn't have this) -->
                <!--<value nullFlavor="NA" /> -->
                <!-- methodCode -->
                <!-- targetSiteCode -->
                <!-- specimen -->
                <!-- performer -->
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
                <!-- author -->
                <!-- participant/ProductInstance -->
                <xsl:for-each select="fhir:focalDevice/fhir:manipulated">
                    <!-- Find Device entry -->
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:apply-templates mode="participant" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Device" />
                </xsl:for-each>

                <!-- entryRelationship/encounter -->
                <!-- entryRelationship/Instruction -->
                <!-- entryRelationship/Indication -->
                <!-- entryRelationship/MedicationActivity -->
                <!-- entryRelationship/ReactionObservation -->
            </procedure>

        </entry>
    </xsl:template>

    <xsl:template match="fhir:Device" mode="participant">
        <participant typeCode="DEV">
            <participantRole classCode="MANU">
                <xsl:call-template name="get-template-id">
                    <xsl:with-param name="pElementType" select="'participant'" />
                </xsl:call-template>

                <!-- If this is a UDI then the FDA OID 2.16.840.1.113883.3.3719 must be used -->
                <!-- SG 20240226: Updated to map identifier to id  -->
                <xsl:if test="fhir:udiCarrier">
                    <id assigningAuthorityName="FDA" extension="{fhir:udiCarrier/fhir:carrierHRF/@value}" root="2.16.840.1.113883.3.3719" />
                </xsl:if>
                <xsl:if test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:if>
                <xsl:if test="not(fhir:udiCarrier or fhir:identifier)">
                    <id nullFlavor="NI" />
                </xsl:if>

                <!--<xsl:apply-templates select="$vDevice/fhir:address" />
                        <xsl:apply-templates select="$vDevice/fhir:telecom" />-->
                <playingDevice>
                    <xsl:apply-templates select="fhir:type" />
                    <!-- SG 20240226: Updated to map name to manufacturerModelName-->
                    <xsl:if test="fhir:name">
                        <manufacturerModelName>
                            <xsl:value-of select="fhir:name/fhir:value/@value" />
                        </manufacturerModelName>
                    </xsl:if>
                    <xsl:if test="fhir:modelNumber">
                        <softwareName>
                            <xsl:value-of select="fhir:modelNumber/@value" />
                        </softwareName>
                    </xsl:if>

                </playingDevice>
                <scopingEntity>
                    <xsl:choose>
                        <!-- If this is a UDI then the FDA OID 2.16.840.1.113883.3.3719 must be used here also -->
                        <xsl:when test="fhir:udiCarrier">
                            <id root="2.16.840.1.113883.3.3719" />
                        </xsl:when>
                        <xsl:otherwise>
                            <id nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="fhir:manufacturer">
                        <desc>
                            <xsl:value-of select="fhir:manufacturer/@value" />
                        </desc>
                    </xsl:if>
                </scopingEntity>
            </participantRole>
        </participant>
    </xsl:template>

    <!-- Named template: make-specimen-collection-procedure -->
    <xsl:template name="make-specimen-collection-procedure">

        <procedure classCode="PROC" moodCode="EVN">

            <xsl:comment select="' [C-CDA] Specimen Collection Procedure (ID) '" />
            <templateId extension="2018-09-01" root="2.16.840.1.113883.10.20.22.4.315" />
            <code code="17636008" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Specimen collection (procedure)" />
            <!-- Specimen collection date/time -->
            <xsl:apply-templates select="fhir:collection/fhir:collectedPeriod" />
            <xsl:apply-templates select="fhir:collection/fhir:collectedDateTime" />

            <!-- Specimen source -->
            <xsl:apply-templates select="fhir:collection/fhir:bodySite">
                <xsl:with-param name="pElementName" select="'targetSiteCode'" />
            </xsl:apply-templates>
            <xsl:if test="fhir:type">
                <xsl:comment select="' [C-CDA ID]  Specimen Participant (ID)  '" />
                <participant typeCode="PRD">
                    <xsl:comment select="' [C-CDA ID] Specimen Participant (ID)  '" />
                    <templateId extension="2018-09-01" root="2.16.840.1.113883.10.20.22.4.310" />
                    <participantRole classCode="SPEC">
                        <!-- Specimen id -->
                        <xsl:choose>
                            <xsl:when test="fhir:identifier">
                                <xsl:apply-templates select="fhir:identifier" />
                            </xsl:when>
                            <xsl:otherwise>
                                <id nullFlavor="NI" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <playingEntity>
                            <!-- Specimen type -->
                            <xsl:apply-templates select="fhir:type" />
                        </playingEntity>
                    </participantRole>
                </participant>
            </xsl:if>
        </procedure>
    </xsl:template>

    <!-- HAI LTC Event Details Group -->
    <xsl:template match="fhir:item[fhir:linkId/@value = 'findings-group']" mode="questionnaire-observation">
        <procedure classCode="PROC" moodCode="EVN">
            <xsl:comment select="' [HAI LTCF R1D1] Specimen Collection Procedure in a Lab Identified Report LTCF '" />
            <templateId extension="2019-08-01" root="2.16.840.1.113883.10.20.5.1.3.2" />
            <code code="17636008" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Specimen collection (procedure)" />
            <xsl:comment select="' Date specimen collected '" />
            <effectiveTime>
                <low>
                    <xsl:attribute name="value">
                        <xsl:call-template name="Date2TS">
                            <xsl:with-param name="date" select="//fhir:item[fhir:linkId/@value = 'date-specimen-collected']/fhir:answer/fhir:valueDate/@value" />
                            <xsl:with-param name="includeTime" select="true()" />
                        </xsl:call-template>
                    </xsl:attribute>
                </low>
            </effectiveTime>
            <participant typeCode="PRD">
                <participantRole classCode="SPEC">
                    <playingEntity>
                        <xsl:comment select="' Specimen type '" />
                        <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'specimen-type']" />
                    </playingEntity>
                </participantRole>
            </participant>
        </procedure>
    </xsl:template>

    <xsl:template match="fhir:text" mode="text">
        <text>
            <xsl:value-of select="@value" />
        </text>
    </xsl:template>

    <xsl:template match="fhir:display" mode="display">
        <xsl:attribute name="displayName">
            <xsl:value-of select="@value" />
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
