<?xml version="1.0" encoding="UTF-8"?>
<!-- 

Copyright 2020 Lantana Consulting Group

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<xsl:stylesheet xmlns="urn:hl7-org:v3" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
    exclude-result-prefixes="lcg xsl cda fhir">


    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-ADDR.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />


    <!-- fhir:author[parent::fhir:Composition] | fhir:sender[parent::fhir:Communication] | fhir:author[parent::fhir:QuestionnaireResponse] -> get referenced resource entry url and process -->
    <!-- SG 20231122: Added fhir:requester[parent::fhir:ServiceRequest] -->
    <xsl:template match="fhir:author[parent::fhir:Composition] | fhir:sender[parent::fhir:Communication] | fhir:author[parent::fhir:QuestionnaireResponse] | fhir:requester[parent::fhir:ServiceRequest]">
        <!-- check author Parent Resource -->
        <xsl:variable name="vAuthorParent" select="../local-name()" />
        <!-- SG 20231122: Add code to get parent id - won't only be one of everying (e.g. ServiceRequest) -->
        <xsl:variable name="vAuthorParentId" select="../fhir:id/@value" />

        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:comment>Author <xsl:value-of select="$referenceURI" /></xsl:comment>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="author">
                    <xsl:with-param name="pAuthorParent" select="$vAuthorParent" />
                    <xsl:with-param name="pAuthorParentId" select="$vAuthorParentId" />
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- fhir:Patient -> cda:author -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Patient" mode="author">
        <xsl:param name="pAuthorParent" />
        <xsl:param name="pAuthorParentId" />
        <xsl:call-template name="make-author">
            <xsl:with-param name="pAuthorParent" select="$pAuthorParent" />
            <xsl:with-param name="pAuthorParentId" select="$pAuthorParentId" />
        </xsl:call-template>
    </xsl:template>

    <!-- fhir:Practitioner -> cda:author -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Practitioner" mode="author">
        <xsl:param name="pAuthorParent" />
        <xsl:param name="pPractitionerRole" />
        <xsl:call-template name="make-author">
            <xsl:with-param name="pAuthorParent" select="$pAuthorParent" />
        </xsl:call-template>
    </xsl:template>

    <!-- fhir:Organization -> cda:author -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Organization" mode="author">
        <xsl:param name="pAuthorParent" />
        <xsl:param name="pAuthorParentId" />
        <xsl:call-template name="make-author">
            <xsl:with-param name="pAuthorParent" select="$pAuthorParent" />
            <xsl:with-param name="pAuthorParentId" select="$pAuthorParentId" />
        </xsl:call-template>
    </xsl:template>

    <!-- fhir:PractitionerRole -> cda:author -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:PractitionerRole" mode="author">

        <!-- NOTE: There is a mix of different data from the PractitionerRole, Practitioner, Organization, and 
                Location involved in building up author. Easier to put the data into variables to mix and 
                match. Could consider a refactor later to get back to original design -->
        <!-- Get the URL for the related Practitioner - there can only ever be one -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:practitioner/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Put the Practitioner node into a variable so we can use it to build author -->
        <xsl:variable name="vPractitioner" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />

        <!-- Get the URL for the related Organization - there can only ever be one -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:organization/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Put the Organization node into a variable so we can use it to build author -->
        <xsl:variable name="vOrganization" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

        <author>
            <xsl:choose>
                <xsl:when test="//fhir:Composition/fhir:date">
                    <xsl:call-template name="get-time">
                        <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                        <xsl:with-param name="pElement" select="//fhir:Composition/fhir:date" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="//fhir:QuestionnaireResponse/fhir:authored">
                    <xsl:call-template name="get-time">
                        <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                        <xsl:with-param name="pElement" select="//fhir:QuestionnaireResponse/fhir:authored" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="//fhir:Communication/fhir:sent">
                    <xsl:call-template name="get-time">
                        <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                        <xsl:with-param name="pElement" select="//fhir:Communication/fhir:sent" />
                    </xsl:call-template>
                </xsl:when>

            </xsl:choose>
            <!--  
      
      Old comment: Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! 
      RG: Yup, that was absolutely the case! Had to change to a choice
      <xsl:call-template name="get-time">
        <xsl:with-param name="pElement" select="//fhir:Composition/fhir:date | //fhir:QuestionnaireResponse/fhir:authored | //fhir:Communication/fhir:sent" />
      </xsl:call-template>
      -->
            <assignedAuthor>
                <xsl:call-template name="get-id">
                    <xsl:with-param name="pElement" select="fhir:identifier | $vPractitioner/fhir:identifier" />
                </xsl:call-template>
                <!--<xsl:choose>
          <xsl:when test="fhir:identifier or $vPractitioner/fhir:identifier">
            <xsl:apply-templates select="fhir:identifier" />
            <xsl:apply-templates select="$vPractitioner/fhir:identifier" />
          </xsl:when>
          <xsl:otherwise>
            <id nullFlavor="NI" />
          </xsl:otherwise>
        </xsl:choose>-->
                <xsl:apply-templates select="fhir:code" />
                <!-- PractitionerRole doesn't have an address, this will come from Practitioner (TODO - organization, location?) -->
                <xsl:call-template name="get-addr">
                    <xsl:with-param name="pElement" select="$vPractitioner/fhir:address" />
                </xsl:call-template>
                <xsl:call-template name="get-telecom">
                    <xsl:with-param name="pElement" select="fhir:telecom | $vPractitioner/fhir:telecom" />
                </xsl:call-template>
                <!--<xsl:apply-templates select="fhir:telecom | $vPractitioner/fhir:telecom" />-->
                <assignedPerson>
                    <xsl:apply-templates select="$vPractitioner/fhir:name" />
                </assignedPerson>
                <xsl:if test="$vOrganization">
                    <representedOrganization>
                        <xsl:call-template name="get-id">
                            <!-- address a duplicate Organization issue -->
                            <xsl:with-param name="pElement" select="$vOrganization[1]/fhir:identifier" />
                        </xsl:call-template>
                        <xsl:call-template name="get-org-name">
                            <!-- address a duplicate Organization issue -->
                            <xsl:with-param name="pElement" select="$vOrganization[1]/fhir:name" />
                        </xsl:call-template>
                        <!-- SG 2023-04 Get address -->
                        <!-- address a duplicate Organization issue -->
                        <xsl:for-each select="$vOrganization[1]/fhir:address[1]">
                            <xsl:call-template name="get-addr">
                                <xsl:with-param name="pElement" select="." />
                            </xsl:call-template>
                        </xsl:for-each>
                    </representedOrganization>
                </xsl:if>
            </assignedAuthor>
        </author>
    </xsl:template>

    <!-- Device -->
    <!-- Get the organization out of device and use here 
       This is only for RR because there is nothing in a Communication for a custodian
       so use the owner of the Author device -->
    <xsl:template match="fhir:entry/fhir:resource/fhir:Device" mode="custodian">

        <!-- Get the URL for the related Organizer (owner) - there can only ever be one -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:owner/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <!-- Put the Organization node into a variable so we can use it to build author -->
        <xsl:variable name="vOrganization" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

        <custodian>
            <assignedCustodian>
                <representedCustodianOrganization>
                    <xsl:call-template name="get-id">
                        <xsl:with-param name="pElement" select="$vOrganization/fhir:identifier" />
                    </xsl:call-template>
                    <!--          <id nullFlavor="UNK" />-->
                    <xsl:call-template name="get-org-name">
                        <xsl:with-param name="pElement" select="$vOrganization/fhir:name" />
                    </xsl:call-template>
                    <xsl:call-template name="get-telecom">
                        <xsl:with-param name="pElement" select="$vOrganization/fhir:telecom" />
                    </xsl:call-template>
                    <xsl:call-template name="get-addr">
                        <xsl:with-param name="pElement" select="$vOrganization/fhir:address" />
                    </xsl:call-template>
                </representedCustodianOrganization>
            </assignedCustodian>
        </custodian>
    </xsl:template>

    <xsl:template match="fhir:entry/fhir:resource/fhir:Device" mode="author">
        <author>
            <xsl:call-template name="get-time">
                <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                <xsl:with-param name="pElement" select="//fhir:Composition/fhir:date | //fhir:QuestionnaireResponse/fhir:authored | //fhir:Communication/fhir:sent" />
            </xsl:call-template>
            <assignedAuthor>
                <!-- id comes from Device -->
                <xsl:call-template name="get-id" />
                <xsl:choose>
                    <!-- if there's a location get addr, and telecom from there -->
                    <xsl:when test="fhir:location">
                        <xsl:apply-templates select="fhir:location" mode="author" />
                    </xsl:when>
                    <xsl:when test="fhir:contact">
                        <xsl:apply-templates select="fhir:contact" />
                    </xsl:when>
                </xsl:choose>


                <assignedAuthoringDevice>
                    <xsl:choose>
                        <xsl:when test="fhir:modelNumber[@value]">
                            <manufacturerModelName displayName="{fhir:modelNumber/@value}" />
                        </xsl:when>
                        <xsl:otherwise>
                            <manufacturerModelName nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:choose>
                        <xsl:when test="fhir:version/fhir:value/@value">
                            <softwareName displayName="{fhir:version/fhir:value/@value}" />
                        </xsl:when>
                        <xsl:otherwise>
                            <softwareName nullFlavor="NI" />
                        </xsl:otherwise>
                    </xsl:choose>
                </assignedAuthoringDevice>
            </assignedAuthor>
        </author>
    </xsl:template>

    <!-- fhir:location -> get referenced resource entry url and process -->
    <xsl:template match="fhir:location" mode="author">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="author" />
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:entry/fhir:resource/fhir:Location" mode="author">
        <xsl:call-template name="get-addr" />
        <xsl:call-template name="get-telecom" />
    </xsl:template>

    <xsl:template name="make-author">
        <xsl:param name="pElementName">author</xsl:param>
        <xsl:param name="pPractitionerRoleTelecom" />
        <xsl:param name="pAuthorParent" />
        <xsl:param name="pAuthorParentId" />

        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$pAuthorParent = 'Composition'">
                    <xsl:call-template name="get-time">
                        <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                        <!-- Add check for the parent resource, to avoid multiple time validation error. We may need to do some more for
                            the otherwise branch. for now just fix for Composition author. 
                            <xsl:with-param name="pElement" select="//fhir:Composition/fhir:date | 
                            //fhir:QuestionnaireResponse/fhir:authored |
                            //fhir:Communication/fhir:sent" /> 
                          -->
                        <xsl:with-param name="pElement" select="//fhir:Composition/fhir:date" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$pAuthorParent = 'ServiceRequest'">
                    <xsl:comment select="' [C-CDA R2.0] Author Participation '" />
                    <templateId root="2.16.840.1.113883.10.20.22.4.119" />

                    <xsl:call-template name="get-time">
                        <xsl:with-param name="pElement" select="//fhir:ServiceRequest[fhir:id/@value = $pAuthorParentId]/fhir:authoredOn" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="get-time">
                        <!-- Assuming we are never going to have more than one of these at a time in one bundle.. Could be wrong though! -->
                        <!-- with //fhir:Communication/fhir:sent cause more time entry  for now just pass //fhir:Conposition/fhir:date -->
                        <xsl:with-param name="pElement" select="//fhir:QuestionnaireResponse/fhir:authored | //fhir:Communication/fhir:sent" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <assignedAuthor>
                <xsl:call-template name="get-id" />
                <xsl:call-template name="get-addr" />
                <xsl:call-template name="get-telecom" />
                <xsl:if test="local-name() != 'Organization'">
                    <assignedPerson>
                        <xsl:apply-templates select="fhir:name" />
                    </assignedPerson>
                </xsl:if>
                <!-- SG 20231123: Check for Organization and add it -->
                <xsl:if test="local-name() = 'Organization'">
                    <representedOrganization>
                        <xsl:call-template name="get-id" />
                        <xsl:call-template name="get-org-name" />
                    </representedOrganization>
                </xsl:if>
            </assignedAuthor>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
