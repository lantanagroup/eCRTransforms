<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fhir="http://hl7.org/fhir" xmlns:cda="urn:hl7-org:v3"
  xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="xs fhir cda lcg" version="2.0">
  <xsl:output indent="yes" />
  <!-- create bundle-entry for RR externalDocument as DocumentReference -->
  <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']" mode="bundle-entry">
    <entry>
      <fullUrl value="urn:uuid:{@lcg:uuid}" />
      <resource>
        <xsl:apply-templates select="cda:reference/cda:externalDocument" />
      </resource>
    </entry>
  </xsl:template>
  <!-- 20260424 SG: manually create bundle-entry for CDA Document as DocumentReference -->
  <!-- 20260727 Claude: Fix - when the CDA has no setId this emitted an entry with an empty fullUrl ("urn:uuid:").
       The DocumentReference records the prior/superseded document version identified by setId, so when there is no
       setId there is nothing meaningful to record - skip the entry entirely (nothing references it: Composition's
       relatesTo uses targetIdentifier, not a reference) -->
  <xsl:template match="cda:ClinicalDocument" mode="manual-bundle-entry">
    <xsl:if test="cda:setId">
      <entry>
        <fullUrl value="urn:uuid:{cda:setId/@lcg:uuid}" />
        <resource>
          <xsl:apply-templates select="." mode="doc-ref" />
        </resource>
      </entry>
    </xsl:if>
  </xsl:template>
  <!-- 20260424 SG: create bundle-entry for eICR relatedDocument as DocumentReference -->
  <xsl:template match="cda:relatedDocument[@typeCode = 'XFRM']" mode="bundle-entry">
    <xsl:for-each select=".">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
  </xsl:template>
  <!-- 20260424 SG: create bundle-entry for CDA Document as DocumentReference -->
  <xsl:template match="cda:ClinicalDocument/cda:setId" mode="bundle-entry">
    <xsl:for-each select=".">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
  </xsl:template>
  <!-- SG: Not sure if this is the correct place for this - leaving it here for now -->
  <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.9']" mode="reference">
    <xsl:param name="wrapping-elements" />
    <xsl:param name="pElementName">reference</xsl:param>
    <xsl:if test="not(@nullFlavor)">
      <xsl:variable name="this" select="." />
      <!-- SG: Changed to a for-each so that all template ids get spit out -->
      <xsl:for-each select="cda:templateId">
        <xsl:choose>
          <xsl:when test="@extension">
            <xsl:comment><xsl:value-of select="concat(@root, ':', @extension)" /></xsl:comment>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment><xsl:value-of select="@root" /></xsl:comment>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <!-- 20260729 Claude: Fix - xsl:element name="{$wrapping-elements}" was used unconditionally; when this template is
           reached without a wrapping-elements param that is a runtime error (invalid empty QName). Now falls back to a
           plain reference element named by pElementName -->
      <xsl:choose>
        <xsl:when test="string-length($wrapping-elements) > 0">
          <xsl:element name="{$wrapping-elements}">
            <reference>
              <xsl:attribute name="value">urn:uuid:<xsl:value-of select="@lcg:uuid" /></xsl:attribute>
            </reference>
            <!-- Special code for [RR R1S1] Received eICR Information -->
            <identifier>
              <system value="urn:ietf:rfc:3986" />
              <value>
                <xsl:attribute name="value" select="concat('urn:uuid:', cda:reference/cda:externalDocument/cda:id/@root)" />
              </value>
            </identifier>
            <!-- 20260804 Claude (CDAFHIR-048): guarded. cda:text on the Received eICR Information act
                 (15.2.3.9) carries the eICR filename and is recommended only for error cases, so it is
                 legitimately absent in conformant input - but xsl:attribute materialises the attribute
                 even when its select is an empty sequence, so absence produced <display value=""/>: an
                 ele-1 violation in 7 of the 9 RR corpus documents. Reference.display is 0..1 and purely a
                 human-readable label, and no nullFlavor was asserted, so the element is omitted rather
                 than given a data-absent-reason (DAR is this codebase's convention for data the source
                 explicitly flagged as absent, not for an optional label that simply is not there). -->
            <xsl:if test="normalize-space(cda:text)">
              <display>
                <xsl:attribute name="value" select="normalize-space(cda:text)" />
              </display>
            </xsl:if>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">urn:uuid:<xsl:value-of select="@lcg:uuid" /></xsl:attribute>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- RR External Resource[1]/RR External Reference[1..*] -> RR DocumentReference - bundle entry -->
  <xsl:template match="cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.20']" mode="bundle-entry">
    <xsl:for-each select="cda:reference/cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.17']">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
  </xsl:template>
  <!-- RR External Resource[1]/RR External Reference[1..*] -> RR DocumentReference -->
  <xsl:template match="cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.17']">
    <xsl:comment>RR DocumentReference</xsl:comment>
    <!--        <xsl:for-each select="cda:reference/cda:externalDocument">-->
    <DocumentReference>
      <xsl:call-template name="add-meta" />
      <xsl:for-each select="../../cda:priorityCode">
        <!-- priorityCode -->
        <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension">
          <xsl:apply-templates select=".">
            <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
          </xsl:apply-templates>
        </extension>
      </xsl:for-each>
      <xsl:apply-templates select="cda:id" />
      <status value="current" />
      <type>
        <coding>
          <system value="http://loinc.org" />
          <code value="83910-0" />
          <display value="Public health Note" />
        </coding>
        <text value="Public health information" />
      </type>
      <xsl:apply-templates select="../../cda:code">
        <xsl:with-param name="pElementName">category</xsl:with-param>
      </xsl:apply-templates>
      <!--<xsl:for-each select="../../cda:code">
                    <!-\- code -\->
                    <extension url="http://hl7.org/fhir/us/ecr/StructureDefinition/rr-external-resource-type-extension">
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="pElementName" select="'valueCodeableConcept'" />
                        </xsl:apply-templates>
                    </extension>
                </xsl:for-each>-->
      <!-- subject -->
      <subject>
        <xsl:apply-templates select="/cda:ClinicalDocument/cda:recordTarget" mode="reference" />
      </subject>
      <!-- date -->
      <!-- author -->
      <!-- 20260804 Claude (CDAFHIR-049): predicate extended to require content in originalText. Three RR
           corpus documents carry an RR External Reference whose <code nullFlavor="OTH"> holds an empty
           <originalText/>; the guard tested only for the presence of the code, so xsl:attribute emitted
           <description value=""/> - an ele-1 violation. DocumentReference.description is 0..1 and the
           rr-documentreference profile does not raise that lower bound (the profile's required content for
           an external reference is content.attachment.url, emitted below), so omission is correct. Not a
           DAR case: the OTH nullFlavor sits on the code and is already consumed to select this branch -
           it is not an assertion that the description is unknown. -->
      <!-- 20260804 Claude: separately from the ele-1 guard above, normalise the value. These
           originalText elements are pretty-printed in the source, so the emitted description carried
           the source's own line breaks and indentation into a FHIR string value - e.g. a newline
           followed by 34 spaces mid-sentence, plus a trailing space (itself a validator warning).
           That is serialisation, not data. normalize-space() is what this pipeline already applies to
           originalText everywhere else it is read (see newCreateCodableConcept in
           cda-to-fhir-datatypes.xslt), so the unnormalised path here was the outlier. Deliberately a
           separate commit from the ele-1 fix: nothing here was failing a gate, and it moves 46 snapshot
           lines against the 3 that the actual defect moved. -->
      <!-- 20260821 Claude (item 056): the 20260804 comment above was wrong about the profile -
           rr-documentreference 2.1.2 makes description 1..1 REQUIRED, and three RR corpus documents
           (whose external-reference code is not OTH, or has empty originalText) were failing
           Validation_VAL_Profile_Minimum in production-shaped validation. Per SG's decision
           (2026-08-21): description falls back through the source displayNames, then a constant.
           Order: originalText (the richest, kept from the 049 fix) -> the externalDocument's own
           code/@displayName -> the parent External Resources act's code/@displayName (e.g.
           "Additional Resources", "PHA Contact Information") -> "Public health information" (the
           same wording this template already emits as type.text). -->
      <xsl:variable name="vDescription" select="normalize-space((
          cda:code[@nullFlavor = 'OTH']/cda:originalText[normalize-space(.)],
          cda:code/@displayName[normalize-space(.)],
          ../../cda:code/@displayName[normalize-space(.)],
          'Public health information')[1])" />
      <description>
        <xsl:attribute name="value" select="$vDescription" />
      </description>
      <content>
        <attachment>
          <xsl:choose>
            <xsl:when test="cda:text/cda:reference">
              <!-- 20260824 Claude (B1): guard value-bearing elements at the ELEMENT level so an
                   absent source attribute can never emit value="" (mediaType here, originalText
                   in the data branch below). -->
              <xsl:if test="cda:text/@mediaType">
                <contentType>
                  <xsl:attribute name="value" select="cda:text/@mediaType" />
                </contentType>
              </xsl:if>
              <url>
                <xsl:attribute name="value" select="cda:text/cda:reference/@value" />
              </url>
            </xsl:when>
            <xsl:otherwise>
              <contentType value="text/plain" />
              <xsl:if test="cda:code/cda:originalText[normalize-space()]">
                <data>
                  <xsl:attribute name="value">
                    <xsl:apply-templates select="cda:code/cda:originalText" mode="base64" />
                  </xsl:attribute>
                </data>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </attachment>
      </content>
    </DocumentReference>
    <!--</xsl:for-each>-->
  </xsl:template>
  <!-- create DocumentReference from externalDocument -->
  <xsl:template match="cda:externalDocument">
    <DocumentReference>
      <status value="current" />
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <content>
        <attachment>
          <!-- 20260803 Claude (CDAFHIR-015): the no-setId case used to emit an empty <url/> (comment
               only, no value, no extension) - an invalid empty primitive (ele-1). attachment.url is
               optional, so the element is now omitted entirely; the WARNING comment survives outside it. -->
          <xsl:choose>
            <xsl:when test="cda:setId/@root and cda:versionNumber/@value">
              <url>
                <xsl:attribute name="value" select="concat('urn:hl7ii:', cda:setId/@root, ':', cda:versionNumber/@value)" />
              </url>
            </xsl:when>
            <xsl:when test="cda:setId/@root">
              <url>
                <xsl:attribute name="value" select="concat('urn:oid:', cda:setId/@root)" />
              </url>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>WARNING: URL cannot be determined because CDA document does not have a cda:setId for the cda:externalDocument</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </attachment>
      </content>
    </DocumentReference>
  </xsl:template>
  <!-- 20260424 SG: Create DocumentReference for transform relatedDocument entries -->
  <xsl:template match="cda:relatedDocument[@typeCode = 'XFRM']">
    <DocumentReference>
      <!--      <xsl:call-template name="add-meta" />-->
      <!-- relatedDocument/parentDocument/id -->
      <xsl:comment>DocumentReference.masterIdentifier = ClinicalDocument/id</xsl:comment>
      <xsl:for-each select="cda:parentDocument">
        <xsl:apply-templates select="cda:id">
          <xsl:with-param name="pElementName" select="'masterIdentifier'" />
        </xsl:apply-templates>
        <xsl:comment>DocumentReference.identifier = ClinicalDocument/setId and ClinicalDocument/versionNumber (output as setId:versionNumber)</xsl:comment>

        <!-- ClinicalDocument.setId and versionNumber -->
        <xsl:variable name="vAssigningAuthorityName">
          <xsl:choose>
            <xsl:when test="cda:setId/@assigningAuthorityName">
              <xsl:value-of select="cda:setId/@assigningAuthorityName"/>
            </xsl:when>
            <xsl:when test="cda:id/@assigningAuthorityName">
              <xsl:value-of select="cda:id/@assigningAuthorityName"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="createIdentifierWithVersionNumber" >
          <xsl:with-param name="pAssigningAuthorityName" select="$vAssigningAuthorityName" />
        </xsl:call-template>
        
        <status value="superseded" />
        <!-- type -->
        <xsl:apply-templates select="cda:code">
          <xsl:with-param name="pElementName" select="'type'" />
        </xsl:apply-templates>
        <!-- subject -->
        <subject>
          <xsl:apply-templates select="../../cda:recordTarget" mode="reference" />
        </subject>
        <content>
          <attachment>
            <contentType value="text/plain" />
            <!-- 20261124 Claude (SG decision 2026-11-24, re-trace finding RT-A3): attachment.url is no longer
                 emitted here. It was invented as urn:hl7ii:{setId root}:{versionNumber} (or urn:oid:{root}),
                 which dropped setId/@extension, put the version in the extension slot, and gave every document
                 set under one assigning root the same url. There is no retrievable location for the CDA
                 document; the element is optional; identifier and masterIdentifier carry the same facts
                 correctly. (This also retires the CDAFHIR-015 empty-url handling at this site.) -->
          </attachment>
        </content>
      </xsl:for-each>
    </DocumentReference>
  </xsl:template>
  
  <!-- 20260424 SG: Create DocumentReference for CDA Document -->
  <xsl:template match="cda:ClinicalDocument" mode="doc-ref">
    <DocumentReference>
      <!--      <xsl:call-template name="add-meta" />-->
      <!-- relatedDocument/parentDocument/id -->
      <xsl:comment>DocumentReference.masterIdentifier = ClinicalDocument/id</xsl:comment>
      <xsl:apply-templates select="cda:id">
        <xsl:with-param name="pElementName" select="'masterIdentifier'" />
      </xsl:apply-templates>
      <xsl:comment>DocumentReference.identifier = ClinicalDocument/setId</xsl:comment>
      
      <!-- ClinicalDocument.setId and versionNumber -->
      <xsl:variable name="vAssigningAuthorityName">
        <xsl:choose>
          <xsl:when test="cda:setId/@assigningAuthorityName">
            <xsl:value-of select="cda:setId/@assigningAuthorityName"/>
          </xsl:when>
          <xsl:when test="cda:id/@assigningAuthorityName">
            <xsl:value-of select="cda:id/@assigningAuthorityName"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="createIdentifierWithVersionNumber" >
        <xsl:with-param name="pAssigningAuthorityName" select="$vAssigningAuthorityName" />
      </xsl:call-template>
      <status value="superseded" />
      <!-- type -->
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <!-- category -->
      <!-- subject -->
      <subject>
        <xsl:apply-templates select="cda:recordTarget" mode="reference" />
      </subject>
      <content>
        <attachment>
          <contentType value="text/plain" />
          <!-- 20261124 Claude (SG decision 2026-11-24, re-trace finding RT-A3): attachment.url is no longer
               emitted here; see the note in the relatedDocument template above. -->
        </attachment>
      </content>
    </DocumentReference>
  </xsl:template>
  <!-- create DocumentReference from 2.16.840.1.113883.10.20.15.2.3.10 eICR External Document Reference externalDocument -->
  <xsl:template match="cda:externalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.3.10']">
    <DocumentReference>
      <xsl:call-template name="add-meta" />
      <!-- ClinicalDocument.id -->
      <xsl:apply-templates select="cda:id">
        <xsl:with-param name="pElementName" select="'masterIdentifier'" />
      </xsl:apply-templates>
      <!-- ClinicalDocument.setId and versionNumber (output as setId:versionNumber) -->
      <xsl:call-template name="createIdentifierWithVersionNumber" />
      <status value="current" />
      <!-- type -->
      <xsl:apply-templates select="cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <!-- category -->
      <category>
        <coding>
          <system value="http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category" />
          <code value="clinical-note" />
          <display value="Clinical Note" />
        </coding>
        <text value="Clinical Note" />
      </category>
      <!-- subject -->
      <subject>
        <xsl:apply-templates select="/cda:ClinicalDocument/cda:recordTarget" mode="reference" />
      </subject>
      <content>
        <attachment>
          <contentType value="text/plain" />
          <!-- 20260804 Claude (CDAFHIR-015, FOURTH SITE): see the note in the relatedDocument template. -->
          <!-- 20261124 Claude (SG decision 2026-11-24, re-trace finding RT-A3): this DocumentReference claims
               us-core-documentreference, which needs attachment.url or attachment.data (us-core-6), so the url
               stays here (it was dropped from the unprofiled DocumentReferences above) but is now built
               correctly. It used to be urn:hl7ii:{setId root}:{versionNumber}: the hl7ii form is
               root:extension, so the version sat in the extension slot, setId/@extension was lost, and
               different document sets under one assigning root shared a url. Now root:extension when there
               is an extension; a root-only setId gives urn:uuid: or urn:oid: according to the root's shape.
               The version is not part of the url; it is in identifier (setId extension:version). -->
          <xsl:choose>
            <xsl:when test="cda:setId/@root and cda:setId/@extension">
              <url>
                <xsl:attribute name="value" select="concat('urn:hl7ii:', cda:setId/@root, ':', iri-to-uri(cda:setId/@extension))" />
              </url>
            </xsl:when>
            <xsl:when test="matches(cda:setId/@root, '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')">
              <url>
                <xsl:attribute name="value" select="concat('urn:uuid:', lower-case(cda:setId/@root))" />
              </url>
            </xsl:when>
            <xsl:when test="cda:setId/@root">
              <url>
                <xsl:attribute name="value" select="concat('urn:oid:', cda:setId/@root)" />
              </url>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>WARNING: URL cannot be determined because CDA document does not have a cda:setId for the cda:externalDocument</xsl:comment>
            </xsl:otherwise>
          </xsl:choose>
        </attachment>
      </content>
    </DocumentReference>
  </xsl:template>
  
  <!-- This is a workaround to get versionNumber in -->
  <xsl:template name="createIdentifierWithVersionNumber">
    <xsl:param name="pElementName">identifier</xsl:param>
    <xsl:param name="pAssigningAuthorityName" select="cda:setId/@assigningAuthorityName" />
    
    <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
    <xsl:variable name="root" select="cda:setId/@root" />
    <xsl:variable name="root-uri">
      <xsl:choose>
        <!-- 20260729 Claude: Fix - the predicate was [@oid = cda:setId/$root], a malformed path that evaluated $root as
             a location step and never matched, so the OID-to-URI mapping lookup always fell through to the urn heuristic -->
        <xsl:when test="$mapping/map[@oid = $root]">
          <xsl:value-of select="$mapping/map[@oid = $root][1]/@uri" />
        </xsl:when>
        <xsl:when test="contains($root, '-')">
          <xsl:text>urn:uuid:</xsl:text>
          <xsl:value-of select="$root" />
        </xsl:when>
        <xsl:when test="contains($root, '.')">
          <xsl:text>urn:oid:</xsl:text>
          <xsl:value-of select="$root" />
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="cda:setId/@nullFlavor">
        <!-- TODO: ignore for now, add better handling later -->
      </xsl:when>
      <xsl:when test="cda:setId/@root">
        <xsl:choose>
          <xsl:when test="cda:setId/@extension and cda:versionNumber/@value">
            <xsl:element name="{$pElementName}">
              <system value="{$root-uri}" />
              <value value="{concat(cda:setId/@extension, ':', cda:versionNumber/@value)}" />
              <xsl:if test="string-length($pAssigningAuthorityName) > 0">
                <assigner>
                  <display value="{$pAssigningAuthorityName}" />
                </assigner>
              </xsl:if>
            </xsl:element>
          </xsl:when>
          <!-- 20260424 SG: Added case -->
          <xsl:when test="not(cda:setId/@extension) and cda:versionNumber/@value">
            <xsl:element name="{$pElementName}">
              <system value="urn:ietf:rfc:3986" />
              <value value="{concat($root-uri, ':', cda:versionNumber/@value)}" />
              <xsl:if test="string-length($pAssigningAuthorityName) > 0">
                <assigner>
                  <display value="{$pAssigningAuthorityName}" />
                </assigner>
              </xsl:if>
            </xsl:element>
          </xsl:when>
          <xsl:when test="cda:setId/@extension">
            <xsl:element name="{$pElementName}">
              <system value="{$root-uri}" />
              <value value="{cda:setId/@extension}" />
              <xsl:if test="string-length($pAssigningAuthorityName) > 0">
                <assigner>
                  <display value="{$pAssigningAuthorityName}" />
                </assigner>
              </xsl:if>
            </xsl:element>
          </xsl:when>
          <xsl:when test="not(cda:setId/@extension)">
            <xsl:element name="{$pElementName}">
              <system value="urn:ietf:rfc:3986" />
              <value value="{$root-uri}" />
              <xsl:if test="string-length($pAssigningAuthorityName) > 0">
                <assigner>
                  <display value="{$pAssigningAuthorityName}" />
                </assigner>
              </xsl:if>
            </xsl:element>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
