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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="lcg xsl cda fhir">

  <xsl:import href="fhir2cda-TS.xslt" />
  <xsl:import href="fhir2cda-CD.xslt" />
  <xsl:import href="fhir2cda-utility.xslt" />
  <xsl:import href="fhir2cda-Observation.xslt" />

  <!-- ALLERGY INTOLERANCE -->
  <xsl:template match="fhir:AllergyIntolerance" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <entry>
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="make-allergyintolerance" />
    </entry>
  </xsl:template>

  <!-- (PCP) Health Concern Act (Pharmacist Care Plan) (Act) -->
  <xsl:template name="make-allergyintolerance">
    <xsl:variable name="no-known-allergy">
      <xsl:choose>
        <!-- All children of 716186003, no known allergy -->
        <xsl:when
          test="fhir:code/fhir:coding/fhir:system/@value = 'http://snomed.info/sct' and (fhir:code/fhir:coding/fhir:code/@value = '716186003' or fhir:code/fhir:coding/fhir:code/@value = '716220001' or fhir:code/fhir:coding/fhir:code/@value = '428197003' or fhir:code/fhir:coding/fhir:code/@value = '409137002' or fhir:code/fhir:coding/fhir:code/@value = '428607008' or fhir:code/fhir:coding/fhir:code/@value = '429625007' or fhir:code/fhir:coding/fhir:code/@value = '716184000')">
          <xsl:text>true</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <!--<xsl:variable name="vCurrentIg">
      <xsl:choose>
        <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition'">eICR</xsl:when>
        <xsl:when test="//fhir:Communication/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-communication'">RR</xsl:when>
        <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Care-Plan'">PCP</xsl:when>
        <!-\- Not sure if we will need to distinguish between HAI, HAI LTCF, single person, summary - for now, putting them all in the same bucket-\->
        <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-single-person-report-questionnaireresponse'">HAI</xsl:when>
        <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-population-summary-questionnaireresponse'">HAI</xsl:when>
        <!-\- MD: Add dental data exchange IG -\->
        <xsl:when test="
            //fhir:Composition/fhir:meta/fhir:profile/@value =
            'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-referral-note'">DentalReferalNote</xsl:when>
        <xsl:when test="
            //fhir:Composition/fhir:meta/fhir:profile/@value =
            'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-consult-note'">DentalConsultNote</xsl:when>
        <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '57134-9'">DentalReferalNote</xsl:when>
        <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '34756-7'">DentalConsultNote</xsl:when>
      </xsl:choose>
    </xsl:variable>-->
    <act classCode="ACT" moodCode="EVN">
      <xsl:choose>
        <xsl:when test="$gvCurrentIg eq 'DentalConsultNote' or $gvCurrentIg eq 'DentalReferalNote'">
          <templateId root="2.16.840.1.113883.10.20.22.4.30" extension="2015-08-01" />
          <id nullFlavor="NI" />
          <code code="CONC" codeSystem="2.16.840.1.113883.5.6" />
          <statusCode code="active" />
          <xsl:choose>
            <xsl:when test="fhir:onsetDateTime">
              <effectiveTime>
                <low>
                  <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                      <xsl:with-param name="date" select="fhir:onsetDateTime/@value" />
                      <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                  </xsl:attribute>
                </low>
              </effectiveTime>
            </xsl:when>
            <xsl:otherwise>
              <effectiveTime>
                <low nullFlavor="NI" />
              </effectiveTime>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:when>
        <xsl:otherwise>
          <!-- [C-CDA R2.1] Health Concern Act (V2) -->
          <templateId root="2.16.840.1.113883.10.20.22.4.132" extension="2015-08-01" />
          <!-- [PCP R1 STU1] Health Concern Act (Pharmacist Care Plan) -->
          <templateId root="2.16.840.1.113883.10.20.37.3.8" extension="2017-08-01" />
          <id nullFlavor="NI" />
          <code code="75310-3" codeSystem="2.16.840.1.113883.6.1" displayName="Health Concern" codeSystemName="LOINC" />
          <statusCode code="active" />
          <!-- <entryRelationship typeCode="REFR">          -->
        </xsl:otherwise>
      </xsl:choose>
      <entryRelationship typeCode="SUBJ">
        <observation classCode="OBS" moodCode="EVN">
          <xsl:if test="$no-known-allergy = 'true'">
            <xsl:attribute name="negationInd">true</xsl:attribute>
          </xsl:if>
          <!-- [C-CDA R2.0] Allergy - Intolerance Observation (V2) -->
          <templateId root="2.16.840.1.113883.10.20.22.4.7" extension="2014-06-09" />
          <xsl:call-template name="get-id" />
          <code code="ASSERTION" codeSystem="2.16.840.1.113883.5.4" />
          <statusCode code="completed" />

          <xsl:if test="fhir:assertedDate">
            <effectiveTime>
              <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                  <xsl:with-param name="date" select="fhir:assertedDate/@value" />
                  <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
              </xsl:attribute>
            </effectiveTime>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="fhir:onsetDateTime">
              <effectiveTime>
                <low>
                  <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                      <xsl:with-param name="date" select="fhir:onsetDateTime/@value" />
                      <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                  </xsl:attribute>
                </low>
              </effectiveTime>
            </xsl:when>
            <xsl:when test="fhir:assertedDate">
              <effectiveTime>
                <low>
                  <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                      <xsl:with-param name="date" select="fhir:assertedDate/@value" />
                      <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                  </xsl:attribute>
                </low>
              </effectiveTime>
            </xsl:when>
            <xsl:otherwise>
              <effectiveTime>
                <low nullFlavor="NI" />
              </effectiveTime>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test="fhir:code/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/cda-negated-code'">
              <!--TODO: Replace line below with code from extension http://hl7.org/fhir/StructureDefinition/cda-negated-code-->
              <value xsi:type="CD" code="419199007" codeSystem="2.16.840.1.113883.6.96" displayName="Allergy to Substance" codeSystemName="SNOMED" />
            </xsl:when>
            <xsl:otherwise>
              <value xsi:type="CD" code="419199007" codeSystem="2.16.840.1.113883.6.96" displayName="Allergy to Substance" codeSystemName="SNOMED" />
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test="$no-known-allergy = 'true'">
              <participant typeCode="CSM">
                <participantRole classCode="MANU">
                  <playingEntity classCode="MMAT">
                    <code nullFlavor="NI" />
                  </playingEntity>
                </participantRole>
              </participant>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="fhir:code">
                <participant typeCode="CSM">
                  <participantRole classCode="MANU">
                    <playingEntity classCode="MMAT">
                        <xsl:apply-templates select="."/>
