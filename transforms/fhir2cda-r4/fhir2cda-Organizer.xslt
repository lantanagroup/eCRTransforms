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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-Observation.xslt" />

    <!-- Organizer -->
    <!-- An Observation from FHIR translates to an Organizer if it contains hasMember 
       A result observation from FHIR must be wrapped in an Organizer -->
    <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
    <xsl:template match="fhir:Observation[fhir:hasMember] | fhir:Observation[fhir:category[1]/fhir:coding[fhir:code/@value = 'laboratory']]" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>
        <entry>
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:choose>
                <xsl:when test="fhir:category[1]/fhir:coding[fhir:code/@value = 'vital-signs']">
                    <xsl:call-template name="make-vitalsign-organizer" />
                </xsl:when>
                <xsl:when test="fhir:category[1]/fhir:coding[fhir:code/@value = 'laboratory'] and fhir:hasMember">
                    <xsl:call-template name="make-result-organizer" />
                </xsl:when>
                <xsl:when test="fhir:category[1]/fhir:coding[fhir:code/@value = 'laboratory']">
                    <xsl:call-template name="make-result-organizer-wrapper" />
                </xsl:when>
                <!-- SG 20240307: Added for social-history observation with hasMembers, just make a regular observation
                     as there aren't any social-history organizers -->
                <xsl:when test="fhir:category[1]/fhir:coding[fhir:code/@value = 'social-history']">
                    <xsl:call-template name="make-generic-observation" />
                </xsl:when>
            </xsl:choose>
        </entry>
    </xsl:template>

    <!-- An DiagnosticReport from FHIR translates to an Lab Result Organizer if category = LAB and it has a result -->
    <xsl:template match="fhir:DiagnosticReport[fhir:category/fhir:coding[fhir:code/@value = 'LAB']][fhir:result]" mode="entry">
        <xsl:param name="generated-narrative">additional</xsl:param>
        <xsl:if test="$generated-narrative = 'generated'">
            <xsl:attribute name="typeCode">DRIV</xsl:attribute>
        </xsl:if>
        <entry>
            <xsl:call-template name="make-result-organizer" />
        </entry>
    </xsl:template>
    

    <!-- Vital Signs Organizer (Organizer) -->
    <xsl:template name="make-vitalsign-organizer">
        <organizer classCode="CLUSTER" moodCode="EVN">
            <!-- MD: hard code vital signs organizer template 
      <xsl:apply-templates select="." mode="map-resource-to-template" />
      -->
            <templateId root="2.16.840.1.113883.10.20.22.4.26" extension="2015-08-01" />
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- **TODO** change this from hard coded to use what is in fhir? -->
            <code code="46680005" displayName="Vital Signs" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT">
                <translation code="74728-7" displayName="Vital signs, weight, height, head circumference, oximetry, BMI, and BSA panel - HL7.CCDAr1.1" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" />
            </code>
            <statusCode code="completed" />
            <xsl:choose>
                <xsl:when test="fhir:effectiveDateTime">
                    <xsl:apply-templates select="fhir:effectiveDateTime" />
                </xsl:when>
                <xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="fhir:hasMember/fhir:reference">
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="component">
                        <xsl:with-param name="generated-narrative" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:for-each>
        </organizer>
    </xsl:template>

    <!-- Result Organizer (Organizer) -->
    <xsl:template name="make-result-organizer">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />

        <organizer classCode="BATTERY" moodCode="EVN">
            <!-- templateId -->
            <xsl:choose>
                <xsl:when test="$vTriggerExtension">
                    <xsl:apply-templates select="." mode="map-trigger-resource-to-template" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="map-resource-to-template" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="fhir:code">
                <xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
            </xsl:apply-templates>
            <xsl:apply-templates select="fhir:status" mode="map-result-status"/>
            <xsl:choose>
                <!-- effectiveTime in an Organizer is IVL TS and requires both high and low if it is present-->
                <xsl:when test="fhir:effectiveDateTime">
                    <xsl:apply-templates select="fhir:effectiveDateTime" mode="period" />
                </xsl:when>
                <xsl:when test="fhir:effectivePeriod">
                    <xsl:apply-templates select="fhir:effectivePeriod" />
                </xsl:when>
                <!-- effectiveTime is optional in CDA -->
                <!--<xsl:otherwise>
                    <effectiveTime nullFlavor="NI" />
                </xsl:otherwise>-->
            </xsl:choose>
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
            <xsl:for-each select="fhir:result/fhir:reference">
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="component">
                        <xsl:with-param name="generated-narrative" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:for-each>
            <xsl:for-each select="fhir:hasMember/fhir:reference">
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="component">
                        <xsl:with-param name="generated-narrative" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:for-each>
            <!-- If this is eICR and this is a Result Organizer Trigger Code template -->
