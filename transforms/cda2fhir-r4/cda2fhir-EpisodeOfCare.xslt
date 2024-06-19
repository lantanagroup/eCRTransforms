<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">



    <!-- ClinicalDocument.serviceEvent (other than the eCR special case) -->
    <xsl:template match="cda:serviceEvent[not(@moodCode = 'INT')][not(cda:code[@code = 'PHC1464'])]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:for-each select="cda:performer">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
        <xsl:if test="cda:performer">
            <xsl:call-template name="create-care-team" />
        </xsl:if>
    </xsl:template>

    <!-- ClinicalDocument.serviceEvent (other than the eCR special case) -->
    <xsl:template match="cda:serviceEvent[not(@moodCode = 'ÍNT')][not(cda:code[@code = 'PHC1464'])]">
        <EpisodeOfCare>
            <xsl:call-template name="add-meta" />
            <!-- identifier -->
            <xsl:apply-templates select="cda:id" />
            <!-- status -->
            <status value="active" />
            <!-- type -->
            <type>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/v3-ActClass" />
                    <code value="{@classCode}" />
                    <xsl:choose>
                        <xsl:when test="@classCode = 'PCPR'">
                            <display value="care provision" />
                        </xsl:when>
                    </xsl:choose>
                </coding>
            </type>
            <!-- diagnosis -->
            <!-- patient -->
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <!-- managingOrganization -->
            <xsl:if test="parent::cda:*/preceding-sibling::cda:recordTarget/cda:patientRole/cda:providerOrganization">
                <managingOrganization>
                    <reference value="urn:uuid:{parent::cda:*/preceding-sibling::cda:recordTarget/cda:patientRole/cda:providerOrganization/@lcg:uuid}" />
                </managingOrganization>
            </xsl:if>
            <!-- period -->
            <!-- referralRequest -->
            <!-- careManager -->
            <!-- team -->
            <xsl:apply-templates select="parent::cda:documentationOf" mode="reference">
                <xsl:with-param name="wrapping-elements">team</xsl:with-param>
            </xsl:apply-templates>
            <!-- account -->
        </EpisodeOfCare>
    </xsl:template>
</xsl:stylesheet>
