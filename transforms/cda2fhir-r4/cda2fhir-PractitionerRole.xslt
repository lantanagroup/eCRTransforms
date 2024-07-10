<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="
            cda:informationRecipient[cda:intendedRecipient] |
            cda:author[cda:assignedAuthor] |
            cda:legalAuthenticator[cda:assignedEntity] |
            cda:authenticator[cda:assignedEntity] |
            cda:performer[cda:assignedEntity] |
            cda:participant[cda:associatedEntity] |
            cda:participent[cda:participantRole] |
            cda:dataEnterer[cda:assignedEntity] |
            cda:informant[cda:assignedEntity]" mode="bundle-entry">
        <xsl:apply-templates select="
                cda:intendedRecipient |
                cda:assignedAuthor |
                cda:assignedEntity |
                cda:associatedEntity |
                cda:participantRole" mode="bundle-entry" />
    </xsl:template>

    <!-- Note: the informationRecipient structure is informationRecipient/intendedRecipient/informationRecipient -->
    <xsl:template match="
            cda:intendedRecipient |
            cda:assignedAuthor |
            cda:assignedEntity |
            cda:associatedEntity |
            cda:participantRole" mode="bundle-entry">
        <!-- Create up to 4 resources, PractitionerRole, Practitioner, Organization, Device-->
        <!-- PractitionerRole - if there isn't a person, don't create PractitionerRole for eCR -->
        <xsl:if test="
                cda:informationRecipient[parent::cda:intendedRecipient] or
                cda:assignedPerson or
                cda:associatedPerson">
            <xsl:call-template name="create-bundle-entry" />
        </xsl:if>
        <!-- Practitioner -->
        <xsl:for-each select="
                cda:informationRecipient[parent::cda:intendedRecipient] |
                cda:assignedPerson |
                cda:associatedPerson">
            <xsl:call-template name="create-bundle-entry" />
        </xsl:for-each>
        <!-- Organization -->
        <xsl:for-each select="
                cda:receivedOrganization |
                cda:representedOrganization |
                cda:scopingOrganization">
            <xsl:call-template name="create-bundle-entry" />
        </xsl:for-each>
        <!-- Device -->
        <xsl:apply-templates select="cda:assignedAuthoringDevice" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="
            cda:intendedRecipient |
            cda:assignedAuthor[not(cda:assignedAuthoringDevice)] |
            cda:assignedEntity |
            cda:associatedEntity |
            cda:participantRole[not(@classCode = 'TERR')][not(parent::cda:participant/@typeCode = 'CSM')]">
        <PractitionerRole>

            <!-- Set profiles based on IG and Resource if it is needed -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'NA'">
                    <xsl:call-template name="add-meta" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$gvCurrentIg" />
                            <xsl:with-param name="pResource" select="'PractitionerRole'" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$vProfileValue ne 'NA'">
                            <meta>
                                <profile>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="$vProfileValue" />
                                    </xsl:attribute>
                                </profile>
                            </meta>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="breadcrumb-comment" />

            <xsl:apply-templates select="cda:id[1]" />
            <xsl:if test="not(cda:id)">
                <identifier>
                    <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                        <valueCode value="unknown" />
                    </extension>
                </identifier>
            </xsl:if>
            <xsl:for-each select="
                    cda:informationRecipient[parent::cda:intendedRecipient] |
                    cda:assignedPerson |
                    cda:associatedPerson">
                <practitioner>
                    <xsl:apply-templates select="." mode="reference" />
                </practitioner>
            </xsl:for-each>
            <xsl:for-each select="
                    cda:receivedOrganization |
                    cda:representedOrganization |
                    cda:scopingOrganization">
                <organization>
                    <xsl:apply-templates select="." mode="reference" />
                </organization>
            </xsl:for-each>
            <xsl:if test="@classCode">
                <code>
                    <coding>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-RoleClass" />
                        <code value="{@classCode}" />
                    </coding>
                </code>
            </xsl:if>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:apply-templates>
            <!-- eCR PractitionerRole must have a telecom, if there is no telecom at this level, look into the 
                 person and organization for a telecom, otherwise data-absent-reason -->
            <xsl:choose>
                <xsl:when test="cda:telecom">
                    <xsl:apply-templates select="cda:telecom" />
                </xsl:when>
                <xsl:when test="descendant::cda:telecom">
                    <xsl:apply-templates select="descendant::cda:telecom" />
                </xsl:when>
                <xsl:otherwise>
                    <telecom>
                        <system value="other" />
                        <value>
                            <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                                <valueCode value="unknown" />
                            </extension>
                        </value>
                    </telecom>
                </xsl:otherwise>
            </xsl:choose>
        </PractitionerRole>
    </xsl:template>

    <xsl:template match="
            cda:informationRecipient[parent::cda:intendedRecipient] |
            cda:assignedPerson |
            cda:associatedPerson">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="../cda:id" />
            <xsl:with-param name="name" select="cda:name" />
            <xsl:with-param name="telecom" select="../cda:telecom" />
            <xsl:with-param name="address" select="../cda:addr" />
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
