<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.7' or @root = '2.16.840.1.113883.10.20.24.3.90']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.7' or @root = '2.16.840.1.113883.10.20.24.3.90']]">
        <AllergyIntolerance>

            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <xsl:apply-templates select="ancestor::cda:entry/cda:act/cda:statusCode" mode="allergy" />
            <verificationStatus>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/allergyintolerance-verification" />
                    <xsl:choose>
                        <xsl:when test="@negationInd='true'">
                            <code value="refuted" />
                            <display value="Refuted" />
                        </xsl:when>
                        <xsl:otherwise>
                            <code value="confirmed" />
                            <display value="Confirmed" />
                        </xsl:otherwise>
                    </xsl:choose>
                </coding>
            </verificationStatus>
            <type>
                <xsl:attribute name="value">
                    <xsl:choose>
                        <xsl:when test="cda:value/@code = '419199007' and cda:value/@codeSystem = '2.16.840.1.113883.6.96'">allergy</xsl:when>
                        <xsl:otherwise>intolerance</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </type>
            <xsl:choose>
                <xsl:when test="@negationInd = 'true'">
                    <code>
                        <xsl:comment>INFO: Original negated code: <xsl:value-of select="cda:value/@code" /></xsl:comment>
                        <coding>
                            <system value="http://snomed.info/sct" />
                            <code value="716186003" />
                            <display value="No known allergy" />
                        </coding>
                    </code>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:participant[@typeCode = 'CSM']" mode="allergy" />
                </xsl:otherwise>
            </xsl:choose>
            <patient>
                <!-- TODO: find the nearest subject in the CDA, or the record target if none present -->
                <reference value="urn:uuid:{//cda:recordTarget/@lcg:uuid}" />
            </patient>
            <xsl:apply-templates select="cda:effectiveTime" mode="allergy" />
            <xsl:apply-templates select="cda:informant" mode="reference">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:apply-templates>
            <xsl:choose>
                <xsl:when test="@negationInd = 'true'">
                    <xsl:comment>INFO: Negated manifestation not currently supported</xsl:comment>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:entryRelationship/cda:observation/cda:value" mode="reaction" />
                </xsl:otherwise>
            </xsl:choose>
        </AllergyIntolerance>
    </xsl:template>

    <xsl:template match="cda:value" mode="reaction">
        <reaction>
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">manifestation</xsl:with-param>
            </xsl:call-template>
        </reaction>
    </xsl:template>

    <xsl:template match="cda:value" mode="type">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">type</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:statusCode" mode="allergy">
        <!-- TODO: actually map the status codes, not always the same between CDA and FHIR -->
        <xsl:if test="@code">
            <clinicalStatus>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical" />
                    <code value="{@code}" />
                </coding>
            </clinicalStatus>
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="allergy">
        <xsl:choose>
            <xsl:when test="cda:low and cda:high">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName">onsetPeriod</xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="cda:low/@value">
                <onsetDateTime value="{lcg:cdaTS2date(cda:low/@value)}" />
            </xsl:when>
            <xsl:when test="@value">
                <onsetDateTime value="{lcg:cdaTS2date(@value)}" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!--
    <xsl:template match="cda:value" mode="allergy">
        <xsl:comment>Should be no category here</xsl:comment>
        <type>
            <coding>
                <system>
                    <xsl:attribute name="value">
                        <xsl:call-template name="convertOID">
                            <xsl:with-param name="oid" select="@codeSystem"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </system>
                <code value="{@code}"/>
                <xsl:if test="@displayName">
                    <display value="{@displayName}"/>
                </xsl:if>
            </coding>
        </type>
    </xsl:template>
    -->
    <xsl:template match="cda:participant[@typeCode = 'CSM']" mode="allergy">
        <xsl:if test="cda:participantRole/cda:playingEntity/cda:code[not(@nullFlavor)]">
            <code>
                <xsl:for-each select="cda:participantRole/cda:playingEntity/cda:code[not(@nullFlavor)]">
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

            </code>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
