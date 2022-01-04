<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">


    <xsl:import href="c-to-fhir-utility.xslt"/>

    <xsl:template
        match="cda:act[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
    </xsl:template>

    <xsl:template
        match="cda:procedure[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
    </xsl:template>

    <xsl:template
        match="cda:observation[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
    </xsl:template>

    <xsl:template
        match="cda:act[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id"/>
            <xsl:apply-templates select="cda:statusCode" mode="procedure"/>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference"/>
            <xsl:choose>
                <xsl:when
                    test="cda:effectiveTime/@nullFlavor and ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.131']]">
                    <xsl:apply-templates select="ancestor::cda:act/cda:effectiveTime" mode="period">
                        <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:effectiveTime" mode="period">
                        <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:call-template>
            <!-- RG: Commented out for demo -->
            <!--
            <xsl:if test="cda:performer">
                <performer>
                    <xsl:call-template name="performer-reference">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:call-template>
                </performer>
            </xsl:if>
            -->
        </Procedure>
    </xsl:template>

    <xsl:template
        match="cda:procedure[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id"/>
            <xsl:apply-templates select="cda:statusCode" mode="procedure"/>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference"/>
            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:call-template>
            
            <!-- MD: Add BodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>
                
            <!-- RG: Commented out for demo -->
            <!--
            <xsl:if test="cda:performer">
                <performer>
                    <xsl:call-template name="performer-reference">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:call-template>
                </performer>
            </xsl:if>
            -->
        </Procedure>
    </xsl:template>
    
   

    <xsl:template
        match="cda:observation[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id"/>
            <xsl:apply-templates select="cda:statusCode" mode="procedure"/>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference"/>
            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:call-template>
            <!-- RG: Commented out for demo -->
            <!--
            <xsl:if test="cda:performer">
                <performer>
                    <xsl:call-template name="performer-reference">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:call-template>
                </performer>
            </xsl:if>
            -->
            <xsl:if test="cda:value[@code or @nullFlavor]">
                <!-- Only process value elements that actually have some content, not empty stuff like <value xsi:type="CD"/> -->
                <xsl:choose>
                    <xsl:when test="cda:value[@xsi:type = 'CD']">
                        <xsl:apply-templates select="cda:value">
                            <xsl:with-param name="pElementName">outcome</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Unknown procedure obeservation procedure value for
                            <xsl:apply-templates select="cda:id"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </Procedure>
    </xsl:template>

    <xsl:template match="cda:statusCode" mode="procedure">
        <status>
            <xsl:choose>
                <xsl:when test="@code = 'active'">
                    <xsl:attribute name="value">in-progress</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'cancelled'">
                    <xsl:attribute name="value">not-done</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'aborted'">
                    <xsl:attribute name="value">stopped</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value" select="@code"/>
                </xsl:otherwise>
            </xsl:choose>
        </status>
    </xsl:template>

</xsl:stylesheet>
