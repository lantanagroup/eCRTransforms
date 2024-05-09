<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:participant" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500']]">

        <CareTeam>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />

            <xsl:choose>
                <xsl:when test="cda:statusCode/@code = 'active'">
                    <status value="active" />
                </xsl:when>
            </xsl:choose>

            <xsl:call-template name="subject-reference" />

            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">period</xsl:with-param>
            </xsl:apply-templates>
            <!-- Care Team Member Act -->
            <xsl:for-each select="cda:component/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500.1']]">
                <participant>
                    <xsl:apply-templates select="cda:performer/sdtc:functionCode">
                        <xsl:with-param name="pElementName">role</xsl:with-param>
                    </xsl:apply-templates>
                    <member>
                        <xsl:apply-templates select="cda:performer/cda:assignedEntity" mode="reference" />
                    </member>
                    <xsl:if test="cda:performer/cda:representedOrganization">
                        <onBehalfOf>
                            <xsl:apply-templates select="cda:performer/cda:assignedEntity/cda:representedOrganization" mode="reference" />
                        </onBehalfOf>
                    </xsl:if>
                    <xsl:apply-templates select="cda:effectiveTime" mode="period">
                        <xsl:with-param name="pElementName">period</xsl:with-param>
                    </xsl:apply-templates>
                </participant>
            </xsl:for-each>
        </CareTeam>
    </xsl:template>

</xsl:stylesheet>
