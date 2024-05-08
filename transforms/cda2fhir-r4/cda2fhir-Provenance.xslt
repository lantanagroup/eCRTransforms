<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

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
                            <xsl:apply-templates select="cda:time" mode="instant" />
                        </xsl:when>
                        <xsl:when test="cda:relatedEntity/cda:time">
                            <xsl:apply-templates select="cda:relatedEntity/cda:time" mode="instant" >
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="/cda:ClinicalDocument/cda:effectiveTime" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
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
    
    <xsl:template match="cda:author | cda:performer" mode="provenance">
        <entry>
            <fullUrl value="urn:uuid:{@lcg:uuid}" />
            <resource>
                <Provenance>
                    <target>
                        <reference value="urn:uuid:{parent::cda:observation/@lcg:uuid}" />
                    </target>
                    <xsl:choose>
                        <xsl:when test="cda:time">
                            <xsl:apply-templates select="cda:time" mode="instant" >
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="/cda:ClinicalDocument/cda:effectiveTime" mode="instant">
                                <xsl:with-param name="pElementName">recorded</xsl:with-param>
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
                            <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid | cda:assignedAuthor/@lcg:uuid}" />
                        </who>
                    </agent>
                </Provenance>
            </resource>
        </entry>
    </xsl:template>
</xsl:stylesheet>