<!--                      <xsl:call-template name="CodeableConcept2CD" />-->
                    </playingEntity>
                  </participantRole>
                </participant>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </observation>
      </entryRelationship>
    </act>
  </xsl:template>

  <!-- fhir:Condition -> (Generic) Concern wrapper on Condition (Act) -->
  <xsl:template match="fhir:Condition" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
    <entry>
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="fhir:category/fhir:coding/fhir:code/@value = 'CONC'">
          <xsl:call-template name="make-problem-concern-act" />
        </xsl:when>
        <xsl:when test="fhir:category/fhir:coding/fhir:code/@value = '75310-3'">
          <xsl:call-template name="make-health-concern-act" />
        </xsl:when>
        <xsl:when test="$gvCurrentIg = 'PCP'">
          <xsl:call-template name="make-health-concern-act" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="make-problem-concern-act" />
        </xsl:otherwise>
      </xsl:choose>
      <!-- 
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'PCP'">
                    <xsl:call-template name="make-health-concern-act" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="make-problem-concern-act" />
                </xsl:otherwise>
            </xsl:choose>  -->
    </entry>
  </xsl:template>

  <!-- fhir:Condition -> (Generic) Condition processing (Encounter or Observation) -->
  <xsl:template match="fhir:Condition" mode="entry-relationship">
    <xsl:param name="pTypeCode" select="'COMP'" />
    <entryRelationship typeCode="{$pTypeCode}">
      <xsl:choose>
        <xsl:when test="fhir:category/fhir:coding/fhir:code/@value = 'encounter-diagnosis'">
          <xsl:call-template name="make-encounter-diagnosis" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="make-problem-observation" />
        </xsl:otherwise>
      </xsl:choose>
    </entryRelationship>
  </xsl:template>

  <!-- (PCP) Health Concern Act (Pharmacist Care Plan) -->
  <xsl:template name="make-health-concern-act">
    <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
    <!--<xsl:variable name="gvCurrentIg">
      <xsl:choose>
        <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition'">eICR</xsl:when>
        <xsl:when test="//fhir:Communication/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-communication'">RR</xsl:when>
        <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Care-Plan'">PCP</xsl:when>
        <!-\- Not sure if we will need to distinguish between HAI, HAI LTCF, single person, summary - for now, putting them all in the same bucket-\->
        <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-single-person-report-questionnaireresponse'">HAI</xsl:when>
        <xsl:when test="//fhir:QuestionnaireReponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-population-summary-questionnaireresponse'">HAI</xsl:when>
      </xsl:choose>
    </xsl:variable>-->
    <xsl:if test="fhir:category/@value = 'encounter-diagnosis'"> </xsl:if>

    <act classCode="ACT" moodCode="EVN">
      <xsl:comment select="' [C-CDA R2.1] Health Concern Act (V2) '" />
      <templateId root="2.16.840.1.113883.10.20.22.4.132" extension="2015-08-01" />
      <xsl:if test="$gvCurrentIg = 'PCP'">
        <xsl:comment select="' Health Concern Act (Pharmacist Care Plan) '" />
        <templateId root="2.16.840.1.113883.10.20.37.3.8" extension="2017-08-01" />
      </xsl:if>
      <id nullFlavor="NI" />
      <code code="75310-3" codeSystem="2.16.840.1.113883.6.1" displayName="Health Concern" codeSystemName="LOINC" />
      <statusCode code="active" />
      <entryRelationship typeCode="REFR">
        <xsl:call-template name="make-problem-observation" />
      </entryRelationship>
    </act>
  </xsl:template>

  <!-- (C-CDA) Problem Concern Act (Act) -->
  <xsl:template name="make-problem-concern-act">
    <act classCode="ACT" moodCode="EVN">
      <xsl:comment select="' [C-CDA 1.1] Problem Concern Act '" />
      <templateId root="2.16.840.1.113883.10.20.22.4.3" />
      <xsl:comment select="' [C-CDA 2.1] Problem Concern Act (V3) '" />
      <templateId root="2.16.840.1.113883.10.20.22.4.3" extension="2015-08-01" />
      <id nullFlavor="NI" />
      <code code="CONC" codeSystem="2.16.840.1.113883.5.6" displayName="Concern" />
      <statusCode code="active" />
      <effectiveTime>
        <xsl:choose>
          <xsl:when test="fhir:onsetDateTime/@value">
            <low>
              <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                  <xsl:with-param name="date" select="fhir:onsetDateTime/@value" />
                  <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
              </xsl:attribute>
            </low>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="nullFlavor">NI</xsl:attribute>
            <low nullFlavor="NI" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="fhir:abatementDateTime">
          <high>
            <xsl:attribute name="value">
              <xsl:call-template name="Date2TS">
                <xsl:with-param name="date" select="fhir:abatementDateTime/@value" />
                <xsl:with-param name="includeTime" select="true()" />
              </xsl:call-template>
            </xsl:attribute>
          </high>
        </xsl:if>
      </effectiveTime>
      <entryRelationship typeCode="SUBJ">
        <xsl:call-template name="make-problem-observation" />
      </entryRelationship>
    </act>
  </xsl:template>

  <!-- (C-CDA) Encounter Diagnosis (Act) -->
  <xsl:template name="make-encounter-diagnosis">
    <act classCode="ACT" moodCode="EVN">
      <xsl:comment select="' [C-CDA R1.1] Encounter Diagnosis '" />
      <templateId root="2.16.840.1.113883.10.20.22.4.80" />
      <xsl:comment select="' [C-CDA R2.1] Encounter Diagnosis (V3) '" />
      <templateId root="2.16.840.1.113883.10.20.22.4.80" extension="2015-08-01" />
      <code code="29308-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Diagnosis" />
      <entryRelationship typeCode="SUBJ">
        <xsl:call-template name="make-problem-observation" />
      </entryRelationship>
    </act>
  </xsl:template>

  <!-- GOAL -->
  <xsl:template match="fhir:Goal" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <entry>
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="make-goal" />
    </entry>
  </xsl:template>

  <xsl:template match="fhir:Goal" mode="entry-relationship">
    <entryRelationship typeCode="RSON">
      <act classCode="ACT" moodCode="EVN">
        <!-- [C-CDA R2.0] Entry Reference -->
        <templateId root="2.16.840.1.113883.10.20.22.4.122" />
        <xsl:call-template name="get-id" />
        <code nullFlavor="NP" />
        <statusCode code="completed" />
      </act>
    </entryRelationship>
  </xsl:template>

  <!-- Goal Observation -->
  <xsl:template name="make-goal">
    <observation classCode="OBS" moodCode="GOL">
      <!-- [C-CDA R2.0] Goal Observation -->
      <templateId root="2.16.840.1.113883.10.20.22.4.121" />
      
      <xsl:call-template name="get-id" />
      <xsl:for-each select="fhir:description">
          <xsl:apply-templates select="."/>
      </xsl:for-each>

      <xsl:apply-templates select="fhir:status" mode="goal" />
      <xsl:apply-templates select="fhir:lifecycleStatus" mode="goal" />

      <xsl:if test="fhir:outcomeReference">
        <xsl:variable name="ref">
          <xsl:value-of select="fhir:outcomeReference/fhir:reference/@value" />
        </xsl:variable>
        <effectiveTime>
          <low>
            <xsl:attribute name="value">
              <xsl:call-template name="Date2TS">
                <xsl:with-param name="date" select="//fhir:entry[fhir:fullUrl[@value = $ref]]/fhir:resource/fhir:Observation/fhir:effectiveDateTime/@value" />
                <xsl:with-param name="includeTime" select="true()" />
              </xsl:call-template>
            </xsl:attribute>
          </low>
        </effectiveTime>
      </xsl:if>
      <xsl:apply-templates select="fhir:subject" />
      <xsl:apply-templates select="fhir:expressedBy" />

      <!-- fhir:entry/fhir:item -> get referenced resource entry url and process-->
      <xsl:for-each select="fhir:entry/fhir:item">
        <xsl:for-each select="fhir:reference">
          <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
              <xsl:with-param name="referenceURI" select="@value" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry-relationship">
              <xsl:with-param name="typeCode">REFR</xsl:with-param>
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </observation>
  </xsl:template>

  <!-- Goal/statusCode -->
  <xsl:template match="fhir:status | fhir:lifecycleStatus" mode="goal">
    <!-- TODO: actually map the status codes, not always the same between CDA and FHIR -->
    <!-- TODO: the status might be better pulled from the outcome observation -->
    <xsl:choose>
      <xsl:when test="@value = 'in-progress'">
        <statusCode code="active" />
      </xsl:when>
      <xsl:otherwise>
        <statusCode code="{@value}" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- fhir:expressedBy[parent::fhir:Goal] -> get referenced resource entry url and process -->
  <xsl:template match="fhir:expressedBy[parent::fhir:Goal]">
    <xsl:for-each select="fhir:reference">
      <xsl:variable name="referenceURI">
        <xsl:call-template name="resolve-to-full-url">
          <xsl:with-param name="referenceURI" select="@value" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
        <xsl:variable name="author-time">
          <xsl:choose>
            <xsl:when test="parent::fhir:assertedDate/@value">
              <xsl:call-template name="Date2TS">
                <xsl:with-param name="date" select="//parent::fhir:assertedDate/@value" />
                <xsl:with-param name="includeTime" select="true()" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="Date2TS">
                <xsl:with-param name="date" select="//fhir:Composition[1]/fhir:date/@value" />
                <xsl:with-param name="includeTime" select="true()" />
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="fhir:resource/fhir:*" mode="author">
          <xsl:with-param name="author-time" select="$author-time" />
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- INTERVENTION -->
  <xsl:template match="fhir:List[fhir:code/fhir:coding[fhir:system/@value = 'http://snomed.info/sct'][fhir:code/@value = '362956003']]" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <!--TODO: replace match with profile id when available-->
    <entry>
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>

      <xsl:call-template name="make-intervention-list" />
    </entry>
  </xsl:template>

  <xsl:template match="fhir:RequestGroup" mode="entry">
    <xsl:param name="generated-narrative">additional</xsl:param>
    <!--TODO: replace match with profile id when available-->
    <entry>
      <xsl:if test="$generated-narrative = 'generated'">
        <xsl:attribute name="typeCode">DRIV</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="make-intervention-request" />
    </entry>
  </xsl:template>

  <!-- (PCP) Planned Intervention Act (Pharmacist Care Plan) (Act) -->
  <!-- **TODO** refactor - this should have a name specific to PCP as it's not generic -->
  <xsl:template name="make-intervention-request">
    <xsl:param name="time">
      <xsl:call-template name="Date2TS">
        <xsl:with-param name="date" select="fhir:authoredOn/@value" />
        <xsl:with-param name="includeTime" select="true()" />
      </xsl:call-template>
    </xsl:param>
    <act classCode="ACT" moodCode="INT">
      <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.146" />
      <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.12" />
      <xsl:call-template name="get-id" />
      <code code="362956003" displayName="Intervention" codeSystemName="SNOMED" codeSystem="2.16.840.1.113883.6.96" />
      <statusCode code="active" />
      <xsl:if test="fhir:authoredOn">
        <effectiveTime value="{$time}" />
      </xsl:if>
      <xsl:choose>
        <xsl:when test="fhir:reasonReference">
          <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
              <xsl:with-param name="referenceURI" select="fhir:reasonReference/fhir:reference/@value" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry-relationship" />
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <entryRelationship typeCode="RSON">
            <act classCode="ACT" moodCode="EVN" nullFlavor="RSON">
              <templateId root="2.16.840.1.113883.10.20.22.4.122" />
              <id nullFlavor="NI" />
              <code nullFlavor="NI" />
              <statusCode code="completed" />
            </act>
          </entryRelationship>
        </xsl:otherwise>
      </xsl:choose>
      <!-- fhir:action/fhir/resource -> get referenced resource entry url and process -->
      <xsl:for-each select="fhir:action/fhir:resource">
        <xsl:if test="fhir:reference">
          <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
              <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="@value" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
              <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry-relationship">
                <xsl:with-param name="typeCode">REFR</xsl:with-param>
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </act>
  </xsl:template>

  <!-- (PCP) Intervention Act (Pharmacist Care Plan) (Act) -->
  <!-- **TODO** refactor - this should have a name specific to PCP as it's not generic -->
  <xsl:template name="make-intervention-list">
    <xsl:param name="time">
      <xsl:call-template name="Date2TS">
        <xsl:with-param name="date" select="fhir:date/@value" />
        <xsl:with-param name="includeTime" select="true()" />
      </xsl:call-template>
    </xsl:param>
    <act classCode="ACT" moodCode="EVN">
      <templateId extension="2015-08-01" root="2.16.840.1.113883.10.20.22.4.131" />
      <templateId extension="2017-08-01" root="2.16.840.1.113883.10.20.37.3.15" />
      <xsl:call-template name="get-id" />
      <code code="362956003" displayName="Procedure/intervention" codeSystemName="SNOMED" codeSystem="2.16.840.1.113883.6.96" />
      <statusCode code="completed" />
      <effectiveTime value="{$time}" />
      <!-- fhir:entry/fhir:item -> get referenced resource entry url and process -->
      <xsl:for-each select="fhir:entry/fhir:item">
        <xsl:for-each select="fhir:reference">
          <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
              <xsl:with-param name="referenceURI" select="@value" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
            <xsl:apply-templates select="fhir:resource/fhir:*" mode="entry-relationship">
              <xsl:with-param name="typeCode">REFR</xsl:with-param>
            </xsl:apply-templates>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </act>
  </xsl:template>

  <!-- fhir: -> Received eICR Information (Act) -->
  <!--  <xsl:template match="fhir:entry[fhir:reference][fhir:identifier]" mode="rr">-->
  <xsl:template match="fhir:entry[fhir:reference][fhir:identifier][preceding-sibling::fhir:code/fhir:coding/fhir:code/@value = '88082-3']" mode="rr">
    <xsl:variable name="referenceURI">
      <xsl:call-template name="resolve-to-full-url">
        <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
      </xsl:call-template>
    </xsl:variable>
    <!-- This reference can be to a DocumentReference or a Bundle -->
    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:DocumentReference">
      <entry>
        <act classCode="ACT" moodCode="EVN">
          <!-- templateId -->
          <xsl:comment select="' [RR R1S1] Received eICR Information '" />
          <templateId root="2.16.840.1.113883.10.20.15.2.3.9" extension="2017-04-01" />
          <xsl:call-template name="get-id" />
          <code code="RR5" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Received eICR Information" />
          <text xsi:type="ST">
            <xsl:value-of select="fhir:display/@value" />
          </text>
          <statusCode code="completed" />
          <!-- eICR Receipt Time (effectiveTime) -->
          <xsl:apply-templates select="//fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-receipt-time-extension']/fhir:valueDateTime" />
          <!-- eICR External Document Reference (External Document) -->
          <xsl:variable name="vIdentifier" select="fhir:identifier" />
          <xsl:apply-templates select="//fhir:DocumentReference[fhir:masterIdentifier = $vIdentifier]" mode="reference" />
        </act>
      </entry>
    </xsl:for-each>


    <!--<xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Bundle">
            <entry>
                <act classCode="ACT" moodCode="EVN">
                    <!-\- templateId -\->
                    <xsl:call-template name="get-template-id" />
                    <xsl:call-template name="get-id" />
                    <code code="RR5" codeSystem="2.16.840.1.114222.4.5.232" codeSystemName="PHIN Questions" displayName="Received eICR Information" />
                    <text xsi:type="ST">
                        <xsl:value-of select="fhir:display/@value" />
                    </text>
                    <statusCode code="completed" />
                    <!-\- eICR Receipt Time (effectiveTime) -\->
                    <xsl:apply-templates select="preceding-sibling::*[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-receipt-time-extension']/fhir:valueDateTime" />
                    <!-\- eICR External Document Reference (External Document) -\->
                    <xsl:variable name="vIdentifier" select="fhir:identifier" />
                    <xsl:apply-templates select="//fhir:DocumentReference[fhir:masterIdentifier = $vIdentifier]" mode="reference" />
                </act>
            </entry>
        </xsl:for-each>-->
  </xsl:template>

  <!-- TODO -->
  <!-- //fhir:Observation[fhir:code/fhir:coding/fhir:code[@value='304561000']] -> Reportability Response Summary (Act) -->
  <xsl:template match="//fhir:Observation[fhir:code/fhir:coding/fhir:code[@value = '304561000']]" mode="rr">
    <entry typeCode="DRIV">
      <act classCode="ACT" moodCode="INT">
        <xsl:call-template name="get-template-id" />
        <xsl:call-template name="get-id">
          <xsl:with-param name="pNoNullAllowed" select="true()" />
        </xsl:call-template>
        <code code="304561000" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Informing health care professional (procedure)" />
        <text>
          <xsl:value-of select="fhir:valueString/@value" />
        </text>
        <statusCode code="completed" />
      </act>
    </entry>
  </xsl:template>

  <!-- fhir:section.text -> Reportability Response Subject (Act) -->
  <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code/@value = '88084-9']" mode="entry">
    <entry typeCode="DRIV">
      <act classCode="ACT" moodCode="INT">
        <!-- [C-CDA R2.1] Instruction (V2) -->
        <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09" />
        <!-- [RR R1S1] Reportability Response Subject -->
        <templateId root="2.16.840.1.113883.10.20.15.2.3.7" extension="2017-04-01" />
        <xsl:call-template name="get-id">
          <xsl:with-param name="pNoNullAllowed" select="true()" />
        </xsl:call-template>
        <code code="131195008" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" displayName="Subject of information" />
        <text>
          <xsl:value-of select="fhir:text" />
        </text>
        <statusCode code="completed" />
      </act>
    </entry>
  </xsl:template>

  <!-- fhir:extension[eICRProcessingStatus] -> eICR Processing Status - Resolve Reference (Act) -->
  <xsl:template match="fhir:extension[@url = 'eICRProcessingStatus']" mode="rr">
    <xsl:variable name="referenceURI">
      <xsl:call-template name="resolve-to-full-url">
        <xsl:with-param name="referenceURI" select="fhir:valueReference/fhir:reference/@value" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
      <xsl:apply-templates select="fhir:resource/fhir:*" mode="rr" />
    </xsl:for-each>
  </xsl:template>

  <!-- fhir:Observation[rr-eicr-processing-status-observation] -> eICR Processing Status (Act) -->
  <xsl:template match="fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-observation']" mode="rr">
    <entry>
      <act classCode="ACT" moodCode="EVN">
        <xsl:call-template name="get-template-id" />
        <xsl:apply-templates select="fhir:code" />

        <!-- eICR processing status reason -->
        <xsl:for-each select="fhir:hasMember">
          <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
              <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
            </xsl:call-template>
          </xsl:variable>

          <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
            <xsl:apply-templates select="fhir:resource/fhir:*" mode="rr" />
          </xsl:for-each>
        </xsl:for-each>

        <!-- fhir:extension[eICRValidationOutput] -> (RR) eICR Validation Output (Observaton) -->
        <xsl:apply-templates select="//fhir:extension[@url = 'eICRValidationOutput']" mode="rr" />
      </act>
    </entry>
  </xsl:template>

  <!-- fhir:Observation[us-ph-travel-history/travel-history] -> Travel History (Act) -->
    <xsl:template match="fhir:Observation[fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-travel-history']|fhir:Observation[fhir:code/fhir:coding/fhir:code/@value = '420008001']" mode="entry" priority="5">
    <entry>
      <act classCode="ACT" moodCode="EVN">
        <!-- templateId -->
        <xsl:call-template name="get-template-id" />
        <!-- id -->
        <xsl:call-template name="get-id" />
        <!-- code -->
        <xsl:apply-templates select="fhir:code" />
        <!-- text -->
        <!-- statusCode -->
        <xsl:apply-templates select="fhir:status" />
        <!-- effectiveTime -->
        <xsl:choose>
          <xsl:when test="fhir:effectiveDateTime | fhir:effectivePeriod | fhir:effectiveTime | fhir:effectiveInstant">
            <xsl:apply-templates select="fhir:effectiveDateTime | fhir:effectivePeriod | fhir:effectiveTime | fhir:effectiveInstant" />
          </xsl:when>
          <xsl:otherwise>
            <effectiveTime nullFlavor="NI" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:for-each select="fhir:component">
          <xsl:choose>
            <!-- These are participants not entryRelationships -->
            <xsl:when test="fhir:code/fhir:coding/fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-ParticipationType'">
              <participant typeCode="{fhir:code/fhir:coding/fhir:code/@value}">
                <participantRole classCode="TERR">
                  <xsl:choose>
                    <xsl:when test="fhir:extension/@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-address-extension'">
                      <xsl:apply-templates select="fhir:extension/fhir:valueAddress" />
                    </xsl:when>
                    <xsl:when test="fhir:valueCodeableConcept">
                      <xsl:apply-templates select="fhir:valueCodeableConcept" />
                    </xsl:when>
                  </xsl:choose>
                </participantRole>
              </participant>
            </xsl:when>
            <xsl:otherwise>
              <entryRelationship>
                <xsl:attribute name="typeCode" select="'COMP'" />
                <xsl:apply-templates select="." />
              </entryRelationship>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </act>
    </entry>
  </xsl:template>

  <!-- fhir:extension[eicr-initiation-type-extension] -> RR eICR Initiation Type (Act) -->
  <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension']" mode="rr">
    <entry>
      <act classCode="ACT" moodCode="EVN">
        <xsl:call-template name="get-template-id" />
        <xsl:call-template name="get-id" />
        <xsl:apply-templates select="fhir:valueCodeableConcept" />
      </act>
    </entry>
  </xsl:template>

  <!-- HAI LTC -->
  <xsl:template
    match="fhir:item[fhir:linkId/@value = ('no-lab-id-event-mrsa', 'no-lab-id-event-mssa', 'no-lab-id-event-vre', 'no-lab-id-event-cephr-klebsiella', 'no-lab-id-event-mrsa-cre-e-coli', 'no-lab-id-event-mrsa-cre-enterobacter', 'no-lab-id-event-cre-klebsiella', 'no-lab-id-event-mdr-acinetobacter', 'no-lab-id-event-c-difficile')]">
    <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
    <xsl:if test="fhir:answer/fhir:valueBoolean/@value = 'true'">
      <act classCode="ACT" moodCode="EVN">
        <xsl:call-template name="get-template-id" />
        <code>
          <xsl:apply-templates select="$gvHaiQuestionnaire/fhir:Questionnaire//fhir:item[fhir:linkId/@value = $vLinkId]/fhir:code" />
        </code>
      </act>
    </xsl:if>
  </xsl:template>

  <xsl:template match="fhir:item[fhir:linkId/@value = 'nhsn-comment']">
    <xsl:variable name="vLinkId" select="fhir:linkId/@value" />
    <act classCode="ACT" moodCode="EVN">
      <xsl:comment select="' [HAI R3D2] NHSN Comment '" />
      <templateId root="2.16.840.1.113883.10.20.5.6.243" extension="2017-04-01" />
      <code>
        <xsl:apply-templates select="$questionnaire-mapping/fhir:map[@linkId = $vLinkId][@type='entry']/fhir:coding" />
      </code>
      <text>
        <xsl:value-of select="fhir:answer/fhir:valueString/@value" />
      </text>
    </act>
  </xsl:template>

</xsl:stylesheet>
