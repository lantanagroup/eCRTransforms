<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.45']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.45']]">
        <FamilyMemberHistory>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <xsl:apply-templates select="cda:statusCode" mode="family-history" />
            <xsl:call-template name="family-history-subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:subject" mode="family-history" />
            <xsl:apply-templates select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.46']" mode="family-history" />
        </FamilyMemberHistory>
    </xsl:template>

    <xsl:template match="cda:statusCode" mode="family-history">
        <!-- 20260729 Claude: Fix - only 'active' was mapped; every other ActStatus code was copied raw, but the
             FamilyMemberHistory status value set is partial | completed | entered-in-error | health-unknown.
             active -> partial (collection ongoing); aborted/cancelled/suspended/held -> partial (collection stopped
             before completion); nullified -> entered-in-error; completed and default -> completed -->
        <status>
            <xsl:attribute name="value">
                <xsl:choose>
                    <xsl:when test="@code = 'active' or @code = 'aborted' or @code = 'cancelled' or @code = 'suspended' or @code = 'held'">partial</xsl:when>
                    <xsl:when test="@code = 'nullified'">entered-in-error</xsl:when>
                    <xsl:otherwise>completed</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </status>
    </xsl:template>

    <xsl:template match="cda:subject" mode="family-history">
        <xsl:for-each select="cda:relatedSubject">

            <xsl:if test="cda:subject/cda:name">
                <name value="{cda:subject/cda:name}" />
            </xsl:if>
            <xsl:apply-templates select="cda:code" mode="relationship" />
            <xsl:apply-templates select="cda:subject/cda:administrativeGenderCode" mode="family-history" />
            <xsl:apply-templates select="cda:subject/cda:birthTime">
                <xsl:with-param name="pElementName">bornDate</xsl:with-param>
            </xsl:apply-templates>
            <xsl:choose>
                <xsl:when test="cda:subject/sdtc:deceasedTime[@value]">
                    <deceasedDate value="{lcg:dateFromcdaTS(cda:subject/sdtc:deceasedTime/@value)}" />
                </xsl:when>
                <xsl:when test="cda:subject/sdtc:deceasedInd[@value]">
                    <deceasedBoolean value="{cda:subject/sdtc:deceasedInd/@value}" />
                </xsl:when>
            </xsl:choose>

        </xsl:for-each>
    </xsl:template>


    <xsl:template match="cda:code" mode="relationship">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">relationship</xsl:with-param>
            <xsl:with-param name="pIncludeCoding" select="true()" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.46']" mode="family-history">
        <condition>
            <xsl:apply-templates select="cda:value">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>

            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.47']">
                <xsl:apply-templates select="cda:value">
                    <xsl:with-param name="pElementName">outcome</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
        </condition>
    </xsl:template>

    <xsl:template name="family-history-subject-reference">
        <xsl:param name="pElementName">subject</xsl:param>
        <!-- TODO: handle multiple subjects (record as a group where allowed) -->
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <!-- Don't count the current subject, because that is the relative not the patient -->
                <!--
                <xsl:when test="cda:subject">
                    <reference value="urn:uuid:{cda:subject/@lcg:uuid}"/>
                </xsl:when>
                -->
                <xsl:when test="ancestor::cda:section/cda:subject">
                    <reference value="urn:uuid:{ancestor::cda:section[1]/cda:subject/@lcg:uuid}" />
                </xsl:when>
                <xsl:otherwise>
                    <reference value="urn:uuid:{/cda:ClinicalDocument/cda:recordTarget/@lcg:uuid}" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:administrativeGenderCode" mode="family-history">
        <xsl:variable name="cda-gender" select="@code" />
        <sex>
            <coding>
                <system value="http://hl7.org/fhir/administrative-gender" />
                <code>
                    <xsl:choose>
                        <xsl:when test="@nullFlavor = 'UNK'">
                            <xsl:attribute name="value">unknown</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="$cda-gender = 'M'">
                            <xsl:attribute name="value">male</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="$cda-gender = 'F'">
                            <xsl:attribute name="value">female</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="$cda-gender = 'UN'">
                            <xsl:attribute name="value">other</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- TODO: at some point figure out what to do for other options, like nullFlavor of OTH with originalText -->
                            <xsl:attribute name="value">unknown</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </code>
            </coding>
        </sex>
    </xsl:template>
</xsl:stylesheet>
