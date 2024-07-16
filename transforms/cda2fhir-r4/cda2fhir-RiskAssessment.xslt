<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:uuid="http://www.uuid.org" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.136']]">
        <xsl:param name="condition" required="yes" />
        <xsl:if test="$condition">
            <xsl:call-template name="create-risk">
                <xsl:with-param name="condition" select="$condition" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="create-risk">
        <xsl:param name="condition" />
        <RiskAssessment>
            <!--
            <id value="{@lcg:uuid}"/>
            -->
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:if test="cda:effectiveTime">
                <xsl:choose>
                    <xsl:when test="@nullFlavor">
                        <xsl:comment>INFO: null effectiveTime</xsl:comment>
                    </xsl:when>
                    <xsl:when test="cda:effectiveTime/@value">
                        <xsl:apply-templates select="." mode="instant">
                            <xsl:with-param name="pElementName">occuranceDateTime</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <occurencePeriod>
                            <xsl:if test="cda:effectiveTime/cda:low/@value">
                                <start value="{lcg:cdaTS2date(cda:effectiveTime/cda:low/@value)}" />
                            </xsl:if>
                            <xsl:if test="cda:effectiveTime/cda:high/@value">
                                <end value="{lcg:cdaTS2date(cda:effectiveTime/cda:high/@value)}" />
                            </xsl:if>
                        </occurencePeriod>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <condition>
                <xsl:apply-templates select="$condition" mode="reference" />
            </condition>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">performer</xsl:with-param>
            </xsl:call-template>
        </RiskAssessment>
    </xsl:template>

</xsl:stylesheet>
