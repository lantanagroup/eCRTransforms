<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- This file matches on Coverage activities, but removes that wrapper and iterates over the Policy activies instead, since Coverage activity adds nothing from the FHIR perspective -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.60']]" mode="bundle-entry">

        <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
            <xsl:call-template name="create-bundle-entry" />
            <xsl:for-each select="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]">
                <xsl:call-template name="create-payor-org-entry" />
            </xsl:for-each>
            <xsl:for-each select="cda:participant[@typeCode = 'HLD']">
                <xsl:call-template name="create-bundle-entry" />
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="create-payor-org-entry">
        <entry>
            <fullUrl value="urn:uuid:{@lcg:uuid}" />
            <resource>
                <xsl:apply-templates select="." mode="payor" />
            </resource>
        </entry>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.60']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
            <xsl:apply-templates select="." mode="reference">
                <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
        <Coverage>
            <xsl:choose>
                <!-- MD: using hrex-coverage for tental data exchange IG -->
                <xsl:when test="
                        /cda:ClinicalDocument/cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.2' or
                        /cda:ClinicalDocument/cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.1'">
                    <meta>
                        <profile>
                            <xsl:attribute name="value" select="'http://hl7.org/fhir/us/davinci-hrex/StructureDefinition/hrex-coverage'" />
                        </profile>
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="add-meta" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:id" />
            <!-- 20260729 Claude: Fix - status was hard-coded 'active'; now mapped from the Policy Activity statusCode
                 (C-CDA fixes it to 'completed', meaning the recording is complete, so completed/active -> active;
                 defensive mappings for other ActStatus codes; default active) -->
            <status>
                <xsl:attribute name="value">
                    <xsl:choose>
                        <xsl:when test="cda:statusCode/@code = 'cancelled' or cda:statusCode/@code = 'aborted'">cancelled</xsl:when>
                        <xsl:when test="cda:statusCode/@code = 'nullified'">entered-in-error</xsl:when>
                        <xsl:when test="cda:statusCode/@code = 'new'">draft</xsl:when>
                        <xsl:otherwise>active</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </status>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">subscriber</xsl:with-param>
            </xsl:call-template>

            <xsl:choose>
                <xsl:when test="cda:participant[@typeCode = 'COV']">
                    <xsl:choose>

                        <xsl:when test="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']">
                            <!-- 20260729 Claude: Fix - subscriberId previously defaulted to the literal string "NI"
                                 (fake data); a nullFlavor'd id now gets a data-absent-reason extension and when there is
                                 no usable id at all the element is omitted -->
                            <xsl:choose>
                                <xsl:when test="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']/cda:id/@extension">
                                    <subscriberId>
                                        <xsl:attribute name="value" select="xs:string(cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']/cda:id[@extension][1]/@extension)" />
                                    </subscriberId>
                                </xsl:when>
                                <xsl:when test="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']/cda:id/@nullFlavor">
                                    <subscriberId>
                                        <xsl:apply-templates select="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']/cda:id[@nullFlavor][1]/@nullFlavor" mode="data-absent-reason-extension" />
                                    </subscriberId>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">beneficiary</xsl:with-param>
            </xsl:call-template>

            <xsl:choose>
                <xsl:when test="cda:participant[@typeCode = 'COV']">
                    <xsl:choose>
                        <xsl:when test="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']">
                            <xsl:apply-templates select="cda:participant[@typeCode = 'COV']/cda:participantRole[@classCode = 'PAT']/cda:code">
                                <xsl:with-param name="pElementName">relationship</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>

            <!-- 20260729 Claude: removed unused $vTest variable and the redundant choose (applying templates to an
                 empty selection is already a no-op) -->
            <xsl:apply-templates select="cda:performer[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.87']/cda:time" />

            <xsl:if test="
                    cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]
                    [cda:assignedEntity[cda:code[@code = 'PAYOR']]]">
                <payor>
                    <xsl:apply-templates select="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]" mode="reference" />
                </payor>
            </xsl:if>


            <!-- Commenting out for now, makes invalid assumption that the contained clinical statement is an act and maps it to Coverage.class. Should probably be a separate Claim or ExplanationOfBenefit resource -->
            <!--
            <xsl:choose>
                <xsl:when test="cda:entryRelationship[@typeCode='REFR']">
                    <xsl:apply-templates 
                        select="cda:entryRelationship[@typeCode='REFR']/
                        cda:act[cda:templateId/@root='2.16.840.1.113883.10.20.1.19']/
                        cda:entryRelationship[@typeCode='SUBJ']" mode="SUBJ"/>
                </xsl:when>
            </xsl:choose>
            -->


            <!-- RG: Commented out for demo -->
            <!--
            <xsl:if test="cda:participant[@typeCode= 'HLD']">
                <policyHolder>
                    <xsl:apply-templates select="cda:participant[@typeCode= 'HLD']" mode="reference"/>
                </policyHolder>
            </xsl:if>
            -->

            <!--
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">subscriber</xsl:with-param>
            </xsl:call-template>
            <xsl:if test="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.89']]">
                <subscriberId value="urn:hl7ii:{cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.89']]
                    /cda:participantRole/cda:id/@root}:{cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.89']]
                    /cda:participantRole/cda:id/@extension}"/>
            </xsl:if>
            -->

        </Coverage>
    </xsl:template>

    <!-- 20260729 Claude: removed dead template match="cda:entryRelationship" mode="SUBJ" - its only caller is the
         commented-out Coverage.class block above (which notes the mapping made an invalid assumption) -->

    <xsl:template match="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]" mode="payor">
        <Organization>
            <xsl:apply-templates select="cda:id" />
            <active value="true" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            <!-- 20260729 Claude: removed stray copy-pasted comment "Pregnancy Status Recorded Date" that was emitted
                 into every payor Organization -->

            <!-- MD: add comment for CCDA missing name for cause validation error -->
            <xsl:choose>
                <xsl:when test="cda:representedOrganization/cda:name">
                    <name>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:representedOrganization/cda:name" />
                        </xsl:attribute>
                    </name>
                </xsl:when>
                <xsl:otherwise>
                    <!-- 20260729 Claude: Fix - typo "Orgainzation" in the warning message (same as Organization.xslt) -->
                    <xsl:comment>WARNING: Missing cda:representedOrganization/cda:name in CDA document</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
            <!--
            <xsl:if test="cda:representedOrganization/cda:name">
                <name>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:representedOrganization/cda:name"/>
                    </xsl:attribute>
                </name>
            </xsl:if>
              -->
            <xsl:apply-templates select="cda:telecom" />
            <xsl:apply-templates select="cda:addr" />
        </Organization>
    </xsl:template>



</xsl:stylesheet>
