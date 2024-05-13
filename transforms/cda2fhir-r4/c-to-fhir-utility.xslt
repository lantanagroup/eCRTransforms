<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64" version="2.0" exclude-result-prefixes="lcg cda fhir xs xsi sdtc xhtml b64">

    <xsl:param name="template-profile-mapping-file">../template-profile-mapping.xml</xsl:param>
    <xsl:param name="participant-profile-mapping-file">../participant-profile-mapping.xml</xsl:param>
    <xsl:param name="template-subprofile-mapping-file">../template-subprofile-mapping.xml</xsl:param>
    <xsl:param name="lab-obs-status-mapping-file">../lab-obs-status-mapping.xml</xsl:param>
    <xsl:param name="lab-status-mapping-file">../lab-status-mapping.xml</xsl:param>
    <xsl:param name="code-display-mapping-file">../code-display-mapping.xml</xsl:param>
    <!-- File listing the templates that are suppressed because they are not full resources in FHIR (extensions, components, data elements, etc.) -->
    <xsl:param name="templates-to-suppress-file">../templates-to-suppress.xml</xsl:param>

    <xsl:variable name="template-profile-mapping" select="document($template-profile-mapping-file)/mapping" />
    <xsl:variable name="participant-profile-mapping" select="document($participant-profile-mapping-file)/mapping" />
    <xsl:variable name="template-subprofile-mapping" select="document($template-subprofile-mapping-file)/mapping" />
    <xsl:variable name="lab-status-mapping" select="document($lab-status-mapping-file)/mapping" />
    <xsl:variable name="lab-obs-status-mapping" select="document($lab-obs-status-mapping-file)/mapping" />
    <xsl:variable name="code-display-mapping" select="document($code-display-mapping-file)/mapping" />
    <!-- Variable with the list of all the templates that are suppressed because they are not full resources in FHIR (extensions, components, data elements, etc.) -->
    <xsl:variable name="templates-to-suppress" select="document($templates-to-suppress-file)/templatesToSuppress" />

    <xsl:key name="referenced-acts" match="cda:*[not(cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.122'])]" use="cda:id/@root" />

    <!-- Key to match templates that are suppresed because they are not full resources in FHIR (extension, components, data elements, etc.) -->
    <xsl:key name="templates-to-suppress-key" match="$templates-to-suppress" use="templateToSuppress/@templateIdRoot" />

    <!-- use predefined key that uses a list of templates to suppress in the file templates-to-suppress.xml -->
    <xsl:template match="cda:*[cda:templateId[key('templates-to-suppress-key', @root)]]" mode="bundle-entry" />

    <!-- TEMPLATE: Create the bundle entry -->
    <xsl:template name="create-bundle-entry">
        <!-- MD: do not create entry for Diastolic Blood Pressure, since it has been created
        with systolic blood pressure -->
        <xsl:choose>
            <xsl:when test="not(local-name(.) = 'observation' and ./cda:code/@code = '8462-4' and ./cda:code/@codeSystem = '2.16.840.1.113883.6.1')">
                <entry>
                    <fullUrl value="urn:uuid:{@lcg:uuid}" />
                    <resource>
                        <xsl:apply-templates select="." mode="#default" />
                    </resource>
                </entry>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: act reference -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.122']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:variable name="reference-id" select="cda:id" />

        <xsl:for-each select="key('referenced-acts', $reference-id/@root)">
            <xsl:variable name="vTemplateIdRoot" select="cda:templateId/@root" />
            <!-- Skip creating a reference for a suppressed template -->
            <xsl:if test="empty(key('templates-to-suppress-key', $vTemplateIdRoot))">
                <xsl:comment>
                <xsl:text>Found reference to </xsl:text>
                <xsl:text>&lt;id root=</xsl:text>
                <xsl:value-of select="cda:id/@root" />
                <xsl:if test="cda:id/@extention">
                    <xsl:text> extension=</xsl:text>
                    <xsl:value-of select="cda:id/@extension" />
                </xsl:if>
                <xsl:text>/&gt;</xsl:text>
            </xsl:comment>
                <xsl:choose>
                    <xsl:when test="$reference-id/@extension = cda:id/@extension">
                        <xsl:apply-templates select="." mode="reference">
                            <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="$reference-id[not(@extension)] and cda:id[not(@extension)]">
                        <xsl:apply-templates select="." mode="reference">
                            <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
                        </xsl:apply-templates>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: convert elements to markdown string -->
    <xsl:template match="@* | node()" mode="markdown">
        <!-- TODO: Make this more intelligent -->
        <xsl:choose>
            <xsl:when test="@styleCode = 'Bold'">
                <xsl:text>**</xsl:text>
                <xsl:apply-templates select="*" mode="markdown" />
                <xsl:value-of select="text()" />
                <xsl:text>**</xsl:text>
                <xsl:if test="text()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*" mode="markdown" />
                <xsl:if test="text()">
                    <xsl:value-of select="text()" />
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Serialize XML -->
    <xsl:template match="*" mode="serialize">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()" />
        <xsl:apply-templates select="@*" mode="serialize" />
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:text>&gt;</xsl:text>
                <xsl:apply-templates mode="serialize" />
                <xsl:text>&lt;/</xsl:text>
                <xsl:value-of select="name()" />
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> /&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Catch LCG-specific add-ons that shouldn't be serialized -->
    <xsl:template match="@lcg:uuid | lcg:binary" mode="serialize" />

    <!-- TEMPLATE: Serialize XML -->
    <xsl:template match="@*" mode="serialize">
        <xsl:text> </xsl:text>
        <xsl:value-of select="name()" />
        <xsl:text>="</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>"</xsl:text>
    </xsl:template>

    <!-- TEMPLATE: Serialize XML -->
    <xsl:template match="text()" mode="serialize">
        <xsl:value-of select="." />
    </xsl:template>

    <!-- TEMPLATE: Don't create entries for entry references -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.122']]" mode="bundle-entry" />

    <!-- TEMPLATE: Suppress any unknown clinical statements -->
    <xsl:template match="cda:*[cda:templateId]" mode="bundle-entry" priority="-1">
        <xsl:for-each select="cda:templateId">
            <xsl:message terminate="no">
                <xsl:text>No template match for </xsl:text>
                <xsl:value-of select="@root" />
                <xsl:if test="@extension">
                    <xsl:text>: </xsl:text>
                    <xsl:value-of select="@extension" />
                </xsl:if>
            </xsl:message>

            <xsl:comment>
        <xsl:text>No template match for </xsl:text>
        <xsl:value-of select="@root" />
        <xsl:if test="@extension">
          <xsl:text>: </xsl:text>
          <xsl:value-of select="@extension" />
        </xsl:if>
      </xsl:comment>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: Adds meta tag to profile with the name of the profile to conform to
       Uses the template with mode="template2profile" which uses the file 
       imported at the top of this file with the template-profile-mapping -->
    <xsl:template name="add-meta">
        <xsl:variable name="profiles">
            <xsl:apply-templates select="cda:templateId" mode="template2profile" />
        </xsl:variable>
        <xsl:if test="$profiles/fhir:profile or cda:confidentialityCode[not(@nullFlavor)]">

            <meta>
                <xsl:choose>
                    <xsl:when test="$profiles/fhir:profile">
                        <xsl:apply-templates select="cda:templateId" mode="template2profile" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment>No profiles found for any of the following templates:
                        <xsl:for-each select="cda:templateId">
                            <xsl:variable name="vTemplateURI" select="lcg:fcnGetTemplateURI(.)" />
                            <xsl:value-of select="$vTemplateURI" />
                        </xsl:for-each>
                    </xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- This is R5 code -->
                <!--<xsl:if test="cda:confidentialityCode[not(@nullFlavor)]">
                    <security>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-Confidentiality" />
                        <code value="{cda:confidentialityCode/@code}" />
                    </security>
                </xsl:if>-->
            </meta>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: Uses the template to profile file imported at the top of this file to match template oids with their structureDefinition profile -->
    <xsl:template match="cda:templateId" mode="template2profile">
        <xsl:variable name="vTemplateURI" select="lcg:fcnGetTemplateURI(.)" />
        <xsl:variable name="vCurrentIg">
            <xsl:apply-templates select="/" mode="currentIg" />
        </xsl:variable>

        <!-- If this is eCR or RR don't want to add CCDA-on-FHIR-US-Realm-Header conformance so skip those -->
        <xsl:choose>
            <xsl:when test="$vCurrentIg = 'eICR' or $vCurrentIg = 'RR'">
                <xsl:for-each select="$template-profile-mapping/map[@templateURI = $vTemplateURI][not(contains(@templateURI, '2.16.840.1.113883.10.20.22.1.1'))]">
                    <profile value="{@profileURI}" />
                    <xsl:comment>CDA templateId: <xsl:value-of select="$vTemplateURI" /></xsl:comment>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$template-profile-mapping/map[@templateURI = $vTemplateURI]">
                    <profile value="{@profileURI}" />
                    <xsl:comment>CDA templateId: <xsl:value-of select="$vTemplateURI" /></xsl:comment>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Adds name to "subprofile" (e.g. Observation.component that is mapped from a CDA template) -->
    <xsl:template name="comment-subprofile-name">
        <xsl:variable name="vName">
            <xsl:apply-templates select="cda:templateId" mode="template2subprofile" />
        </xsl:variable>
        <xsl:if test="$vName">
            <xsl:comment>
        <xsl:apply-templates select="cda:templateId" mode="template2subprofile" />
      </xsl:comment>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: Uses the template to profile file imported at the top of this file to match template oids with their "subprofile" name -->
    <xsl:template match="cda:templateId" mode="template2subprofile">
        <xsl:variable name="vTemplateURI" select="lcg:fcnGetTemplateURI(.)" />
        <xsl:for-each select="$template-subprofile-mapping/map[@templateURI = $vTemplateURI]">
            <xsl:value-of select="@subprofileName" />
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: Add meta to participant elements that are profiles in FHIR but not separate templates in CDA -->
    <xsl:template name="add-participant-meta">
        <xsl:variable name="profiles">
            <xsl:apply-templates select="self::node()" mode="participant2profile" />
        </xsl:variable>
        <xsl:if test="$profiles/fhir:profile">
            <meta>
                <xsl:apply-templates select="self::node()" mode="participant2profile" />
            </meta>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: Match the particpants with their profiles to add meta -->
    <xsl:template match="*" mode="participant2profile">
        <!-- Get the current node because we lose context when we iterate through the ClinicalDocument/templateIds -->
        <xsl:variable name="vContext" as="node()" select="." />
        <!-- Could be multiple ClinicalDocument templateIds we need to check -->
        <xsl:for-each select="/cda:ClinicalDocument/cda:templateId">
            <!-- Get our string with templateId for the beginning of the XPath -->
            <xsl:variable name="vClinicalDocument">
                <xsl:choose>
                    <xsl:when test="@extension">
                        <xsl:value-of select="concat('ClinicalDocument[templateId/@root=''', @root, '''][templateId/@extension=''', @extension, ''']/')" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('ClinicalDocument[templateId/@root=''', @root, ''']/')" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- Get the full XPath for this node -->
            <xsl:variable name="vParticipantXPath">
                <xsl:value-of select="concat($vClinicalDocument, lcg:fcnGetXPath($vContext, name($vContext)))" />
            </xsl:variable>
            <!-- Check to see if it exists in our mapping file and if it does get the profile it maps to -->
            <xsl:for-each select="$participant-profile-mapping/map[@participantXPath = $vParticipantXPath]">
                <profile value="{@profileURI}" />
                <xsl:comment>CDA participant: <xsl:value-of select="$vParticipantXPath" /></xsl:comment>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- FUNCTION: to return templateId with root and extension and prefix -->
    <xsl:function name="lcg:fcnGetTemplateURI" as="xs:string">
        <xsl:param name="pTemplateId" />
        <xsl:variable name="vTemplateURI">
            <xsl:text>urn:hl7ii:</xsl:text>
            <xsl:value-of select="$pTemplateId/@root" />
            <xsl:if test="$pTemplateId/@extension">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$pTemplateId/@extension" />
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="$vTemplateURI" />
    </xsl:function>

    <!-- FUNCTION:  to return XPath of the element -->
    <xsl:function name="lcg:fcnGetXPath" as="xs:string">
        <xsl:param name="pNode" as="node()" />
        <xsl:param name="pXPathStr" as="xs:string" />
        <xsl:choose>
            <!-- Go up the tree to ClinicalDocument and exit with everything up to there -->
            <xsl:when test="name($pNode/parent::*) = 'ClinicalDocument'">
                <xsl:value-of select="$pXPathStr" />
            </xsl:when>
            <!-- Otherwise build up XPath reversing up the tree -->
            <xsl:otherwise>
                <xsl:value-of select="lcg:fcnGetXPath($pNode/parent::*, concat(name($pNode/parent::*), '/', $pXPathStr))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- TEMPLATE: Convert OIDs to their uri equivalents - these are stored in mapping file oid-uri-mapping.xml -->
    <xsl:template name="convertOID">
        <xsl:param name="oid" />
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
        <xsl:choose>
            <xsl:when test="$mapping/map[@oid = $oid]">
                <xsl:value-of select="$mapping/map[@oid = $oid][1]/@uri" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="contains($oid, '.')">urn:oid:</xsl:when>
                    <xsl:when test="contains($oid, '-')">urn:uuid:</xsl:when>
                </xsl:choose>
                <xsl:value-of select="$oid" />
                <xsl:message>Warning: Unmapped OID - <xsl:value-of select="$oid" /></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-reference-text">
        <xsl:param name="pTextElement" />
        <xsl:variable name="vTextReference">
            <xsl:value-of select="substring($pTextElement/cda:reference/@value, 2)" />
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$pTextElement/cda:reference">
                <xsl:choose>
                    <xsl:when test="//*[@ID = $vTextReference]/text()">
                        <xsl:value-of select="//*[@ID = $vTextReference]/text()" />
                    </xsl:when>
                    <xsl:when test="//*[@ID = $vTextReference]/../text()">
                        <xsl:value-of select="//*[@ID = $vTextReference]/following-sibling::text()" />
                    </xsl:when>
                    <xsl:when test="//*[@ID = $vTextReference]">
                        <xsl:apply-templates select="//*[@ID = $vTextReference]" mode="serialize" />
                        <!--<xsl:copy-of select="//*[@ID = $vTextReference]" />-->
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pTextElement">
                <xsl:value-of select="$pTextElement" />
            </xsl:when>
        </xsl:choose>

        <!--        <xsl:value-of select="$vText"/>-->
    </xsl:template>

    <xsl:template name="resource-reference">
        <xsl:param name="pTemplateId" />
        <xsl:param name="pElementName">focus</xsl:param>

        <xsl:element name="{$pElementName}">
            <reference value="urn:uuid:{//cda:*[cda:templateId/@root=$pTemplateId/@root]/@lcg:uuid}" />
        </xsl:element>
    </xsl:template>

    <!-- MD: Add encompassingEncounter reference -->
    <xsl:template name="encompassingEncounter-reference">
        <xsl:param name="pElementName">encounter</xsl:param>
        <!-- TODO: handle multiple subjects (record as a group where allowed - needed for HAI) -->
        <xsl:element name="{$pElementName}">
            <reference value="urn:uuid:{/cda:ClinicalDocument/
                cda:componentOf/cda:encompassingEncounter[1]/@lcg:uuid}" />
        </xsl:element>
    </xsl:template>

    <xsl:template name="subject-reference">
        <xsl:param name="pElementName">subject</xsl:param>
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="cda:subject">
                    <reference value="urn:uuid:{cda:subject/@lcg:uuid}" />
                </xsl:when>
                <xsl:when test="ancestor::cda:section[1]/cda:subject">
                    <reference value="urn:uuid:{ancestor::cda:section[1]/cda:subject/@lcg:uuid}" />
                </xsl:when>
                <xsl:otherwise>
                    <reference value="urn:uuid:{/cda:ClinicalDocument/cda:recordTarget[1]/@lcg:uuid}" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template name="author-reference">
        <xsl:param name="pElementName">author</xsl:param>
        <!-- If the resource can take PractitionerRole this will be true, otherwise false -->
        <xsl:param name="pPractitionerRole" as="xs:boolean" select="true()" />
        <!-- TODO: handle multiple authors. May not be legal for all resources.  -->
        <!-- TODO: some resources can't take PractitionerRole, so handle just a Practitioner.   -->
        <!-- SG: Updated to handle no author (default to encompassingEncounter/responsibleParty/assignedEntity and
         if there isn't one of those either, don't create element
         Updating for resources that can't take PractitionerRole (testing for pPractitionerRole) -->
        <xsl:comment>Author reference</xsl:comment>

        <xsl:choose>
            <!-- direct performer/author - either contained in the template or in the containing act or organizer -->
            <xsl:when test="
                    $pPractitionerRole = true() and (cda:performer or
                    cda:author or
                    ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:performer or
                    ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:author or
                    ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:performer or
                    ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:author)">
                <xsl:for-each select="cda:performer">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:performer">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:performer">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:author">
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName" select="$pElementName" />
                    </xsl:apply-templates>
                    <!--<xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>-->
                </xsl:for-each>
            </xsl:when>
            <!-- when there is nothing above, start looking further afield - check the containing section/author -->
            <xsl:when test="$pPractitionerRole = true() and ancestor::cda:section/cda:author">
                <xsl:for-each select="ancestor::cda:section/cda:author">
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName" select="$pElementName" />
                    </xsl:apply-templates>
                    <!--<xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>-->
                </xsl:for-each>
            </xsl:when>
            <!-- when there is no section author - look at the ClinicalDocument/author -->
            <xsl:when test="$pPractitionerRole = true() and /cda:ClinicalDocument/cda:author">
                <xsl:for-each select="/cda:ClinicalDocument/cda:author">
                    <xsl:apply-templates select="." mode="rename-reference-participant">
                        <xsl:with-param name="pElementName" select="$pElementName" />
                    </xsl:apply-templates>
                    <!--<xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>-->
                </xsl:for-each>
            </xsl:when>
            <!-- when there is none of the above authors - look at the encompassingEncounter/responsibleParty -->
            <xsl:when test="$pPractitionerRole = true() and /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty/cda:assignedEntity">
                <xsl:for-each select="/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty[cda:assignedEntity]">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <!-- when PractitionerRole isn't allowed -->
            <xsl:when
                test="$pPractitionerRole = false() and (/cda:ClinicalDocument/cda:author/cda:assignedAuthor/cda:assignedPerson or /cda:ClinicalDocument/cda:author/cda:assignedAuthor/cda:assignedAuthoringDevice)">
                <xsl:for-each select="/cda:ClinicalDocument/cda:author/cda:assignedAuthor[cda:assignedPerson]">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedPerson/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="/cda:ClinicalDocument/cda:author/cda:assignedAuthor[cda:assignedAuthoringDevice]">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthoringDevice/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <xsl:when
                test="$pPractitionerRole = false() and (/cda:ClinicalDocument/cda:author/cda:assignedAuthor/cda:assignedPerson or /cda:ClinicalDocument/cda:author/cda:assignedAuthor/cda:assignedAuthoringDevice)">
                <xsl:for-each select="/cda:ClinicalDocument/cda:author/cda:assignedAuthor[cda:assignedPerson]">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedPerson/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="/cda:ClinicalDocument/cda:author/cda:assignedAuthor[cda:assignedAuthoringDevice]">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthoringDevice/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>

            <xsl:otherwise>
                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                    <valueCode value="unknown" />
                </extension>
                <xsl:comment>No author reference found</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="performer-reference">
        <xsl:param name="pElementName">actor</xsl:param>
        <!-- TODO: handle multiple authors. May not be legal for all resources.  -->
        <!-- SG: Updated to handle no performer (default to encompassingEncounter/responsibleParty/assignedEntity and
         if there isn't one of those either, don't create element-->
        <xsl:if
            test="cda:performer/cda:assignedEntity or ancestor::cda:section[1]/cda:performer/cda:assignedEntity or /cda:ClinicalDocument/cda:documentation/cda:serviceEvent/cda:performer/cda:assignedEntity or /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty/cda:assignedEntity">
            <xsl:element name="{$pElementName}">
                <xsl:choose>
                    <xsl:when test="cda:performer/cda:assignedEntity">
                        <!-- TODO: test to see author.id is the same as an ancestor author, if so use that URN -->
                        <reference value="urn:uuid:{cda:performer[1]/cda:assignedEntity/@lcg:uuid}" />
                    </xsl:when>
                    <xsl:when test="ancestor::cda:section[1]/cda:performer/cda:assignedEntity">
                        <reference value="urn:uuid:{ancestor::cda:section[1]/cda:performer/cda:assignedEntity/@lcg:uuid}" />
                    </xsl:when>
                    <xsl:when test="/cda:ClinicalDocument/cda:documentation/cda:serviceEvent/cda:performer/cda:assignedEntity">
                        <reference value="urn:uuid:{/cda:ClinicalDocument/cda:documentation/cda:serviceEvent/cda:performer/cda:assignedEntity/@lcg:uuid}" />
                    </xsl:when>
                    <xsl:when test="/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty/cda:assignedEntity">
                        <reference value="urn:uuid:{/cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty/cda:assignedEntity/@lcg:uuid}" />
                    </xsl:when>
                </xsl:choose>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:observation/cda:referenceRange">
        <!-- Rule: must have at least a low or a high or a text -->
        <referenceRange>
            <xsl:for-each select="cda:observationRange">
                <xsl:for-each select="cda:value">
                    <xsl:choose>
                        <xsl:when test="@nullFlavor">
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </xsl:when>
                        <xsl:when test="@xsi:type = 'IVL_PQ'">
                            <xsl:apply-templates select="cda:low" mode="range" />
                            <xsl:apply-templates select="cda:high" mode="range" />
                        </xsl:when>
                        <!-- SG 2023-06-04: Remove terminate="yes" - whole transform doesn't need to stop because the reference range type can't be dealt with 
                             (rule is that must have at least a low or a high or a text)
                             and if it's a string, moving it down to text -->
                        <xsl:otherwise>
                            <xsl:message> Unsupported observation reference range type: <xsl:value-of select="@xsi:type" />
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <!-- Put whatever is in text into a variable -->
                <xsl:variable name="vText">
                    <xsl:value-of select="cda:text" />
                </xsl:variable>
                <!-- Put whatever is in value with xsi:type = ST into a variable -->
                <xsl:variable name="vValueST">
                    <xsl:choose>
                        <xsl:when test="cda:value/@xsi:type = 'ST'">
                            <xsl:value-of select="cda:value[@xsi:type = 'ST']" />
                        </xsl:when>
                        <xsl:otherwise />
                    </xsl:choose>
                </xsl:variable>

                <!-- If there is no value in either, AND there was no low or high, then put a note into text to pass FHIR validation
                     If there is no value in either, there is no text. 
                     If they are different concatenate, if they are the same just use text -->
                <xsl:choose>
                    <xsl:when test="not(cda:value/@xsi:type = 'IVL_PQ') and not(cda:value/cda:low) and not(cda:value/cda:high) and not($vText/string()) and not($vValueST/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="'No reference range supplied'" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="not($vText/string()) and not($vValueST/string())" />
                    <xsl:when test="not($vText/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vValueST" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="not($vValueST/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vText" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="$vText = $vValueST">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vText" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="concat($vText, '; ', $vValueST)" />
                            </xsl:attribute>
                        </text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </referenceRange>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.80']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <!-- Remove Encounter Diagnosis wrappers, since maps to Condition.category -->
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="reference">
                <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.80']]" mode="bundle-entry">
        <!-- Remove Encounter Diagnosis wrappers, since maps to Condition.category -->
        <xsl:comment>Removed Encounter diagnosis wrapper</xsl:comment>
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:*[@nullFlavor]" mode="bundle-entry">
        <!-- Suppress -->
    </xsl:template>

    <!-- TEMPLATE: Uses the lab-status-mapping file imported at the top of this file to match cda lab status with fhir equivalents -->
    <xsl:template match="cda:value" mode="map-lab-status">
        <xsl:param name="pElementName" select="'status'" />
        <xsl:variable name="vLabStatus" select="@code" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$lab-status-mapping/map[@cdaLabStatus = $vLabStatus]">
                    <xsl:attribute name="value" select="$lab-status-mapping/map[@cdaLabStatus = $vLabStatus]/@fhirLabStatus" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value" select="'final'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- TEMPLATE: Map Lab Result Status values to Observation.status values -->
    <!--<xsl:template match="cda:value" mode="map-lab-status">
    <xsl:choose>
      <!-\- Order received; specimen not yet received -\->
      <xsl:when test="@code = 'O'">
        <status value="registered" />
      </xsl:when>
      <!-\- No results available; specimen received procedure incomplete -\->
      <xsl:when test="@code = 'I'">
        <status value="registered" />
      </xsl:when>
      <!-\- No results available; procedure scheduled, but not done -\->
      <xsl:when test="@code = 'S'">
        <status value="registered" />
      </xsl:when>
      <!-\- Some, but not all, results available -\->
      <xsl:when test="@code = 'A'">
        <status value="preliminary" />
      </xsl:when>
      <!-\- Preliminary: A verified early result is available, final results not yet obtained -\->
      <xsl:when test="@code = 'P'">
        <status value="preliminary" />
      </xsl:when>
      <!-\- Correction to results (Corrected result and order is final) -\->
      <xsl:when test="@code = 'C'">
        <status value="final" />
      </xsl:when>
      <!-\- Results stored; not yet verified -\->
      <xsl:when test="@code = 'R'">
        <status value="preliminary" />
      </xsl:when>
      <!-\- Final results; results stored and verified. Can only be changed with a corrected result. -\->
      <xsl:when test="@code = 'F'">
        <status value="final" />
      </xsl:when>
      <!-\- No results available; Order canceled. -\->
      <xsl:when test="@code = 'X'">
        <status value="cancelled" />
      </xsl:when>
      <!-\- Corrected result but order is not final -\->
      <xsl:when test="@code = 'M'">
        <status value="corrected" />
      </xsl:when>
      <xsl:otherwise>
        <status value="final" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
-->

    <!-- TEMPLATE: Uses the lab-obs-status-mapping file imported at the top of this file to match cda lab obs status with fhir equivalents -->
    <xsl:template match="cda:value" mode="map-lab-obs-status">
        <xsl:param name="pElementName" select="'status'" />
        <xsl:variable name="vStatus" select="@code" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$lab-obs-status-mapping/map[@cdaLabObsStatus = $vStatus]">
                    <xsl:attribute name="value" select="$lab-obs-status-mapping/map[@cdaLabObsStatus = $vStatus]/@fhirLabObsStatus" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value" select="'final'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- TEMPLATE: Map Lab Result Observation Status values to Observation.status values -->
    <!--<xsl:template match="cda:value" mode="map-lab-obs-status">
    <xsl:choose>
      <!-\- Amended based on adjustments provided by the Placer (Physician) regarding patient demographics (such as age and/or gender or other patient specific information -\->
      <xsl:when test="@code = 'A'">
        <status value="amended" />
      </xsl:when>
      <!-\- Appended Report - Final results reviewed and further information provided for clarity without change to the original result values. -\->
      <xsl:when test="@code = 'B'">
        <status value="final" />
      </xsl:when>
      <!-\-Record coming over is a correction and thus replaces a final result -\->
      <xsl:when test="@code = 'C'">
        <status value="final" />
      </xsl:when>
      <!-\- Final results -\->
      <xsl:when test="@code = 'F'">
        <status value="final" />
      </xsl:when>
      <!-\- Specimen in lab; results pending -\->
      <xsl:when test="@code = 'I'">
        <status value="registered" />
      </xsl:when>
      <!-\- Order detail description only (no result) -\->
      <xsl:when test="@code = 'O'">
        <status value="registered" />
      </xsl:when>
      <!-\- Preliminary results -\->
      <xsl:when test="@code = 'P'">
        <status value="preliminary" />
      </xsl:when>
      <!-\- Results entered - not verified -\->
      <xsl:when test="@code = 'R'">
        <status value="preliminary" />
      </xsl:when>
      <!-\- Results status change to final without retransmitting results already sent as 'preliminary.'  E.g., radiology changes status from preliminary to final -\->
      <xsl:when test="@code = 'U'">
        <status value="final" />
      </xsl:when>
      <!-\- Verified - Final results reviewed and confirmed to be correct, no change to result value, normal range or abnormal flag -\->
      <xsl:when test="@code = 'V'">
        <status value="final" />
      </xsl:when>
      <!-\- Post original as wrong, e.g., transmitted for wrong patient -\->
      <xsl:when test="@code = 'W'">
        <status value="entered-in-error" />
      </xsl:when>
      <!-\- Results cannot be obtained for this observation -\->
      <xsl:when test="@code = 'X'">
        <status value="cancelled" />
      </xsl:when>
      <xsl:otherwise>
        <status value="final" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
-->
    <!-- FUNCTION: Map nullFlavor values -->

    <xsl:function name="lcg:fcnMapNullFlavor" as="xs:string">
        <xsl:param name="pNullFlavorValue" as="xs:string" />
        <xsl:choose>
            <xsl:when test="$pNullFlavorValue = 'ASKU'">Asked but unknown</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'MSK'">Masked</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'NINF'">Negative infinity</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'NI'">NoInformation</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'NA'">Not applicable</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'NASK'">Not asked</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'OTH'">Other</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'PINF'">Positive</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'QS'">Sufficient</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'NAV'">Temporarily</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'TRC'">Trace</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'UNC'">Un-encoded</xsl:when>
            <xsl:when test="$pNullFlavorValue = 'UNK'">Unknown</xsl:when>
            <xsl:otherwise>Invalid nullFlavor</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Returns full data absent reason extension -->
    <xsl:template match="@nullFlavor" mode="data-absent-reason-extension">
        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
            <xsl:element name="valueCode">
                <xsl:attribute name="value">
                    <xsl:choose>
                        <xsl:when test=". = 'UNK'">unknown</xsl:when>
                        <xsl:when test=". = 'NA'">not-applicable</xsl:when>
                        <xsl:when test=". = 'MSK'">masked</xsl:when>
                        <xsl:when test=". = 'NINF'">negative-infinity</xsl:when>
                        <xsl:when test=". = 'PINF'">positive-infinity</xsl:when>
                        <xsl:when test=". = 'ASKU'">asked-unknown</xsl:when>
                        <xsl:when test=". = 'NAV'">temp-unknown</xsl:when>
                        <xsl:when test=". = 'NASK'">not-asked</xsl:when>
                        <xsl:when test=". = 'NI'">unknown</xsl:when>
                        <xsl:otherwise>unknown</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:element>
        </extension>
    </xsl:template>

    <!-- This is for Observation.dataAbsentReason only  -->
    <xsl:template match="@nullFlavor" mode="data-absent-reason">
        <dataAbsentReason>
            <coding>
                <system value="http://hl7.org/fhir/ValueSet/data-absent-reason" />
                <xsl:element name="code">
                    <xsl:attribute name="value">
                        <xsl:choose>
                            <xsl:when test=". = 'UNK'">unknown</xsl:when>
                            <xsl:when test=". = 'NA'">not-applicable</xsl:when>
                            <xsl:when test=". = 'MSK'">masked</xsl:when>
                            <xsl:when test=". = 'NINF'">negative-infinity</xsl:when>
                            <xsl:when test=". = 'PINF'">positive-infinity</xsl:when>
                            <xsl:when test=". = 'ASKU'">asked-unknown</xsl:when>
                            <xsl:when test=". = 'NAV'">temp-unknown</xsl:when>
                            <xsl:when test=". = 'NASK'">not-asked</xsl:when>
                            <xsl:when test=". = 'NI'">unknown</xsl:when>
                            <xsl:otherwise>unknown</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </xsl:element>
            </coding>
        </dataAbsentReason>
    </xsl:template>

    <!-- TEMPLATE: Returns a referenced participant -->
    <xsl:template match="cda:author | cda:performer" mode="rename-reference-participant">
        <xsl:param name="pElementName" />
        <xsl:choose>
            <xsl:when test="cda:*/cda:assignedPerson">
                <xsl:element name="{$pElementName}">
                    <xsl:element name="reference">
                        <xsl:attribute name="value">urn:uuid:<xsl:value-of select="cda:*[cda:assignedPerson]/@lcg:uuid" /></xsl:attribute>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:*/cda:assignedAuthoringDevice">
                <xsl:element name="{$pElementName}">
                    <xsl:element name="reference">
                        <xsl:attribute name="value">urn:uuid:<xsl:value-of select="cda:*/cda:assignedAuthoringDevice/@lcg:uuid" /></xsl:attribute>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:*/cda:representedOrganization">
                <xsl:element name="{$pElementName}">
                    <xsl:element name="reference">
                        <xsl:attribute name="value">urn:uuid:<xsl:value-of select="cda:*/cda:representedOrganization/@lcg:uuid" /></xsl:attribute>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: get-closest-author: work up hierarchy and get closest author for resources that require an author (or whatever name) -->
    <xsl:template name="get-closest-author">
        <xsl:choose>
            <xsl:when test="cda:author">
                <xsl:copy-of select="cda:author" />
            </xsl:when>
            <!-- when there is nothing above, start looking further afield - check the containing section/author -->
            <xsl:when test="ancestor::cda:section/cda:author">
                <xsl:copy-of select="ancestor::cda:section/cda:author" />
            </xsl:when>
            <!-- when there is no section author - look at the ClinicalDocument/author -->
            <xsl:when test="/cda:ClinicalDocument/cda:author">
                <xsl:copy-of select="/cda:ClinicalDocument/cda:author" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-author-uuid">
        <xsl:param name="pAuthor" />
        <xsl:choose>
            <!-- PractitionerRole -->
            <xsl:when test="$pAuthor/cda:assignedAuthor/cda:assignedPerson">
                <xsl:value-of select="$pAuthor/cda:assignedAuthor/@lcg:uuid" />
            </xsl:when>
            <!-- Organization -->
            <xsl:when test="$pAuthor/cda:assignedAuthor/cda:assignedOrganization">
                <xsl:value-of select="$pAuthor/cda:assignedAuthor/cda:assignedOrganization/@lcg:uuid" />
            </xsl:when>
            <!-- Device -->
            <xsl:when test="$pAuthor/cda:assignedAuthor/cda:assignedAuthoringDevice">
                <xsl:value-of select="$pAuthor/cda:assignedAuthor/cda:assignedAuthoringDevice/@lcg:uuid" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pAuthor/cda:assignedAuthor/@lcg:uuid" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:ClinicalDocument" mode="currentIg">
        <xsl:choose>
            <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2'">
                <xsl:value-of select="'eICR'" />
            </xsl:when>
            <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2'">
                <xsl:value-of select="'RR'" />
            </xsl:when>
            <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.2'">
                <xsl:value-of select="'DentalConsultNote'" />
            </xsl:when>
            <xsl:when test="cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.1'">
                <xsl:value-of select="'DentalReferalNote'" />
            </xsl:when>
            <!-- Summarization of Episode Note -->
            <xsl:when test="
                    cda:templateId/@root = '2.16.840.1.113883.10.20.22.1.1'
                    or cda:templateId/@root = '2.16.840.1.113883.10.20.22.1.2'">
                <xsl:value-of select="'SOEN'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'NA'" />
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-profile-for-ig">
        <xsl:param name="pIg" />
        <xsl:param name="pResource" />
        <xsl:choose>
            <xsl:when test="$pIg = 'eICR'">
                <xsl:choose>
                    <xsl:when test="$pResource = 'Condition'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-condition'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Encounter'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-encounter'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Patient'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-patient'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'PractitionerRole'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-practitionerrole'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'ServiceRequest'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-servicerequest'" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pIg = 'RR'">
                <xsl:choose>
                    <xsl:when test="$pResource = 'Encounter'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-encounter'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Patient'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-patient'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'PractitionerRole'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-practitionerrole'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'ServiceRequest'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-servicerequest'" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$pIg = 'DentalConsultNote' or $pIg = 'DentalReferalNote'">
                <xsl:choose>
                    <xsl:when test="$pResource = 'Condition'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Encounter'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Patient'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'PractitionerRole'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'ServiceRequest'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/dental-data-exchange/dental-servicerequest'" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$pResource = 'Condition'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Encounter'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'Patient'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'" />
                    </xsl:when>
                    <xsl:when test="$pResource = 'PractitionerRole'">
                        <xsl:value-of select="'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="." mode="base64">
        <xsl:call-template name="b64:encode">
            <xsl:with-param name="asciiString" select="text()" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="get-current-ig">
        <xsl:choose>
            <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
            <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-substring-after-last">
        <xsl:param name="pString" />
        <xsl:param name="pDelimiter" />
        <xsl:choose>
            <xsl:when test="contains($pString, $pDelimiter)">
                <xsl:call-template name="get-substring-after-last">
                    <xsl:with-param name="pString" select="substring-after($pString, $pDelimiter)" />
                    <xsl:with-param name="pDelimiter" select="$pDelimiter" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pString" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="breadcrumb-comment">
        <xsl:comment>
            <xsl:call-template name="breadcrumb-path-walker" />
        </xsl:comment>
    </xsl:template>

    <xsl:template name="breadcrumb-path-walker">
        <xsl:for-each select="parent::cda:*">
            <xsl:call-template name="breadcrumb-path-walker" />
        </xsl:for-each>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="local-name(.)" />
        <xsl:for-each select="cda:id">
            <xsl:text>[cda:id</xsl:text>
            <xsl:if test="@root">
                <xsl:text>[@root="</xsl:text>
                <xsl:value-of select="@root" />
                <xsl:text>"]</xsl:text>
            </xsl:if>
            <xsl:if test="@extension">
                <xsl:text>[@extension="</xsl:text>
                <xsl:value-of select="@extension" />
                <xsl:text>"]</xsl:text>
            </xsl:if>
            <xsl:text>]</xsl:text>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
