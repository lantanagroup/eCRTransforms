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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:uuid="http://www.uuid.org" 
    xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sdtc="urn:hl7-org:sdtc" version="2.0" exclude-result-prefixes="sdtc lcg xsl cda fhir">

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
                    <templateId root="2.16.840.1.113883.10.20.22.4.14" extension="2014-06-09" />
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
                                        <xsl:with-param name="date" select="fhir:performedDateTime/@value"/>
                                        <xsl:with-param name="includeTime" select="true()"/>                                         
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
                    <templateId root="2.16.840.1.113883.10.20.22.4.14" extension="2014-06-09" />
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
            <!-- priorityCode -->
            <!-- value (nullFlavor as FHIR doesn't have this) -->
            <!--<value nullFlavor="NA" /> -->
            <!-- methodCode -->
            <!-- targetSiteCode -->
            <!-- specimen -->
            <!-- performer -->
            <!-- author -->
            <!-- participant/ProductInstance -->
            <xsl:for-each select="fhir:focalDevice/fhir:manipulated">
                <!-- Find Device entry -->
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:apply-templates select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Device" mode="participant"/>
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
                    <xsl:with-param name="pElementType" select="'participant'"/>
                </xsl:call-template>
                <!-- Hard-coding this templateId for now -->
                <!--<xsl:comment select="' [C-CDA R1.1] Product Instance'" />
                <templateId root="2.16.840.1.113883.10.20.22.4.37" />-->
                <xsl:choose>
                    <!-- If this is a UDI then the FDA OID 2.16.840.1.113883.3.3719 must be used -->
                    <xsl:when test="fhir:udiCarrier">
                        <id root="2.16.840.1.113883.3.3719" assigningAuthorityName="FDA" extension="{fhir:udiCarrier/fhir:carrierHRF/@value}" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <!--<xsl:apply-templates select="$vDevice/fhir:address" />
                        <xsl:apply-templates select="$vDevice/fhir:telecom" />-->
                <playingDevice>
                    <xsl:apply-templates select="fhir:type" />
                    <xsl:for-each select="fhir:manufacturer">
                        <manufacturerModelName>
                            <xsl:value-of select="@value" />
                        </manufacturerModelName>
                    </xsl:for-each>
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
                </scopingEntity>
            </participantRole>
        </participant>
    </xsl:template>

    <!-- Named template: make-specimen-collection-procedure -->
    <xsl:template name="make-specimen-collection-procedure">

        <procedure classCode="PROC" moodCode="EVN">

            <xsl:comment select="' [C-CDA] Specimen Collection Procedure (ID) '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.315" extension="2018-09-01" />
            <code code="17636008" displayName="Specimen collection (procedure)" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" />
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
                    <templateId root="2.16.840.1.113883.10.20.22.4.310" extension="2018-09-01" />
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
     
    <xsl:template match="fhir:text" mode="text">
        <text>
            <xsl:value-of select="@value"/>
        </text> 
    </xsl:template>
    
    <xsl:template match="fhir:display" mode="display">
        <xsl:attribute name="displayName">
            <xsl:value-of select="@value"/> 
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
