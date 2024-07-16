<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template name="make-practitioner">
        <xsl:param name="id" />
        <xsl:param name="name" />
        <xsl:param name="telecom" />
        <xsl:param name="address" />

        <xsl:variable name="vIdentifier">
            <xsl:apply-templates select="$id" />
            <xsl:if test="not($id)">
                <identifier>
                    <system>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </system>
                    <value>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </value>
                </identifier>
            </xsl:if>
        </xsl:variable>

        <Practitioner>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner" />
            </meta>
            <!--<text>
                <status value="generated" />
                <div xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="$name">
                        <xsl:choose>
                            <xsl:when test="cda:family">
                                <p>
                                    <xsl:text>Name: </xsl:text>
                                    <xsl:value-of select="cda:family" />
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="cda:given" />
                                </p>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:for-each select="$vIdentifier/fhir:identifier">
                        <p>Identifier system: <xsl:value-of select="fhir:system/@value" /> value: <xsl:value-of select="fhir:value/@value" /></p>
                    </xsl:for-each>
                    <xsl:for-each select="$telecom">
                        <p>Telephone: <xsl:value-of select="@value" /></p>
                    </xsl:for-each>
                </div>
            </text>-->
            <xsl:for-each select="$vIdentifier/fhir:identifier">
                <xsl:copy-of select="." />
            </xsl:for-each>
            <xsl:apply-templates select="$name">
                <xsl:with-param name="pFamilyRequired" select="true()"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$telecom" />
            <xsl:apply-templates select="$address" />
            <!-- Qualification -->
            <xsl:choose>
                <xsl:when test="cda:participantRole">
                    <xsl:apply-templates select="cda:participantRole/cda:code" mode="practitioner" />
                </xsl:when>
                <xsl:when test="cda:assignedAuthor">
                    <xsl:apply-templates select="cda:assignedAuthor/cda:code" mode="practitioner" />
                </xsl:when>
            </xsl:choose>
        </Practitioner>
    </xsl:template>

    <xsl:template match="cda:code" mode="practitioner">
        <qualification>
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:call-template>
        </qualification>
    </xsl:template>

        
</xsl:stylesheet>
