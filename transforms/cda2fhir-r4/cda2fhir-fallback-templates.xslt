<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" version="2.0"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml">

    <xsl:template match="cda:text">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="cda:*" mode="reference" priority="-1">
        <xsl:param name="wrapping-elements" />
        <xsl:param name="pElementName">reference</xsl:param>
        <xsl:if test="not(@nullFlavor)">
            <xsl:variable name="this" select="." />
            <!-- SG: Changed to a for-each so that all template ids get spit out -->
            <xsl:for-each select="cda:templateId">
                <xsl:choose>
                    <xsl:when test="@extension">
                        <xsl:comment><xsl:value-of select="concat(@root, ':', @extension)" /></xsl:comment>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment><xsl:value-of select="@root" /></xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="$wrapping-elements">
                    <xsl:call-template name="wrap-reference">
                        <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
                        <xsl:with-param name="reference-uuid" select="@lcg:uuid" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="{$pElementName}">
                        <xsl:attribute name="value">urn:uuid:<xsl:value-of select="@lcg:uuid" /></xsl:attribute>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- don't create reference -->
    <xsl:template match="cda:sequenceNumber" mode="reference"/>

    <xsl:template name="wrap-reference">
        <xsl:param name="wrapping-elements" />
        <xsl:param name="reference-uuid" />
        <xsl:param name="pElementName">reference</xsl:param>

        <xsl:choose>
            <xsl:when test="$wrapping-elements">
                <xsl:choose>
                    <xsl:when test="contains($wrapping-elements, '/')">
                        <xsl:element name="{substring-before($wrapping-elements,'/')}">
                            <xsl:call-template name="wrap-reference">
                                <xsl:with-param name="wrapping-elements" select="substring-after($wrapping-elements, '/')" />
                                <xsl:with-param name="reference-uuid" select="$reference-uuid" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="{$wrapping-elements}">
                            <xsl:apply-templates select="self::node()" mode="entry-extension" />
                            <xsl:call-template name="wrap-reference">
                                <xsl:with-param name="reference-uuid" select="$reference-uuid" />
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">urn:uuid:<xsl:value-of select="@lcg:uuid" /></xsl:attribute>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- don't create reference -->
    <xsl:template match="cda:entryRelationship" mode="entry-extension"/>
        
    
    <xsl:template match="cda:statusCode" priority="-1">
        <status value="{@code}" />
    </xsl:template>

    <!-- swallow unmapped entry and entryRelationship children -->
    <xsl:template match="*[parent::cda:entry] | *[parent::cda:entryRelationship] | *[parent::act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132'][@extension = '2015-08-01']]]" priority="-10"
        mode="bundle-entry">
        <xsl:choose>

            <xsl:when test="cda:templateId">
                <xsl:for-each select="cda:templateId">
                    <xsl:comment>
                        <xsl:text>WARNING: No template match for </xsl:text>
                        <xsl:value-of select="@root" />
                        <xsl:if test="@extension">
                            <xsl:text>: </xsl:text>
                            <xsl:value-of select="@extension" />
                        </xsl:if>
                    </xsl:comment>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>
                    <text>WARNING: No match for </text>
                    <xsl:value-of select="local-name()" />
                </xsl:comment>
                <!--<xsl:comment>
          <text>No match for </text>
          <xsl:value-of select="." />
        </xsl:comment>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Add warning so we can see when default templates are running when we don't want them to -->
    <xsl:template match="cda:*" priority="-10">
        <xsl:message>WARNING: Unmatched element: <xsl:value-of select="name()" /></xsl:message>
        <xsl:apply-templates />
    </xsl:template>

    <!--<xsl:template match="text()|@*" priority="-10">
    <xsl:comment terminate="no">WARNING: Unmatched text: <xsl:value-of select="." />
    </xsl:comment>
    <xsl:apply-templates />
  </xsl:template>-->

</xsl:stylesheet>
