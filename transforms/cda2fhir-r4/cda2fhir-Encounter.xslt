<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    exclude-result-prefixes="lcg xsl cda fhir xs xsi sdtc xhtml" version="2.0">

    <xsl:template match="cda:encompassingEncounter" mode="bundle-entry">
        <xsl:call-template name="create-bundle-entry" />

        <xsl:apply-templates select="cda:responsibleParty[not(@nullFlavor)]/cda:assignedEntity[not(@nullFlavor)]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:dataEnterer" mode="bundle-entry" />
        <xsl:apply-templates select="cda:encounterParticipant" mode="bundle-entry" />
        <xsl:apply-templates select="cda:location[not(@nullFlavor)]" mode="bundle-entry" />
        <xsl:apply-templates select="cda:location/cda:healthCareFacility/cda:serviceProviderOrganization[not(@nullFlavor)]" mode="bundle-entry" />

        <!-- Provenance -->
        <xsl:apply-templates select="cda:dataEnterer" mode="provenance" />
        <xsl:apply-templates select="cda:encounterParticipant" mode="provenance" />
    </xsl:template>

    <xsl:template match="cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']" mode="bundle-entry">
        <!-- Don't want a second encounter if this is eICR -->
        <xsl:if test="$gvCurrentIg != 'eICR'">
            <xsl:call-template name="create-bundle-entry" />
            <xsl:apply-templates select="cda:performer" mode="bundle-entry" />
        </xsl:if>
        <!-- Encounter Diagnosis/Problem Observation -->
        <xsl:apply-templates
            select="cda:entryRelationship/cda:act[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.80']/cda:entryRelationship/cda:observation[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.4']"
            mode="bundle-entry" />
    </xsl:template>

    <xsl:template
        match="cda:encompassingEncounter[not(@nullFlavor)] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49'] | cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.40']">
        <Encounter>
            <xsl:choose>
                <xsl:when test="$gvCurrentIg = 'eICR'">
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
                    <!-- set meta profile based on Ig -->
                    <xsl:choose>
                        <xsl:when test="$gvCurrentIg = 'NA'">
                            <xsl:call-template name="add-meta" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="vProfileValue">
                                <xsl:call-template name="get-profile-for-ig">
                                    <xsl:with-param name="pIg" select="$gvCurrentIg" />
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

            <xsl:comment select="'INFO: Id from encompassingEncounter'" />
            <xsl:apply-templates select="cda:id[1]" />
            <!-- Note, there are also ids on the other Encounters. The Encounter in eCR only allows one identifier.
                Commenting this code out for now - consider updating the FHIR IG to allow multiple identifiers
                If this is eCR get the id from other encounters in the CDA -->
            <!--<xsl:if test="$gvCurrentIg = 'eICR'">
                <xsl:comment select="'Id from Encounter Activity'"/>
                <xsl:apply-templates select="//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:id" />
                <xsl:comment select="'Id from Encounter Diagnosis Act'"/>
                <xsl:apply-templates select="//cda:act[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.80']/cda:id" />
            </xsl:if>-->

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
                <!-- also check encounter -->
                <xsl:when test="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']/@code}" />
                    </class>
                </xsl:when>
                <xsl:when test="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.5.4']/@code}" />
                    </class>
                </xsl:when>
                <!-- MD: add for ambulatory encounter-->
                <xsl:when test="cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{cda:code/@code}" />
                    </class>
                </xsl:when>
                <xsl:when test="cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{cda:code/cda:translation/@code}" />
                    </class>
                </xsl:when>
                <!-- Also check encounter -->
                <xsl:when test="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code[@codeSystem = '2.16.840.1.113883.1.11.13955']/@code}" />
                    </class>
                </xsl:when>
                <xsl:when test="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']">
                    <class>
                        <system value="http://terminology.hl7.org/CodeSystem/v3-ActCode" />
                        <code value="{//cda:encounter[cda:templateId/@root='2.16.840.1.113883.10.20.22.4.49']/cda:code/cda:translation[@codeSystem = '2.16.840.1.113883.1.11.13955']/@code}" />
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

            <xsl:for-each select="cda:code[not(@codeSystem = '2.16.840.1.113883.1.11.13955')]">
                <xsl:call-template name="newCreateCodableConcept">
                    <xsl:with-param name="pElementName" select="'type'" />
                    <xsl:with-param name="pIncludeCoding" select="true()" />
                    <xsl:with-param name="includeTranslations" select="true()" />
                </xsl:call-template>
            </xsl:for-each>

            <!-- Also get any encounter codes -->
            <xsl:for-each select="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/cda:code[not(@codeSystem = '2.16.840.1.113883.1.11.13955')]">
                <xsl:call-template name="newCreateCodableConcept">
                    <xsl:with-param name="pElementName" select="'type'" />
                    <xsl:with-param name="pIncludeCoding" select="true()" />
                    <xsl:with-param name="includeTranslations" select="true()" />
                </xsl:call-template>
            </xsl:for-each>

            <xsl:call-template name="subject-reference" />

            <xsl:for-each select="cda:responsibleParty[not(@nullFlavor)]">
                <participant>
                    <type>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                            <code value="ATND" />
                        </coding>
                    </type>
                    <!--<xsl:apply-templates select="cda:assignedEntity/cda:code">
                        <xsl:with-param name="pElementName">type</xsl:with-param>
                    </xsl:apply-templates>-->
                    <individual>
                        <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
                    </individual>
                </participant>
            </xsl:for-each>
            <xsl:for-each select="cda:encounterParticipant[not(@nullFlavor)] | cda:performer[not(@nullFlavor)]">
                <participant>
                    <!--<type>
                        <coding>
                            <system value="http://terminology.hl7.org/CodeSystem/v3-ParticipationType" />
                            <code value="PPRF" />
                        </coding>
                    </type>-->

                    <!--<xsl:apply-templates select="cda:assignedEntity/cda:code">
                        <xsl:with-param name="pElementName">type</xsl:with-param>
                    </xsl:apply-templates>-->
                    <individual>
                        <xsl:apply-templates select="cda:assignedEntity" mode="reference" />
                    </individual>
                </participant>
            </xsl:for-each>

            <!--<xsl:choose>
                
                <xsl:when test="
                        cda:author/cda:assignedAuthor/cda:assignedPerson or
                        ancestor::cda:section[1]/cda:author[1]/cda:assignedAuthor or
                        /cda:ClinicalDocument/cda:author[1]/cda:assignedAuthor/cda:assignedPerson or
                        /cda:ClinicalDocument/cda:componentOf/cda:encompassingEncounter/cda:responsibleParty">-->
            <xsl:for-each select="cda:author/cda:assignedAuthor[cda:assignedPerson]">
                <participant>
                    <xsl:for-each select="cda:assignedPerson">
                        <xsl:apply-templates select="." mode="rename-reference-participant">
                            <xsl:with-param name="pElementName">individual</xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:for-each>
                    <!--<xsl:call-template name="author-reference">
                        <xsl:with-param name="pElementName">individual</xsl:with-param>
                    </xsl:call-template>-->
                </participant>
            </xsl:for-each>
            <!--</xsl:when>
            </xsl:choose>-->
            <xsl:for-each select="/cda:ClinicalDocument/cda:participant/cda:associatedEntity[@classCode = 'NOK']">
                <participant>
                    <individual>
                        <xsl:apply-templates select="." mode="reference" />
                    </individual>
                </participant>
            </xsl:for-each>
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
                <xsl:when test="local-name(.) = 'encompassingEncounter' and $gvCurrentIg = 'eICR'">
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

            <!-- Can only have one dischargeDisposition use the one in the encompassingEncounter first,
                 otherwise use the body encounter one-->
            <xsl:choose>
                <xsl:when test="cda:dischargeDispositionCode">
                    <hospitalization>
                        <xsl:apply-templates select="cda:dischargeDispositionCode">
                            <xsl:with-param name="pElementName" select="'dischargeDisposition'" />
                            <xsl:with-param name="pIncludeCoding" select="true()" />
                        </xsl:apply-templates>
                    </hospitalization>
                </xsl:when>
                <xsl:when test="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/sdtc:dischargeDispositionCode">
                    <hospitalization>
                        <xsl:apply-templates select="//cda:encounter[cda:templateId/@root = '2.16.840.1.113883.10.20.22.4.49']/sdtc:dischargeDispositionCode">
                            <xsl:with-param name="pElementName" select="'dischargeDisposition'" />
                            <xsl:with-param name="pIncludeCoding" select="true()" />
                        </xsl:apply-templates>
                    </hospitalization>
                </xsl:when>
            </xsl:choose>


            <!--<sdtc:dischargeDispositionCode code="1" codeSystem="1.2.840.114350.1.13.671.3.7.4.698084.18888" codeSystemName="EPC" displayName="DISCHARGED TO HOME OR SELF CARE (ROUTINE DISCHARGE)">
                    <originalText>DISCHARGED TO HOME OR SELF CARE (ROUTINE DISCHARGE)</originalText>
                </sdtc:dischargeDispositionCode>-->

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
