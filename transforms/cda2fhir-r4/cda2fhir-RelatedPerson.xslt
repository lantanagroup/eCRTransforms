<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">
    
    <!-- (ODH) Subject (relatedSubject) to Base FHIR RelatedPerson -->
    <xsl:template match="cda:subject[preceding-sibling::cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.217']][cda:relatedSubject]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>
    
    <xsl:template match="cda:informant[cda:relatedEntity]" mode="bundle-entry">
        <xsl:for-each select="cda:relatedEntity">
            <xsl:call-template name="create-bundle-entry" />
        </xsl:for-each>
    </xsl:template>
    
    <!-- (eICR) Person Participant to Base FHIR RelatedPerson -->
    <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.6']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>
    
    <!-- (eICR) Animal Participant to Base FHIR RelatedPerson -->
    <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.5']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>
    
    <!-- (eICR) Person Participant to Base FHIR RelatedPerson -->
    <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.6']]">
        <RelatedPerson>
            <xsl:comment>cda:participant (Person Participant)</xsl:comment>
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:participantRole/cda:playingEntity/cda:name" />
            <xsl:apply-templates select="cda:participantRole/cda:playingEntity/sdtc:birthTime" />
        </RelatedPerson>
    </xsl:template>
    
    <xsl:template match="cda:participant[cda:associatedEntity[@classCode = 'NOK']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:section" mode="relatedPerson-entry">
        <xsl:for-each select="cda:entry/cda:organizer/cda:subject/cda:relatedSubject[@classCode = 'PRS']">
            <xsl:variable name="related-person-id" select="cda:subject/sdtc:id" />
            <xsl:variable name="related-person-name" select="cda:subject/cda:name" />
            <entry>
                <!-- Using cda:subject/@lsc:uuid here to avoid a conflict with RelatedPerson below, which uses the uuid on relatedSubject -->
                <fullUrl value="urn:uuid:{cda:subject/@lcg:uuid}" />
                <resource>
                    <Patient>
                        <xsl:call-template name="generate-text-patient2" />
                        <xsl:for-each select="cda:subject/sdtc:id">
                            <identifier>
                                <system>
                                    <xsl:attribute name="value" select="concat('urn:oid:', @root)" />
                                </system>
                                <value>
                                    <xsl:attribute name="value" select="@extension" />
                                </value>
                            </identifier>
                        </xsl:for-each>
                        <xsl:apply-templates select="cda:subject/cda:name" />
                    </Patient>
                </resource>
            </entry>
            <entry>
                <fullUrl value="urn:uuid:{@lcg:uuid}" />
                <resource>
                    <RelatedPerson>
                        <xsl:apply-templates select="//cda:patientRole/cda:id" />
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:id" />
                        <patient>
                            <reference value="urn:uuid:{cda:subject/@lcg:uuid}" />
                        </patient>
                        <xsl:apply-templates select="cda:code">
                            <xsl:with-param name="pElementName">relationship</xsl:with-param>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:name" />
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:administrativeGenderCode" />
                        <xsl:apply-templates select="//cda:patientRole/cda:patient/cda:birthTime" />
                    </RelatedPerson>
                </resource>
            </entry>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="generate-text-patient2">
        <text>
            <status value="generated" />
            <div xmlns="http://www.w3.org/1999/xhtml">
                <xsl:for-each select="cda:subject/cda:name[not(@nullFlavor)]">
                    <xsl:choose>
                        <xsl:when test="position() = 1">
                            <h1><xsl:value-of select="cda:family" />, <xsl:value-of select="cda:given" /></h1>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>Alternate name: <xsl:value-of select="cda:family" />, <xsl:value-of select="cda:given" /></p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <xsl:for-each select="cda:subject/cda:administrativeGenderCode[not(@nullFlavor)]">
                    <p>Gender: <xsl:value-of select="@code" /></p>
                </xsl:for-each>
                <xsl:for-each select="cda:subject/cda:birthTime[not(@nullFlavor)]">
                    <xsl:variable name="vTest">
                        <xsl:value-of select="lcg:cdaTS2date(@value)" />
                    </xsl:variable>
                    <p>Birthdate: <xsl:value-of select="lcg:cdaTS2date(@value)" /></p>
                </xsl:for-each>

            </div>
        </text>
    </xsl:template>

    <!-- (eICR) Animal Participant to Base FHIR RelatedPerson with extension -->
    <!--http://hl7.org/fhir/StructureDefinition/practitioner-animalSpecies-->
    <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.5']]">
        <RelatedPerson>
            <xsl:comment>cda:participant (Animal Participant)</xsl:comment>
            <extension url="http://hl7.org/fhir/StructureDefinition/practitioner-animalSpecies">
                <xsl:apply-templates select="cda:participantRole/cda:playingEntity/cda:code">
                    <xsl:with-param name="pElementName">valueCodeableConcept</xsl:with-param>
                </xsl:apply-templates>
            </extension>
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="cda:participantRole/cda:playingEntity/cda:code/cda:originalText">
                    <name>
                        <text>
                            <xsl:attribute name="value" select="cda:participantRole/cda:playingEntity/cda:code/cda:originalText" />
                        </text>
                    </name>
                </xsl:when>
                <xsl:when test="cda:participantRole/cda:playingEntity/cda:code/@displayName">
                    <name>
                        <text>
                            <xsl:attribute name="value" select="cda:participantRole/cda:playingEntity/cda:code/@displayName" />
                        </text>
                    </name>
                </xsl:when>

            </xsl:choose>
        </RelatedPerson>
    </xsl:template>

    <!-- NOK Person Participant to Base FHIR RelatedPerson -->
    <xsl:template match="cda:participant[cda:associatedEntity[@classCode = 'NOK']]">
        <RelatedPerson>
            <xsl:comment>cda:participant (NOK)</xsl:comment>
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <relationship>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/v2-0131" />
                    <code value="N" />
                    <display value="Next-of-Kin" />
                </coding>
            </relationship>
            <xsl:apply-templates select="cda:associatedEntity/cda:code">
                <xsl:with-param name="pElementName">relationship</xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:associatedEntity/cda:id" />

            <xsl:apply-templates select="cda:associatedEntity/cda:associatedPerson/cda:name" />
            <xsl:apply-templates select="cda:associatedEntity/cda:telecom" />
            <xsl:apply-templates select="cda:associatedEntity/cda:address" />
        </RelatedPerson>
    </xsl:template>
    
    <!-- Observation/subject in an ODH template to Base FHIR RelatedPerson -->
    <xsl:template match="cda:subject[preceding-sibling::cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.217']][cda:relatedSubject]">
        <RelatedPerson>
            <xsl:comment>ODH RelatedSubject</xsl:comment>
            <!-- patient -->
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <!-- relationship -->
            <xsl:apply-templates select="cda:relatedSubject/cda:code">
                <xsl:with-param name="pElementName">relationship</xsl:with-param>
            </xsl:apply-templates>
        </RelatedPerson>
    </xsl:template>


    <!-- informant/relatedEntity to Base FHIR RelatedPerson -->
    <xsl:template match="cda:relatedEntity">
        <RelatedPerson>
            <xsl:comment>cda:informant/cda:relatedPerson</xsl:comment>
            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">patient</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">relationship</xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="cda:id" />
            <xsl:apply-templates select="cda:relatedPerson/cda:name" />
            <xsl:apply-templates select="cda:telecom" />
            <xsl:apply-templates select="cda:address" />
        </RelatedPerson>
    </xsl:template>
</xsl:stylesheet>
