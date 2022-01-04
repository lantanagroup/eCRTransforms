<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="cda2fhir-DocumentReference.xslt" />
    <xsl:import href="cda2fhir-Extension.xslt" />
    <xsl:import href="cda2fhir-Narrative.xslt" />
    <xsl:import href="c-to-fhir-utility.xslt" />

    <xsl:output indent="yes" />

    <xsl:template match="cda:effectiveTime" mode="communication">
        <sent value="{lcg:cdaTS2date(@value)}" />
    </xsl:template>

    <!-- Add Communication for Instruction template -->
    <!-- Want to exclude Reportability Response Summary and Subject from this transform -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]">
        <Communication>
            <status>
                <xsl:attribute name="value">
                    <xsl:value-of select="cda:statusCode/@code" />
                </xsl:attribute>
            </status>
            <xsl:call-template name="subject-reference" />
            <xsl:call-template name="encompassingEncounter-reference" />

            <xsl:for-each select="cda:entryRelationship">
                <xsl:choose>
                    <xsl:when test="cda:act/cda:participant[@typeCode = 'AUT']">
                        <!-- MD: need to check the present of effectiveTime to prevent error -->
                        <xsl:choose>
                            <xsl:when test="cda:act/cda:effectiveTime">
                                <sent value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
                            </xsl:when>
                        </xsl:choose>
                        
                    </xsl:when>
                    <xsl:when test="cda:act/cda:participant[@typeCode = 'IRCP']">
                        <xsl:choose>
                            <!-- MD: need to check the present of effectiveTime to prevent error -->
                            <xsl:when test="cda:act/cda:effectiveTime">
                                <received value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
                            </xsl:when>
                        </xsl:choose>
                       
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName" select="'recipient'" />
            </xsl:call-template>

            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName" select="'sender'" />
            </xsl:call-template>
            
            <xsl:if test="cda:text">
                <payload>
                    <contentString>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:text" />
                        </xsl:attribute>
                    </contentString>
                </payload>
            </xsl:if>

        </Communication>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.141']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
    </xsl:template>

    <!-- Communication: cda Handoff Communication Participants template -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.141']]">
        <Communication xmlns="http://hl7.org/fhir">
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id" />
            <status value="{cda:statusCode/@code}" />
            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime" mode="communication" />
            <xsl:for-each select="cda:participant">
                <recipient>
                    <xsl:apply-templates select="cda:participantRole" mode="reference" />
                    <!--<reference value="urn:uuid:{@lcg:uuid}"/>-->
                </recipient>
            </xsl:for-each>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">sender</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
            </xsl:apply-templates>
        </Communication>
    </xsl:template>

    <!--
        ##############################################
        RR Templates
        ##############################################
    -->

    <!-- No longer relevant - Communication has been replaced with Composition for RR -->
    <!-- Match Reportability Response Document (RR) (bundle-entry) -->
    <!--<xsl:template match="cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />

    <xsl:apply-templates select="cda:recordTarget" mode="bundle-entry" />
    <xsl:apply-templates select="cda:componentOf/cda:encompassingEncounter" mode="bundle-entry" />
    <xsl:apply-templates select="cda:author" mode="bundle-entry" />
    <xsl:apply-templates select="cda:custodian" mode="bundle-entry" />
    <xsl:apply-templates select="cda:legalAuthenticator" mode="bundle-entry" />
    <xsl:apply-templates select="cda:authenticator" mode="bundle-entry" />
    <xsl:apply-templates select="cda:participant" mode="bundle-entry" />
    <xsl:apply-templates select="cda:documentationOf/cda:serviceEvent" mode="bundle-entry" />
<!-\-    <xsl:apply-templates select="cda:informationRecipient/cda:intendedRecipient/cda:receivedOrganization" mode="bundle-entry" />-\->
    <xsl:apply-templates select="cda:informationRecipient/cda:intendedRecipient" mode="bundle-entry" />
  </xsl:template>-->
    
    <!-- No longer relevant - Communication has been replaced with Composition for RR -->
    <!-- (RR) Reportability Response Document -> fhir:Communication -->
    <!--<xsl:template match="cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">
      <!-\- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -\->
      <xsl:variable name="vCurrentIg">
          <xsl:choose>
              <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
              <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
              <xsl:otherwise>NA</xsl:otherwise>
          </xsl:choose>
      </xsl:variable>

    <Communication xmlns="http://hl7.org/fhir">
      <!-\- Generates an id that is unique for the node. It will always be the same for the same id. -\->
      <id value="{concat($vCurrentIg, '-communication-', generate-id(cda:id))}" />
      <xsl:call-template name="add-meta" />
      
      <text>
        <status value="generated" />
        <xsl:choose>
          <xsl:when test="cda:languageCode/@code">
            <div xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
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
      
      <!-\- Reportability Response Priority -> fhir:extension rr-priority-extension -\->
      <xsl:apply-templates select="//cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.30']" mode="extension" />

      <!-\- fhir:extension relates-to-extension -\->
      <xsl:apply-templates select="." mode="extension" />

      <!-\- cda:id/@lcg:uuid -> Globally unique identifier for this Communication -\->
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
      <identifier>
        <system value="urn:ietf:rfc:3986" />
        <value value="urn:uuid:{$newSetIdUUID}" />
      </identifier>

      <!-\- fhir:status -\->
      <status value="completed" />

      <!-\- cda:code -> fhir:category -\->
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'category'" />
      </xsl:apply-templates>

      <!-\- cda:recordTarget -> fhir:subject -\->
      <subject>
        <reference value="urn:uuid:{cda:recordTarget/@lcg:uuid}" />
      </subject>

      <!-\- Reportability Response Subject -> fhir:topic -\->
      <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.7']">
        <topic>
          <text value="{concat('Subject: ',cda:text)}" />
        </topic>
      </xsl:for-each>

      <!-\- cda:encompassingEncounter -> fhir:encounter -\->
      <xsl:if test="cda:componentOf/cda:encompassingEncounter">
        <encounter>
          <reference value="urn:uuid:{cda:componentOf/cda:encompassingEncounter/@lcg:uuid}" />
        </encounter>
      </xsl:if>

      <!-\- cda:effectiveTime -> fhir:sent -\->
      <sent>
        <xsl:attribute name="value">
          <xsl:value-of select="lcg:cdaTS2date(cda:effectiveTime/@value)" />
        </xsl:attribute>
      </sent>

      <!-\- cda:informationRecipient -> fhir:recipient -\->
      <xsl:for-each select="cda:informationRecipient/cda:intendedRecipient">
        <recipient>
          <reference value="urn:uuid:{@lcg:uuid}" />
        </recipient>
      </xsl:for-each>

      <!-\- cda:author -> fhir:sender -\->
      <sender>
        <xsl:choose>
          <xsl:when test="cda:author/cda:assignedAuthor/cda:assignedAuthoringDevice">
            <reference value="urn:uuid:{cda:author/cda:assignedAuthor/cda:assignedAuthoringDevice/@lcg:uuid}" />
