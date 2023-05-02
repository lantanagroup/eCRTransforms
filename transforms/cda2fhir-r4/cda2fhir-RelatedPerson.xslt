<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt"/>

    <xsl:template match="cda:section" mode="relatedPerson-entry">
        <xsl:for-each
            select="cda:entry/cda:organizer/cda:subject/cda:relatedSubject[@classCode = 'PRS']">
            <xsl:variable name="related-person-id" select="cda:subject/sdtc:id"/>
            <xsl:variable name="related-person-name" select="cda:subject/cda:name"/>
            <entry>
                <!-- Using cda:subject/@lsc:uuid here to avoid a conflict with RelatedPerson below, which uses the uuid on relatedSubject -->
                <fullUrl value="urn:uuid:{cda:subject/@lcg:uuid}"/>
                <resource>
                    <Patient>
                        <xsl:call-template name="generate-text-patient2"/>
                        <xsl:comment>need to find out how to transform identifier</xsl:comment>
                        <xsl:for-each select="cda:subject/sdtc:id">
                            <identifier>
                                <system>
                                    <xsl:attribute name="value" select="concat('urn:oid:', @root)"/>
                                </system>
                                <value>
                                    <xsl:attribute name="value" select="@extension"/>
                                </value>
                            </identifier>
                        </xsl:for-each>
                        <xsl:apply-templates select="cda:subject/cda:name"/>
                    </Patient>
                </resource>
            </entry>
            <entry>
                <fullUrl value="urn:uuid:{@lcg:uuid}"/>
                <resource>
                    <RelatedPerson>
                        <xsl:apply-templates select="//cda:patientRole/cda:id"/>
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:id"/>
                        <patient>
                            <reference value="urn:uuid:{cda:subject/@lcg:uuid}"/>
                        </patient>
                        <xsl:apply-templates select="cda:code">
                            <xsl:with-param name="pElementName">relationship</xsl:with-param>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:name"/>
                        <xsl:apply-templates
                            select="//cda:patientRole/cda:patient/cda:administrativeGenderCode"/>
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:birthTime"/>
                    </RelatedPerson>
                </resource>
            </entry>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="generate-text-patient2">
        <text>
            <status value="generated"/>
            <div xmlns="http://www.w3.org/1999/xhtml">
                <xsl:for-each
                    select="cda:subject/cda:name[not(@nullFlavor)]">
                    <xsl:choose>
                        <xsl:when test="position() = 1">
                            <h1><xsl:value-of select="cda:family"/>, <xsl:value-of
                                    select="cda:given"/></h1>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>Alternate name: <xsl:value-of select="cda:family"/>, <xsl:value-of
                                    select="cda:given"/></p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <xsl:for-each
                    select="cda:subject/cda:administrativeGenderCode[not(@nullFlavor)]">
                    <p>Gender: <xsl:value-of select="@code"/></p>
                </xsl:for-each>
                <xsl:for-each                
                    select="cda:subject/cda:birthTime[not(@nullFlavor)]">
                    <xsl:variable name="vTest">
                        <xsl:value-of select="lcg:cdaTS2date(@value)"/>
                    </xsl:variable>
                    <p>Birthdate: <xsl:value-of select="lcg:cdaTS2date(@value)"/></p>
                </xsl:for-each>

            </div>
        </text>
    </xsl:template>

</xsl:stylesheet>
