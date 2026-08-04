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

      <!-- Adding telecom -->
      <xsl:apply-templates select="cda:healthCareFacility/cda:serviceProviderOrganization/cda:telecom" />

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
