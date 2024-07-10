<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" version="2.0"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml">

    <!-- TEMPLATE: eICR Trigger Code extension
       Check to see if there is a @sdtc:valueSet value in the template - this should mean it's an eICR Trigger Code template -->
    <xsl:template match="
            cda:*/cda:code[@sdtc:valueSet] |
            cda:*/cda:code/cda:translation[@sdtc:valueSet] |
            cda:*/cda:value[@sdtc:valueSet] |
            cda:*/cda:value/cda:translation[@sdtc:valueSet] |
            cda:*/cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:code[@sdtc:valueSet] |
            cda:*/cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:code/cda:translation[@sdtc:valueSet]" mode="entry-extension">
        
        <!-- Make sure it is a template in eICR - there could potentially be other templates that use @sdtc:valueSet -->
        <xsl:if test="$gvCurrentIg = 'eICR'">
            <xsl:comment>eICR Trigger Code Flag Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-trigger-code-flag-extension">
                <extension url="triggerCodeValueSet">
                    <xsl:variable name="vValueOid" select="concat('urn:oid:', @sdtc:valueSet)" />
                    <valueOid value="{$vValueOid}" />
                </extension>
                <extension url="triggerCodeValueSetVersion">
                    <valueString value="{@sdtc:valueSetVersion}" />
                </extension>
                <extension url="triggerCode">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName">valueCoding</xsl:with-param>
                        <xsl:with-param name="pIncludeCoding" select="false()" />
                    </xsl:apply-templates>
                </extension>
            </extension>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: eICR Initiation Type Extension in Composition -->
    <xsl:template match="cda:documentationOf/cda:serviceEvent[cda:code[@code = 'PHC1464']]" mode="extension">
        <xsl:comment>eICR Initiation Type Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension">
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: Address extension in eICR Travel History Observation profile -->
    <xsl:template match="cda:addr" mode="extension">
        <xsl:comment>Travel History Address Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-address-extension">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pElementName">valueAddress</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- MD: address OrderExtension -->
    <xsl:template match="cda:inFulfillmentOf" mode="extension">
        <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pElementName">ServiceRequest</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: Therapeutic Response to Medication Extension -->
    <xsl:template match="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.37']" mode="extension">
        <xsl:comment>US Public Health Therapeutic Medication Response Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-therapeutic-medication-response-extension">
            <xsl:apply-templates select="cda:value">
                <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: Patient Religion Extension -->
    <xsl:template match="cda:religiousAffiliationCode" mode="extension">
        <xsl:comment>FHIR Patient Religion Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/StructureDefinition/patient-religion">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: Date determined extension (Pregnancy Status, Estimated Date of Delivery, Estimated Gestational Age of Pregnancy) -->
    <xsl:template match="cda:effectiveTime[parent::*[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.297' or @root = '2.16.840.1.113883.10.20.22.4.280']]] | cda:time[parent::cda:performer]"
        mode="extension">
        <xsl:comment>Date Determined Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-date-determined-extension">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pStartElementName">value</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: Date recorded extension (Pregnancy Status) -->
    <xsl:template match="cda:time[parent::cda:author]" mode="extension">
        <xsl:comment>Date Recorded Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-date-recorded-extension">
            <xsl:apply-templates select=".">
                <xsl:with-param name="pStartElementName">value</xsl:with-param>
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: determination of reportability (RR Composition)-->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.19']]" mode="extension">
        <xsl:comment>RR Determination of Reportability</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-extension">
            <xsl:apply-templates select="cda:value">
                <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: RR External Resource Extension (RR Composition)-->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.20']]" mode="extension">
        <xsl:for-each select="cda:reference/cda:externalDocument[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.17']]">
            <xsl:comment>RR External Resource Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-extension">
                <valueReference>
                    <xsl:apply-templates select="." mode="reference" />
                </valueReference>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: [RR R1S1] eICR Processing Status -->
    <xsl:template match="cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.2.3']" mode="extension">
        <xsl:comment>eICR Processing Status Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension">
            <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.29']">
                <extension url="eICRProcessingStatus">
                    <valueReference>
                        <reference value="urn:uuid:{@lcg:uuid}" />
                    </valueReference>
                </extension>
                <!-- eICR Validation Output -> fhir:extension -->
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.33']/cda:value">
                    <xsl:comment>eICR Validation Output Extension</xsl:comment>
                    <extension url="eICRValidationOutput">
                        <xsl:choose>
                            <xsl:when test="@mediaType = 'text/xhtml'">
                                <xsl:variable name="vValidationOutputSerialized">
                                    <xsl:apply-templates select="xhtml:html" mode="serialize" />
                                </xsl:variable>
                                <!-- Not sure whether this should be a string or markdown -->
                                <valueString value="{$vValidationOutputSerialized}" />
                            </xsl:when>
                            <xsl:otherwise />
                        </xsl:choose>
                    </extension>
                </xsl:for-each>
            </xsl:for-each>
        </extension>

        <!-- Manually Initiated eICR -> fhir: extension rr-initiation-type-extension-->
        <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.22']">
            <xsl:comment>eICR Initiation Type Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension">
                <xsl:apply-templates select="cda:code">
                    <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                </xsl:apply-templates>
            </extension>
        </xsl:for-each>

        <!-- Received eICR Information -> fhir:extension rr-eicr-receipt-time-extension -->
        <xsl:for-each select="cda:documentationOf/cda:serviceEvent[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']">
            <xsl:comment>eICR Receipt Time Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-receipt-time-extension">
                <valueDateTime>
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:effectiveTime/@value)" />
                    </xsl:attribute>
                </valueDateTime>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: [RR R1S1] Reportability Response Summary Section -->
    <xsl:template match="cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.2.2']" mode="extension">
        <xsl:for-each select="cda:entry/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.30']">
            <xsl:comment>RR Priority Extension</xsl:comment>
            <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension">
                <xsl:apply-templates select="cda:value">
                    <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                </xsl:apply-templates>
            </extension>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: determination of reportability reason (RR Composition) -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.26']" mode="extension">
        <xsl:comment>Determination of Reportability Reason Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-reason-extension">
            <xsl:apply-templates select="cda:value[@xsi:type = 'ST']">
                <xsl:with-param name="pElementName" select="'valueString'" />
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:value[@xsi:type = 'CD']">
                <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: determination of reportability rule (RR Composition)-->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.27']" mode="extension">
        <xsl:comment>Determination of Reportability Rule Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-determination-of-reportability-rule-extension">
            <xsl:apply-templates select="cda:value[@xsi:type = 'ST']">
                <xsl:with-param name="pElementName" select="'valueString'" />
            </xsl:apply-templates>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: odh-Employer-extension -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']/cda:participant[@typeCode = 'IND']" mode="extension">
        <xsl:comment>ODH Employer Extension</xsl:comment>
        <extension url="http://hl7.org/fhir/us/odh/StructureDefinition/odh-Employer-extension">
            <valueReference>
                <xsl:apply-templates select="." mode="reference" />
                <!--        <reference value="urn:uuid:{@lcg:uuid}" />-->
            </valueReference>
        </extension>
    </xsl:template>

    <!-- TEMPLATE: ClinicalDocument/informationRecipient/intendedRecipient -->
    <xsl:template match="cda:informationRecipient/cda:intendedRecipient" mode="extension">

        <xsl:choose>
            <xsl:when test="$gvCurrentIg = 'eICR' or $gvCurrentIg = 'RR'">
                <xsl:comment>US Public Health Information Recipient Extension</xsl:comment>
                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-information-recipient-extension">
                    <valueReference>
                        <xsl:apply-templates select="." mode="reference" />
                        <!--        <reference value="urn:uuid:{@lcg:uuid}" />-->
                    </valueReference>
                </extension>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>C-CDA Recipient Extension</xsl:comment>
                <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/InformationRecipientExtension">
                    <valueReference>
                        <xsl:apply-templates select="." mode="reference" />
                        <!--        <reference value="urn:uuid:{@lcg:uuid}" />-->
                    </valueReference>
                </extension>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Stop text printing out if there is no match -->
    <xsl:template match="text() | @*" mode="entry-extension">
        <xsl:apply-templates />
    </xsl:template>

</xsl:stylesheet>
