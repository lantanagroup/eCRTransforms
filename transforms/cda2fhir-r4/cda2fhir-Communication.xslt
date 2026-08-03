<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
  exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <!-- Add Communication for Instruction template -->
  <!-- Want to exclude Reportability Response Summary and Subject from this transform -->
  <xsl:template
    match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]"
    mode="bundle-entry">

    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20260803 Claude (item 43/CDAFHIR-007): guard on @value - a null-flavored or interval
       effectiveTime passed an empty sequence to cdaTS2date (typed xs:string) and killed the
       transform with XPTY0004. sent is optional, so the absent case emits nothing. -->
  <xsl:template match="cda:effectiveTime" mode="communication">
    <xsl:if test="@value">
    <sent value="{lcg:cdaTS2date(@value)}" />
    </xsl:if>
  </xsl:template>

  <xsl:template
    match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.20']][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.8'])][not(cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.7'])]">
    <Communication>
      <!-- 20260729 Claude: Fix - this template never called add-meta (the 4.141 template below does) -->
      <xsl:call-template name="add-meta" />
      <xsl:apply-templates select="cda:id" />

      <!-- partOf: point back to the containing resource -->
      <!-- 20260729 Claude: Fix - was ../../../cda:* (a fixed-depth wildcard that selects ALL children of the
           great-grandparent; multiple matches space-joined into a malformed reference, and the wrong node when the
           nesting depth varies); now the nearest containing clinical statement, omitted when there is none -->
      <xsl:variable name="vContaining"
        select="ancestor::cda:*[self::cda:act or self::cda:observation or self::cda:organizer or self::cda:substanceAdministration or self::cda:procedure or self::cda:encounter][1]" />
      <xsl:if test="$vContaining">
        <partOf>
          <reference value="urn:uuid:{$vContaining/@lcg:uuid}" />
        </partOf>
      </xsl:if>
      <!-- status -->
      <!-- 20260729 Claude: Fix - the CDA ActStatus code was copied raw; now mapped to the Communication status value
           set (shared template below); 'completed' kept as the no-statusCode default -->
      <xsl:choose>
        <xsl:when test="cda:statusCode/@code">
          <xsl:apply-templates select="cda:statusCode" mode="map-communication-status" />
        </xsl:when>
        <xsl:otherwise>
          <status value="completed" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="subject-reference" />

      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName">topic</xsl:with-param>
      </xsl:apply-templates>

      <xsl:call-template name="encompassingEncounter-reference" />

      <xsl:for-each select="cda:entryRelationship">
        <xsl:choose>
          <xsl:when test="cda:act/cda:participant[@typeCode = 'AUT']">
            <!-- MD: need to check the present of effectiveTime to prevent error -->
            <xsl:choose>
              <!-- 20260803 Claude (item 43/CDAFHIR-007): test @value, not element existence - nullFlavor/interval times crashed cdaTS2date -->
              <xsl:when test="cda:act/cda:effectiveTime/@value">
                <sent value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
              </xsl:when>
            </xsl:choose>

          </xsl:when>
          <xsl:when test="cda:act/cda:participant[@typeCode = 'IRCP']">
            <xsl:choose>
              <!-- MD: need to check the present of effectiveTime to prevent error -->
              <!-- 20260803 Claude (item 43/CDAFHIR-007): test @value, not element existence - nullFlavor/interval times crashed cdaTS2date -->
              <xsl:when test="cda:act/cda:effectiveTime/@value">
                <received value="{lcg:cdaTS2date(cda:act/cda:effectiveTime/@value)}" />
              </xsl:when>
            </xsl:choose>

          </xsl:when>
        </xsl:choose>
      </xsl:for-each>

      <xsl:call-template name="subject-reference">
        <xsl:with-param name="pElementName" select="'recipient'" />
      </xsl:call-template>

      <!-- get closest author (work up the hierarchy if needed) -->
      <xsl:variable name="vClosestAuthor">
        <xsl:call-template name="get-closest-author" />
      </xsl:variable>
      <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
        <xsl:with-param name="pElementName">sender</xsl:with-param>
      </xsl:apply-templates>

      <xsl:if test="cda:text">
        
        <xsl:variable name="vText">
          <xsl:call-template name="get-reference-text">
            <xsl:with-param name="pTextElement" select="cda:text" />
          </xsl:call-template>
        </xsl:variable>
        
        <payload>
          <contentString>
            <xsl:attribute name="value">
              <xsl:value-of select="$vText" />
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
    <xsl:comment>INFO: C-CDA Handoff Communication Participants</xsl:comment>
    <Communication xmlns="http://hl7.org/fhir">
      <xsl:call-template name="add-meta" />
      <xsl:apply-templates select="cda:id" />
      <!-- 20260729 Claude: Fix - raw statusCode copy replaced with the shared status mapping -->
      <xsl:choose>
        <xsl:when test="cda:statusCode/@code">
          <xsl:apply-templates select="cda:statusCode" mode="map-communication-status" />
        </xsl:when>
        <xsl:otherwise>
          <status value="completed" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="subject-reference" />
      <xsl:apply-templates select="cda:effectiveTime" mode="communication" />
      <xsl:for-each select="cda:participant">
        <recipient>
          <xsl:apply-templates select="cda:participantRole" mode="reference" />
          <!--<reference value="urn:uuid:{@lcg:uuid}"/>-->
        </recipient>
      </xsl:for-each>
      <!-- get closest author (work up the hierarchy if needed) -->
      <xsl:variable name="vClosestAuthor">
        <xsl:call-template name="get-closest-author" />
      </xsl:variable>
      <xsl:apply-templates select="$vClosestAuthor/cda:author[1]" mode="rename-reference-participant">
        <xsl:with-param name="pElementName">sender</xsl:with-param>
      </xsl:apply-templates>
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
      </xsl:apply-templates>
    </Communication>
  </xsl:template>

  <!-- 20260729 Claude: Added - maps CDA ActStatus to the FHIR Communication status value set
       (preparation | in-progress | not-done | on-hold | stopped | completed | entered-in-error | unknown) -->
  <xsl:template match="cda:statusCode" mode="map-communication-status">
    <status>
      <xsl:attribute name="value">
        <xsl:choose>
          <xsl:when test="@code = 'completed'">completed</xsl:when>
          <xsl:when test="@code = 'active'">in-progress</xsl:when>
          <xsl:when test="@code = 'new'">preparation</xsl:when>
          <xsl:when test="@code = 'held' or @code = 'suspended'">on-hold</xsl:when>
          <xsl:when test="@code = 'aborted'">stopped</xsl:when>
          <xsl:when test="@code = 'cancelled'">not-done</xsl:when>
          <xsl:when test="@code = 'nullified'">entered-in-error</xsl:when>
          <xsl:otherwise>unknown</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </status>
  </xsl:template>

</xsl:stylesheet>
