<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']" mode="bundle-entry">
        <!-- Don't want a second encounter if this is eICR (unless this is a planned encounter) -->

        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <!-- Encounter Diagnosis/Problem Observation -->
        <xsl:apply-templates
            select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']/cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']"
            mode="bundle-entry" />
    </xsl:template>

    <!-- Planned Encounter -->
    <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']">
        <Appointment>
            <!-- set meta profile based on Ig -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'NA'">
                    <xsl:call-template name="add-meta" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$gvCurrentIg" />
                            <xsl:with-param name="pResource" select="'Appointment'" />
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
            <!-- identifier -->
            <xsl:apply-templates select="cda:id" />
            <!-- status -->
            <xsl:choose>
                <xsl:when test="@moodCode = 'INT' or @moodCode = 'RQO'">
                    <status value="proposed" />
                </xsl:when>
                <xsl:when test="@moodCode = 'APT'">
                    <status value="booked" />
                </xsl:when>
            </xsl:choose>
            <!-- cancelationReason -->
            <!-- serviceCategory -->
            <!-- serviceType -->
            <xsl:for-each select="cda:code[not(@codeSystem = '2.16.840.1.113883.1.11.13955')]">
                <xsl:call-template name="newCreateCodableConcept">
                    <xsl:with-param name="pElementName" select="'serviceType'" />
                    <xsl:with-param name="pIncludeCoding" select="true()" />
                    <xsl:with-param name="includeTranslations" select="true()" />
                </xsl:call-template>
            </xsl:for-each>
            <!-- speciality -->
            <!-- appointmentType -->
            <xsl:choose>
                <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.5.4']">
                    <appointmentType>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                            <code value="{cda:code/@code}" />
                        </coding>
                    </appointmentType>
                </xsl:when>
                <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']">
                    <appointmentType>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                            <code value="{cda:code/cda:translation/@code}" />
                        </coding>
                    </appointmentType>
                </xsl:when>
                <!-- MD: add for ambulatory-->
                <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <appointmentType>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                            <code value="{cda:code/@code}" />
                        </coding>
                    </appointmentType>
                </xsl:when>
                <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <appointmentType>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                            <code value="{cda:code/cda:translation/@code}" />
                        </coding>
                    </appointmentType>
                </xsl:when>
                <xsl:otherwise>
                    <appointmentType>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
                            <code value="NI" />
                            <display value="NoInformtion" />
                        </coding>
                    </appointmentType>
                </xsl:otherwise>
            </xsl:choose>
            <!-- reasonCode -->
            <xsl:for-each select="cda:entryRelationship[@typeCode = 'RSON']/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
                <xsl:apply-templates select="cda:value[@xsi:type = 'CD']">
                    <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <!-- reasonReference -->
            <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
                    <reasonReference>
                        <xsl:apply-templates select="." mode="reference" />
                    </reasonReference>
                </xsl:for-each>
            </xsl:for-each>
            <!-- priority -->
            <!-- description -->
            <!-- supportingInformation -->
            <!-- start TODO -->
            <xsl:variable name="vPeriod">
                <xsl:apply-templates select="cda:effectiveTime" mode="period" />
            </xsl:variable>
            <xsl:copy-of select="$vPeriod/fhir:period/fhir:start" />
            <!-- end -->
            <xsl:choose>
                <xsl:when test="$vPeriod/fhir:period/fhir:end">
                    <xsl:copy-of select="$vPeriod/fhir:period/fhir:end" />
                </xsl:when>
                <xsl:otherwise>
                    <end>
                        <xsl:attribute name="value" select="$vPeriod/fhir:period/fhir:start/@value" />
                    </end>
                </xsl:otherwise>
            </xsl:choose>

            <!-- minutesDuration -->
            <!-- slot -->
            <!-- created -->
            <!-- comment -->
            <!-- patientInstruction -->
            <!-- basedOn -->
            <!-- participant (patient) -->
            <participant>
                <type>
                    <coding>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                        <code value="SBJ" />
                    </coding>
                </type>
                <xsl:call-template name="subject-reference">
                    <xsl:with-param name="pElementName">actor</xsl:with-param>
                </xsl:call-template>
                <required value="required" />
                <status value="accepted" />
            </participant>

            <!-- participant (others) -->
            <xsl:for-each select="cda:performer[not(@nullFlavor)]">
                <participant>
                    <actor>
                        <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
                    </actor>
                    <required value="required" />
                    <status value="accepted" />
                </participant>
            </xsl:for-each>
            <xsl:for-each select="cda:author/cda:assignedAuthor[cda:assignedPerson]">
                <participant>
                    <xsl:for-each select="cda:assignedPerson">
                        <xsl:apply-templates select="." mode="rename-reference-participant">
                            <xsl:with-param name="pElementName">actor</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:for-each>
                    <required value="required" />
                    <status value="accepted" />
                </participant>
            </xsl:for-each>
            <!-- requestedPeriod -->
        </Appointment>
    </xsl:template>

</xsl:stylesheet>
