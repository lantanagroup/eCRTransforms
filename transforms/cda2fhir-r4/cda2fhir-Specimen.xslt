<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0" xmlns="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Specimen Collection Procedure -> FHIR Specimen -->
    <xsl:template match="cda:organizer/cda:component/cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.415']] | cda:organizer/cda:component/cda:procedure[cda:code[@code = '17636008']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:organizer/cda:component/cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.415']] | cda:organizer/cda:component/cda:procedure[cda:code[@code = '17636008']]">
        <Specimen xmlns="http://hl7.org/fhir" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <xsl:call-template name="add-meta" />
            <!-- id -->
            <xsl:apply-templates select="cda:participant/cda:participantRole/cda:id" />
            <!-- status -->
            <xsl:apply-templates select="cda:statusCode" mode="map-specimen-status" />
            <!-- type -->
            <xsl:apply-templates select="cda:participant/cda:participantRole/cda:playingEntity/cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            <!-- receivedTime - this is an IHE template -->
            <xsl:if test="cda:entryRelationship/cda:act/cda:templateId[@root='1.3.6.1.4.1.19376.1.3.1.3']">
                <xsl:apply-templates select="cda:entryRelationship/cda:act[cda:templateId/@root='1.3.6.1.4.1.19376.1.3.1.3']/cda:effectiveTime" mode="instant">
                    <xsl:with-param name="pElementName" select="'receivedTime'" />
                </xsl:apply-templates>
            </xsl:if>
            <!-- collection -->
            <xsl:if test="cda:effectiveTime or cda:targetSiteCode">
                <collection>
                    <!-- collected -->
                    <xsl:apply-templates select="cda:effectiveTime">
                        <xsl:with-param name="pStartElementName" select="'collected'" />
                    </xsl:apply-templates>
                    <!-- bodySite -->
                    <xsl:apply-templates select="cda:targetSiteCode">
                        <xsl:with-param name="pElementName" select="'bodySite'" />
                    </xsl:apply-templates>
                </collection>
            </xsl:if>
            <!-- condition -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.421']]/cda:value">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="pElementName">condition</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </Specimen>
    </xsl:template>

</xsl:stylesheet>
