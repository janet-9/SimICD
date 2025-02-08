This is the codebase for SimICD, a tool for the closed loop simulation of cardiac EP episodes and virtual ICD logic modelled after the Boston Scientific single chamber transvenous ICD (https://www.bostonscientific.com/en-US/home.html). Examples of episode simulations can be found in the paper: 'SimICD: A Closed-Loop Framework for ICD Modelling'

The base consists of:
A. ICD_Logic: Contains the sensing and discrimination algorithms for descision making during simulations, the therapy presciption scripts and calls to and from the simulator to translate the data from the EP simulations into EGMs. 
B. NSR_Temps: Templates of EGMs representing normal sinus rhythm that can be used in morphology analysis. 
C. Sim_Files: Python scripts (using carputils, the python framework used by OpenCARP - https://opencarp.org) for running episodes of NSR, focal VT and re-entrant VT. Users are invited to upload their own meshes, stimulus sites and electrode sites in order to run simulations. 
