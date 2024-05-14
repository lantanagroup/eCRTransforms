<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act/cda:participant" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500']]">
        <CareTeam>
            <!-- set meta profile based on Ig -->
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />

            <xsl:choose>
                <xsl:when test="cda:statusCode/@code = 'active'">
                    <status value="active" />
                </xsl:when>
            </xsl:choose>

            <xsl:call-template name="subject-reference" />

            <xsl:apply-templates select="cda:effectiveTime" mode="period">
                <xsl:with-param name="pElementName">period</xsl:with-param>
            </xsl:apply-templates>
            <!-- Care Team Member Act -->
            <xsl:for-each select="cda:component/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.500.1']]">
                <participant>
                    <!-- role -->
                    <xsl:choose>
                        <xsl:when test="cda:performer/cda:functionCode">
                            <xsl:apply-templates select="cda:performer/cda:functionCode">
                                <xsl:with-param name="pElementName">role</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="cda:performer/sdtc:functionCode">
                            <xsl:apply-templates select="cda:performer/sdtc:functionCode">
                                <xsl:with-param name="pElementName">role</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <role>
                                <coding>
                                    <system value="http://terminology.hl7.org/ValueSet/v3-xServiceEventPerformer"/>
                                    <code value="@typeCode"/>
                                    <xsl:choose>
                                        <xsl:when test="'PPRF'">
                                            <display value="primary performer"/>
                                        </xsl:when>
                                        <xsl:when test="'PRF'">
                                            <display value="performer"/>
                                        </xsl:when>
                                        <xsl:when test="'SPRF'">
                                            <display value="secondary performer"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </coding>
                            </role>
                        </xsl:otherwise>
                    </xsl:choose>
                    <member>
                        <xsl:apply-templates select="cda:performer/cda:assignedEntity" mode="reference" />
                    </member>
                    <xsl:if test="cda:performer/cda:representedOrganization">
                        <onBehalfOf>
                            <xsl:apply-templates select="cda:performer/cda:assignedEntity/cda:representedOrganization" mode="reference" />
                        </onBehalfOf>
                    </xsl:if>
                    <xsl:apply-templates select="cda:effectiveTime" mode="period">
                        <xsl:with-param name="pElementName">period</xsl:with-param>
                    </xsl:apply-templates>
                </participant>
            </xsl:for-each>
        </CareTeam>
    </xsl:template>

    <!-- Create a CareTeam from a bunch of peformers for later reference in an Episode of Care -->
    <xsl:template name="create-care-team">
        <entry>
            <!-- use the documentationOf uuid for this fullUrl because there isn't a corresponding one -->
            <fullUrl value="urn:uuid:{parent::cda:documentationOf/@lcg:uuid}" />
            <resource>
                <CareTeam>
                    <meta>
                        <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam" />
                    </meta>
                    <!-- subject -->
                    <xsl:call-template name="subject-reference">
                        <xsl:with-param name="pElementName">subject</xsl:with-param>
                    </xsl:call-template>
                    <!-- period -->
                    <xsl:apply-templates select="cda:effectiveTime" mode="period">
                        <xsl:with-param name="pElementName">period</xsl:with-param>
                    </xsl:apply-templates>

                    <!-- participant -->
                    <xsl:for-each select="cda:performer">
                        <participant>
                            <!-- role -->
                            <xsl:choose>
                                <xsl:when test="cda:functionCode">
                                    <xsl:apply-templates select="cda:functionCode">
                                        <xsl:with-param name="pElementName">role</xsl:with-param>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:when test="sdtc:functionCode">
                                    <xsl:apply-templates select="sdtc:functionCode">
                                        <xsl:with-param name="pElementName">role</xsl:with-param>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <role>
                                        <coding>
                                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType"/>
                                            <code value="{@typeCode}"/>
                                            <xsl:choose>
                                                <xsl:when test="'PPRF'">
                                                    <display value="primary performer"/>
                                                </xsl:when>
                                                <xsl:when test="'PRF'">
                                                    <display value="performer"/>
                                                </xsl:when>
                                                <xsl:when test="'SPRF'">
                                                    <display value="secondary performer"/>
                                                </xsl:when>
                                            </xsl:choose>
                                        </coding>
                                    </role>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- member -->
                            <xsl:apply-templates select="cda:assignedEntity" mode="reference">
                                <xsl:with-param name="wrapping-elements">member</xsl:with-param>
                            </xsl:apply-templates>
                            <xsl:if test="cda:assignedEntity/cda:representedOrganization">
                                <!-- onBehalfOf -->
                                <xsl:apply-templates select="cda:assignedEntity/cda:representedOrganization" mode="reference">
                                    <xsl:with-param name="wrapping-elements">onBehalfOf</xsl:with-param>
                                </xsl:apply-templates>
                            </xsl:if>
                            <xsl:apply-templates select="cda:time" mode="period">
                                <xsl:with-param name="pElementName">period</xsl:with-param>
                            </xsl:apply-templates>
                        </participant>
                    </xsl:for-each>
                </CareTeam>
            </resource>
        </entry>
    </xsl:template>
</xsl:stylesheet>
