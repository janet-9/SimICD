%% varargin are:
% 1: bandpass parameters (unused)
% 2: sensing thresholds
% 3: ICDsense state
% 4: ICDsense params


function [EGM, events, ICD_sense_state, ICD_sense_param] = icd_sense_new(egm, algo, varargin)

% disp(varargin)
% events = icd_sense(egm, algo, BPF, vth, ICD state, ICD params)
%
% Sense egm using 'bsc' or 'med', after processing through the band-pass
% filter, rectification and truncating the first N samples, where N is the
% half-length of the band-pass filter.
%
% 
% egm.VSigRaw = V signal, unfiltered
% algo = string, either 'bsc' or 'med'

% BPF = a band-pass filter created using bpf_for_egm_sensing. Optional.
% vth: ventricular sensing threshold
% Optional. Can be obtained by running bin_initial_sensing_thresholds.
%
% If vth is provided as negative, then it is chosen
% according to the automatic setting strategy.
%
% Example:
% events = icd_sense(egm, 'bsc')
% events is a struct:
% egm.Vin = 1s and 0s

global debugprog;
debugme = debugprog;

EGM = egm;
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
if  nargin <4 || isempty(varargin{2})
    disp('No thresholds set')
    vth = set_initial_sensing_threshold(egm, 'midpoint');
%     [ath,vth] = bin_initial_sensing_thresholds(egm, 'midpoint', BandPassFilt);
else    
    sensing_threshold = varargin{2};
    if sensing_threshold <0 
        vth = set_initial_sensing_threshold(egm, 'midpoint');
%         [ath,vth] = bin_initial_sensing_thresholds(egm, 'midpoint', BandPassFilt);
        if strcmp(algo,'bsc')
            vth = 0.8*vth;
        end
        
        if sensing_threshold > 0
            vth = sensing_threshold;
        end
    else
        vth = sensing_threshold;
    end
end


%TODO: We don't want to load the full signal at once. In the online format,
%VSigRaw will ideally be updated one measurement at a time. 

vsigRaw=egm.VSigRaw;
% vsigFilt=filter(BandPassFilt,vsigRaw);
shocksigRaw = egm.Shock;
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


%%%% Initialises the 'current signal' as the raw atrial and ventricular
%%%% signals 
vsigFilt = vsigRaw;
curSig= vsigRaw;

%%%
lx              = size(curSig,1);
lfilt            = length(vsigFilt);

%output datastructure
%%%TODO: The size shouldn't be pre-set, set it to zero and update as you
%%%read in the data
V_in_signal     = zeros(lfilt,1);
Vpeak_values    = zeros(lfilt,1);


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

    %If there is no prior sense state or parameter given, use the
    %initialization function to generate them. 
    if nargin < 3 || numel(varargin) < 4 || isempty(varargin{3}) || isempty(varargin{4})
        [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_BS(...
            vth, vth, 135, 50, 40, 45, 35, 35);
    else
        ICD_sense_state=varargin{3};
        ICD_sense_param=varargin{4};
    end
    
    %plotVoutput = zeros(lfilt,4);
    %Input waveform one sample at a time
    for i=1:lx
        signal=curSig(i);
        [signal, V_in_signal(i), ICD_sense_state, ICD_sense_param]=ICD_sensing_BS(...
            ICD_sense_state, ICD_sense_param,...
            signal);
    end
    

    
% elseif strcmp(algo,'med')
%     % function [ICD_sense_state, ICD_sense_param]= ICD_sensing_init_MED (...
%     %     vThresNom,  vThresMin, vTC...
%     %     vBlankAfterSense, vBlankAfterPace,vCrossChamberBlank,...
%     %     aThresNom,  aThresMin, aTC...
%     %     aBlankAfterSense, aBlankAfterPace,aCrossChamberBlank)
%     if nargin < 3 || numel(varargin) < 4 || isempty(varargin{3}) || isempty(varargin{4})
%         [ICD_sense_state, ICD_sense_param]=ICD_sensing_init_MED(...
%             vth,vth, 150,... %NOTE: TC is different from reference-- 450ms doesn't make sense. Was 270,50
%             120, 150, 450,...
%             ath,ath, 150,... %NOTE: TC is different from reference-- 450ms doesn't make sense
%             120, 150, 450);
%     else
%         ICD_sense_state=varargin{3};
%         ICD_sense_param=varargin{4};
%     end
%     plotAoutput = zeros(lfilt,2);
%     plotVoutput = zeros(lfilt,2);
%     %Input waveform one sample at a time
%     for i=1:lx
%         signal=curSig(i,:);
%         [signal, V_in_signal(i), A_in_signal(i), A_block,ICD_sense_state, ICD_sense_param]=ICD_sensing_MED(...
%             ICD_sense_state, ICD_sense_param,...
%             signal);
%         %============== Plot ===================
%         if(V_in_signal(i)==1)
%             Vpeak_values(i)=abs(curSig(i,1));
%         end
%         if(A_in_signal(i)==1)
%             Apeak_values(i)=abs(curSig(i,2));
%         end
%         if plotit
%             plotVoutput(i,:)=[ICD_sense_state.VThres, ...
%                 ICD_sense_state.VThresMin
%                 ];
%             plotAoutput(i,:)=[ICD_sense_state.AThres, ...
%                 ICD_sense_state.AThresMin
%                 ];
%         end
%         %=================================
%     end

elseif strcmp(algo, 'ground truth')
   
    %warning('Ground truth sensing is used')
    if ~isfield(egm,'RVin')
        error('For ground truth sensing, you need RVin')
    end
    V_in_signal = egm.RVin;
else
    error(['Sensing algo ', algo, ' not supported'])
end


events.Vin              = V_in_signal;
events.Vpeakvalues      = Vpeak_values;
events.initial_vth      = vth;
events.shock            = shocksigRaw;

end
