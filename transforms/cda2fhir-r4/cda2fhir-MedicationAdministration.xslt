<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <!-- Match if this is a substanceAdministration inside a Medication Administered, Admission Medication, or Procedures section, or Medications Section -->
  <!--<xsl:template match="
            cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']
            [ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38'] or
            ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44'] or
            ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1'] or
            ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.1.1']]" mode="bundle-entry">-->

  <!-- Match all substanceAdministration with moodCode of 'EVN' - this is an evoloving mapping in the C-CDA to FHIR project - will update when that group has decided on mapping -->
  <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']" mode="bundle-entry">

    <xsl:call-template name="create-bundle-entry" />

    <xsl:apply-templates select="cda:author" mode="bundle-entry" />
    <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
    <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

    <xsl:for-each select="cda:author | cda:informant">
      <xsl:apply-templates select="." mode="provenance" />
    </xsl:for-each>

    <xsl:apply-templates select="cda:consumable/cda:manufacturedProduct" mode="bundle-entry" />

    <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />

    <!--<!-\- If this substanceAdministration is inside a Procedure, create a Medication for later reference in the Procedure -\->
        <xsl:apply-templates select="
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']] |
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]" mode="bundle-entry" />-->
  </xsl:template>

  <!-- SubstanceAdministration inside an Admission Medication -->
  <!-- 20260729 Claude: added explicit priority so this specific template beats the generalized one below -->
  <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN'][ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44']]" priority="2">
    <!-- 20260729 Claude: removed unused $dateAsserted variable (computed but never referenced; dateAsserted is a
         MedicationStatement element, not MedicationAdministration) -->
    <MedicationAdministration>
      <xsl:call-template name="add-meta" />
      <!-- Therapeutic Response to Medication -->
      <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
      <xsl:apply-templates select="cda:id" />
      <!-- status -->
      <xsl:apply-templates select="cda:statusCode" mode="map-medication-status">
        <xsl:with-param name="pMoodCode" select="@moodCode" />
        <xsl:with-param name="pMedicationResource" select="'MedicationAdministration'" />
      </xsl:apply-templates>

      <!--<xsl:apply-templates select="cda:consumable" mode="medication-administration" />-->

      <xsl:for-each select="cda:consumable/cda:manufacturedProduct">
        <medicationReference>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </medicationReference>
      </xsl:for-each>

      <xsl:call-template name="subject-reference" />

      <!-- Doesn't make sense to have a repeat instruction inside a MedicationAdministration 
           If there is an effectiveTime with operator='A', treat as either period or an instant
           Also there can only be one effective[x] in a MedicationAdministration so just take the first one-->
      <xsl:choose>
        <xsl:when test="cda:effectiveTime[1]/cda:low or cda:effectiveTime[1]/cda:high">
          <xsl:apply-templates select="cda:effectiveTime[1]" mode="period">
            <xsl:with-param name="pElementName">effectivePeriod</xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="cda:effectiveTime[1]" mode="instant">
            <xsl:with-param name="pElementName">effectiveDateTime</xsl:with-param>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>

      <!--<xsl:apply-templates select="cda:effectiveTime">
        <xsl:with-param name="pStartElementName">effective</xsl:with-param>
      </xsl:apply-templates>-->

      <xsl:for-each select="cda:performer">
        <performer>
          <actor>
            <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
          </actor>
        </performer>
      </xsl:for-each>

      <!-- reasonReference (C-CDA Indication) -->
      <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
        <reasonReference>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </reasonReference>
      </xsl:for-each>

      <xsl:call-template name="get-dosage" />
    </MedicationAdministration>
  </xsl:template>

  <!-- 20260729 Claude: Fix - this body template was restricted to the Medications Administered / Procedures /
       Medications sections, so a 4.16 EVN Medication Activity anywhere else got a bundle entry (the bundle-entry
       match above is unrestricted) but only a fallback resource body. Section predicate removed; the Admission
       Medication template above keeps its own handling via priority -->
  <xsl:template
    match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']" priority="1">
    <!-- 20260729 Claude: removed unused $dateAsserted variable (computed but never referenced; dateAsserted is a
         MedicationStatement element, not MedicationAdministration) -->
    <MedicationAdministration>
      <xsl:call-template name="add-meta" />
      <!-- Therapeutic Response to Medication -->
      <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
      <xsl:apply-templates select="cda:id" />

      <!-- partOf: if this is contained in a procedure or substanceAdministration, reference that -->
      <xsl:if
        test="parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12'] or parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14'] or parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13'] or parent::cda:*/parent::cda:*/parent::cda:*/cda:substanceAdministration">
        <partOf>
          <reference value="urn:uuid:{parent::cda:*/parent::cda:*/@lcg:uuid}" />
        </partOf>
      </xsl:if>

      <!-- status -->
      <xsl:apply-templates select="cda:statusCode" mode="map-medication-status">
        <xsl:with-param name="pMoodCode" select="@moodCode" />
        <xsl:with-param name="pMedicationResource" select="'MedicationAdministration'" />
      </xsl:apply-templates>

      <xsl:for-each select="cda:consumable/cda:manufacturedProduct">
        <medicationReference>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </medicationReference>
      </xsl:for-each>

      <xsl:call-template name="subject-reference" />

      <!-- supportingInformation: anything in an entryRelationship that isn't already mapped -->
      <!-- 20260803 Claude (item 45/CDAFHIR-020): also skip null-flavored and suppressed children -
           the bundle-entry side drops both, so referencing them dangles (same rule as item 40/41). -->
      <xsl:for-each
        select="cda:entryRelationship/cda:*[not(@nullFlavor)][not(cda:templateId[key('templates-to-suppress-key', @root)])][not(cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37') and not(cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19') and not(cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.118')]">
        <supportingInformation>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </supportingInformation>
      </xsl:for-each>

      <!-- Doesn't make sense to have a repeat instruction inside a MedicationAdministration 
                 If there is an effectiveTime with operator='A', treat as either period or an instant
                 Also there can only be one effective[x] in a MedicationAdministration so just take the first one-->
      <xsl:choose>
        <xsl:when test="cda:effectiveTime[1]/cda:low or cda:effectiveTime[1]/cda:high">
          <xsl:apply-templates select="cda:effectiveTime[1]" mode="period">
            <xsl:with-param name="pElementName">effectivePeriod</xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="cda:effectiveTime[1]" mode="instant">
            <xsl:with-param name="pElementName">effectiveDateTime</xsl:with-param>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:for-each select="cda:performer">
        <performer>
          <actor>
            <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
          </actor>
        </performer>
      </xsl:for-each>

      <!-- reasonReference (C-CDA Indication) -->
      <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
        <reasonReference>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </reasonReference>
      </xsl:for-each>

      <xsl:for-each select="cda:text">
        <xsl:variable name="vText">
          <xsl:choose>
            <xsl:when test="cda:reference">
              <xsl:call-template name="get-reference-text">
                <xsl:with-param name="pTextElement" select="." />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="." />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="string-length($vText) > 0">
          <note>
            <text>
              <xsl:attribute name="value" select="$vText" />
            </text>
          </note>
        </xsl:if>
      </xsl:for-each>
      <xsl:call-template name="get-dosage" />
    </MedicationAdministration>
  </xsl:template>

  <xsl:template name="get-dosage">
    <xsl:if test="cda:routeCode[not(@nullFlavor) or cda:translation] or cda:doseQuantity[not(@nullFlavor)] or cda:approachSiteCode[not(@nullFlavor)] or cda:rateQuantity[not(@nullFlavor)]">
      <dosage>
        <xsl:apply-templates select="cda:approachSiteCode[not(@nullFlavor)]">
          <xsl:with-param name="pElementName">site</xsl:with-param>
        </xsl:apply-templates>
        <xsl:choose>
          <xsl:when test="cda:routeCode[not(@nullFlavor)]">
            <xsl:apply-templates select="cda:routeCode[not(@nullFlavor)]">
              <xsl:with-param name="pElementName">route</xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="cda:routeCode[@nullFlavor and cda:translation]">
            <xsl:apply-templates select="cda:routeCode/cda:translation">
              <xsl:with-param name="pElementName">route</xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="cda:routeCode">
              <xsl:with-param name="pElementName">route</xsl:with-param>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="cda:doseQuantity[not(@nullFlavor)]">
          <xsl:with-param name="pElementName">dose</xsl:with-param>
          <xsl:with-param name="pSimpleQuantity" select="true()" />
        </xsl:apply-templates>
        <xsl:apply-templates select="cda:rateQuantity[not(@nullFlavor)]">
          <xsl:with-param name="pElementName">rateQuantity</xsl:with-param>
          <xsl:with-param name="pSimpleQuantity" select="true()" />
        </xsl:apply-templates>
      </dosage>
    </xsl:if>
  </xsl:template>

  <!-- 20260729 Claude: removed dead template cda:effectiveTime[IVL_TS] mode="medication-administration" - never
       invoked (and it emitted start/end children inside an effectiveDateTime element, which would have been invalid) -->

  <!-- 20260729 Claude: NOTE - this template's only caller is commented out (line ~50, replaced by medicationReference);
       kept in case the inline-CodeableConcept option is wanted again -->
  <xsl:template match="cda:consumable" mode="medication-administration">
    <medicationCodeableConcept>
      <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
        <xsl:variable name="vCode" select="@code" />
        <coding>
          <system>
            <xsl:attribute name="value">
              <xsl:call-template name="convertOID">
                <xsl:with-param name="oid" select="@codeSystem" />
              </xsl:call-template>
            </xsl:attribute>
          </system>
          <code value="{@code}" />
          <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this 
                        isn't going to catch everything, but will clean up testing errors -->
          <xsl:choose>
            <xsl:when test="$code-display-mapping/map[@code = $vCode]">
              <display>
                <xsl:attribute name="value">
                  <xsl:value-of select="$code-display-mapping/map[@code = $vCode]/@display" />
                </xsl:attribute>
              </display>
            </xsl:when>
            <xsl:when test="@displayName">
              <display value="{@displayName}" />
            </xsl:when>
          </xsl:choose>
        </coding>
      </xsl:for-each>
      <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
        <xsl:variable name="vTranslationCode" select="@code" />
        <coding>
          <system>
            <xsl:attribute name="value">
              <xsl:call-template name="convertOID">
                <xsl:with-param name="oid" select="@codeSystem" />
              </xsl:call-template>
            </xsl:attribute>
          </system>
          <code value="{@code}" />
          <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this 
                        isn't going to catch everything, but will clean up testing errors -->
          <xsl:choose>
            <xsl:when test="$code-display-mapping/map[@code = $vTranslationCode]">
              <display>
                <xsl:attribute name="value">
                  <xsl:value-of select="$code-display-mapping/map[@code = $vTranslationCode]/@display" />
                </xsl:attribute>
              </display>
            </xsl:when>
            <xsl:when test="@displayName">
              <display value="{@displayName}" />
            </xsl:when>
          </xsl:choose>
        </coding>
      </xsl:for-each>
      <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@nullFlavor]">
        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
      </xsl:for-each>
    </medicationCodeableConcept>
  </xsl:template>

</xsl:stylesheet>
