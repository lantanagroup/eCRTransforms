<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fhir="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3"
    xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="xs fhir cda lcg" version="2.0">

    <xsl:output indent="yes" />

    <!-- create bundle-entry for RR externalDocument as DocumentReference -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']" mode="bundle-entry">
        <entry>
            <fullUrl value="urn:uuid:{@lcg:uuid}" />
            <resource>
                <xsl:apply-templates select="cda:reference/cda:externalDocument" />
            </resource>
        </entry>
    </xsl:template>

    <!-- SG: Not sure if this is the correct place for this - leaving it here for now -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:param name="pElementName">reference</xsl:param>
        <xsl:if test="not(@nullFlavor)">
            <xsl:variable name="this" select="." />
            <!-- SG: Changed to a for-each so that all template ids get spit out -->
            <xsl:for-each select="cda:templateId">
                <xsl:choose>
                    <xsl:when test="@extension">
                        <xsl:comment><xsl:value-of select="concat(@root, ':', @extension)" /></xsl:comment>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment><xsl:value-of select="@root" /></xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:element name="{$wrapping-elements}">
                <reference>
                    <xsl:attribute name="value">urn:uuid:<xsl:value-of select="@lcg:uuid" /></xsl:attribute>
                </reference>
                <!-- Special code for [RR R1S1] Received eICR Information -->
                <identifier>
                    <system value="urn:ietf:rfc:3986" />
                    <value>
                        <xsl:attribute name="value" select="concat('urn:uuid:', cda:reference/cda:externalDocument/cda:id/@root)" />
                    </value>
                </identifier>
                <display>
                    <xsl:attribute name="value" select="cda:text" />
                </display>
            </xsl:element>

        </xsl:if>
    </xsl:template>

    <!-- RR External Resource[1]/RR External Reference[1..*] -> RR DocumentReference - bundle entry -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.20']" mode="bundle-entry">
        <xsl:for-each select="cda:reference/cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.17']">
            <xsl:call-template name="create-bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <!-- RR External Resource[1]/RR External Reference[1..*] -> RR DocumentReference -->
    <xsl:template match="cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.17']">
        <xsl:comment>RR DocumentReference</xsl:comment>
        <!--        <xsl:for-each select="cda:reference/cda:externalDocument">-->
        <DocumentReference>
            <xsl:call-template name="add-meta" />
            <xsl:for-each select="../../cda:priorityCode">
                <!-- priorityCode -->
                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                    </xsl:apply-templates>
                </extension>
            </xsl:for-each>
            <xsl:apply-templates select="cda:id" />
            <status value="current" />
            <type>
                <coding>
                    <system value="http://loinc.org" />
                    <code value="83910-0" />
                    <display value="Public health Note" />
                </coding>
                <text value="Public health information" />
            </type>
            <xsl:apply-templates select="../../cda:code">
                <xsl:with-param name="pElementName">category</xsl:with-param>
            </xsl:apply-templates>
            <!--<xsl:for-each select="../../cda:code">
                    <!-\- code -\->
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-type-extension">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                        </xsl:apply-templates>
                    </extension>
                </xsl:for-each>-->
            <!-- subject -->
            <subject>
                <xsl:apply-templates select="/cda:ClinicalDocument/cda:recordTarget" mode="reference" />
            </subject>
            <!-- date -->
            <!-- author -->
            <xsl:for-each select="cda:code[@nullFlavor = 'OTH']">
                <description>
                    <xsl:attribute name="value" select="cda:originalText" />
                </description>
            </xsl:for-each>
            <content>
                <attachment>
                    <xsl:choose>
                        <xsl:when test="cda:text/cda:reference">
                            <contentType>
                                <xsl:attribute name="value" select="cda:text/@mediaType" />
                            </contentType>
                            <url>
                                <xsl:attribute name="value" select="cda:text/cda:reference/@value" />
                            </url>
                        </xsl:when>
                        <xsl:otherwise>
                            <contentType value="text/plain" />
                            <data>
                                <xsl:attribute name="value">
                                    <xsl:apply-templates select="cda:code/cda:originalText" mode="base64" />
                                </xsl:attribute>
                            </data>
                        </xsl:otherwise>
                    </xsl:choose>
                </attachment>

            </content>

        </DocumentReference>
        <!--</xsl:for-each>-->
    </xsl:template>

    <!-- create DocumentReference from externalDocument -->
    <xsl:template match="cda:externalDocument">
        <DocumentReference>
            <status value="current" />

            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'type'" />
            </xsl:apply-templates>
            <content>
                <attachment>
                    <url>
                        <xsl:choose>
                            <xsl:when test="cda:setId/@root and cda:versionNumber/@value">
                                <xsl:attribute name="value" select="concat('urn:hl7ii:', cda:setId/@root, ':', cda:versionNumber/@value)" />
                            </xsl:when>
                            <xsl:when test="cda:setId/@root">
                                <xsl:attribute name="value" select="concat('urn:oid:', cda:setId/@root)" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:comment>WARNING: URL cannot be determined because CDA document does not have a cda:setId for the cda:externalDocument</xsl:comment>
                            </xsl:otherwise>
                        </xsl:choose>
                    </url>
                </attachment>
            </content>
        </DocumentReference>
    </xsl:template>

    <!-- create DocumentReference from 2.16.840.1.113883.10.20.15.2.3.10 eICR External Document Reference externalDocument -->
    <xsl:template match="cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.10']">
        <DocumentReference>
            <xsl:call-template name="add-meta" />
            <!-- ClinicalDocument.id -->
            <xsl:apply-templates select="cda:id">
                <xsl:with-param name="pElementName" select="'masterIdentifier'" />
            </xsl:apply-templates>
            <!-- ClinicalDocument.setId and versionNumber -->
            <xsl:call-template name="createIdentifierWithVersionNumber" />
            <status value="current" />
            <!-- type -->
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'type'" />
            </xsl:apply-templates>
            <!-- category -->
            <category>
                <coding>
                    <system value="http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category" />
                    <code value="clinical-note" />
                    <display value="Clinical Note" />
                </coding>
                <text value="Clinical Note" />
            </category>
            <!-- subject -->
            <subject>
                <xsl:apply-templates select="/cda:ClinicalDocument/cda:recordTarget" mode="reference" />
            </subject>

            <content>
                <attachment>
                    <contentType value="text/plain" />
                    <url>
                        <xsl:choose>
                            <xsl:when test="cda:setId/@root and cda:versionNumber/@value">
                                <xsl:attribute name="value" select="concat('urn:hl7ii:', cda:setId/@root, ':', cda:versionNumber/@value)" />
                            </xsl:when>
                            <xsl:when test="cda:setId/@root">
                                <xsl:attribute name="value" select="concat('urn:oid:', cda:setId/@root)" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:comment>WARNING: URL cannot be determined because CDA document does not have a cda:setId for the cda:externalDocument</xsl:comment>
                            </xsl:otherwise>
                        </xsl:choose>
                    </url>
                </attachment>


            </content>
        </DocumentReference>
    </xsl:template>

    <!-- This is a workaround to get versionNumber in -->
    <xsl:template name="createIdentifierWithVersionNumber">
        <xsl:param name="pElementName">identifier</xsl:param>
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
        <xsl:variable name="root" select="cda:setId/@root" />
        <xsl:variable name="root-uri">
            <xsl:choose>
                <xsl:when test="$mapping/map[@oid = cda:setId/$root]">
                    <xsl:value-of select="$mapping/map[@oid = cda:setId/$root][1]/@uri" />
                </xsl:when>
                <xsl:when test="contains($root, '-')">
                    <xsl:text>urn:uuid:</xsl:text>
                    <xsl:value-of select="$root" />
                </xsl:when>
                <xsl:when test="contains($root, '.')">
                    <xsl:text>urn:oid:</xsl:text>
                    <xsl:value-of select="$root" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="cda:setId/@nullFlavor">
                <!-- TODO: ignore for now, add better handling later -->
            </xsl:when>
            <xsl:when test="cda:setId/@root and cda:setId/@extension and cda:versionNumber/@value">
                <xsl:element name="{$pElementName}">
                    <system value="{$root-uri}" />
                    <value value="{concat(cda:setId/@extension, '#', cda:versionNumber/@value)}" />
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:setId/@root and cda:setId/@extension">
                <xsl:element name="{$pElementName}">
                    <system value="{$root-uri}" />
                    <value value="{cda:setId/@extension}" />
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:setId/@root and not(cda:setId/@extension)">
                <xsl:element name="{$pElementName}">
                    <system value="urn:ietf:rfc:3986" />
                    <value value="{$root-uri}" />
                </xsl:element>
            </xsl:when>
        </xsl:choose>

    </xsl:template>


</xsl:stylesheet>
