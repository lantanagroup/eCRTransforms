<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://hl7.org/fhir" xmlns:lcg="http://www.lantanagroup.com" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" version="2.0"
    exclude-result-prefixes="lcg cda fhir">
    
    <xsl:include href="../base64.xsl" />
    <xsl:include href="c-to-fhir-utility.xslt" />
    <xsl:include href="cda-to-fhir-datatypes.xslt" />
    <xsl:include href="cda2fhir-AllergyIntolerance.xslt" />
    <xsl:include href="cda2fhir-Bundle.xslt" />
    <xsl:include href="cda2fhir-CarePlan.xslt" />
    <xsl:include href="cda2fhir-CareTeam.xslt" />
    <xsl:include href="cda2fhir-Communication.xslt" />
    <xsl:include href="cda2fhir-Composition.xslt" />
    <xsl:include href="cda2fhir-Condition.xslt" />
    <xsl:include href="cda2fhir-Consent.xslt" />
    <xsl:include href="cda2fhir-Coverage.xslt" />
    <xsl:include href="cda2fhir-Device.xslt" />
    <xsl:include href="cda2fhir-DocumentReference.xslt" />
    <xsl:include href="cda2fhir-Encounter.xslt" />
    <xsl:include href="cda2fhir-EpisodeOfCare.xslt" />
    <xsl:include href="cda2fhir-Extension.xslt" />
    <xsl:include href="cda2fhir-FamilyMemberHistory.xslt" />
    <xsl:include href="cda2fhir-Goal.xslt" />
    <xsl:include href="cda2fhir-Immunization.xslt" />
    <xsl:include href="cda2fhir-Location.xslt" />
    <xsl:include href="cda2fhir-Medication.xslt" />
    <xsl:include href="cda2fhir-MedicationAdministration.xslt" />
    <xsl:include href="cda2fhir-MedicationDispense.xslt" />
    <xsl:include href="cda2fhir-MedicationRequest.xslt" />
    <!-- Removing mapping to MedicationStatement for now - this is an evoloving mapping in the C-CDA to FHIR project - will update when that group has decided on mapping -->
<!--    <xsl:include href="cda2fhir-MedicationStatement.xslt" />-->
    <xsl:include href="cda2fhir-Narrative.xslt" />
    <xsl:include href="cda2fhir-Observation.xslt" />
    <xsl:include href="cda2fhir-Organization.xslt" />
    <xsl:include href="cda2fhir-Patient.xslt" />
    <xsl:include href="cda2fhir-PlanDefinition.xslt" />
    <xsl:include href="cda2fhir-Practitioner.xslt" />
    <xsl:include href="cda2fhir-PractitionerRole.xslt" />
    <xsl:include href="cda2fhir-Procedure.xslt" />
    <xsl:include href="cda2fhir-Provenance.xslt" />
    <xsl:include href="cda2fhir-RelatedPerson.xslt" />
    <xsl:include href="cda2fhir-RequestGroup.xslt" />
    <xsl:include href="cda2fhir-RiskAssessment.xslt" />
    <xsl:include href="cda2fhir-ServiceRequest.xslt" />
    <xsl:include href="cda2fhir-Specimen.xslt" />
    <xsl:include href="cda2fhir-fallback-templates.xslt" />


</xsl:stylesheet>
