<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" version="2.0" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml">

    <xsl:import href="c-to-fhir-utility.xslt" />
    <xsl:import href="cda2fhir-Narrative.xslt" />

    <xsl:template match="cda:ClinicalDocument" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <!-- MD add infulfillmentof -->
        <xsl:apply-templates select="cda:inFulfillmentOf" mode="bundle-entry" />

        <!-- MD: create the Patient will be referenced in RelatedPerson
      create the ReleatedPerson will be reference in Patient on recordTarget
      2.16.840.1.113883.10.20.22.2.15 family history section
    -->
        <xsl:variable name="vTest" select="
                //cda:section/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.15']/following-sibling::cda:entry/
                cda:organizer/cda:subject/cda:relatedSubject[@classCode = 'PRS']/cda:code/@code" />
        <xsl:choose>
            <xsl:when test="
                    //cda:section/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.15']/
                    following-sibling::cda:entry/cda:organizer/cda:subject/cda:relatedSubject[@classCode = 'PRS']">
                <xsl:for-each select="cda:component/cda:structuredBody/cda:component">
                    <xsl:choose>
                        <xsl:when test="cda:section/cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.15']">
                            <xsl:apply-templates select="cda:section" mode="relatedPerson-entry" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>


        <xsl:apply-templates select="cda:recordTarget" mode="bundle-entry" />
        <xsl:apply-templates select="cda:componentOf/cda:encompassingEncounter" mode="bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:custodian" mode="bundle-entry" />
        <xsl:apply-templates select="cda:legalAuthenticator" mode="bundle-entry" />
        <xsl:apply-templates select="cda:authenticator" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:documentationOf/cda:serviceEvent" mode="bundle-entry" />
        <!--        <xsl:apply-templates select="cda:informationRecipient/cda:intendedRecipient/cda:receivedOrganization" mode="bundle-entry" />-->
        <xsl:apply-templates select="cda:informationRecipient" mode="bundle-entry" />
        <xsl:apply-templates select="//cda:section/cda:author" mode="bundle-entry" />

    </xsl:template>

    <xsl:template match="cda:ClinicalDocument">
        <xsl:variable name="newSetIdUUID">
            <xsl:choose>
                <xsl:when test="cda:setId">
                    <xsl:value-of select="cda:setId/@lcg:uuid" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@lcg:uuid" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Composition>

            <xsl:call-template name="add-meta" />

            <xsl:if test="cda:languageCode/@code">
                <language>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:languageCode/@code" />
                    </xsl:attribute>
                </language>
            </xsl:if>

            <text>
                <status value="generated" />
                <xsl:choose>
                    <xsl:when test="cda:languageCode/@code">
                        <div xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
                            <xsl:call-template name="CDAtext" />
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div xmlns="http://www.w3.org/1999/xhtml">
                            <xsl:call-template name="CDAtext" />
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </text>
            <!-- ClinicalDocument.setId maps to Composition.identifier and ClinicalDocument.id maps to Bundle.id (see FHIR Composition documentation) 
                 - the SAXON-PE transformed values go in the above elements
          
               But need to preserve indentifying meta-data of the transformed CDA document
                - for eCR versionNumber will go into the official FHIR extension
                - for others versionNumber will go into the C-CDA on FHIR extension in Composition 
            -->
            <!-- For eICR/RR we want to default version number to 1 when it's missing -->
            <xsl:comment>Version Number</xsl:comment>
            <xsl:choose>
                <xsl:when test="
                        (/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2'] or
                        /cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']) and
                        not(cda:versionNumber/@value)">
                    <extension url="http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber">
                        <valueString value="1" />
                    </extension>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:versionNumber" />
                </xsl:otherwise>
            </xsl:choose>

            <!-- InformationRecipient extension -->
            <xsl:for-each select="cda:informationRecipient">
                <xsl:apply-templates select="." mode="extension" />
            </xsl:for-each>

            <!-- MD: add transform  
      <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension">
      there can be multiple OrderExtensions, each OrderExtension reference one ServiceRequest
      -->
            <xsl:for-each select="cda:inFulfillmentOf">
                <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/OrderExtension">
                    <valueReference>
                        <reference value="urn:uuid:{cda:order/@lcg:uuid}" />
                    </valueReference>
                </extension>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="cda:setId">
                    <xsl:apply-templates select="cda:setId" />
                </xsl:when>
                <xsl:otherwise>
                    <identifier>
                        <system value="urn:ietf:rfc:3986" />
                        <value value="urn:uuid:{$newSetIdUUID}" />
                    </identifier>
                </xsl:otherwise>
            </xsl:choose>
            <!--<identifier>
                <system value="urn:ietf:rfc:3986" />
                <!-\- <value value="urn:uuid:{$newSetIdUUID}" />  -\->
                <value value="urn:uuid:{cda:setId/@root}" />
            </identifier>-->
            <status value="final" />
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            <subject>
                <!-- TODO: handle multiple record targets (record as a group) -->
                <reference value="urn:uuid:{cda:recordTarget/@lcg:uuid}" />
            </subject>
            <xsl:if test="cda:componentOf/cda:encompassingEncounter">
                <encounter>
                    <xsl:apply-templates select="cda:componentOf/cda:encompassingEncounter" mode="reference" />
                </encounter>
            </xsl:if>
            <date>
                <xsl:attribute name="value">
                    <xsl:value-of select="lcg:cdaTS2date(cda:effectiveTime/@value)" />
                </xsl:attribute>
            </date>
            <xsl:for-each select="cda:author">
                <author>
                    <xsl:apply-templates select="cda:assignedAuthor" mode="reference" />
                </author>
            </xsl:for-each>
            <title>
                <xsl:attribute name="value">
                    <xsl:value-of select="cda:title" />
                </xsl:attribute>
            </title>
            <!-- Composition.confidentiality is deprecated. Use Composition.meta.security instead with a code from http://terminology.hl7.org/ValueSet/v3-ConfidentialityClassification -->
            <!-- 
            <xsl:if test="cda:confidentialityCode/@code">
                <confidentiality>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:confidentialityCode/@code" />
                    </xsl:attribute>
                </confidentiality>
            </xsl:if>
            -->
            <xsl:for-each select="cda:legalAuthenticator | cda:authenticator">
                <attester>
                    <xsl:choose>
                        <xsl:when test="local-name(.) = 'legalAuthenticator'">
                            <mode value="legal" />
                        </xsl:when>
                        <xsl:otherwise>
                            <mode value="professional" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="cda:time/@value">
                        <time value="{lcg:cdaTS2date(cda:time/@value)}" />
                    </xsl:if>
                    <party>
                        <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
                    </party>
                </attester>
            </xsl:for-each>
            <!--
            <xsl:if test="cda:legalAuthenticator">
                <attester>
                    <mode value="legal"/>
                    <xsl:if test="cda:legalAuthenticator/cda:time/@value">
                        <time value="{lcg:cdaTS2date(cda:legalAuthenticator/cda:time/@value)}"/>
                    </xsl:if>
                    <party>
                        <xsl:apply-templates select="cda:legalAuthenticator/cda:assignedEntity" mode="reference"/>
                    </party>
                </attester>
            </xsl:if>
            -->

            <custodian>
                <xsl:apply-templates select="cda:custodian" mode="reference" />
            </custodian>

            <!-- relatesTo contains the ClinicalDocument.id of the CDA document 
           (versionNumber and setId can be found using id as id is unique across all documents) -->
            <relatesTo>
                <code value="transforms" />
                <xsl:apply-templates select="cda:id">
                    <xsl:with-param name="pElementName">targetIdentifier</xsl:with-param>
                </xsl:apply-templates>
            </relatesTo>
            <xsl:apply-templates select="cda:documentationOf/cda:serviceEvent" mode="composition-event" />
            <xsl:apply-templates select="cda:component/cda:structuredBody/cda:component/cda:section" />
        </Composition>
    </xsl:template>

    <xsl:template match="cda:ClinicalDocument/cda:versionNumber">
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
                <xsl:otherwise>NA</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- SG 20191204: eCR & RR use the "official" FHIR extension for version number - added logic to use -->
        <xsl:choose>
            <xsl:when test="($vCurrentIg = 'eICR' or $vCurrentIg = 'RR')">
                <extension url="http://hl7.org/fhir/StructureDefinition/composition-clinicaldocument-versionNumber">
                    <valueString value="{@value}" />
                </extension>
            </xsl:when>
            <xsl:otherwise>
                <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/VersionNumber">
                    <valueInteger value="{@value}" />
                </extension>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:section">

        <!-- Check current Ig -->
        <xsl:variable name="vCurrentIg">
            <xsl:apply-templates select="/" mode="currentIg" />
        </xsl:variable>

        <!-- Don't want the encounters section if this is eICR - the encounter information goes in Composition.Encounter-->
        <xsl:choose>
            <xsl:when test="$vCurrentIg = 'eICR' and cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1'" />
            <xsl:otherwise>
                <section>
                    <!-- Start: Section Extensions -->
                    <xsl:if test="cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.2.3'] or cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.2.2']">
                        <xsl:apply-templates select="." mode="extension" />
                    </xsl:if>
                    <!-- End: Section Extensions -->

                    <!-- Only want title if it exists in the source document, don't want an empty title -->
                    <xsl:if test="cda:title">
                        <title>
                            <xsl:attribute name="value" select="cda:title" />
                        </title>
                    </xsl:if>
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName">code</xsl:with-param>
                    </xsl:apply-templates>
                    <text>
                        <xsl:choose>
                            <xsl:when test="count(cda:entry) = count(cda:entry[@typeCode = 'DRIV'])">
                                <status value="generated" />
                            </xsl:when>
                            <xsl:otherwise>
                                <status value="additional" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <div xmlns="http://www.w3.org/1999/xhtml">
                            <!-- MD: just in case there is no cda:text, need add a <p>no value</p> to avoid validation error -->
                            <xsl:choose>
                                <xsl:when test="cda:text">
                                    <xsl:apply-templates select="cda:text" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <p>
                                        <xsl:value-of select="'no value'" />
                                    </p>
                                </xsl:otherwise>
                            </xsl:choose>

                        </div>
                    </text>
                    <!-- SG: Birth Sex, Gender Identity, eICR Processing Status, Manually Initiated eICR, Reportability Response Priority are put in extensions in FHIR so we'll skip them -->

                    <xsl:choose>
                        <!-- MD:  History of Past illness Narrative should not have entry -->
                        <xsl:when test="not(cda:templateId[@root = '2.16.840.1.113883.10.20.22.2.65'])">
                            <xsl:for-each select="
                                    cda:entry[not(cda:observation/cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.200')]
                                    [not(cda:observation/cda:templateId/@root = '2.16.840.1.113883.10.20.34.3.45')]
                                    [not(cda:act/cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.29')]
                                    [not(cda:act/cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.22')]
                                    [not(cda:act/cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.7')]
                                    [not(cda:observation/cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.30')]">

                                <xsl:apply-templates select="cda:*" mode="reference">
                                    <xsl:with-param name="wrapping-elements">entry</xsl:with-param>
                                </xsl:apply-templates>

                            </xsl:for-each>
                        </xsl:when>
                    </xsl:choose>


                    <!-- Pregnancy Outcome is contained in Pregnancy Status in CDA but not in FHIR (it has a focus of the related pregnancy observation instead) -->
                    <xsl:if test="cda:code/@code = '90767-5'">
                        <xsl:for-each select="//cda:entryRelationship[cda:observation/cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.284']">
                            <xsl:apply-templates select="cda:observation" mode="reference">
                                <xsl:with-param name="wrapping-elements">entry</xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:for-each>
                    </xsl:if>
                    <xsl:apply-templates select="cda:component/cda:section" />
                </section>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:serviceEvent" mode="composition-event">
        <event>
            <xsl:comment>Add CCDA-on-FHIR-Performer extension after C-CDA on FHIR is published</xsl:comment>

            <xsl:for-each select="cda:performer/cda:assignedEntity">

                <extension url="http://hl7.org/fhir/us/ccda/StructureDefinition/PerformerExtension">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="wrapping-elements">valueReference</xsl:with-param>
                    </xsl:apply-templates>
                </extension>
            </xsl:for-each>

            <!-- MD: transform cda:serviceEvent/cda:code to fhir:Composition/fhir:event/fhir:code -->
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>

            <xsl:apply-templates select="cda:effectiveTime" mode="period" />

            <!-- CarePlan resource not strictly needed for ONC-HIP use casem, but added at Clinician's on FHIR event.  -->

            <detail>
                <xsl:apply-templates select="." mode="reference" />
            </detail>
        </event>
    </xsl:template>

</xsl:stylesheet>
