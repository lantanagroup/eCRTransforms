<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0" xmlns="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <xsl:template match="/" mode="convert">
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
                <xsl:otherwise>NA</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Bundle>
            <!-- Generates an id that is unique for the node. It will always be the same for the same id. Should be unique across 
           documents as the CDA document id should be unique-->
            <id value="{concat($vCurrentIg, '-bundle-', generate-id(cda:ClinicalDocument/cda:id))}" />

            <!-- Adding meta for eICR - needs to conform to eICR document bundle profile 
           **TODO** hard coding these for now - because the bundles are usually one level
           higher than the mapping in the template-profile-mapping.xml file
           but need to add in more scaleable solution -->
            <xsl:variable as="xs:string" name="vBundleProfile">
                <xsl:choose>
                    <xsl:when test="$vCurrentIg = 'eICR'">
                        <xsl:text>http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-document-bundle</xsl:text>
                    </xsl:when>
                    <xsl:when test="$vCurrentIg = 'RR'">
                        <xsl:text>http://hl7.org/fhir/us/ecr/StructureDefinition/rr-document-bundle</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="$vBundleProfile != ''">
                <meta>
                    <profile value="{$vBundleProfile}" />
                </meta>
            </xsl:if>
            <!--      <identifier>-->
            <xsl:apply-templates select="cda:ClinicalDocument/cda:id" />
            <!--<system value="urn:ietf:rfc:3986" />
        <!-\-<value value="urn:uuid:{cda:ClinicalDocument/cda:id/@lcg:uuid}" /> -\->
        <value value="urn:uuid:{cda:ClinicalDocument/cda:id/@root}"/>-->
            <!--</identifier>-->
            <type value="document" />
            <timestamp>
                <xsl:attribute name="value">
                    <xsl:choose>
                        <xsl:when test="cda:ClinicalDocument/cda:effectiveTime/@value">
                            <xsl:value-of select="lcg:cdaTS2date(cda:ClinicalDocument/cda:effectiveTime/@value)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'NI'" />
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:attribute>
            </timestamp>
            <xsl:apply-templates mode="bundle-entry" select="cda:ClinicalDocument" />

            <xsl:message>TODO: Add remaining header resources</xsl:message>

            <xsl:for-each select="//descendant::cda:entry">
                <xsl:apply-templates mode="bundle-entry" select="cda:*[not(@nullFlavor)]" />
            </xsl:for-each>

            <!-- Organization resources from participants of type LOC -->
            <xsl:for-each select="//descendant::cda:participant[@typeCode = 'LOC'][not(cda:participantRole/@classCode = 'TERR') and not(cda:participantRole/@classCode = 'SDLOC')][not(@nullFlavor)]">
                <xsl:apply-templates mode="bundle-entry" select="." />
            </xsl:for-each>

            <!-- SG 202402: Added -->
            <!-- Device resources from [C-CDA R1.1] Product Instances in procedures -->
            <xsl:for-each select="//cda:participant/cda:participantRole[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.37']">
                <xsl:apply-templates mode="bundle-entry" select="." />
            </xsl:for-each>
        </Bundle>
    </xsl:template>
</xsl:stylesheet>
