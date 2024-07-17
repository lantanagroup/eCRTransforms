<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">
    <!-- Match all substanceAdministration with moodCode of 'INT' - this is an evoloving mapping in the C-CDA to FHIR project - will update when that group has decided on mapping -->
    <xsl:template match="cda:substanceAdministration[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.16' or @root = '2.16.840.1.113883.10.20.22.4.42']][@moodCode = 'INT']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <!--<xsl:apply-templates select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18']]" mode="bundle-entry" />-->

        <xsl:apply-templates select="cda:consumable/cda:manufacturedProduct" mode="bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer[cda:assignedEntity]" mode="bundle-entry" />

        <xsl:for-each select="cda:author[position() > 1] | cda:informant | cda:performer[position() > 1]">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:substanceAdministration[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.16' or @root = '2.16.840.1.113883.10.20.22.4.42']][@moodCode = 'INT'][not(@nullFlavor)]">
        <MedicationRequest>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest" />
            </meta>
            <xsl:apply-templates select="cda:id" />
            
            <!-- status -->
            <xsl:apply-templates select="cda:statusCode" mode='map-medication-status'>
                <xsl:with-param name="pMoodCode" select="@moodCode"/>
                <xsl:with-param name="pMedicationResource" select="'MedicationRequest'"/>
            </xsl:apply-templates>
            
            <!-- This is an actual order in the Pharmacist's system -->
            <intent value="order" />

            <!--            <xsl:apply-templates select="cda:consumable" mode="medication-request" />-->
            <xsl:for-each select="cda:consumable/cda:manufacturedProduct">
                <medicationReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </medicationReference>
            </xsl:for-each>

            <!-- subject -->
            <xsl:call-template name="subject-reference" />

            <!-- supportingInformation: anything in an entryRelationship that isn't already mapped -->
            <xsl:for-each select="cda:entryRelationship/cda:*[not(cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.19']) and not(cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.118'])]">
                <supportingInformation>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </supportingInformation>
            </xsl:for-each>

            <!-- authoredOn -->
            <xsl:choose>
                <xsl:when test="cda:author[1]/cda:time/@value">
                    <authoredOn value="{lcg:cdaTS2date(cda:author[1]/cda:time/@value)}" />
                </xsl:when>
                <xsl:when test="ancestor::cda:*/cda:author[1]/cda:time/@value">
                    <authoredOn value="{lcg:cdaTS2date(ancestor::cda:*/cda:author[1]/cda:time/@value)}" />
                </xsl:when>
            </xsl:choose>

            <!-- requester (required and max 1)-->
            <!-- get closest author (work up the hierarchy if needed) -->
            <xsl:variable name="vClosestAuthor">
                <xsl:call-template name="get-closest-author" />
            </xsl:variable>
            <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">requester</xsl:with-param>
            </xsl:apply-templates>

            <!-- performer (max 1)-->
            <xsl:apply-templates select="cda:performer[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">performer</xsl:with-param>
            </xsl:apply-templates>

            <!-- reasonReference (c-cda indication) -->
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.19']]">
                <reasonReference>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </reasonReference>
            </xsl:for-each>

            <!-- SG 202201: dosageInstruction isn't required, so if there is no data we don't want an empty element -->
            <xsl:if
                test="cda:text or cda:approachSiteCode or cda:routeCode or (not(cda:doseQuantity/@nullFlavor) and cda:doseQuantity) or cda:effectiveTime[@xsi:type = 'IVL_TS'] or cda:effectiveTime[@operator = 'A']">
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
                    <xsl:if test="cda:effectiveTime[@xsi:type = 'IVL_TS'] or cda:effectiveTime[@operator = 'A'] or cda:effectiveTime[@value]">
                        <timing>
                            <xsl:if test="cda:effectiveTime[@value][not(@operator = 'A')]">
                                <xsl:apply-templates select="cda:effectiveTime[@value][not(@operator = 'A')]" mode="instant">
                                    <xsl:with-param name="pElementName">event</xsl:with-param>
                                </xsl:apply-templates>
                            </xsl:if>
                            <xsl:if test="cda:effectiveTime[@xsi:type = 'IVL_TS'] or cda:effectiveTime[@operator = 'A']">
                                <repeat>
                                    <xsl:apply-templates select="cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-request" />
                                    <xsl:apply-templates select="cda:effectiveTime[@operator = 'A'][not(@xsi:type = 'EIVL_TS')]" mode="medication-request" />
                                </repeat>
                            </xsl:if>
                            <xsl:if test="cda:effectiveTime[@xsi:type = 'EIVL_TS']/cda:event[@code]">
                                <code>
                                    <coding>
                                        <system value="http://terminology.hl7.org/CodeSystem/v3-TimingEvent" />
                                        <code value="{cda:effectiveTime/cda:event/@code}" />
                                    </coding>
                                </code>
                            </xsl:if>
                        </timing>
                    </xsl:if>
                    <xsl:apply-templates select="cda:approachSiteCode">
                        <xsl:with-param name="pElementName">site</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:routeCode">
                        <xsl:with-param name="pElementName">route</xsl:with-param>
                    </xsl:apply-templates>

                    <!--MD: doseAndRate must have at lease one child element -->
                    <xsl:if test="(not(cda:doseQuantity/@nullFlavor) and cda:doseQuantity) or (not(cda:rateQuantity/@nullFlavor) and cda:rateQuantity)">
                        <doseAndRate>
                            <xsl:apply-templates select="cda:doseQuantity">
                                <xsl:with-param name="pElementName">doseQuantity</xsl:with-param>
                                <xsl:with-param name="pSimpleQuantity" select="true()" />
                            </xsl:apply-templates>
                            <xsl:apply-templates select="cda:rateQuantity">
                                <xsl:with-param name="pElementName">rateQuantity</xsl:with-param>
                                <xsl:with-param name="pSimpleQuantity" select="true()" />
                            </xsl:apply-templates>
                        </doseAndRate>
                    </xsl:if>
                    <xsl:if test="cda:maxDoseQuantity">
                        <maxDosePerPeriod>
                            <numerator>
                                <value>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="cda:maxDoseQuantity/cda:numerator/@value" />
                                    </xsl:attribute>
                                </value>
                            </numerator>
                            <denominator>
                                <value>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="cda:maxDoseQuantity/cda:denominator/@value" />
                                    </xsl:attribute>
                                </value>
                                <unit>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="cda:maxDoseQuantity/cda:denominator/@unit" />
                                    </xsl:attribute>
                                </unit>
                                <system value="http://unitsofmeasure.org" />
                            </denominator>
                        </maxDosePerPeriod>
                    </xsl:if>
                </dosageInstruction>
            </xsl:if>

            <!-- dispenseRequest -->
            <xsl:if test="cda:repeatNumber/@value > 0 or cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]">
                <dispenseRequest>
                    <!-- dispenseInterval -->
                    <xsl:if test="
                            cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:effectiveTime/cda:high/@value and
                            cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:effectiveTime/cda:low/@value">
                        <xsl:variable name="vIntervalDays">
                            <xsl:value-of select="
                                    days-from-duration(xs:date(lcg:cdaTS2date(cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:effectiveTime/cda:high/@value)) -
                                    xs:date(lcg:cdaTS2date(cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:effectiveTime/cda:low/@value)))"
                             />
                        </xsl:variable>
                        <dispenseInterval>
                            <value>
                                <xsl:attribute name="value" select="$vIntervalDays" />
                            </value>
                            <unit value="days" />
                            <system value="http://unitsofmeasure.org" />
                            <code value="d" />
                        </dispenseInterval>
                    </xsl:if>

                    <!-- repeatNumber -->
                    <!-- there can be a repeat number in the main substanceAdministration and in the Supply Order, use the main one first and 
                     only if that doesn't exist use the one in the supply order-->
                    <xsl:choose>
                        <xsl:when test="cda:repeatNumber">
                            <xsl:apply-templates select="cda:repeatNumber" mode="medication-request" />
                        </xsl:when>
                        <xsl:when test="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:repeatNumber">
                            <xsl:apply-templates select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:repeatNumber" mode="medication-request" />
                        </xsl:when>
                    </xsl:choose>
                    <!-- quantity -->
                    <xsl:if test="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:quantity/@value">
                        <quantity>
                            <value>
                                <xsl:attribute name="value" select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:quantity/@value" />
                            </value>
                        </quantity>
                    </xsl:if>

                    <!-- performer (max 1): can only be an Organization -->
                    <xsl:apply-templates select="cda:entryRelationship/cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']]/cda:performer[1][cda:assignedEntity/cda:representedOrganization]"
                        mode="rename-reference-participant">
                        <xsl:with-param name="pElementName">performer</xsl:with-param>
                        <xsl:with-param name="pParticipantType">organization</xsl:with-param>
                    </xsl:apply-templates>
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

    <xsl:template match="cda:repeatNumber" mode="medication-request">
        <xsl:variable name="vRepeats" select="@value - 1"/>
        <numberOfRepeatsAllowed value="{$vRepeats}" />
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A'][@xsi:type = 'PIVL_TS']" mode="medication-request">


        <!--<xsl:if test="cda:period">
            <period value="{cda:period/@value}" />
            <periodUnit value="{cda:period/@unit}" />
        </xsl:if>-->

        <xsl:choose>
            <xsl:when test="cda:period/@value and not(cda:period/cda:low) and not(cda:period/cda:high)">
                <period>
                    <xsl:attribute name="value">
                        <xsl:value-of select="normalize-space(cda:period/@value)" />
                    </xsl:attribute>
                </period>
                <periodUnit value="{cda:period/@unit}" />
            </xsl:when>
            <xsl:when test="not(cda:period/@value) and cda:period/cda:low/@value and cda:period/cda:high/@value">
                <period>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:period/cda:low/@value" />
                    </xsl:attribute>
                </period>
                <periodMax>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:period/cda:high/@value" />
                    </xsl:attribute>
                </periodMax>
                <periodUnit value="{cda:period/cda:low/@unit}" />
            </xsl:when>
            <xsl:when test="not(cda:period/@value) and cda:period/cda:low/@value">
                <period>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:period/cda:low/@value" />
                    </xsl:attribute>
                </period>
                <periodUnit value="{cda:period/cda:low/@unit}" />
            </xsl:when>
            <xsl:when test="not(cda:period/@value) and not(cda:period/cda:low/@value) and cda:period/cda:high/@value">
                <period>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:period/cda:high/@value" />
                    </xsl:attribute>
                </period>
                <periodUnit value="{cda:period/cda:high/@unit}" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A']" mode="medication-request" priority="-1">
        <xsl:comment>WARNING: Unknown effectiveTime pattern: 
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
