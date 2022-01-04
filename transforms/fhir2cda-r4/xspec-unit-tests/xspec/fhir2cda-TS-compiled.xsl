<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">
   <!-- the tested stylesheet -->
   <xsl:import href="file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/fhir2cda-TS.xslt"/>
   <!-- XSpec library modules providing tools -->
   <xsl:include href="file:/C:/Program%20Files/Oxygen%20XML%20Developer%2024/frameworks/xspec/src/common/runtime-utils.xsl"/>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}stylesheet-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/fhir2cda-TS.xslt</xsl:variable>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}xspec-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:variable>
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
            <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
            <xsl:attribute name="stylesheet" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/fhir2cda-TS.xslt</xsl:attribute>
            <xsl:attribute name="date" namespace="" select="current-dateTime()"/>
            <!-- invoke each compiled top-level x:scenario -->
            <xsl:for-each select="1 to 5">
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
                  <xsl:when test=". eq 4">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4"/>
                  </xsl:when>
                  <xsl:when test=". eq 5">
                     <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5"/>
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
      <xsl:message>Simple date: YYYY</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Simple date: YYYY</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:call" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
               <xsl:attribute name="template" namespace="">Date2TS</xsl:attribute>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">date</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'2017'</xsl:attribute>
               </xsl:element>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">includeTime</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'no_value'</xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}date"
                          select="'2017'"/>
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}includeTime"
                          select="'no_value'"/>
            <xsl:call-template name="Q{}Date2TS">
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}date"
                               select="$Q{}date"/>
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}includeTime"
                               select="$Q{}includeTime"/>
            </xsl:call-template>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>The result should be 2017</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e7-doc" as="document-node()">
         <xsl:document>
            <xsl:text>2017</xsl:text>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e7"
                    select="$Q{urn:x-xspec:compile:impl}expect-d54e7-doc ! ( node() )"><!--expected result--></xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d54e7, $Q{http://www.jenitennison.com/xslt/xspec}result, '')"/>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>The result should be 2017</xsl:text>
         </xsl:element>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d54e7"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Simple date: YYYY-MM</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Simple date: YYYY-MM</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:call" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
               <xsl:attribute name="template" namespace="">Date2TS</xsl:attribute>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">date</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'2017-10'</xsl:attribute>
               </xsl:element>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">includeTime</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'no_value'</xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}date"
                          select="'2017-10'"/>
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}includeTime"
                          select="'no_value'"/>
            <xsl:call-template name="Q{}Date2TS">
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}date"
                               select="$Q{}date"/>
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}includeTime"
                               select="$Q{}includeTime"/>
            </xsl:call-template>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>The result should be 201710</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e13-doc"
                    as="document-node()">
         <xsl:document>
            <xsl:text>201710</xsl:text>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e13"
                    select="$Q{urn:x-xspec:compile:impl}expect-d54e13-doc ! ( node() )"><!--expected result--></xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d54e13, $Q{http://www.jenitennison.com/xslt/xspec}result, '')"/>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>The result should be 201710</xsl:text>
         </xsl:element>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d54e13"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Simple date: YYYY-MM-DD</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario3</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Simple date: YYYY-MM-DD</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:call" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
               <xsl:attribute name="template" namespace="">Date2TS</xsl:attribute>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">date</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'2017-10-01'</xsl:attribute>
               </xsl:element>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">includeTime</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'no_value'</xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}date"
                          select="'2017-10-01'"/>
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}includeTime"
                          select="'no_value'"/>
            <xsl:call-template name="Q{}Date2TS">
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}date"
                               select="$Q{}date"/>
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}includeTime"
                               select="$Q{}includeTime"/>
            </xsl:call-template>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>The result should be 20171001</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e19-doc"
                    as="document-node()">
         <xsl:document>
            <xsl:text>20171001</xsl:text>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e19"
                    select="$Q{urn:x-xspec:compile:impl}expect-d54e19-doc ! ( node() )"><!--expected result--></xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d54e19, $Q{http://www.jenitennison.com/xslt/xspec}result, '')"/>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario3-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>The result should be 20171001</xsl:text>
         </xsl:element>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d54e19"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Date with time: YYYY-MM-DDThh:mm:ss+zz:zz</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario4</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Date with time: YYYY-MM-DDThh:mm:ss+zz:zz</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:call" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
               <xsl:attribute name="template" namespace="">Date2TS</xsl:attribute>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">date</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'2015-02-07T13:28:17-05:00'</xsl:attribute>
               </xsl:element>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">includeTime</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'no_value'</xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}date"
                          select="'2015-02-07T13:28:17-05:00'"/>
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}includeTime"
                          select="'no_value'"/>
            <xsl:call-template name="Q{}Date2TS">
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}date"
                               select="$Q{}date"/>
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}includeTime"
                               select="$Q{}includeTime"/>
            </xsl:call-template>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>The result should be 20150207132817-0500</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e25-doc"
                    as="document-node()">
         <xsl:document>
            <xsl:text>20150207132817-0500</xsl:text>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e25"
                    select="$Q{urn:x-xspec:compile:impl}expect-d54e25-doc ! ( node() )"><!--expected result--></xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d54e25, $Q{http://www.jenitennison.com/xslt/xspec}result, '')"/>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario4-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>The result should be 20150207132817-0500</xsl:text>
         </xsl:element>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d54e25"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Date with time: YYYY-MM-DDThh:mm:ss+zz:zz</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario5</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/C:/Users/minigrrl/Dropbox/12_SourceControl/GitHub/Lantana/FHIRTransforms/transforms/fhir2cda-r4/xspec-unit-tests/fhir2cda-TS.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Date with time: YYYY-MM-DDThh:mm:ss+zz:zz</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="x:call" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
               <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
               <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
               <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
               <xsl:attribute name="template" namespace="">Date2TS</xsl:attribute>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">date</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'2017-10-01T10:35:00+10:00'</xsl:attribute>
               </xsl:element>
               <xsl:element name="x:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="cda">urn:hl7-org:v3</xsl:namespace>
                  <xsl:namespace name="fhir">http://hl7.org/fhir</xsl:namespace>
                  <xsl:namespace name="lcg">http://www.lantanagroup.com</xsl:namespace>
                  <xsl:namespace name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:namespace>
                  <xsl:attribute name="name" namespace="">includeTime</xsl:attribute>
                  <xsl:attribute name="select" namespace="">'no_value'</xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}date"
                          select="'2017-10-01T10:35:00+10:00'"/>
            <xsl:variable xmlns:x="http://www.jenitennison.com/xslt/xspec"
                          xmlns:cda="urn:hl7-org:v3"
                          xmlns:fhir="http://hl7.org/fhir"
                          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                          xmlns:lcg="http://www.lantanagroup.com"
                          name="Q{}includeTime"
                          select="'no_value'"/>
            <xsl:call-template name="Q{}Date2TS">
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}date"
                               select="$Q{}date"/>
               <xsl:with-param xmlns:x="http://www.jenitennison.com/xslt/xspec"
                               xmlns:cda="urn:hl7-org:v3"
                               xmlns:fhir="http://hl7.org/fhir"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               xmlns:lcg="http://www.lantanagroup.com"
                               name="Q{}includeTime"
                               select="$Q{}includeTime"/>
            </xsl:call-template>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                 as="item()*"
                 required="yes"/>
      <xsl:message>The result should be 20171001103500+1000</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e31-doc"
                    as="document-node()">
         <xsl:document>
            <xsl:text>20171001103500+1000</xsl:text>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d54e31"
                    select="$Q{urn:x-xspec:compile:impl}expect-d54e31-doc ! ( node() )"><!--expected result--></xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d54e31, $Q{http://www.jenitennison.com/xslt/xspec}result, '')"/>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario5-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>The result should be 20171001103500+1000</xsl:text>
         </xsl:element>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d54e31"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
