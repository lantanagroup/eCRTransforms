<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- 20261125 Claude (SG decision 2026-11-25, re-trace finding RT-C5): the Medication carried code and form only.
         - manufacturerOrganization (with a name or a real id) now becomes an Organization entry referenced from
           Medication.manufacturer, and manufacturedMaterial/lotNumberText goes to Medication.batch.lotNumber,
           as the Immunization mapping already did. A null-flavored or empty one gives nothing.
         - A typeCode CSM participant on the substanceAdministration is the C-CDA Drug Vehicle (22.4.24), not a
           dose form. It used to be written to Medication.form, and two vehicles gave two form elements (max 1).
           Each vehicle is now one Medication.ingredient: itemCodeableConcept from playingEntity/code, or from
           playingEntity/name as text when the code is null-flavored or absent. Medication.form is no longer
           written.
         FHIR element order: code, manufacturer, ingredient, batch. -->
    <xsl:template match="cda:manufacturedProduct" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:manufacturerOrganization[cda:name[normalize-space()] or cda:id[not(@nullFlavor)]]" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:manufacturedProduct">
        <Medication>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication" />
            </meta>
            <xsl:apply-templates select="cda:manufacturedMaterial/cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>

            <!-- manufacturer -->
            <xsl:apply-templates select="cda:manufacturerOrganization[cda:name[normalize-space()] or cda:id[not(@nullFlavor)]]" mode="reference">
                <xsl:with-param name="wrapping-elements">manufacturer</xsl:with-param>
            </xsl:apply-templates>

            <!-- ingredient: drug vehicle(s) -->
            <xsl:for-each select="parent::cda:consumable/following-sibling::cda:participant[@typeCode = 'CSM']/cda:participantRole/cda:playingEntity">
                <xsl:choose>
                    <xsl:when test="cda:code[@code][not(@nullFlavor)]">
                        <ingredient>
                            <xsl:apply-templates select="cda:code">
                                <xsl:with-param name="pElementName">itemCodeableConcept</xsl:with-param>
                            </xsl:apply-templates>
                        </ingredient>
                    </xsl:when>
                    <xsl:when test="cda:name[normalize-space()]">
                        <ingredient>
                            <itemCodeableConcept>
                                <text value="{normalize-space(cda:name[normalize-space()][1])}" />
                            </itemCodeableConcept>
                        </ingredient>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>

            <!-- batch.lotNumber -->
            <xsl:for-each select="cda:manufacturedMaterial/cda:lotNumberText[not(@nullFlavor)][normalize-space()][1]">
                <batch>
                    <lotNumber value="{normalize-space(.)}" />
                </batch>
            </xsl:for-each>
        </Medication>
    </xsl:template>

</xsl:stylesheet>
