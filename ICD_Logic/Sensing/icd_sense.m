function events = icd_sense(egm, algo, varargin)
% events = icd_sense(egm, algo, BPF, [ath, vth])  
%
% Sense egm using 'bsc' or 'med', after processing through the band-pass
% filter, rectification and truncating the first N samples, where N is the
% half-length of the band-pass filter.
%
% egm.ASigRaw = A signal, unfiltered
% egm.VSigRaw = V signal, unfiltered
% algo = string, either 'bsc' or 'med'
% BPF = a band-pass filter created using bpf_for_egm_sensing. Optional.
% ath, vth: atrial and ventricular sensing threshold, respectively.
% Optional. Can be obtained by running bin_initial_sensing_thresholds.
%
% If either ath or vth are provided as negative numbers, then it is chosen
% according to the automatic setting strategy.
%
% Example:
% events = icd_sense(egm, 'bsc')
% events is a struct:
% egm.Ain = 1s and 0s
% egm.Vin = 1s and 0s

global debugprog;
debugme = debugprog;
plotit=1;

%NOTE: The filtering doesn't appear to be used in the sensing - the raw
%signals are the ones used later on. 
if nargin <3 || isempty(varargin{1})
    %Band-pass filter
    BandPassFilt = bpf_for_egm_sensing();
else
    BandPassFilt = varargin{1};
end

%This calcuates the sensing thresholds for each signal - or sets the
%thresholds given the input argument. 
if nargin < 4 
    [ath,vth] = set_initial_sensing_thresholds(egm, 'midpoint');
%     [ath,vth] = bin_initial_sensing_thresholds(egm, 'midpoint', BandPassFilt);
else    
    sensing_thresholds = varargin{2};
    if sensing_thresholds(1) <0 || sensing_thresholds(2)<0
        [ath,vth] = set_initial_sensing_thresholds(egm, 'midpoint');
%         [ath,vth] = bin_initial_sensing_thresholds(egm, 'midpoint', BandPassFilt);
        if strcmp(algo,'bsc')
            ath = 0.8*ath;
            vth = 0.8*vth;
        end
        if sensing_thresholds(1) > 0
            ath = sensing_thresholds(1);
        end
        if sensing_thresholds(2) > 0
            vth = sensing_thresholds(2);
        end
    else
        ath = sensing_thresholds(1);
        vth = sensing_thresholds(2);
    end
end


vsigRaw=egm.VSigRaw;
% vsigFilt=filter(BandPassFilt,vsigRaw);
asigRaw=egm.ASigRaw;
% asigFilt=filter(BandPassFilt,asigRaw);
filterlength = (length(BandPassFilt.numerator)-1)/2;
% curSig=[vsigFilt(1+filterlength:end) asigFilt(1+filterlength:end)];

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
vsigFilt = vsigRaw;
asigFilt = asigRaw;
curSig=[vsigRaw, asigRaw];

lx              = size(curSig,1);
lfilt            = length(vsigFilt);

%output datastructure
V_in_signal     = zeros(lfilt,1);
A_in_signal     = zeros(lfilt,1);
Vpeak_values    = zeros(lfilt,1);
Apeak_values    = zeros(lfilt,1);
%tempFig=figure;

