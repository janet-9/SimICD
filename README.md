
# SimICD: Closed Loop ICD Simulations

## Description

This is the codebase for SimICD, a tool for the closed loop simulation of cardiac EP episodes and virtual ICD logic modelled after the Boston Scientific single chamber transvenous ICD (https://www.bostonscientific.com/en-US/home.html). Examples of episode simulations can be found in the paper: 'SimICD: A Closed-Loop Framework for ICD Modelling'

The base consists of:
A. ICD_Logic: Contains the sensing and discrimination algorithms for descision making during simulations, the therapy presciption scripts and calls to and from the simulator to translate the data from the EP simulations into EGMs. 
B. NSR_Temps: Templates of EGMs representing normal sinus rhythm that can be used in morphology analysis. 
C. Sim_Files: Python scripts (using carputils, the python framework used by OpenCARP - https://opencarp.org) for running episodes of NSR, focal VT and re-entrant VT. Users are invited to upload their own meshes, stimulus sites and electrode sites in order to run simulations and are welcome to the tailor the simulation scripts to meet the requirements of their own experiments. 


## Table of Contents

- [Requirements](#requirements)
- [Usage](#usage)
- [Example](#example)
- [Features](#features)
- [Contact](#contact)

## Requirements

To run this project, you need the following dependencies installed:

- Python 3.8.10
- MATLAB version R2023b 
- pip
- Compatibility with Linux OS 

- openCARP and necessary packages installed on the machine that you are using (carputils, meshtool, meshalyzer)
(Details on how to install these can be found at the openCARP website: https://opencarp.org)

- To use the example scripts provided, you require:
    - Mesh files (meshname.elem, meshname.lon, meshname.pts, meshname.surf)
    - NSR.vtx files (stimulus sites for NSR rhythm)
    - ATP.vtx (Stimulus site for the ATP delivery)
    - If using the Focal VT script you must also provide the Focal.vtx stimulus site 
    - electrodesICD.pts (sites within the mesh to record ICD traces)
NOTE:
- You can find information on how to structure the above files at the openCARP website: https://opencarp.org
- You will need to structure your electrodeICD.pts file in the following order: CAN, RVCoil, RVRing, RVTip 
- If you wish to structure your electrodes differently, you will need to edit the 'generate_EGM_from_ascii.m' function in order to correspond to the electrodes that you specify for your simulation. )


## Usage

 To run the example scripts provided, you will need to upload the required files mentioned above withtin the Sim_Files/Episode_Scripts/Focal_VT OR Sim_Files/Episode_Scripts/Reentrant_VT depending on which type of episode you wish to simulate. 
 The two generic scripts provided are designed to use the carputils scripts found in 'Sim_Files', and are called:

 1. A_Focal_VT_Patient.m 
 2. B_Reentrant_VT_Patient.m 
 
 Both of these scripts can be run directly in matlab (with optional arguments found in the pre-amble of the scripts) using the command 

 matlab -batch '{A_Focal/B_Reentrant}_VT_Patient(varargin)' 
!<<
## Example Results 

Below is an example of a reentrant VT episode and corresponding EGMs, this was simulated on a basic bi-ventricular mesh.  

1. Initial reentrant circuit:



2. Delivery of ATP:



>>!

## Features

- Simulation scripts for ventricular arrhytmia episodes
- Therapy scripts for the delivery of ATP
- ICD logic scripts for detection and analysis of episode EGMs 
- File Processing functions for extraction and monitoring of data. 


## Contact 
- Any Queries regarding the codebase, please contact:  [hannah.lydon@kcl.ac.uk](mailto:hannah.lydon@kcl.ac.uk)
- GitHub: [janet-9](https://github.com/janet-9)
