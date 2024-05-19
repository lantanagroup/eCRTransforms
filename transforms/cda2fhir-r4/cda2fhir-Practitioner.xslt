<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template name="make-practitioner">
        <xsl:param name="id" />
        <xsl:param name="name" />
        <xsl:param name="telecom" />
        <xsl:param name="address" />

        <xsl:variable name="vIdentifier">
            <xsl:apply-templates select="$id" />
            <xsl:if test="not($id)">
                <identifier>
                    <system>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </system>
                    <value>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </value>
                </identifier>
            </xsl:if>
        </xsl:variable>

        <Practitioner>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner" />
            </meta>
            <text>
                <status value="generated" />
                <div xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="$name">
                        <xsl:choose>
                            <xsl:when test="cda:family">
                                <p>
                                    <xsl:text>Name: </xsl:text>
                                    <xsl:value-of select="cda:family" />
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="cda:given" />
                                </p>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:for-each select="$vIdentifier/fhir:identifier">
                        <p>Identifier system: <xsl:value-of select="fhir:system/@value" /> value: <xsl:value-of select="fhir:value/@value" /></p>
                    </xsl:for-each>
                    <xsl:for-each select="$telecom">
                        <p>Telephone: <xsl:value-of select="@value" /></p>
                    </xsl:for-each>
                </div>
            </text>
            <xsl:for-each select="$vIdentifier/fhir:identifier">
                <xsl:copy-of select="." />
            </xsl:for-each>
            <xsl:apply-templates select="$name" />
            <xsl:apply-templates select="$telecom" />
            <xsl:apply-templates select="$address" />
            <!-- Qualification -->
            <xsl:choose>
                <xsl:when test="cda:participantRole">
                    <xsl:apply-templates select="cda:participantRole/cda:code" mode="practitioner" />
                </xsl:when>
                <xsl:when test="cda:assignedAuthor">
                    <xsl:apply-templates select="cda:assignedAuthor/cda:code" mode="practitioner" />
                </xsl:when>
            </xsl:choose>
        </Practitioner>
    </xsl:template>

    <xsl:template match="cda:code" mode="practitioner">
        <qualification>
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:call-template>
        </qualification>
    </xsl:template>

    <!--<xsl:template match="cda:author[not(cda:assignedAuthor/cda:representedOrganization)] | cda:legalAuthenticator | cda:performer[not(cda:assignedEntity/cda:representedOrganization)] | cda:participant" mode="bundle-entry">
        <xsl:for-each select="cda:assignedAuthor | cda:assignedEntity |  cda:associatedEntity">
            <!-\-<xsl:apply-templates select="." mode="bundle-entry" />-\->
            <xsl:call-template name="create-bundle-entry" />
            
        </xsl:for-each>
    </xsl:template>
    
    
    <xsl:template match="cda:assignedEntity[not(cda:representedOrganization)]">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:id" />
            <xsl:with-param name="name" select="cda:assignedPerson/cda:name" />
            <xsl:with-param name="telecom" select="cda:telecom" />
            <xsl:with-param name="address" select="cda:addr" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="cda:author">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:assignedAuthor/cda:id" />
            <xsl:with-param name="name" select="cda:assignedAuthor/cda:assignedPerson/cda:name" />
            <xsl:with-param name="telecom" select="cda:assignedAuthor/cda:telecom" />
            <xsl:with-param name="address" select="cda:assignedAuthor/cda:addr" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:legalAuthenticator">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:assignedEntity/cda:id" />
            <xsl:with-param name="name" select="cda:assignedEntity/cda:assignedPerson/cda:name" />
            <xsl:with-param name="telecom" select="cda:assignedEntity/cda:telecom" />
            <xsl:with-param name="address" select="cda:assignedEntity/cda:addr" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:performer[not(cda:assignedEntity/cda:representedOrganization)]">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:assignedEntity/cda:id" />
            <xsl:with-param name="name" select="cda:assignedEntity/cda:assignedPerson/cda:name" />
            <xsl:with-param name="telecom" select="cda:assignedEntity/cda:telecom" />
            <xsl:with-param name="address" select="cda:assignedEntity/cda:addr" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:participant">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:participantRole/cda:id" />
            <xsl:with-param name="name" select="cda:participantRole/cda:playingEntity/cda:name" />
            <xsl:with-param name="telecom" select="cda:participantRole/cda:telecom" />
            <xsl:with-param name="address" select="cda:participantRole/cda:addr" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:informationRecipient">
        <xsl:call-template name="make-practitioner">
            <xsl:with-param name="id" select="cda:intendedRecipient/cda:id" />
            <xsl:with-param name="name" select="cda:intendedRecipient/cda:informationRecipient/cda:name" />
            <xsl:with-param name="telecom" select="cda:intendedRecipient/cda:telecom" />
            <xsl:with-param name="address" select="cda:intendedRecipient/cda:addr" />
        </xsl:call-template>
    </xsl:template>-->



    <!--<xsl:template name="make-practitioner">
        <xsl:param name="id" />
        <xsl:param name="name" />
        <xsl:param name="telecom" />
        <xsl:param name="address" />
        <Practitioner>
            <xsl:comment>
        <xsl:value-of select="local-name(parent::cda:*)" />
        <xsl:for-each select="parent::cda:*/cda:id">
          <xsl:text>[cda:id</xsl:text>
          <xsl:if test="@root">
            <xsl:text>[@root="</xsl:text>
            <xsl:value-of select="@root" />
            <xsl:text>"]</xsl:text>
          </xsl:if>
          <xsl:text>]</xsl:text>
        </xsl:for-each>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="local-name(.)" />
      </xsl:comment>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner" />
            </meta>
            <text>
                <status value="generated" />
                <!-\- Not sure how you'd like the ID info generated in the html output. I can output them in the way the rest of it is done but wanted to double check. -\->
                <div xmlns="http://www.w3.org/1999/xhtml">
                    <xsl:for-each select="$name">
                        <xsl:choose>
                            <xsl:when test="cda:family">
                                <p>
                                    <xsl:text>Name: </xsl:text>
                                    <xsl:value-of select="cda:family" />
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="cda:given" />
                                </p>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:for-each select="cda:id">
                        <p><xsl:value-of select="@root" />|<xsl:value-of select="@extension" /></p>

                    </xsl:for-each>

                    <p>Telephone: <xsl:value-of select="$telecom/@value" /></p>
                </div>
            </text>
            <xsl:apply-templates select="$id" />
            <xsl:apply-templates select="$name" />
            <xsl:apply-templates select="$telecom" />
            <xsl:apply-templates select="$address" />
            <!-\- Qualification -\->
            <xsl:choose>
                <xsl:when test="cda:participantRole">
                    <xsl:apply-templates select="cda:participantRole/cda:code" mode="practitioner" />
                </xsl:when>
                <xsl:when test="cda:assignedAuthor">
                    <xsl:apply-templates select="cda:assignedAuthor/cda:code" mode="practitioner" />
                </xsl:when>
            </xsl:choose>
        </Practitioner>
    </xsl:template>

    <xsl:template match="cda:code" mode="practitioner">
        <qualification>
            <xsl:call-template name="newCreateCodableConcept">
                <xsl:with-param name="pElementName">code</xsl:with-param>
            </xsl:call-template>
        </qualification>
    </xsl:template>-->
</xsl:stylesheet>
