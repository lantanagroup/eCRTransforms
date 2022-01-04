<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3" 
    xmlns:fhir="http://hl7.org/fhir" 
    xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml"
    version="2.0">



    <xsl:template
        match="cda:ClinicalDocument/cda:authorization"
        mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry"/>
    </xsl:template>
    
    
    <xsl:template
        match="cda:ClinicalDocument/cda:authorization">
        <Consent xmlns="http://hl7.org/fhir">
            
        </Consent>
    </xsl:template>
    
    <!--

    <xsl:template
        match="cda:organizer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.108']]"
        mode="bundle-entry">
        <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
            <xsl:call-template name="create-bundle-entry"/>
            <xsl:for-each select="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]">
                <xsl:call-template name="create-payor-org-entry"/>
            </xsl:for-each>
            <xsl:for-each select="cda:participant[@typeCode= 'HLD']">
                <xsl:call-template name="create-bundle-entry"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    
    
    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.60']]"
        mode="reference">
        <xsl:param name="wrapping-elements"/>
        <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
            <xsl:apply-templates select="." mode="reference">
            	<xsl:with-param name="wrapping-elements" select="$wrapping-elements"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
	

    <xsl:template
        match="cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.61']]">
        <Coverage>
            <xsl:call-template name="add-meta" />
            <xsl:apply-templates select="cda:id"/>
            <status value="active"/>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            
            <xsl:if test="cda:participant[@typeCode= 'HLD']">
                <policyHolder>
                    <xsl:apply-templates select="cda:participant[@typeCode= 'HLD']" mode="reference"/>
                </policyHolder>
            </xsl:if>

            <xsl:call-template name="subject-reference">
                <xsl:with-param name="pElementName">beneficiary</xsl:with-param>
            </xsl:call-template>
            <xsl:if test="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]
                [cda:assignedEntity[cda:code[@code = 'PAYOR']]]">
                <payor>
                    <xsl:apply-templates select="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]" mode="reference"/>
                </payor>
            </xsl:if>
        </Coverage>
    </xsl:template>
    
   
    <xsl:template match="cda:performer[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.87']]/cda:assignedEntity[cda:code[@code = 'PAYOR']]" mode="payor">
        <Organization>
            <xsl:apply-templates select="cda:id"/>
            <xsl:apply-templates select="cda:code">
                <xsl:with-param name="pElementName">type</xsl:with-param>
            </xsl:apply-templates>
            <xsl:if test="cda:representedOrganization/cda:name">
                <name>
                    <xsl:attribute name="value">
                        <xsl:value-of select="cda:representedOrganization/cda:name"/>
                    </xsl:attribute>
                </name>
            </xsl:if>
            <xsl:apply-templates select="cda:telecom"/>
            <xsl:apply-templates select="cda:addr"/>
        </Organization>
    </xsl:template>
   
    
    -->
    
</xsl:stylesheet>
