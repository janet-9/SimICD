function [WV,varargout] = get_single_beats(EGM,method,maxnbeats,perc,rawOrFiltered)
% [WA,WV,WS] = get_single_beats(EGM, method, maxnbeats, perc, rawOrFiltered)
%
% Extracts single beats from input EGM.
% 
% The extraction algo finds the max M of the rectified egm signal,
% calculates a threshold based on perc, and gets all values above the
% threshold. The first time this threshold is exceeded is taken to be the peak location
% (though not exactly - read on).
% If perc > 0, it is treated as a percentage and the threshold for
% detection is set at 100*perc% of M.
% If perc is given as a negative number, then the threshold is set at -perc
% i.e. -perc is treated as an absolute threshold, not as a percentage.
% If perc = 0, then the pre-detected events are used to find peaks. These
% are stored in the fields RAin and RVin of EGM.
% perc can be either a scalar or a 3-element vector, one value per channel:
% perc(1) for right atrium, perc(2) for right ventricle, and perc(3) for
% shock channel.
% If perc is a scalar, then this scalar is used as the perc value for all
% three channels.
% If isempty(perc), uses default value = 0.5 for all channels.
%
% Returns maxnbeats, not all peaks it finds. If maxnbeats <=0, uses default
% value of 10 beats.
%
% The window around the peak which determines the beginning and end of beat
% is determined by method: if 'fixed window', a window of width 100 on
% either side is used.
% If 'midpoint', the midpoint between successive peaks
% is used. The midpoint only works if it can catch all consecutive peaks.
% Otherwise it will be picking the midpoint between distant peaks, and as
% such is not really reliable.
% User can also give an integer as method, which is then used as the width
% for 'fixed window' method.
% If method is '', uses default value = 'fixed window'.
% 
% rawOrFiltered is a string: 'raw' finds beats in the raw signals,
% 'filtered' finds beats in the filtered signals. Default is 'raw'.
%
% All arguments are optional except EGM. EGM is a struct with ASigRaw and
% VSigRaw fields, and ASigFilt and VSigFilt fields if rawOrFiltered =
% 'filtered'.
%
% WA : nx2 gives timestamps of start and end single atrial beats: ith
% atrial beat starts at WA(i,1) and ends at WA(i,2)
% WV and WS do the same thing for ventricular and shock beats

global debugprog;
debugme = debugprog;

%--------------------------------------------------------------------------
% Magic numbers
% For two above-threshold values to be counted as belonging to different
% peaks, they need to be at least this much apart
min_peak_separation = 50;
%--------------------------------------------------------------------------

width = 100;
if nargin < 5
    rawOrFiltered = 'raw';
else
    assert(strcmp(rawOrFiltered, 'raw') || strcmp(rawOrFiltered,'filtered'))
end
if nargin < 4 || isempty(perc)
    perc= [0.5, 0.5];
end
if nargin < 3 
    maxnbeats = 10;
end
if nargin < 2 || strcmp(method , '')
    method = 'fixed window';
    width = 100;
else
    if ischar(method)
        if ~strcmp(method, 'fixed window') && ~strcmp(method,'midpoint')
            error('Unsupported method')
        end
    else
        width = method;
        method = 'fixed window';
    end
    
end

% For fixed window method, hte window is not symmetric because we center it
% on the beginning of the peak, so it's shorter in the past than it is in
% the future.
width_past = ceil(0.33*width);


%This sets the perc value for each channel to the same value as the single
%input if only 1 number is given. Set up for 2 channels rather than 3 as we
%don't monitor the atrial channel. 
if numel(perc) == 1 
    perc = perc*ones(1,2);
end

