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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3"
  xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org" 
  xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid">
  
  <xsl:import href="fhir2cda-utility.xslt" />
  <xsl:import href="fhir2cda-CD.xslt"/>
  
  <xsl:output method="xml" indent="yes" encoding="UTF-8" />
  
  <xsl:template match="fhir:Communication" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    
    <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
    
    <entry typeCode="DRIV">
      <act classCode="ACT" moodCode="INT">
        <xsl:comment select="' Instruction Activity (V3) '" />
        <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09"/>
        <id nullFlavor="NI" />
        <!-- for now we use Patient Education, in the future we may have other Instruction topic -->
        <code code="311401005" 
              codeSystem="2.16.840.1.113883.6.96" 
              displayName="Patient Education" />
        <text>
          <xsl:value-of select="fhir:payload/fhir:contentString/@value"/>
        </text>
        <statusCode>
          <xsl:attribute name="code">
            <xsl:value-of select="fhir:status/@value"/>
          </xsl:attribute>
        </statusCode>
        <!-- since we want to education the patient we do not want to change the context, 
          so no need to specifiy the <subject>  and <encounter> -->
        
        <!-- use entryRelationship "REFR" to show the general relationship between source and target -->
        <entryRelationship typeCode="REFR">
          <act classCode="ACT" moodCode="INT">
            <xsl:comment select="' Instruction Activity (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09"/>
            <id nullFlavor="NI" />
            <!-- for now we use Patient Education, in the future we may have other Instruction topic -->
            <code code="311401005" 
              codeSystem="2.16.840.1.113883.6.96" 
              displayName="Patient Education" />
            <text>
              <xsl:value-of select="fhir:payload/fhir:contentString/@value"/>
            </text>
            <statusCode>
              <xsl:attribute name="code">
                <xsl:value-of select="fhir:status/@value"/>
              </xsl:attribute>
            </statusCode>
            <xsl:choose>
              <xsl:when test="fhir:sent">
                <effectiveTime>
                  <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                      <xsl:with-param name="date" select="fhir:sent/@value"/>
                      <xsl:with-param name="includeTime" select="true()"/>
                    </xsl:call-template>
                  </xsl:attribute>
                </effectiveTime>
              </xsl:when>
            </xsl:choose>
            <!-- participationInformationGenerator -->
            <participant typeCode="AUT">  
              <xsl:comment select="' participationInformationGenerator '" />
              <!-- <templateId root="2.16.840.1.113883.1.11.10251"/>  --> 
              
              <!-- healthcare provider -->
              <participantRole classCode="PROV">
                <id nullFlavor="NI" />       
              </participantRole>        
            </participant>
          </act>
        </entryRelationship>
        
        <entryRelationship typeCode="REFR">
          <act classCode="ACT" moodCode="INT">
            <xsl:comment select="' Instruction Activity (V3) '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09"/>
            <id nullFlavor="NI" />
            <!-- for now we use Patient Education, in the future we may have other Instruction topic -->
            <code code="311401005" 
              codeSystem="2.16.840.1.113883.6.96" 
              displayName="Patient Education" />
            <text>
              <xsl:value-of select="fhir:payload/fhir:contentString/@value"/>
            </text>
            <statusCode>
              <xsl:attribute name="code">
                <xsl:value-of select="fhir:status/@value"/>
              </xsl:attribute>
            </statusCode>
            <xsl:choose>
              <xsl:when test="fhir:received">
                <effectiveTime>
                  <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                      <xsl:with-param name="date" select="fhir:received/@value"/>
                      <xsl:with-param name="includeTime" select="true()"/>
                    </xsl:call-template>
                  </xsl:attribute>
                </effectiveTime>
              </xsl:when>
            </xsl:choose>
        
            <!-- participationInformationRecipient -->
            <participant typeCode="IRCP"> 
              <xsl:comment select="' participationInformationRecipient '" />
              <!--  <templateId root="2.16.840.1.113883.1.11.10263"/>  -->
              
              <!-- patient -->
              <participantRole classCode="PAT">
                <id nullFlavor="NI" />               
              </participantRole>             
            </participant>
          </act>
        </entryRelationship>       
      </act>
    </entry>
  </xsl:template>
      
  
</xsl:stylesheet>