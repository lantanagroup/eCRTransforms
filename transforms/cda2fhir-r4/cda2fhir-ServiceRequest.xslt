<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <!-- SG 20211126: I think that all of the following need to be ServiceRequest
        (need to double check with Ming)
            Planned Procedure [2.16.840.1.113883.10.20.22.4.41] (included in code)
                Initial Case Report Trigger Code Planned Procedure [2.16.840.1.113883.10.20.15.2.3.42] (not included, taken care of by parent?)
            Planned Act [2.16.840.1.113883.10.20.22.4.39] (ADDED)
                Initial Case Report Trigger Code Planned Act [2.16.840.1.113883.10.20.15.2.3.41] (not included, taken care of by parent) 
            Planned Observation [2.16.840.1.113883.10.20.22.4.44] (ADDED)
                Initial Case Report Trigger Code Lab Test Order [2.16.840.1.113883.10.20.15.2.3.4] (included in code, REMOVED, taken care of by parent)
                Initial Case Report Trigger Code Planned Observation [2.16.840.1.113883.10.20.15.2.3.43] (not included, taken care of by parent?)
    -->

    <!-- MD: add transfer Planned Procedure (request or intent) to fhir ServiceRequest -->
    <xsl:template match="cda:procedure[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.41']]" mode="bundle-entry">
        <xsl:comment>Planned Procedure</xsl:comment>
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry"/>
    </xsl:template>

    <!-- Planned Procedure (request or intent) -->
    <xsl:template match="cda:procedure[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.41']]">
        <ServiceRequest>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />
            <xsl:apply-templates select="cda:id" />
           
            <xsl:choose>
                <xsl:when test="cda:statusCode/@code = 'active'">
                    <status value="active" />
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="." mode="intent" />
            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:entryRelationship" mode="encounter-reference" />

            <!-- MD: add Occured time -->
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName">occurrenceDateTime</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">requester</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>
        </ServiceRequest>
    </xsl:template>

    <!-- MD: add encounter-reference -->
    <xsl:template match="cda:entryRelationship" mode="encounter-reference">
        <xsl:choose>
            <xsl:when test="@typeCode != 'SUBJ'">
                <xsl:variable name="vTest" select="cda:encounter/cda:code/cda:translation/@code" />
                <encounter>
                    <reference
                        value="urn:uuid:{/cda:ClinicalDocument/cda:component/cda:structuredBody/
                        cda:component/cda:section/cda:entry/cda:encounter[cda:code/cda:translation/@code=$vTest]/@lcg:uuid}"
                     />
                </encounter>
            </xsl:when>
        </xsl:choose>

    </xsl:template>

    <!-- MD: add transfer inFullfillmentOf to fhir ServiceRequest -->
    <xsl:template match="cda:inFulfillmentOf/cda:order" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:inFulfillmentOf/cda:order">
        <ServiceRequest>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />

            <xsl:choose>
                <xsl:when test="cda:id/@root">
                    <!-- This identifier is linked back to the referral order if there is an identifier in the referral order -->
                    <identifier>
                        <system value="urn:ietf:rfc:3986" />
                        <value>
                            <xsl:attribute name="value">
                                <xsl:value-of select="concat('urn:uuid:', cda:id/@root)" />
                            </xsl:attribute>
                        </value>
                    </identifier>
                </xsl:when>
            </xsl:choose>

            <!--MD: handle the case @classCode is not present -->
            <xsl:choose>
                <xsl:when test="@classCode = 'ACT'">
                    <status value="active" />
                </xsl:when>
                <xsl:otherwise>
                    <status value="active" />
                </xsl:otherwise>
            </xsl:choose>
            
            <!--MD: handle case no cda:order, cda:act, cda:observation, cda:procedure -->
            <xsl:choose>
                <xsl:when test="cda:order | cda:act | cda:observation | cda:procedure">
                    <xsl:apply-templates select="." mode="intent" />
                </xsl:when>
                <xsl:otherwise>
                    <intent value="plan" />
                </xsl:otherwise>
            </xsl:choose>
            
            

            <xsl:apply-templates select="cda:priorityCode" mode="priorityCode" />
            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            <xsl:call-template name="subject-reference" />
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">requester</xsl:with-param>
            </xsl:call-template>

        </ServiceRequest>
    </xsl:template>

    <xsl:template match="cda:priorityCode" mode="priorityCode">
        <xsl:choose>
            <xsl:when test="@code = 'A'">
                <priority value="asap" />
            </xsl:when>
            <xsl:when test="@code = 'S'">
                <priority value="stat" />
            </xsl:when>
            <xsl:when test="@code = 'UR'">
                <priority value="urgent" />
            </xsl:when>
            <xsl:when test="@code = 'R'">
                <priority value="routine" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:order" mode="classCode">
        <xsl:choose>
            <xsl:when test="@classCode = 'ACT'">
                <status value="active" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- SG 20211117
        Might just be able to lump these all in with Planned Procedure above (but also might not!)
        Patient Referral Act [2.16.840.1.113883.10.20.22.4.140] 
        **Procedure Activity Act [2.16.840.1.113883.10.20.22.4.12] template has hardcoded moodCode of EVN, is always an act that has already happened,
         so removing from the match below**
        Deleted because taken care of by parent (Planned Observation) Initial Case Report Trigger Code Lab Test Order [2.16.840.1.113883.10.20.15.2.3.4] (hardcoded moodCode of RQO)
        Adding: 
            Planned Act [2.16.840.1.113883.10.20.22.4.39]
            Planned Observation [2.16.840.1.113883.10.20.22.4.44]
            
    -->
    <!--<xsl:template
        match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
            cda:act[@moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12'][@extension = '2014-06-09']] |
            cda:observation[@moodCode = 'RQO'][cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.4']]"
        mode="bundle-entry">-->
    <xsl:template
        match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
            cda:act[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.39']] |
            cda:observation[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.44']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
    </xsl:template>

    <!--<xsl:template
        match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
            cda:act[@moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12'][@extension = '2014-06-09']] |
            cda:observation[@moodCode = 'RQO'][cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.4']]">
    -->
    <xsl:template
        match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
            cda:act[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.39']] |
            cda:observation[@moodCode = 'RQO' or @moodCode = 'INT'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.44']]">
        <ServiceRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="{cda:statusCode/@code}" />
            <xsl:apply-templates select="." mode="intent" />

            <!-- need to add .priority -->
            <xsl:choose>
                <xsl:when test="cda:priorityCode/@code = 'A'">
                    <priority value="asap" />
                </xsl:when>
                <xsl:when test="cda:priorityCode/@code = 'S'">
                    <priority value="stat" />
                </xsl:when>
                <xsl:when test="cda:priorityCode/@code = 'UR'">
                    <priority value="urgent" />
                </xsl:when>
                <xsl:when test="cda:priorityCode/@code = 'R'">
                    <priority value="routine" />
                </xsl:when>
            </xsl:choose>

            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName" select="'occurrenceDateTime'" />
            </xsl:apply-templates>
            <xsl:if test="cda:author">
                <xsl:call-template name="author-reference">
                    <xsl:with-param name="pElementName">requester</xsl:with-param>
                </xsl:call-template>
            </xsl:if>
        </ServiceRequest>
    </xsl:template>


    <xsl:template match="cda:code" mode="procedure-request">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">code</xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <!-- SG 20211126: This was already here but added to matches and deleted replicated code above -->
    <xsl:template match="cda:order | cda:act | cda:observation | cda:procedure" mode="intent">
        <xsl:choose>
            <xsl:when test="@moodCode = 'INT'">
                <intent value="plan" />
            </xsl:when>
            <xsl:when test="@moodCode = 'RQO'">
                <intent value="order" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- SG 20211126: Moved out from code above for reuse -->
    <xsl:template name="add-servicerequest-meta">
        <!-- Check current Ig -->
        <xsl:variable name="vCurrentIg">
            <xsl:apply-templates select="/" mode="currentIg" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$vCurrentIg = 'NA'">
                <xsl:call-template name="add-meta" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="vProfileValue">
                    <xsl:call-template name="get-profile-for-ig">
                        <xsl:with-param name="pIg" select="$vCurrentIg" />
                        <xsl:with-param name="pResource" select="'ServiceRequest'" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$vProfileValue ne 'NA'">
                        <meta>
                            <profile>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="$vProfileValue" />
                                </xsl:attribute>
                            </profile>
                        </meta>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
