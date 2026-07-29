<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="
            cda:act[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
            cda:procedure[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']] |
            cda:observation[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <xsl:for-each select="cda:author[position() > 1] | cda:informant[position() > 1]">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>
        <!-- C-CDA Service Delivery Location -->
        <xsl:apply-templates select="cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <!-- Moved all suppression processing to c-to-fhir-utility and templates-to-suppress.xml holds the list of templateIds to suppress -->
    <!-- Suppress Reaction Observation in a procedure since matched as complication (only code) -->
    <!--<xsl:template match="
            cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9'][../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']] |
            cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9'][../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']] |
            cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9'][../../cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']]" mode="bundle-entry" />
-->
    <!-- Procedure Activity Act -->
    <xsl:template match="cda:act[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-procedure" />
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="add-meta" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:id" />

            <!-- partOf: if this is contained in a procedure or substanceAdministration, reference that -->
            <xsl:if test="
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.12'] or
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14'] or
                    parent::cda:*/parent::cda:*/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13'] or
                    parent::cda:*/cda:substanceAdministration">
                <partOf>
                    <reference value="urn:uuid:{parent::cda:*/parent::cda:*/@lcg:uuid}" />
                </partOf>
            </xsl:if>

            <xsl:apply-templates select="cda:statusCode" mode="procedure" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <!-- encounter -->
            <!-- 20260729 Claude: Fix - the match required @extension equality even when the encompassingEncounter id has
                 no extension (an absent attribute never equals an empty string), so root-only ids could never match; now
                 roots must match and extensions must either match or both be absent -->
            <xsl:if test="
                    cda:entryRelationship/cda:encounter/cda:id[some $e in /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:id
                        satisfies (@root = $e/@root and ((@extension = $e/@extension) or (not(@extension) and not($e/@extension))))]">
                <encounter>
                    <reference value="urn:uuid:{/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter[1]/@lcg:uuid}" />
                </encounter>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="cda:effectiveTime/@nullFlavor and ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.131']]">
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

            <!-- recorder (max 1)-->
            <xsl:apply-templates select="cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">recorder</xsl:with-param>
            </xsl:apply-templates>

            <!-- asserter (max 1)-->
            <xsl:apply-templates select="cda:informant[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:apply-templates>

            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <performer>
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:apply-templates>
                </performer>
            </xsl:for-each>
            
            <!-- location -->
            <!-- 20260729 Claude: Fix - added [1]; with more than one SDL participant the AVT space-joined all uuids into
                 one malformed reference (Procedure.location is 0..1) -->
            <xsl:if test="cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']]">
                <location>
                    <reference value="urn:uuid:{cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']][1]/@lcg:uuid}" />
                </location>
            </xsl:if>
            
            <!-- reasonReference (c-cda indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.19']]">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>
            
            <!-- BodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>

            <!-- complication -->
            <xsl:if test="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']/cda:value/@code">
                <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']/cda:value">
                    <xsl:with-param name="pElementName">complication</xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>

            <!-- usedReference:medication -->
            <xsl:for-each select="cda:entryRelationship/cda:substanceAdministration/cda:consumable/cda:manufacturedProduct">
                <usedReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </usedReference>
            </xsl:for-each>

        </Procedure>
    </xsl:template>

    <!-- Procedure Activity Procedure -->
    <xsl:template match="cda:procedure[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.14']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-procedure" />
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="add-meta" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:id" />
            <xsl:apply-templates select="cda:statusCode" mode="procedure" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <!-- encounter -->
            <!-- 20260729 Claude: Fix - the match required @extension equality even when the encompassingEncounter id has
                 no extension (an absent attribute never equals an empty string), so root-only ids could never match; now
                 roots must match and extensions must either match or both be absent -->
            <xsl:if test="
                    cda:entryRelationship/cda:encounter/cda:id[some $e in /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:id
                        satisfies (@root = $e/@root and ((@extension = $e/@extension) or (not(@extension) and not($e/@extension))))]">
                <encounter>
                    <reference value="urn:uuid:{/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter[1]/@lcg:uuid}" />
                </encounter>
            </xsl:if>

            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
            </xsl:apply-templates>

            <!-- recorder (max 1)-->
            <xsl:apply-templates select="cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">recorder</xsl:with-param>
            </xsl:apply-templates>

            <!-- asserter (max 1)-->
            <xsl:apply-templates select="cda:informant[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:apply-templates>

            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <performer>
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:apply-templates>
                </performer>
            </xsl:for-each>
            
            <!-- location -->
            <!-- 20260729 Claude: Fix - added [1]; with more than one SDL participant the AVT space-joined all uuids into
                 one malformed reference (Procedure.location is 0..1) -->
            <xsl:if test="cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']]">
                <location>
                    <reference value="urn:uuid:{cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']][1]/@lcg:uuid}" />
                </location>
            </xsl:if>
            
            <!-- reasonReference (c-cda indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.19']]">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>

            <!-- BodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>

            <!-- complication -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']">
                <complicationDetail>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </complicationDetail>
            </xsl:for-each>

            <!-- focalDevice -->
            <!-- 20260729 Claude: Fix - a stray apply-templates on the Product Instance templateId element (a no-op) sat
                 where the device mapping belonged; Product Instance participants now map to focalDevice.manipulated
                 (Bundle.xslt creates the Device entry with the participantRole's uuid, and fhir2cda maps
                 focalDevice.manipulated back to a Product Instance participant) -->
            <xsl:for-each select="cda:participant/cda:participantRole[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.37']">
                <focalDevice>
                    <manipulated>
                        <reference value="urn:uuid:{@lcg:uuid}" />
                    </manipulated>
                </focalDevice>
            </xsl:for-each>

            <!-- usedReference:medication -->
            <xsl:for-each select="cda:entryRelationship/cda:substanceAdministration/cda:consumable/cda:manufacturedProduct">
                <usedReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </usedReference>
            </xsl:for-each>
        </Procedure>
    </xsl:template>

    <!-- Procedure Activity Observation -->
    <xsl:template match="cda:observation[@moodCode = 'EVN'][cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.13']]">
        <Procedure xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-procedure" />
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="add-meta" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:apply-templates select="cda:id" />
            <xsl:apply-templates select="cda:statusCode" mode="procedure" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <!-- encounter -->
            <!-- 20260729 Claude: Fix - the match required @extension equality even when the encompassingEncounter id has
                 no extension (an absent attribute never equals an empty string), so root-only ids could never match; now
                 roots must match and extensions must either match or both be absent -->
            <xsl:if test="
                    cda:entryRelationship/cda:encounter/cda:id[some $e in /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:id
                        satisfies (@root = $e/@root and ((@extension = $e/@extension) or (not(@extension) and not($e/@extension))))]">
                <encounter>
                    <reference value="urn:uuid:{/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter[1]/@lcg:uuid}" />
                </encounter>
            </xsl:if>
            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">performedPeriod</xsl:with-param>
            </xsl:apply-templates>

            <!-- recorder (max 1)-->
            <xsl:apply-templates select="cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">recorder</xsl:with-param>
            </xsl:apply-templates>

            <!-- asserter (max 1)-->
            <xsl:apply-templates select="cda:informant[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:apply-templates>

            <!-- performers (multiple) -->
            <xsl:for-each select="cda:performer">
                <performer>
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName">actor</xsl:with-param>
                    </xsl:apply-templates>
                </performer>
            </xsl:for-each>
            
            <!-- location -->
            <!-- 20260729 Claude: Fix - added [1]; with more than one SDL participant the AVT space-joined all uuids into
                 one malformed reference (Procedure.location is 0..1) -->
            <xsl:if test="cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']]">
                <location>
                    <reference value="urn:uuid:{cda:participant[cda:participantRole/cda:templateId[@root='2.16.840.1.113883.10.20.22.4.32']][1]/@lcg:uuid}" />
                </location>
            </xsl:if>
            
            <!-- reasonReference (c-cda indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.19']]">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>
            
            <!-- BodySite -->
            <xsl:apply-templates select="cda:targetSiteCode">
                <xsl:with-param name="pElementName" select="'bodySite'" />
            </xsl:apply-templates>

            <xsl:if test="cda:value[@code or @nullFlavor]">
                <!-- Only process value elements that actually have some content, not empty stuff like <value xsi:type="CD"/> -->
                <xsl:choose>
                    <xsl:when test="cda:value[@xsi:type = 'CD']">
                        <xsl:apply-templates select="cda:value">
                            <xsl:with-param name="pElementName">outcome</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment>WARNING: Unknown procedure observation procedure value for <xsl:apply-templates select="cda:id" /></xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>

            <!-- complication -->
            <xsl:if test="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']/cda:value/@code">
                <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']/cda:value">
                    <xsl:with-param name="pElementName">complication</xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>

            <!-- usedReference:medication -->
            <xsl:for-each select="cda:entryRelationship/cda:substanceAdministration/cda:consumable/cda:manufacturedProduct">
                <usedReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </usedReference>
            </xsl:for-each>
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
                <xsl:when test="@code = 'new'">
                    <xsl:attribute name="value">preparation</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'completed'">
                    <xsl:attribute name="value">completed</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'held'">
                    <xsl:attribute name="value">on-hold</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'suspended'">
                    <xsl:attribute name="value">on-hold</xsl:attribute>
                </xsl:when>
                <xsl:when test="@code = 'nullified'">
                    <xsl:attribute name="value">entered-in-error</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <!-- 20260727 Claude: Fix - select="completed" was an unquoted XPath (a child-element step selecting nothing),
                         producing an empty status value=""; quoted so the fallback is the string 'completed' -->
                    <xsl:attribute name="value" select="'completed'" />
                </xsl:otherwise>
            </xsl:choose>
        </status>
    </xsl:template>
</xsl:stylesheet>