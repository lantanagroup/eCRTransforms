<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64" version="2.0" exclude-result-prefixes="lcg cda fhir xs xsi sdtc xhtml b64">

    <xsl:include href="../base64.xsl" />

    <xsl:param name="template-profile-mapping-file">../template-profile-mapping.xml</xsl:param>
    <xsl:param name="participant-profile-mapping-file">../participant-profile-mapping.xml</xsl:param>
    <xsl:param name="template-subprofile-mapping-file">../template-subprofile-mapping.xml</xsl:param>
    <xsl:param name="lab-obs-status-mapping-file">../lab-obs-status-mapping.xml</xsl:param>
    <xsl:param name="lab-status-mapping-file">../lab-status-mapping.xml</xsl:param>
    <xsl:param name="code-display-mapping-file">../code-display-mapping.xml</xsl:param>

    <xsl:variable name="template-profile-mapping" select="document($template-profile-mapping-file)/mapping" />
    <xsl:variable name="participant-profile-mapping" select="document($participant-profile-mapping-file)/mapping" />
    <xsl:variable name="template-subprofile-mapping" select="document($template-subprofile-mapping-file)/mapping" />
    <xsl:variable name="lab-status-mapping" select="document($lab-status-mapping-file)/mapping" />
    <xsl:variable name="lab-obs-status-mapping" select="document($lab-obs-status-mapping-file)/mapping" />
    <xsl:variable name="code-display-mapping" select="document($code-display-mapping-file)/mapping" />

    <xsl:key name="referenced-acts" match="cda:*[not(cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.122'])]" use="cda:id/@root" />

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
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>

                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.2']">DentalConsultNote</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.1']">DentalReferalNote</xsl:when>

                <xsl:otherwise>NA</xsl:otherwise>
            </xsl:choose>
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

    <!-- FUNCTION:  to return date part of a CDA TS -->
    <xsl:function name="lcg:dateFromcdaTS" as="xs:string">
        <!-- Just get the date part, ignoring any time data -->
        <xsl:param name="cdaTS" as="xs:string" />

        <xsl:variable name="date" as="xs:string">
            <xsl:choose>
                <xsl:when test="string-length($cdaTS) > 6">
                    <xsl:value-of select="string-join((substring($cdaTS, 1, 4), substring($cdaTS, 5, 2), substring($cdaTS, 7, 2)), '-')" />
                </xsl:when>
                <xsl:when test="string-length($cdaTS) > 4">
                    <xsl:value-of select="string-join((substring($cdaTS, 1, 4), substring($cdaTS, 5, 2)), '-')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring($cdaTS, 1, 4)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$date" />
    </xsl:function>

    <!-- FUNCTION:  to convert CDA TS to FHIR date -->
    <xsl:function name="lcg:cdaTS2date" as="xs:string">
        <!-- the FHIR specification allows ignoring seconds, but the FHIR XSD does not -->
        <!-- set seconds to 0 for simplicity -->
        <!-- SG 20191203 - Updating so that if seconds are in the CDA time they are included in the FHIR time -->
        <!-- Make sure that timestame is the correct length - can be YYYYMMDD (8), YYYYMMDDHHMM (12), YYYYMMDDHHMMSS YYYYMMDDHHMMSS.UUUU[+|-ZZzz] -->
        <xsl:param name="cdaTS" as="xs:string" />

        <xsl:variable name="date" as="xs:string" select="lcg:dateFromcdaTS($cdaTS)" />
        <!-- Get a seconds value if there is one -->
        <xsl:variable name="vSeconds">
            <xsl:choose>
                <xsl:when test="substring($cdaTS, 13, 6) and matches(substring($cdaTS, 13, 6), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 6))" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 5) and matches(substring($cdaTS, 13, 5), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 5), '0')" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 4) and matches(substring($cdaTS, 13, 4), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 4), '00')" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 2) and not(matches(substring($cdaTS, 13, 2), '[-+]'))">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 2), '.000')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="':00.000'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message>Trying to convert timestamp: <xsl:value-of select="$cdaTS" /></xsl:message>
        <xsl:choose>
            <!-- If there is a + or - this has a TZ -->
            <xsl:when test="matches($cdaTS, '[-+]')">
                <xsl:variable name="time" select="concat(substring($cdaTS, 9, 2), ':', substring($cdaTS, 11, 2), $vSeconds)" as="xs:string" />
                <xsl:variable name="timezone" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="contains($cdaTS, '-')">
                            <xsl:sequence select="concat('-', substring(substring-after($cdaTS, '-'), 1, 2), ':', substring(substring-after($cdaTS, '-'), 3, 2))" />
                        </xsl:when>
                        <xsl:when test="contains($cdaTS, '+')">
                            <xsl:sequence select="concat('+', substring(substring-after($cdaTS, '+'), 1, 2), ':', substring(substring-after($cdaTS, '+'), 3, 2))" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:sequence select="concat($date, 'T', $time, $timezone)" />
            </xsl:when>
            <xsl:when test="string-length($cdaTS) > 8">
                <xsl:variable name="time" as="xs:time">
                    <xsl:sequence select="adjust-time-to-timezone(xs:time(concat(substring($cdaTS, 9, 2), ':', substring($cdaTS, 11, 2), ':00.000')))" />
                </xsl:variable>
                <xsl:sequence select="concat($date, 'T', format-time($time, '[H01]:[m01]:[s01][Z]'))" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$date" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="TS2Date">
        <xsl:param name="ts" />
        <xsl:param name="date-only" select="false()" />
        <xsl:variable name="without-offset">
            <xsl:choose>
                <xsl:when test="contains($ts, '-')">
                    <xsl:value-of select="substring-before(translate($ts, 'T', ''), '-')" />
                </xsl:when>
                <xsl:when test="contains($ts, '+')">
                    <xsl:value-of select="substring-before(translate($ts, 'T', ''), '+')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$ts" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="default-date-part">
            <xsl:choose>
                <xsl:when test="$date-only" />
                <xsl:otherwise>01</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="default-time-part">
            <xsl:choose>
                <xsl:when test="$date-only" />
                <xsl:otherwise>00</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="year" select="substring($without-offset, 1, 4)" />
        <xsl:variable name="month">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 5, 2)">
                    <xsl:value-of select="substring($without-offset, 5, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-date-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="day">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 7, 2)">
                    <xsl:value-of select="substring($without-offset, 7, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-date-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="hour">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 9, 2)">
                    <xsl:value-of select="substring($without-offset, 9, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="minute">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 11, 2)">
                    <xsl:value-of select="substring($without-offset, 11, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="second">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 13, 2)">
                    <xsl:value-of select="substring($without-offset, 13, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="offset-direction">
            <xsl:if test="contains($ts, '-')">-</xsl:if>
            <xsl:if test="contains($ts, '+')">+</xsl:if>
        </xsl:variable>
        <xsl:variable name="offset">
            <xsl:choose>
                <xsl:when test="contains($ts, '-')">
                    <xsl:value-of select="translate(substring-after($ts, '-'), ':', '')" />
                </xsl:when>
                <xsl:when test="contains($ts, '+')">
                    <xsl:value-of select="translate(substring-after($ts, '+'), ':', '')" />
                </xsl:when>
                <xsl:otherwise />
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$year" />
        <xsl:if test="$month != ''">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$month" />
        </xsl:if>
        <xsl:if test="$day != ''">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$day" />
        </xsl:if>

        <!-- add the time, timezone, 'Z', etc, only if full dateTime -->
        <xsl:if test="not($date-only)">
            <xsl:if test="$hour != ''">
                <xsl:text>T</xsl:text>
                <xsl:value-of select="$hour" />
            </xsl:if>
            <xsl:if test="$minute != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$minute" />
            </xsl:if>
            <xsl:if test="$second != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$second" />
            </xsl:if>
            <xsl:choose>
                <xsl:when test="string-length($offset) = 2">
                    <xsl:variable name="offset-hour" select="substring($offset, 1, 2)" />
                    <xsl:value-of select="concat($offset-direction, $offset-hour, ':00')" />
                </xsl:when>
                <xsl:when test="string-length($offset) = 4">
                    <xsl:variable name="offset-hour" select="substring($offset, 1, 2)" />
                    <xsl:variable name="offset-minute" select="substring($offset, 3, 2)" />
                    <xsl:value-of select="concat($offset-direction, $offset-hour, ':', $offset-minute)" />
                </xsl:when>
                <xsl:otherwise>Z</xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

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

    <!-- Data type templates -->

    <!-- TEMPLATE: doseQuantity -->
    <xsl:template match="cda:doseQuantity">
        <!-- RG: Refactoring note - Look for use of this template, and see if we can refactor the whole Dosage datatype out of the resources and into this file -->
        <xsl:param name="pElementName">doseQuantity</xsl:param>
        <xsl:param name="pSimpleQuantity" select="false()" />

        <xsl:if test="$pSimpleQuantity = false() or not(@nullFlavor)">
            <xsl:element name="{$pElementName}">
                <xsl:if test="@value">
                    <value value="{@value}" />
                </xsl:if>
                <xsl:if test="@unit">
                    <unit value="{@unit}" />
                </xsl:if>
                <!-- A simple quantity doesn't allow a nullFlavor but we won't be in here if that param was true()-->
                <xsl:if test="@nullFlavor">
                    <code value="{lcg:fcnMapNullFlavor(@nullFlavor)}" />
                    <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
                </xsl:if>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: name -->
    <xsl:template match="cda:name" mode="display">
        <xsl:if test="cda:prefix">
            <xsl:value-of select="cda:prefix" />
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="cda:family and cda:given">
                <xsl:for-each select="cda:given">
                    <xsl:value-of select="." />
                    <xsl:text> </xsl:text>
                </xsl:for-each>
                <xsl:value-of select="cda:family/text()" />
            </xsl:when>
            <xsl:when test="cda:given and not(cda:family)">
                <xsl:value-of select="cda:given" />
            </xsl:when>
            <xsl:when test="cda:family and not(cda:given)">
                <xsl:value-of select="cda:family/text()" />
            </xsl:when>
            <xsl:otherwise>NAME NOT GIVEN</xsl:otherwise>
        </xsl:choose>
        <xsl:if test="cda:suffix">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="cda:suffix" />
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: name -->
    <xsl:template match="cda:name[not(@nullFlavor)]">
        <xsl:variable name="name-string">
            <xsl:for-each select="text() | cda:*">
                <xsl:value-of select="normalize-space(.)" />
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="use">
            <xsl:choose>
                <xsl:when test="@use = 'L'">usual</xsl:when>
                <xsl:when test="@use = 'P'">nickname</xsl:when>
                <xsl:when test="descendant::*/@qualifier = 'BR'">maiden</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="string-length(normalize-space($name-string)) > 0">
            <name>
                <xsl:if test="string-length($use) > 0">
                    <use value="{$use}" />
                </xsl:if>
                <xsl:if test="string-length(normalize-space(.)) > 0">
                    <xsl:choose>
                        <xsl:when test="cda:*">
                            <text>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="normalize-space(cda:family)" />
                                    <xsl:text>,</xsl:text>
                                    <xsl:for-each select="cda:suffix">
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                        <xsl-text>,</xsl-text>
                                    </xsl:for-each>
                                    <xsl:for-each select="cda:prefix">
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </xsl:for-each>
                                    <xsl:for-each select="cda:given">
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </xsl:for-each>
                                    <xsl:if test="string-length($use) > 0">
                                        <text> (</text>
                                        <xsl:value-of select="$use" />
                                        <text> name)</text>
                                    </xsl:if>
                                </xsl:attribute>
                            </text>
                        </xsl:when>
                        <xsl:otherwise>
                            <text value="{$name-string}" />
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:if>
                <xsl:for-each select="cda:family">
                    <xsl:if test="string-length(.) &gt; 0">
                        <family value="{.}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:given">
                    <xsl:if test="string-length(.) &gt; 0">
                        <given value="{.}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:prefix">
                    <xsl:if test="string-length(.) &gt; 0">
                        <prefix value="{.}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:suffix">
                    <xsl:if test="string-length(.) &gt; 0">
                        <suffix value="{.}" />
                    </xsl:if>
                </xsl:for-each>
            </name>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: telecom -->
    <xsl:template match="cda:telecom">
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="contains(@value, ':')">
                    <xsl:value-of select="substring-before(@value, ':')" />
                </xsl:when>
                <xsl:otherwise>tel</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="contains(@value, 'http')">
                    <xsl:value-of select="normalize-space(@value)" />
                </xsl:when>
                <xsl:when test="contains(@value, ':')">
                    <!-- Added normalize-space to trim spaces -->
                    <xsl:value-of select="normalize-space(substring-after(@value, ':'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@nullFlavor">
                <xsl:comment>Omitting null telecom</xsl:comment>
            </xsl:when>
            <xsl:otherwise>
                <telecom>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="lower-case($type) = 'tel'">phone</xsl:when>
                                <xsl:when test="lower-case($type) = 'mailto'">email</xsl:when>
                                <xsl:when test="lower-case($type) = 'http'">url</xsl:when>
                                <xsl:when test="lower-case($type) = 'https'">url</xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($type)" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </system>
                    <value>
                        <xsl:choose>
                            <xsl:when test="@value">
                                <xsl:attribute name="value">
                                    <xsl:value-of select="$value" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- TODO: Believe this extension needs to appear 1st in the datatype resource -->
                                <!-- this appears to cause problems with the FHIR->JSON converter -->
                                <!--<extension url="http://terminology.hl7.org/CodeSystem/v3-NullFlavor"> 
									<valueCode value="UNK"/>
								</extension>-->
                                <xsl:attribute name="value">Unknown</xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                    </value>
                    <xsl:if test="@use">
                        <use>
                            <xsl:attribute name="value">
                                <xsl:choose>
                                    <xsl:when test="@use = 'H' or @use = 'HP' or @use = 'HV'">home</xsl:when>
                                    <xsl:when test="@use = 'WP' or @use = 'DIR' or @use = 'PUB'">work</xsl:when>
                                    <xsl:when test="@use = 'MC'">mobile</xsl:when>
                                    <!-- default to work -->
                                    <xsl:otherwise>work</xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </use>
                    </xsl:if>
                    <xsl:apply-templates select="cda:useablePeriod" />
                </telecom>
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: time -->
    <xsl:template match="cda:time[cda:low/@value or cda:high/@value]">
        <xsl:choose>
            <xsl:when test="cda:low/@value or cda:high/@value">
                <period>
                    <xsl:if test="cda:low/@value">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high/@value">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </period>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>Unable to map usablePeriod to a FHIR period</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: usablePeriod -->
    <xsl:template match="cda:useablePeriod[@value or cda:low/@value or cda:high/@value]">
        <xsl:choose>
            <xsl:when test="@value">
                <period>
                    <start value="{lcg:cdaTS2date(@value)}" />
                    <end value="{lcg:cdaTS2date(@value)}" />
                </period>
            </xsl:when>
            <xsl:when test="cda:low/@value or cda:high/@value">
                <period>
                    <xsl:if test="cda:low/@value">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high/@value">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </period>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>Unable to map usablePeriod to a FHIR period</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE:addr -->
    <xsl:template match="cda:addr[not(@nullFlavor)]">
        <xsl:param name="pElementName">address</xsl:param>
        <xsl:variable name="addr-string">
            <xsl:for-each select="text() | cda:*">
                <xsl:value-of select="normalize-space(.)" />
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="string-length($addr-string) &gt; 0">
            <xsl:element name="{$pElementName}">
                <xsl:if test="@use">
                    <use>
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="@use = 'H' or @use = 'HP' or @use = 'HV'">home</xsl:when>
                                <xsl:when test="@use = 'WP' or @use = 'DIR' or @use = 'PUB'">work</xsl:when>
                                <!-- default to work -->
                                <xsl:otherwise>work</xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </use>
                </xsl:if>
                <xsl:for-each select="cda:streetAddressLine[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <line value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:city[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <city value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:county[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <!-- SG: Updating this from county to district - no county in FHIR -->
                        <district value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:state[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <state value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:postalCode[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <postalCode value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:country[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <country value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:apply-templates select="cda:useablePeriod" />

            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: id, setId -->
    <xsl:template match="cda:id | cda:setId">
        <xsl:param name="pElementName">identifier</xsl:param>
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
        <xsl:variable name="oid" select="@root" />
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="$oid = '2.16.840.1.113883.4.873'">
                    <xsl:call-template name="get-substring-after-last">
                        <xsl:with-param name="pString" select="@extension" />
                        <xsl:with-param name="pDelimiter" select="'/'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="lower-case(@extension)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="root-uri">
            <xsl:choose>
                <!-- SG 2023-11-15: Updating the below based on the rules here: 
                    https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html (see: CDA id → FHIR Identifier with Example Mapping) Case: "Root = URI OID, Value = URL"-->
                <xsl:when test="$oid = '2.16.840.1.113883.4.873'">
                    <xsl:value-of select="substring-before(@extension, concat('/', $value))" />
                </xsl:when>
                <xsl:when test="$mapping/map[@oid = $oid]">
                    <xsl:value-of select="$mapping/map[@oid = $oid][1]/@uri" />
                </xsl:when>
                <xsl:when test="contains(@root, '.')">
                    <xsl:text>urn:oid:</xsl:text>
                    <xsl:value-of select="@root" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>urn:uuid:</xsl:text>
                    <xsl:value-of select="@root" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$root-uri and @nullFlavor">
                <xsl:element name="{$pElementName}">
                    <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    <system value="{lower-case($root-uri)}" />
                </xsl:element>
            </xsl:when>
            <xsl:when test="@nullFlavor">
                <xsl:element name="{$pElementName}">
                    <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                </xsl:element>
            </xsl:when>

            <!-- Check assigningAuthorityName first -->
            <xsl:when test="@root and @extension and @assigningAuthorityName">
                <xsl:element name="{$pElementName}">
                    <system value="{lower-case($root-uri)}" />
                    <value value="{$value}" />
                    <assigner>
                        <display value="{@assigningAuthorityName}" />
                    </assigner>
                </xsl:element>
            </xsl:when>

            <!-- If no assigningAuthorityName -->
            <xsl:when test="@root and @extension">
                <xsl:element name="{$pElementName}">
                    <system value="{lower-case($root-uri)}" />
                    <value value="{$value}" />
                </xsl:element>
            </xsl:when>

            <xsl:when test="@root and not(@extension)">
                <xsl:element name="{$pElementName}">
                    <system value="urn:ietf:rfc:3986" />
                    <value value="{$root-uri}" />
                </xsl:element>
            </xsl:when>
        </xsl:choose>

    </xsl:template>

    <!-- TEMPLATE: All different kinds of code
    cda:raceCode, sdtc:raceCode are used in mode extension-raceCode, which calls this template 
     Param: pElementName - defaults to CodeableConcept - name of outer element
     Param: pIncludeCoding - defaults to true whether or not to include a coding element as the inner element 
  -->
    <xsl:template match="
            cda:code | cda:confidentialityCode | cda:maritalStatusCode | cda:routeCode | cda:raceCode | sdtc:raceCode |
            cda:ethnicGroupCode | cda:religiousAffiliationCode | cda:targetSiteCode | cda:priorityCode | cda:translation |
            cda:methodCode | cda:approachSiteCode | sdtc:functionCode | cda:dischargeDispositionCode | sdtc:dischargeDispositionCode">
        <xsl:param name="pElementName" select="'CodeableConcept'" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="$pElementName" />
            <xsl:with-param name="pIncludeCoding" select="$pIncludeCoding" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="get-reference-text">
        <xsl:param name="pTextElement"/>
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
                            <xsl:apply-templates select="//*[@ID = $vTextReference]" mode="serialize"/>
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

    <!-- TEMPLATE (named):newCreateCodeableConcept - creates a codeableConcept element-->
    <xsl:template name="newCreateCodableConcept">
        <xsl:param name="pElementName" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:param name="includeTranslations" select="true()" />
        <xsl:variable name="originalTextReference">
            <xsl:value-of select="substring(cda:originalText/cda:reference/@value, 2)" />
        </xsl:variable>
        <xsl:variable name="originalText">
            <xsl:choose>
                <xsl:when test="cda:originalText/cda:reference">
                    <xsl:choose>
                        <xsl:when test="//*[@ID = $originalTextReference]/text()">
                            <xsl:value-of select="//*[@ID = $originalTextReference]/text()" />
                        </xsl:when>
                        <xsl:when test="//*[@ID = $originalTextReference]/../text()">
                            <xsl:value-of select="//*[@ID = $originalTextReference]/following-sibling::text()" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="cda:originalText">
                    <xsl:value-of select="cda:originalText" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="isValue" select="false()" />
        <xsl:variable name="vCode" select="@code" />
        <xsl:variable name="display">
            <xsl:choose>
                <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this isn't going to catch everything,
                     but will clean up our testing warnings -->
                <xsl:when test="$code-display-mapping/map[@code = $vCode]">
                    <xsl:value-of select="$code-display-mapping/map[@code = $vCode]/@display" />
                </xsl:when>
                <xsl:when test="@displayName">
                    <xsl:value-of select="@displayName" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$originalText" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vNullFlavor">
            <xsl:choose>
                <xsl:when test="not(@nullFlavor) and not(@code) and not(@codeSystem)">NI</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@nullFlavor" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="content">
            <xsl:call-template name="createCodeableConceptContent">
                <xsl:with-param name="codeSystem" select="@codeSystem" />
                <xsl:with-param name="code" select="@code" />
                <xsl:with-param name="displayName" select="$display" />
                <xsl:with-param name="isValue" select="$isValue" />
                <xsl:with-param name="pNullFlavor" select="$vNullFlavor" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="translations">
            <xsl:for-each select="cda:translation">
                <xsl:variable name="vTranslationCode" select="@code" />
                <xsl:variable name="vTranslationDisplay">
                    <xsl:choose>
                        <xsl:when test="$code-display-mapping/map[@code = $vTranslationCode]">
                            <xsl:value-of select="$code-display-mapping/map[@code = $vTranslationCode]/@display" />
                        </xsl:when>
                        <xsl:when test="@displayName">
                            <xsl:value-of select="normalize-space(@displayName)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(cda:originalText)" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="vNullFlavorInTranslation">
                    <xsl:choose>
                        <xsl:when test="not(@nullFlavor) and not(@code) and not(@codeSystem)">NI</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@nullFlavor" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="this-translation">
                    <xsl:call-template name="createCodeableConceptContent">
                        <xsl:with-param name="codeSystem" select="@codeSystem" />
                        <xsl:with-param name="code" select="@code" />
                        <xsl:with-param name="displayName" select="$vTranslationDisplay" />
                        <xsl:with-param name="isValue" select="$isValue" />
                        <xsl:with-param name="pNullFlavor" select="$vNullFlavorInTranslation" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>

                    <xsl:when test="$pIncludeCoding = true()">
                        <coding>
                            <xsl:copy-of select="$this-translation" />
                        </coding>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$this-translation" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$pIncludeCoding = true()">
                    <coding>
                        <xsl:copy-of select="$content" />
                    </coding>
                    <xsl:if test="$includeTranslations">
                        <xsl:copy-of select="$translations" />
                    </xsl:if>
                    <xsl:if test="string-length($originalText) &gt; 0 and normalize-space($originalText) != ''">
                        <xsl:element name="text">
                            <xsl:attribute name="value">
                                <xsl:value-of select="normalize-space($originalText)" />
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$content" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>

    </xsl:template>

    <xsl:template name="createCodeableConcept">
        <xsl:param name="pSystem" />
        <xsl:param name="pCode" />
        <xsl:param name="pDisplay" />
        <xsl:param name="pText" />
        <xsl:param name="pInnerElement" select="'coding'" />
        <xsl:param name="pOuterElement" select="'CodeableConcept'" />

        <xsl:element name="{$pOuterElement}">
            <xsl:call-template name="createCoding">
                <xsl:with-param name="pSystem" select="$pSystem" />
                <xsl:with-param name="pCode" select="$pCode" />
                <xsl:with-param name="pDisplay" select="$pDisplay" />
                <xsl:with-param name="pElement" select="$pInnerElement" />
            </xsl:call-template>
            <xsl:if test="$pText">
                <text>
                    <xsl:value-of select="$pText" />
                </text>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createCoding">
        <xsl:param name="pSystem" />
        <xsl:param name="pCode" />
        <xsl:param name="pDisplay" />
        <xsl:param name="pElement" />

        <xsl:element name="{$pElement}">
            <system>
                <xsl:attribute name="value" select="$pSystem" />
            </system>
            <code>
                <xsl:attribute name="value" select="$pCode" />
            </code>
            <display>
                <xsl:attribute name="value" select="$pDisplay" />
            </display>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createCodeableConceptContent">
        <xsl:param name="codeSystem" />
        <xsl:param name="code" />
        <xsl:param name="displayName" />
        <!--
		<xsl:param name="label"/>
		-->
        <xsl:param name="isValue" select="false()" />
        <xsl:param name="pNullFlavor" />
        <xsl:variable name="codeOrValueElementName">
            <xsl:choose>
                <xsl:when test="not($isValue)">code</xsl:when>
                <xsl:otherwise>value</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$codeSystem and $pNullFlavor = ''">
            <system>
                <xsl:attribute name="value">
                    <xsl:call-template name="convertOID">
                        <xsl:with-param name="oid" select="$codeSystem" />
                    </xsl:call-template>
                </xsl:attribute>
            </system>
        </xsl:if>
        <xsl:if test="$code">
            <xsl:element name="{$codeOrValueElementName}">
                <xsl:attribute name="value">
                    <xsl:value-of select="$code" />
                </xsl:attribute>
            </xsl:element>
        </xsl:if>

        <xsl:if test="not($pNullFlavor = '') and not($code)">
            <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
            <xsl:element name="{$codeOrValueElementName}">
                <xsl:attribute name="value">
                    <xsl:value-of select="$pNullFlavor" />
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$displayName and not($displayName = '') and $pNullFlavor = ''">
                <display>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$displayName" />
                    </xsl:attribute>
                </display>
            </xsl:when>
            <xsl:when test="not($pNullFlavor = '')">
                <display>
                    <xsl:attribute name="value" select="lcg:fcnMapNullFlavor($pNullFlavor)" />
                </display>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:birthTime | sdtc:birthTime">
        <xsl:param name="pElementName">birthDate</xsl:param>
        <xsl:if test="not(@nullFlavor)">
            <xsl:element name="{$pElementName}">
                <xsl:attribute name="value" select="lcg:dateFromcdaTS(@value)" />
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:administrativeGenderCode">
        <xsl:param name="pElementName">gender</xsl:param>
        <xsl:variable name="cda-gender" select="@code" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$cda-gender = 'M'">
                    <xsl:attribute name="value">male</xsl:attribute>
                </xsl:when>
                <xsl:when test="$cda-gender = 'F'">
                    <xsl:attribute name="value">female</xsl:attribute>
                </xsl:when>
                <xsl:when test="$cda-gender = 'UN'">
                    <xsl:attribute name="value">other</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value">unknown</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:interpretationCode">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="'interpretation'" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'TS']">
        <xsl:param name="pElementName" select="'valueDateTime'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="lcg:cdaTS2date(@value)" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'BL']">
        <xsl:param name="pElementName" select="'valueBoolean'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="@value" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'ST' or @xsi:type = 'ED']">
        <xsl:param name="pElementName" select="'valueString'" />
        <xsl:variable name="content">
            <xsl:choose>
                <xsl:when test="@nullFlavor">
                    <xsl:value-of select="@nullFlavor" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="$content" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'INT'] | cda:sequenceNumber">
        <xsl:param name="pElementName" select="'valueInteger'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="@value" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'PQ'][not(@nullFlavor)]">
        <xsl:param name="pElementName" select="'valueQuantity'" />
        <xsl:param name="pVitalSign" select="false()" />

        <!-- Make sure units are correct -->
        <xsl:variable name="vUnit">
            <xsl:choose>
                <xsl:when test="$pVitalSign = true()">
                    <xsl:choose>
                        <xsl:when test="@unit = '[in_us]'">[in_i]</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@unit" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@unit" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$pElementName}">
            <xsl:if test="@value">
                <value>
                    <xsl:attribute name="value">
                        <xsl:value-of select="@value" />
                    </xsl:attribute>
                </value>
            </xsl:if>
            <xsl:if test="@unit">
                <unit>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$vUnit" />
                    </xsl:attribute>
                </unit>
            </xsl:if>
            <!-- If this is a vital sign need system and unit-->
            <xsl:if test="$pVitalSign = true()">
                <system value="http://unitsofmeasure.org" />
                <code>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$vUnit" />
                    </xsl:attribute>
                </code>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'CD' or @xsi:type = 'CE']">
        <xsl:param name="pElementName" select="'valueCodeableConcept'" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="$pElementName" />
            <xsl:with-param name="pIncludeCoding" select="$pIncludeCoding" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:effectiveTime | cda:time" mode="instant">
        <xsl:param name="pElementName">date</xsl:param>
        <xsl:choose>
            <xsl:when test="./@value and not(cda:low) and not(cda:center)">
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(./@value)" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:low/@value and not(@value) and not(cda:center)">
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:center/@value and not(@value) and not(cda:low)">
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:center/@value)" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:template>

    <!--    <xsl:template match="cda:effectiveTime[@value or cda:low/@value or cda:high/@value] | cda:time[@value or cda:low/@value or cda:high/@value]" mode="period">-->
    <xsl:template match="cda:effectiveTime[@value or cda:low or cda:high] | cda:time[@value or cda:low or cda:high]" mode="period">
        <xsl:param name="pElementName">period</xsl:param>
        <xsl:element name="{$pElementName}">
            <xsl:call-template name="effectiveTimeInner" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:effectiveTime | cda:time" mode="timingPeriod">
        <timingPeriod>
            <xsl:call-template name="effectiveTimeInner" />
        </timingPeriod>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="whenGiven">
        <whenGiven>
            <xsl:call-template name="effectiveTimeInner" />
        </whenGiven>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="event">
        <event>
            <xsl:call-template name="effectiveTimeInner" />
        </event>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A']">
        <repeat>
            <frequency value="1" />
            <xsl:choose>
                <xsl:when test="cda:period/@value and not(cda:period/cda:low) and not(cda:period/cda:high)">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="normalize-space(cda:period/@value)" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
                <xsl:when test="not(cda:period/@value) and cda:period/cda:low/@value">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:low/@value" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
                <xsl:when test="not(cda:period/@value) and not(cda:period/cda:low/@value) and cda:period/cda:high/@value">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:high/@value" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="cda:period/@unit and not(cda:period/cda:low) and not(cda:period/cda:high)">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
                <xsl:when test="not(cda:period/@unit) and cda:period/cda:low/@unit">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:low/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
                <xsl:when test="not(cda:period/@unit) and not(cda:period/cda:low/@unit) and cda:period/cda:high/@unit">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:high/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
            </xsl:choose>
        </repeat>
    </xsl:template>

    <xsl:template match="cda:ClinicalDocument/cda:effectiveTime" mode="observation">
        <xsl:comment>Using document effective time as issued date</xsl:comment>
        <xsl:apply-templates select="." mode="instant">
            <xsl:with-param name="pElementName">issued</xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="effectiveTimeInner">
        <xsl:if test="cda:width/@value and cda:width/@unit = 'weeks' and cda:high">
            <!-- Convert date string into date - only care about the first 8 chars -->
            <xsl:variable name="vDate" select="xs:date(concat(substring(cda:high/@value, 1, 4), '-', substring(cda:high/@value, 5, 2), '-', substring(cda:high/@value, 7, 2)))" />
            <xsl:variable name="vNumDays" select="7 * cda:width/@value" />
            <!-- Subtract number of days from start date -->
            <xsl:variable name="vStartDate" select="format-date(($vDate - $vNumDays * xs:dayTimeDuration('P1D')), '[Y][M][D]')" />
            <!-- Convert back to a string for futher processing -->
            <start value="{lcg:cdaTS2date($vStartDate)}" />
        </xsl:if>
        <xsl:if test="cda:low[@value]">
            <start value="{lcg:cdaTS2date(cda:low/@value)}" />
        </xsl:if>
        <xsl:if test="cda:high[@value]">
            <end value="{lcg:cdaTS2date(cda:high/@value)}" />
        </xsl:if>
        <xsl:if test="@value and not(cda:low/@value)">
            <start value="{lcg:cdaTS2date(@value)}" />
            <end value="{lcg:cdaTS2date(@value)}" />
        </xsl:if>
        <xsl:if test="cda:center/@value and not(cda:width/@value)">
            <start value="{lcg:cdaTS2date(cda:center/@value)}" />
            <end value="{lcg:cdaTS2date(cda:center/@value)}" />
        </xsl:if>
        <xsl:if test="not(@value) and cda:low/@nullFlavor and cda:high/@nullFlavor">
            <start>
                <xsl:apply-templates select="cda:low/@nullFlavor" mode="data-absent-reason-extension" />
            </start>
            <end>
                <xsl:apply-templates select="cda:low/@nullFlavor" mode="data-absent-reason-extension" />
            </end>

        </xsl:if>

    </xsl:template>

    <xsl:template name="II2Identifier">
        <xsl:param name="this" />

        <!-- if an II with @root only, then system is IETF, and value is the URI
			if @extension, then system is the @root and value is the @extension
			-->
        <xsl:choose>
            <xsl:when test="$this/@extension">
                <system>
                    <xsl:attribute name="value">urn:oid:<xsl:value-of select="$this/@root" /></xsl:attribute>
                </system>
                <value>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$this/@extension" />
                    </xsl:attribute>
                </value>
            </xsl:when>
            <xsl:otherwise>
                <system value="urn:ietf:rfc:3986" />
                <value>
                    <xsl:attribute name="value">urn:oid:<xsl:value-of select="$this/@root" /></xsl:attribute>
                </value>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper templates -->
    <xsl:template match="cda:effectiveTime" mode="extension-effectiveTime">
        <extension url="http://lantana.com/fhir/Profile/organizer#effectiveTime">
            <valuePeriod>
                <xsl:if test="cda:low">
                    <start>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                        </xsl:attribute>
                    </start>
                </xsl:if>
                <xsl:if test="cda:high">
                    <end>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                        </xsl:attribute>
                    </end>
                </xsl:if>
            </valuePeriod>
        </extension>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="applies">
        <xsl:choose>
            <xsl:when test="@value and @value != ''">
                <appliesDateTime>
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(@value)" />
                    </xsl:attribute>
                </appliesDateTime>
            </xsl:when>
            <xsl:when test="(cda:low/@value and not(cda:high/@value)) or cda:low/@value = cda:high/@value">
                <appliesDateTime>
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                    </xsl:attribute>
                </appliesDateTime>
            </xsl:when>
            <xsl:otherwise>
                <appliesPeriod>
                    <xsl:if test="cda:low">
                        <start>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                            </xsl:attribute>
                        </start>
                    </xsl:if>
                    <xsl:if test="cda:high">
                        <end>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                            </xsl:attribute>
                        </end>
                    </xsl:if>
                </appliesPeriod>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="appliesPeriod">
        <appliesPeriod>
            <xsl:choose>
                <xsl:when test="@value and @value != ''">
                    <start>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(@value)" />
                        </xsl:attribute>
                    </start>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="cda:low">
                        <start>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                            </xsl:attribute>
                        </start>
                    </xsl:if>
                    <xsl:if test="cda:high">
                        <end>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                            </xsl:attribute>
                        </end>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </appliesPeriod>
    </xsl:template>

    <!-- TEMPLATE: If effectiveTime has no mode figure out what mode it's supposed to have -->
    <xsl:template match="cda:effectiveTime | cda:time" priority="-1">
        <xsl:param name="pStartElementName" />
        <xsl:choose>
            <xsl:when test="cda:width and cda:high">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@xsi:type = 'IVL_TS'">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="cda:low or cda:high">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@value">
                <xsl:apply-templates select="." mode="instant">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'DateTime')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@nullFlavor">
                <xsl:comment>CDA effectiveTime/time was null</xsl:comment>
                <xsl:copy />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">Unknown effective time format</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
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
        <!-- TODO: handle multiple subjects (record as a group where allowed - needed for HAI) -->
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
            <xsl:when
                test="$pPractitionerRole = true() and (cda:performer or cda:author or ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:performer or /ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:author)">
                <xsl:for-each select="cda:performer">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:performer">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedEntity/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="ancestor::cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.1']]/cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <!-- when there is nothing above, start looking further afield - check the containing section/author -->
            <xsl:when test="$pPractitionerRole = true() and ancestor::cda:section/cda:author">
                <xsl:for-each select="ancestor::cda:section/cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
            <!-- when there is no section author - look at the ClinicalDocument/author -->
            <xsl:when test="$pPractitionerRole = true() and /cda:ClinicalDocument/cda:author">
                <xsl:for-each select="/cda:ClinicalDocument/cda:author">
                    <xsl:element name="{$pElementName}">
                        <reference value="urn:uuid:{cda:assignedAuthor/@lcg:uuid}" />
                    </xsl:element>
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

    <xsl:template match="cda:high | cda:low" mode="range">
        <xsl:variable name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:if test="@value">
                <value>
                    <xsl:attribute name="value">
                        <xsl:value-of select="@value" />
                    </xsl:attribute>
                </value>
            </xsl:if>
            <xsl:if test="@unit">

                <unit>
                    <xsl:attribute name="value">
                        <xsl:value-of select="@unit" />
                    </xsl:attribute>
                </unit>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'INT']" mode="scale">
        <xsl:param name="pElementName" select="'valueQuantity'" />
        <xsl:element name="{$pElementName}">
            <value>
                <xsl:attribute name="value">
                    <xsl:value-of select="@value" />
                </xsl:attribute>
            </value>
            <system value="http://unitsofmeasure.org" />
            <code>
                <xsl:attribute name="value">{score}</xsl:attribute>
            </code>
        </xsl:element>
    </xsl:template>

    <!-- TEMPLATE: act reference -->
    <xsl:template match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.122']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:variable name="reference-id" select="cda:id" />
        <xsl:for-each select="key('referenced-acts', $reference-id/@root)">
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
            <!--  
			<xsl:comment>wrapping-elements=<xsl:value-of select="$wrapping-elements"/></xsl:comment>
			-->
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
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: Remove Concern wrappers -->
    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.30'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.136']]"
        mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="reference">
                <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: Remove Concern wrappers -->
    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.30'] or cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.136']]"
        mode="bundle-entry">
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
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

</xsl:stylesheet>
