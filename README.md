# eCR Transforms

This repo contains the following transforms:

## CDA to FHIR

### CDA RR R1 to FHIR RR R2 
(1st in line to be updated to CDA RR R1.1 to FHIR RR R2.1)

* Sample files to use: samples/cda/RR-R1
  * Files to run:
    * Native UUID Generation: transforms/cda2fhir-r4/NativeUUIDGen-cda2fhir.xslt
    * Saxon UUID Generation: transforms/cda2fhir-r4/SaxonPE-cda2fhir.xslt
           
### CDA eICR R3 to FHIR eICR R2 
(2nd in line to be updated to CDA eICR R3.2 to FHIR eICR R2.1)

* Sample files to use: samples/cda/eICR-R3 
  * Files to run:
    * Native UUID Generation: transforms/cda2fhir-r4/NativeUUIDGen-cda2fhir.xslt
    * Saxon UUID Generation: transforms/cda2fhir-r4/SaxonPE-cda2fhir.xslt
         
## FHIR to CDA

### FHIR eICR R2 to CDA eICR R1.1 
(4th in line to be updated to FHIR eICR R2.1 to CDA eICR R1.1)

* Sample files to use: samples/fhir/eICR-R2 
* File to run: transforms/fhir2cda-r4/fhir2cda.xslt with parameter gParamCDAeICRVersion = 'R1.1'
     
### FHIR eICR R2.1 to CDA eICR R3.1 
(Added 2023-APR-25)

* Sample files to use: samples/fhir/eICR-R2_1
* File to run: transforms/fhir2cda-r4/fhir2cda.xslt
      
### FHIR RR R2 to CDA RR R1 
(3rd ine line to be updated to FHIR RR R2.1 to CDA RR R2.1)

* Sample files to use: samples/fhir/RR-R2
     * File to run: transforms/fhir2cda-r4/fhir2cda.xslt 
  

## DEPRECATED 

### FHIR eICR R2 to CDA eICR R3
* Replaced with FHIR eICR R2.1 to CDA eICR 3.1
