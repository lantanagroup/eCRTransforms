<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:import href="c-to-fhir-utility.xslt" />
    <xsl:import href="cda2fhir-Narrative.xslt" />
    <xsl:import href="cda2fhir-Practitioner.xslt" />
    <xsl:import href="cda2fhir-PractitionerRole.xslt" />
    <xsl:import href="cda2fhir-Organization.xslt" />

    <xsl:template match="cda:encompassingEncounter" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />
        <xsl:apply-templates select="cda:responsibleParty[not(@nullFlavor)]/cda:assignedEntity[not(@nullFlavor)]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:location[not(@nullFlavor)]" mode="bundle-entry" />
        <!-- Added location/healthCareFacility to path so this is picked up -->
        <xsl:apply-templates select="cda:location/cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]" mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']" mode="bundle-entry">
        <!-- Variable for identification of IG - moved out of Global var because XSpec can't deal with global vars -->
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
                <!-- MD add Dental templateId -->
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.2']">DentalConsultNote</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.1']">DentalReferalNote</xsl:when>
                <xsl:otherwise>NA</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Don't want a second encounter if this is eICR -->
        <xsl:if test="$vCurrentIg != 'eICR'">
            <xsl:call-template name="create-bundle-entry" />
            <xsl:apply-templates select="cda:responsibleParty[not(@nullFlavor)]/cda:assignedEntity[not(@nullFlavor)]" mode="bundle-entry" />
            <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
            <xsl:apply-templates select="cda:location[not(@nullFlavor)]" mode="bundle-entry" />
        </xsl:if>
        <xsl:apply-templates select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']/cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']"
            mode="bundle-entry" />
    </xsl:template>

    <xsl:template match="cda:encompassingEncounter[not(@nullFlavor)] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']">
        <xsl:variable name="vCurrentIg">
            <xsl:choose>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2']">eICR</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.15.2.1.2']">RR</xsl:when>
                <!-- MD add Dental templateId -->
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.2']">DentalConsultNote</xsl:when>
                <xsl:when test="/cda:ClinicalDocument[cda:templateId/@root = '2.16.840.1.113883.10.20.40.1.1.1']">DentalReferalNote</xsl:when>
                <xsl:otherwise>NA</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Encounter>
            <xsl:comment>In Encounter</xsl:comment>
            <xsl:choose>
                <xsl:when test="$vCurrentIg = 'eICR'">
                    <xsl:call-template name="add-participant-meta" />
                    <!-- For eICR we need to grab the Encounter section text -->
                    <text>
                        <xsl:choose>
                            <xsl:when
                                test="count(//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:entry) = count(//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:entry[@typeCode = 'DRIV'])">
                                <status value="generated" />
                            </xsl:when>
                            <xsl:otherwise>
                                <status value="additional" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <div xmlns="http://www.w3.org/1999/xhtml">
                            <xsl:apply-templates select="//cda:section[cda:templateId/@root = '2.16.840.1.113883.10.20.22.2.22.1']/cda:text" />
                            <p>...</p>
                        </div>
                    </text>
                </xsl:when>
                <xsl:otherwise>
                    <!--<xsl:call-template name="add-meta" /> -->
                    <!-- Check current Ig -->
                    <xsl:variable name="vCurrentIg">
                        <xsl:apply-templates select="/" mode="currentIg" />
                    </xsl:variable>

                    <!-- set meta profile based on Ig -->
                    <xsl:choose>
                        <xsl:when test="$vCurrentIg = 'NA'">
                            <xsl:call-template name="add-meta" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="vProfileValue">
                                <xsl:call-template name="get-profile-for-ig">
                                    <xsl:with-param name="pIg" select="$vCurrentIg" />
                                    <xsl:with-param name="pResource" select="'Encounter'" />
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

                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:id" />

            <xsl:if test="local-name(.) eq 'encounter'">
                <xsl:choose>
                    <xsl:when test="@moodCode = 'EVN'">
                        <status value="finished" />
                    </xsl:when>
                    <xsl:when test="@moodCode = 'INT' or @moodCode = 'RQO'">
                        <status value="planned" />
                    </xsl:when>
                    <xsl:otherwise>
                        <status value="unknown" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>

            <!-- Added to deal with status of encompassingEncounter -->
            <xsl:if test="local-name(.) eq 'encompassingEncounter'">
                <!-- Use times to find out the status of the encounter -->
                <xsl:choose>
                    <xsl:when test="not(cda:effectiveTime)">
                        <status value="unknown" />
                    </xsl:when>
                    <xsl:when test="cda:effectiveTime/cda:high">
                        <status value="finished" />
                    </xsl:when>
                    <xsl:otherwise>
                        <status value="in-progress" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>

            <!-- These are the other way round in the eCR encompassingEncounter - 
           translation goes in type and code goes in class -->
            <!-- RG: The above comment and the eICR specific code below is based on a false assumption. Encounter.class is not a code vs. translation thing, it is a codeSystem thing in this case. 
           Fixed for other IGs (see <otherwise> below) but leaving eICR as is for now. 
           Next eICR person reading this should review and see if the special eICR code is even needed. -->
            <!--  MD: Using RG suggestion
            <xsl:choose>
                <xsl:when test="$vCurrentIg = 'eICR'">
                    <xsl:for-each select="cda:code">
                        <class>
                            <xsl:call-template name="createCodeableConceptContent">
                                <xsl:with-param name="code" select="@code" />
                                <xsl:with-param name="codeSystem" select="@codeSystem" />
                                <xsl:with-param name="displayName" select="@displayName" />
                            </xsl:call-template>
                        </class>
                    </xsl:for-each>

                    <xsl:for-each select="cda:code/cda:translation">
                        <xsl:call-template name="newCreateCodableConcept">
                            <xsl:with-param name="pElementName" select="'type'" />
                            <xsl:with-param name="includeCoding" select="true()" />
                            <xsl:with-param name="includeTranslations" select="false()" />
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                
                <xsl:when test="$vCurrentIg eq 'DentalConsultNote' or $vCurrentIg eq 'DentalReferalNote'">
                    <xsl:for-each select="cda:code">
                        <class>
                            <xsl:call-template name="createCodeableConceptContent">
                                <xsl:with-param name="code" select="@code" />
                                <xsl:with-param name="codeSystem" select="@codeSystem" />
                                <xsl:with-param name="displayName" select="@displayName" />
                            </xsl:call-template>
                        </class>
                    </xsl:for-each>

                    <xsl:for-each select="cda:code/cda:translation">
                        <xsl:call-template name="newCreateCodableConcept">
                            <xsl:with-param name="pElementName" select="'type'" />
                            <xsl:with-param name="includeCoding" select="true()" />
                            <xsl:with-param name="includeTranslations" select="false()" />
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
               
                <xsl:otherwise>   -->
                    <!-- RG: If any code or translation is from the ActCode code system, use that to populate class, otherwise make it a nullFlavor -->
                    <xsl:choose>
                        <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.5.4']">
                            <class>
                                <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                                <code value="{cda:code/@code}" />
                            </class>
                        </xsl:when>
                        <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']">
                            <class>
                                <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                                <code value="{cda:code/cda:translation/@code}" />
                            </class>
                        </xsl:when>
                        <xsl:otherwise>
                            <class>
                                <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
                                <code value="NI" />
                                <display value="NoInformtion" />
                            </class>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:for-each select="cda:code">
                        <xsl:call-template name="newCreateCodableConcept">
                            <xsl:with-param name="pElementName" select="'type'" />
                            <xsl:with-param name="includeCoding" select="true()" />
                            <xsl:with-param name="includeTranslations" select="true()" />
                        </xsl:call-template>
                    </xsl:for-each>

            <!-- MD: Using RG suggestion 
                </xsl:otherwise>
            </xsl:choose>  -->

            <xsl:call-template name="subject-reference" />

            <xsl:choose>
                <xsl:when test="cda:performer[not(@nullFlavor)] | cda:responsibleParty[not(@nullFlavor)]">
                    <xsl:for-each select="cda:performer[not(@nullFlavor)] | cda:responsibleParty[not(@nullFlavor)]">
                        <participant>
                            <xsl:comment>In participant</xsl:comment>
                            <xsl:choose>
                                <xsl:when test="local-name(.) = 'performer'">
                                    <type>
                                        <coding>
                                            <system value="http://hl7.org/fhir/v3/ParticipationType" />
                                            <code value="PPRF" />
                                        </coding>
                                    </type>
                                </xsl:when>
                                <xsl:when test="$vCurrentIg = 'eICR' or $vCurrentIg = 'RR'">
                                    <type>
                                        <coding>
                                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                                            <code value="ATND" />
                                        </coding>
                                    </type>
                                </xsl:when>
                            </xsl:choose>

                            <xsl:apply-templates select="cda:assignedEntity/cda:code">
                                <xsl:with-param name="pElementName">type</xsl:with-param>
                            </xsl:apply-templates>
                            <individual>
                                <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
                            </individual>
                        </participant>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <participant>
                        <xsl:call-template name="author-reference">
                            <xsl:with-param name="pElementName">individual</xsl:with-param>
                        </xsl:call-template>
                    </participant>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:effectiveTime" mode="period" />
            <xsl:choose>
                <xsl:when test="local-name(.) = 'encompassingEncounter'">
                    <xsl:apply-templates select="/cda:ClinicalDocument/cda:documentationOf/cda:serviceEvent/cda:code">
                        <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="cda:entryRelationship[@typeCode = 'RSON']/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.19']">
                        <xsl:apply-templates select="cda:value[@xsi:type = 'CD']">
                            <xsl:with-param name="pElementName">reasonCode</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <!-- When this is an eICR and we are inside the encompassingEncounter we want to put the encounter diagnoses in this encounter -->
                <xsl:when test="local-name(.) = 'encompassingEncounter' and $vCurrentIg = 'eICR'">
                    <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
                        <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
                            <diagnosis>
                                <xsl:apply-templates select="self::node()" mode="entry-extension" />
                                <condition>
                                    <xsl:apply-templates select="." mode="reference" />
                                </condition>
                            </diagnosis>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="local-name(.) = 'encompassingEncounter'">
                    <xsl:for-each select="//cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80'][not(ancestor::cda:encounter)]">
                        <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
                            <diagnosis>
                                <condition>
                                    <xsl:apply-templates select="." mode="reference" />
                                </condition>
                            </diagnosis>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']">
                        <xsl:for-each select="cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']">
                            <diagnosis>
                                <condition>
                                    <xsl:apply-templates select="." mode="reference" />
                                </condition>
                            </diagnosis>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="cda:location[not(@nullFlavor)]">
                <location>
                    <location>
                        <reference value="urn:uuid:{cda:location/@lcg:uuid}" />
                    </location>
                </location>
            </xsl:if>
            <xsl:if test="cda:location/cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]">
                <serviceProvider>
                    <reference value="urn:uuid:{cda:location/cda:healthCareFacility/cda:serviceProviderOrganization/@lcg:uuid}" />
                </serviceProvider>
            </xsl:if>

        </Encounter>
    </xsl:template>

    <xsl:template match="cda:code" mode="encounter">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName">type</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
