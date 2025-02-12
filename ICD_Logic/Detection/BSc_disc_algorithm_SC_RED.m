%% varargin is:
% 1: The recordings of the therapy signals delivered so far as well as
% which zone we have delivered them in to make descisons about what therapy
% pathway to take
% 2:The clock and mode states from the previous chunk as well as the
% previous vbeatnumber, all stored in the output struct ICD_disc_state


function [ICD_diagnosis, ICD_disc_state, therapySigs, message] = BSc_disc_algorithm_SC_RED(ICDparam,egmData, varargin)

% case when we pass an individual EGM feature structure
fldnames = fieldnames(egmData);

if ismember(fldnames{1},["vpeaks","VbeatCnt","vPeriods",...
        "beatWindowSize","meanVrates","Vcovs","Vevent","fCCs"])
    % we re-arrange it in the expected format
    egmData_tmp = egmData;
    egmData = {};
    egmData.EGM_0 = egmData_tmp;
end


%% Add the parameters for the ICD discrimination

VF_th = ICDparam.VF_th;
QC_Override_th = ICDparam.QC_Override_th;
VT_th = ICDparam.VT_th;
VT_1_th = ICDparam.VT_1_th;

VF_red_dur = ICDparam.VF_red_dur;
VT_red_dur = ICDparam.VT_red_dur;
VT_1red_dur = ICDparam.VT_1red_dur;


%% loading the signal chunk we've been given, and looking at the number of beats found in the section of signal.
%Analysing the signal: data is the EGM features, which gets updated as each
%new chunk is added
fields = fieldnames(egmData);
data = egmData.(fields{1});
%This gives us the number of sensed beats in a section
numVbeats = length(data.vPeriods);



%% Analyse the varargin, checking for previous discrimination states and therapy signals.
%if no previous discrimination state has been passed, initialise the
%therapy zone modes and the clocks to zero.

if nargin < 3 %AKA, no previous therapy signals have been given - this is an error when performing redetection!

   error('No previous therapy delivered, exiting redetection mode');
   

else
    %Use the previous therapy signals from the last chunk, to keep track of
    %the therapy delivered so far.
    therapySigs = varargin{1};
end

if nargin < 4 %No discrimination state has been passed.
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

