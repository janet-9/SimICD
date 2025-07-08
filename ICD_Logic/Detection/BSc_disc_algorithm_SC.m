
% this version has the correct implementation of the VT start
% plus the therapy signal is generated at each heart cycle (not sample) 

%% varargin is:
% 1: Whether or not stability is analysed in RhythmID - passed as a zero or
% one to turn it on or off. 
% 2:The clock and mode states from the previous chunk as well as the
% previous vbeatnumber, all stored in the output struct ICD_disc_state
% 3: The recordings of the therapy signals delivered so far. 


function [ICD_diagnosis, message] = BSc_disc_algorithm_SC(ICDparam, egmData, varargin)


% case when we pass an individual EGM feature structure
fldnames = fieldnames(egmData);

if ismember(fldnames{1},["vpeaks","VbeatCnt","vPeriods"...
    "beatWindowSize", "meanVrates","Vcovs","Vevent","fCCs"])
   % we re-arrange it in the expected format
   egmData_tmp = egmData;
   egmData = {};
   egmData.EGM_0 = egmData_tmp;
end


%% Add the parameters for the ICD discrimination 

%NEW: adding the parameters for the VT_1 zone and for Quick Convert ATP
%override threshold 

% all integers, but
VF_th = ICDparam.VF_th;
QC_Override_th = ICDparam.QC_Override_th;
VT_th = ICDparam.VT_th;
VT_1_th = ICDparam.VT_1_th;
VF_dur = ICDparam.VF_dur;
VT_dur = ICDparam.VT_dur;
VT_1_dur = ICDparam.VT_1_dur;

VTC_corr_th = ICDparam.VTC_corr_th;% real
stab = ICDparam.stab;% real


%% loading the signal chunk we've been given, and looking at the number of beats found in the section of signal. 
%Analysing the signal: data is the EGM features, which gets updated as each
%new chunk is added
fields = fieldnames(egmData);
data = egmData.(fields{1});
%This gives us the number of sensed beats in a section
numVbeats = length(data.vPeriods);

% VF_dur_mode is 1 if the algorithm is in VF duration at a given heart
% cycle. 0 otherwise. 

% Analyse the varargin, checking for the stability flag,  previous discrimination states and therapy signals. 
%if no previous discrimination state has been passed, initialise the
%therapy zone modes and the clocks to zero.


if nargin < 3 %AKA no flag given for stability analysis, default is to have it turned off
    stability_analysis = 0;
else
    stability_analysis = varargin{1};




if nargin < 4 %AKA, no discrimination state has been passed. 
    %Therapy Zone modes, including the redetection zones 
    VF_dur_mode = zeros(numVbeats,1);
    VT_dur_mode = zeros(numVbeats,1);
    VT_1_dur_mode = zeros(numVbeats,1);

    QC_dur_mode = zeros(numVbeats,1);
    VT1_ATP1_dur_mode = zeros(numVbeats,1);
    VT_ATP1_dur_mode = zeros(numVbeats,1);

    %Timers for each therapy zone
    vf_dur_clock = zeros(numVbeats,1);
    vt_dur_clock = zeros(numVbeats,1);
    vt_1_dur_clock = zeros(numVbeats,1);
    QC_dur_clock = zeros(numVbeats,1);
    VT1_ATP1_dur_clock = zeros(numVbeats,1);
    VT_ATP1_dur_clock = zeros(numVbeats,1);
    prev_vbeatnumber = 1;
else
    %load the therapy zone mode and clocks from the previous chunk 
    disc_state = varargin{2}; % Access the previous ICD_disc_state
    VF_dur_mode = disc_state.VF_dur_mode;
    VT_dur_mode = disc_state.VT_dur_mode;
    VT_1_dur_mode = disc_state.VT_1_dur_mode;
    vf_dur_clock = disc_state.vf_dur_clock; 
    vt_dur_clock = disc_state.vt_dur_clock;
    vt_1_dur_clock = disc_state.vt_1_dur_clock;
    %This should be the numVbeats from the previous chunk, if no beats have
    %yet been recorded, set it 1
    if disc_state.VbeatNum < 1
        prev_vbeatnumber = 1;
    else
        prev_vbeatnumber = disc_state.VbeatNum;
    end
    QC_dur_mode = disc_state.QC_dur_mode;
    QC_dur_clock = disc_state.QC_dur_clock;
    VT1_ATP1_dur_mode = disc_state.VT1_ATP1_dur_mode;
    VT1_ATP1_dur_clock = disc_state.VT1_ATP1_dur_clock;
    VT_ATP1_dur_mode = disc_state.VT_ATP1_dur_mode;
    VT_ATP1_dur_clock = disc_state.VT_ATP1_dur_clock;
