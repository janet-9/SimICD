%% varargin are:
% 1: bandpass parameters (unused)
% 2: sensing thresholds
% 3: ICDsense state
% 4: ICDsense params

function [EGM, EGM_features,ICD_sense_state,ICD_sense_param] = BSc_extract_EGM_features_NSR_temp(EGM, EGM_NSR, varargin)

% parameters to build the VTC template
beatWindowSize = 10;

% apply sensing to the signal

%[bevents,ICD_sense_state,ICD_sense_param]=icd_sense_new(EGM,'bsc', bpf, own_thresholds, varargin{3}, varargin{4});
[EGM, events, ICD_sense_state, ICD_sense_param] = icd_sense_new(EGM, 'bsc', varargin{:});

%If no previous events are passed, only use the events found in this
%section 
if numel(varargin) <5
    bevents = events;    
else 
    %If previous events are given as an argument, concat those events to
    %the current signal for feature extraction. 
    prev_bevents = varargin{5};
    %disp(prev_bevents)
    bevents.Vin = [prev_bevents.Vin ; events.Vin];
    bevents.Vpeakvalues = [prev_bevents.Vpeakvalues ; events.Vpeakvalues];
    bevents.shock = [prev_bevents.shock ; events.shock];
end 


% total number of samples in the signal
N = length(bevents.Vin);

%%% BUILD THE TEMPLATE USING THE NSR TRACE FROM OPENCARP%%%%
NSR_temp = EGM_NSR;

% compute atrial and ventricular peak locations and periods
vpeaks = find(bevents.Vin);
%disp(vpeaks)
%vpeaks_curr = find(events.Vin);

% Initialise VbeatCnt(t)/AbeatCont(t) = total number of ventricular/atrial beats up to time t
VbeatCnt = zeros(1,N);

%Initialise vPeriods = the size of the windows between successive
%peaks 
vPeriods = [];

%Search for any sensed peaks, and if any are found, calculate the periods
%between the peaks and fill in the counters. 
if isempty(vpeaks)
    %disp('No Ventricular Peaks Found')
else
    vPeriods = [vpeaks(1);diff(vpeaks)];
    EGM_features.vPeriods = vPeriods;
    for k=1:length(vpeaks)-1
        VbeatCnt(vpeaks(k):vpeaks(k+1)-1) = k;
    end
    VbeatCnt(vpeaks(end):end) = VbeatCnt(vpeaks(end)-1)+1;
end

 
% % pre-compute fcc scores (used in the correlation discriminator)
fCCs = zeros(size(vpeaks));
for k = 1:length(vpeaks)
    vpeak = vpeaks(k);
    start_in = max(1, vpeak - 100);
    end_in = min(N, vpeak + 100);
    VTC_morph = bevents.shock(start_in:end_in);
    x = NSR_temp.refy;

    if sum(NSR_temp.refx>length(VTC_morph))>0
        fCCs(k) = inf;
    else
        y=(VTC_morph(NSR_temp.refx))';
       
        fCCs(k)=(8*sum(x.*y)-(sum(x)*sum(y)))^2/((8*sum(x.^2)-sum(x)^2)*(8*sum(y.^2)-sum(y)^2));
    end
end


% build the Vevent vector, s.t. Vevent(t) = 1 if a ventricular beat
% happens at t, 0 otherwise

% TODO: Vevent is transpose of bevent.Vin - is this necessary?
Vevent = (logical([0 diff(VbeatCnt)]))';

% precompute mean V rates 
% meanVrate = 60000/mean(V_win);
meanVrates = zeros(size(vpeaks));
for k=1:length(vpeaks)
    V_win = vPeriods(max(1,k-beatWindowSize+1):k);
    meanVrates(k) = 60000/mean(V_win);
end

% precompute V win covariances
Vcovs = zeros(size(vpeaks));
for k=1:length(vpeaks)
    V_win = vPeriods(max(1,k-beatWindowSize+1):k);
    Vcovs(k) = cov(V_win);
end

%populate the structure
EGM_features.vpeaks = vpeaks;
EGM_features.VbeatCnt = VbeatCnt;
EGM_features.vPeriods = vPeriods;
EGM_features.beatWindowSize = beatWindowSize;
EGM_features.meanVrates = meanVrates;
EGM_features.Vcovs = Vcovs;
EGM_features.Vevent = Vevent;
EGM_features.fCCs = fCCs;
EGM_features.events = bevents;

end