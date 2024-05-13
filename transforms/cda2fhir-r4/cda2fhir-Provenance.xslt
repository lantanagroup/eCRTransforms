<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- Put CDA participants with nowhere to go in FHIR in Provenance resource -->

    <!-- ClinicalDocument level participants -->
    <xsl:template match="cda:dataEnterer | cda:informant[parent::cda:ClinicalDocument]" mode="provenance">
        <entry>
            <fullUrl value="urn:uuid:{@lcg:uuid}" />
            <resource>
                <Provenance>
                    <target>
                        <reference value="urn:uuid:{/cda:ClinicalDocument/@lcg:uuid}" />
                    </target>
                    <xsl:choose>
                        <xsl:when test="cda:time">
                            <xsl:apply-templates select="cda:time" mode="instant">
                                <xsl:with-param name="pDataType">instant</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="cda:relatedEntity/cda:time">
                            <xsl:apply-templates select="cda:relatedEntity/cda:time" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                                <xsl:with-param name="pDataType">instant</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="/cda:ClinicalDocument/cda:effectiveTime" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                                <xsl:with-param name="pDataType">instant</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                    <agent>
                        <type>
                            <coding>
                                <system value="http://terminology.hl7.org/CodeSystem/provenance-participant-type" />
                                <xsl:choose>
                                    <xsl:when test="self::cda:dataEnterer">
                                        <code value="enterer" />
                                    </xsl:when>
                                    <xsl:when test="self::cda:informant">
                                        <code value="informant" />
                                    </xsl:when>
                                </xsl:choose>
                            </coding>
                        </type>
                        <who>
                            <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid | cda:relatedEntity/@lcg:uuid}" />
                        </who>
                    </agent>
                </Provenance>
            </resource>
        </entry>
    </xsl:template>

    <!-- Entry-level participants -->
    <xsl:template match="cda:author | cda:performer" mode="provenance">
        <xsl:param name="pTargetUUID"/>
        <entry>
            <fullUrl value="urn:uuid:{@lcg:uuid}" />
            <resource>
                <Provenance>
                    <xsl:choose>
                        <!-- when we've passed in a specific uuid, use that -->
                        <xsl:when test="string-length($pTargetUUID)>0">
                            <target>
                                <reference value="urn:uuid:{$pTargetUUID}" />
                            </target>
                        </xsl:when>
                        <!-- When this is contained in a Problem Concern Act, because the Problem Concern Act doesn't have a target in FHIR,
                                 set the target to any contained Problem Observations -->
                        <xsl:when test="parent::cda:act/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']">
                            <xsl:for-each select="following-sibling::cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]">
                                <target>
                                    <reference value="urn:uuid:{@lcg:uuid}" />
                                </target>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <target>
                                <reference value="urn:uuid:{parent::cda:*/@lcg:uuid}" />
                            </target>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="cda:time">
                            <xsl:apply-templates select="cda:time" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                                <xsl:with-param name="pDataType">instant</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="/cda:ClinicalDocument/cda:effectiveTime" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                                <xsl:with-param name="pDataType">instant</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                    <agent>
                        <type>
                            <coding>
                                <system value="http://terminology.hl7.org/CodeSystem/provenance-participant-type" />
                                <xsl:choose>
                                    <xsl:when test="self::cda:author">
                                        <code value="author" />
                                    </xsl:when>
                                    <xsl:when test="self::cda:performer">
                                        <code value="performer" />
                                    </xsl:when>
                                </xsl:choose>
                            </coding>
                        </type>
                        <who>
                            <xsl:choose>
                                <xsl:when test="self::cda:author">
                                    <xsl:variable name="vAuthorUUID">
                                        <xsl:call-template name="get-author-uuid">
                                            <xsl:with-param name="pAuthor" select="." />
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <reference value="urn:uuid:{$vAuthorUUID}" />
                                </xsl:when>
                                <xsl:when test="self::cda:performer">
                                    <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                                </xsl:when>
                            </xsl:choose>

                        </who>
                    </agent>
                </Provenance>
            </resource>
        </entry>
    </xsl:template>
</xsl:stylesheet>