for VbeatNum = prev_vbeatnumber:numVbeats

    % t is the time at which the current V beat occured
    t = data.vpeaks(VbeatNum);
 
    %Assign values for the last measured beat and average cycle length even
    %if no episode has occured - these are reassigned if therapy is
    %required.
    last_beat_time = t;
    average_cycle = mean(data.vPeriods);
    message = 'No further therapy required';

    % loops over the ventricular beats (not the number of samples)
    % VbeatNum is the total number of ventricular beats occured up to t

    % if 10 (beatWindowSize) atrial and ventricular beats are available
    if VbeatNum>=data.beatWindowSize
        % build windows of size beatWindowSize for ventricular periods
        V_win = data.vPeriods(VbeatNum-data.beatWindowSize+1:VbeatNum);
        % % fcc scores
        % fcc_win = data.fCCs(VbeatNum-data.beatWindowSize+1:VbeatNum);
       
        % these correspond to the VF and VT discriminators
        %NEW: added a discriminator for VT_1
        disc_1 = V_win(end)<VF_th && sum(V_win<VF_th)>=8; %VF discriminator 
        disc_3 = V_win(end)<VT_th && sum(V_win<VT_th)>=8; %VT discriminator
        disc_2 = V_win(end)<VT_1_th && sum(V_win<VT_1_th)>=8; %VT_1 discriminator 



        %% Redection Zones for signals given post therapy.  For redetection post-ATP we are in redetection mode, so we don't need the parameters for Rhythm ID
        %% enhancement, we just look at rate and duration of the signal.

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
            elseif vf_dur_clock(VbeatNum) >= VF_red_dur

                %selecting therapy type for VF Zone

                %If the last period before therapy is decided on is shorter
                %than the override threshold, you go straight to biphasic
                %shock.
                if V_win(end)<QC_Override_th
                    therapySigs(1,3) = therapySigs(1,3) + 1;
             
                    message = ['Ventricular biphasic shock delivery required at time, QC Override ' num2str(t)];
                    break
                else %You have a persistant VF episode
                    if therapySigs(1,3) == 1 %You've already delivered therapy in the VF zone
                        therapySigs(1,3) = therapySigs(1,3) + 1;
                        message = ['Ventricular biphasic shock delivery required at time, QC failed ' num2str(t)];
                        break

                    elseif therapySigs(1,3) == 0 % You've not yet delivered therapy in this zone

                        % Start the first round.
                        % Update the therapy signal to indicate that Quick
                        % Convert ATP has to be delivered.
                        % You also return the time at which therapy is required
                        % and the last measured bcl.

                        therapySigs(1,3) = therapySigs(1,3) + 1;
                        message = ['Quick Convert ATP required at time ' num2str(t), ' last measured bcl ', num2str(V_win(end)), ' 4 cycle average bcl', num2str(mean(V_win(end-3:end)))];

                        %Assign ATP parameters
                        last_beat_time = t;
                        average_cycle = mean(V_win(end-3:end));

                        %start the QC therapy zone
                        QC_dur_mode(VbeatNum+1) = 1;
                        %interrupt the window
                        VF_dur_mode(VbeatNum+1) = 0;
                        break
                    end
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



        %% VT Protocol
        if ~isempty(VT_dur_mode) && VT_dur_mode(VbeatNum) % in VT duration
            % updates the VT duration clock (adding the last V period)
            vt_dur_clock(VbeatNum) = vt_dur_clock(VbeatNum-1)+V_win(end);
            % event_4_tmp stores whether or not VT persisted
            disc_4_tmp = V_win(end)<VT_th && sum(V_win<VT_th)>=6;
            % if not, interrupts the window
            if ~disc_4_tmp
                if VbeatNum < numVbeats
                    VT_dur_mode(VbeatNum+1) = 0;
                    % if event_4_tmp is false, then also event_1_tmp and event_3_tmp are
                    % so a new window cannot start straight away
                end
                % if instead VT persisted and the VT duration length for redetection has
                % passed
            elseif vt_dur_clock(VbeatNum) > VT_red_dur %You've passed redetection duration

                if therapySigs(1,2) == 1 % ATP1 has already been delivered in the VT zone
                    %Only therapy left in this zone is ATP2
                    %Update therapy signals to flag a therapy delivery in
                    %VT zone
                    therapySigs(1,2) = therapySigs(1,2) + 1;

                    %Assign ATP parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['VT ATP2 required at time ' num2str(last_beat_time), ' last measured bcl ', num2str(average_cycle), ' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                    break

                elseif therapySigs(1,2) == 0 % No delivery in this zone yet
                    %Update therapy signals to flag a therapy delivery in
                    %VT zone
                    therapySigs(1,2) = therapySigs(1,2) + 1;

                    %Assign ATP parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['VT ATP1 required at time ' num2str(last_beat_time), ' last measured bcl ', num2str(average_cycle), ' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                    break

                elseif therapySigs(1,2) == 2 %ATP1 and ATP2 have already been delivered in the VT zone
                    % Both therapies within this zone have been applied, so
                    % the only option left is to apply a shock
                    therapySigs(1,2) = therapySigs(1,2) + 1;

                    %Return Therapy Parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['Ventricular biphasic shock delivery required at time ' num2str(t)];
                    break

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




        %% VT_1 Protocol - this is the same as VT zone but results in a different course of therapy and has different detection parameters
        if ~isempty(VT_1_dur_mode) && VT_1_dur_mode(VbeatNum) %VT_1_dur_mode(VbeatNum) % in VT duration
            % updates the VT duration clock (adding the last V period)
            vt_1_dur_clock(VbeatNum) = vt_1_dur_clock(VbeatNum-1)+V_win(end);
            % event_4_tmp stores whether or not VT persisted
            disc_8_tmp = V_win(end)<VT_1_th && sum(V_win<VT_1_th)>=6;
            % if not, interrupts the window
            if ~disc_8_tmp
                if VbeatNum < numVbeats
                    VT_1_dur_mode(VbeatNum+1) = 0;
                    % if event_4_tmp is false, then also event_1_tmp and event_3_tmp are
                    % so a new window cannot start straight away
                end
                % if instead VT_1 persisted and the VT_1 duration length has
                % passed
            elseif vt_1_dur_clock(VbeatNum) > VT_1red_dur %You've passed redetection duration

                if therapySigs(1,1) == 1 % ATP1 has already been delivered in the VT_1 zone
                    %Only therapy left in this zone is ATP2
                    %Update therapy signals to flag a second therapy delivery in
                    %Vt_1 zone
                    therapySigs(1,1) = therapySigs(1,1) + 1;


                    %Assign ATP parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['VT_1 ATP2 required at time ' num2str(last_beat_time), ' last measured bcl ', num2str(average_cycle),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                    break

                elseif therapySigs(1,1) == 0 % No Therapy in delivered in this zone yet
                    %Update therapy signals to flag a second therapy delivery in
                    %Vt_1 zone
                    therapySigs(1,1) = therapySigs(1,1) + 1;


                    %Assign ATP parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['VT_1 ATP2 required at time ' num2str(last_beat_time), ' last measured bcl ', num2str(average_cycle),' 4 cycle average bcl ', num2str(mean(V_win(end-3:end))) ];
                    break

                elseif therapySigs(1,1) == 2 %ATP1 and ATP2 has already been delivered in the VT_1 zone
                    % Both therapies within this zone have been applied, so
                    % the only option left is to apply a shock
                    therapySigs(1,1) = therapySigs(1,1) + 1;

                    %Return Therapy Parameters
                    last_beat_time = t;
                    average_cycle = mean(V_win(end-3:end));
                    message = ['Ventricular biphasic shock delivery required at time ' num2str(t)];
                    break
                end



                if VbeatNum < numVbeats
                    % stopping the VT_1 window does not imply stopping the VF
                    % one

                    % if event_3_tmp is true (another VT_1 episode is
                    % detected) need to start a new VT_1 window for the next
                    % iteration
                    if disc_2
                        vt_1_dur_clock(VbeatNum) = 0;
                        VT_1_dur_mode(VbeatNum+1) = 1;
                    end
                end
            else % VT_1 persisted, but window is not over
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


%ICD_disc_state.EoE_NT_clock = EoE_NT_clock;
%ICD_disc_state.EoE_ATP_clock = EoE_ATP_clock;

%Populate the initial detection discrimination structure
ICD_diagnosis.ICD_disc_state = ICD_disc_state;
ICD_diagnosis.therapySigs = therapySigs;
ICD_diagnosis.average_cycle = average_cycle;
ICD_diagnosis.last_beat_time = last_beat_time;
ICD_diagnosis.message = message;








end