end


if nargin < 5 %AKA, no previous therapy signals have been given 
    % Set up the therapy signal recordings for each therapy zone to keep track
    % of therapy delivery.

    numTherapyZones = 3;
    %VT1 is column 1
    %VT is column 2
    %VF is column 3

    %Set up the therapy signal counter 
    therapySigs= zeros(1,numTherapyZones);
else 
    %Use the previous therapy signal counter from the last chunk, to keep track of
    %the therapy delivered so far. 
    therapySigs = varargin{3};
end 




% loops over the ventricular beats (not the number of samples)
% VbeatNum is the total number of ventricular beats occured up to time t

for VbeatNum = prev_vbeatnumber:numVbeats

    % t is the time at which the current V beat occured
    t = data.vpeaks(VbeatNum);
   
    %Assign values for the last measured beat and average cycle length even
    %if no episode has occured - these are reassigned if therapy is
    %required. 
    last_beat_time = t;
    average_cycle = mean(data.vPeriods);
    message = 'No Therapy Required';


    %% Initial Detection, looking at an untreated signal to determine if an arrythmia episode will occur. For single chamber detection, only consider the ventricular and far field signal and the only extra discriminator used is the VTC discriminator. 
    

    % if 10 (beatWindowSize) ventricular beats are available
    if VbeatNum>=data.beatWindowSize
        % build windows of size beatWindowSize for ventricular periods
        V_win = data.vPeriods(VbeatNum-data.beatWindowSize+1:VbeatNum);
        % fcc scores
        fcc_win = data.fCCs(VbeatNum-data.beatWindowSize+1:VbeatNum);
     
        % these correspond to the VF and VT discriminators
        %NEW: added a discriminator for VT_1
        disc_1 = V_win(end)<VF_th && sum(V_win<VF_th)>=8; % VF discriminator
        disc_3 = V_win(end)<VT_th && sum(V_win<VT_th)>=8; % VT discriminator
        disc_2 = V_win(end)<VT_1_th && sum(V_win<VT_1_th)>=8; %VT_1 discriminator


        %% VF Protocol - No enhancement discriminators, only the rate
        %% and duration are considered.
        if ~isempty(VF_dur_mode) && VF_dur_mode(VbeatNum) % if in VF duration
            % updates the VF duration clock (adding the last V period)
            vf_dur_clock(VbeatNum) = vf_dur_clock(VbeatNum-1)+V_win(end);

            % event_2_tmp stores whether or not VF persisted
            disc_2_tmp = V_win(end)<VF_th && sum(V_win<VF_th)>=6;
            % if not, interrupt the window (for the next beat
            % VF_dur_win = 0)
            if ~disc_2_tmp
                if VbeatNum < numVbeats
                    VF_dur_mode(VbeatNum+1) = 0;
                end

                % if instead VF persisted and the VF duration length has
                % passed, we must give therapy
            elseif vf_dur_clock(VbeatNum) >= VF_dur

                %selecting therapy type for VF Zone

                %If the last period before therapy is decided on is shorter
                %than the override threshold, you go straight to biphasic
                %shock. 
                if V_win(end)<QC_Override_th
                    therapySigs(1,3) = 1; 
                    disp('Ventricular biphasic shock delivery required (QC Override)');
                    break 
                else
                    % Update the therapy signal to indicate that Quick
                    % Convert ATP has to be delivered.
                    % You also return the time at which therapy is required
                    % and the last measured bcl. 
                    therapySigs(1,3) = 1;
                    message = ['Quick Convert ATP required: Last measured bcl ', num2str(V_win(end)), ' 4 cycle average bcl', num2str(mean(V_win(end-3:end)))];
                    
                    %Assign ATP parameters 
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));

                    %start the QC therapy zone
                    QC_dur_mode(VbeatNum+1) = 1;
                    %interrupt the window
                    VF_dur_mode(VbeatNum+1) = 0;
                    break
                    
                end

                % if event_1_tmp is true (another VF episode is
                % detected) need to start a new VF window for the next
                % iteration
                if VbeatNum < numVbeats
                    if disc_1
                        vf_dur_clock(VbeatNum) = 0;
                        VF_dur_mode(VbeatNum+1) = 1;
                    end
                end

            else % VF persisted, but window is not over
                VF_dur_mode(VbeatNum+1) = 1;
            end
        end

        %% VT Protocol - Rhythm ID enhancement is used for Single Chamber Devices
        if ~isempty(VT_dur_mode) && VT_dur_mode(VbeatNum) % in VT duration
            % updates the VT duration clock (adding the last V period)
            vt_dur_clock(VbeatNum) = vt_dur_clock(VbeatNum-1)+V_win(end);
            % event_4_tmp stores whether or not VT persisted
            disc_4_tmp = V_win(end)<VT_th && sum(V_win<VT_th)>=6;
            % if not, interrupts the window
            if ~disc_4_tmp
                if VbeatNum < numVbeats
                    VT_dur_mode(VbeatNum+1) = 0;
                end
                % if instead VT persisted and the VT duration length has
                % passed
            elseif vt_dur_clock(VbeatNum) >= VT_dur
                % check the other discriminators in the VT branch - only
                % VTC used by default, stability is optional
                %Vector timing and correlation analysis - if 3 or more
                %are above the correlation threshold the rhythm is
                %considered correlated.
                disc_5 = sum(fcc_win >= VTC_corr_th)>= 3;
                %Stability analysis, if variation in periods is less
                %than the threshold the rhythm is declared unstable.
                disc_6 = data.Vcovs(VbeatNum) <= stab;

                if stability_analysis == 1 %You choose to analyse the stability 
                    % If the rhythm is declared both uncorrelated AND
                    % stable then ATP is called for VT zone
                    if ~disc_5 && ~disc_6
                        therapySigs(1,2) = 1;
                        message = ['VT ATP1 required: Last measured bcl ', num2str(V_win(end)),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                        VT_ATP1_dur_mode(VbeatNum+1)= 1;

                        %Assign ATP parameters
                        last_beat_time = t;
                        average_cycle = mean(V_win(end-3:end));
                        break
                    end


                elseif stability_analysis == 0 %Stability analysis is disabled 
                    % If the rhythm is declared uncorrelated then ATP is called for VT zone
                    if ~disc_5
                        therapySigs(1,2) = 1;
                        message = ['VT ATP1 required: Last measured bcl ', num2str(V_win(end)),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                        VT_ATP1_dur_mode(VbeatNum+1)= 1;

                        %Assign ATP parameters
                        last_beat_time = t;
                        average_cycle = mean(V_win(end-3:end));
                        break
                    end
                end

                if VbeatNum < numVbeats
                    % stopping the VT window does not imply stopping the VF
                    % one

                    % if event_3_tmp is true (another VT episode is
                    % detected) need to start a new VT window for the next
                    % iteration
                    if disc_3
                        vt_dur_clock(VbeatNum) = 0;
                        VT_dur_mode(VbeatNum+1) = 1;
                    end
                end
            else % VT persisted, but window is not over
                VT_dur_mode(VbeatNum+1) = 1;
            end
        end




        %% VT1 Protocol - Rhythm ID enhancement is used for Single Chamber Devices
        if ~isempty(VT_1_dur_mode) && VT_1_dur_mode(VbeatNum) % in VT1 duration
            % updates the VT1 duration clock (adding the last V period)
            vt_1_dur_clock(VbeatNum) = vt_1_dur_clock(VbeatNum-1)+V_win(end);
            % event_4_tmp stores whether or not VT1 persisted
            disc_4_tmp = V_win(end)<VT_1_th && sum(V_win<VT_1_th)>=6;
            % if not, interrupts the window
            if ~disc_4_tmp
                if VbeatNum < numVbeats
                    VT_1_dur_mode(VbeatNum+1) = 0;
                end
                % if instead VT1 persisted and the VT1 duration length has
                % passed
            elseif vt_1_dur_clock(VbeatNum) >= VT_1_dur
                % check the other discriminators in the VT branch - only
                % VTC used by default, stability is optional
                %Vector timing and correlation analysis - if 3 or more
                %are above the correlation threshold the rhythm is
                %considered correlated.
                disc_5 = sum(fcc_win >= VTC_corr_th)>= 3;
                %Stability analysis, if variation in periods is less
                %than the threshold the rhythm is declared unstable.
                disc_6 = data.Vcovs(VbeatNum) <= stab;

                if stability_analysis == 1 %You choose to analyse the stability 
                    % If the rhythm is declared both uncorrelated AND
                    % stable then ATP is called for VT zone
                    if ~disc_5 && ~disc_6
                        therapySigs(1,1) = 1;
                        message = ['VT1 ATP1 required: Last measured bcl ', num2str(V_win(end)),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                        VT1_ATP1_dur_mode(VbeatNum+1)= 1;

                        %Assign ATP parameters
                        last_beat_time = t;
                        average_cycle = mean(V_win(end-3:end));
                        break
                    end


                elseif stability_analysis == 0 %Stability analysis is disabled 
                    % If the rhythm is declared uncorrelated then ATP is called for VT zone
                    if ~disc_5
                        therapySigs(1,1) = 1;
                        message = ['VT1 ATP1 required: Last measured bcl ', num2str(V_win(end)),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                        VT1_ATP1_dur_mode(VbeatNum+1)= 1;

                        %Assign ATP parameters
                        last_beat_time = t;
                        average_cycle = mean(V_win(end-3:end));
                        break
                    end
                end

                if VbeatNum < numVbeats
                    % stopping the VT window does not imply stopping the VF
                    % one

                    % If another VT1 episode is
                    % detected) need to start a new VT window for the next
                    % iteration
                    if disc_2
                        vt_1_dur_clock(VbeatNum) = 0;
                        VT_1_dur_mode(VbeatNum+1) = 1;
                    end
                end
            else % VT1 persisted, but window is not over
                VT_1_dur_mode(VbeatNum+1) = 1;
            end
        end


        
        % if not in VF window, but VF detected, starts a new window
        if VF_dur_mode(VbeatNum) == 0  && disc_1
            vf_dur_clock(VbeatNum) = 0;
            VF_dur_mode(VbeatNum+1) = 1;
        end
        % if not in the VT window, but VT detected, starts a new window
        if VT_dur_mode(VbeatNum) == 0 && disc_3
            vt_dur_clock(VbeatNum) = 0;
            VT_dur_mode(VbeatNum+1) = 1;
        end
        % if not in VT_1 window, but VT_1 detected, starts a new window
        if VT_1_dur_mode(VbeatNum) == 0 && disc_2
            vt_1_dur_clock(VbeatNum) = 0;
            VT_1_dur_mode(VbeatNum+1) = 1;
        end

    end
end

%Populate the discrimination state structure

ICD_disc_state.VF_dur_mode = VF_dur_mode;
ICD_disc_state.VT_dur_mode = VT_dur_mode;
ICD_disc_state.VT_1_dur_mode = VT_1_dur_mode;
ICD_disc_state.vf_dur_clock = vf_dur_clock;
ICD_disc_state.vt_dur_clock = vt_dur_clock;
ICD_disc_state.vt_1_dur_clock = vt_1_dur_clock;
ICD_disc_state.VbeatNum = numVbeats;

% %Therapy and Redection Zone parameters 
ICD_disc_state.QC_dur_mode = QC_dur_mode;
ICD_disc_state.QC_dur_clock = QC_dur_clock;
ICD_disc_state.VT1_ATP1_dur_mode = VT1_ATP1_dur_mode;
ICD_disc_state.VT1_ATP1_dur_clock = VT1_ATP1_dur_clock;
ICD_disc_state.VT_ATP1_dur_mode = VT_ATP1_dur_mode;
ICD_disc_state.VT_ATP1_dur_clock = VT_ATP1_dur_clock;

%Populate the initial detection discrimination structure
ICD_diagnosis.ICD_disc_state = ICD_disc_state;
ICD_diagnosis.therapySigs = therapySigs;
ICD_diagnosis.average_cycle = average_cycle;
ICD_diagnosis.last_beat_time = last_beat_time;
ICD_diagnosis.message = message;



end
