<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:custodian" mode="bundle-entry">
        <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="
            cda:representedCustodianOrganization |
            cda:representedOrganization |
            cda:receivedOrganization |
            cda:providerOrganization |
            cda:manufacturerOrganization |
            cda:serviceProviderOrganization |
            cda:participant[@typeCode = 'LOC'][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.4'])]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <!-- Participant inside an [ODH R1] Past or Present Occupation Observation  -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']/cda:participant[@typeCode = 'IND']" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:custodian" mode="reference">
        <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
            <xsl:apply-templates select="." mode="reference" />
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:custodian">
        <xsl:for-each select="cda:assignedCustodian/cda:representedCustodianOrganization">
            <xsl:apply-templates select="." />
        </xsl:for-each>
    </xsl:template>

    <xsl:template
        match="cda:representedCustodianOrganization | cda:representedOrganization | cda:scopingOrganization | cda:receivedOrganization | cda:serviceProviderOrganization | cda:providerOrganization | cda:manufacturerOrganization">
        <xsl:call-template name="create-organization" />
    </xsl:template>

    <!-- Organization from participant of type LOC -->
    <xsl:template
        match="cda:participant[@typeCode = 'LOC'][cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.1' or cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.2' or cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.3']">
        <Organization>
            <xsl:choose>
                <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.1'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-routing-entity-organization" />
                    </meta>
                </xsl:when>
                <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.2'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-responsible-agency-organization" />
                    </meta>
                </xsl:when>
                <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.3'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-rules-authoring-agency-organization" />
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="add-participant-meta" />
                </xsl:otherwise>

            </xsl:choose>
            <xsl:comment>participant[LOC]</xsl:comment>
            <xsl:choose>
                <xsl:when test="cda:participantRole/cda:id">
                    <xsl:apply-templates select="cda:participantRole/cda:id" />
                </xsl:when>
            </xsl:choose>
            <active value="true" />

            <!-- Adding type -->
            <xsl:apply-templates select="cda:participantRole/cda:code">
                <xsl:with-param name="pElementName" select="'type'" />
            </xsl:apply-templates>

            <xsl:if test="cda:participantRole/cda:playingEntity/cda:name/text()">
                <name value="{cda:participantRole/cda:playingEntity/cda:name}" />
            </xsl:if>
            <xsl:apply-templates select="cda:participantRole/cda:telecom" />
            <xsl:apply-templates select="cda:participantRole/cda:addr" />
        </Organization>
    </xsl:template>

    <!-- Organization from Participant inside an [ODH R1] Past or Present Occupation Observation  -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.217']/cda:participant[@typeCode = 'IND']">
        <!-- MD: Check IG -->
        <!--<xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig" />
        </xsl:variable>-->

        <Organization>
            <!-- MD: for eICR Organization using us-ph-organization profile -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-organization" />
                    </meta>
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="cda:participantRole/cda:id">
                    <xsl:apply-templates select="cda:participantRole/cda:id" />
                </xsl:when>
                <!-- identifier isn't a required field, so remove this -->
                <!--<xsl:otherwise>
                    <identifier>
                        <system value="urn:ietf:rfc:3986" />
                        <value value="urn:uuid:{@lcg:uuid}" />
                    </identifier>
                </xsl:otherwise>-->
            </xsl:choose>
            <active value="true" />

            <!-- Adding type -->
            <xsl:apply-templates select="cda:participantRole/cda:code">
                <xsl:with-param name="pElementName" select="'type'" />
            </xsl:apply-templates>

            <xsl:if test="cda:participantRole/cda:playingEntity/cda:name/text()">
                <name value="{cda:participantRole/cda:playingEntity/cda:name}" />
            </xsl:if>
            <xsl:apply-templates select="cda:participantRole/cda:telecom" />
            <xsl:apply-templates select="cda:participantRole/cda:addr" />
        </Organization>
    </xsl:template>

    <!-- standard Organization from representedCustodianOrganization, representedOrganization, etc -->
    <xsl:template name="create-organization">
        <!-- MD: Check IG -->
        <!--<xsl:variable name="vCurrentIg">
            <xsl:call-template name="get-current-ig" />
        </xsl:variable>-->

        <Organization>
            <!-- MD: for eICR Organization using us-ph-organization profile -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
                    <meta>
                        <profile value="http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-organization" />
                    </meta>
                </xsl:when>
                <xsl:otherwise>
                    <!-- SG 20191211: Add meta.profile -->
                    <xsl:call-template name="add-participant-meta" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <!-- If this is an Organization without a person preceding-sibling 
                     grab any ids that are preceding siblings because otherwise they will get
                     lost - if there was a preceding sibling that was a person the ids
                     would get put into a PractitionerRole 
                     However, can only have one NPI (2.16.840.1.113883.4.6) and one CLIA (2.16.840.1.113883.4.7), 
                     so pick the first non-null NPI and first non-null CLIA and use that -->
                
                <xsl:when test="not(preceding-sibling::cda:assignedPerson) and cda:id">
                    <xsl:variable name="vPossibleNPIOrgIdentifiers" select="cda:id[@root='2.16.840.1.113883.4.6'] | preceding-sibling::cda:id[@root='2.16.840.1.113883.4.6']" />
                    <xsl:variable name="vPossibleCLIAOrgIdentifiers" select="cda:id[@root='2.16.840.1.113883.4.7'] | preceding-sibling::cda:id[@root='2.16.840.1.113883.4.7']" />
                    <xsl:variable name="vPossibleOtherOrgIdentifiers" select="cda:id[not(@root='2.16.840.1.113883.4.6') and not(@root='2.16.840.1.113883.4.7')] | preceding-sibling::cda:id[not(@root='2.16.840.1.113883.4.6') and not(@root='2.16.840.1.113883.4.7')]" />
                    <xsl:choose>
                        <xsl:when test="count($vPossibleNPIOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="count($vPossibleCLIAOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="$vPossibleOtherOrgIdentifiers" />
                    <!--<xsl:apply-templates select="cda:id" />
                    <xsl:apply-templates select="preceding-sibling::cda:id" />-->
                </xsl:when>
                <xsl:when test="not(preceding-sibling::cda:assignedPerson)">
                    <xsl:variable name="vPossibleNPIOrgIdentifiers" select="preceding-sibling::cda:id[@root='2.16.840.1.113883.4.6']" />
                    <xsl:variable name="vPossibleCLIAOrgIdentifiers" select="preceding-sibling::cda:id[@root='2.16.840.1.113883.4.7']" />
                    <xsl:variable name="vPossibleOtherOrgIdentifiers" select="preceding-sibling::cda:id[not(@root='2.16.840.1.113883.4.6') and not(@root='2.16.840.1.113883.4.7')]" />
                    <xsl:choose>
                        <xsl:when test="count($vPossibleNPIOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="count($vPossibleCLIAOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="$vPossibleOtherOrgIdentifiers" />
<!--                    <xsl:apply-templates select="preceding-sibling::cda:id" />-->
                </xsl:when>
                <xsl:when test="cda:id">
                    <xsl:variable name="vPossibleNPIOrgIdentifiers" select="cda:id[@root='2.16.840.1.113883.4.6']" />
                    <xsl:variable name="vPossibleCLIAOrgIdentifiers" select="cda:id[@root='2.16.840.1.113883.4.7']" />
                    <xsl:variable name="vPossibleOtherOrgIdentifiers" select="cda:id[not(@root='2.16.840.1.113883.4.6') and not(@root='2.16.840.1.113883.4.7')]" />
                    <xsl:choose>
                        <xsl:when test="count($vPossibleNPIOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleNPIOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="count($vPossibleCLIAOrgIdentifiers) > 1">
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers[@extension][1]" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$vPossibleCLIAOrgIdentifiers" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="$vPossibleOtherOrgIdentifiers" />
                    
                    <!--<xsl:apply-templates select="cda:id" />-->
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            <active value="true" />
            <xsl:for-each select="cda:standardIndustryClassCode">
                <xsl:call-template name="newCreateCodableConcept">
                    <xsl:with-param name="pElementName">type</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:if test="cda:name/text()">
                <name>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:name" />
                    </xsl:attribute>
                </name>
            </xsl:if>
            <!-- SG: US Core Organization needs a telecom so if this is a organization that
            doesn't have a telecom, check to see if its containing role has telecom(s) that
            we can use
            in the case of location/serviceProviderOrganization, let's check siblings
             -->
            <xsl:choose>
                <!-- If the organization has a telecom, use it -->
                <xsl:when test="cda:telecom">
                    <xsl:apply-templates select="cda:telecom" />
                </xsl:when>
                <!-- If the parent role has a telcom, use that -->
                <xsl:when test="parent::*/cda:telecom">
                    <xsl:apply-templates select="parent::*/cda:telecom" />
                </xsl:when>
                <!-- else if a sibling has a telecom, use that -->
                <xsl:when test="preceding-sibling::*/cda:telecom">
                    <xsl:apply-templates select="preceding-sibling::*/cda:telecom" />
                </xsl:when>
                <xsl:when test="following-sibling::*/cda:telecom">
                    <xsl:apply-templates select="following-sibling::*/cda:telecom" />
                </xsl:when>
                <xsl:otherwise>
                    <telecom>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </telecom>
                </xsl:otherwise>
            </xsl:choose>
            <!-- SG: US Public Health Organization needs an address so if this is a organization that
            doesn't have a address, check to see if its containing role has an address(s) that
            we can use 
            in the case of location/serviceProviderOrganization, let's check siblings
      -->
            <xsl:choose>
                <!-- If the organization has an address, use it -->
                <xsl:when test="cda:addr">
                    <xsl:apply-templates select="cda:addr" />
                </xsl:when>
                <!-- else if the parent role has an address, use that -->
                <xsl:when test="parent::*/cda:addr">
                    <xsl:apply-templates select="parent::*/cda:addr" />
                </xsl:when>
                <!-- else if a sibling has an address, use that -->
                <xsl:when test="preceding-sibling::*/cda:addr">
                    <xsl:apply-templates select="preceding-sibling::*/cda:addr" />
                </xsl:when>
                <xsl:when test="following-sibling::*/cda:addr">
                    <xsl:apply-templates select="following-sibling::*/cda:addr" />
                </xsl:when>
                <xsl:otherwise>
                    <address>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </address>
                </xsl:otherwise>
            </xsl:choose>
        </Organization>
    </xsl:template>
</xsl:stylesheet>
