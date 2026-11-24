<?xml version="1.0" encoding="UTF-8"?>
<!-- 20260729 Claude: the three priority values here were raised 1 -> 2. cda2fhir-Organization.xslt now claims all
     cda:participant[@typeCode='LOC'] at priority 1 as a generic LOC -> Organization fallback, so these specific
     location templates (eICR Location Participant 15.2.4.4, and Service Delivery Location 4.32 whose templateId sits
     on the participantRole) need to outrank it. Precedence is now: Location 2 > Organization 1 > PractitionerRole 0. -->
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com" exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

  <xsl:template match="cda:location" mode="bundle-entry">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20260729 Claude: added priority="2" to the Location participant templates (here and the body template below) so
       they beat cda2fhir-PractitionerRole.xslt's generic cda:participant[cda:participantRole] match (equal default
       priority; include order previously decided the winner) -->
  <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.4']]" mode="bundle-entry" priority="2">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20260729 Claude: Fix - matched cda:participant[cda:templateId 4.32], but the Service Delivery Location templateId
       is on the participantRole (the body template below already uses the participantRole axis, as does
       cda2fhir-Procedure.xslt), so this bundle-entry never fired and the Location entry referenced from
       Procedure.location was never created -->
  <xsl:template match="cda:participant[cda:participantRole/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.32']]" mode="bundle-entry" priority="2">
    <xsl:call-template name="create-bundle-entry" />
  </xsl:template>

  <!-- 20261124 Claude (re-trace findings RT-A14/RT-A15, SG decision 2026-11-24): an eICR document
       can list additional facilities visited during the encounter as header participants
       (typeCode LOC, associatedEntity classCode SDLOC, Vol 2 CONF:4527-1040 to 1053). Each becomes a
       Location, built the same way as the first location (cda:location below) and added to
       Encounter.location in cda2fhir-Encounter.xslt. Priority 3 so it outranks the generic
       LOC -> Organization fallback (1), which only reads participantRole and so produced an empty
       Organization here. The entry for the umbrella organization (scopingOrganization) is created
       here as well, because nothing else reaches it. -->
  <xsl:template match="cda:ClinicalDocument/cda:participant[@typeCode = 'LOC'][cda:associatedEntity[@classCode = 'SDLOC']]" mode="bundle-entry" priority="3">
    <xsl:call-template name="create-bundle-entry" />
    <xsl:for-each select="cda:associatedEntity/cda:scopingOrganization[not(@nullFlavor)]">
      <xsl:call-template name="create-bundle-entry" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="cda:ClinicalDocument/cda:participant[@typeCode = 'LOC'][cda:associatedEntity[@classCode = 'SDLOC']]" priority="3">
    <xsl:variable name="vRole" select="cda:associatedEntity" />
    <Location>
      <!-- Same profile, under the same document-version rule, as the first location: look up the
           first location's key in participant-profile-mapping.xml for each document templateId. -->
      <xsl:variable name="vApos" as="xs:string">'</xsl:variable>
      <xsl:variable name="vProfiles" as="xs:string*">
        <xsl:for-each select="/cda:ClinicalDocument/cda:templateId">
          <xsl:variable name="vKey"
            select="concat('ClinicalDocument[templateId/@root=', $vApos, @root, $vApos, ']', if (@extension) then concat('[templateId/@extension=', $vApos, @extension, $vApos, ']') else '', '/componentOf/encompassingEncounter/location')" />
          <xsl:sequence select="$participant-profile-mapping/map[@participantXPath = $vKey]/@profileURI/string()" />
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="exists($vProfiles)">
        <meta>
          <xsl:for-each select="distinct-values($vProfiles)">
            <profile value="{.}" />
          </xsl:for-each>
        </meta>
      </xsl:if>
      <xsl:apply-templates select="$vRole/cda:id" />
      <!-- This structure has no facility name; Location.name is 1..1 in us-ph-location, so the
           umbrella organization's name is used (the same fallback the first location uses). -->
      <xsl:if test="$vRole/cda:scopingOrganization/cda:name/text()">
        <name value="{$vRole/cda:scopingOrganization/cda:name}" />
      </xsl:if>
      <xsl:apply-templates select="$vRole/cda:code[not(@nullFlavor)]">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <!-- The facility's own address only. The organization's address stays on the Organization. -->
      <xsl:apply-templates select="$vRole/cda:addr" />
      <xsl:if test="$vRole/cda:scopingOrganization[not(@nullFlavor)]">
        <managingOrganization>
          <reference value="urn:uuid:{$vRole/cda:scopingOrganization/@lcg:uuid}" />
        </managingOrganization>
      </xsl:if>
    </Location>
  </xsl:template>

  <xsl:template match="cda:location">

    <Location>
      <xsl:call-template name="add-participant-meta" />

      <xsl:apply-templates select="cda:healthCareFacility/cda:id" />
      <xsl:choose>
        <xsl:when test="cda:healthCareFacility/cda:location/cda:name/text()">
          <name value="{cda:healthCareFacility/cda:location/cda:name}" />
        </xsl:when>
        <xsl:when test="cda:healthCareFacility/cda:serviceProviderOrganization/cda:name/text()">
          <name value="{cda:healthCareFacility/cda:serviceProviderOrganization/cda:name}" />
        </xsl:when>
      </xsl:choose>

      <!-- Adding type -->
      <!-- Added parameter elementName -->
      <xsl:apply-templates select="cda:healthCareFacility/cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <!-- If this is eICR let's see if there is another type in the Encounter Activities -->
      <!-- 20260803 Claude (CDAFHIR-019): kept eICR-only (there the 4.49 activities are deduplicated
           into the document encounter, so their service-delivery-location types legitimately describe
           THIS encounter's facility), but now grouped by codeSystem+code: multiple activities usually
           repeat the same SDLOC code, and each repeat emitted a duplicate Location.type. Also skip
           null-flavored codes, which produced empty type elements. -->
      <xsl:if test="$gvCurrentIg = 'eICR'">
        <xsl:for-each-group
          select="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:participant[@typeCode = 'LOC']/cda:participantRole[@classCode = 'SDLOC']/cda:code[not(@nullFlavor)]"
          group-by="concat(@codeSystem, '|', @code)">
          <xsl:apply-templates select=".">
            <xsl:with-param name="pElementName" select="'type'" />
          </xsl:apply-templates>
        </xsl:for-each-group>
      </xsl:if>

      <!-- 20261124 Claude (SG decision 2026-11-24, re-trace finding RT-C11): the telecom of
           serviceProviderOrganization is no longer copied here. That element is the umbrella
           organization the facility operates under (Vol 2 CONF:4527-16/34), not the facility; CDA has
           no telecom on healthCareFacility and Location.telecom is optional in us-ph-location. The
           organization (with its telecom) is reachable through managingOrganization below. The NAME
           fallback above is kept on purpose: Location.name is 1..1 and the facility name is optional
           in the CDA (CONF:4527-1149). -->

      <xsl:variable name="vLocationAddr" select="cda:healthCareFacility/cda:location/cda:addr" />

      <!-- SG 2023-06-05 If there is no non-null address in location, check in serviceProviderOrganization -->
      <xsl:choose>
        <xsl:when test="$vLocationAddr/cda:postalCode[not(@nullFlavor)] or $vLocationAddr/cda:streetAddressLine[not(@nullFlavor)]">
          <xsl:apply-templates select="cda:healthCareFacility/cda:location/cda:addr" />
        </xsl:when>
        <xsl:when test="cda:healthCareFacility/cda:serviceProviderOrganization/cda:addr">
          <xsl:apply-templates select="cda:healthCareFacility/cda:serviceProviderOrganization/cda:addr" />
        </xsl:when>
      </xsl:choose>

      <!-- 20261124 Claude (RT-C11): link the facility to its umbrella organization. Same condition
           and target as Encounter.serviceProvider (cda2fhir-Encounter.xslt), which is what creates
           the Organization entry, so the reference always resolves. -->
      <xsl:if test="cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]">
        <managingOrganization>
          <reference value="urn:uuid:{cda:healthCareFacility/cda:serviceProviderOrganization/@lcg:uuid}" />
        </managingOrganization>
      </xsl:if>
    </Location>
  </xsl:template>

  <xsl:template match="cda:assignedAuthor[cda:assignedAuthoringDevice]">
    <!-- 20260423 SG: Unless there is data, do not create a location -->
    <xsl:if test="cda:representedOrganization/cda:name/text() or cda:telecom[not(@nullFlavor='NA')] or cda:addr[not(@nullFlavor='NA')]">
      <entry>
        <fullUrl value="urn:uuid:{@lcg:uuid}" />
        <resource>
          <Location>
            <xsl:call-template name="add-participant-meta" />
            <xsl:choose>
              <xsl:when test="cda:representedOrganization/cda:name/text()">
                <name value="{cda:representedOrganization/cda:name}" />
              </xsl:when>
              <xsl:otherwise>
                <!-- 20260731 Claude: defect item 42 - an authoring DEVICE's assignedAuthor usually carries only
                     an id/addr/telecom and no representedOrganization, so this Location (referenced from
                     Device.location) was emitted with no name at all: 17 of 34 corpus documents. The source
                     genuinely has no name, so per the pipeline's convention for required-but-absent data
                     (US Core expects Location.name 1..1) emit the data-absent-reason extension rather than
                     inventing a value. -->
                <name>
                  <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                    <valueCode value="unknown" />
                  </extension>
                </name>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:telecom" />
            <xsl:apply-templates select="cda:addr" />
          </Location>
        </resource>
      </entry>
    </xsl:if>
  </xsl:template>

  <!-- (eICR) Location Participant to US Core Location -->
  <xsl:template match="cda:participant[cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.4.4']] | cda:participant[cda:participantRole/cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.32']]" priority="2">
    <Location>
      <!-- 20260729 Claude: Fix - add-meta reads cda:templateId children of the context node, but for a Service
           Delivery Location (2.16.840.1.113883.10.20.22.4.32) the templateId sits on the participantRole, so this
           always fell to add-meta's otherwise branch: no meta.profile, plus a "No profiles found" comment listing
           nothing. Without us-ph-location the Location cannot satisfy Encounter.location.location in eicr-encounter.
           Resolved through get-profile-for-ig (the house pattern for IG-dependent profiles), falling back to
           add-meta for the 15.2.4.4 eICR Location Participant, whose templateId IS on the participant and which
           template-profile-mapping.xml already covers. -->
      <xsl:choose>
        <xsl:when test="cda:templateId">
          <xsl:call-template name="add-meta" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="vProfileValue">
            <xsl:call-template name="get-profile-for-ig">
              <xsl:with-param name="pIg" select="$gvCurrentIg" />
              <xsl:with-param name="pResource" select="'Location'" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="$vProfileValue ne 'NA'">
            <meta>
              <profile value="{$vProfileValue}" />
            </meta>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <!-- 20260729 Claude: Fix - participantRole/id was dropped; us-ph-location requires identifier 1..*, and the
           facility id is the only stable identity a Service Delivery Location carries -->
      <xsl:apply-templates select="cda:participantRole/cda:id" />

      <!-- 20260729 Claude: Fix - added participantRole/playingEntity/name (the actual location name in a Service
           Delivery Location) ahead of the preceding-sibling value fallbacks; previously procedure SDL participants
           always fell through to the hard-coded 'Unknown' -->
      <name>
        <xsl:choose>
          <xsl:when test="cda:participantRole/cda:playingEntity/cda:name/text()">
            <xsl:attribute name="value" select="cda:participantRole/cda:playingEntity/cda:name[1]" />
          </xsl:when>
          <xsl:when test="preceding-sibling::cda:value/cda:originalText">
            <xsl:attribute name="value" select="preceding-sibling::cda:value/cda:originalText" />
          </xsl:when>
          <xsl:when test="preceding-sibling::cda:value/@displayName">
            <xsl:attribute name="value" select="preceding-sibling::cda:value/@displayName" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="value" select="'Unknown'" />
          </xsl:otherwise>
        </xsl:choose>
      </name>
      <!-- 20260729 Claude: Fix - participantRole/code (the Service Delivery Location's facility type, bound to
           HealthcareServiceLocation) was dropped entirely; us-ph-location requires type 1..*. Same pElementName
           mechanism the encompassingEncounter Location template above uses for healthCareFacility/code. -->
      <xsl:apply-templates select="cda:participantRole/cda:code">
        <xsl:with-param name="pElementName" select="'type'" />
      </xsl:apply-templates>
      <xsl:apply-templates select="cda:participantRole/cda:telecom" />
      <xsl:apply-templates select="cda:participantRole/cda:addr" />
    </Location>
  </xsl:template>
</xsl:stylesheet>
