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
            <!--<text>
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
            </text>-->
            <xsl:for-each select="$vIdentifier/fhir:identifier">
                <xsl:copy-of select="." />
            </xsl:for-each>
            <xsl:apply-templates select="$name">
                <xsl:with-param name="pFamilyRequired" select="true()"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="$telecom" />
            <xsl:apply-templates select="$address" />
            <!-- 20261124 Claude (SG decision 2026-11-24, re-trace finding RT-A11): removed a Practitioner.qualification
                 branch that could never run. It looked for cda:participantRole or cda:assignedAuthor as a CHILD of the
                 person element this template is called on, which the CDA schema does not allow. The role's code is not
                 lost: cda2fhir-PractitionerRole.xslt writes it to PractitionerRole.code. The mode="practitioner"
                 template it used went with it. -->
        </Practitioner>
    </xsl:template>

    <!-- 20260803 Claude (item 41): a "hollow" author (assignedAuthor carrying only <id> elements) that
         references no complete participation elsewhere in the document used to have its uuid blanked in
         the update-referenced-actor-uuids phase, so requester / Provenance.agent.who references were
         emitted as the invalid "urn:uuid:". The phase now keeps the minted uuid and flags the author
         lcg:unmatched="true"; a global pass in cda2fhir-Bundle.xslt reaches these two templates.
         The result is an identifier-only Practitioner: the ids a hollow author carries (typically an
         Epic-internal id plus an NPI) are real data worth preserving, and requester and agent.who both
         allow Reference(Practitioner). name is required by us-core-practitioner and is genuinely absent
         in source, so per the house convention family carries the data-absent-reason extension (same
         shape the datatypes module emits for a name element without family). -->
    <!-- 20261124 Claude (RT-C1): both templates now also take a hollow performer (cda:performer/cda:assignedEntity) -->
    <xsl:template match="cda:assignedAuthor | cda:assignedEntity" mode="unmatched-participation-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:assignedAuthor[@lcg:unmatched = 'true'] | cda:assignedEntity[@lcg:unmatched = 'true']" priority="2">
        <Practitioner>
            <meta>
                <profile value="http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner" />
            </meta>
            <xsl:call-template name="breadcrumb-comment" />
            <xsl:apply-templates select="cda:id" />
            <name>
                <family>
                    <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                        <valueCode value="unknown" />
                    </extension>
                </family>
            </name>
        </Practitioner>
    </xsl:template>

</xsl:stylesheet>
