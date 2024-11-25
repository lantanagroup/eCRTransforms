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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sdtc="urn:hl7-org:sdtc" version="2.0" exclude-result-prefixes="lcg xsl cda fhir sdtc">

    <xsl:import href="fhir2cda-TS.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-utility.xslt" />

    <!-- Global carriage return variable for nicer formatting -->
    <xsl:variable name="carriageReturn">
        <xsl:text>
        </xsl:text>
    </xsl:variable>

    <!-- Map profile uri to template -->
    <xsl:template match="fhir:*" mode="map-resource-to-template">
        <xsl:param name="pElementType" />

        <xsl:choose>

            <!-- Documents -->
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-denom'">
                <xsl:comment select="' Published in HAI IG R3D3 '" />
                <templateId root="2.16.840.1.113883.10.20.5.7.3.3" />
                <xsl:comment select="' Conformant to Healthcare Associated Infection Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.25" />
                <xsl:comment select="' Conformant to HAI Single-Person Report Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.27" />
                <xsl:comment select="' [Conformant to the HAI Late Onset Sepsis/Meningitis Event (LOS) Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.53" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event'">
                <xsl:comment select="' Published in HAI IG R3D4 '" />
                <templateId root="2.16.840.1.113883.10.20.5.7.3.4" />
                <xsl:comment select="' Conformant to Healthcare Associated Infection Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.25" />
                <xsl:comment select="' Conformant to HAI Single-Person Report Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.27" />
                <xsl:comment select="' [HAI R3D4] Late Onset Sepsis/Meningitis Denominator (LOS/Men Denom) Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.58" extension="2019-04-01" />
            </xsl:when>

            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event'">
                <xsl:comment select="' [HAI Normative R1] Conformant to Healthcare Associated Infection Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.25" />
                <xsl:comment select="' [HAI LTCF R1D1] Conformant to Laboratory Identified MDRO or CDI Event Report for LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.1.1" extension="2019-08-01" />
                <xsl:comment select="' [HAI LTCF R1D1] Conformant to HAI Single-Person Report Generic Constraints LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.1.3" extension="2019-08-01" />
            </xsl:when>

            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary'">
                <xsl:comment select="' [HAI Normative R1] Conformant to Healthcare Associated Infection Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.25" />
                <xsl:comment select="' [HAI Normative R1] Conformant to the HAI Population Summary Report Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.28" />
                <xsl:comment select="' [HAI LTCF R1D1] Conformant to MDRO and CDI LabID Event Reporting Monthly Summary Data for LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.1.2" extension="2019-08-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-composition'">
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" extension="2015-08-01" />
                <xsl:comment select="' [RR R1S1] Initial Public Health Case Report Reportability Response Document (RR) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.1.2" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-composition' or fhir:type/fhir:coding/fhir:code/@value = '55751-2'">
                <xsl:comment select="' [C-CDA R1.1] US Realm Header '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" />
                <xsl:comment select="' [C-CDA R2.1] US Realm Header (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.1.1" extension="2015-08-01" />
                <xsl:choose>
                    <xsl:when test="$gParamCDAeICRVersion = 'R1.1'">
                        <xsl:comment select="' [eICR R2 STU1.1] Initial Public Health Case Report Document (eICR) (V2) '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2" extension="2016-12-01" />
                    </xsl:when>
                    <xsl:otherwise>
                        <!--  MD: skip R2 
                        <xsl:comment select="' [eICR R2 STU2] Initial Public Health Case Report Document (eICR) (V3) '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2" extension="2019-04-01" />
                        -->
                        <!-- MD skip V4
            <xsl:comment select="' [eICR R2 STU3] Initial Public Health Case Report Document (eICR) (V4) '" />
            <templateId root="2.16.840.1.113883.10.20.15.2" extension="2021-01-01" />
              -->
                        <xsl:comment select="' [eICR R2 STU3] Initial Public Health Case Report Document (eICR) (V5) '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2" extension="2022-05-01" />
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:when>

            <!-- Sections -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '75310-3'">
                <templateId root="2.16.840.1.113883.10.20.22.2.58" extension="2015-08-01" />
                <templateId root="2.16.840.1.113883.10.20.37.2.1" extension="2017-08-01" />
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '61146-7'">
                <templateId root="2.16.840.1.113883.10.20.22.2.60" />
                <templateId root="2.16.840.1.113883.10.20.37.2.2" extension="2017-08-01" />
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '62387-6'">
                <templateId root="2.16.840.1.113883.10.20.21.2.3" extension="2015-08-01" />
                <templateId root="2.16.840.1.113883.10.20.37.2.4" extension="2017-08-01" />
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '11383-7'">
                <templateId root="2.16.840.1.113883.10.20.22.2.61" />
                <templateId root="2.16.840.1.113883.10.20.37.2.3" extension="2017-08-01" />
            </xsl:when>

            <!-- Payers Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '48768-6'">
                <xsl:comment select="' Payers Section (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.18" extension="2015-08-01" />
            </xsl:when>
            <!-- History of Present Illness Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '10164-2'">
                <xsl:comment select="' [C-CDA R1.1 History of Present Illness Section '" />
                <templateId root="1.3.6.1.4.1.19376.1.5.3.1.3.4" />
            </xsl:when>
            <!-- Plan of Care/Plan of Treatment Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '18776-5'">
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.10" />
                <xsl:comment select="' [C-CDA R2.0] Plan of Treatment Section (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.10" extension="2014-06-09" />
            </xsl:when>
            <!-- Encounters Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '46240-8'">
                <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries optional) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.22" />
                <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries optional) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.22" extension="2015-08-01" />
                <xsl:comment select="' [C-CDA R1.1] Encounters Section (entries required) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.22.1" />
                <xsl:comment select="' [C-CDA R2.1] Encounters Section (entries required) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.22.1" extension="2015-08-01" />
            </xsl:when>
            <!-- Medications Administered Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '29549-3'">
                <xsl:comment select="' [C-CDA R1.1] Medications Administered Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.38" />
                <xsl:comment select="' [C-CDA R2.0] Medications Administered Section (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.38" extension="2014-06-09" />
            </xsl:when>
            <!-- Problem Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '11450-4'">
                <xsl:comment select="' [C-CDA R1.1] Problem Section (entries optional) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.5" />
                <xsl:comment select="' [C-CDA R2.1] Problem Section (entries optional) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.5" extension="2015-08-01" />
                <xsl:comment select="' [C-CDA R1.1] Problem Section (entries required) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.5.1" />
                <xsl:comment select="' [C-CDA R2.1] Problem Section (entries required) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.5.1" extension="2015-08-01" />
            </xsl:when>

            <!-- Reason for Visit Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '29299-5'">
                <xsl:comment select="' [C-CDA R1.1] Reason for Visit Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.12" />
            </xsl:when>

            <!-- Reason for Referral Section (V3) -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '42349-1'">
                <xsl:comment select="' Reason for Referral Section (V3) '" />
                <templateId root="1.3.6.1.4.1.19376.1.5.3.1.3.1" />
                <templateId root="1.3.6.1.4.1.19376.1.5.3.1.3.1" extension="2014-06-09" />
            </xsl:when>

            <!-- Chief Complaint Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '10154-3'">
                <xsl:comment select="' [C-CDA R1.1] Chief Complaint Section '" />
                <templateId root="1.3.6.1.4.1.19376.1.5.3.1.1.13.2.1" />
            </xsl:when>

            <!-- Results Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '30954-2'">
                <xsl:comment select="' [C-CDA R1.1] Results Section (entries optional) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.3" />
                <xsl:comment select="' [C-CDA R2.1] Results Section (entries optional) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.3" extension="2015-08-01" />
                <xsl:comment select="' [C-CDA R1.1] Results Section (entries required) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.3.1" />
                <xsl:comment select="' [C-CDA R2.1] Results Section (entries required) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.3.1" extension="2015-08-01" />
            </xsl:when>
            <!-- Immunizations Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '11369-6'">
                <xsl:comment select="' [C-CDA R2.1] Immunizations Section (entries required)(V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.2.1" extension="2015-08-01" />
            </xsl:when>

            <!-- MD: add Instrctions Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '69730-0'">
                <xsl:comment select="' Instructions Section (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.21.2.45" extension="2014-06-09" />
            </xsl:when>

            <!-- MD: add Medical Equipment Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '46264-8'">
                <xsl:comment select="' Medical Equipment Section (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.23" extension="2014-06-09" />
            </xsl:when>

            <!-- MD: add Allergies and Intolerance Section (entries required) V3 -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '48765-2'">
                <xsl:comment select="' Allergies and Intolerances Section (entries required) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.6.1" extension="2015-08-01" />
            </xsl:when>

            <!-- MD: add Assessment Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '51848-0'">
                <xsl:comment select="' Assessment Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.8" />
            </xsl:when>

            <!-- MD: add Assessment and Plan Section (V2) -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '51847-2'">
                <xsl:comment select="' Assessment and Plan Section (V2)  '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.9" extension="2014-06-09" />
            </xsl:when>

            <!-- MD: add Dental Findings Section Physical findings of Mouth and Throat and Teeth ) -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '8704-9'">
                <xsl:comment select="' Dental Findings Section  '" />
                <templateId root="2.16.840.1.113883.10.20.40.1.2.1" extension="2020-08-01" />
            </xsl:when>

            <!-- Procedures Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '47519-4'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R2.1] Procedures Section (entries optional)(V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.7.1" extension="2014-06-09" />
                <xsl:comment select="' [C-CDA R2.1] Procedures Section (entries required)(V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.7" extension="2014-06-09" />
            </xsl:when>
            <!-- Social History Section -->
            <xsl:when test="fhir:code[parent::fhir:section]/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '29762-2'">
                <xsl:comment select="' [C-CDA 1.1] Social History Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.17" />
                <xsl:comment select="' [C-CDA 2.1] Social History Section (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.17" extension="2015-08-01" />
                <xsl:comment select="' [ODH R2] Occupational Data for Health Templates Requirements Section (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.17" extension="2020-09-01" />
            </xsl:when>
            <!-- Pregnancy Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '90767-5'">
                <xsl:comment select="' [C-CDA PREG] Pregnancy Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.80" extension="2020-04-01" />
                <templateId root="2.16.840.1.113883.10.20.22.2.80" extension="2018-04-01" />
            </xsl:when>
            <!-- Vital Signs Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '8716-3'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R2.1] Vital Signs Section (entries required) (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.4.1" extension="2015-08-01" />
            </xsl:when>
            <!-- Emergency Outbreak Information Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '83910-0'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R2 STU3] Emergency Outbreak Information Section '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.2.4" extension="2021-01-01" />
            </xsl:when>
            <!-- Past Medical History Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '11348-0'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R2.1] Past Medical History (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.20" extension="2015-08-01" />
            </xsl:when>
            <!-- Review of Systems Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '10187-3'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R1.1] Review of Systems Section '" />
                <templateId root="1.3.6.1.4.1.19376.1.5.3.1.3.18" />
            </xsl:when>
            <!-- Chief Complaint and Reason for Visit Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '46239-0'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R1.1] Chief Complaint and Reason for Visit Section '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.13" />
            </xsl:when>
            <!-- Admission Medications Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '42346-7'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R2.1] Admission Medications Section (entries optional)(V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.44" extension="2015-08-01" />
            </xsl:when>
            <!-- Medications Section -->
            <xsl:when test="fhir:code/fhir:coding[fhir:system/@value = 'http://loinc.org']/fhir:code/@value = '10160-0'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This section is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this section so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA R2] Medications Section (entries required)(V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.2.1.1" extension="2014-06-09" />
            </xsl:when>

            <!-- [RR R1S1] Reportability Response Subject Section -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '88084-9'">
                <xsl:comment select="' [RR R1S1] Reportability Response Subject Section '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.2.1" extension="2017-04-01" />
            </xsl:when>
            <!-- [RR R1S1] Reportability Response Summary Section -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '55112-7'">
                <xsl:comment select="' [RR R1S1] Reportability Response Summary Section '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.2.2" extension="2017-04-01" />
            </xsl:when>
            <!-- [RR R1S1] Electronic Initial Case Report Section -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '88082-3'">
                <xsl:comment select="' [RR R1S1] Electronic Initial Case Report Section '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.2.3" extension="2017-04-01" />
            </xsl:when>

            <!-- HAI Sections -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'risk-factors'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI R3D3] Risk Factors Section (LOS/Men) '" />
                <templateId root="2.16.840.1.113883.10.20.5.5.64" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'event-details'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI R3D3] Infection Details in Late Onset Sepsis Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.5.64" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'findings-group'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI R1] Findings Section in an Infection-Type Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.5.45" />
            </xsl:when>

            <!-- HAI LTC Sections -->
            <!-- Findings Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'findings-group'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI LTCF R1D1] Findings Section in a Laboratory Identified Report LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.2.1" extension="2019-08-01" />
            </xsl:when>
            <!-- Encounters Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'encounters-group'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI LTCF R1D1] Encounters Section in an LTCF Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.2.2" extension="2019-08-01" />
            </xsl:when>
            <!-- Summary Data Section LTCF -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary' and fhir:linkId/@value = 'summary-data-group'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI LTCF R1D1] Summary Data Section LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.2.3" extension="2019-08-01" />
            </xsl:when>
            <!-- Report No Events -->
            <xsl:when
                test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary' and fhir:linkId/@value = 'report-no-events-group'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI R2D1] Report No Events Section '" />
                <templateId root="2.16.840.1.113883.10.20.5.5.62" extension="2018-04-01" />
            </xsl:when>
            <!-- NHSN Comment Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'nhsn-comment'">
                <xsl:comment select="' [HAI R1] HAI Section Generic Constraints '" />
                <templateId root="2.16.840.1.113883.10.20.5.4.26" />
                <xsl:comment select="' [HAI R3D2] NHSN Comment Section '" />
                <templateId root="2.16.840.1.113883.10.20.5.5.61" extension="2017-04-01" />
            </xsl:when>

            <!-- HAI Entries -->
            <xsl:when test="fhir:linkId/@value = 'risk-factor-central-line'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [HAI] Infection Risk Factors Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.138" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'risk-factor-birth-weight'">
                <xsl:comment select="' [C-CDA R1.1] Vital Sign Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.27" />
                <xsl:comment select="' [HAI] Infection Risk Factors Measurement Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.137" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'risk-factor-gestational-age'">
                <xsl:comment select="' [HAI R3D3] Gestational Age Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.255" extension="2018-04-01" />
            </xsl:when>
            <!-- Same as above: this is where the nullFlavor='UNK' for this template comes from -->
            <xsl:when test="fhir:linkId/@value = 'gestational-age-known'">
                <xsl:comment select="' [HAI R3D3] Gestational Age Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.255" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'inborn-outborn-observation'">
                <xsl:comment select="' [HAI R3D3] Inborn/Outborn Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.257" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'died'">
                <xsl:comment select="' [C-CDA R1.1] Deceased Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.79" />
                <xsl:comment select="' Death Observation in an Infection-type Report '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.120" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'los-contributed-to-death'">
                <xsl:comment select="' Infection Contributed to Death Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.136" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'infection-condition'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [HAI R1] Infection Condition Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.135" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'criteria-used'">
                <xsl:comment select="' [C-CDA R1.1] Indication '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.19" />
                <xsl:comment select="' [HAI R1] Criterion of Diagnosis Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.119" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'event-type'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [HAI R2N1] Infection-Type Observation '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.139" />
            </xsl:when>

            <!-- HAI LTC Entries -->
            <xsl:when test="fhir:linkId/@value = 'transfer-from-acute-care-facility'">
                <xsl:comment select="' [HAI LTCF R1D1] Transfer From Acute Care Facility to LTCF in Past Four Weeks '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.5" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'date-of-first-admission-to-facility'">
                <xsl:comment select="' [C-CDA R2.1] Encounter Activity (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.49" />
                <xsl:comment select="' [HAI LTCF R1D1] First Admission Encounter in a Lab Identified Report LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.4" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'facility-location-code'">
                <xsl:comment select="' [HAI LTCF R1D1] Summary Encounter LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.15" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = ('resident-days', 'resident-admissions', 'number-admissions-on-c-diff-treatment', 'number-c-diff-treatment-starts')">
                <xsl:comment select="' [HAI LTCF R1D1] Summary Data Observation LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.14" extension="2019-08-01" />
            </xsl:when>
            <xsl:when
                test="fhir:linkId/@value = ('no-lab-id-event-mrsa', 'no-lab-id-event-mssa', 'no-lab-id-event-vre', 'no-lab-id-event-cephr-klebsiella', 'no-lab-id-event-mrsa-cre-e-coli', 'no-lab-id-event-mrsa-cre-enterobacter', 'no-lab-id-event-cre-klebsiella', 'no-lab-id-event-mdr-acinetobacter', 'no-lab-id-event-c-difficile')">
                <xsl:comment select="' [HAI R2D1] Report No Events '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.249" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'transfer-from-acute-care-facility'">
                <xsl:comment select="' [HAI LTCF R1D1] Transfer From Acute Care Facility to LTCF in Past Four Weeks '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.5" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'antibiotic-at-time-of-transfer'">
                <xsl:comment select="' [HAI LTCF R1D1] Antibiotic Treatment at Time of Transfer '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.12" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'specific-organism-type'">
                <xsl:comment select="' [C-CDA R2.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
                <xsl:comment select="' [HAI LTCF R1D1] Pathogen Identified Observation in a Lab Identified Report LTCF '" />
                <templateId root="2.16.840.1.113883.10.20.5.1.3.3" extension="2019-08-01" />
            </xsl:when>
            <xsl:when test="fhir:linkId/@value = 'nhsn-comment'">
                <xsl:comment select="' [HAI R3D2] NHSN Comment '" />
                <templateId root="2.16.840.1.113883.10.20.5.6.243" extension="2017-04-01" />
            </xsl:when>

            <xsl:when test="@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-priority-extension'">
                <xsl:comment select="' Reportability Response Priority '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.30" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="$pElementType = 'organizer' and fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-plandefinition'">
                <xsl:comment select="' [RR R1S1] Reportability Response Coded Information Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.34" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-observation'">
                <xsl:comment select="' [RR R1S1] Relevant Reportable Condition Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.12" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="$gvCurrentIg = 'RR' and fhir:code/fhir:coding/fhir:code[@value = '304561000']">
                <xsl:comment select="' [C-CDA R2.1] Instruction (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09" />
                <xsl:comment select="' [RR R1S1] Reportability Response Summary '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.8" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="@url = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-initiation-type-extension'">
                <xsl:comment select="' [RR R1S1] Manually Initiated eICR '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.22" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="@url = 'eICRValidationOutput'">
                <xsl:comment select="' [RR R1S1] eICR Validation Output '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.33" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-reason-observation'">
                <xsl:comment select="' [RR R1S1] eICR Processing Status Reason Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.21" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-eicr-processing-status-observation'">
                <xsl:comment select="' [RR R1S1] eICR Processing Status '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.29" extension="2017-04-01" />
            </xsl:when>

            <xsl:when test="local-name() = 'DocumentReference' and fhir:type/fhir:coding/fhir:code/@value = '55751-2'">
                <xsl:comment select="' [C-CDA R2.0 External Document Reference] '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.115" extension="2014-06-09" />
                <xsl:comment select="' [RR R1S1 eICR External Document Reference] '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.10" extension="2017-04-01" />
            </xsl:when>
            <!-- Reference -->
            <!--<xsl:when test="fhir:type/fhir:coding/fhir:code/@value = '55751-2'">
                <xsl:comment select="' [C-CDA R2.0 External Document Reference] '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.115" extension="2014-06-09" />
                <xsl:comment select="' [RR R1S1 eICR External Document Reference] '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.10" extension="2017-04-01" />
            </xsl:when>-->

            <xsl:when test="parent::*/@id = 'eicr-information'">
                <xsl:comment select="' [RR R1S1] Received eICR Information '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.9" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/rr-relevant-reportable-condition-plandefinition'">
                <xsl:comment select="' [RR R1S1] Received eICR Information '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.9" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/odh/StructureDefinition/odh-UsualWork'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [ODH R1] Usual Occupation Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.221" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/odh/StructureDefinition/odh-PastOrPresentJob'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [ODH R1] Past or Present Occupation Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.217" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-status-observation'">
                <xsl:comment select="' [C-CDA R1] Pregnancy Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.3.8" />
                <xsl:comment select="' [C-CDA PREG] Pregnancy Observation (SUPPLEMENTAL PREGNANCY) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.293" extension="2020-04-01" />
                <templateId root="2.16.840.1.113883.10.20.22.4.293" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-servicerequest'">
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-procedure'">
                <xsl:comment select="' [C-CDA R2.0] Procedure Activity Procedure (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.14" extension="2014-06-09" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [C-CDA R2.1] Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" extension="2015-08-01" />
            </xsl:when>
            <!-- us-core-observation-lab containing hasMember maps to organizer (not observation) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab' and count(fhir:hasMember) > 0">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
            </xsl:when>
            <xsl:when test="fhir:category[parent::fhir:DiagnosticReport]/fhir:coding[fhir:code/@value = 'LAB']">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
            </xsl:when>
            
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
            </xsl:when>

            <!-- SG 2023-04 eCR (added) -->
            <!-- If the us-ph-lab-result-observation contains hasMember it maps to an Organizer (not Observation) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-lab-result-observation' and count(fhir:hasMember) > 0">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
            </xsl:when>
            <!-- SG 2023-04 eCR (added) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-lab-result-observation'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
            </xsl:when>

            <!-- SG 2023-04 eCR (added) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/odh/StructureDefinition/odh-EmploymentStatus'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [ODH R1D1] History of Employment Status Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.212" extension="2017-11-30" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization'">
                <xsl:comment select="' [C-CDA 2.1] Immunization Activity (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.52" extension="2015-08-01" />
            </xsl:when>
            <xsl:when test="local-name() = 'vaccineCode'">
                <xsl:comment select="' [C-CDA R2.1] Immunization Medication Information (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.54" extension="2014-06-09" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-characteristics-of-home-environment'">
                <xsl:comment select="' [C-CDA R2] Characteristics of Home Environment '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.109" />
            </xsl:when>

            <!-- SG 2023-04 eICR (updated for 3.1) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-travel-history' or fhir:code/fhir:coding/fhir:code/@value = '420008001'">
                <xsl:choose>
                    <xsl:when test="$gParamCDAeICRVersion = 'R1.1'">
                        <xsl:comment select="' [eICR R2 STU1.1] Travel History '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2.3.1" extension="2016-12-01" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment select="' [eICR R2 STU3.1] Travel History (V3) '" />
                        <templateId root="2.16.840.1.113883.10.20.15.2.3.1" extension="2022-05-01" />
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-pregnancy-outcome-observation'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA PREG] Pregnancy Outcome '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.284" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/vr-common-library/StructureDefinition/Observation-last-menstrual-period'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [COTPS R1D2] Last Menstrual Period (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.30.3.34" extension="2014-06-09" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-postpartum-status'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [C-CDA PREG] Postpartum Status  '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.285" extension="2018-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-emergency-outbreak-information'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R3] Emergency Outbreak Information Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.40" extension="2021-01-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-disability-status'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R3] Disability Status Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.47" extension="2021-01-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-exposure-contact-information'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R3] Exposure/Contact Information Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.52" extension="2021-01-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-country-of-residence'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R3] Country of Residence Observation  '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.53" extension="2021-01-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-country-of-nationality'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R3] Country of Nationality Observation '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.54" extension="2021-01-01" />
            </xsl:when>

            <!-- SG 2023-04 eCR (added for 3.1) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-vaccine-credential-patient-assertion'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains this template so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R2 STU3] Vaccine Credential Patient Assertion '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.55" extension="2021-01-01" />
            </xsl:when>

            <!-- We'll see if there is a code match first, then try the IG plus resource type -->
            <!-- Vital Sign Observation -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="fhir:category[1]/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/observation-category']/fhir:code/@value = 'vital-signs' and count(fhir:hasMember) = 0">
                <xsl:comment select="' [C-CDA R2.0] Vital Sign Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.27" />
                <xsl:comment select="' [C-CDA R2.0] Vital Sign Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.27" extension="2014-06-09" />
            </xsl:when>
            <!-- Vital Sign Organizer -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="fhir:category[1]/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/observation-category']/fhir:code/@value = 'vital-signs'">
                <xsl:comment select="' [C-CDA R2.0] Vital Sign Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.26" />
                <xsl:comment select="' [C-CDA R2.0] Vital Sign Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.26" extension="2015-08-01" />
            </xsl:when>

            <!-- Sometimes the meta is missing -->
            <xsl:when test="local-name() = 'ServiceRequest'">
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />
            </xsl:when>

            <!-- Pretty sure there are many different mappings for Device - this is just the Product Instance (participant) one -->
            <xsl:when test="$pElementType = 'participant' and local-name() = 'Device'">
                <xsl:comment select="' [C-CDA R1.1] Product Instance'" />
                <templateId root="2.16.840.1.113883.10.20.22.4.37" />
            </xsl:when>

            <!-- MedicationAdministration -->
            <xsl:when test="local-name() = 'MedicationAdministration'">
                <xsl:comment select="'[C-CDA R1.1] Medication Activity '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.16" />
                <xsl:comment select="'[C-CDA R2.0] Medication Activity (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.16" extension="2014-06-09" />
            </xsl:when>
            <!-- MedicationInformation -->
            <xsl:when test="local-name() = 'medicationCodeableConcept'">
                <xsl:comment select="' [C-CDA R2.0] Medication Information (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.23" extension="2014-06-09" />
            </xsl:when>
            
            <!-- MedicationInformation -->
            <xsl:when test="local-name() = 'medicationReference'">
                <xsl:comment select="' [C-CDA R2.0] Medication Information (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.23" extension="2014-06-09" />
            </xsl:when>

            <!--  Reportability Response Subject act -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '88084-9'">
                <xsl:comment select="' [C-CDA R2.1] Instruction (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.20" extension="2014-06-09" />
                <xsl:comment select="' [RR R1S1] Reportability Response Subject '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.7" extension="2017-04-01" />
            </xsl:when>

            <xsl:when test="local-name() = 'Condition'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [C-CDA R2.1] Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" extension="2015-08-01" />
            </xsl:when>

            <!-- MD: change 2.16.840.1.113883.10.20.22.4.54 Immunization Medication Information (V2)
                         to 2.16.840.1.113883.10.20.22.4.52 Immunization Activity (V3)
                         for fix drop Immunization resource during cda2fhir transform
            -->
            <xsl:when test="local-name() = 'Immunization'">
                <xsl:comment select="' [C-CDA R2.1] Immunization Activity (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.52" extension="2015-08-01" />
            </xsl:when>

            <!-- Entries (from fhir Components) -->
            <!-- Estimated Date of Delivery -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = ('11778-8', '11779-6', '11780-4', '11781-2', '53692-0', '53694-6', '57063-0', '57064-8')">
                <xsl:comment select="' [C-CDA PREG] Estimated Date of Delivery (SUPPLEMENTAL PREGNANCY) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.297" extension="2018-04-01" />
            </xsl:when>
            <!-- Estimated Gestational Age of Pregnancy-->
            <xsl:when
                test="fhir:code/fhir:coding/fhir:code/@value = ('11884-4', '11885-1', '11886-9', '11887-7', '11888-5', '11889-3', '11895-0', '11909-9', '11919-8', '11927-1', '11930-5', '53691-2', '53693-8', '53695-3', '57064-8')">
                <xsl:comment select="' [C-CDA PREG] Estimated Gestational Age of Pregnancy '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.280" extension="2018-04-01" />
            </xsl:when>
            <!-- Usual Industry Observation-->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '21844-6'">
                <xsl:comment select="' [ODH R1] Usual Industry Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.219" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '87729-0'">
                <xsl:comment select="' [ODH R1] Occupational Hazard Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.215" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '86188-0'">
                <xsl:comment select="' [ODH R1] Past or Present Industry Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.216" extension="2017-11-30" />
            </xsl:when>



            <!-- Participants -->
            <xsl:when test="fhir:type/fhir:coding/fhir:code/@value = 'RR7'">
                <xsl:comment select="' [RR R1S1] Routing Entity '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.4.1" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:type/fhir:coding/fhir:code/@value = 'RR8'">
                <xsl:comment select="' [RR R1S1] Responsible Agency '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.4.2" extension="2017-04-01" />
            </xsl:when>
            <xsl:when test="fhir:type/fhir:coding/fhir:code/@value = 'RR12'">
                <xsl:comment select="' [RR R1S1] Rules Authoring Agency '" />
                <!-- [RR R1S1] Rules Authoring Agency -->
                <templateId root="2.16.840.1.113883.10.20.15.2.4.3" extension="2017-04-01" />
            </xsl:when>

            <!-- SG 2023-04 eCR (updated for 3.1 added note for 1.1) -->
            <!-- Purpose of Travel -->
            <xsl:when test="fhir:code/fhir:coding/fhir:code/@value = '280147009'">
                <xsl:if test="$gParamCDAeICRVersion = 'R1.1'">
                    <xsl:comment select="' NOTE: This template is not contained in eICR R1.1 but the FHIR Bundle that has been converted contains it so the data has been preserved. '" />
                </xsl:if>
                <xsl:comment select="' [eICR R2 STU3.1] Purpose of Travel Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.51" extension="2022-05-01" />
            </xsl:when>
            
            <!-- SG 20240307: Adding social-history category -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="local-name() = 'Observation' and fhir:category[1]/fhir:coding/fhir:code/@value = 'social-history'">
                <xsl:comment select="' [C-CDA R1.1] Social History Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.38" />
                <xsl:comment select="' [C-CDA R2.1] Social History Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.38" extension="2015-08-01" />
            </xsl:when>
            
            <!-- SG 20240307: Adding laboratory category -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="local-name() = 'Observation' and fhir:category[1]/fhir:coding/fhir:code/@value = 'laboratory'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:comment select="'No profile-template map found'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Map component code to template -->
    <xsl:template match="fhir:code" mode="map-component-code-to-template">
        <xsl:choose>
            <!-- Estimated Date of Delivery -->
            <xsl:when test="@value = ('11778-8', '11779-6', '11780-4', '11781-2', '53692-0', '53694-6', '57063-0', '57064-8')">
                <xsl:comment select="' [C-CDA PREG] Estimated Date of Delivery (SUPPLEMENTAL PREGNANCY) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.297" extension="2018-04-01" />
            </xsl:when>
            <!-- Estimated Gestational Age of Pregnancy-->
            <xsl:when test="@value = ('11884-4', '11885-1', '11886-9', '11887-7', '11888-5', '11889-3', '11895-0', '11909-9', '11919-8', '11927-1', '11930-5', '53691-2', '53693-8', '53695-3', '57064-8')">
                <xsl:comment select="' [C-CDA PREG] Estimated Gestational Age of Pregnancy '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.280" extension="2018-04-01" />
            </xsl:when>
            <!-- Usual Industry Observation-->
            <xsl:when test="@value = '21844-6'">
                <xsl:comment select="' [ODH R1] Usual Industry Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.219" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="@value = '87729-0'">
                <xsl:comment select="' [ODH R1] Occupational Hazard Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.215" extension="2017-11-30" />
            </xsl:when>
            <xsl:when test="@value = '86188-0'">
                <xsl:comment select="' [ODH R1] Past or Present Industry Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.216" extension="2017-11-30" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment select="'No profile-template map found'" />
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>

    <!-- TRIGGER CODE TEMPLATES ONLY Map profile uri to trigger templates -->
    <xsl:template match="fhir:*" mode="map-trigger-resource-to-template">
        <xsl:choose>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/eicr-servicerequest'">
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Lab Test Order (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.4" extension="2019-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-condition'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [C-CDA R2.1] Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.3" extension="2021-01-01" />
            </xsl:when>

            <!-- If the us-core-observation-lab contains hasMember it maps to an Organizer (not Observation) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab' and count(fhir:hasMember) > 0">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.35" extension="2019-04-01" />
            </xsl:when>
            <xsl:when test="fhir:category[parent::fhir:DiagnosticReport]/fhir:coding[fhir:code/@value = 'LAB']">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.35" extension="2019-04-01" />
            </xsl:when>
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.2" extension="2019-04-01" />
            </xsl:when>

            <!-- SG 2023-04 eCR (added) -->
            <!-- If the us-ph-lab-result-observation contains hasMember it maps to an Organizer (not Observation) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-lab-result-observation' and count(fhir:hasMember) > 0">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.35" extension="2019-04-01" />
            </xsl:when>
            <!-- SG 2023-04 eCR (added) -->
            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/ecr/StructureDefinition/us-ph-lab-result-observation'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.2" extension="2019-04-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.2" extension="2019-04-01" />
            </xsl:when>

            <xsl:when test="fhir:meta/fhir:profile/@value = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization'">
                <xsl:comment select="' [C-CDA R2.1] Immunization Medication Information (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.54" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Immunization Medication Information '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.38" extension="2019-04-01" />
            </xsl:when>
            <xsl:when test="local-name() = 'MedicationAdministration'">
                <xsl:comment select="' [C-CDA R2.0] Medication Information (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.23" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Medication Information '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.36" extension="2019-04-01" />
            </xsl:when>
            <!-- Sometimes the meta is missing -->
            <xsl:when test="local-name() = 'Condition'">
                <xsl:comment select="' [C-CDA R1.1] Problem Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" />
                <xsl:comment select="' [C-CDA R2.1] Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.4" extension="2015-08-01" />
                <!-- MD: skip V2
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Problem Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.3" extension="2019-04-01" />  -->
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Problem Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.3" extension="2021-01-01" />
            </xsl:when>
            <xsl:when test="local-name() = 'Immunization'">
                <xsl:comment select="' [C-CDA R2.1] Immunization Medication Information (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.54" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Immunization Medication Information '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.38" extension="2019-04-01" />
            </xsl:when>
            <xsl:when test="local-name() = 'ServiceRequest'">
                <xsl:comment select="' [C-CDA R1.1] Plan of Care Activity Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" />
                <xsl:comment select="' [C-CDA R2.0] Planned Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.44" extension="2014-06-09" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Lab Test Order (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.4" extension="2019-04-01" />
            </xsl:when>
            <!-- SG 20240306: Add more missing meta processing -->
            <!-- If this is a laboratory Observation and it contains hasMember(not Observation) -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="local-name() = 'Observation' and fhir:category[1]/fhir:coding/fhir:code/@value = 'laboratory' and count(fhir:hasMember) > 0">
                <xsl:comment select="' [C-CDA R1.1] Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" />
                <xsl:comment select="' [C-CDA R2.1] Result Organizer (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.1" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Organizer '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.35" extension="2019-04-01" />
            </xsl:when>
            <!-- SG 20240306: Just a laboratory Observation without hasMember then Observation -->
            <!-- SG 20240308: Sometimes there are multiple categories - only going to use first one -->
            <xsl:when test="local-name() = 'Observation' and fhir:category[1]/fhir:coding/fhir:code/@value = 'laboratory'">
                <xsl:comment select="' [C-CDA R1.1] Result Observation '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" />
                <xsl:comment select="' [C-CDA R2.1] Result Observation (V3) '" />
                <templateId root="2.16.840.1.113883.10.20.22.4.2" extension="2015-08-01" />
                <xsl:comment select="' [eICR R2 STU2] Initial Case Report Trigger Code Result Observation (V2) '" />
                <templateId root="2.16.840.1.113883.10.20.15.2.3.2" extension="2019-04-01" />
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:comment select="'No profile-template map found'" />
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>

    <!-- Map to title -->
    <xsl:template match="fhir:*" mode="map-to-title">
        <xsl:choose>
            <!-- HAI Documents -->
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-denom'">
                <title>Late Onset Sepsis/ Meningitis Denominator</title>
            </xsl:when>
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event'">
                <title>Late Onset Sepsis/Meningitis Event (LOS) Report</title>
            </xsl:when>

            <!-- HAI LTC Documents -->
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event'">
                <title>Laboratory Identified MDRO or CDI Event Report for LTCF</title>
            </xsl:when>
            <xsl:when test="fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary'">
                <title>MDRO and CDI LabID Event Reporting Monthly Summary Data for LTCF</title>
            </xsl:when>


            <!-- HAI Sections -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'risk-factors'">
                <title>Risk Factors Section</title>
            </xsl:when>
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'event-details'">
                <title>Details Section</title>
            </xsl:when>
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai/Questionnaire/hai-questionnaire-los-event' and fhir:linkId/@value = 'findings-group'">
                <title>Findings Section</title>
            </xsl:when>

            <!-- HAI LTC Sections -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary' and fhir:linkId/@value = 'summary-data-group'">
                <title>Summary Data Section</title>
            </xsl:when>
            <xsl:when
                test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-summary' and fhir:linkId/@value = 'report-no-events-group'">
                <title>Report No Events</title>
            </xsl:when>
            <!-- Findings Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'findings-group'">
                <title>Findings Section</title>
            </xsl:when>
            <!-- Encounters Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'encounters-group'">
                <title>Encounters Section</title>
            </xsl:when>
            <!-- NHSN Comment Section -->
            <xsl:when test="preceding-sibling::fhir:questionnaire/@value = 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire/hai-ltcf-questionnaire-mdro-cdi-event' and fhir:linkId/@value = 'nhsn-comment'">
                <title>NHSN Comment Section</title>
            </xsl:when>

            <xsl:otherwise>
                <xsl:comment select="'No profile-title map found'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Map profile uri to code -->
    <xsl:template match="fhir:*" mode="map-profile-to-code">
        <xsl:choose>
            <xsl:when test="starts-with(fhir:questionnaire/@value, 'http://hl7.org/fhir/us/hai/Questionnaire')">
                <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" code="51897-7" displayName="Healthcare Associated Infection Report" />
            </xsl:when>
            <xsl:when test="starts-with(fhir:questionnaire/@value, 'http://hl7.org/fhir/us/hai-ltcf/Questionnaire')">
                <code codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" code="51897-7" displayName="Healthcare Associated Infection Report" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment select="'No profile-code map found'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



</xsl:stylesheet>
