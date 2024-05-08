<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns="http://hl7.org/fhir" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" 
    xmlns:fhir="http://hl7.org/fhir" 
    xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml"
    version="2.0">
    
    <xsl:import href="c-to-fhir-utility.xslt"/>

    <!-- Don't want the eCR serviceEvent that is just about a manually initiated eCR -->
    <xsl:template match="cda:serviceEvent[not(cda:code[@code = 'PHC1464'])]" mode="bundle-entry">
        <xsl:comment>Creating CarePlan Bundle Entry</xsl:comment>
        <xsl:call-template name="create-bundle-entry"/>
        <xsl:for-each select="cda:performer">
            <xsl:apply-templates select="." mode="bundle-entry"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Don't want the eCR serviceEvent that is just about a manually initiated eCR -->
    <xsl:template match="cda:serviceEvent[not(cda:code[@code = 'PHC1464'])]">
        <CarePlan>
            <xsl:call-template name="add-meta"/>
            <status value="unknown"/>
            <intent value="plan"/>
            <xsl:call-template name="subject-reference"/>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">author</xsl:with-param>
            </xsl:call-template>
            <xsl:for-each select="//cda:observation[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.4']]">
                <xsl:comment>Observation <xsl:value-of select="cda:id/@root"/></xsl:comment>
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">addresses</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:for-each select="//cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.121']]">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">goal</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:for-each select="//cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.146' or @root = '2.16.840.1.113883.10.20.22.4.131']]">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">activity/reference</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>

        </CarePlan>
    </xsl:template>

    
</xsl:stylesheet>
