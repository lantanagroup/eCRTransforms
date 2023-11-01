<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />

    <!-- Need to import this to get the XSpec working -->
    <xsl:import href="cda2fhir-Extension.xslt" />

    <!-- Note: default bundle-entry observation template is down below so that it can be easily overriden -->
    <!-- RESULT/VITAL-SIGN/FUNCTIONAL-STATUS ORGANIZER/OBSERVATION -->

    <!-- ********************************************************************************************** 
      Supress things that are templates in CDA but end up being extensions or components etc. in FHIR
       i.e. anything which won't have its own bundle entry 
  ***************************************************************************************************-->
    <!-- SG: Suppress bundle entry for Laboratory Result Status (ID) and Laboratory Result Observation Status (ID) 
        We are already processing them and using them for the status value in their containing Observations -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.418' or @root = '2.16.840.1.113883.10.20.22.4.419']]" mode="bundle-entry" />

    <!-- SG: Suppress bundle entry for Estimated Date of Delivery and Estimated Gestation Age of Pregnancy
       They are being processed as Observation.components of Pregnancy Status Observation-->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.297' or @root = '2.16.840.1.113883.10.20.22.4.280']]" mode="bundle-entry" />

    <!-- SG: Suppress bundle entry for ODH Usual Industry Observation
       It is being processed as Observation.component of ODH Usual Work -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.219']]" mode="bundle-entry" />

    <!-- SG: Suppress bundle entry for ODH Past or Present Industry Observation
       It is being processed as Observation.component of ODH Usual Work -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.216']]" mode="bundle-entry" />

    <!-- SG: Suppress bundle entry for ODH Occupational Hazard Observation
       It is being processed as Observation.component of ODH Usual Work -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.215']]" mode="bundle-entry" />

    <!-- Suppress Birth Sex Observation since matched in add-birth-sex-extension in cda2fhir-Patient.xslt -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.200']" mode="bundle-entry" />

    <!-- Supress Gender Identity since matched in gender-identity-extension in cda2fhir-Patient.xslt -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.34.3.45']" mode="bundle-entry" />

    <!-- Suppress Reportability Response Priority, Validation Output, Subject since matched in extension in cda2fhir-Composition.xslt -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.30' or @root = '2.16.840.1.113883.10.20.15.2.3.33']]" mode="bundle-entry" />

    <!-- Suppress Subject, Initiation since matched in extension in cda2fhir-Composition.xslt (even though they are acts...) -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7' or @root = '2.16.840.1.113883.10.20.15.2.3.22']]" mode="bundle-entry" />

    <!-- Suppress Tribal Affiliation Observation since matched in add-tribal-affiliation-extension in cda2fhir-Patient.xslt -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.48']" mode="bundle-entry" />
    <!-- ********************************************************************************************** -->

    <!-- C-CDA Result Organizer, C-CDA Vital Signs Organizer, Functional Status Organizer - bundle entry  -->
    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1' or @root = '2.16.840.1.113883.10.20.22.4.26' or @root = '2.16.840.1.113883.10.20.22.4.66']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:*[not(cda:code[@code = '8462-4' or @code = '8480-6'])]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:observation[cda:code[@code = '8462-4' or @code = '8480-6']]/cda:performer" mode="bundle-entry" />
    </xsl:template>

    <!-- C-CDA Result Organizer, C-CDA Vital Signs Organizer, Functional Status Organizer  -->
    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1' or @root = '2.16.840.1.113883.10.20.22.4.26' or @root = '2.16.840.1.113883.10.20.22.4.66']]">
        <xsl:variable name="category">
            <xsl:choose>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']">laboratory</xsl:when>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.26']">vital-signs</xsl:when>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.66']">activity</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <!-- SG: If there is a nested Laboratory Result Status (ID) 2.16.840.1.113883.10.20.22.4.418 use 
           the value in there to set the status-->
            <xsl:choose>
                <xsl:when test="cda:component/cda:observation/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.418']">
                    <xsl:apply-templates select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.418']/cda:value" mode="map-lab-status" />
                </xsl:when>
                <xsl:otherwise>
                    <status value="final" />
                </xsl:otherwise>
            </xsl:choose>
            <category>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/observation-category" />
                    <code value="{$category}" />
                </coding>
            </category>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />

            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName" select="'effective'" />
            </xsl:apply-templates>


            <xsl:call-template name="performer-or-author" />
            <!-- if there are any specific perfomers, get them -->
            <xsl:for-each select="cda:component/cda:observation[cda:performer/cda:assignedEntity]">
                <xsl:call-template name="performer-or-author" />
            </xsl:for-each>
            <!-- Specimen Collection Procedure -->
            <xsl:for-each select="cda:component/cda:procedure[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.415']] | cda:component/cda:procedure[cda:code[@code = '17636008']]">
                <specimen>
                    <xsl:apply-templates select="." mode="reference" />
                </specimen>
            </xsl:for-each>
            <!-- SG: Oids below are for C-CDA Result Observation, C-CDA Vital Sign Observation -->
            <xsl:for-each select="cda:component/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.2']]">
                <hasMember>
                    <xsl:apply-templates select="." mode="reference" />
                </hasMember>
            </xsl:for-each>
            <!-- SG: Oids below are for C-CDA Vital Sign Observation -->
            <xsl:for-each select="cda:component/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.27']][not(cda:code[@code = '8462-4' or @code = '8480-6'])]">
                <hasMember>
                    <xsl:apply-templates select="." mode="reference" />
                </hasMember>
            </xsl:for-each>

            <xsl:for-each select="cda:component/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.27']][cda:code[@code = '8462-4' or @code = '8480-6']]">
                <!-- MD: blood pressure has two parts with one reference, here we using  systolic part as reference point supress diastolic part -->

                <component>
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName">code</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:choose>
                        <xsl:when test="cda:value[@xsi:type = 'INT']">
                            <!-- There is no valueInteger in observations. Assume is a scale instead -->
                            <xsl:apply-templates select="cda:value" mode="scale" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="cda:value" />
                        </xsl:otherwise>
                    </xsl:choose>
                </component>

            </xsl:for-each>
        </Observation>
    </xsl:template>

    <!-- C-CDA Result Observation, C-CDA Vital Sign Observation -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.2' or @root = '2.16.840.1.113883.10.20.22.4.27']]">
        <xsl:variable name="category">
            <xsl:choose>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.2']">laboratory</xsl:when>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.27']">vital-signs</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="profile">
            <xsl:choose>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.2']">http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab</xsl:when>
                <xsl:when test="cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.27']">http://hl7.org/fhir/StructureDefinition/vitalsigns</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <!-- SG: If there is a nested Laboratory Observation Result Status (ID) 2.16.840.1.113883.10.20.22.4.419 use 
           the value in there to set the status-->
            <xsl:choose>
                <xsl:when test="cda:entryRelationship/cda:observation/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.419']">
                    <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.419']/cda:value" mode="map-lab-obs-status" />
                </xsl:when>
                <xsl:otherwise>
                    <status value="final" />
                </xsl:otherwise>
            </xsl:choose>
            <category>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/observation-category" />
                    <code value="{$category}" />
                </coding>
            </category>

            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName" select="'effective'" />
            </xsl:apply-templates>
            <xsl:call-template name="performer-or-author" />
            <xsl:apply-templates select="cda:value" />
            <xsl:apply-templates select="cda:interpretationCode" />
            <xsl:apply-templates select="cda:referenceRange" />
            <!-- TODO process entryRelationships -->

        </Observation>
    </xsl:template>

    <!-- C-CDA Caregiver Characteristics - bundle entry-->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.72']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant[@typeCode = 'IND'][cda:participantRole/@classCode = 'CAREGIVER']" mode="bundle-entry" />
    </xsl:template>

    <!-- C-CDA Caregiver Characteristics -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.72']]">
        <xsl:variable name="caregiver" select="cda:participant[@typeCode = 'IND'][cda:participantRole/@classCode = 'CAREGIVER']" />
        <xsl:comment>C-CDACaregiver Characteristics</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:for-each select="$caregiver">
                <focus>
                    <xsl:apply-templates select="cda:participantRole" mode="reference" />
                </focus>
            </xsl:for-each>
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:apply-templates select="cda:value" />
        </Observation>
    </xsl:template>

    <!-- (eICR) Travel History -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.1']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- (eICR) Travel History -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.1']]">
        <xsl:comment>Travel History</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <!-- SG: Sending off effectiveTime, will let the utility figure out what type it is -->
            <xsl:apply-templates select="cda:effectiveTime">
                <!-- Will let the utility append the correct DateTime, Period, Timing, or effectiveInstant string onto this -->
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <component>
                <xsl:for-each select="cda:participant/cda:participantRole/cda:addr">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:for-each>
                <xsl:call-template name="createCodeableConcept">
                    <xsl:with-param name="pCode">LOC</xsl:with-param>
                    <xsl:with-param name="pSystem">http://terminology.hl7.org/CodeSystem/v3-ParticipationType</xsl:with-param>
                    <xsl:with-param name="pDisplay">Location</xsl:with-param>
                    <xsl:with-param name="pInnerElement">coding</xsl:with-param>
                    <xsl:with-param name="pOuterElement">code</xsl:with-param>
                </xsl:call-template>

                <xsl:if test="cda:participant/cda:participantRole/cda:code | cda:text">
                    <valueCodeableConcept>
                        <xsl:for-each select="cda:participant/cda:participantRole/cda:code">
                            <xsl:apply-templates select=".">
                                <xsl:with-param name="pElementName">coding</xsl:with-param>
                                <xsl:with-param name="includeCoding" select="false()" />
                            </xsl:apply-templates>
                        </xsl:for-each>
                        <xsl:for-each select="cda:text">
                            <text>
                                <xsl:attribute name="value" select="(.)" />
                            </text>
                        </xsl:for-each>
                    </valueCodeableConcept>
                </xsl:if>
            </component>

        </Observation>
    </xsl:template>

    <!-- (eICR) Last Menstrual Period -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.30.3.34']">
        <xsl:comment>Last Menstrual Period</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:comment>Start of last menstrual period</xsl:comment>
            <xsl:apply-templates select="cda:value" />
        </Observation>
    </xsl:template>

    <!-- (eICR) Postpartum Status -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.285']">
        <xsl:comment>Postpartum Status</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />

            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />

            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:comment>Postpartum status</xsl:comment>
            <xsl:apply-templates select="cda:value" />
        </Observation>
    </xsl:template>

    <!-- (eICR) Characteristics of Home Environment -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.109']">
        <xsl:comment>Characteristics of Home Environment</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />

            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />

            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:apply-templates select="cda:value" />
        </Observation>
    </xsl:template>

    <!-- Pregnancy Status Observation -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.293' or cda:templateId/@root = '2.16.840.1.113883.10.20.15.3.8']">
        <xsl:comment>Pregnancy Status Observation</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:comment>Pregnancy Status Recorded Date</xsl:comment>
            <xsl:apply-templates select="cda:author/cda:time" mode="extension" />
            <xsl:comment>Pregnancy Status Determination Date</xsl:comment>
            <xsl:apply-templates select="cda:performer/cda:time" mode="extension" />

            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <!-- SG: Updated this to hard coded value - the assertion from CDA isn't used in FHIR -->
            <xsl:call-template name="createCodeableConcept">
                <xsl:with-param name="pSystem" select="'http://loinc.org'" />
                <xsl:with-param name="pCode" select="'82810-3'" />
                <xsl:with-param name="pDisplay" select="'Pregnancy Status'" />
                <xsl:with-param name="pInnerElement" select="'coding'" />
                <xsl:with-param name="pOuterElement" select="'code'" />
            </xsl:call-template>

            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <!-- SG: value is always a code in Pregnancy Status -->
            <xsl:choose>
                <xsl:when test="cda:value[@nullFlavor]">
                    <xsl:apply-templates select="cda:value/@nullFlavor" mode="data-absent-reason" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:value" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- Adding method -->
            <xsl:apply-templates select="cda:methodCode">
                <xsl:with-param name="pElementName" select="'method'" />
                <xsl:with-param name="includeCoding" select="true()" />
            </xsl:apply-templates>

            <!-- The entryRelationships (other than Pregnancy Outcome) -->
            <xsl:apply-templates select="cda:entryRelationship/cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.297' or @root = '2.16.840.1.113883.10.20.22.4.280']]" />

        </Observation>
    </xsl:template>

    <!-- (eICR) Estimated Date of Delivery, Estimated Gestational Age of Pregnancy -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.280']]">
        <component>
            <xsl:call-template name="comment-subprofile-name" />
            <!-- This is the extension for date determined -->
            <xsl:apply-templates select="cda:effectiveTime" mode="extension" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'code'" />
                <xsl:with-param name="includeCoding" select="true()" />
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:value" />
        </component>
    </xsl:template>

    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.297']]">
        <component>
            <xsl:call-template name="comment-subprofile-name" />
            <!-- This is the extension for date determined -->
            <xsl:apply-templates select="cda:effectiveTime" mode="extension" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'code'" />
                <xsl:with-param name="includeCoding" select="true()" />
            </xsl:apply-templates>
            <valueDateTime value="{lcg:cdaTS2date(cda:effectiveTime/@value)}" />
        </component>
    </xsl:template>

    <xsl:template match="cda:sequenceNumber[following-sibling::cda:observation/cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.284']" mode="bundle-entry"/>
    
    <!-- Pregnancy Outcome Observation -->
    <xsl:template match="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.284']">
        <xsl:comment>Pregnancy Outcome Observation</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:comment>Reference to related Pregnancy Observation</xsl:comment>
            <xsl:call-template name="resource-reference">
                <xsl:with-param name="pElementName">focus</xsl:with-param>
                <xsl:with-param name="pTemplateId" select="parent::*/parent::*/cda:templateId" />
            </xsl:call-template>

            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:apply-templates select="cda:value" />

            <xsl:if test="parent::*/cda:sequenceNumber">
                <xsl:comment>Birth Order component</xsl:comment>
                <component>
                    <xsl:call-template name="createCodeableConcept">
                        <xsl:with-param name="pSystem" select="'http://loinc.org'" />
                        <xsl:with-param name="pCode" select="'73771-8'" />
                        <xsl:with-param name="pDisplay" select="'Birth order'" />
                        <xsl:with-param name="pInnerElement" select="'coding'" />
                        <xsl:with-param name="pOuterElement" select="'code'" />
                    </xsl:call-template>

                    <xsl:apply-templates select="parent::*/cda:sequenceNumber" />
                </component>
            </xsl:if>
        </Observation>
    </xsl:template>

    <!-- *************** Start Reportability Response Processing ******************************************************************* -->
    <!-- (RR) Reportability Response Summary -> RR Summary (Observation) - bundle entry -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.8']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- (RR) Reportability Response Summary -> RR Summary (Observation) -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8']]">
        <xsl:comment>RR Summary</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />

            <xsl:call-template name="performer-or-author" />
            <xsl:variable name="vApos">'</xsl:variable>
            <xsl:variable name="vQuot">"</xsl:variable>
            <valueString value="{replace(cda:text/text(),$vQuot,$vApos)}" />
        </Observation>
    </xsl:template>

    <!-- (RR) Remove Reportability Response Coded Information Organizer wrapper -->
    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.34']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:for-each select="cda:component/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="reference">
                <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- (RR) Remove Reportability Response Coded Information Organizer wrapper and create bundle-entries for any contained
         Relevant Reportable Condition Observation -->
    <xsl:template match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.34']]" mode="bundle-entry">
        <xsl:for-each select="cda:component/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <!-- (RR) Relvant Reportable Condition Observation -> RR Relevant Reportable Condition Observation -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.12']">
        <xsl:comment>Relevant Reportable Condition Observation</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:choose>
                <xsl:when test="cda:value[@nullFlavor]">
                    <xsl:apply-templates select="cda:value/@nullFlavor" mode="data-absent-reason" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:value" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="cda:entryRelationship/cda:*">
                <hasMember>
                    <xsl:apply-templates select="." mode="reference" />
                </hasMember>
            </xsl:for-each>
        </Observation>
    </xsl:template>

    <!-- (RR) Reportability Information Organizer -> RR Reportability Information Observation - bundle entry -->
    <xsl:template match="cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.13']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:component/cda:act" mode="bundle-entry" />
    </xsl:template>

    <!-- (RR) Reportability Information Organizer -> RR Reportability Information Observation -->
    <xsl:template match="cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.13']">
        <xsl:comment>Reportability Information Observation</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <!-- RR Determination of Reportability -->
            <xsl:for-each select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.19']">
                <xsl:apply-templates select="." mode="extension" />

                <!-- RR Determination of Reportability Reason -->
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.26']">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:for-each>

                <!-- RR Determination of Reportability Rule -->
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.27']">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:for-each>
            </xsl:for-each>

            <!-- RR External Resources/ RR External Reference -->
            <xsl:for-each select="cda:component/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.20']">
                <xsl:apply-templates select="." mode="extension" />
            </xsl:for-each>

            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>


            <!-- Rules Authoring Agency, Routing Entity, Responsible Agency -->
            <xsl:for-each select="cda:participant">
                <xsl:comment>Rules Authoring Agency, Routing Entity, Responsible Agency</xsl:comment>
                <performer>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </performer>
            </xsl:for-each>

            <!-- Reporting Timeframe -->
            <!-- Looks like FHIR mistakenly has this as required so will need to always something here -->
            <xsl:choose>
                <xsl:when test="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.14']">
                    <xsl:for-each select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.14']">
                        <xsl:comment>Reporting Timeframe</xsl:comment>
                        <component>
                            <xsl:apply-templates select="cda:code">
                                <xsl:with-param name="pElementName">code</xsl:with-param>
                            </xsl:apply-templates>
                            <xsl:apply-templates select="cda:value">
                                <xsl:with-param name="pElementName">valueQuantity</xsl:with-param>
                            </xsl:apply-templates>
                        </component>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <component>
                        <code>
                            <coding>
                                <system value="urn:oid:2.16.840.1.114222.4.5.232" />
                                <code value="RR4" />
                                <display value="Timeframe to report (urgency)" />
                            </coding>
                        </code>
                        <valueQuantity>
                            <value>
                                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                                    <valueCode value="unknown" />
                                </extension>
                            </value>
                            <unit>
                                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                                    <valueCode value="unknown" />
                                </extension>
                            </unit>
                        </valueQuantity>
                    </component>

                </xsl:otherwise>
            </xsl:choose>
        </Observation>
    </xsl:template>

    <!-- (RR) eICR Processing Status -> eICR Processing Status Observation - bundle entry -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.29']" mode="bundle-entry">
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- (RR) eICR Processing Status -> eICR Processing Status Observation -->
    <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.29']">
        <xsl:comment>(RR) eICR Processing Status -> eICR Processing Status Observation</xsl:comment>
        <Observation>
            <xsl:comment>Processing Status</xsl:comment>
            <xsl:call-template name="add-meta" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'code'" />
            </xsl:apply-templates>
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.21']">
                <hasMember>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </hasMember>
            </xsl:for-each>
        </Observation>
    </xsl:template>

    <!-- Processing Status Reason - entry -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.21']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- Processing Status Reason -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.21']">
        <xsl:comment>Processing Status Reason</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'code'" />
            </xsl:apply-templates>
            <xsl:call-template name="performer-or-author" />
            <xsl:apply-templates select="cda:value">
                <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
            </xsl:apply-templates>
            <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.32']">
                <component>
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName" select="'code'" />
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:value[@xsi:type = 'ST']">
                        <xsl:with-param name="pElementName" select="'valueString'" />
                    </xsl:apply-templates>
                    <xsl:apply-templates select="cda:value[@xsi:type = 'CD']">
                        <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                    </xsl:apply-templates>
                </component>
            </xsl:for-each>
        </Observation>
    </xsl:template>

    <!-- *************** End Reportability Response Processing ******************************************************************* -->

    <!-- Usual Occupation Observation -> ODH Usual Work -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.221']">
        <xsl:comment>ODH Usual Work</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <!-- This isn't required by the profile, but I think that might be an oversight in the 
            ODH profile so adding it-->
            <category>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/observation-category" />
                    <code value="social-history" />
                    <display value="Social History" />
                </coding>
            </category>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />
            <xsl:choose>
                <xsl:when test="cda:value[@nullFlavor]">
                    <xsl:apply-templates select="cda:value/@nullFlavor" mode="data-absent-reason" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:value" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:entryRelationship/cda:*" />
        </Observation>
    </xsl:template>

    <!-- ODH Past or Present Job -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']" mode="bundle-entry">
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- ODH Past or Present Job -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']">
        <xsl:comment>ODH Past or Present Job</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:comment>ohh-Employer-extension</xsl:comment>
            <xsl:apply-templates select="cda:participant[@typeCode = 'IND']" mode="extension" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />

            <xsl:choose>
                <xsl:when test="cda:value[@nullFlavor]">
                    <xsl:apply-templates select="cda:value/@nullFlavor" mode="data-absent-reason" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:value" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- In CDA the job title goes in text as there is nowhere to store it in the ODH template
           putting it in note in the FHIR profile MD: ???? comment it out since it cause schema validation error
            <xsl:if test="cda:text">
                <note>
                    <xsl:value-of select="cda:text" />
                </note>
            </xsl:if>
            -->
            <xsl:apply-templates select="cda:entryRelationship/cda:*" />
        </Observation>
    </xsl:template>

    <!-- ODH Past or Present Industry (component of ODH Past or Present Job)
       ODH Occupational Hazard (component of ODH Past or Present Job)
       ODH Usual Industry  (component of ODH Usual Work)-->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.216' or @root = '2.16.840.1.113883.10.20.22.4.215' or @root = '2.16.840.1.113883.10.20.22.4.219']]">
        <component>
            <xsl:call-template name="comment-subprofile-name" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName" select="'code'" />
                <xsl:with-param name="includeCoding" select="true()" />
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:value" />
        </component>
    </xsl:template>


    <!-- Exposure/Contact Information Observation - bundle entry-->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.52']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant[not(@typeCode = 'CSM')]" mode="bundle-entry" />
    </xsl:template>

    <!-- Exposure/Contact Information Observation -> US Public Health Exposure Contact Information -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.52']]">
        <xsl:comment>Exposure/Contact Information Observation</xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />

            <xsl:choose>
                <xsl:when test="cda:participant/sdtc:functionCode">
                    <xsl:apply-templates select="cda:participant/sdtc:functionCode">
                        <xsl:with-param name="pElementName">category</xsl:with-param>
                    </xsl:apply-templates>

                </xsl:when>
                <xsl:otherwise>
                    <category>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ActClass" />
                            <code value="EXPOS" />
                            <display value="exposure" />
                        </coding>
                        <text value="An interaction between entities that provides opportunity for transmission of a physical, chemical, or biological agent from an exposure source entity to an exposure target entity." />
                    </category>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <!-- focus (cda:participant) person, animal, location -->
            <xsl:for-each select="cda:participant[not(@typeCode = 'CSM')]">
                <focus>
                    <reference value="urn:uuid:{@lcg:uuid}" />
                </focus>
            </xsl:for-each>
            <xsl:apply-templates select="cda:effectiveTime">
                <xsl:with-param name="pStartElementName">effective</xsl:with-param>
            </xsl:apply-templates>

            <xsl:call-template name="performer-or-author" />

            <xsl:for-each select="cda:participant[@typeCode = 'CSM']">
                <component>
                    <code>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                            <code value="EXPAGNT" />
                            <display value="ExposureAgent" />
                        </coding>
                    </code>
                    <xsl:apply-templates select="cda:participantRole/cda:playingEntity/cda:code">
                        <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
                    </xsl:apply-templates>
                </component>
            </xsl:for-each>
        </Observation>
    </xsl:template>

    <!-- Generic Observation Processing -->
    <xsl:template match="cda:observation" priority="-1">
        <xsl:comment>Processing as generic observation: <xsl:value-of select="cda:templateId/@root" />:<xsl:value-of select="cda:templateId/extension" /></xsl:comment>
        <Observation>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <xsl:call-template name="subject-reference" />
            <xsl:choose>
                <!-- MD: need to check the effectiveTime present and has value -->
                <xsl:when test="cda:effectiveTime and not(cda:effectiveTime/@nullFlavor)">
                    <xsl:apply-templates select="cda:effectiveTime">
                        <xsl:with-param name="pStartElementName">effective</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>

            <xsl:apply-templates select="/cda:ClinicalDocument/cda:effectiveTime" mode="observation" />

            <xsl:call-template name="performer-or-author" />

            <xsl:choose>
                <xsl:when test="cda:value[@xsi:type = 'INT']">
                    <!-- There is no valueInteger in observations. Assume is a scale instead -->
                    <xsl:apply-templates select="cda:value" mode="scale" />
                </xsl:when>
                <xsl:when test="cda:value[@xsi:type = 'CD']">
                    <xsl:apply-templates select="cda:value" />
                </xsl:when>
                <xsl:when test="cda:value[@xsi:type = 'BL']">
                    <valueBoolean value="true" />
                </xsl:when>
                <xsl:when test="cda:value[@nullFlavor]">
                    <xsl:apply-templates select="cda:value/@nullFlavor" mode="data-absent-reason" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:value" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:interpretationCode" />

            <xsl:apply-templates select="cda:methodCode">
                <xsl:with-param name="pElementName" select="'method'" />
                <xsl:with-param name="includeCoding" select="true()" />
            </xsl:apply-templates>

            <xsl:apply-templates select="cda:referenceRange" />
            <xsl:for-each select="cda:entryRelationship/cda:observation">
                <hasMember>
                    <xsl:apply-templates select="." mode="reference" />
                </hasMember>
            </xsl:for-each>
        </Observation>
    </xsl:template>

    <xsl:template name="performer-or-author">
        <xsl:choose>
            <xsl:when test="cda:performer/cda:assignedEntity[assignedPerson|assignedEntity]">
                <xsl:for-each select="cda:performer/cda:assignedEntity">
                    <performer>
                        <reference value="urn:uuid:{@lcg:uuid}" />
                    </performer>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="
                    cda:author/cda:assignedAuthor/cda:assignedPerson or
                    ancestor::cda:section[1]/cda:author/cda:assignedAuthor or
                    /cda:ClinicalDocument/cda:author/cda:assignedAuthor/cda:assignedPerson or
                    /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty">
                <xsl:call-template name="author-reference">
                    <xsl:with-param name="pElementName">performer</xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>No author reference candidate found</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Generic bundle entry creation (inc. author and contained templates) -->
    <xsl:template match="cda:observation" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author[cda:assignedAuthor[cda:assignedPerson or cda:assignedDevice]]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer[cda:assignedEntity[cda:assignedPerson or cda:assignedOrganization]]" mode="bundle-entry" />
        <!--        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />-->
        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>


</xsl:stylesheet>
