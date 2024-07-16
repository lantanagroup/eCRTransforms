<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- ClinicalDocument.serviceEvent will never have a moodCode of INT so this code should never run
         but the FHIR mapping to CarePlan shows that the moodCode must be INT -->
    <xsl:template match="cda:serviceEvent[@moodCode='ÍNT']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:for-each select="cda:performer">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <!-- ClinicalDocument.serviceEvent will never have a moodCode of INT so this code should never run
         but the FHIR mapping to CarePlan shows that the moodCode must be INT-->
    <xsl:template match="cda:serviceEvent[@moodCode='ÍNT']">
        <CarePlan>
            <xsl:call-template name="add-meta" />
            <!-- status -->
            <status value="unknown" />
            <!-- intent -->
            <intent value="plan" />
            <!-- subject -->
            <xsl:call-template name="subject-reference" />
            <!-- author -->
            <!-- get closest author (work up the hierarchy if needed) -->
            <xsl:variable name="vClosestAuthor">
                <xsl:call-template name="get-closest-author" />
            </xsl:variable>
            <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">author</xsl:with-param>
            </xsl:apply-templates>
            <!-- addresses -->
            <xsl:for-each select="//cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]">
                <xsl:comment>INFO: Observation <xsl:value-of select="cda:id/@root" /></xsl:comment>
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">addresses</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <!-- goal -->
            <xsl:for-each select="//cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.121']]">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">goal</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <!-- activity/reference -->
            <xsl:for-each select="//cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.146' or @root = '2.16.840.1.113883.10.20.22.4.131']]">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">activity/reference</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </CarePlan>
    </xsl:template>
</xsl:stylesheet>
