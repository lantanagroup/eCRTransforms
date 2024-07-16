<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- Add Communication for Instruction template -->
    <!-- Want to exclude Reportability Response Summary and Subject from this transform -->
    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']]
        [not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])]
        [not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]"
        mode="bundle-entry">
        
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="communication">
        <sent value="{lcg:cdaTS2date(@value)}" />
    </xsl:template>

    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]">
        <Communication>
            <xsl:apply-templates select="cda:id" />
            
            <!-- partOf: point back to the containing resource -->
            <partOf>
                <reference value="urn:uuid:{../../../cda:*/@lcg:uuid}" />
            </partOf>
            <!-- status -->
            <status>
                <xsl:choose>
                    <xsl:when test="cda:statusCode/@code">
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:statusCode/@code" />
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="value">
                            <xsl:value-of select="'completed'" />
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                
            </status>
            <xsl:call-template name="subject-reference" />
            
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">topic</xsl:with-param>
            </xsl:apply-templates>
            
            <xsl:call-template name="encompassingEncounter-reference" />

            <xsl:for-each select="cda:entryRelationship">
                <xsl:choose>
                    <xsl:when test="cda:act/cda:participant[@typeCode = 'AUT']">
                        <!-- MD: need to check the present of effectiveTime to prevent error -->
                        <xsl:choose>
                            <xsl:when test="cda:act/cda:effectiveTime">
                                <sent value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
                            </xsl:when>
                        </xsl:choose>

                    </xsl:when>
                    <xsl:when test="cda:act/cda:participant[@typeCode = 'IRCP']">
                        <xsl:choose>
                            <!-- MD: need to check the present of effectiveTime to prevent error -->
                            <xsl:when test="cda:act/cda:effectiveTime">
                                <received value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
                            </xsl:when>
                        </xsl:choose>

                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName" select="'recipient'" />
            </xsl:call-template>
            
            <!-- get closest author (work up the hierarchy if needed) -->
            <xsl:variable name="vClosestAuthor">
                <xsl:call-template name="get-closest-author" />
            </xsl:variable>
            <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">sender</xsl:with-param>
            </xsl:apply-templates>

            <xsl:if test="cda:text">
                <payload>
                    <contentString>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:text" />
                        </xsl:attribute>
                    </contentString>
                </payload>
            </xsl:if>

        </Communication>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.141']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
    </xsl:template>

    <!-- Communication: cda Handoff Communication Participants template -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.141']]">
        <xsl:comment>INFO: C-CDA Handoff Communication Participants</xsl:comment>
        <Communication xmlns="http://hl7.org/fhir">
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="{cda:statusCode/@code}" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime" mode="communication" />
            <xsl:for-each select="cda:participant">
                <recipient>
                    <xsl:apply-templates select="cda:participantRole" mode="reference" />
                    <!--<reference value="urn:uuid:{@lcg:uuid}"/>-->
                </recipient>
            </xsl:for-each>
            <!-- get closest author (work up the hierarchy if needed) -->
            <xsl:variable name="vClosestAuthor">
                <xsl:call-template name="get-closest-author" />
            </xsl:variable>
            <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">sender</xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
            </xsl:apply-templates>
        </Communication>
    </xsl:template>

</xsl:stylesheet>
