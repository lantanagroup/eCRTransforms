<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <xsl:template match="cda:substanceAdministration[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.16' or @root = '2.16.840.1.113883.10.20.22.4.42']][@moodCode = 'INT']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18']]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
    </xsl:template>


    <xsl:template match="cda:substanceAdministration[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.16' or @root = '2.16.840.1.113883.10.20.22.4.42']][@moodCode = 'INT'][not(@nullFlavor)]">
        <MedicationRequest>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest" />
            </meta>
            <xsl:apply-templates select="cda:id" />
            <status value="active" />
            <!-- This is an actual order in the Pharmacist's system -->
            <intent value="order" />
            <xsl:apply-templates select="cda:consumable" mode="medication-request" />
            <xsl:call-template name="subject-reference" />
            <xsl:choose>
                <xsl:when test="cda:*/cda:author[1]/cda:time/@value">
                    <authoredOn value="{lcg:cdaTS2date(cda:author/cda:time/@value)}" />
                </xsl:when>
                <xsl:when test="ancestor::cda:*/cda:author[1]/cda:time/@value">
                    <authoredOn value="{lcg:cdaTS2date(ancestor::cda:*/cda:author[1]/cda:time/@value)}" />
                </xsl:when>
            </xsl:choose>

            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">requester</xsl:with-param>
            </xsl:call-template>

            <!-- SG 202201: dosageInstruction isn't required, so if there is no data we don't want an empty element -->
            <xsl:if test="cda:text or cda:routeCode or (not(cda:doseQuantity/@nullFlavor) and cda:doseQuantity) or cda:effectiveTime[@xsi:type = 'IVL_TS'] or cda:effectiveTime[@operator = 'A']">
                <dosageInstruction>
                    <xsl:choose>
                        <xsl:when test="cda:text">
                            <xsl:choose>
                                <xsl:when test="cda:text/cda:reference/@value">
                                    <xsl:variable name="vRefValue" select="substring-after(cda:text/cda:reference/@value, '#')" />
                                    <xsl:variable name="vTest" select="../../cda:text/cda:table/cda:tbody/cda:tr/@ID" />
                                    <xsl:choose>
                                        <xsl:when test="../../cda:text/cda:table/cda:tbody/cda:tr[@ID = $vRefValue]">
                                            <xsl:variable name="vTextValue">
                                                <xsl:apply-templates select="../../cda:text/cda:table/cda:tbody/cda:tr[@ID = $vRefValue]/cda:td" mode="textRefValue" />
                                            </xsl:variable>
                                            <text>
                                                <xsl:attribute name="value" select="$vTextValue" />
                                            </text>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <text>
                                        <xsl:attribute name="value">
                                            <xsl:value-of select="cda:text" />
                                        </xsl:attribute>
                                    </text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:if test="cda:effectiveTime[@xsi:type = 'IVL_TS'] or cda:effectiveTime[@operator = 'A']">
                        <timing>
                            <repeat>
                                <xsl:apply-templates select="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-request" />
                                <xsl:apply-templates select="cda:effectiveTime[@operator = 'A']" mode="medication-request" />
                            </repeat>
                        </timing>
                    </xsl:if>
                    <xsl:apply-templates select="cda:routeCode">
                        <xsl:with-param name="pElementName">route</xsl:with-param>
                    </xsl:apply-templates>

                    <!--MD: doseAndRate must have at lease one child element -->
                    <xsl:if test="not(cda:doseQuantity/@nullFlavor) and cda:doseQuantity">
                        <doseAndRate>
                            <xsl:apply-templates select="cda:doseQuantity">
                                <xsl:with-param name="pElementName">doseQuantity</xsl:with-param>
                                <xsl:with-param name="pSimpleQuantity" select="true()" />
                            </xsl:apply-templates>
                        </doseAndRate>
                    </xsl:if>

                </dosageInstruction>
            </xsl:if>


            <xsl:if test="cda:repeatNumber/@value and cda:repeatNumber/@value > 0">
                <dispenseRequest>
                    <xsl:apply-templates select="cda:repeatNumber" mode="medication-request" />
                </dispenseRequest>
            </xsl:if>
        </MedicationRequest>
    </xsl:template>


    <xsl:template match="cda:td" mode="textRefValue">
        <xsl:for-each select=".">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:template>



    <xsl:template match="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-request">
        <boundsPeriod>
            <xsl:if test="cda:low[not(@nullFlavor)]">
                <start value="{lcg:cdaTS2date(cda:low/@value)}" />
            </xsl:if>
            <xsl:if test="cda:high[not(@nullFlavor)]">
                <end value="{lcg:cdaTS2date(cda:high/@value)}" />
            </xsl:if>
        </boundsPeriod>
    </xsl:template>

    <!--<xsl:template match="cda:doseQuantity" mode="medication-request">
        <doseQuantity>
            <xsl:if test="@value">
                <value value="{@value}"/>
            </xsl:if>
            <xsl:if test="@unit">
                <unit value="{@unit}"/>
            </xsl:if>
            <xsl:if test="@nullFlavor">
                <code value="{@nullFlavor}"/>
              <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor"/>
            </xsl:if>
        </doseQuantity>
    </xsl:template>-->


    <xsl:template match="cda:repeatNumber" mode="medication-request">
        <numberOfRepeatsAllowed value="{@value}" />
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A'][@xsi:type = 'PIVL_TS']" mode="medication-request">
        <xsl:if test="cda:period">
            <period value="{cda:period/@value}" />
            <periodUnit value="{cda:period/@unit}" />
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A']" mode="medication-request" priority="-1">
        <xsl:comment>Unknown effectiveTime pattern: 
            <cda:effectiveTime>
                <xsl:copy />
            </cda:effectiveTime>
        </xsl:comment>
    </xsl:template>

    <xsl:template match="cda:consumable" mode="medication-request">
        <medicationCodeableConcept>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@code][@codeSystem]">
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <xsl:if test="@displayName">
                        <display value="{@displayName}" />
                    </xsl:if>
                </coding>
            </xsl:for-each>
            <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@code][@codeSystem]">
                <coding>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="@codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                    <code value="{@code}" />
                    <xsl:if test="@displayName">
                        <display value="{@displayName}" />
                    </xsl:if>
                </coding>
            </xsl:for-each>
        </medicationCodeableConcept>
    </xsl:template>

</xsl:stylesheet>
