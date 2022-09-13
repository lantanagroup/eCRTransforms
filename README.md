# eCR Transforms

This repo contains the following transforms:

## CDA to FHIR

### CDA RR R1 to FHIR RR R2

* Sample files to use: samples/cda/RR-R1.1
  * Files to run:
    * Native UUID Generation: transforms/cda2fhir-r4/NativeUUIDGen-cda2fhir.xslt
    * Saxon UUID Generation: transforms/cda2fhir-r4/SaxonPE-cda2fhir.xslt
           
### CDA eICR R3 to FHIR eICR R2

* Sample files to use: samples/cda/eICR-R3 
  * Files to run:
    * Native UUID Generation: transforms/cda2fhir-r4/NativeUUIDGen-cda2fhir.xslt
    * Saxon UUID Generation: transforms/cda2fhir-r4/SaxonPE-cda2fhir.xslt
         
## FHIR to CDA

### FHIR eICR R2 to CDA eICR R1.1

* Sample files to use: samples/fhir/eICR-R2 
* File to run: transforms/fhir2cda-r4/fhir2cda.xslt with parameter gParamCDAeICRVersion = 'R1.1'
     
### FHIR eICR R2 to CDA eICR R3

* Sample files to use: samples/fhir/eICR-R2
* File to run: transforms/fhir2cda-r4/fhir2cda.xslt
      
### FHIR RR R2 to CDA RR1

* Sample files to use: samples/fhir/RR-R2
     * File to run: transforms/fhir2cda-r4/fhir2cda.xslt 
  
*Note*: There have been new releases of all the eCR IGs as follows and the above transforms will be updated to reflect those changes in the next week:

* CDA RR R1 -> CDA RR1.1
* CDA eICR R3 -> CDA eICR R3.1
* FHIR eCR R2 -> FHIR eCR R2.1 (contains both eICR and RR) 