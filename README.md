
# SimICD: Closed Loop ICD Simulations


## Description

This is the codebase for **SimICD**, a tool for the closed-loop simulation of cardiac EP episodes and virtual ICD logic modeled after the Boston Scientific single chamber transvenous ICD ([Boston Scientific](https://www.bostonscientific.com/en-US/home.html)). Examples of episode simulations can be found in the paper: *'SimICD: A Closed-Loop Framework for ICD Modelling'*.

The base consists of:

### A. ICD_Logic:
Contains the sensing and discrimination algorithms for decision-making during simulations, therapy prescription scripts, and calls to and from the simulator to translate the data from the EP simulations into EGMs.  
  - **i. Sensing**: Scripts for generating EGMs from simulated data and extracting key features.
  - **ii. Detection**: Scripts for utilizing the discrimination algorithm and making therapy decisions.
  - **iii. Therapy**: Scripts for implementing and analyzing therapy decisions.

### B. NSR_Temps:
Templates of EGMs representing normal sinus rhythm that can be used in morphology analysis.  
  Users can either use these templates or generate their own using a custom mesh, which can be done using the NSR script provided in *Sim_Files*.

### C. Sim_Files:
Python scripts (using *carputils*, the Python framework used by OpenCARP - [OpenCARP](https://opencarp.org)) for running the cardiac simulations. These include:
  - **i. Focal VT**
  - **ii. Re-entrant VT**

Users are invited to upload their own meshes, stimulus sites, and electrode sites in order to run simulations. They are also welcome to tailor the simulation scripts to meet their specific experimental requirements.

## Table of Contents

- [Requirements](#requirements)
- [Usage](#usage)
- [Features](#features)
- [Contact](#contact)

## Requirements

To run this project, the following dependencies need to be installed:

- **Python 3.8.10**
- **MATLAB version R2023b**
- **pip** (Python package manager)
- **Linux OS compatibility**

Additionally, **openCARP** and necessary packages must be installed on the machine you are using (including *carputils*, *meshtool*, and *meshalyzer*).  
(Details on how to install these can be found on the [openCARP website](https://opencarp.org)).

### Required Files:
To use the example scripts provided, you will need:
- Mesh files (`meshname.elem`, `meshname.lon`, `meshname.pts`, `meshname.surf`)
- **NSR.vtx** files (stimulus sites for NSR rhythm)
- **ATP.vtx** (stimulus site for ATP delivery)
- For the **Focal VT** script, you must also provide the **Focal.vtx** stimulus site
- **electrodesICD.pts** (sites within the mesh to record ICD traces)

**Note:**
- For details on how to structure the required files, visit the [openCARP website](https://opencarp.org).
- The **electrodeICD.pts** file must be structured in this order: `CAN`, `RVCoil`, `RVRing`, `RVTip`.
- If you wish to structure your electrodes differently, you will need to edit the `generate_EGM_from_ascii.m` function to match the electrodes you specify for your simulation.

## Usage

- To run the example scripts, upload the required files mentioned above into the folder of the episode type you wish to simulate. The two generic scripts provided are designed to use the *carputils* scripts found in *Sim_Files*.  

- Both of these scripts can be run directly in MATLAB (with optional arguments found in the pre-amble of the scripts) using the following commands with your own variable arguments:

1. **A_Focal_VT_Patient.m**

```bash
matlab -batch 'A_Focal_VT_Patient(varargin)'
```
2. **B_Reentrant_VT_Patient.m**

```bash
matlab -batch 'B_Reentrant_VT_Patient(varargin)'
```

## Features

- Simulation scripts for ventricular arrhytmia episodes
- Therapy scripts for the delivery of ATP
- ICD logic scripts for detection and analysis of episode EGMs 
- File Processing functions for extraction and monitoring of data. 


## Contact 
- Any Queries regarding the codebase, please contact:  [hannah.lydon@kcl.ac.uk](mailto:hannah.lydon@kcl.ac.uk)
- GitHub: [janet-9](https://github.com/janet-9)


