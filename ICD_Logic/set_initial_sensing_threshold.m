function vth = set_initial_sensing_threshold(EGM, method, varargin)

global debugprog;
debugme = debugprog;

%Find max values of the raw ventricular signal
Mv = max(abs(EGM.VSigRaw));
M = Mv;

%Why is this done??
if nargin < 3
    decrement = 0.3*Mv;
end

maxnbeats = length(EGM.VSigRaw);
[truenbVbeats] = count_true_beats(EGM);
Vtolerance = floor(0.1*truenbVbeats);
if debugme
    fprintf('%d True V beats, tolerance (%d)\n', truenbVbeats, Vtolerance)
end

already_set_vth = 0;
% Since we don't care about WS here, we set it to the usual 0.5
k=[1,0.5];
vth = nan;
while ~(already_set_vth)
    % Get the beats
    [WV,~, ~] = get_single_beats(EGM,method,maxnbeats,[-k(1)*decrement, -k(2)*decrement, k(3)]);
    if debugme 
        fprintf('%d V beats, Th= %d\n', ...
            size(WV,1),...
            Mv-k(2)*decrement);
    end

    % If the nb of beats is within tolerance of the true value, stop
    % decrementing
    if abs(size(WV,1) - truenbVbeats) <= Vtolerance || Mv-(k(2)+1)*decrement <= 0
        vth = M - k(2)*decrement;
        already_set_vth = 1;
    else
        k(2) = k(2)+1;
    end
    
    if Mv-k(2)*decrement < 0
        warning('Negative sensing threshold')
        %keyboard
    end
    
end