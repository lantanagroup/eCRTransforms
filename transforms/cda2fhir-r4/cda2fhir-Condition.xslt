<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt"/>

    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
        <xsl:apply-templates select="cda:author" mode="bundle-entry"/>
    </xsl:template>
    
    

    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]">
        

        <Condition xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">
            
            <!-- Check current Ig -->
            <xsl:variable name="vCurrentIg">
                <xsl:apply-templates select="/" mode="currentIg"/>
            </xsl:variable>
            
            <!-- Set profiles based on Ig and Resource if it is needed -->
            <xsl:choose>
                <xsl:when test="$vCurrentIg='NA'">
                    <xsl:call-template name="add-meta"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$vCurrentIg"/>
                            <xsl:with-param name="pResource" select="'Condition'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$vProfileValue ne 'NA'">
                            <meta>
                                <profile>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="$vProfileValue"/>
                                    </xsl:attribute>
                                </profile>
                            </meta>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            
            <!-- 
            <xsl:call-template name="add-meta"/>
             -->
            <xsl:apply-templates select="../preceding-sibling::cda:id"/>
            <xsl:apply-templates select="cda:id"/>
            <xsl:choose>
                <xsl:when
                    test="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.6']">
                    <xsl:apply-templates
                        select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.6']"
                        mode="condition"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Observation could be in Encounter entryRelationship, there is no statusCode in ancestor::cda:entry/cda:act/cda:statusCode
                        in the context of encounter, the cda:statusCode is in cda:entryRelationship level. Not sure we need enforce this by the 
                        for cda2fhir in xSpec since clinicalStatus is option in fhir -->
                    <xsl:choose>
                        <xsl:when test="ancestor::cda:entry/cda:act/cda:statusCode">
                            <xsl:apply-templates select="ancestor::cda:entry/cda:act/cda:statusCode"
                                mode="condition"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="cda:statusCode"
                                mode="condition"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <!-- SG 2024-02-05: Updated negationInd processing for eCR -->
            <xsl:choose>
                <xsl:when test="@negationInd = 'true' and cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.3']">
                    <verificationStatus>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-ver-status"/>
                            <code value="entered-in-error"/>
                        </coding>
                    </verificationStatus>
                </xsl:when>
                <xsl:when test="@negationInd = 'true' and not(cda:value/@code = '55607006')">
                    <verificationStatus>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-ver-status"/>
                            <code value="refuted"/>
                        </coding>
                    </verificationStatus>
                </xsl:when>
            </xsl:choose>
            
            <xsl:choose>
                <xsl:when
                    test="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.80']]">
                    <category>
                        <coding>
                          <system value="http://terminology.hl7.org/CodeSystem/condition-category"/>
                            <code value="encounter-diagnosis"/>
                        </coding>
                    </category>
                </xsl:when>
                <xsl:when test="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132']]">
                    <xsl:apply-templates select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132']]/cda:code">
                        <xsl:with-param name="pElementName">category</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                
                <xsl:when test="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]">
                    <xsl:apply-templates select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:code">
                        <xsl:with-param name="pElementName">category</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:code" mode="condition"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates select="cda:value" mode="condition"/>

            <xsl:call-template name="subject-reference"/>
            <xsl:apply-templates select="cda:effectiveTime" mode="condition"/>
            <xsl:call-template name="author-reference">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:call-template>

            <xsl:for-each
                select="cda:entryRelationship[@typeCode = 'REFR']/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.122']">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">evidence/detail</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:if test="cda:text">
                <xsl:variable name="text">
                    <xsl:apply-templates select="cda:text"/>
                </xsl:variable>
                <xsl:if test="string-length($text) &gt; 0">
                    <note>
                        <text value="{normalize-space(cda:text)}"/>
                    </note>
                </xsl:if>
            </xsl:if>
            <xsl:if test="@negationInd = 'true' and not(cda:value/@code = '55607006')">
                <note>
                    <text
                        value="This condition was converted from a C-CDA document. It was marked as negated in that file, so marked as refuted in FHIR"
                    />
                </note>
            </xsl:if>
        </Condition>
    </xsl:template>

    <xsl:template match="cda:statusCode" mode="condition">
        <clinicalStatus>
            <coding>
                <system value="http://terminology.hl7.org/CodeSystem/condition-clinical"/>
                <code>
                    <xsl:choose>
                        <xsl:when test="@code = 'completed'">
                            <xsl:attribute name="value">resolved</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="value" select="@code"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </code>
            </coding>
        </clinicalStatus>
    </xsl:template>

    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.6']"
        mode="condition">

        <xsl:for-each select="cda:value">
            <clinicalStatus>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/condition-clinical"/>

                    <xsl:choose>
                        <xsl:when test="@code = '55561003'">
                            <code value="active"/>
                        </xsl:when>
                        <xsl:when test="@code = '73425007'">
                            <code value="inactive"/>
                        </xsl:when>
                        <xsl:when test="@code = '413322009'">
                            <code value="resolved"/>
                        </xsl:when>
                    </xsl:choose>
                </coding>
            </clinicalStatus>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="condition">
        <xsl:if test="cda:low/@value">
            <onsetDateTime value="{lcg:cdaTS2date(cda:low/@value)}"/>
        </xsl:if>
        <xsl:if test="cda:high/@value">
            <abatementDateTime value="{lcg:cdaTS2date(cda:high/@value)}"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:code" mode="condition">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">category</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:value" mode="condition">
        <xsl:choose>
            <xsl:when test="../@negationInd = 'true' and @code = '55607006'">
                <code>
                    <coding>
                        <system value="http://snomed.info/sct"/>
                        <code value="160245001"/>
                        <display value="No known problems"/>
                    </coding>
                </code>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="newCreateCodableConcept">
                    <xsl:with-param name="pElementName">code</xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Using the assumption that all ids of cda MTP medications always have a root and an extension as a way
                to distinguish when a medication reference is being made -->
    <!--
    <xsl:template name="create-medication-entry">
        <xsl:for-each select="cda:entryRelationship[@typeCode='REFR']/cda:act[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.122']">

            <xsl:if test="cda:id/@root and cda:id/@extension">
                <entry>
                    <fullUrl value="urn:uuid:{@lcg:uuid}"/>
                    <resource>
                        <xsl:apply-templates select="." mode="medication"/>
                    </resource>
                </entry>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="cda:act" mode="medication">
        <xsl:variable name="root" select="cda:id/@root"/>
        <xsl:variable name="extension" select="cda:id/@extension"/>
        <Medication>
            <xsl:for-each select="//cda:substanceAdministration
                [cda:templateId[@root='2.16.840.1.113883.10.20.37.3.10'][@extension='2017-08-01']]
                [cda:id[@root=$root][@extension=$extension]]">
                <xsl:apply-templates select="cda:consumable/cda:manufacturedProduct/cda:manufacturedMaterial/cda:code">
                    <xsl:with-param name="pElementName">code</xsl:with-param>
                </xsl:apply-templates>
                <status value="{cda:statusCode/@code}"/>
            </xsl:for-each>
        </Medication>
    </xsl:template>
    -->
</xsl:stylesheet>
