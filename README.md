
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
- [Features](#features)
- [License](#license)
- [Contact](#contact)

## Requirements

To run this project, you need the following dependencies installed:

- Python 3.x
- pip
- Compatible operating system (Windows, macOS, or Linux)

- openCARP and necessary packages installed on the machine that you are using, plus meshes, electrodes and stimulus sites for modelling episodes and therapy. Details on how to create these can be found at the openCARP website: https://opencarp.org  

## Usage
 Currently, this repository cannot be used without the meshes, stimulus sites and electrodes uploaded by the user and is mainly used to demonstrate the codebase features. The patient scripts in this repository were used to generate the results seen in the corresponding SimICD paper. 

<!-- This is a commented out line in the README 
To run the virtual ICD scripts:
```sh
python run_icd.py
```

To execute therapy scripts:
```sh
python run_therapy.py 
```
-->

## Features

- Simulation scripts for ventricular arrhytmia episodes
- Therapy scripts for the delivery of ATP
- ICD logic scripts for detection and analysis of episode EGMs 
- File Processing functions for extraction and monitoring of data. 


- Author - [hannah.lydon@kcl.ac.uk](mailto:your-email@example.com)
- GitHub: [janet-9](https://github.com/your-username)