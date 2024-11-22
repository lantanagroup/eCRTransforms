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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:hl7-org:v3" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
    exclude-result-prefixes="lcg xsl cda fhir">

    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />


    <!-- fhir:event[parent::fhir:Composition] -> cda:documentationOf/cda:serviceEvent -->
    <xsl:template match="fhir:event[parent::fhir:Composition]">
        <documentationOf>
            <serviceEvent classCode="PCPR">

                <!-- MD: add handle fhir:event/fhir:code -->
                <xsl:for-each select="fhir:code">
                    <xsl:apply-templates select="." />
                    <!--<xsl:call-template name="CodeableConcept2CD" />-->
                </xsl:for-each>

                <xsl:call-template name="get-effective-time">
                    <xsl:with-param name="pElement" select="fhir:period" />
                </xsl:call-template>

                <xsl:choose>
                    <xsl:when test="fhir:extension[@url = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Performer']/fhir:valueReference">
                        <xsl:for-each select="fhir:extension[@url = 'http://hl7.org/fhir/ccda/StructureDefinition/CCDA-on-FHIR-Performer']/fhir:valueReference">
                            <xsl:variable name="referenceURI">
                                <xsl:call-template name="resolve-to-full-url">
                                    <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                                <xsl:apply-templates select="fhir:resource/fhir:*" mode="event-performer" />
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:when>

                    <!-- MD: Not sure we need <performer> it cause cda2fhir issue comment it for now
          <xsl:otherwise>
            <performer typeCode="PRF" nullFlavor="NI">
              <assignedEntity nullFlavor="NI">
                <id nullFlavor="NI" />
                <assignedPerson nullFlavor="NI" />
              </assignedEntity>
            </performer>
          </xsl:otherwise>-->

                </xsl:choose>

            </serviceEvent>
        </documentationOf>
    </xsl:template>

    <!-- Template: make-encompassing-encounter-hai
         Creates the HAI encompassingEncounter from the Questionnaire -->
    <xsl:template name="make-service-event-hai">
        <xsl:comment select="' The period reported '" />
        <documentationOf>
            <serviceEvent classCode="CASE">
                <code codeSystem="2.16.840.1.113883.6.277" codeSystemName="cdcNHSN" code="1891-1" displayName="Summary data reporting MDRO and CDI LabID Event Monthly Summary Data for LTCF" />
                <effectiveTime>
                    <xsl:comment select="' the first day of the period reported '" />
                    <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'report-period-start']/fhir:answer/fhir:valueDate">
                        <xsl:with-param name="pElementName">low</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:comment select="' the last day of the period reported '" />
                    <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'report-period-end']/fhir:answer/fhir:valueDate">
                        <xsl:with-param name="pElementName">high</xsl:with-param>
                    </xsl:apply-templates>
                </effectiveTime>
            </serviceEvent>
        </documentationOf>
    </xsl:template>



    <xsl:template match="fhir:entry/fhir:resource/fhir:Practitioner" mode="event-performer">
        <xsl:call-template name="make-performer" />
    </xsl:template>


</xsl:stylesheet>
