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
    
    <!-- All the attesters that aren't the first attester with mode = legal will be Authenticators because
         CDA only allows one legalAuthenticator -->
    <xsl:template match="fhir:attester[position()!=1][parent::fhir:Composition][fhir:mode/@value = 'legal'] | fhir:attester[parent::fhir:Composition][not(fhir:mode/@value = 'legal')]">
        <xsl:for-each select="fhir:party/fhir:reference">
            <xsl:variable name="vAttesterTime">
                <xsl:value-of select="../../fhir:time/@value"/>
            </xsl:variable>
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates select="fhir:resource/fhir:*" mode="not-legal">
                    <xsl:with-param name="pAttesterTime" select="$vAttesterTime"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- MD: for attester.mode can be legal, personal, professtional or official
    now we just handle the case with mode is legal, with party as Pracitioner and PractitionerRole
    the other possible cases are Patient, ReleatedPerson, or Organization -->
    <xsl:template match="fhir:Practitioner" mode="not-legal">
        <xsl:param name="pAttesterTime"/>
        <authenticator>
            <time>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="$pAttesterTime" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </time>
            
            <signatureCode code="S" />
            <assignedEntity>
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="get-addr" />
                
                <xsl:for-each select="fhir:telecom">
                    <xsl:apply-templates select="." />
                </xsl:for-each>
                
                <assignedPerson>
                    <xsl:for-each select="fhir:name">
                        <xsl:apply-templates select="." />
                    </xsl:for-each>
                </assignedPerson>
            </assignedEntity>
        </authenticator>
    </xsl:template>
    <!--  
  For now just using PractitionerRole, we may need to relate it to organization. 
  older standard, the legal was with Practitioner. See we still need to support it 
  <xsl:template match="//fhir:entry/fhir:resource/fhir:Practitioner" mode="not-legal">
 -->
    <xsl:template match="fhir:PractitionerRole" mode="not-legal">
        <xsl:param name="pAttesterTime"/>
        <xsl:call-template name="make-authenticator">
            <xsl:with-param name="pAttesterTime" select="$pAttesterTime"></xsl:with-param>    
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="make-authenticator">
        <xsl:param name="pAttesterTime"/>
        <authenticator>
            <time>
                <xsl:attribute name="value">
                    <xsl:call-template name="Date2TS">
                        <xsl:with-param name="date" select="$pAttesterTime" />
                        <xsl:with-param name="includeTime" select="true()" />
                    </xsl:call-template>
                </xsl:attribute>
            </time>
            <signatureCode code="S" />
            <assignedEntity>
                <xsl:choose>
                    <xsl:when test="fhir:identifier">
                        <xsl:apply-templates select="fhir:identifier" />
                    </xsl:when>
                    <xsl:otherwise>
                        <id nullFlavor="NI" />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="get-addr" />
                <xsl:for-each select="fhir:telecom">
                    <xsl:apply-templates select="." />
                </xsl:for-each>
                
                <!-- MD: assignedPerson  -->
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:practitioner/fhir:reference/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="authenticator-assignedPerson" />
                </xsl:for-each>
                
                <!-- MD: representedOrganization  -->
                <xsl:variable name="referenceURI">
                    <xsl:call-template name="resolve-to-full-url">
                        <xsl:with-param name="referenceURI" select="fhir:organization/fhir:reference/@value" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:comment>Processing entry <xsl:value-of select="$referenceURI" /></xsl:comment>
                
                <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                    <xsl:apply-templates select="fhir:resource/fhir:*" mode="authenticator-representedOrganization" />
                </xsl:for-each>
                
            </assignedEntity>
        </authenticator>
    </xsl:template>
    
    <xsl:template match="fhir:Practitioner" mode="authenticator-assignedPerson">
        <assignedPerson>
            <xsl:apply-templates select="fhir:name" />
        </assignedPerson>
    </xsl:template>
    
    <xsl:template match="fhir:Organization" mode="authenticator-representedOrganization">
        <representedOrganization>
            <xsl:choose>
                <xsl:when test="fhir:identifier">
                    <xsl:apply-templates select="fhir:identifier" />
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:choose>
                <xsl:when test="fhir:name">
                    <xsl:call-template name="get-org-name" />
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="fhir:name" />
            <xsl:for-each select="fhir:telecom">
                <xsl:apply-templates select="." />
            </xsl:for-each>
            
            <xsl:choose>
                <xsl:when test="fhir:address">
                    <xsl:apply-templates select="fhir:address" />
                </xsl:when>
                <xsl:otherwise>
                    <addr nullFlavor="NI" />
                </xsl:otherwise>
            </xsl:choose>
            
        </representedOrganization>
    </xsl:template>
</xsl:stylesheet>