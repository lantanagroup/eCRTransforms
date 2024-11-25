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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:uuid="http://www.uuid.org"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xhtml uuid">

  <xsl:import href="fhir2cda-utility.xslt" />

  <xsl:output method="xml" indent="yes" encoding="UTF-8" />

  <!-- fhir:section -> cda:section (Generic) -->
  <xsl:template match="fhir:section">
    <xsl:param name="title" />
    <section>
      <!-- SG 20240307: Check to see if this is a section that requires an entry if there is no nullFlavor
                Sections: Emergency Outbreak Information Section, Encounters Section (entries required), Immunizations Section (entries required),
                          Medications Section (entries required), Problem Section (entries required), Procedures Section (entries required), 
                          Reportability Resonse Information Section, Results Section (entries required), Vital Signs Section (entries required)-->
        <xsl:if test="not(fhir:entry) and fhir:code/fhir:coding/fhir:code/@value = ('83910-0', '46240-8', '11369-6', '10160-0', '11450-4', '47519-4', '88085-6', '30954-2', '8716-3')">
            <xsl:attribute name="nullFlavor">NI</xsl:attribute>
        </xsl:if>  
      <xsl:variable name="generated-narrative" select="fhir:text/fhir:status/@value" />
      <!--xsl:apply-templates select="fhir:extension[1]" mode="templateId"/-->
      <!--<xsl:call-template name="section-templates" />-->

      <!-- templateId -->
      <xsl:call-template name="get-template-id" />

      <xsl:apply-templates select="fhir:code" />
      <title>
        <xsl:value-of select="$title" />
      </title>

      <!-- MD: move the <text> from outside <xsl:choose> to inside -->
      <xsl:choose>
        <xsl:when test="fhir:entry">
          <text>
            <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
              <xsl:apply-templates select="fhir:text" mode="narrative" />
            </xsl:if>
          </text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '75310-3'">
              <text>
                <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
                  <xsl:apply-templates select="fhir:text" mode="narrative-footnote" />
                </xsl:if>
              </text>
            </xsl:when>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="fhir:entry">
          <xsl:variable name="sectionCodeforEntry" select="fhir:code/fhir:coding/fhir:code/@value" />
          <xsl:for-each select="fhir:entry">
            <xsl:for-each select="fhir:reference">
              <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                  <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
              </xsl:variable>
              <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
              <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <!-- Process for all entry elements other than Pregnancy Outcome - it's an entryRelationship of Pregnancy Observation in CDA -->
                <xsl:if test="not(fhir:resource/fhir:Observation/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-outcome-observation')">

                  <!-- MD: a procedure can be an entry for procedure section or for medical equipment -->
                  <!-- 
                <xsl:choose>
                  <xsl:when test ="$vMedicalEquipmentSecion=true()">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="entryMedicalEquipment">
                      <xsl:with-param name="generated-narrative" />         
                    </xsl:apply-templates>
                  </xsl:when>
                  <xsl:otherwise>
                   -->
                  <xsl:choose>
                    <xsl:when test="$sectionCodeforEntry = '46264-8'">
                      <!-- MD: a procedure can be an entry for procedure section or for medical equipment -->
                      <xsl:apply-templates select="fhir:resource/fhir:*" mode="entryMedicalEquipment">
                        <xsl:with-param name="generated-narrative" />
                      </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$sectionCodeforEntry = '42346-7'">
                      <!-- MD: Admission Medication Administration is different from Medication Administration -->
                      <xsl:apply-templates select="fhir:resource/fhir:*" mode="entryAdmissionMedication">
                        <xsl:with-param name="generated-narrative" />
                      </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry">
                        <xsl:with-param name="generated-narrative" />
                      </xsl:apply-templates>
                    </xsl:otherwise>
                  </xsl:choose>

                </xsl:if>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="section-no-entry" />
        </xsl:otherwise>
      </xsl:choose>
      <!-- fhir:entry -> get referenced resource entry url and process -->


      <!-- If this is the Social History Section (29762-2) -->
      <xsl:if test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '29762-2'">
        <!-- we need to process Birth Sex and Gender Identity (extensions on fhir Composition) as Observations onto CDA Social history Section-->
        <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex']" mode="entry" />
        
        <!-- MD: eICR using different genderidentity extension -->
        <xsl:choose>
          <xsl:when test="$gvCurrentIg = 'eICR' ">
            <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-genderidentity-extension']" mode="entry"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity']" mode="entry" />
          </xsl:otherwise>
        </xsl:choose>
       
        <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity']" mode="entry" />

        <!-- MD: we need to process tribal affiliation (extension on fhir Patient) as Observation onto CDA Social history Section -->
        <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-tribal-affiliation-extension']" mode="entry" />
      </xsl:if>
    </section>
  </xsl:template>

  <xsl:template name="section-no-entry">

    <xsl:choose>
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '61146-7'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
        <entry>
          <observation classCode="OBS" moodCode="GOL">
            <xsl:comment select="' Goals Observation '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.121" />
            <id nullFlavor="NI" />
            <code nullFlavor="UNK">
              <originalText>
                <xsl:value-of select="fhir:text" />
              </originalText>
            </code>
            <statusCode code="completed" />
          </observation>
        </entry>

      </xsl:when>
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '75310-3'">
        <entry>
          <act classCode="ACT" moodCode="EVN">
            <xsl:comment select="' Health Concern Act '" />
            <templateId root="2.16.840.1.113883.10.20.22.4.132" extension="2015-08-01" />
            <id nullFlavor="NI" />
            <code code="75310-3" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Health Concern" />
            <text>
              <reference value="#HealthConcerns" />
            </text>

            <statusCode code="active" />

          </act>
        </entry>
      </xsl:when>

      <!-- MD: handle Reason for visit Narrative -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '29299-5'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />

          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Review of System Narrative -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '10187-3'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />

          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Chief complaint Narrative -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '10154-3'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>
      
      <!-- MD History of Present illness Narrative -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '10164-2'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Past medical History Narrative -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '11348-0'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Assessment Section (Evaluation Note) -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '51848-0'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Procedure Secion no entry  -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '47519-4'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Insurance Provides Secion no entry  -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '48768-6'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>

      <!-- MD Dental Findings Section no entry  -->
      <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '8704-9'">
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:when>
      
      <!-- SG 20230216: Adding a catch all for these no entry (actually unsure why we have all the above specifically, 
           but I'm sure there is a reason-->
      <xsl:otherwise>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <text>
            <xsl:apply-templates select="fhir:text" mode="narrative-text-no-entries" />
          </text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <!-- fhir:Composition/fhir:encounter -> eICR Encounters Section (Section) -->
  <!-- The Encounters Section for eICR is created from Composition.encounter - there isn't a 
        section in the Composition, so we need to manually create the Section -->
  <xsl:template name="create-eicr-encounters-section">
    <section>
      <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries optional) '" />
      <templateId root="2.16.840.1.113883.10.20.22.2.22" />
      <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries optional) (V3) '" />
      <templateId root="2.16.840.1.113883.10.20.22.2.22" extension="2015-08-01" />
      <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries required) '" />
      <templateId root="2.16.840.1.113883.10.20.22.2.22.1" />
      <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries required) (V3) '" />
      <templateId root="2.16.840.1.113883.10.20.22.2.22.1" extension="2015-08-01" />
      <code code="46240-8" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="History of encounters" />
      <title>Encounters</title>
      <text>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </xsl:if>
      </text>
      <xsl:apply-templates select="." mode="encounter" />
    </section>
  </xsl:template>

  <!-- Create the Reportability Response Subject Section - this is basically just some text -->
  <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '88084-9']]">
    <section>
      <xsl:call-template name="get-template-id">
        <xsl:with-param name="pElementType" select="'section'" />
      </xsl:call-template>
      <code code="88084-9" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Reportable condition response information and summary Document" />
      <text>
        <xsl:apply-templates select="fhir:text" mode="narrative" />
      </text>
      <!-- Create the Reportability Response Subject act -->
      <xsl:apply-templates select="." mode="entry" />
    </section>
  </xsl:template>

  <!-- [RR R1S1] Electronic Initial Case Report Section -->
  <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '88082-3']]">
    <section>
      <!-- templateId -->
      <xsl:call-template name="get-template-id" />

      <code code="88082-3" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Initial case report processing information Document" />
      <xsl:if test="fhir:text">
        <text>
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </text>
      </xsl:if>
      <xsl:apply-templates select="fhir:entry[fhir:reference][fhir:identifier]" mode="rr" />
      <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension']" mode="rr" />
      <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension']" mode="rr" />
    </section>
  </xsl:template>

  <!-- Reportability Response Summary Section -->
  <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code[@value = '55112-7']]">
    <section>
      <xsl:comment select="' [RR R1S1] Reportability Response Summary Section '" />
      <templateId root="2.16.840.1.113883.10.20.15.2.2.2" extension="2017-04-01" />
      <code code="55112-7" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Document Summary" />
      <text>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </xsl:if>
      </text>

      <xsl:apply-templates select="//fhir:Observation[fhir:code/fhir:coding/fhir:code[@value = '304561000']]" mode="rr" />

      <xsl:apply-templates select="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension']" />

      <!-- Create the Reportability Response Coded Information Organizer [1..1] -->
      <xsl:call-template name="make-reportability-response-coded-information-organizer" />
    </section>
  </xsl:template>

  <!-- HAI Questionnaire Response processing
  This uses the questionnaire-mapping.xml file (used in fhir2cda-ClinicalDocument)-->
  <!--<xsl:template match="fhir:item" mode="section">
    <xsl:param name="pSectionEntries" />
    <xsl:param name="pSectionEntryRelationships" />
    
    <!-\- Get the link id for this section -\->
    <xsl:variable name="vSectionLinkId" select="fhir:linkId/@value" />
    <section>
      <!-\- templateId -\->
      <xsl:call-template name="get-template-id" />
      <code>
        <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire/fhir:item[fhir:linkId/@value = $vSectionLinkId]/fhir:code" />
      </code>
      <!-\- title -\->
      <xsl:apply-templates select="." mode="map-to-title" />

      <text>We will generate the text using the HAI transform in the second phase of processing - this ensures we get the correct text in the correct section</text>

      <xsl:if test="//fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event'">
        <xsl:if test="$vSectionLinkId = 'event-details'">
          <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'event-type'][fhir:answer]" />
        </xsl:if>

        <xsl:apply-templates select="fhir:item[fhir:answer]" />

        <xsl:if test="$vSectionLinkId = 'event-details'">
          <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'inborn-outborn-observation'][fhir:answer]" />
        </xsl:if>
      </xsl:if>

      <!-\- SG 20220210: HAI LTC -\->
      <!-\- SG 20220209: Iterate through the entries for this section (entries determined by checking questionnaire-mapping.xml in fhir2cda-ClinicalDocument.xml -\->
      <xsl:for-each select="$pSectionEntries">
        <xsl:variable name="vLinkId" select="fhir:linkId/@value"/>
        <!-\- Grab the entryRelationship linkIds for this entry and put into variable -\->
        <xsl:variable name="vEntryRelationshipLinkIds" select="$questionnaire-mapping/fhir:map[@parent = $vLinkId][@type = 'entryRelationship']/@linkId" />
        
        <!-\- Get any matching entryRelationship items and put into variable -\->
        <xsl:variable name="vEntryRelationships" select="$pSectionEntryRelationships/.[fhir:linkId/@value = $vEntryRelationshipLinkIds]" />
        <entry typeCode="DRIV">
          <xsl:apply-templates select="." >
            <xsl:with-param name="pEntryRelationships" select="$vEntryRelationships"/>
          </xsl:apply-templates>
        </entry>
      </xsl:for-each>
    </section>
  </xsl:template>-->

  <!-- (HAI) Infection Details Section (Section) -->
  <!--<xsl:template name="infection-details-section">
    <section>
      <templateId root="2.16.840.1.113883.10.20.5.4.26" />
      <!-\- [HAI R3D3] Infection Details in Late Onset Sepsis Report -\->
      <templateId root="2.16.840.1.113883.10.20.5.5.64" extension="2018-04-01" />
      <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" code="51899-3" displayName="Details" />
      <title>Details Section</title>
      <!-\- **TODO** Let's generate the text using the HAI transform - otherwise there is no way to separate the text into sections -\->
      <text>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </xsl:if>
      </text>
      <xsl:for-each select="//fhir:item[fhir:linkId/@value = 'event-type']">
        <entry typeCode="DRIV">
          <xsl:apply-templates select="." mode="infection" />
        </entry>
      </xsl:for-each>
      <xsl:for-each select="//fhir:item[fhir:linkId[@value = 'inborn-outborn-observation']]">
        <entry typeCode="DRIV">
          <xsl:apply-templates select="." mode="inborn" />
        </entry>
      </xsl:for-each>
      <xsl:for-each select="//fhir:item[fhir:linkId[@value = 'died']]">
        <entry typeCode="DRIV">
          <xsl:apply-templates select="." mode="death" />
        </entry>
      </xsl:for-each>
    </section>
  </xsl:template>-->

  <!-- (HAI) Risk Factors Section (Section) -->
  <!--<xsl:template name="risk-factors-section">
    <section>
      <templateId root="2.16.840.1.113883.10.20.5.4.26" />
      <!-\- [HAI R3D3] Risk Factors Section (LOS/Men) -\->
      <templateId root="2.16.840.1.113883.10.20.5.5.65" extension="2018-04-01" />
      <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" code="51898-5" displayName="Risk Factors" />
      <title>Risk Factors</title>
      <!-\- **TODO** Let's generate the text using the HAI transform - otherwise there is no way to separate the text into sections -\->
      <text>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </xsl:if>
      </text>
      <xsl:for-each select="//fhir:item[fhir:linkId[@value = 'risk-factor-central-line']]">
        <entry>
          <xsl:apply-templates select="." mode="risk-observation" />
        </entry>
      </xsl:for-each>
      <xsl:for-each select="//fhir:item[fhir:linkId[@value = 'risk-factor-birth-weight']]">
        <entry>
          <xsl:apply-templates select="." mode="measurement-observation" />
        </entry>
      </xsl:for-each>
      <xsl:for-each select="//fhir:item[fhir:linkId[@value = 'risk-factor-gestational-age']]">
        <entry>
          <xsl:apply-templates select="." mode="gestational-age" />
        </entry>
      </xsl:for-each>
    </section>
  </xsl:template>-->

  <!-- (HAI) Findings Section in an Infection-Type Report (Section) -->
  <!--<xsl:template name="findings-section">
    <section>
      <templateId root="2.16.840.1.113883.10.20.5.5.45" />
      <code code="18769-0" codeSystem="2.16.840.1.113883.6.1" displayName="Findings Section" />
      <title>Findings</title>
      <!-\- **TODO** Let's generate the text using the HAI transform - otherwise there is no way to separate the text into sections -\->
      <text>
        <xsl:if test="normalize-space(fhir:text/xhtml:div/xhtml:div[@class = 'custom']) != 'No information.'">
          <xsl:apply-templates select="fhir:text" mode="narrative" />
        </xsl:if>
      </text>
      <xsl:choose>
        <!-\- Check to see if a finding's group exists. If it doesn't, create an empty observation entry -\->
        <xsl:when test="//fhir:item[fhir:linkId[@value = 'findings-group']]">
          <entry>
            <xsl:apply-templates select="//fhir:item[fhir:linkId[@value = 'findings-group']]" mode="findings-organizer" />
          </entry>
        </xsl:when>
        <xsl:otherwise>
          <entry>
            <xsl:call-template name="no-pathogens-found" />
          </entry>
        </xsl:otherwise>
      </xsl:choose>

    </section>
  </xsl:template>-->

</xsl:stylesheet>