%BS Ventricular Long AGC
%initialize
% function [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_BS (...
%     vThresNom, vAGCNomThres, ...
%     vRefPeriod, vAbsBlankPeriod, vNoiseWindow,vFixedRefPeriod, ...
%     vsAGCPeriod, vpAGCPeriod,...
%     aThresNom, aAGCNomThres, ...
%     aRefPeriod, aAbsBlankPeriod, aNoiseWindow,aFixedRefPeriod, ...
%     asAGCPeriod, apAGCPeriod, ...
%     aCCBlockPeriod)
%Nominal: 135ms refractory (50ms abs + 40ms noise + 45 ms fixed)


if strcmp(algo, 'bsc')
    % Boston SCientific's sensing seems to have many misses, so we
    % artificially (and arbitrarily) decrease the initial threshold for it.
    [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_BS(...
        vth,vth,... % for now make them all 270
        135, 50, 40, 45,... %
        35,35, ...
        ath,ath,... % for now make them all 270
        135, 50, 40, 45,... %
        35,35, ...
        15);
    plotAoutput = zeros(lfilt,5);
    plotVoutput = zeros(lfilt,4);
    %Input waveform one sample at a time
    for i=1:lx
        signal=curSig(i,:);
        [signal, V_in_signal(i), A_in_signal(i), A_blank, ICD_sense_state, ICD_sense_param]=ICD_sensing_BS(...
            ICD_sense_state, ICD_sense_param,...
            signal);
        %============== Plot ===================
        if(V_in_signal(i)==1)
            Vpeak_values(i)=abs(curSig(i,1));
        end
        if(A_in_signal(i)==1)
            Apeak_values(i)=abs(curSig(i,2));
        end
        if plotit
            plotVoutput(i,:)=[ICD_sense_state.VThres, ...
                ICD_sense_state.VAvg,...
                ICD_sense_state.VThresMax,...
                ICD_sense_state.VThresMin,...                
                ];
            plotAoutput(i,:)=[ICD_sense_state.AThres, ...
                ICD_sense_state.AAvg,...
                ICD_sense_state.AThresMax,...
                ICD_sense_state.AThresMin,...
                A_blank
                ];

        end
        %=================================
    end
    

    
elseif strcmp(algo,'med')
    % function [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_MED (...
    %     vThresNom,  vThresMin, vTC...
    %     vBlankAfterSense, vBlankAfterPace,vCrossChamberBlank,...
    %     aThresNom,  aThresMin, aTC...
    %     aBlankAfterSense, aBlankAfterPace,aCrossChamberBlank)
    [ICD_sense_state, ICD_sense_param]=ICD_sensing_init_MED(...
        vth,vth, 150,... %NOTE: TC is different from reference-- 450ms doesn't make sense. Was 270,50
        120, 150, 450,...
        ath,ath, 150,... %NOTE: TC is different from reference-- 450ms doesn't make sense
        120, 150, 450);
    plotAoutput = zeros(lfilt,2);
    plotVoutput = zeros(lfilt,2);
    %Input waveform one sample at a time
    for i=1:lx
        signal=curSig(i,:);
        [signal, V_in_signal(i), A_in_signal(i), A_block,ICD_sense_state, ICD_sense_param]=ICD_sensing_MED(...
            ICD_sense_state, ICD_sense_param,...
            signal);
        %============== Plot ===================
        if(V_in_signal(i)==1)
            Vpeak_values(i)=abs(curSig(i,1));
        end
        if(A_in_signal(i)==1)
            Apeak_values(i)=abs(curSig(i,2));
        end
        if plotit
            plotVoutput(i,:)=[ICD_sense_state.VThres, ...
                ICD_sense_state.VThresMin
                ];
            plotAoutput(i,:)=[ICD_sense_state.AThres, ...
                ICD_sense_state.AThresMin
                ];
        end
        %=================================
    end

elseif strcmp(algo, 'ground truth')
    plotit = 0;
    %warning('Ground truth sensing is used')
    if ~isfield(egm,'RVin') || ~isfield(egm,'RAin')
        error('For ground truth sensing, need both RVin and RAin')
    end
    A_in_signal = egm.RAin;
    V_in_signal = egm.RVin;
else
    error(['Sensing algo ', algo, ' not supported'])
end

events.Ain              = A_in_signal;
events.Apeakvalues      = Apeak_values;
events.Vin              = V_in_signal;
events.Vpeakvalues      = Vpeak_values;
events.initial_ath      = ath;
events.initial_vth      = vth;
if plotit
events.plot.plotAoutput = plotAoutput;
events.plot.plotVoutput = plotVoutput;

end
