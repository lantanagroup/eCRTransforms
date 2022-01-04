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
        <xsl:apply-templates select="fhir:type" />
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
      <id root="{lower-case(uuid:get-uuid())}"/>
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
      <xsl:for-each-group select="//fhir:ServiceRequest/fhir:encounter/fhir:reference"
        group-by="@value">
        <xsl:variable name="vTest" select="@value"/>
        <entry>
          <encounter moodCode="INT" classCode="ENC">
            <xsl:comment select="' Planned  Encounter V2 '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.40" extension="2014-06-09"/>
            <!-- <templateId root="2.16.840.1.113883.11.20.9.23" extension="2014-09-01"/> -->
            <id root="{lower-case(uuid:get-uuid())}"/>
            
            <xsl:variable name="referenceURI">
              <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" 
                  select="@value" />
                <!--  select="//fhir:ServiceRequest/fhir:encounterfhir/fhir:reference/@value" />-->
              </xsl:call-template>
            </xsl:variable>
            <xsl:comment>Processing entry <xsl:value-of select="$referenceURI"/></xsl:comment>
            <xsl:variable name="vTest" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]"/>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
              <xsl:apply-templates select="fhir:resource/fhir:*" mode="serviceRequest"/>
            </xsl:for-each> 
            
          </encounter>
          
        </entry>
        
      </xsl:for-each-group>
    </section>
   
  </xsl:template>
  
  <xsl:template match="fhir:Encounter" mode="serviceRequest">
    <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
    
    <code>
      <xsl:apply-templates select="fhir:class" />
      <xsl:for-each select="fhir:type">
        <xsl:apply-templates select=".">
          <xsl:with-param name="pElementName" select="'translation'" />
        </xsl:apply-templates>
      </xsl:for-each>  
    </code>
    
    <statusCode>
      <xsl:attribute name="code" select="fhir:status/@value"/>
    </statusCode>
    
    <effectiveTime>
      <xsl:attribute name="value">
        <xsl:call-template name="Date2TS">
          <xsl:with-param name="date" select="fhir:period/fhir:start/@value"/>
          <xsl:with-param name="includeTime" select="true()"/>
        </xsl:call-template>
      </xsl:attribute>
    </effectiveTime>
    
    <priorityCode>
      <xsl:attribute name="code">
        <xsl:value-of select="fhir:priority/fhir:coding/fhir:code/@value"/> 
      </xsl:attribute>    
      <xsl:variable name="vCodeSystemUri" select="fhir:priority/fhir:coding/fhir:system/@value"/>                    
      <xsl:choose>
        <xsl:when test="$mapping/map[@uri=$vCodeSystemUri]">
          <xsl:attribute name="codeSystem">
            <xsl:value-of select="$mapping/map[@uri=$vCodeSystemUri][1]/@oid"/> 
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>    
      <xsl:apply-templates select="fhir:priority/fhir:coding/fhir:display" mode="display"/>    
    </priorityCode>   
  </xsl:template>
   
</xsl:stylesheet>
