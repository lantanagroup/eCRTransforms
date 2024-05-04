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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
    exclude-result-prefixes="lcg cda fhir">

    <xsl:include href="fhir2cda-ClinicalDocument.xslt" />

    <!-- Data Types -->
    <xsl:include href="fhir2cda-CD.xslt" />
    <xsl:include href="fhir2cda-II.xslt" />
    <xsl:include href="fhir2cda-TEL.xslt" />
    <xsl:include href="fhir2cda-ADDR.xslt" />
    <xsl:include href="fhir2cda-PQ.xslt" />
    <xsl:include href="fhir2cda-TS.xslt" />
    <xsl:include href="fhir2cda-PN.xslt" />
    <xsl:include href="fhir2cda-ON.xslt" />

    <!-- Header Participants -->
    <xsl:include href="fhir2cda-RecordTarget.xslt" />
    <xsl:include href="fhir2cda-Author.xslt" />
    <xsl:include href="fhir2cda-Custodian.xslt" />
    <xsl:include href="fhir2cda-ExternalDocument.xslt" />
    <xsl:include href="fhir2cda-InformationRecipient.xslt" />
    <xsl:include href="fhir2cda-LegalAuthenticator.xslt" />
    <xsl:include href="fhir2cda-Authenticator.xslt" />
    <xsl:include href="fhir2cda-EncompassingEncounter.xslt" />

    <!-- Other particpants -->
    <xsl:include href="fhir2cda-Participant.xslt" />

    <xsl:include href="fhir2cda-Section.xslt" />

    <!-- ClinicalStatements -->
    <xsl:include href="fhir2cda-Act.xslt" />
    <xsl:include href="fhir2cda-Encounter.xslt" />
    <xsl:include href="fhir2cda-SubstanceAdministration.xslt" />
    <xsl:include href="fhir2cda-Supply.xslt" />
    <xsl:include href="fhir2cda-ServiceEvent.xslt" />
    <xsl:include href="fhir2cda-Observation.xslt" />
    <xsl:include href="fhir2cda-Organizer.xslt" />
    <xsl:include href="fhir2cda-Procedure.xslt" />
    <xsl:include href="fhir2cda-Coverage.xslt" />
    <xsl:include href="fhir2cda-Instruction.xslt" />

    <xsl:include href="native-xslt-uuid.xslt" />
    <xsl:include href="fhir2cda-utility.xslt" />
    <xsl:include href="fhir2cda-narrative.xslt" />
    <xsl:include href="fhir2cda-mapProfileToTemplate.xslt" />

    <!--  <xsl:include href="../hai-ltc/generate-narrative-ltc.xslt" />-->


</xsl:stylesheet>
