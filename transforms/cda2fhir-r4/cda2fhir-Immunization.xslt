<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.52'][@moodCode = 'EVN']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.52'][@moodCode = 'EVN']">
        <Immunization>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />

            <xsl:choose>
                <xsl:when test="@negationInd = 'true'">
                    <status value="not-done" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:statusCode" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- statusReason: C-CDA Immunization Refusal Reason (2.16.840.1.113883.10.20.22.4.53) -->
            <xsl:if test="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.53']">
                <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.53']/cda:code">
                    <xsl:with-param name="pElementName">statusReason</xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="cda:consumable" mode="immunization" />

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName">occurrenceDateTime</xsl:with-param>
            </xsl:apply-templates>

            <xsl:comment>Defaulting primarySource to false since this info is not in the C-CDA Immunization Activity template</xsl:comment>
            <primarySource value="false" />
            <xsl:for-each select="cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:lotNumberText/@value">
                <lotNumber value="{.}" />
            </xsl:for-each>
            <xsl:apply-templates select="cda:routeCode">
                <xsl:with-param name="pElementName">route</xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:doseQuantity">
                <xsl:with-param name="pElementName">doseQuantity</xsl:with-param>
                <xsl:with-param name="pSimpleQuantity" select="true()" />
            </xsl:apply-templates>
            <xsl:if test="cda:performer">
                <performer>
                    <xsl:call-template name="performer-reference">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:call-template>
                </performer>
            </xsl:if>
            
            <!-- reasonReference (C-CDA Indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>

            <!-- reaction -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']">
                <reaction>
                    <detail>
                        <reference value="urn:uuid:{@lcg:uuid}" />
                    </detail>
                </reaction>
            </xsl:for-each>
        </Immunization>
    </xsl:template>

    <xsl:template match="cda:consumable" mode="immunization">
        <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">vaccineCode</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
