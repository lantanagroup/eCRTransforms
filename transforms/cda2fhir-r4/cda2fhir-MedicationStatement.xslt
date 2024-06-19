<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- Don't want this to match if it is inside a Medications Admin, Admission Meds, Procedures Section -->
    <xsl:template match="
            cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']
            [not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38']) and
            not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44']) and
            not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1'])]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer[cda:assignedEntity]" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant[position() > 1] | cda:performer">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>


    <!-- Don't want this to match if it is inside a Medications Admin, Admission Meds, Procedures Section -->
    <xsl:template match="
            cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'EVN']
            [not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.38']) and
            not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.44']) and
            not(ancestor::*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.7.1'])]">
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
        <MedicationStatement>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <xsl:for-each select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18']]">
                <partOf>
                    <xsl:apply-templates select="." mode="reference" />
                </partOf>
            </xsl:for-each>
            <!-- status -->
            <xsl:apply-templates select="cda:statusCode" mode='map-medication-status'>
                <xsl:with-param name="pMoodCode" select="@moodCode"/>
            </xsl:apply-templates>
            
            <xsl:apply-templates select="cda:consumable" mode="medication-statement" />
            <xsl:call-template name="subject-reference" />
            <dateAsserted value="{lcg:cdaTS2date($dateAsserted)}" />

            <xsl:for-each select="cda:informant[1]">
                <informationSource>
                    <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                </informationSource>
            </xsl:for-each>
            <!--
            <taken value="unk"/>
            -->
            <dosage>
                <timing>
                    <repeat>
                        <xsl:apply-templates select="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-statement" />
                        <xsl:apply-templates select="cda:effectiveTime[@operator = 'A'][@xsi:type = 'PIVL_TS' or @xsi:type = 'EIVL_TS']" mode="medication-statement" />
                    </repeat>
                </timing>
                <xsl:apply-templates select="cda:routeCode">
                    <xsl:with-param name="pElementName">route</xsl:with-param>
                </xsl:apply-templates>

                <xsl:if test="cda:doseQuantity">
                    <doseAndRate>
                        <xsl:apply-templates select="cda:doseQuantity">
                            <xsl:with-param name="pElementName">doseQuantity</xsl:with-param>
                            <xsl:with-param name="pSimpleQuantity" select="true()" />
                        </xsl:apply-templates>
                    </doseAndRate>
                </xsl:if>
            </dosage>
        </MedicationStatement>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-statement">
        <boundsPeriod>
            <xsl:if test="cda:low[not(@nullFlavor)]">
                <start value="{lcg:cdaTS2date(cda:low/@value)}" />
            </xsl:if>
            <xsl:if test="cda:high[not(@nullFlavor)]">
                <end value="{lcg:cdaTS2date(cda:high/@value)}" />
            </xsl:if>
        </boundsPeriod>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A'][@xsi:type = 'PIVL_TS']" mode="medication-statement">
        <xsl:if test="cda:period">
            <period value="{cda:period/@value}" />
            <periodUnit value="{cda:period/@unit}" />
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A']" mode="medication-statement" priority="-1">
        <xsl:comment>Unknown effectiveTime pattern: 
            <cda:effectiveTime>
        <xsl:copy />
      </cda:effectiveTime>
    </xsl:comment>
    </xsl:template>

    <xsl:template match="cda:consumable" mode="medication-statement">
        <medicationCodeableConcept>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <xsl:if test="@displayName">
                        <display value="{@displayName}" />
                    </xsl:if>
                </coding>
            </xsl:for-each>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <xsl:if test="@displayName">
                        <display value="{@displayName}" />
                    </xsl:if>
                </coding>
            </xsl:for-each>
        </medicationCodeableConcept>
    </xsl:template>

</xsl:stylesheet>
