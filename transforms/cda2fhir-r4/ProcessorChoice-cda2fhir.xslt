<?xml version="1.0" encoding="UTF-8"?>
<!-- 
   
Copyright 2024 Lantana Consulting Group

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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
    exclude-result-prefixes="lcg cda fhir">

    <xsl:import href="cda2fhir-includes.xslt" />
    <xsl:import href="SaxonPE-cda2fhir.xslt" />
    <xsl:import href="NativeUUIDGen-cda2fhir.xslt" />

    <xsl:param name="pProcessor" select="'native'"/>

    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$pProcessor = 'saxon'">
                <xsl:apply-templates select="/" mode="saxon" />
            </xsl:when>
            <xsl:when test="$pProcessor = 'native'">
                <xsl:apply-templates select="/" mode="native" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
