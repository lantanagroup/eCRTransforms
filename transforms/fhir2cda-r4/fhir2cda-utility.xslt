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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda xsi fhir xhtml sdtc" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-II.xslt" />
    <xsl:import href="fhir2cda-ADDR.xslt" />
    <xsl:import href="fhir2cda-PN.xslt" />
    <xsl:import href="fhir2cda-ON.xslt" />
    <xsl:import href="fhir2cda-PQ.xslt" />
    <xsl:import href="fhir2cda-TEL.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />

    <xsl:import href="native-xslt-uuid.xslt" />

    <xsl:param name="lab-obs-status-mapping-file">../lab-obs-status-mapping.xml</xsl:param>
    <xsl:param name="lab-status-mapping-file">../lab-status-mapping.xml</xsl:param>
    <xsl:param name="questionnaire-mapping-file">../questionnaire-mapping.xml</xsl:param>
    <xsl:param name="section-title-mapping-file">../section-title-mapping.xml</xsl:param>

    <xsl:variable name="lab-status-mapping" select="document($lab-status-mapping-file)/mapping" />
    <xsl:variable name="lab-obs-status-mapping" select="document($lab-obs-status-mapping-file)/mapping" />
    <xsl:variable name="questionnaire-mapping" select="document($questionnaire-mapping-file)/mapping" />
    <xsl:variable name="section-title-mapping" select="document($section-title-mapping-file)/mapping" />

    <!-- Get the HAI Document Questionnaire URL (**TODO** - might not use this and just use the select all the time) -->
    <xsl:variable name="gvQuestionnaireUrl" select="//fhir:QuestionnaireResponse/fhir:questionnaire/@value" />

    <!-- Put the contents of the Questionnaire resource instance into a global variable -->
    <xsl:variable name="gvHaiQuestionnaire">
        <xsl:copy-of select="document($gvQuestionnaireUrl)/fhir:Questionnaire" />
    </xsl:variable>

    <xsl:template name="get-current-ig">
        <!-- Identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:choose>
            <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition'">eICR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '55751-2'">eICR</xsl:when>
            <xsl:when test="//fhir:Communication/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-composition'">RR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '88085-6'">RR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Care-Plan'">PCP</xsl:when>
            <!-- Not sure if we will need to distinguish between HAI, HAI LTCF, single person, summary - for now, putting them all in the same bucket-->
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-single-person-report-questionnaireresponse'">HAI</xsl:when>
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai/StructureDefinition/hai-population-summary-questionnaireresponse'">HAI</xsl:when>
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai-ltcf/StructureDefinition/hai-ltc-single-person-report-questionnaireresponse'">HAI</xsl:when>
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/hai-ltcf/StructureDefinition/hai-ltc-population-summary-questionnaireresponse'">HAI</xsl:when>
            <!-- SG 20230206: Adding in Questionnaire in case the meta/profile isn't present -->
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event'">HAI</xsl:when>
            <xsl:when test="//fhir:QuestionnaireResponse/fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary'">HAI</xsl:when>

            <!-- MD: using Composition.meta.profile or Composition.type.coding.code to identify detal data exchange IG -->
            <xsl:when test="
                    //fhir:Composition/fhir:meta/fhir:profile/@value =
                    'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-referral-note'">DentalReferalNote</xsl:when>
            <xsl:when test="
                    //fhir:Composition/fhir:meta/fhir:profile/@value =
                    'http://hl7.org/fhir/us/dental-data-exchange/StructureDefinition/dental-consult-note'">DentalConsultNote</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '57134-9'">DentalReferalNote</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '34756-7'">DentalConsultNote</xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- Check to see if this is a trigger code template -->
    <xsl:template name="check-for-trigger">
        <xsl:variable name="vTriggerEntry">
            <xsl:call-template name="get-associated-trigger-extension" />
        </xsl:variable>
        <xsl:variable name="vAssociatedTriggerExtension" select="$vTriggerEntry/fhir:extension" />

        <!-- Get all codes in the profile -->
        <xsl:variable name="vCodesToMatch" select="descendant::*/fhir:coding/fhir:code/@value" />
        <!-- Check current Resource code against the trigger codes in the associated extensions -->
        <xsl:copy-of select="$vAssociatedTriggerExtension[fhir:extension//fhir:code/@value = $vCodesToMatch]" />
    </xsl:template>

    <xsl:template name="get-associated-trigger-extension">
        <xsl:variable name="vTriggerExtensionUrl" select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-trigger-code-flag-extension'" />
        <!-- This profile might have been contained in another profile, need to get to top of tree for match -->
        <xsl:variable name="vFullUrl">
            <xsl:value-of select="../../fhir:fullUrl/@value" />
        </xsl:variable>
        <!-- Get the relative url because sometimes it's used in the reference -->
        <xsl:variable name="vRelativeUrl">
            <xsl:value-of select="tokenize($vFullUrl, '/')[position() &gt;= last() - 1]" separator="/" />
        </xsl:variable>
        <xsl:choose>
            <!-- This means we need to move up the tree -->
            <xsl:when test="//fhir:hasMember[fhir:reference/@value = $vFullUrl]">
                <xsl:for-each select="//fhir:*[fhir:hasMember[fhir:reference/@value = $vFullUrl]]">
                    <xsl:call-template name="get-associated-trigger-extension" />
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="//fhir:entry[fhir:reference/@value = $vFullUrl]/fhir:extension[@url = $vTriggerExtensionUrl]">
                <xsl:copy-of select="//fhir:entry[fhir:reference/@value = $vFullUrl]/fhir:extension[@url = $vTriggerExtensionUrl]" />
            </xsl:when>

            <!-- Could also be a relative reference in the section.entry -->
            <xsl:when test="//fhir:entry[fhir:reference/@value = $vRelativeUrl]/fhir:extension[@url = $vTriggerExtensionUrl]">
                <xsl:copy-of select="//fhir:entry[fhir:reference/@value = $vRelativeUrl]/fhir:extension[@url = $vTriggerExtensionUrl]" />
            </xsl:when>


            <xsl:when test="//fhir:diagnosis[fhir:condition/fhir:reference/@value = $vFullUrl]/fhir:extension[@url = $vTriggerExtensionUrl]">
                <xsl:copy-of select="//fhir:diagnosis[fhir:condition/fhir:reference/@value = $vFullUrl]/fhir:extension[@url = $vTriggerExtensionUrl]" />
            </xsl:when>

            <!-- Could also be a relative reference in Encounter.diagnosis -->
            <xsl:when test="//fhir:diagnosis[fhir:condition/fhir:reference/@value = $vRelativeUrl]/fhir:extension[@url = $vTriggerExtensionUrl]">
                <xsl:copy-of select="//fhir:diagnosis[fhir:condition/fhir:reference/@value = $vRelativeUrl]/fhir:extension[@url = $vTriggerExtensionUrl]" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="convertURI">
        <xsl:param name="uri" />
        <xsl:variable name="mapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />
        <xsl:choose>
            <xsl:when test="$mapping/map[@uri = $uri]">
                <xsl:value-of select="$mapping/map[@uri = $uri][1]/@oid" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="starts-with($uri, 'urn:oid')">
                        <xsl:value-of select="substring-after($uri, 'urn:oid:')" />
                    </xsl:when>
                    <xsl:when test="starts-with($uri, 'urn:uuid')">
                        <xsl:value-of select="substring-after($uri, 'urn:uuid:')" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$uri" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="resolve-to-full-url">
        <xsl:param name="referenceURI" select="fhir:reference/@value" />
        <xsl:param name="entryFullUrl" select="ancestor::fhir:entry[parent::fhir:Bundle][1]/fhir:fullUrl/@value" />
        <xsl:param name="currentResourceType" select="local-name(ancestor::fhir:entry[parent::fhir:Bundle][1]/fhir:resource/fhir:*)" />
        <xsl:message>../<xsl:value-of select="local-name(.)" /></xsl:message>
        <xsl:for-each select="parent::*">
            <xsl:message>../<xsl:value-of select="local-name(.)" /></xsl:message>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="starts-with($referenceURI, 'http:')">
                <xsl:call-template name="remove-history-from-url">
                    <xsl:with-param name="fullURL" select="$referenceURI" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="starts-with($referenceURI, 'https:')">
                <xsl:call-template name="remove-history-from-url">
                    <xsl:with-param name="fullURL" select="$referenceURI" />
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="starts-with($referenceURI, 'urn:')">
                <xsl:value-of select="$referenceURI" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="fhirBaseUrl" select="substring-before($entryFullUrl, $currentResourceType)" />

                <xsl:message> referenceURI: <xsl:value-of select="$referenceURI" /> entryFullUrl: <xsl:value-of select="$entryFullUrl" /> currentResourceType: <xsl:value-of select="$currentResourceType" /> fhirBaseUrl: <xsl:value-of select="$fhirBaseUrl" />
                </xsl:message>
                <!--
        <xsl:message>$entryFullUrl=<xsl:value-of select="$entryFullUrl"/>, $currentResourceType=<xsl:value-of select="$currentResourceType"/>, $fhirBaseUrl=<xsl:value-of select="$fhirBaseUrl"/></xsl:message>
        -->
                <!-- **TODO** Why are there two value-of here?? Only the last one will get used... Maybe I'm missing something -->
                <!-- RG: There are two values because it means that the reference is a relative URL (i.e. Observation/1 instead of http://some.server.org/fhir/Observation/1), not a full URL, so need to prepend the base which is $fhirBaseUrl -->
                <xsl:value-of select="$fhirBaseUrl" />
                <xsl:value-of select="$referenceURI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="resolve-reference">
        <xsl:param name="referenceURI" select="fhir:reference/@value" />
        <xsl:param name="entryFullUrl" select="ancestor::fhir:entry[parent::fhir:Bundle][1]/fhir:fullUrl/@value" />
        <xsl:param name="currentResourceType" select="local-name(ancestor::fhir:entry[parent::fhir:Bundle][1]/fhir:resource/fhir:*)" />
        <xsl:message>Attempting to resolve <xsl:value-of select="fhir:reference/@value" /></xsl:message>
        <xsl:choose>
            <xsl:when test="starts-with($referenceURI, '#')">
                <xsl:variable name="id" select="substring-after($referenceURI, '#')" />
                <xsl:apply-templates mode="copy" select="ancestor::fhir:entry[1]/fhir:resource/fhir:*/fhir:contained/fhir:*[fhir:id/@value = $id]" />

            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="fullUrl">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="$referenceURI" />
                        <xsl:with-param name="entryFullUrl" select="$entryFullUrl" />
                        <xsl:with-param name="currentResourceType" select="$currentResourceType" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:message>Evaluated <xsl:value-of select="fhir:reference/@value" /> to <xsl:value-of select="$fullUrl" /></xsl:message>
                <xsl:apply-templates mode="copy" select="//fhir:entry[fhir:fullUrl/@value = $fullUrl]/fhir:resource/fhir:*" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@* | node()" mode="copy">
        <xsl:copy>
            <xsl:apply-templates mode="copy" select="@* | node()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template name="remove-history-from-url">
        <xsl:param name="fullURL" />
        <xsl:choose>
            <xsl:when test="contains($fullURL, '/_history/')">
                <xsl:value-of select="substring-before($fullURL, '/_history/')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$fullURL" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="make-performer">
        <xsl:param name="pElementName" select="'performer'" />
        <xsl:param name="pTypeCode" select="'PRF'" />
        <xsl:param name="pPerformerTime" />
        <xsl:param name="pOrganization" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="typeCode" select="$pTypeCode" />
            <xsl:if test="$pPerformerTime">
                <time value="{pPerformerTime}" />
            </xsl:if>
            <assignedEntity>
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:choose>
                    <xsl:when test="fhir:address">
                        <xsl:apply-templates select="fhir:address" />
                    </xsl:when>
                    <xsl:otherwise>
                        <addr>
                            <streetAddressLine nullFlavor="NI" />
                            <city nullFlavor="NI" />
                            <state nullFlavor="NI" />
                            <postalCode nullFlavor="NI" />
                        </addr>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates select="fhir:telecom" />
                <!--<telecom value="{fhir:telecom/fhir:value/@value}">
          <xsl:call-template name="telecomUse">
            <xsl:with-param name="use" select="fhir:telecom/@use" />
          </xsl:call-template>
        </telecom>-->
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
            </assignedEntity>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:effectivePeriod | fhir:period | fhir:collectedPeriod | fhir:performedPeriod | fhir:valuePeriod">
        <!-- CDA element effectiveTime unless specified something else -->
        <xsl:param name="pElementName" select="'effectiveTime'" />
        <!-- This might be cast to a specific xsi-type in the cda -->
        <xsl:param name="pXSIType" />
        <xsl:param name="pOperator" />

        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:if test="$pOperator">
                <xsl:attribute name="operator" select="$pOperator" />
            </xsl:if>
            <low>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="fhir:start/@value" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </low>
            <xsl:if test="fhir:end">
                <high>
                    <xsl:attribute name="value">
                        <xsl:call-template name="Date2TS">
                            <xsl:with-param name="date" select="fhir:end/@value" />
                            <xsl:with-param name="includeTime" select="true()" />
                        </xsl:call-template>
                    </xsl:attribute>
                </high>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:effectiveDateTime | fhir:effectiveInstant | fhir:dateAsserted">
        <!-- CDA element effectiveTime unless specified something else -->
        <xsl:param name="pElementName" select="'effectiveTime'" />
        <!-- This might be cast to a specific xsi-type in the cda -->
        <xsl:param name="pXSIType" />
        <xsl:param name="pOperator" />

        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:if test="$pOperator">
                <xsl:attribute name="operator" select="$pOperator" />
            </xsl:if>
            <xsl:attribute name="value">
                <xsl:call-template name="Date2TS">
                    <xsl:with-param name="date" select="@value" />
                    <xsl:with-param name="includeTime" select="true()" />
                </xsl:call-template>
            </xsl:attribute>
        </xsl:element>

    </xsl:template>

    <xsl:template match="fhir:status">
        <statusCode>
            <xsl:choose>
                <xsl:when test="@value = 'completed'">
                    <xsl:attribute name="code" select="'completed'" />
                </xsl:when>
                <xsl:when test="@value = 'final'">
                    <xsl:attribute name="code" select="'completed'" />
                </xsl:when>
                <xsl:when test="@value = 'registered'">
                    <xsl:attribute name="code" select="'new'" />
                </xsl:when>
                <xsl:when test="@value = 'preliminary'">
                    <xsl:attribute name="code" select="'new'" />
                </xsl:when>

                <xsl:when test="@value = 'cancelled'">
                    <xsl:attribute name="code" select="'cancelled'" />
                </xsl:when>
                <xsl:when test="@value = 'entered-in-error'">
                    <xsl:attribute name="code" select="'nullified'" />
                </xsl:when>
                <xsl:when test="@value = 'unknown'">
                    <xsl:attribute name="nullFlavor" select="'UNK'" />
                </xsl:when>
                <!-- No idea what these should map to - using completed -->
                <xsl:when test="@value = 'amended'">
                    <xsl:attribute name="code" select="'completed'" />
                </xsl:when>
                <xsl:when test="@value = 'corrected'">
                    <xsl:attribute name="code" select="'completed'" />
                </xsl:when>
                <xsl:when test="@value = 'active'">
                    <xsl:attribute name="code" select="'active'" />
                </xsl:when>

            </xsl:choose>
        </statusCode>

    </xsl:template>

    <xsl:template match="fhir:meta/fhir:security">
        <xsl:choose>
            <xsl:when test="fhir:coding">
                <confidentialityCode>
                    <xsl:if test="fhir:coding[1]/fhir:code[@value]">
                        <xsl:attribute name="code" select="fhir:coding[1]/fhir:code/@value" />
                    </xsl:if>
                    <xsl:if test="fhir:coding[1]/fhir:system[@value]">
                        <xsl:choose>
                            <xsl:when test="fhir:coding[1]/fhir:system/@value = 'http://hl7.org/fhir/ValueSet/security-labels'">
                                <xsl:attribute name="system">2.16.840.1.113883.5.25</xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="system" select="fhir:coding[1]/fhir:system/@value" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </confidentialityCode>
            </xsl:when>
            <xsl:otherwise>
                <confidentialityCode code="N" codeSystem="2.16.840.1.113883.5.25" displayName="Normal" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Uses the lab-obs-status-mapping file imported at the top of this file to match fhir status with cda lab obs equivalents -->
    <xsl:template match="fhir:status" mode="map-lab-obs-status">
        <xsl:param name="pElementName" select="'value'" />
        <xsl:param name="pXSIType" select="'CD'" />
        
        <xsl:variable name="vStatus">
            <xsl:value-of select="@value"/>
        </xsl:variable>
        
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="xsi:type" select="$pXSIType" />
            <xsl:choose>
                <xsl:when test="$lab-obs-status-mapping/map[@fhirLabObsStatus = $vStatus]">
                    <xsl:attribute name="code" select="$lab-obs-status-mapping/map[@fhirLabObsStatus = $vStatus][1]/@cdaLabObsStatus" />
                    <xsl:attribute name="displayName" select="$lab-obs-status-mapping/map[@fhirLabObsStatus = $vStatus][1]/@cdaDisplayName" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="code" select="'F'" />
                    <xsl:attribute name="displayName" select="'Final results'" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:attribute name="codeSystem" select="'2.16.840.1.113883.18.34'" />
            <xsl:attribute name="codeSystemName" select="'HL7ObservationResultStatusCodesInterpretation'" />
        </xsl:element>
    </xsl:template>

    <!-- TEMPLATE: Uses the lab-status-mapping file imported at the top of this file to match fhir status with cda lab equivalents -->
    <xsl:template match="fhir:status" mode="map-lab-status">
        <xsl:param name="pElementName" select="'value'" />
        <xsl:param name="pXSIType" select="'CD'" />
        
        <xsl:variable name="vStatus">
            <xsl:value-of select="@value"/>
        </xsl:variable>
        
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="xsi:type" select="$pXSIType" />
            <xsl:choose>
                <xsl:when test="$lab-status-mapping/map[@fhirLabStatus = $vStatus]">
                    <xsl:attribute name="code" select="$lab-status-mapping/map[@fhirLabStatus = $vStatus][1]/@cdaLabStatus" />
                    <xsl:attribute name="displayName" select="$lab-status-mapping/map[@fhirLabStatus = $vStatus][1]/@cdaDisplayName" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="code" select="'F'" />
                    <xsl:attribute name="displayName" select="'Final results; results stored and verified. Can only be changed with a corrected result.'" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:attribute name="codeSystem" select="'2.16.840.1.113883.18.51'" />
            <xsl:attribute name="codeSystemName" select="'HL7ResultStatus'" />
        </xsl:element>
    </xsl:template>
    
    <!-- TEMPLATE: Uses the section-title-mapping file imported at the top of this file to match section.code with section.title 
         when the title is missing from the fhir data-->
    <xsl:template match="fhir:code" mode="map-section-title">
        <xsl:variable name="vSectionCode">
            <xsl:value-of select="fhir:coding/fhir:code/@value"/>
        </xsl:variable>        
        <title>
            <xsl:choose>
                <xsl:when test="$section-title-mapping/map[@sectionCode = $vSectionCode]">
                    <xsl:value-of select="$section-title-mapping/map[@sectionCode = $vSectionCode]/@sectionTitle" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'No title specified'" />
                </xsl:otherwise>
            </xsl:choose>
        </title>
    </xsl:template>

    <!-- TEMPLATE: Maps a fhir resource to a cda template and outputs the templateId(s) -->
    <xsl:template name="get-template-id">
        <xsl:param name="pElementType" />
        <xsl:param name="pTriggerExtension" />
        <xsl:choose>
            <xsl:when test="$pTriggerExtension">
                <xsl:apply-templates mode="map-trigger-resource-to-template" select="." />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="map-resource-to-template" select=".">
                    <xsl:with-param name="pElementType" select="$pElementType" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Maps a fhir resource to a cda template and outputs the templateId(s) -->
    <!-- <xsl:template name="get-template-id-questionnaire">
    <xsl:param name="pLinkId" />
    <xsl:apply-templates select="$pLinkId" mode="map-questionnaire-item-to-template"/>
  </xsl:template>-->

    <!-- Outputs an id even if the identifier element doesn't exist
       Use when the CDA requires an id - if pNoNullAllowed is set
       will fill with a generated uuid -->
    <xsl:template name="get-id">
        <xsl:param name="pElement" select="fhir:identifier" />
        <xsl:param name="pNoNullAllowed" select="false()" />
        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:variable name="vPotentialDupes">
                    <xsl:apply-templates select="$pElement" />
                </xsl:variable>
                <xsl:for-each-group group-by="concat(@root, @extension)" select="$vPotentialDupes/cda:id">
                    <xsl:copy-of select="current-group()[1]" />
                </xsl:for-each-group>
            </xsl:when>
            <xsl:when test="$pNoNullAllowed">
                <id root="{lower-case(uuid:get-uuid())}" />
            </xsl:when>
            <xsl:otherwise>
                <id nullFlavor="NI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- If pNoNullAllowed is missing or set to false(): outputs an addr even if the address element doesn't exist
       Use when the CDA requires an addr
       If pNoNullAllowed is set to true: outputs nothing if the address element doesn't exist -->
    <xsl:template name="get-addr">
        <xsl:param name="pElement" select="fhir:address" />
        <xsl:param name="pNoNullAllowed" select="false()" />
        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:apply-templates select="$pElement" />
            </xsl:when>
            <xsl:when test="$pNoNullAllowed" />
            <xsl:otherwise>
                <addr>
                    <streetAddressLine nullFlavor="NI" />
                    <city nullFlavor="NI" />
                    <state nullFlavor="NI" />
                    <postalCode nullFlavor="NI" />
                </addr>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- If pNoNullAllowed is missing or set to false(): outputs a telecom even if the telecom element doesn't exist
       Use when the CDA requires a telecom 
        If pNoNullAllowed is set to true: outputs nothing if the telecom element doesn't exist -->
    <xsl:template name="get-telecom">
        <xsl:param name="pElement" select="fhir:telecom" />
        <xsl:param name="pNoNullAllowed" select="false()" />

        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:variable name="vPotentialDupes">
                    <xsl:apply-templates select="$pElement" />
                </xsl:variable>
                <xsl:for-each-group group-by="concat(@value, @use)" select="$vPotentialDupes/cda:telecom">
                    <xsl:copy-of select="current-group()[1]" />
                </xsl:for-each-group>
            </xsl:when>
            <xsl:when test="$pNoNullAllowed" />
            <xsl:otherwise>
                <telecom nullFlavor="NI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--  If pNoNullAllowed is missing or set to false(): outputs a org name even if the element doesn't exist
       Use when the CDA requires a organization name
    If pNoNullAllowed is set to true: outputs nothing if the element doesn't exist -->
    <xsl:template name="get-org-name">
        <xsl:param name="pElement" select="fhir:name" />
        <xsl:param name="pNoNullAllowed" select="false()" />

        <xsl:choose>
            <xsl:when test="$pElement">
                <name>
                    <xsl:value-of select="$pElement/@value" />
                </name>
            </xsl:when>
            <xsl:when test="$pNoNullAllowed" />
            <xsl:otherwise>
                <name nullFlavor="NI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--  If pNoNullAllowed is missing or set to false(): outputs a name even if the element doesn't exist
       Use when the CDA requires a organization name 
    If pNoNullAllowed is set to true: outputs nothing if the element doesn't exist -->
    <xsl:template name="get-person-name">
        <xsl:param name="pElement" select="fhir:name" />
        <xsl:param name="pNoNullAllowed" select="false()" />

        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:apply-templates select="$pElement" />
            </xsl:when>
            <xsl:when test="$pNoNullAllowed" />
            <xsl:otherwise>
                <name>
                    <given nullFlavor="NI" />
                    <family nullFlavor="NI" />
                </name>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Returns an effectiveTime even if the effectiveTime/time/whatever element doesn't exist
       Use when the CDA requires an effectiveTime -->
    <xsl:template name="get-effective-time">
        <xsl:param name="pElement" select="fhir:effectiveDateTime" />
        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:apply-templates select="$pElement" />
            </xsl:when>
            <xsl:otherwise>
                <effectiveTime nullFlavor="NI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Returns a time even if the time/whatever element doesn't exist
       Use when the CDA requires a time -->
    <xsl:template name="get-time">
        <xsl:param name="pElement" select="fhir:time" />
        <xsl:param name="pElementName" select="'time'" />
        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:apply-templates select="$pElement">
                    <xsl:with-param name="pElementName" select="$pElementName" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="nullFlavor" select="'NI'" />
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-reference-range">
        <referenceRange>
            <observationRange>
                <!--MD: empty <text/> is not allowed -->
                <xsl:choose>
                    <xsl:when test="fhir:text">
                        <text>
                            <xsl:value-of select="fhir:text/@value" />
                        </text>
                    </xsl:when>
                </xsl:choose>

                <value xsi:type="IVL_PQ">
                    <xsl:apply-templates select="fhir:low">
                        <xsl:with-param name="pElementName" select="'low'" />
                        <xsl:with-param name="pIncludeDatatype" select="false()" />
                    </xsl:apply-templates>
                    <xsl:apply-templates select="fhir:high">
                        <xsl:with-param name="pElementName" select="'high'" />
                        <xsl:with-param name="pIncludeDatatype" select="false()" />
                    </xsl:apply-templates>
                </value>
            </observationRange>
        </referenceRange>
    </xsl:template>

    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']">
        <xsl:attribute name="nullFlavor">
            <xsl:choose>
                <xsl:when test="fhir:valueCode/@value = 'unknown'">UNK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'not-applicable'">NA</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'masked'">MSK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'negative-infinity'">NINF</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'positive-infinity'">PINF</xsl:when>
                <xsl:otherwise>UNK</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <xsl:template name="debug-element-stack">
        <xsl:message>
            <xsl:value-of select="local-name(.)" />
            <xsl:for-each select="@*">
                <xsl:text> @</xsl:text>
                <xsl:value-of select="local-name(.)" />
                <xsl:text>=</xsl:text>
                <xsl:value-of select="." />
            </xsl:for-each>
            <xsl:if test="local-name(.) = 'item'">
                <xsl:text> linkId=</xsl:text>
                <xsl:value-of select="fhir:linkId/@value" />
            </xsl:if>
        </xsl:message>
        <xsl:for-each select="parent::*">
            <xsl:call-template name="debug-element-stack" />
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