%This defines the channel each perc is applied to. The events are given by
%RVin and the signal is given by the raw signal. 
for k=1:length(perc)
    if k==1
        events= EGM.RVin;
        if strcmp(rawOrFiltered,'raw')
            y=EGM.VSigRaw;
        else
            y=EGM.VSigFilt;
        end
    elseif k==2
        events = [];
        noshock = 1;
        if isfield(EGM,'Shock')%produced by heart2egm
            y = EGM.Shock;
            shock_channel = 7;
            noshock=0;
        else
            for ch=1:length(EGM.channelLabel)
                if regexpi(EGM.channelLabel{ch}, '-Uni?$')
                    y = EGM.currentRec(:,ch);
                    shock_channel = ch;
                    noshock = 0;
                    %fprintf('\n\n SHOCK!\n\n\n')
                    break
                end
            end
        end
        if noshock
            disp('Found no shock channel')
            %keyboard
        end
    end


    assert(~isempty(y))
    % Rectify ONLY - filtering completely messes up the peak identification
    %Turns all the values in the raw signal positive. 
    x = abs(y);
    %x = y;


    % Get the peaks
    if perc(k) == 0
        % Note that if k==3 (shock channel) this will be empty
        peakindex = find(events);        
    else
        M = max(x);
        % Wild guess: most peaks are above perc% of the max
        if perc(k) >= 0
            curr_th = perc(k)*M;
            capindex =  find(x> curr_th);
        else % indicating an absolute threshold rather than a percentage of max
            curr_th = -perc(k);
            capindex = find(x > curr_th);            
        end


        % delta(k) = capindex(k+1) - capindex(k)
        delta = capindex(2:end)-capindex(1:end-1);
        % Arbitrary: if two above-threshold values are distant by more than 50
        % samples, they belong to different peaks
        fd = find(delta > min_peak_separation);
        
        % fd indexes delta, and thus indexes capindex(2:end): fd(k) is the
        % index of difference capindex(k+1)-capindex(k), so if delta(fd(1))=50,
        % and fd(1) = 70, this means capindex(71)-capindex(70)=50, so
        % capindex(71) is hte beginning of a new peak
        peakindex = capindex(fd+1);
    end
    
    n = length(peakindex);
    % Return some of the windows since we don't want all the templates,
    % just some
    if maxnbeats <= 0
        p = n;
    else
        p = min(maxnbeats,n);
    end

    %The get_peak_centered_win function is not defined anywhere!!

    if strcmp(method, 'fixed window')
        W = zeros(p,2);
        for kk=1:p            
            [~, Wk] = get_peak_centered_win(peakindex(kk), width, x, x);
            W(kk,:) = Wk;
        end
        % W = [max([ones(p,1),peakindex(1:p)-width_past],[],2) , min([length(x)*ones(p,1), peakindex(1:p)+width], [], 2)];


    elseif strcmp(method, 'midpoint')
        % Take the midpoint between peaks.
        W = zeros(p,2);
        if p >= 3 % no peaks might have been detected if the threshold is too high
            iw = 2;
            for ii=2:p-1
                toprevious = peakindex(ii) - peakindex(ii-1);
                tonext = peakindex(ii+1) - peakindex(ii);
                W(iw,:) = [peakindex(ii) - floor(0.5*toprevious), peakindex(ii) + floor(0.5*tonext)];
                assert(nnz(W(iw,:) >0) == 2);
                iw = iw+1;
            end

            
            % Handle end cas           
            toprevious = peakindex(1);                    
            if n==p 
                tonext      = 2*width;
            else
                tonext      = peakindex(p+1) - peakindex(p);
            end
            W(end,:) = [peakindex(p)-floor(0.5*toprevious), peakindex(p) + floor(0.5*tonext)];
        elseif p ==2 
            W = [floor(0.5*peakindex(1)), peakindex(1)+ floor(0.5*(peakindex(2) - peakindex(1)))
                peakindex(2) - floor(0.5*(peakindex(2)-peakindex(1))), peakindex(2)+ floor(0.5*width)];
        elseif p == 1
            W = [floor(0.5*peakindex(1)), peakindex(1)+ 0.5*(width)];
        end
    
    else
        error('Unsupported method')
    end
    if k==1
        WV = W;
    elseif k==2
        WS = W;
    end
    
end

if nargout >= 3
    varargout{1} = WS;
    if nargout >= 4
        varargout{2} = shock_channel;
    end
end

end
