function ICD_LOGIC_TEST(therapy_sig, history, max_therapy_calls)
% ICD_LOGIC_TEST: Simulates ICD logic using dummy therapy signals.
%
% Inputs:
%   - therapy_sig: Initial therapy signals [VT1, VT, VF] (default: [1 0 0])
%   - history: Therapy history per zone [VT1_H, VT_H, VF_H] (default: [0 0 0])
%   - max_therapy_calls: Max therapy allowed per zone [VT1_max, VT_max, VF_max] (default: [3 3 2])
%
% Output:
%   - outcome: String indicating result (e.g., 'Therapy Successful', 'Shock Required')

    % Set defaults if arguments are missing
    if nargin < 1 || isempty(therapy_sig)
        therapy_sig = [1 0 0]; % Default: VT1 only
    end
    if nargin < 2 || isempty(history)
        history = [0 0 0]; % Default: No prior therapy
    end
    if nargin < 3 || isempty(max_therapy_calls)
        max_therapy_calls = [3 3 2]; % Default max calls per zone
    end

%Set Maximum Number of Therapy Calls for each Zone 
VT1_max = max_therapy_calls(1);
VT_max = max_therapy_calls(2);
VF_max = max_therapy_calls(3);

%Load the Therapy Signals and the discrimination state from the initial diagnosis
[VT1, VT, VF] = reachTh(therapy_sig);
%ICD_disc_state = ICD_diagnosis.ICD_disc_state;

while(true)

    %This check is only used in the initial diagnosis, if the
    %discrimination algorithm doesn't initiate therapy from the initial
    %episode then the therapy progression ends here.
    if ~VT1 && ~VT && ~VF %If the therapy counter for all of the zones is zero then no therapy is required - end the simulation process!
        disp('No Therapy Required!');
        return;

    %Check to see if the max therapy calls have been made in any zones and
    %terminate if they have. 
    elseif VT1 >= VT1_max || VT >= VT_max || VF >= VF_max
        disp(therapy_sig)
        disp('ATP Therapy Availability Threshold Exceeded - Shock Required!');
        break;


    elseif VF && history(3) < 2 %QC therapy required - Follow therapy pathway for VF:

        %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");


        disp('Running QC ATP')
        pause(2)

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        % Generate the signals randomly given the input:
        therapy_sig = generate_therapy_sigs(therapy_sig);
        [VT1, VT, VF] = reachTh(therapy_sig);


        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
             disp(['Therapy Successful- VF episode terminated:', num2str(therapy_sig)]);
            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            disp(['VF Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            disp(['VT1 Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
           disp(['VT Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        end


        % From the initial episode, VT therapy required from the diagnosis and
        % no previous therapies have been required in that zone, so ATP therapy
        % is delivered.
    elseif VT && history(2) < 2 % VT ATP_1 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            %Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
           % Input_state_time = ICD_diagnosis.last_beat_time;
        end

        disp('Running VT ATP1 - Burst')
        pause(2)

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        % Generate the signals randomly given the input:
        therapy_sig = generate_therapy_sigs(therapy_sig);
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
             disp(['Therapy Successful- VT episode terminated:', num2str(therapy_sig)]);
            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT >= 1 && history(2) >= 2 % VT ATP_2 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            %Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
           % Input_state_time = ICD_diagnosis.last_beat_time;
        end

        disp('Running VT ATP2 - Ramp')
        pause(2)

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        % Generate the signals randomly given the input:
        therapy_sig = generate_therapy_sigs(therapy_sig);
        [VT1, VT, VF] = reachTh(therapy_sig);


        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
             disp(['Therapy Successful- VT episode terminated:', num2str(therapy_sig)]);

            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT1 && history(1) < 2 % VT_1 ATP_1 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            %Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
           % Input_state_time = ICD_diagnosis.last_beat_time;
        end

        disp('Running VT1 ATP1 - Burst')
        pause(2)

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        % Generate the signals randomly given the input:
        therapy_sig = generate_therapy_sigs(therapy_sig);
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
             disp(['Therapy Successful- VT episode terminated:', num2str(therapy_sig)]);
            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT1 >= 1 && history(1) >= 2 % VT_1 ATP_2 therapy required

       %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            %Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
           % Input_state_time = ICD_diagnosis.last_beat_time;
        end


        disp('Running VT1 ATP2 - Ramp')
        pause(2)

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        % Generate the signals randomly given the input:
        therapy_sig = generate_therapy_sigs(therapy_sig);
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp(['Therapy Successful- VT episode terminated:', num2str(therapy_sig)]);
            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            %save('Therapy_History.mat', "history")
            continue;
        end



    elseif VF >= 1 && history(3) > 2 %QC therapy already applied:

        disp(['VF Called: Available Therapies Unsuccessful - Shock Required!', num2str(history)])
   

        break;

    elseif VT >= 1 && history(2) > 3 %Both rounds of ATP already delivered:
        disp(['VT Called: Available Therapies Unsuccessful - Shock Required!', num2str(history)])
      
        break;

    elseif VT1 >= 1 && history(1) > 3 %Both rounds of ATP already delivered:
        disp(['VT1 Called: Available Therapies Unsuccessful - Shock Required!', num2str(history)])
      
        break;
    end
end

end