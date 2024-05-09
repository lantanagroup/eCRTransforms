<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.146' or @root = '2.16.840.1.113883.10.20.22.4.131']][not(@nullFlavor)]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:for-each select="cda:entryRelationship">
            <xsl:apply-templates select="cda:*" mode="bundle-entry">
                <xsl:with-param name="listEntry">true</xsl:with-param>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.146' or @root = '2.16.840.1.113883.10.20.22.4.131']]">
        <xsl:call-template name="create-request-group" />
    </xsl:template>

    <xsl:template name="create-request-group">
        <RequestGroup xmlns="http://hl7.org/fhir">
            <!--
            <id value="{@lcg:uuid}"/>
            -->
            <xsl:apply-templates select="cda:id" />
            <!-- A status of completed indicates that this is a past intervention and a status of active indicates that this is a planned intervention -->
            <xsl:choose>
                <xsl:when test="@moodCode = 'EVN' and cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.131'">
                    <status value="completed" />
                </xsl:when>
                <xsl:when test="@moodCode = 'INT' and cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.146'">
                    <status value="active" />
                </xsl:when>
            </xsl:choose>
            <intent value="plan" />
            <xsl:if test="cda:effectiveTime">
                <xsl:choose>
                    <xsl:when test="cda:effectiveTime/@value">
                        <authoredOn value="{lcg:cdaTS2date(cda:effectiveTime/@value)}" />
                    </xsl:when>
                    <xsl:when test="cda:effectiveTime/cda:high/@value">
                        <authoredOn value="{lcg:cdaTS2date(cda:effectiveTime/cda:high/@value)}" />
                    </xsl:when>
                    <xsl:when test="cda:effectiveTime/cda:low/@value">
                        <authoredOn value="{lcg:cdaTS2date(cda:effectiveTime/cda:low/@value)}" />
                    </xsl:when>
                    <xsl:when test="cda:effectiveTime/cda:center/@value">
                        <authoredOn value="{lcg:cdaTS2date(cda:effectiveTime/cda:center/@value)}" />
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <!-- TODO: move Goal to RequestGroup.reason and remove as an action -->
            <!-- RG: Commented out for demo -->
            <!--
            <xsl:for-each select="cda:entryRelationship[@typeCode='RSON'][cda:*[not(@nullFlavor)]]">
                <xsl:apply-templates select="cda:*" mode="reference">
                    <xsl:with-param name="wrapping-elements">reasonReference</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            -->
            <!-- RG: Commented out for demo -->
            <!--
            <xsl:for-each select="cda:entryRelationship[not(@typeCode='RSON')][cda:*[not(@nullFlavor)]]">
                <xsl:for-each select="cda:*">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="wrapping-elements">action/resource</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:if test="local-name(.)='substanceAdministration'">
                        <xsl:for-each select="cda:entryRelationship/cda:supply">
                            <xsl:apply-templates select="." mode="reference">
                                <xsl:with-param name="wrapping-elements">action/resource</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
            -->
        </RequestGroup>
    </xsl:template>

</xsl:stylesheet>
