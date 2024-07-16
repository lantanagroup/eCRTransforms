<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <!-- Create bundle entries for the Problem Observation (Condition) and any authors or performers -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:informant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />

        <xsl:for-each select="cda:author | cda:informant | cda:performer[position() > 1]">
            <xsl:apply-templates select="." mode="provenance" />
        </xsl:for-each>

        <xsl:apply-templates select="cda:entryRelationship/cda:*" mode="bundle-entry" />
    </xsl:template>

    <!-- TEMPLATE: Remove Concern/Admission Diagnosis wrappers -->
    <xsl:template match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132'] or
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3'] or
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.30'] or
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.136'] or
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.34']]" mode="reference">
        <xsl:param name="wrapping-elements" />
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="reference">
                <xsl:with-param name="wrapping-elements" select="$wrapping-elements" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- TEMPLATE: Remove Concern/Adminssion Diagnosis wrappers -->
    <xsl:template match="
            cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.132'] or
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3'] or 
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.30'] or 
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.136']or 
            cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.34']]"
        mode="bundle-entry">
        <!-- Create bundle entries for any authors or performers -->
        <xsl:apply-templates select="cda:author" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <!-- Create provenance entries for any authors or performers -->
        <xsl:apply-templates select="cda:author" mode="provenance" />
        <xsl:apply-templates select="cda:performer" mode="provenance" />
        <xsl:for-each select="cda:entryRelationship/cda:*[not(@nullFlavor)]">
            <xsl:apply-templates select="." mode="bundle-entry" />
        </xsl:for-each>
    </xsl:template>

    <!-- C-CDA Problem Observation -->
    <xsl:template match="cda:observation[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.4']]">
        <Condition xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://hl7.org/fhir">

            <!-- Set profiles based on IG and Resource if it is needed -->
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'NA'">
                    <xsl:call-template name="add-meta" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="vProfileValue">
                        <xsl:call-template name="get-profile-for-ig">
                            <xsl:with-param name="pIg" select="$gvCurrentIg" />
                            <xsl:with-param name="pResource" select="'Condition'" />
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$vProfileValue ne 'NA'">
                            <meta>
                                <profile>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="$vProfileValue" />
                                    </xsl:attribute>
                                </profile>
                            </meta>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:apply-templates select="cda:id" />
            <!-- clinicalStatus: check both effectiveTime and potentially a contained Problem Status Observation -->
            <clinicalStatus>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/condition-clinical" />
                    <code>
                        <xsl:choose>
                            <xsl:when test="cda:effectiveTime/cda:high or cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.6']/cda:value/@code='413322009'">
                                <xsl:attribute name="value">resolved</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.6']/cda:value/@code='246455001'">
                                <xsl:attribute name="value">recurrence</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.6']/cda:value/@code='263855007'">
                                <xsl:attribute name="value">relapse</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.6']/cda:value/@code='277022003'">
                                <xsl:attribute name="value">remission</xsl:attribute>
                            </xsl:when>
                            <xsl:when test="cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.6']/cda:value/@code='55561003'">
                                <xsl:attribute name="value">active</xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="value">active</xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                    </code>
                </coding>
            </clinicalStatus>
            <!-- SG 2024-02-05: Updated negationInd processing for eCR -->
            <xsl:choose>
                <xsl:when test="@negationInd = 'true' and cda:templateId[@root = '2.16.840.1.113883.10.20.15.2.3.3']">
                    <verificationStatus>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-ver-status" />
                            <code value="entered-in-error" />
                        </coding>
                    </verificationStatus>
                </xsl:when>
                <xsl:when test="@negationInd = 'true' and not(cda:value/@code = '55607006')">
                    <verificationStatus>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-ver-status" />
                            <code value="refuted" />
                        </coding>
                    </verificationStatus>
                </xsl:when>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.80']]">
                    <category>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-category" />
                            <code value="encounter-diagnosis" />
                        </coding>
                    </category>
                </xsl:when>
                <xsl:otherwise>
                    <category>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/condition-category" />
                            <code value="problem-list-item" />
                        </coding>
                    </category>
                </xsl:otherwise>

            </xsl:choose>

            <xsl:apply-templates select="cda:value" mode="condition" />

            <xsl:call-template name="subject-reference" />
            <xsl:apply-templates select="cda:effectiveTime" mode="condition" />

            <!-- recordedDate (max 1) -->
            <xsl:choose>
                <xsl:when test="cda:author[1]/cda:time">
                    <xsl:apply-templates select="cda:author[1]/cda:time" mode="instant">
                        <xsl:with-param name="pElementName">recordedDate</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:effectiveTime/cda:low/@value">
                    <xsl:apply-templates select="ancestor::cda:act[cda:templateId[@root = '2.16.840.1.113883.10.20.22.4.3']]/cda:effectiveTime" mode="instant">
                        <xsl:with-param name="pElementName">recordedDate</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>

            <!-- recorder (max 1) (can only be Practitioner, PractitionerRole, Patient, RelatedPerson -->
            <xsl:apply-templates select="cda:author[cda:assignedAuthor/cda:assignedPerson[1]]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">recorder</xsl:with-param>
            </xsl:apply-templates>

            <!-- asserter (max 1)-->
            <xsl:apply-templates select="cda:performer[1]" mode="rename-reference-participant">
                <xsl:with-param name="pElementName">asserter</xsl:with-param>
            </xsl:apply-templates>

            <xsl:for-each select="cda:entryRelationship[@typeCode = 'REFR']/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.122']">
                <xsl:apply-templates select="." mode="reference">
                    <xsl:with-param name="wrapping-elements">evidence/detail</xsl:with-param>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- note -->
            <xsl:if test="cda:text | cda:text">
                <xsl:for-each select="cda:text">
                    
                    <xsl:variable name="vText">
                        <xsl:call-template name="get-reference-text">
                            <xsl:with-param name="pTextElement" select="." />
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:if test="string-length($vText) > 0">
                        <note>
                            <text>
                                <xsl:attribute name="value" select="$vText" />
                            </text>
                        </note>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="@negationInd = 'true' and not(cda:value/@code = '55607006')">
                <note>
                    <text value="This condition was converted from a C-CDA document. It was marked as negated in that file, so marked as refuted in FHIR" />
                </note>
            </xsl:if>
        </Condition>
    </xsl:template>

    <!-- C-CDA Problem Status -->
    <xsl:template match="cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.6']" mode="condition">
        <xsl:for-each select="cda:value">
            <clinicalStatus>
                <coding>
                    <system value="http://terminology.hl7.org/CodeSystem/condition-clinical" />

                    <xsl:choose>
                        <xsl:when test="@code = '55561003'">
                            <code value="active" />
                        </xsl:when>
                        <xsl:when test="@code = '73425007'">
                            <code value="inactive" />
                        </xsl:when>
                        <xsl:when test="@code = '413322009'">
                            <code value="resolved" />
                        </xsl:when>
                    </xsl:choose>
                </coding>
            </clinicalStatus>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="condition">
        <xsl:if test="cda:low/@value">
            <onsetDateTime value="{lcg:cdaTS2date(cda:low/@value)}" />
        </xsl:if>
        <xsl:if test="cda:high/@value">
            <abatementDateTime value="{lcg:cdaTS2date(cda:high/@value)}" />
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
                        <system value="http://snomed.info/sct" />
                        <code value="160245001" />
                        <display value="No known problems" />
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
</xsl:stylesheet>
