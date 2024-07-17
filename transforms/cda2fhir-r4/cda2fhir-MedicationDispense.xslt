<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18']] | cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.17']][not(../../../cda:substanceAdministration[@moodCode='INT'])]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        
        <xsl:apply-templates select="cda:product/cda:manufacturedProduct" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>
    
    <!-- Suppress C-CDA Supply Order if it's in a SubstanceAdministration with a moodCode of INT because it's data elements will be part of the MedicationRequest
         and not a standalone resource, but do want performer -->
    <xsl:template match="cda:supply[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.17']][../../../cda:substanceAdministration[@moodCode='INT']]" mode="bundle-entry">
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        
        <xsl:for-each select="cda:performer[position() > 1]">
            <xsl:apply-templates select="." mode="provenance">
                <xsl:with-param name="pTargetUUID" select="../../../cda:substanceAdministration[@moodCode='INT']/@lcg:uuid"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:supply[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.18' or @root = '2.16.840.1.113883.10.20.22.4.17']]">
        <MedicationDispense>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <!-- status -->
            <xsl:choose>
                <xsl:when test="@moodCode='INT'">
                    <status value="preparation" />
                </xsl:when>
                <xsl:when test="cda:statusCode/@code = 'completed'">
                    <status value="completed" />
                </xsl:when>
                <xsl:when test="cda:statusCode/@code = 'aborted'">
                    <status value="stopped" />
                </xsl:when>
            </xsl:choose>
            <!-- medicationCodeableConcept -->
            <!-- A cda supply doesn't have to have a product, but a FHIR MedicationDispense has to have a medication
                 if there isn't a product, get the containing substanceAdministration consumable -->
            <xsl:choose>
                <xsl:when test="cda:product">
                    <!--<xsl:apply-templates select="cda:product" mode="medication-dispense" />-->
                    <xsl:for-each select="cda:product/cda:manufacturedProduct">
                        <medicationReference>
                            <reference value="urn:uuid:{@lcg:uuid}" />
                        </medicationReference>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="ancestor::cda:substanceAdministration/cda:consumable">
<!--                    <xsl:apply-templates select="ancestor::cda:substanceAdministration/cda:consumable" mode="medication-dispense" />        -->
                    <xsl:for-each select="ancestor::cda:substanceAdministration/cda:consumable/cda:manufacturedProduct">
                        <medicationReference>
                            <reference value="urn:uuid:{@lcg:uuid}" />
                        </medicationReference>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <medicationReference>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </medicationReference>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:call-template name="subject-reference" />
            
            <!-- supportingInformation: anything in an entryRelationship that isn't already mapped -->
            <xsl:for-each select="cda:entryRelationship/cda:*[not(cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.118')]">
                <supportingInformation>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </supportingInformation>
            </xsl:for-each>
            
            <!-- performer -->
            <xsl:for-each select="cda:performer">
                <performer>
                    <actor>
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </actor>
                </performer>
            </xsl:for-each>
            <xsl:if test="ancestor::cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'INT']">
                <!-- TODO: Add the MedicationDispense directly to the parent of the prescription (i.e. the section, intervention, or care plan). If not, it may not get pulled in via $document -->
                <authorizingPrescription>
                    <xsl:apply-templates select="ancestor::cda:substanceAdministration[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.16'][@moodCode = 'INT'][1]" mode="reference" />
                </authorizingPrescription>
            </xsl:if>
            <xsl:apply-templates select="cda:quantity" mode="medication-dispense" />
            <xsl:apply-templates select="ancestor::cda:substanceAdministration/cda:effectiveTime[@xsi:type = 'IVL_TS']" mode="medication-dispense" />
            <xsl:if test="cda:effectiveTime/@value">
                <whenHandedOver value="{lcg:cdaTS2date(cda:effectiveTime/@value)}" />
            </xsl:if>
        </MedicationDispense>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@xsi:type = 'IVL_TS'][cda:high/@value][cda:low/@value]" mode="medication-dispense">
        <xsl:variable name="days">
            <xsl:value-of select="
                    days-from-duration(xs:date(substring(lcg:cdaTS2date(cda:high/@value), 1, 10)) -
                    xs:date(substring(lcg:cdaTS2date(cda:low/@value), 1, 10)))" />
        </xsl:variable>
        <daysSupply>
            <value value="{$days}" />
        </daysSupply>
    </xsl:template>

    <xsl:template match="cda:quantity" mode="medication-dispense">
        <quantity>
            <xsl:if test="@value">
                <value value="{@value}" />
            </xsl:if>
            <xsl:if test="@unit">
                <unit value="{@unit}" />
            </xsl:if>
            <xsl:if test="@nullFlavor">
                <code value="{@nullFlavor}" />
                <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
            </xsl:if>
        </quantity>
    </xsl:template>

    <xsl:template match="cda:product | cda:consumable" mode="medication-dispense">
        <xsl:for-each select="cda:manufacturedProduct/cda:manufacturedMaterial/cda:code">
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">medicationCodeableConcept</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