<!--            <xsl:if test="$vTriggerExtension">-->
                <component>
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' [C-CDA ID] Laboratory Result Status (ID) '" />
                        <templateId root="2.16.840.1.113883.10.20.22.4.418" extension="2018-09-01" />
                        <code code="92235-1" displayName="Laboratory Result Status" codeSystemName="LOINC" codeSystem="2.16.840.1.113883.6.1" />
                        <xsl:apply-templates select="fhir:status" mode="map-lab-status" />
                    </observation>
                </component>
                <xsl:for-each select="fhir:specimen/fhir:reference">
                    <xsl:variable name="referenceURI">
                        <xsl:call-template name="resolve-to-full-url">
                            <xsl:with-param name="referenceURI" select="@value" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                        <xsl:apply-templates select="fhir:resource/fhir:*" mode="component">
                            <xsl:with-param name="generated-narrative" />
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:for-each>
            <!--</xsl:if>-->
        </organizer>
    </xsl:template>

    <!-- Result Organizer (Organizer) (just a wrapper around the observation - no hasMember-->
    <xsl:template name="make-result-organizer-wrapper">
        <!-- Check to see if this is a trigger code template -->
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="check-for-trigger" />
        </xsl:variable>
        <xsl:variable name="vTriggerExtension" select="$vTriggerEntry/fhir:extension" />

        <organizer classCode="BATTERY" moodCode="EVN">

            <!-- templateId -->
            <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.1" />
            <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
            <!--<xsl:choose>
        <xsl:when test="$vTriggerExtension">
          <xsl:apply-templates select="." mode="map-trigger-resource-to-template" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="map-resource-to-template" />
        </xsl:otherwise>
      </xsl:choose>-->
            <!-- this organizer is just a wrapper and has no id of its own -->
            <id root="{lower-case(uuid:get-uuid())}" />
            <!--<xsl:choose>
        <xsl:when test="fhir:identifier">
          <xsl:apply-templates select="fhir:identifier" />
        </xsl:when>
        <xsl:otherwise>
          <id nullFlavor="NI" />
        </xsl:otherwise>
      </xsl:choose>-->
            <xsl:apply-templates select="fhir:code" />
            <!--<xsl:with-param name="pTriggerExtension" select="$vTriggerExtension" />
      </xsl:apply-templates>-->
            <statusCode code="completed" />
            <!-- Put the observation time into a period for the Organizer -->
            <xsl:variable name="vTime">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="fhir:effectiveDateTime/@value" />
                    <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
            </xsl:variable>
            
          
            <xsl:choose>
                <xsl:when test="not($vTime = '')">
                    <effectiveTime>
                <low value="{$vTime}" />
                <high value="{$vTime}" />
            </effectiveTime></xsl:when>
            </xsl:choose>

            <!--<xsl:choose>
        <xsl:when test="fhir:effectiveDateTime">
          <xsl:apply-templates select="fhir:effectiveDateTime" />
        </xsl:when>
        <xsl:when test="fhir:effectivePeriod">
          <xsl:apply-templates select="fhir:effectivePeriod" />
        </xsl:when>
        <xsl:otherwise>
          <effectiveTime nullFlavor="NI" />
        </xsl:otherwise>
      </xsl:choose>-->
            <xsl:apply-templates select="." mode="component" />

        </organizer>
    </xsl:template>

    <!-- Reportability Information Organizer (Relevant Reportable Condition: PlanDefinition) (Organizer) -->
    <xsl:template match="fhir:PlanDefinition[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-plandefinition']" mode="rr">
        <!-- There are as many PlanDefinitions as there are Reportability Information Organizers -->
        <!-- Reportability Information Organizer [1..*] - One for each condition-PHA -->
        <!--Each Plan Definition/Relevant Reportable Condition Observation represents a condition/PHA pair-->
        <entryRelationship typeCode="COMP">
            <organizer classCode="CLUSTER" moodCode="EVN">
                <xsl:comment select="' [RR R1S1] Reportability Information Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.13" extension="2017-04-01" />
                <!-- Location Relevance (home, work, etc.) -->
                <xsl:apply-templates select="fhir:jurisdiction/fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-location-relevance-extension']/fhir:valueCodeableConcept" />
                <statusCode code="completed" />
                <!-- Responsible Agency -->
                <xsl:apply-templates select="fhir:jurisdiction/fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-responsible-agency-organization-extension']" mode="rr" />
                <!-- Rules Authoring Agency -->
                <xsl:apply-templates select="fhir:publisher/fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-rules-authoring-agency-organization-extension']" mode="rr" />
                <!-- Routing Entity -->
                <xsl:apply-templates select="fhir:jurisdiction/fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-routing-entity-organization-extension']" mode="rr" />

                <!-- Determination of Reportability -->
                <component typeCode="COMP">
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' [RR R1S1] Determination of Reportability '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2.3.19" extension="2017-04-01" />
                        <id nullFlavor="NI" />
                        <code code="RR1" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability" />
                        <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-determination-of-reportability-extension']/fhir:valueCodeableConcept">
                            <xsl:with-param name="pElementName" select="'value'" />
                            <xsl:with-param name="pXSIType" select="'CD'" />
                        </xsl:apply-templates>

                        <!-- Determination of Reportability Reason -->
                        <entryRelationship typeCode="RSON">
                            <observation classCode="OBS" moodCode="EVN">
                                <xsl:comment select="' [RR R1S1] Determination of Reportability Reason '" />
                                <templateId root="2.16.840.1.113883.10.20.15.2.3.26" extension="2017-04-01" />
                                <id nullFlavor="NI" />
                                <code code="RR2" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability reason" />
                                <value xsi:type="ST">
                                    <xsl:value-of select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-determination-of-reportability-reason-extension']/fhir:valueString/@value" />
                                </value>
                            </observation>
                        </entryRelationship>

                        <!-- Determination of Reportability Rule -->
                        <entryRelationship typeCode="RSON">
                            <observation classCode="OBS" moodCode="EVN">
                                <xsl:comment select="' [RR R1S1] Determination of Reportability Rule '" />
                                <templateId root="2.16.840.1.113883.10.20.15.2.3.27" extension="2017-04-01" />
                                <id nullFlavor="NI" />
                                <code code="RR3" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Determination of reportability rule" />
                                <value xsi:type="ST">
                                    <xsl:value-of select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-determination-of-reportability-rule-extension']/fhir:valueString/@value" />
                                </value>
                            </observation>
                        </entryRelationship>
                    </observation>
                </component>

                <!-- Reporting Timeframe -->
                <component typeCode="COMP">
                    <observation classCode="OBS" moodCode="EVN">
                        <xsl:comment select="' [RR R1S1] Reporting Timeframe '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2.3.14" extension="2017-04-01" />
                        <id nullFlavor="NI" />
                        <code code="RR4" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Timeframe to report (urgency)" />
                        <xsl:apply-templates select="fhir:action/fhir:timingDuration">
                            <xsl:with-param name="pElementName" select="'value'" />
                            <xsl:with-param name="pIncludeDatatype" select="true()" />
                        </xsl:apply-templates>
                    </observation>
                </component>

                <!-- External Resources -->
                <xsl:for-each select="fhir:action/fhir:documentation">
                    <component typeCode="COMP">
                        <act classCode="ACT" moodCode="EVN">
                            <xsl:comment select="'  [RR R1S1] External Resource  '" />
                            <templateId root="2.16.840.1.113883.10.20.15.2.3.20" extension="2017-04-01" />
                            <id nullFlavor="NI" />
                            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-type-extension']/fhir:valueCodeableConcept" />
                            <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension']/fhir:valueCodeableConcept">
                                <xsl:with-param name="pElementName" select="'priorityCode'" />
                            </xsl:apply-templates>
                            <reference typeCode="REFR">
                                <externalDocument classCode="DOC" moodCode="EVN">
                                    <xsl:comment select="'  [RR R1 STU1] External Reference  '" />
                                    <templateId root="2.16.840.1.113883.10.20.15.2.3.17" extension="2017-04-01" />
                                    <xsl:if test="fhir:display/@value">
                                        <code nullFlavor="OTH">
                                            <originalText>
                                                <xsl:value-of select="fhir:display/@value" />
                                            </originalText>
                                        </code>
                                    </xsl:if>
                                    <xsl:if test="fhir:url/@value">
                                        <text mediaType="text/html">
                                            <reference>
                                                <xsl:attribute name="value">
                                                    <xsl:value-of select="fhir:url/@value" />
                                                </xsl:attribute>
                                            </reference>
                                        </text>
                                    </xsl:if>
                                </externalDocument>
                            </reference>
                        </act>
                    </component>
                </xsl:for-each>
            </organizer>
        </entryRelationship>
    </xsl:template>

    <xsl:template name="make-reportability-response-coded-information-organizer">
        <entry typeCode="DRIV">
            <!-- Reportability Response Coded Information Organizer [1..1] -->
            <organizer classCode="CLUSTER" moodCode="EVN">
                <xsl:comment select="' [RR R1S1] Reportability Response Coded Information Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.34" extension="2017-04-01" />

                <code code="RR11" displayName="Reportability Response Coded Information" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" />
                <statusCode code="completed" />
                <!-- Get all the Relevant Reportable Condition Observations -->
                <xsl:apply-templates select="//fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-observation']" />
                <!--<xsl:for-each select="//fhir:Observaton[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-observation']">
              <!-\- There is one Relevant Reportable Condition Observation for each group (condition) -\->
              <xsl:call-template name="make-relevant-condition-observation" />
          </xsl:for-each>-->


                <!-- Get all the PlanDefinitions in the document and group by condition -->
                <!--<xsl:for-each-group select="//fhir:PlanDefinition[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-plandefinition']"
                    group-by="fhir:goal/fhir:addresses/fhir:coding/fhir:code/@value">
                    <!-\- There is one Relevant Reportable Condition Observation for each group (condition) -\->
                    <xsl:call-template name="make-relevant-condition-observation" />
                </xsl:for-each-group>-->
            </organizer>
        </entry>
    </xsl:template>

    <!-- fhir:item[findings-group] -> (HAI) Findings Organizer -->
    <!--<xsl:template match="//fhir:item[fhir:linkId[@value = 'findings-group']]" mode="findings-organizer">
        <xsl:choose>
            <!-\- Check to see if there's a pathogen identified and a ranking for it.  If not, empty observation
           The way ranking is set up is probably incorrect.  Most likely needs to be nested within the pathogen identified fhir:item -\->
            <xsl:when test="fhir:item[fhir:linkId[@value = 'pathogen-identified']] and fhir:item[fhir:linkId[@value = 'pathogen-ranking']]">
                <organizer classCode="CLUSTER" moodCode="EVN">
                    <!-\- Findings Organizer -\->
                    <templateId root="2.16.840.1.113883.10.20.5.6.182" />
                    <id nullFlavor="NA" />
                    <statusCode code="completed" />
                    <component>
                        <xsl:apply-templates select="fhir:item[fhir:linkId[@value = 'pathogen-identified']]" mode="pathogen-identified" />
                    </component>
                    <component>
                        <xsl:apply-templates select="fhir:item[fhir:linkId[@value = 'pathogen-ranking']]" mode="pathogen-ranking" />
                    </component>
                </organizer>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="no-pathogens-found" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
</xsl:stylesheet>