<!-\-            <reference value="urn:uuid:{cda:author/cda:assignedAuthor/@lcg:uuid}" />-\->
          </xsl:when>
          <xsl:when test="cda:author/cda:assignedAuthor/cda:assignedPerson">
<!-\-            <reference value="urn:uuid:{cda:author/cda:assignedAuthor/cda:assignedPerson/@lcg:uuid}" />-\->
            <reference value="urn:uuid:{cda:author/cda:assignedAuthor/@lcg:uuid}" />
          </xsl:when>
        </xsl:choose>
      </sender>

      <!-\- (RR) Reportability Response Summary -> fhir:payload -\->
      <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.8']">
        <payload id="reportability-response-summary">
          <xsl:variable name="vApos">'</xsl:variable>
          <xsl:variable name="vQuot">"</xsl:variable>
          <contentString value="{replace(cda:text/text(),$vQuot,$vApos)}" />
        </payload>
      </xsl:for-each>

      <!-\- (RR) Electronic Initial Case Report Section -> fhir:payload -\->
      <xsl:apply-templates select="cda:component/cda:structuredBody/cda:component/cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.2.3']" mode="communication" />

      <!-\- (RR) Relevant Reportable Condition Information -> fhir:payload  -\->
      <!-\- There will only ever be one of those organizers. It needs to be Reportability Information Organizer - there is a 1 to 1 
           relationship between the Reportability Information Organizer and the PlanDefinition (condition/PHA pair) - however
           the condition is contained in the Relevant Reportable Condition Observation (which contains the Organizer) -\->
      <xsl:for-each select="//cda:organizer[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.13']">
        <payload id="relevant-reportable-condition">
          <contentReference>
            <reference value="urn:uuid:{@lcg:uuid}" />
          </contentReference>
        </payload>
      </xsl:for-each>
    </Communication>
  </xsl:template>
  -->
    
    <!-- No longer relevant - Communication has been replaced with Composition for RR -->
    <!-- Electronic Initial Case Report Section -> fhir:payload eicr information -->
    <!--<xsl:template match="cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.2.3']" mode="communication">
        <!-\- Received eICR Information -> fhir:payload -\->
        <xsl:if test="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']/cda:reference/cda:externalDocument/cda:id">
            <payload id="eicr-information">
                <extension id="eicr-processing-status" url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-extension">
                    <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.29']">
                        <extension url="eICRProcessingStatus">
                            <valueReference>
                                <reference value="urn:uuid:{@lcg:uuid}" />
                            </valueReference>
                        </extension>
                        <!-\- eICR Validation Output -> fhir:extension -\->
                        <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.33']/cda:value">
                            <extension url="eICRValidationOutput">
                                <xsl:choose>
                                    <xsl:when test="@mediaType = 'text/xhtml'">
                                        <xsl:variable name="vValidationOutputSerialized">
                                            <xsl:apply-templates select="xhtml:html" mode="serialize" />
                                        </xsl:variable>
                                        <!-\- Not sure whether this should be a string or markdown -\->
                                        <valueString value="{$vValidationOutputSerialized}" />
                                    </xsl:when>
                                    <xsl:otherwise />
                                </xsl:choose>
                            </extension>
                        </xsl:for-each>
                    </xsl:for-each>
                </extension>

                <!-\- Manually Initiated eICR -> fhir: extension rr-initiation-type-extension-\->
                <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.22']">
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension">
                        <xsl:apply-templates select="cda:code">
                            <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                        </xsl:apply-templates>
                    </extension>
                </xsl:for-each>

                <!-\- Received eICR Information -> fhir:extension rr-eicr-receipt-time-extension -\->
                <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']">
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-receipt-time-extension">
                        <valueDateTime>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:effectiveTime/@value)" />
                            </xsl:attribute>
                        </valueDateTime>
                    </extension>
                </xsl:for-each>

                <!-\- Received eICR Information -> fhir:contentReference -\->
                <xsl:for-each select="cda:entry/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']">
                    <contentReference>
                        <xsl:apply-templates select="cda:reference/cda:externalDocument/cda:id" />
                        <xsl:for-each select="cda:text">
                            <xsl:variable name="vApos">'</xsl:variable>
                            <xsl:variable name="vQuot">"</xsl:variable>
                            <display value="{replace(text(),$vQuot,$vApos)}" />
                        </xsl:for-each>
                    </contentReference>
                </xsl:for-each>
            </payload>
        </xsl:if>
    </xsl:template>-->

</xsl:stylesheet>
