<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.52'][@moodCode = 'EVN']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <!-- create organization from cda:consumable/cda:manufacturedProduct/cda:manufacturerOrganization -->
        <xsl:apply-templates select="cda:consumable/cda:manufacturedProduct/cda:manufacturerOrganization" mode="bundle-entry" />

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.52'][@moodCode = 'EVN']">
        <Immunization>
            <!-- meta -->
            <xsl:call-template name="add-meta" />
            <!-- identifier -->
            <xsl:apply-templates select="cda:id" />
            <!-- status -->
            <xsl:choose>
                <xsl:when test="@negationInd = 'true'">
                    <status value="not-done" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:statusCode" mode="map-immunization-status" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- statusReason: C-CDA Immunization Refusal Reason (2.16.840.1.113883.10.20.22.4.53) -->
            <xsl:if test="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.53']">
                <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.53']/cda:code">
                    <xsl:with-param name="pElementName">statusReason</xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            <!-- vaccineCode -->
            <xsl:apply-templates select="cda:consumable" mode="immunization" />
            <!-- patient -->
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <!-- encounter -->
            <!-- occurrence[x] -->
            <xsl:apply-templates select="cda:effectiveTime" mode="instant">
                <xsl:with-param name="pElementName">occurrenceDateTime</xsl:with-param>
            </xsl:apply-templates>

            <xsl:comment>INFO: Defaulting primarySource to data-absent-reason='unknown' since this required data element is not in the C-CDA Immunization Activity template</xsl:comment>
            <primarySource>
                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                    <valueCode value="unknown" />
                </extension>
            </primarySource>

            <!-- manufacturer -->
            <!-- create organization from cda:consumable/cda:manufacturedProduct/cda:manufacturerOrganization -->
            <xsl:apply-templates select="cda:consumable/cda:manufacturedProduct/cda:manufacturerOrganization" mode="reference">
                <xsl:with-param name="wrapping-elements">manufacturer</xsl:with-param>
            </xsl:apply-templates>

            <!-- lotNumber -->
            <xsl:for-each select="cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:lotNumberText[not(@nullFlavor)]">
                <lotNumber value="{.}" />
            </xsl:for-each>
            <!-- site -->
            <xsl:apply-templates select="cda:approachSiteCode">
                <xsl:with-param name="pElementName">site</xsl:with-param>
            </xsl:apply-templates>
            <!-- route -->
            <xsl:apply-templates select="cda:routeCode">
                <xsl:with-param name="pElementName">route</xsl:with-param>
            </xsl:apply-templates>
            <!-- doseQuantity -->
            <xsl:apply-templates select="cda:doseQuantity">
                <xsl:with-param name="pElementName">doseQuantity</xsl:with-param>
                <xsl:with-param name="pSimpleQuantity" select="true()" />
            </xsl:apply-templates>
            <!-- performer -->
            <xsl:apply-templates select="cda:performer/cda:assignedEntity" mode="reference">
                <xsl:with-param name="wrapping-elements">performer/actor</xsl:with-param>
            </xsl:apply-templates>

            <!-- note -->
            <xsl:for-each select="cda:text">
                <xsl:variable name="vText">
                    <xsl:choose>
                        <xsl:when test="cda:reference">
                            <xsl:call-template name="get-reference-text">
                                <xsl:with-param name="pTextElement" select="." />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="." />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:if test="string-length($vText) > 0">
                    <note>
                        <text>
                            <xsl:attribute name="value" select="$vText" />
                        </text>
                    </note>
                </xsl:if>
            </xsl:for-each>

            <!-- reasonReference (C-CDA Indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>

            <!-- reaction -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.9']">
                <reaction>
                    <detail>
                        <reference value="urn:uuid:{@lcg:uuid}" />
                    </detail>
                </reaction>
            </xsl:for-each>

            <!-- protocolApplied/doseNumberPositiveInt -->
            <xsl:for-each select="cda:repeatNumber">
                <protocolApplied>
                    <doseNumberPositiveInt>
                        <xsl:attribute name="value" select="@value" />
                    </doseNumberPositiveInt>
                </protocolApplied>
            </xsl:for-each>
        </Immunization>
    </xsl:template>

    <xsl:template match="cda:consumable" mode="immunization">
        <xsl:apply-templates select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code">
            <xsl:with-param name="pElementName">vaccineCode</xsl:with-param>
        </xsl:apply-templates>
        <!--<xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">vaccineCode</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>-->
    </xsl:template>

</xsl:stylesheet>
