
%ICD_sensing_BS_init
%Initializes data structure which is use throughout sensing algorithm
%ICD_sense_state
%State: 1 - sensing/AGC
%       2 - peak tracking
%       3 - absolute blanking
%       4 - noise window
%       5 - fixed refractory
%
%(Flags which should be reset when output is set. Intended use is for
%signalling different processes during the function)
%VPace: 1 - occurred; 0 - not occurred
%VSense: 1- occurred; 0 - not occurred 
%APace: 1- occurred; 0 - not occurred
%ASense: 1- Sense Event; 0 - No Event (should be impulse) 
%VThres: Detection threshold (uV)
%StateClock: Clock for time in each state;
%RefPeriodClock: Refractory Period Clock (total time since beginning of
%event)
%FixedRefPeriodClock
%VType: Type of last event (0 - no event 1 - Vsense 2 - VPace)
%debugClock: clock used for debugging
%
%ICD_sense_param
%VThresMin: current threshold minimum for ventricular sense (should start at minimum)

function [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_BS (...
    vThresNom, vAGCNomThres, ...
    vRefPeriod, vAbsBlankPeriod, vNoiseWindow,vFixedRefPeriod, ...
    vsAGCPeriod, vpAGCPeriod)



% Sense state for ventricular signal
ICD_sense_state.VState=1;
ICD_sense_state.VPace=0;
ICD_sense_state.VSense=0;
ICD_sense_state.VStateClock=0;
ICD_sense_state.VStateClockLim=0;
ICD_sense_state.VRefPeriodClock=0;
ICD_sense_state.VThres=vThresNom;
ICD_sense_state.VType=1;
ICD_sense_state.VAvg=vThresNom;%TODO: could be different initial value
ICD_sense_state.DebugClock=0;
ICD_sense_state.VThresMax=vThresNom*(3/2);
ICD_sense_state.VThresMin=vAGCNomThres;
ICD_sense_state.VAGCOn=1;
ICD_sense_state.VAGCClock=0;
ICD_sense_state.VAGCClockLim=vsAGCPeriod;
%TODO: Buffer
ICD_sense_state.VBuffer=[0;0;0];
ICD_sense_state.VBufInd=1;
ICD_sense_state.PrevV=0;

%Sense param for ventricular signal
ICD_sense_param.VAGCNomThres=vAGCNomThres;
ICD_sense_param.VRefPeriod=vRefPeriod;
ICD_sense_param.VAbsBlankPeriod=vAbsBlankPeriod;
ICD_sense_param.VNoiseWindow=vNoiseWindow;
ICD_sense_param.VFixedRefPeriod=vFixedRefPeriod;
ICD_sense_param.VSAGCPeriod=vsAGCPeriod;
ICD_sense_param.VPAGCPeriod=vpAGCPeriod;%TODO should be dynamically adjusted
ICD_sense_param.DebugClock=0;


end