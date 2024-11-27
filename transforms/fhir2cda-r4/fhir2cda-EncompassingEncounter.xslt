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
<xsl:stylesheet exclude-result-prefixes="lcg xsl cda fhir xhtml" version="2.0" xmlns="urn:hl7-org:v3" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="fhir2cda-utility.xslt" />
    <xsl:import href="fhir2cda-CD.xslt" />
    <xsl:import href="fhir2cda-TS.xslt" />

    <!-- fhir:encounter -> get referenced resource entry url and process -->
    <xsl:template match="fhir:encounter">
        <xsl:for-each select="fhir:reference">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:for-each select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]">
                <xsl:apply-templates mode="encompassing-encounter" select="fhir:resource/fhir:*" />
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fhir:entry/fhir:resource/fhir:Encounter" mode="encompassing-encounter">
        <xsl:call-template name="make-encompassing-encounter" />
    </xsl:template>

    <!-- Template: make-encompassing-encounter 
         This template uses Composition.encounter to create the CDA EncompassingEncounter -->
    <xsl:template name="make-encompassing-encounter">
        <componentOf>
            <encompassingEncounter>
                <xsl:call-template name="get-id" />

                <!-- For some reason eICR is different than PCP for encompassingEncounter.code -->
                <xsl:choose>
                    <xsl:when test="$gvCurrentIg = 'eICR' or $gvCurrentIg = 'RR'">
                        <!-- Merging class and type into one data element, and FHIR allows multiple types - merge them into a variable and process -->
                        <xsl:variable name="vMergedTypes">
                            <code xmlns="http://hl7.org/fhir">
                                <xsl:copy-of select="fhir:class/fhir:coding" />
                                <xsl:copy-of select="fhir:type/fhir:coding" />
                                <xsl:if test="fhir:class/fhir:text or fhir:type/fhir:text">
                                    <text xmlns="http://hl7.org/fhir">
                                        <xsl:attribute name="value" select="string-join(fhir:class/fhir:text/@value | fhir:type/fhir:text/@value, ', ')" />
                                    </text>
                                </xsl:if>
                            </code>
                        </xsl:variable>
                        <xsl:apply-templates select="$vMergedTypes/fhir:code" />
                    </xsl:when>
                    <xsl:when test="$gvCurrentIg eq 'DentalConsultNote' or $gvCurrentIg eq 'DentalReferalNote'">
                        <code>
                            <xsl:apply-templates select="fhir:class" />
                            <xsl:for-each select="fhir:type">
                                <xsl:apply-templates select=".">
                                    <xsl:with-param name="pElementName" select="'translation'" />
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </code>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="fhir:type">
                            <xsl:apply-templates select="." />
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- effectiveTime (required) -->
                <xsl:choose>
                    <xsl:when test="fhir:period">
                        <xsl:apply-templates select="fhir:period" />
                    </xsl:when>
                    <xsl:otherwise>
                        <effectiveTime>
                            <low nullFlavor="NA" />
                        </effectiveTime>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- SG 20231126: Added dischargeDisposition processing -->
                <xsl:for-each select="fhir:hospitalization/fhir:dischargeDisposition">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="pElementName" select="'dischargeDispositionCode'" />
                    </xsl:apply-templates>
                </xsl:for-each>

                <!-- SG 20210723: I've refactored this quite a bit - it wasn't picking up multiple participants in eICR 
                        Not sure this is always correct, but if the type of the participant is ATND, assuming that this is the 
                        encompassingEncounter/responsibleParty and that any other participants will go in 
                        encompassingEncounter/encounterParticipant
                        Code needed to account for the fact that you can have either a PratitionerRole, or a Practitioner as 
                        the participant and to get the data for either-->
                <!-- SG 20210723: TODO Need to decide what to do if there isn't a participant with type ATND - for now just leaving them
                      as encounterParticipants, but maybe if there is only one we would want to put it into responsibleParty?-->
                <!-- responsibleParty (with type = ATND) needs to come first -->
                <!-- only take the first ATND participant, put all the others into encounterParticipants -->
                <xsl:for-each select="fhir:participant[fhir:type/fhir:coding/fhir:code/@value = 'ATND']">
                    <xsl:if test="position() = 1">
                        <!-- SG 2021/07/22 Adding: using a variable here to hold either the Provider or ProviderRole information-->
                        <xsl:variable name="vEncounterParticipant">
                            <xsl:apply-templates mode="encounter-participant" select="." />
                        </xsl:variable>
                        <xsl:variable name="vServiceProvider">
                            <xsl:apply-templates mode="composition-encounter" select="../fhir:serviceProvider" />
                        </xsl:variable>
                        <responsibleParty>
                            <!-- SG 2021/07/22: Adding: moved the code out for assignedEntity so we can reuse it in the encounterParticipant -->
                            <xsl:call-template name="get-assigned-entity">
                                <xsl:with-param name="pEncounterParticipant" select="$vEncounterParticipant" />
                                <xsl:with-param name="pServiceProvider" select="$vServiceProvider" />
                            </xsl:call-template>
                        </responsibleParty>
                    </xsl:if>
                </xsl:for-each>
                <!-- all the other participants go into encounterParticipant -->
                <!--<xsl:for-each select="fhir:participant[not(fhir:type/fhir:coding/fhir:code/@value = 'ATND')]">-->
                <xsl:for-each select="fhir:participant">
                    <xsl:if test="not(fhir:type/fhir:coding/fhir:code/@value = 'ATND') or (fhir:type/fhir:coding/fhir:code/@value = 'ATND' and position() > 1)">
                        <!-- SG 2021/07/22 Adding: using a variable here to hold either the Provider or ProviderRole information-->
                        <xsl:variable name="vEncounterParticipant">
                            <xsl:apply-templates mode="encounter-participant" select="." />
                        </xsl:variable>
                        <encounterParticipant>
                            <!-- typeCode is required-->
                            <!-- SG: There is a big mismatch in the codes allowed in CDA (ADM, ATND, CON, DIS, REF) and the codes allowed in FHIR: https://www.hl7.org/fhir/valueset-encounter-participant-type.html
                             Need to do a mapping somehow - might be best in a file so we can reuse
                             For now, if they are not in that short list, will default to CON (not ideal!!)-->
                            <xsl:variable name="vType">
                                <xsl:choose>
                                    <xsl:when test="fhir:type/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-ParticipationType']/fhir:code/@value">
                                        <xsl:value-of select="fhir:type/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-ParticipationType']/fhir:code/@value" />
                                    </xsl:when>
                                    <xsl:otherwise>CON</xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:attribute name="typeCode" select="
                                    if (not($vType) or ($vType = 'CALLBCK' or $vType = 'ESC' or $vType = 'SPRF' or $vType = 'PPRF' or $vType = 'PART' or $vType = 'translator' or $vType = 'emergency'))
                                    then
                                        'CON'
                                    else
                                        $vType"> </xsl:attribute>
                            <xsl:variable name="vServiceProvider">
                                <xsl:apply-templates mode="composition-encounter" select="../fhir:serviceProvider" />
                            </xsl:variable>
                            <!-- SG 2021/07/22: Adding: moved the code out for assignedEntity so we can reuse it in the encounterParticipant -->
                            <xsl:call-template name="get-assigned-entity">
                                <xsl:with-param name="pEncounterParticipant" select="$vEncounterParticipant" />
                                <xsl:with-param name="pServiceProvider" select="$vServiceProvider" />
                            </xsl:call-template>
                        </encounterParticipant>
                    </xsl:if>
                </xsl:for-each>
                <!--  -->
                <xsl:for-each select="fhir:location">
                    <!-- Get location and managingOrganization into a variable -->
                    <xsl:variable name="vLocation">
                        <xsl:apply-templates mode="composition-encounter" select="." />
                    </xsl:variable>

                    <!-- Get serviceProviderOrganization into a variable -->
                    <!-- There is only one serviceProvider per Encounter, but there could be multiple locations and CDA has a 
                         serviceProviderOrganization for each location -->
                    <xsl:variable name="vServiceProvider">
                        <xsl:apply-templates mode="composition-encounter" select="../fhir:serviceProvider" />
                    </xsl:variable>

                    <location>
                        <healthCareFacility>
                            <!-- Refactor -->
                            <xsl:choose>
                                <xsl:when test="$vLocation/fhir:identifier">
                                    <xsl:choose>
                                        <xsl:when test="$vLocation/fhir:identifier">
                                            <xsl:variable name="vPotentialDupes">
                                                <xsl:apply-templates select="$vLocation/fhir:identifier" />
                                            </xsl:variable>
                                            <xsl:for-each-group group-by="concat(@root, @extension)" select="$vPotentialDupes/cda:id">
                                                <xsl:copy-of select="current-group()[1]" />
                                            </xsl:for-each-group>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <id nullFlavor="NI" root="2.16.840.1.113883.4.6" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <!-- Not sure it's actually valid to put the Organization identifier onto the Location -->
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <xsl:when test="$vLocation/fhir:Organization/fhir:identifier">
                                            <xsl:variable name="vPotentialDupes">
                                                <xsl:apply-templates select="$vLocation/fhir:Organization/fhir:identifier" />
                                            </xsl:variable>
                                            <xsl:for-each-group group-by="concat(@root, @extension)" select="$vPotentialDupes/cda:id">
                                                <xsl:copy-of select="current-group()[1]" />
                                            </xsl:for-each-group>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <id nullFlavor="NI" root="2.16.840.1.113883.4.6" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- healthCareFacility/code -->
                            <!-- FHIR type allows more than one so merge them into a variable, concat any texts and process -->
                            <xsl:variable name="vMergedTypes">
                                <type xmlns="http://hl7.org/fhir">
                                    <xsl:copy-of select="$vLocation/fhir:Location/fhir:type/fhir:coding" />
                                    <xsl:if test="$vLocation/fhir:Location/fhir:type/fhir:text">
                                        <text xmlns="http://hl7.org/fhir">
                                            <xsl:attribute name="value" select="string-join($vLocation/fhir:Location/fhir:type/fhir:text/@value, ', ')" />
                                        </text>
                                    </xsl:if>
                                </type>
                            </xsl:variable>
                            <xsl:apply-templates select="$vMergedTypes/fhir:type" />
                            <location>
                                <xsl:call-template name="get-org-name">
                                    <xsl:with-param name="pElement" select="$vLocation/fhir:Location/fhir:name" />
                                </xsl:call-template>
                                <!-- SG 20240307: Sometimes the Location has no address, use the first ServiceProvider address in this case
                                     eICR only allows one address, take the first one-->
                                <xsl:choose>
                                    <xsl:when test="$vLocation/fhir:Location/fhir:address">
                                        <xsl:choose>
                                            <xsl:when test="$gvCurrentIg = 'eICR'">
                                                <xsl:call-template name="get-addr">
                                                    <xsl:with-param name="pElement" select="$vLocation/fhir:Location/fhir:address[1]" />
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:call-template name="get-addr">
                                                    <xsl:with-param name="pElement" select="$vLocation/fhir:Location/fhir:address" />
                                                </xsl:call-template>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:choose>
                                            <xsl:when test="$gvCurrentIg = 'eICR'">
                                                <xsl:call-template name="get-addr">
                                                    <xsl:with-param name="pElement" select="$vServiceProvider/fhir:Organization/fhir:address[1]" />
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:call-template name="get-addr">
                                                    <xsl:with-param name="pElement" select="$vServiceProvider/fhir:Organization/fhir:address" />
                                                </xsl:call-template>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </location>
                            <serviceProviderOrganization>
                                <!--  -->
                                <xsl:call-template name="get-org-name">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$vServiceProvider/fhir:Organization[1]/fhir:name" />
                                </xsl:call-template>
                                <xsl:call-template name="get-telecom">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$vServiceProvider/fhir:Organization[1]/fhir:telecom" />
                                </xsl:call-template>
                                <xsl:call-template name="get-addr">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$vServiceProvider/fhir:Organization[1]/fhir:address[1]" />
                                    <xsl:with-param name="pNoNullAllowed" select="true()" />
                                </xsl:call-template>
                            </serviceProviderOrganization>
                        </healthCareFacility>
                    </location>
                </xsl:for-each>
                <!--  -->
            </encompassingEncounter>
        </componentOf>
    </xsl:template>

    <!-- Template: get-assigned-entity -->
    <xsl:template name="get-assigned-entity">
        <xsl:param name="pEncounterParticipant" />
        <xsl:param name="pServiceProvider" />
        <!-- parameter to pass to the named template to indicate whether it should allow returning nothing (i.e. no nullFlavor filled element) 
             if the FHIR element doesn't exist - the responsibleParty requires some elements, whereas there aren't the same constrains on the encounterParticipant-->
        <xsl:param name="pNoNullAllowed" select="false()" />

        <assignedEntity>
            <!-- new 7/12/2021 -->
            <xsl:choose>
                <!-- If there is a PractitionerRole we want to use that id -->
                <xsl:when test="$pEncounterParticipant/fhir:PractitionerRole/fhir:identifier">
                    <xsl:variable name="vPotentialDupes">
                        <xsl:apply-templates select="$pEncounterParticipant/fhir:PractitionerRole/fhir:identifier" />
                    </xsl:variable>
                    <xsl:for-each-group group-by="concat(@root, @extension)" select="$vPotentialDupes/cda:id">
                        <xsl:copy-of select="current-group()[1]" />
                    </xsl:for-each-group>
                </xsl:when>
                <!-- SG 2021/07/22 Added to get identifier from Pracitioner if there is no PractitionerRole -->
                <xsl:when test="$pEncounterParticipant/fhir:Practitioner/fhir:identifier">
                    <xsl:variable name="vPotentialDupes">
                        <xsl:apply-templates select="$pEncounterParticipant/fhir:Practitioner/fhir:identifier" />
                    </xsl:variable>
                    <xsl:for-each-group group-by="concat(@root, @extension)" select="$vPotentialDupes/cda:id">
                        <xsl:copy-of select="current-group()[1]" />
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <id nullFlavor="NI" root="2.16.840.1.113883.4.6" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="get-addr">
                <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Practitioner/fhir:address" />
                <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
            </xsl:call-template>
            <xsl:call-template name="get-telecom">
                <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Practitioner/fhir:telecom" />
                <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
            </xsl:call-template>

            <assignedPerson>
                <xsl:call-template name="get-person-name">
                    <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Practitioner/fhir:name" />
                    <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                </xsl:call-template>
            </assignedPerson>
            <!-- If this did come from a ProviderRole, then there might be an Organization -->
            <xsl:choose>
                <xsl:when test="$pEncounterParticipant/fhir:Organization">
                    <representedOrganization>
                        <!-- address duplicate Organization issue -->
                        <xsl:apply-templates select="$pEncounterParticipant/fhir:Organization[1]/fhir:identifier" />
                        <xsl:call-template name="get-org-name">
                            <!-- address duplicate Organization issue -->
                            <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Organization[1]/fhir:name" />
                            <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                        </xsl:call-template>
                        <!-- address duplicate Organization issue -->
                        <xsl:apply-templates select="$pEncounterParticipant/fhir:Organization[1]/fhir:telecom" />
                        <!-- SG 20240308: eICR only allows one address here -->
                        <xsl:choose>
                            <xsl:when test="$gvCurrentIg = 'eICR'">
                                <xsl:call-template name="get-addr">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Organization[1]/fhir:address[1]" />
                                    <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="get-addr">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$pEncounterParticipant/fhir:Organization[1]/fhir:address" />
                                    <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </representedOrganization>
                </xsl:when>
                <xsl:when test="$pServiceProvider/fhir:Organization">
                    <representedOrganization>
                        <!-- address duplicate Organization issue -->
                        <xsl:apply-templates select="$pServiceProvider/fhir:Organization[1]/fhir:identifier" />
                        <xsl:call-template name="get-org-name">
                            <xsl:with-param name="pElement" select="$pServiceProvider/fhir:Organization[1]/fhir:name" />
                            <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                        </xsl:call-template>
                        <!-- address duplicate Organization issue -->
                        <xsl:apply-templates select="$pServiceProvider/fhir:Organization[1]/fhir:telecom" />
                        <!-- SG 20240308: eICR only allows one address here -->
                        <xsl:choose>
                            <xsl:when test="$gvCurrentIg = 'eICR'">
                                <xsl:call-template name="get-addr">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$pServiceProvider/fhir:Organization[1]/fhir:address[1]" />
                                    <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="get-addr">
                                    <!-- address duplicate Organization issue -->
                                    <xsl:with-param name="pElement" select="$pServiceProvider/fhir:Organization[1]/fhir:address" />
                                    <xsl:with-param name="pNoNullAllowed" select="$pNoNullAllowed" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </representedOrganization>
                </xsl:when>
            </xsl:choose>
        </assignedEntity>
    </xsl:template>

    <!-- Template: match Encounter.location -->
    <xsl:template match="fhir:location[parent::fhir:Encounter]" mode="composition-encounter">

        <!-- Put the Location into a variable (can be multiple in base Encounter resource but there can only be one location in an EncompassingEncounter) -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:location/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Location" />
        <xsl:variable name="vLocation" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Location" />

        <!-- Copy out the managing organization -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="$vLocation/fhir:managingOrganization/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

    </xsl:template>

    <!-- Template: get-encounter-service-provider -->
    <xsl:template match="fhir:serviceProvider[parent::fhir:Encounter]" mode="composition-encounter">

        <!-- Put the ServiceProvider into a variable (1 max in base Encounter resource) -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

    </xsl:template>

    <!-- Template: match individual.reference.Practitioner in mode "encounter-participant"
        Get copy of Practitioner -->
    <xsl:template match="fhir:individual/fhir:reference[contains(@value, 'Practitioner/')]" mode="encounter-participant">
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />
    </xsl:template>

    <xsl:template match="fhir:individual/fhir:reference[not(contains(@value, 'Practitioner/')) and not(contains(@value, 'PractitionerRole/'))]" mode="encounter-participant">
        <xsl:for-each select=".">
            <xsl:variable name="referenceURI">
                <xsl:call-template name="resolve-to-full-url">
                    <xsl:with-param name="referenceURI" select="@value" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:*" />
            <!--<xsl:choose>
                <xsl:when test="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner">
                    <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />            
                </xsl:when>
                <xsl:when test="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:PractitionerRole">
                    <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:PractitionerRole" />            
                </xsl:when>
            </xsl:choose>-->
        </xsl:for-each>
    </xsl:template>

    <!-- Template: match individual.reference.PractitionerRole in mode "encounter-participant"
        Get copy of PractitionerRole -->
    <xsl:template match="fhir:individual/fhir:reference[contains(@value, 'PractitionerRole/')]" mode="encounter-participant">
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vPractitionerRole" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:PractitionerRole" />
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:PractitionerRole" />

        <!-- Put the Practitioner into a variable (max 1 in base PractitionerRole resource) -->
        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="$vPractitionerRole/fhir:practitioner/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vPractitioner" select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Practitioner" />

        <xsl:variable name="referenceURI">
            <xsl:call-template name="resolve-to-full-url">
                <xsl:with-param name="referenceURI" select="$vPractitionerRole/fhir:organization/fhir:reference/@value" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="//fhir:entry[fhir:fullUrl/@value = $referenceURI]/fhir:resource/fhir:Organization" />

    </xsl:template>

    <!-- Template: make-encompassing-encounter-hai
         Creates the HAI encompassingEncounter from the Questionnaire -->
    <xsl:template name="make-encompassing-encounter-hai">
        <componentOf>
            <encompassingEncounter>
                <xsl:apply-templates mode="make-ii" select="//fhir:item[fhir:linkId/@value = 'event-number']/fhir:answer/fhir:valueUri" />
                <effectiveTime>
                    <!-- SG 20220206: Added date-of-current-admission-to-facility for HAI LTC -->
                    <xsl:apply-templates
                        select="//fhir:item[fhir:linkId/@value = 'date-admitted-to-facility']/fhir:answer/fhir:valueDate | //fhir:item[fhir:linkId/@value = 'date-of-current-admission-to-facility']/fhir:answer/fhir:valueDate">
                        <xsl:with-param name="pElementName">low</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'discharge-date']/fhir:answer/fhir:valueDate">
                        <xsl:with-param name="pElementName">high</xsl:with-param>
                    </xsl:apply-templates>
                </effectiveTime>

                <location>
                    <healthCareFacility>
                        <xsl:apply-templates select="fhir:item[fhir:linkId/@value = 'facility']/fhir:answer/fhir:valueUri" />
                        <xsl:apply-templates select="fhir:item[fhir:linkId/@value = 'facility-location']/fhir:answer" />

                        <!-- SG 20220206: Added for HAI LTC -->
                        <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'resident-care-location']/fhir:answer/fhir:valueUri" />
                        <xsl:apply-templates select="//fhir:item[fhir:linkId/@value = 'primary-resident-service-type']/fhir:answer" />

                    </healthCareFacility>
                </location>
            </encompassingEncounter>
        </componentOf>
    </xsl:template>


</xsl:stylesheet>
