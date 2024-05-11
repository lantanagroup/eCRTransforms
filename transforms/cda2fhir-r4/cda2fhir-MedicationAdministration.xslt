<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- Match if this is a substanceAdministration inside a Medication Administered, Admission Medication, or Procedures section -->
    <xsl:template match="
            cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']
            [ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38'] or
            ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44'] or
            ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />

        <!-- If this substanceAdministration is inside a Procedure, create a Medication for later reference in the Procedure -->
        <xsl:apply-templates select="
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']] |
                cda:consumable[../../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]" mode="bundle-entry" />
    </xsl:template>

    <!-- SubstanceAdministration inside an Admission Medication -->
    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN'][ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44']]">
        <xsl:variable name="dateAsserted">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::cda:*/cda:author/cda:time/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:author/cda:time/@value][1]/cda:author/cda:time/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/@value][1]/cda:effectiveTime/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/cda:low/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/cda:low/@value][1]/cda:effectiveTime/cda:low/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/cda:ClinicalDocument/cda:effectiveTime/@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <MedicationAdministration>
            <xsl:call-template name="add-meta" />
            <!-- Therapeutic Response to Medication -->
            <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
            <xsl:apply-templates select="cda:id" />
            <status value="completed" />

            <xsl:apply-templates select="cda:consumable" mode="medication-administration" />

            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>
            <xsl:for-each select="cda:performer">
                <performer>
                    <actor>
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </actor>
                </performer>
            </xsl:for-each>
            <!--<dosage>
                <xsl:apply-templates select="cda:routeCode">
                    <xsl:with-param name="pElementName">route</xsl:with-param>
                </xsl:apply-templates>

                <xsl:apply-templates select="cda:approachSiteCode">
                    <xsl:with-param name="pElementName">method</xsl:with-param>
                </xsl:apply-templates>

                <xsl:apply-templates select="cda:doseQuantity">
                    <xsl:with-param name="pElementName">dose</xsl:with-param>
                    <xsl:with-param name="pSimpleQuantity" select="true()" />
                </xsl:apply-templates>
            </dosage>-->
            <xsl:call-template name="get-dosage" />
        </MedicationAdministration>
    </xsl:template>

    <!-- Match if this is a substanceAdministration inside a Medication Administered or Procedures section -->
    <xsl:template match="
            cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']
            [ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38'] or ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1']]">
        <xsl:variable name="dateAsserted">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::cda:*/cda:author/cda:time/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:author/cda:time/@value][1]/cda:author/cda:time/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/@value][1]/cda:effectiveTime/@value" />
                </xsl:when>
                <xsl:when test="ancestor-or-self::cda:*/cda:effectiveTime/cda:low/@value">
                    <xsl:value-of select="ancestor-or-self::cda:*[cda:effectiveTime/cda:low/@value][1]/cda:effectiveTime/cda:low/@value" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/cda:ClinicalDocument/cda:effectiveTime/@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <MedicationAdministration>
            <xsl:call-template name="add-meta" />
            <!-- Therapeutic Response to Medication -->
            <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension" />
            <xsl:apply-templates select="cda:id" />

            <!-- partOf: if this is contained in a procedure or substanceAdministration, reference that -->
            <xsl:if test="
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12'] or
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14'] or
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13'] or
                    parent::cda:*/parent::cda:*/parent::cda:*/cda:substanceAdministration">
                <partOf>
                    <reference value="urn:uuid:{parent::cda:*/parent::cda:*/@lcg:uuid}" />
                </partOf>
            </xsl:if>

            <status value="completed" />
            <!-- If this is inside a Procedure we want to reference a medication here rather than have a medicationCodeableConcept so we can reference it from the Procedure -->
            <xsl:choose>
                <xsl:when test="ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1']">
                    <medicationReference>
                        <reference value="urn:uuid:{cda:consumable/cda:manufacturedProduct/@lcg:uuid}" />
                    </medicationReference>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:consumable" mode="medication-administration">
                        <xsl:with-param name="pElementName">medicationCodeableConcept</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="subject-reference" />

            <!-- supportingInformation: anything in an entryRelationship that isn't already mapped -->
            <xsl:for-each select="
                    cda:entryRelationship/cda:*[
                    not(cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37') and
                    not(cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19')]">
                <supportingInformation>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </supportingInformation>
            </xsl:for-each>

            <!-- Doesn't make any sense to have a repeat instruction inside a MedicationAdministration 
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

            <xsl:call-template name="get-dosage" />
        </MedicationAdministration>
    </xsl:template>

    <xsl:template name="get-dosage">
        <xsl:choose>
            <xsl:when test="cda:routeCode/@code or cda:doseQuantity/@value or cda:approachSiteCode/@code">
                <dosage>
                    <xsl:apply-templates select="cda:approachSiteCode">
                        <xsl:with-param name="pElementName">site</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:routeCode">
                        <xsl:with-param name="pElementName">route</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:doseQuantity">
                        <xsl:with-param name="pElementName">dose</xsl:with-param>
                        <xsl:with-param name="pSimpleQuantity" select="true()" />
                    </xsl:apply-templates>
                </dosage>
            </xsl:when>
            <xsl:when test="not(cda:routeCode) and not(cda:approachSiteCode) and not(cda:doseQuantity)" />
            <xsl:when test="cda:doseQuanity/@nullFlavor and not(cda:routeCode) and not(cda:approachSiteCode)">
                <dosage>
                    <xsl:apply-templates select="cda:doseQuantity/@nullFlavor" mode="data-absent-reason-extension" />
                </dosage>
            </xsl:when>
            <xsl:when test="cda:routeCode/@nullFlavor and cda:approachSiteCode/@nullFlavor">
                <dosage>
                    <site>
                        <xsl:apply-templates select="cda:approachSiteCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </site>
                    <route>
                        <xsl:apply-templates select="cda:routeCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </route>
                </dosage>
            </xsl:when>
            <xsl:when test="cda:routeCode/@nullFlavor">
                <dosage>
                    <route>
                        <xsl:apply-templates select="cda:routeCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </route>
                </dosage>
            </xsl:when>
            <xsl:when test="cda:approachSiteCode/@nullFlavor">
                <dosage>
                    <site>
                        <xsl:apply-templates select="cda:approachSiteCode/@nullFlavor" mode="data-absent-reason-extension" />
                    </site>
                </dosage>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-administration">
        <xsl:element name="effectiveDateTime">
            <xsl:choose>
                <xsl:when test="@value">
                    <xsl:attribute name="value" select="lcg:cdaTS2date(@value)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="cda:low[not(@nullFlavor)]">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high[not(@nullFlavor)]">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

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
