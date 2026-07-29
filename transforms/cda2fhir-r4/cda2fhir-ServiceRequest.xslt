<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- C-CDA Patient Referral Act, C-CDA Planned Act, C-CDA Planned Observation -->
    <xsl:template match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.39']] |
            cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.44']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        
        <xsl:for-each select="cda:author[position() > 1] | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <!-- Add transfer Planned Procedure to fhir ServiceRequest -->
    <xsl:template match="cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.41']]" mode="bundle-entry">
        <xsl:comment>Planned Procedure</xsl:comment>
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        
        <xsl:for-each select="cda:author[position() > 1] | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>
    
    <!-- C-CDA Patient Referral Act, Planned Act, Planned Observation  -->
    <xsl:template match="
        cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.140']] |
        cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.39']] |
        cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.44']]">
        <ServiceRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />
            <!-- id -->
            <xsl:apply-templates select="cda:id" />
            <!-- status -->
            <!-- 20260729 Claude: Fix - status was copied raw from cda:statusCode/@code; CDA ActStatus codes such as
                 aborted/new/held are not valid FHIR ServiceRequest statuses. Now mapped (see map-servicerequest-status),
                 with 'unknown' when statusCode is missing (ServiceRequest.status is required) -->
            <xsl:choose>
                <xsl:when test="cda:statusCode">
                    <xsl:apply-templates select="cda:statusCode" mode="map-servicerequest-status" />
                </xsl:when>
                <xsl:otherwise>
                    <status value="unknown" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- intent -->
            <xsl:apply-templates select="." mode="intent" />
            
            <!-- priority -->
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
            
            <!-- code -->
            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            
            <!-- orderDetail (mapping from Observation.method (could also add others?) -->
            <xsl:apply-templates select="cda:methodCode">
                <xsl:with-param name="pElementName">orderDetail</xsl:with-param>
            </xsl:apply-templates>
            
            <!-- subject -->
            <xsl:call-template name="subject-reference" />
            
            <!-- occurrenceDateTime -->
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName" select="'occurrenceDateTime'" />
            </xsl:apply-templates>
            
            <!-- authoredOn -->
            <xsl:apply-templates select="cda:author[1]/cda:time" mode="instant">
                <xsl:with-param name="pElementName">authoredOn</xsl:with-param>
            </xsl:apply-templates>
            
            <!-- requester (max 1)-->
            <xsl:for-each select="cda:author[1]">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">requester</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">performer</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- bodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>
        </ServiceRequest>
    </xsl:template>
    

    <!-- Planned Procedure -->
    <xsl:template match="cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.41']]">
        <ServiceRequest>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />
            <!--  -->
            <xsl:apply-templates select="cda:id" />
            
            <!-- status -->
            <!-- 20260729 Claude: Fix - status was only emitted when statusCode='active' (C-CDA Planned Procedure fixes it
                 to active, but ServiceRequest.status is required 1..1, so any other/missing statusCode produced an invalid
                 resource). Now mapped, with 'unknown' when statusCode is missing -->
            <xsl:choose>
                <xsl:when test="cda:statusCode">
                    <xsl:apply-templates select="cda:statusCode" mode="map-servicerequest-status" />
                </xsl:when>
                <xsl:otherwise>
                    <status value="unknown" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- intent -->
            <xsl:apply-templates select="." mode="intent" />
            
            <!-- code -->
            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            
            <!-- subject -->
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:entryRelationship" mode="encounter-reference" />

            <!-- occurrenceDateTime -->
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName">occurrenceDateTime</xsl:with-param>
            </xsl:apply-templates>
            
            <!-- authoredOn -->
            <xsl:apply-templates select="cda:author[1]/cda:time" mode="instant">
                <xsl:with-param name="pElementName">authoredOn</xsl:with-param>
            </xsl:apply-templates>
            
            <!-- requester (max 1)-->
            <xsl:for-each select="cda:author[1]">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">requester</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">performer</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- bodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>
        </ServiceRequest>
    </xsl:template>
    
    <xsl:template match="cda:inFulfillmentOf/cda:order">
        <ServiceRequest>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-servicerequest-meta" />
            
            <!-- This identifier is linked back to the referral order if there is an identifier in the referral order -->
            <!-- 20260729 Claude: Fix - identifier was hand-built as concat('urn:uuid:', cda:id/@root), which (a) ignored
                 cda:id/@extension and (b) mislabelled OID roots as urn:uuid. Now uses the standard cda:id template, which
                 handles OID vs UUID roots, extensions, and the oid-uri mapping -->
            <xsl:apply-templates select="cda:id" />

            <!-- status -->
            <!-- 20260729 Claude: Fix - the previous @classCode choose emitted 'active' in both branches (no-op); CDA
                 Order has classCode fixed to ACT, and an order carried in inFulfillmentOf is a placed, in-force request,
                 so status is simply 'active' -->
            <status value="active" />

            <!-- intent -->
            <!-- 20260729 Claude: Fix - the previous choose tested for CHILD order/act/observation/procedure elements,
                 which an order never has, so the moodCode-based branch was unreachable and intent was always 'plan'.
                 CDA Order has moodCode fixed to RQO, so the correct intent is 'order' (mapped via mode="intent" when
                 a moodCode is present, defaulting to 'order' when absent) -->
            <xsl:choose>
                <xsl:when test="@moodCode">
                    <xsl:apply-templates select="." mode="intent" />
                </xsl:when>
                <xsl:otherwise>
                    <intent value="order" />
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates select="cda:priorityCode" mode="priorityCode" />
            <xsl:apply-templates select="cda:code" mode="procedure-request" />
            <xsl:call-template name="subject-reference" />
            
            <!-- requester (max 1)-->
            <xsl:for-each select="cda:author[1]">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">requester</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <xsl:apply-templates select="." mode="rename-reference-participant">
                    <xsl:with-param name="pElementName">performer</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
        </ServiceRequest>
    </xsl:template>

    <!-- code -->
    <xsl:template match="cda:code" mode="procedure-request">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">code</xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <!-- intent -->
    <xsl:template match="cda:order | cda:act | cda:observation | cda:procedure" mode="intent">
        <xsl:choose>
            <xsl:when test="@moodCode = 'INT'">
                <intent value="plan" />
            </xsl:when>
            <xsl:when test="@moodCode = 'RQO'">
                <intent value="order" />
            </xsl:when>
            <xsl:when test="@moodCode = 'ARQ'">
                <intent value="plan" />
            </xsl:when>
            <xsl:when test="@moodCode = 'PRMS'">
                <intent value="plan" />
            </xsl:when>
            <xsl:when test="@moodCode = 'PRP'">
                <intent value="plan" />
            </xsl:when>
            <xsl:when test="@moodCode = 'APT'">
                <intent value="plan" />
            </xsl:when>
            <!-- 20260729 Claude: Fix - previously an unrecognized/missing moodCode emitted no intent at all, but
                 ServiceRequest.intent is required 1..1 -->
            <xsl:otherwise>
                <intent value="plan" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 20260729 Claude: Added - maps CDA ActStatus to the FHIR ServiceRequest status value set
         (draft | active | on-hold | revoked | completed | entered-in-error | unknown); previously the raw CDA code was
         copied through, producing invalid statuses such as 'aborted' or 'new' -->
    <xsl:template match="cda:statusCode" mode="map-servicerequest-status">
        <status>
            <xsl:attribute name="value">
                <xsl:choose>
                    <xsl:when test="@code = 'active'">active</xsl:when>
                    <xsl:when test="@code = 'completed'">completed</xsl:when>
                    <xsl:when test="@code = 'new'">draft</xsl:when>
                    <xsl:when test="@code = 'held' or @code = 'suspended'">on-hold</xsl:when>
                    <xsl:when test="@code = 'aborted' or @code = 'cancelled'">revoked</xsl:when>
                    <xsl:when test="@code = 'nullified'">entered-in-error</xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </status>
    </xsl:template>
    
    <!-- add encounter-reference -->
    <!-- 20260729 Claude: Fixes - (1) the target encounter was located via a fixed structural path
         (/ClinicalDocument/component/structuredBody/component/section/entry/encounter), which misses encounters in
         nested sections; (2) multiple matches produced a space-joined, malformed reference (XSLT 2.0 AVT); (3) no match
         produced a dangling empty reference (urn:uuid:). Now searches any section entry, takes the first match on
         code or translation, and emits nothing when no target is found -->
    <xsl:template match="cda:entryRelationship" mode="encounter-reference">
        <xsl:if test="cda:encounter and @typeCode != 'SUBJ'">
            <xsl:variable name="vCode" select="cda:encounter/cda:code/@code | cda:encounter/cda:code/cda:translation/@code" />
            <xsl:variable name="vTarget" select="(//cda:section/cda:entry/cda:encounter[cda:code/@code = $vCode or cda:code/cda:translation/@code = $vCode])[1]" />
            <xsl:if test="$vTarget">
                <encounter>
                    <reference value="urn:uuid:{$vTarget/@lcg:uuid}" />
                </encounter>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- add transfer inFullfillmentOf to fhir ServiceRequest -->
    <xsl:template match="cda:inFulfillmentOf/cda:order" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
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

    <!-- 20260729 Claude: removed dead template match="cda:order" mode="classCode" - it was never invoked from anywhere -->

    <xsl:template name="add-servicerequest-meta">
        <xsl:choose>
            <xsl:when test="$gvCurrentIg = 'NA'">
                <xsl:call-template name="add-meta" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="vProfileValue">
                    <xsl:call-template name="get-profile-for-ig">
                        <xsl:with-param name="pIg" select="$gvCurrentIg" />
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
