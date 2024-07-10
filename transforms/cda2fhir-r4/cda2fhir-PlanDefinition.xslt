<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:output indent="yes" />

    <!-- No longer using PlanDefinition for RR -->
    <!-- Plan Definition (from "Reportability Response Coded Information Organizer") -->
    <!-- There are as many PlanDefinitions as there are Reportability Information Organizers -->
    <!--<xsl:template match="cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.34']" mode="bundle-entry">
    <!-\- Create one bundle entry for each Relevant Reportable Condition Observation (Plan Definition)
          Each Plan Definition/Relevant Reportable Condition Observation represents a condition/PHA pair -\->
    <xsl:for-each select="cda:component/cda:observation/cda:entryRelationship/cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.13']">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
  </xsl:template>-->

    <!-- No longer using PlanDefinition for RR -->
    <!-- Plan Definition (from "Reportability Response Coded Information Organizer") -->
    <!-- Plan Definition matches the Reportability Information Organizer (not 2.3.34) -->
    <!--<xsl:template match="cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.13']">
        
        <PlanDefinition>
            <!-\- Generates an id that is unique for the node. It will always be the same for the same id. -\->
            <id value="{concat($gvCurrentIg, '-plandefinition-', generate-id(cda:id))}" />
            <xsl:call-template name="add-meta" />

            <!-\- Determination of Reportability -\->
            <xsl:for-each select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.19']">
                <xsl:apply-templates select="." mode="extension" />

                <!-\- Determination of Reportability Reason -\->
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.26']">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:for-each>

                <!-\- Determination of Reportability Rule -\->
                <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.27']">
                    <xsl:apply-templates select="." mode="extension" />
                </xsl:for-each>
            </xsl:for-each>

            <url value="{concat($gvCurrentIg, '-plandefinition-', generate-id(cda:id))}" />
            <status value="active" />

            <!-\- Rules Authoring Agency (2.16.840.1.113883.10.20.15.2.4.3) -> publisher -\->
            <publisher>
                <!-\-      <xsl:attribute name="value" select="cda:participantRole/cda:playingEntity/cda:name" />-\->
                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-rules-authoring-agency-organization-extension">
                    <valueReference>
                        <reference value="urn:uuid:{cda:participant[cda:templateId/@root='2.16.840.1.113883.10.20.15.2.4.3']/@lcg:uuid}" />
                    </valueReference>
                </extension>
            </publisher>

            <jurisdiction>
                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-location-relevance-extension">
                    <xsl:apply-templates select="cda:code">
                        <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                    </xsl:apply-templates>
                </extension>
                <!-\- routing-entity participant[2.16.840.1.113883.10.20.15.2.4.1] -\->
                <xsl:for-each select="cda:participant[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.1']">
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-routing-entity-organization-extension">
                        <valueReference>
                            <reference value="urn:uuid:{@lcg:uuid}" />
                        </valueReference>
                    </extension>
                </xsl:for-each>
                <!-\- responsible-agency participant[2.16.840.1.113883.10.20.15.2.4.2] -\->
                <xsl:for-each select="cda:participant[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.4.2']">
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-responsible-agency-organization-extension">
                        <valueReference>
                            <reference value="urn:uuid:{@lcg:uuid}" />
                        </valueReference>
                    </extension>
                </xsl:for-each>
                <!-\- Hard coding this here - it's needed for the PlanDefinition and this will always be USA -\->
                <coding>
                    <system value="urn:iso:std:iso:3166" />
                    <code value="US" />
                    <display value="United States of America" />
                </coding>
            </jurisdiction>

            <!-\- There is only one Goal - it is required - and it's always "Reportability Feedback" 
            We need to get the condition ("addresses") from the PARENT of this template we are in now 
            There is probably a way better way to go back and get this (that doesn't hard code
            the structure) but doing this for now -\->
            <!-\- 2.16.840.1.113883.10.20.15.2.3.12 / value -\->
            <goal>
                <description>
                    <text value="Reportability Feedback" />
                </description>
                <xsl:apply-templates select="../../cda:value">
                    <xsl:with-param name="pElementName" select="'addresses'" />
                </xsl:apply-templates>
            </goal>

            <!-\- We only want children of the template we are in now so changing the XPath slightly 
             Also there should only be one Action with multiple Documentations - have changed it so 
             that <action> is outside the loop
             There alway has to be one action in an RR and since this code is already RR specific... -\->
            <action>
                <xsl:for-each select="cda:component/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.20']">
                    <!-\- external resource 0..* -\->
                    <!-\- external document reference -\->
                    <xsl:for-each select="cda:reference/cda:externalDocument">
                        <documentation>
                            <xsl:for-each select="../../cda:code">
                                <!-\- code -\->
                                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-type-extension">
                                    <xsl:apply-templates select=".">
                                        <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                                    </xsl:apply-templates>
                                </extension>
                            </xsl:for-each>
                            <xsl:for-each select="../../cda:priorityCode">
                                <!-\- priorityCode -\->
                                <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension">
                                    <xsl:apply-templates select=".">
                                        <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                                    </xsl:apply-templates>
                                </extension>
                            </xsl:for-each>
                            <type value="documentation" />
                            <!-\- reference/externalDocument/code[OTH]/originalText -\->
                            <xsl:for-each select="cda:code[@nullFlavor = 'OTH']">
                                <display>
                                    <xsl:attribute name="value" select="cda:originalText" />
                                </display>
                            </xsl:for-each>
                            <!-\- reference/externalDocument/value[text/html]/reference -\->
                            <xsl:for-each select="cda:text[@mediaType = 'text/html']/cda:reference">
                                <url>
                                    <xsl:attribute name="value" select="@value" />
                                </url>
                            </xsl:for-each>
                        </documentation>
                    </xsl:for-each>
                </xsl:for-each>
                <xsl:for-each select="cda:component/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.14']">
                    <xsl:apply-templates select="cda:value">
                        <xsl:with-param name="pElementName" select="'timingDuration'" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </action>
        </PlanDefinition>
    </xsl:template>-->
</xsl:stylesheet>
