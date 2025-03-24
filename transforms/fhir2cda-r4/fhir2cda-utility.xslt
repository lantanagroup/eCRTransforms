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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda xsi fhir xhtml sdtc xs" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:sdtc="urn:hl7-org:sdtc" xmlns:uuid="http://www.uuid.org" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
    <xsl:param name="section-title-mapping-file">../section-title-mapping.xml</xsl:param>
    <xsl:param name="result-status-mapping-file">../result-status-mapping.xml</xsl:param>
    <!-- File containing the eRSD specification bundle -->
    <!--<xsl:param name="eRSD-file">../eRSDv3_specification_bundle.xml</xsl:param>-->

    <xsl:variable name="gvUUIDRegEx" select="'[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?'" />
    <xsl:variable name="gvUUIDRegExWithPrefix" select="'urn:uuid:[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?'" />
    <!--[0-2](.[1-9]\d*)+-->
    <xsl:variable name="gvOIDRegEx" select="'([0-2])((\.0)|(\.[1-9][0-9]*))*'" />

    <xsl:variable name="gvOIDRegExWithPrefix" select="'urn:oid:([0-2])((\.0)|(\.[1-9][0-9]*))*'" />

    <xsl:variable name="lab-status-mapping" select="document($lab-status-mapping-file)/mapping" />
    <xsl:variable name="lab-obs-status-mapping" select="document($lab-obs-status-mapping-file)/mapping" />

    <xsl:variable name="section-title-mapping" select="document($section-title-mapping-file)/mapping" />
    <xsl:variable name="result-status-mapping" select="document($result-status-mapping-file)/mapping" />

    <xsl:variable name="gvMapping" select="document('../oid-uri-mapping-r4.xml')/mapping" />

    <!-- variable containing all the trigger result order test codes for use in determining whether a serviceRequest is a result test order -->
    <!--<xsl:variable name="result-order-valueset-expansion" select="document($eRSD-file)//fhir:Bundle/fhir:entry[fhir:fullUrl/@value='http://ersd.aimsplatform.org/fhir/ValueSet/lotc']/fhir:resource/fhir:ValueSet/fhir:expansion/fhir:contains/fhir:code" />-->

    <!-- Key with all trigger result order test codes -->
    <!--<xsl:key name="result-order-valueset-key" match="$result-order-valueset-expansion" use="@value" />-->

    <xsl:variable name="gvTriggerExtensionUrl" select="'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-trigger-code-flag-extension'" />
    <!-- Key to get all the trigger code extension and their referenced top-level resources -->
    <!--<xsl:key name="trigger-extension" match="//fhir:entry[fhir:extension/@url = $gvTriggerExtensionUrl] | //fhir:diagnosis[fhir:extension/@url = $gvTriggerExtensionUrl]"
        use="fhir:reference/@value | fhir:condition/fhir:reference/@value" />-->

    <!-- Key with all codes and their fullUrl -->
    <xsl:key name="possible-trigger-codes" match="//fhir:entry[descendant::*/fhir:coding/fhir:code/@value]" use="fhir:fullUrl/@value" />

    <xsl:variable name="gvTriggerCodeInfo">
        <!-- Get a copy of each trigger code flag extension -->
        <xsl:for-each select="//fhir:entry[fhir:extension/@url = $gvTriggerExtensionUrl] | //fhir:diagnosis[fhir:extension/@url = $gvTriggerExtensionUrl]">

            <triggerCodeInfo xmlns="http://www.lantanagroup.com">
                <xsl:copy-of select="." />

                <!-- Put the trigger code into a variable for easy reference -->
                <xsl:variable name="vTriggerCode" select="fhir:extension/fhir:extension[@url = 'triggerCode']/fhir:valueCoding/fhir:code/@value" />

                <!-- Put the full url of the original trigger code resource into a variable for easy reference -->
                <xsl:variable name="vOriginalFullUrl">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:reference/@value | fhir:condition/fhir:reference/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <!-- Add in the original reference fullUrl for each trigger code reference (put this in the lcg namespace for easy reference later) -->
                <fullUrl>
                    <xsl:attribute name="value" select="$vOriginalFullUrl" />
                </fullUrl>
                <!-- Get the fullUrls from the referenced resource from the trigger code extension references (trigger codes could be in a referenced resource such as medicationReference or hasMember) that also contain the trigger code-->
                <matchedUrls>
                    <!-- Use possibleTriggerCode key to check if the trigger code is in this resource -->
                    <xsl:for-each select="key('possible-trigger-codes', $vOriginalFullUrl)">
                        <xsl:if test="descendant::*/fhir:coding/fhir:code/@value = $vTriggerCode">
                            <matchedUrl>
                                <xsl:attribute name="value" select="$vOriginalFullUrl" />
                            </matchedUrl>
                        </xsl:if>
                    </xsl:for-each>

                    <xsl:for-each select="
                            //fhir:entry[fhir:fullUrl[@value = $vOriginalFullUrl]]/descendant::fhir:hasMember/fhir:reference/@value |
                            //fhir:entry[fhir:fullUrl[@value = $vOriginalFullUrl]]/descendant::fhir:medicationReference/fhir:reference/@value">
                        <!-- Put referenced full url into a variable for easy use -->
                        <xsl:variable name="vReferencedFullUrl">
                            <xsl:call-template name="resolve-to-full-url">
                                <xsl:with-param name="referenceURI" select="." />
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- Use possibleTriggerCode key to check if the trigger code is in this resource -->
                        <xsl:for-each select="key('possible-trigger-codes', $vReferencedFullUrl)">
                            <xsl:if test="descendant::*/fhir:coding/fhir:code/@value = $vTriggerCode">
                                <matchedUrl>
                                    <xsl:attribute name="value" select="$vReferencedFullUrl" />
                                </matchedUrl>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </matchedUrls>
            </triggerCodeInfo>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="gvCurrentIg">
        <xsl:choose>
            <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition'">eICR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '55751-2'">eICR</xsl:when>
            <xsl:when test="//fhir:Communication/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-composition'">RR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:type/fhir:coding/fhir:code/@value = '88085-6'">RR</xsl:when>
            <xsl:when test="//fhir:Composition/fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Care-Plan'">PCP</xsl:when>

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
    </xsl:variable>

    <!-- Check to see if this template contains a trigger code -->
    <xsl:template name="check-for-trigger">
        <xsl:variable name="vFullUrl" select="parent::fhir:resource/preceding-sibling::fhir:fullUrl/@value" />

        <xsl:if test="$gvTriggerCodeInfo/lcg:triggerCodeInfo/lcg:matchedUrls/lcg:matchedUrl/@value = $vFullUrl">
            <xsl:copy-of select="
                    $gvTriggerCodeInfo/lcg:triggerCodeInfo[lcg:matchedUrls/lcg:matchedUrl/@value = $vFullUrl]/fhir:entry/fhir:extension |
                    $gvTriggerCodeInfo/lcg:triggerCodeInfo[lcg:matchedUrls/lcg:matchedUrl/@value = $vFullUrl]/fhir:diagnosis/fhir:extension" />
        </xsl:if>
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

                <xsl:message> referenceURI: <xsl:value-of select="$referenceURI" /> entryFullUrl: <xsl:value-of select="$entryFullUrl" /> currentResourceType: <xsl:value-of select="$currentResourceType" />
                    fhirBaseUrl: <xsl:value-of select="$fhirBaseUrl" />
                </xsl:message>

                <xsl:value-of select="$fhirBaseUrl" />
                <xsl:value-of select="$referenceURI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--<xsl:function name="lcg:fcnGetLocalName">
        <xsl:param name="referenceURI" as="attribute()" />
        <xsl:param name="entryFullUrl" as="attribute()" />
        <xsl:param name="currentResourceType" as="xs:string" />
        
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
                
                <xsl:message> referenceURI: <xsl:value-of select="$referenceURI" /> entryFullUrl: <xsl:value-of select="$entryFullUrl" /> currentResourceType: <xsl:value-of select="$currentResourceType" />
                    fhirBaseUrl: <xsl:value-of select="$fhirBaseUrl" />
                </xsl:message>
                
                <xsl:value-of select="$fhirBaseUrl" />
                <xsl:value-of select="$referenceURI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>-->

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
        <xsl:param name="pCode" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="typeCode" select="$pTypeCode" />
            <xsl:if test="$pPerformerTime">
                <time value="{pPerformerTime}" />
            </xsl:if>
            <assignedEntity>
                <!-- id -->
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <!-- code -->
                <xsl:apply-templates select="$pCode">
                    <xsl:with-param name="pElementName">code</xsl:with-param>
                </xsl:apply-templates>
                <!-- addr -->
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
                <xsl:choose>
                    <xsl:when test="fhir:start/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                        <xsl:apply-templates select="fhir:start/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="value">
                            <xsl:call-template name="Date2TS">
                                <xsl:with-param name="date" select="fhir:start/@value" />
                                <xsl:with-param name="includeTime" select="true()" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>

            </low>
            <xsl:choose>
                <xsl:when test="fhir:end">
                    <high>
                        <xsl:choose>
                            <xsl:when test="fhir:start/fhir:extension/@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'">
                                <xsl:apply-templates select="fhir:start/fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="value">
                                    <xsl:call-template name="Date2TS">
                                        <xsl:with-param name="date" select="fhir:end/@value" />
                                        <xsl:with-param name="includeTime" select="true()" />
                                    </xsl:call-template>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                    </high>
                </xsl:when>
                <xsl:otherwise>
                    <high nullFlavor="UNK" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:effectiveDateTime | fhir:date" mode="period">
        <!-- CDA element effectiveTime unless specified something else -->
        <xsl:param name="pElementName" select="'effectiveTime'" />

        <xsl:element name="{$pElementName}">
            <low>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="@value" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </low>
            <high>
                <xsl:attribute name="nullFlavor" select="'NI'" />
            </high>
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
                <xsl:when test="@value = 'preparation'">
                    <xsl:attribute name="code" select="'active'" />
                </xsl:when>
                <xsl:when test="@value = 'in-progress'">
                    <xsl:attribute name="code" select="'active'" />
                </xsl:when>
                <xsl:when test="@value = 'not-done'">
                    <xsl:attribute name="code" select="'aborted'" />
                </xsl:when>
                <xsl:when test="@value = 'on-hold'">
                    <xsl:attribute name="code" select="'active'" />
                </xsl:when>
                <xsl:when test="@value = 'stopped'">
                    <xsl:attribute name="code" select="'cancelled'" />
                </xsl:when>
                <xsl:when test="@value = 'entered-in-error'">
                    <xsl:attribute name="code" select="'cancelled'" />
                </xsl:when>

            </xsl:choose>
        </statusCode>

    </xsl:template>

    <!-- intent -->
    <xsl:template match="fhir:intent">
        <xsl:choose>
            <xsl:when test="@value = 'proposal'">PRP</xsl:when>
            <xsl:when test="@value = 'plan'">INT</xsl:when>
            <xsl:when test="@value = 'order'">RQO</xsl:when>
            <xsl:when test="@value = 'original-order'">RQO</xsl:when>
            <xsl:when test="@value = 'reflex-order'">RQO</xsl:when>
            <xsl:when test="@value = 'filler-order'">RQO</xsl:when>
            <xsl:when test="@value = 'instance-order'">RQO</xsl:when>
            <xsl:otherwise>INT</xsl:otherwise>
        </xsl:choose>
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
            <xsl:value-of select="@value" />
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
            <xsl:value-of select="@value" />
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

    <!-- TEMPLATE: Uses the result-status-mapping file imported at the top of this file to match cda result status with fhir equivalents -->
    <xsl:template match="fhir:status" mode="map-result-status">
        <xsl:param name="pElementName" select="'statusCode'" />
        <xsl:variable name="vResultStatus" select="@value" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$result-status-mapping/map[@fhirLabStatus = $vResultStatus]">
                    <xsl:attribute name="code" select="$result-status-mapping/map[@fhirLabStatus = $vResultStatus][1]/@cdaResultStatus" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="code" select="'completed'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- TEMPLATE: Uses the section-title-mapping file imported at the top of this file to match section.code with section.title 
         when the title is missing from the fhir data-->
    <xsl:template match="fhir:code" mode="map-section-title">
        <xsl:variable name="vSectionCode">
            <xsl:value-of select="fhir:coding/fhir:code/@value" />
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
            <xsl:when test="$pNoNullAllowed = true()">
                <id root="{lower-case(uuid:get-uuid())}" />
            </xsl:when>
            <xsl:otherwise>
                <id nullFlavor="NI" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- If pNoNullAllowed is missing or set to false(): outputs a nullFlavor addr even if the address element doesn't exist
       Use when the CDA requires an addr
       If pNoNullAllowed is set to true: outputs nothing if the address element doesn't exist -->
    <xsl:template name="get-addr">
        <xsl:param name="pElement" select="fhir:address" />
        <xsl:param name="pNoNullAllowed" select="false()" />
        <xsl:choose>
            <xsl:when test="$pElement">
                <xsl:apply-templates select="$pElement" />
            </xsl:when>
            <xsl:when test="$pNoNullAllowed = true()" />
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
            <xsl:when test="$pNoNullAllowed = true()" />
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
            <xsl:when test="$pNoNullAllowed = true()" />
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

    <!-- SG 20231124: Added bodySite (targetSiteCode) -->
    <xsl:template match="fhir:bodySite[fhir:coding]">

        <xsl:for-each select="fhir:coding">
            <targetSiteCode>
                <xsl:attribute name="code">
                    <xsl:value-of select="./fhir:code/@value" />
                </xsl:attribute>
                <xsl:variable name="vBodySiteSystemUri" select="./fhir:system/@value" />
                <xsl:choose>
                    <xsl:when test="$gvMapping/map[@uri = $vBodySiteSystemUri]">
                        <xsl:attribute name="codeSystem">
                            <xsl:value-of select="$gvMapping/map[@uri = $vBodySiteSystemUri][1]/@oid" />
                        </xsl:attribute>
                    </xsl:when>
                </xsl:choose>
                <xsl:apply-templates mode="display" select="./fhir:display" />
            </targetSiteCode>
        </xsl:for-each>
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
        <xsl:param name="pElementName">code</xsl:param>
        <xsl:param name="pXSIType" />
        <xsl:element name="{$pElementName}">
            <xsl:if test="$pXSIType">
                <xsl:attribute name="xsi:type" select="$pXSIType" />
            </xsl:if>
            <xsl:attribute name="nullFlavor">
                <xsl:choose>
                    <!-- Mapping from here: https://build.fhir.org/ig/HL7/ccda-on-fhir/ConceptMap-FC-DataAbsentReasonNullFlavor.html -->
                    <xsl:when test="fhir:valueCode/@value = 'unknown'">NI</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'asked-unknown'">ASKU</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'temp-unknown'">NAV</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'not-asked'">NASK</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'asked-declined'">UNK</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'masked'">MSK</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'not-applicable'">NA</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'unsupported'">NI</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'as-text'">OTH</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'error'">NAV</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'non-a-number'">OTH</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'negative-infinity'">NINF</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'positive-infinity'">PINF</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'not-performed'">NASK</xsl:when>
                    <xsl:when test="fhir:valueCode/@value = 'not-permitted'">OTH</xsl:when>
                </xsl:choose>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="fhir:extension[@url = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason']" mode="attribute-only">
        <xsl:attribute name="nullFlavor">
            <xsl:choose>
                <!-- Mapping from here: https://build.fhir.org/ig/HL7/ccda-on-fhir/ConceptMap-FC-DataAbsentReasonNullFlavor.html -->
                <xsl:when test="fhir:valueCode/@value = 'unknown'">NI</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'asked-unknown'">ASKU</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'temp-unknown'">NAV</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'not-asked'">NASK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'asked-declined'">UNK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'masked'">MSK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'not-applicable'">NA</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'unsupported'">NI</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'as-text'">OTH</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'error'">NAV</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'non-a-number'">OTH</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'negative-infinity'">NINF</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'positive-infinity'">PINF</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'not-performed'">NASK</xsl:when>
                <xsl:when test="fhir:valueCode/@value = 'not-permitted'">OTH</xsl:when>
                <xsl:otherwise>UNK</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="fhir:dataAbsentReason" mode="data-absent-reason">
        <xsl:attribute name="nullFlavor">
            <xsl:choose>
                <!-- Mapping from here: https://build.fhir.org/ig/HL7/ccda-on-fhir/ConceptMap-FC-DataAbsentReasonNullFlavor.html -->
                <xsl:when test="fhir:coding/fhir:code/@value = 'unknown'">NI</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'asked-unknown'">ASKU</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'temp-unknown'">NAV</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'not-asked'">NASK</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'asked-declined'">UNK</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'masked'">MSK</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'not-applicable'">NA</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'unsupported'">NI</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'as-text'">OTH</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'error'">NAV</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'non-a-number'">OTH</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'negative-infinity'">NINF</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'positive-infinity'">PINF</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'not-performed'">NASK</xsl:when>
                <xsl:when test="fhir:coding/fhir:code/@value = 'not-permitted'">OTH</xsl:when>
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
