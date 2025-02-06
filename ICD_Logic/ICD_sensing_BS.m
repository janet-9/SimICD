%ICD Sensing Function
%input: TBD
% % parameter struct
% (initial settings)
%ICD_sense_state
%State: 1 - sensing/AGC
%       2 - peak tracking
%       3 - absolute blanking
%       4 - noise window
%       5 - fixed refractory
% ICD_sense_state.State=1;
% ICD_sense_state.VPace=0;
% ICD_sense_state.VSense=0;
% ICD_sense_state.APace=0;
% ICD_sense_state.ASense=0;
% ICD_sense_state.StateClock=0;
% ICD_sense_state.StateClockLim=0;
% ICD_sense_state.RefPeriodClock=0;
% ICD_sense_state.VThres=vThresMin;
% ICD_sense_state.VType=1;
% ICD_sense_state.VAvg=vThresMin;%TODO: could be different initial value
% ICD_sense_state.DebugClock=0;

% current state
% current waveform sample (vector)
%output: TBD
% input waveform
% current threshold
%TODO: what happens when there is a VPACE event, but it is not sensed?
function [signal, V_in, ICD_sense_state, ICD_sense_param]=ICD_sensing_BS(...
    ICD_sense_state, ICD_sense_param,...
    signal)

%Sensing for the ventricular signal 
[VSignal, V_out, ICD_sense_state, ICD_sense_param]=ICD_sensing_BS_V(...
    ICD_sense_state, ICD_sense_param, ...
    signal(:,1));

%Sensing for the atrial signal 
% [ASignal, V_null, A_out, A_blank, ICD_sense_state, ICD_sense_param]=ICD_sensing_BS_A(...
%     ICD_sense_state, ICD_sense_param, ...
%     signal(:,2));


%ASignal=signal(:,2);
V_in=V_out;
signal= VSignal;
end
