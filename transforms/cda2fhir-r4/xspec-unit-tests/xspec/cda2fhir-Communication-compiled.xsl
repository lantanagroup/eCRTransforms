<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">
   <!-- the tested stylesheet -->
   <xsl:import href="file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/cda2fhir-Communication.xslt"/>
   <!-- XSpec library modules providing tools -->
   <xsl:include href="file:/C:/Program%20Files/Oxygen%20XML%20Developer%2024/frameworks/xspec/src/common/runtime-utils.xsl"/>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}stylesheet-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/cda2fhir-Communication.xslt</xsl:variable>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}xspec-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/xspec-unit-tests/cda2fhir-Communication.xspec</xsl:variable>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}is-external"
                 as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                 select="false()"/>
   <!-- the main template to run the suite -->
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}main"
                 as="empty-sequence()">
      <xsl:context-item use="absent"/>
      <!-- info message -->
      <xsl:message>
         <xsl:text>Testing with </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-name')"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-version')"/>
      </xsl:message>
      <!-- set up the result document (the report) -->
      <xsl:result-document format="Q{{http://www.jenitennison.com/xslt/xspec}}xml-report-serialization-parameters">
         <xsl:element name="report" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/xspec-unit-tests/cda2fhir-Communication.xspec</xsl:attribute>
            <xsl:attribute name="stylesheet" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/cda2fhir-Communication.xslt</xsl:attribute>
            <xsl:attribute name="date" namespace="" select="current-dateTime()"/>
            <!-- invoke each compiled top-level x:scenario -->
            <xsl:for-each select="1 to 3">
               <xsl:choose>
                  <xsl:when test=". eq 1">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"/>
                  </xsl:when>
                  <xsl:when test=". eq 2">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2"/>
                  </xsl:when>
                  <xsl:when test=". eq 3">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:message terminate="yes">ERROR: Unhandled scenario invocation</xsl:message>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </xsl:element>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/xspec-unit-tests/cda2fhir-Communication.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:element name="act" namespace="urn:hl7-org:v3">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="classCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="ACT"/>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="moodCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="EVN"/>
                  <xsl:comment> [C-CDA R2.0] Handoff Communication Participants </xsl:comment>
                  <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.10.20.22.4.141"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Hand off ID</xsl:comment>
                  <xsl:element name="id" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="d839038b-2456-AABD-1c6a-467925b43857"/>
                  </xsl:element>
                  <xsl:element name="code" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="432138007"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystem"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.6.96"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystemName"
                                    namespace=""
                                    select="'', ''"
                                    separator="SNOMED CT"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="displayName"
                                    namespace=""
                                    select="'', ''"
                                    separator="handoff communication (procedure)"/>
                  </xsl:element>
                  <xsl:element name="statusCode" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="completed"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Time of Handoff </xsl:comment>
                  <xsl:element name="effectiveTime" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="value"
                                    namespace=""
                                    select="'', ''"
                                    separator="20161201"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Author Participation (care coordination) </xsl:comment>
                  <xsl:element name="author" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="AUT"/>
                     <xsl:comment> [C-CDA R2.0] Author Participation </xsl:comment>
                     <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="root"
                                       namespace=""
                                       select="'', ''"
                                       separator="2.16.840.1.113883.10.20.22.4.119"/>
                     </xsl:element>
                     <xsl:element name="time" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="value"
                                       namespace=""
                                       select="'', ''"
                                       separator="20161201"/>
                     </xsl:element>
                     <xsl:element name="assignedAuthor" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="d839038b-7171-4165-a760-467925b43857"/>
                        </xsl:element>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Healthcare Provider Taxonomy (HIPAA)"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered nurse"/>
                        </xsl:element>
                        <xsl:element name="assignedPerson" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nurse</xsl:text>
                              </xsl:element>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Florence</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
                  <xsl:comment> DataElement: Participant </xsl:comment>
                  <xsl:element name="participant" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="IRCP"/>
                     <xsl:element name="participantRole" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:comment> DataElement: Participant ID </xsl:comment>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="extension"
                                          namespace=""
                                          select="'', ''"
                                          separator="1138345"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.19"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Role </xsl:comment>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="NUCC Health Care Provider Taxonomy"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered Nurse"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Address </xsl:comment>
                        <xsl:element name="addr" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="streetAddressLine" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>1006 Health Drive</xsl:text>
                           </xsl:element>
                           <xsl:element name="city" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>Ann Arbor</xsl:text>
                           </xsl:element>
                           <xsl:element name="state" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>MI</xsl:text>
                           </xsl:element>
                           <xsl:element name="postalCode" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>97867</xsl:text>
                           </xsl:element>
                           <xsl:element name="country" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>US</xsl:text>
                           </xsl:element>
                        </xsl:element>
                        <xsl:element name="telecom" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="value"
                                          namespace=""
                                          select="'', ''"
                                          separator="tel:+1(555)555-1014"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="use"
                                          namespace=""
                                          select="'', ''"
                                          separator="WP"/>
                        </xsl:element>
                        <xsl:element name="playingEntity" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:comment> DataElement: Participant Name </xsl:comment>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nancy</xsl:text>
                              </xsl:element>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nightingale</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d54e0-doc"
                       as="document-node()">
            <xsl:document>
               <xsl:element name="act" namespace="urn:hl7-org:v3">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="classCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="ACT"/>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="moodCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="EVN"/>
                  <xsl:comment> [C-CDA R2.0] Handoff Communication Participants </xsl:comment>
                  <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.10.20.22.4.141"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Hand off ID</xsl:comment>
                  <xsl:element name="id" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="d839038b-2456-AABD-1c6a-467925b43857"/>
                  </xsl:element>
                  <xsl:element name="code" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="432138007"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystem"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.6.96"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystemName"
                                    namespace=""
                                    select="'', ''"
                                    separator="SNOMED CT"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="displayName"
                                    namespace=""
                                    select="'', ''"
                                    separator="handoff communication (procedure)"/>
                  </xsl:element>
                  <xsl:element name="statusCode" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="completed"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Time of Handoff </xsl:comment>
                  <xsl:element name="effectiveTime" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="value"
                                    namespace=""
                                    select="'', ''"
                                    separator="20161201"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Author Participation (care coordination) </xsl:comment>
                  <xsl:element name="author" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="AUT"/>
                     <xsl:comment> [C-CDA R2.0] Author Participation </xsl:comment>
                     <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="root"
                                       namespace=""
                                       select="'', ''"
                                       separator="2.16.840.1.113883.10.20.22.4.119"/>
                     </xsl:element>
                     <xsl:element name="time" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="value"
                                       namespace=""
                                       select="'', ''"
                                       separator="20161201"/>
                     </xsl:element>
                     <xsl:element name="assignedAuthor" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="d839038b-7171-4165-a760-467925b43857"/>
                        </xsl:element>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Healthcare Provider Taxonomy (HIPAA)"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered nurse"/>
                        </xsl:element>
                        <xsl:element name="assignedPerson" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nurse</xsl:text>
                              </xsl:element>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Florence</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
                  <xsl:comment> DataElement: Participant </xsl:comment>
                  <xsl:element name="participant" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="IRCP"/>
                     <xsl:element name="participantRole" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:comment> DataElement: Participant ID </xsl:comment>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="extension"
                                          namespace=""
                                          select="'', ''"
                                          separator="1138345"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.19"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Role </xsl:comment>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="NUCC Health Care Provider Taxonomy"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered Nurse"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Address </xsl:comment>
                        <xsl:element name="addr" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="streetAddressLine" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>1006 Health Drive</xsl:text>
                           </xsl:element>
                           <xsl:element name="city" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>Ann Arbor</xsl:text>
                           </xsl:element>
                           <xsl:element name="state" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>MI</xsl:text>
                           </xsl:element>
                           <xsl:element name="postalCode" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>97867</xsl:text>
                           </xsl:element>
                           <xsl:element name="country" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>US</xsl:text>
                           </xsl:element>
                        </xsl:element>
                        <xsl:element name="telecom" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="value"
                                          namespace=""
                                          select="'', ''"
                                          separator="tel:+1(555)555-1014"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="use"
                                          namespace=""
                                          select="'', ''"
                                          separator="WP"/>
                        </xsl:element>
                        <xsl:element name="playingEntity" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:comment> DataElement: Participant Name </xsl:comment>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nancy</xsl:text>
                              </xsl:element>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nightingale</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
               </xsl:element>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d54e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d54e0-doc ! ( node() )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d54e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d54e0"/>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect2">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect3">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect4">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect5">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect6">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should produce a Communication resource</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e59" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:Communication) = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:Communication) = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should produce a Communication resource'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should produce a Communication resource</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:Communication) = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e59"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should have one identifier with the correct system and a value</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e60-doc"
                    as="document-node()">
         <xsl:document>
            <xsl:element name="identifier" namespace="http://hl7.org/fhir">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
               <xsl:element name="system" namespace="http://hl7.org/fhir">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="http://hl7.org/fhir"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="value"
                                 namespace=""
                                 select="'', ''"
                                 separator="urn:ietf:rfc:3986"/>
               </xsl:element>
               <xsl:element name="value" namespace="http://hl7.org/fhir">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="http://hl7.org/fhir"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="value"
                                 namespace=""
                                 select="'', ''"
                                 separator="..."/>
               </xsl:element>
            </xsl:element>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e60"
                    select="$Q{urn:x-xspec:compile:impl}expect-d52e60-doc ! ( node() )"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="fhir:Communication/fhir:identifier"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="fhir:Communication/fhir:identifier"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should have one identifier with the correct system and a value'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d52e60, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect2</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should have one identifier with the correct system and a value</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">fhir:Communication/fhir:identifier</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e60"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should have a single status</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e64" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:Communication/fhir:status)=1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:Communication/fhir:status)=1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should have a single status'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect3</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should have a single status</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:Communication/fhir:status)=1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e64"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect4"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should have a status of completed</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e65" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:Communication/fhir:status/@value='completed') = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:Communication/fhir:status/@value='completed') = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should have a status of completed'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect4</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should have a status of completed</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:Communication/fhir:status/@value='completed') = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e65"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect5"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should have a sent date</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e66" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:Communication/fhir:sent/@value='2016-12-01') = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:Communication/fhir:sent/@value='2016-12-01') = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should have a sent date'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect5</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should have a sent date</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:Communication/fhir:sent/@value='2016-12-01') = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e66"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect6"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should have the correct reason</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e67" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:Communication/fhir:reasonCode/fhir:coding/fhir:code/@value='432138007') = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:Communication/fhir:reasonCode/fhir:coding/fhir:code/@value='432138007') = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']] Should have the correct reason'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect6</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should have the correct reason</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:Communication/fhir:reasonCode/fhir:coding/fhir:code/@value='432138007') = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e67"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry'</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/xspec-unit-tests/cda2fhir-Communication.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry'</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="mode" namespace="">bundle-entry</xsl:attribute>
               <xsl:element name="act" namespace="urn:hl7-org:v3">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="classCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="ACT"/>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="moodCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="EVN"/>
                  <xsl:comment> [C-CDA R2.0] Handoff Communication Participants </xsl:comment>
                  <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.10.20.22.4.141"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Hand off ID</xsl:comment>
                  <xsl:element name="id" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="d839038b-2456-AABD-1c6a-467925b43857"/>
                  </xsl:element>
                  <xsl:element name="code" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="432138007"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystem"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.6.96"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystemName"
                                    namespace=""
                                    select="'', ''"
                                    separator="SNOMED CT"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="displayName"
                                    namespace=""
                                    select="'', ''"
                                    separator="handoff communication (procedure)"/>
                  </xsl:element>
                  <xsl:element name="statusCode" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="completed"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Time of Handoff </xsl:comment>
                  <xsl:element name="effectiveTime" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="value"
                                    namespace=""
                                    select="'', ''"
                                    separator="20161201"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Author Participation (care coordination) </xsl:comment>
                  <xsl:element name="author" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="AUT"/>
                     <xsl:comment> [C-CDA R2.0] Author Participation </xsl:comment>
                     <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="root"
                                       namespace=""
                                       select="'', ''"
                                       separator="2.16.840.1.113883.10.20.22.4.119"/>
                     </xsl:element>
                     <xsl:element name="time" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="value"
                                       namespace=""
                                       select="'', ''"
                                       separator="20161201"/>
                     </xsl:element>
                     <xsl:element name="assignedAuthor" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="d839038b-7171-4165-a760-467925b43857"/>
                        </xsl:element>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Healthcare Provider Taxonomy (HIPAA)"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered nurse"/>
                        </xsl:element>
                        <xsl:element name="assignedPerson" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nurse</xsl:text>
                              </xsl:element>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Florence</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
                  <xsl:comment> DataElement: Participant </xsl:comment>
                  <xsl:element name="participant" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="IRCP"/>
                     <xsl:element name="participantRole" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:comment> DataElement: Participant ID </xsl:comment>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="extension"
                                          namespace=""
                                          select="'', ''"
                                          separator="1138345"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.19"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Role </xsl:comment>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="NUCC Health Care Provider Taxonomy"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered Nurse"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Address </xsl:comment>
                        <xsl:element name="addr" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="streetAddressLine" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>1006 Health Drive</xsl:text>
                           </xsl:element>
                           <xsl:element name="city" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>Ann Arbor</xsl:text>
                           </xsl:element>
                           <xsl:element name="state" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>MI</xsl:text>
                           </xsl:element>
                           <xsl:element name="postalCode" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>97867</xsl:text>
                           </xsl:element>
                           <xsl:element name="country" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>US</xsl:text>
                           </xsl:element>
                        </xsl:element>
                        <xsl:element name="telecom" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="value"
                                          namespace=""
                                          select="'', ''"
                                          separator="tel:+1(555)555-1014"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="use"
                                          namespace=""
                                          select="'', ''"
                                          separator="WP"/>
                        </xsl:element>
                        <xsl:element name="playingEntity" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:comment> DataElement: Participant Name </xsl:comment>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nancy</xsl:text>
                              </xsl:element>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nightingale</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d102e0-doc"
                       as="document-node()">
            <xsl:document>
               <xsl:element name="act" namespace="urn:hl7-org:v3">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="classCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="ACT"/>
                  <xsl:attribute xmlns="urn:hl7-org:v3"
                                 xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                 xmlns:cda="urn:hl7-org:v3"
                                 xmlns:fhir="http://hl7.org/fhir"
                                 xmlns:lcg="http://www.lantanagroup.com"
                                 name="moodCode"
                                 namespace=""
                                 select="'', ''"
                                 separator="EVN"/>
                  <xsl:comment> [C-CDA R2.0] Handoff Communication Participants </xsl:comment>
                  <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.10.20.22.4.141"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Hand off ID</xsl:comment>
                  <xsl:element name="id" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="root"
                                    namespace=""
                                    select="'', ''"
                                    separator="d839038b-2456-AABD-1c6a-467925b43857"/>
                  </xsl:element>
                  <xsl:element name="code" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="432138007"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystem"
                                    namespace=""
                                    select="'', ''"
                                    separator="2.16.840.1.113883.6.96"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="codeSystemName"
                                    namespace=""
                                    select="'', ''"
                                    separator="SNOMED CT"/>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="displayName"
                                    namespace=""
                                    select="'', ''"
                                    separator="handoff communication (procedure)"/>
                  </xsl:element>
                  <xsl:element name="statusCode" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="code"
                                    namespace=""
                                    select="'', ''"
                                    separator="completed"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Time of Handoff </xsl:comment>
                  <xsl:element name="effectiveTime" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="value"
                                    namespace=""
                                    select="'', ''"
                                    separator="20161201"/>
                  </xsl:element>
                  <xsl:comment> DataElement: Author Participation (care coordination) </xsl:comment>
                  <xsl:element name="author" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="AUT"/>
                     <xsl:comment> [C-CDA R2.0] Author Participation </xsl:comment>
                     <xsl:element name="templateId" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="root"
                                       namespace=""
                                       select="'', ''"
                                       separator="2.16.840.1.113883.10.20.22.4.119"/>
                     </xsl:element>
                     <xsl:element name="time" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:attribute xmlns="urn:hl7-org:v3"
                                       xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                       xmlns:cda="urn:hl7-org:v3"
                                       xmlns:fhir="http://hl7.org/fhir"
                                       xmlns:lcg="http://www.lantanagroup.com"
                                       name="value"
                                       namespace=""
                                       select="'', ''"
                                       separator="20161201"/>
                     </xsl:element>
                     <xsl:element name="assignedAuthor" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="d839038b-7171-4165-a760-467925b43857"/>
                        </xsl:element>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Healthcare Provider Taxonomy (HIPAA)"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered nurse"/>
                        </xsl:element>
                        <xsl:element name="assignedPerson" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nurse</xsl:text>
                              </xsl:element>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Florence</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
                  <xsl:comment> DataElement: Participant </xsl:comment>
                  <xsl:element name="participant" namespace="urn:hl7-org:v3">
                     <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                     <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                     <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                     <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                     <xsl:attribute xmlns="urn:hl7-org:v3"
                                    xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                    xmlns:cda="urn:hl7-org:v3"
                                    xmlns:fhir="http://hl7.org/fhir"
                                    xmlns:lcg="http://www.lantanagroup.com"
                                    name="typeCode"
                                    namespace=""
                                    select="'', ''"
                                    separator="IRCP"/>
                     <xsl:element name="participantRole" namespace="urn:hl7-org:v3">
                        <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                        <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                        <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                        <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                        <xsl:comment> DataElement: Participant ID </xsl:comment>
                        <xsl:element name="id" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="extension"
                                          namespace=""
                                          select="'', ''"
                                          separator="1138345"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="root"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.19"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Role </xsl:comment>
                        <xsl:element name="code" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="code"
                                          namespace=""
                                          select="'', ''"
                                          separator="163W00000X"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystem"
                                          namespace=""
                                          select="'', ''"
                                          separator="2.16.840.1.113883.6.101"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="codeSystemName"
                                          namespace=""
                                          select="'', ''"
                                          separator="NUCC Health Care Provider Taxonomy"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="displayName"
                                          namespace=""
                                          select="'', ''"
                                          separator="Registered Nurse"/>
                        </xsl:element>
                        <xsl:comment> DataElement: Participant Address </xsl:comment>
                        <xsl:element name="addr" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:element name="streetAddressLine" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>1006 Health Drive</xsl:text>
                           </xsl:element>
                           <xsl:element name="city" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>Ann Arbor</xsl:text>
                           </xsl:element>
                           <xsl:element name="state" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>MI</xsl:text>
                           </xsl:element>
                           <xsl:element name="postalCode" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>97867</xsl:text>
                           </xsl:element>
                           <xsl:element name="country" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:text>US</xsl:text>
                           </xsl:element>
                        </xsl:element>
                        <xsl:element name="telecom" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="value"
                                          namespace=""
                                          select="'', ''"
                                          separator="tel:+1(555)555-1014"/>
                           <xsl:attribute xmlns="urn:hl7-org:v3"
                                          xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                          xmlns:cda="urn:hl7-org:v3"
                                          xmlns:fhir="http://hl7.org/fhir"
                                          xmlns:lcg="http://www.lantanagroup.com"
                                          name="use"
                                          namespace=""
                                          select="'', ''"
                                          separator="WP"/>
                        </xsl:element>
                        <xsl:element name="playingEntity" namespace="urn:hl7-org:v3">
                           <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                           <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                           <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                           <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                           <xsl:comment> DataElement: Participant Name </xsl:comment>
                           <xsl:element name="name" namespace="urn:hl7-org:v3">
                              <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                              <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                              <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                              <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                              <xsl:element name="family" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nancy</xsl:text>
                              </xsl:element>
                              <xsl:element name="given" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>Nightingale</xsl:text>
                              </xsl:element>
                              <xsl:element name="suffix" namespace="urn:hl7-org:v3">
                                 <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                                 <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                                 <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                                 <xsl:namespace name="x">http://www.jenitennison.com/xslt/xspec</xsl:namespace>
                                 <xsl:text>RN</xsl:text>
                              </xsl:element>
                           </xsl:element>
                        </xsl:element>
                     </xsl:element>
                  </xsl:element>
               </xsl:element>
            </xsl:document>
         </xsl:variable>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d102e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d102e0-doc ! ( node() )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d102e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d102e0"
                                 mode="Q{}bundle-entry"/>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect2">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect3">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect4">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should produce an entry</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e125" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:entry) = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:entry) = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry' Should produce an entry'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should produce an entry</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:entry) = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e125"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should produce an entry with a full url</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e126" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:entry/fhir:fullUrl[@value]) = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:entry/fhir:fullUrl[@value]) = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry' Should produce an entry with a full url'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect2</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should produce an entry with a full url</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:entry/fhir:fullUrl[@value]) = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e126"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should produce an entry with a resource</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e127" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:entry/fhir:resource) = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:entry/fhir:resource) = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry' Should produce an entry with a resource'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect3</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should produce an entry with a resource</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:entry/fhir:resource) = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e127"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect4"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                 as="item()*"
                 required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>Should produce an entry with a full url</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d52e128" select="()"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                                xmlns:cda="urn:hl7-org:v3"
                                xmlns:fhir="http://hl7.org/fhir"
                                xmlns:lcg="http://www.lantanagroup.com"
                                select="count(fhir:entry/fhir:resource/fhir:Communication) = 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:x="http://www.jenitennison.com/xslt/xspec"
                             xmlns:cda="urn:hl7-org:v3"
                             xmlns:fhir="http://hl7.org/fhir"
                             xmlns:lcg="http://www.lantanagroup.com"
                             select="count(fhir:entry/fhir:resource/fhir:Communication) = 1"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in x:expect ('Act that matches 'cda:act[cda:templateId[@root='2.16.840.1.113883.10.20.22.4.141']]' and mode 'bundle-entry' Should produce an entry with a full url'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect4</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Should produce an entry with a full url</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="x:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(fhir:entry/fhir:resource/fhir:Communication) = 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d52e128"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Create Bundle entries for CDAR2_IG_PHCR_R2_RR_D1_2019APR_SAMPLE_ZIKA</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario3</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/cda2fhir-r4/xspec-unit-tests/cda2fhir-Communication.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Create Bundle entries for CDAR2_IG_PHCR_R2_RR_D1_2019APR_SAMPLE_ZIKA</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/samples/cda/RR-R1/RR-CDA-001_R1.xml</xsl:attribute>
            </xsl:element>
         </xsl:element>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
