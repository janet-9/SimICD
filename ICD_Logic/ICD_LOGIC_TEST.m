%ICD Logic Tester

%Therapy History Tracker Initialisation:
%History = [ VT1_H, VT_H, VF_H]
history = [0 0 0];
VT1_H = history(1);
VT_H = history(2);
VF_H = history(3);

%Set Maximum Number of Therapy Calls for each Zone 
max_therapy_calls = [3 3 2];
VT1_max = max_therapy_calls(1);
VT_max = max_therapy_calls(2);
VF_max = max_therapy_calls(3);



%Load the Therapy Signals and the discrimination state from the initial diagnosis

therapy_sig = [0 0 0];
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

        % % Terminate background episode simulation
        % killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1');
        % system(killCommand);
        % disp('Initial Episode Simulation Ended...');
        % return;
        % 

         %% TO-DO: Sort the therapy delivery and redetection for the VF zone!!
        % For the initial episode, if VF therapy required and no therapy has been
        % delivered in this zone, proceed with QC ATP.

    elseif VF && history(3) < 2 %QC therapy required - Follow therapy pathway for VF:

        %Set the parameters for QC therapy
        ATP_CL = 0.88; % Nominal value for the BSc device
        ATP_coupling = 0.88; % Nominal value for the BSc device

        %Save the previous therapy signals for later comparison
        prev_therapySigs = therapy_sig;
        %save("Prev_TherapySigs.mat", "prev_therapySigs");

        % % Call the function to run the QC ATP therapy simulation
        % %[outputFile, ICD_diagnosis, pid] = QC_ATP(outputFile, ICD_diagnosis, Input_state_time_init, ATP_CL, ATP_coupling, ...
        %     mesh, conmul, nprocs, pythonExe, Simscript, full_sim_time, bcl, strength, duration, ...
        %     start, output_res, check, monitor_duration);


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
        % %Terminate background episode simulation
        % killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
        % system(killCommand);
        % disp('Initial Episode Simulation Ended...');

        break;

    elseif VT >= 1 && history(2) > 3 %Both rounds of ATP already delivered:
        disp(['VT Called: Available Therapies Unsuccessful - Shock Required!', num2str(history)])
        % %Terminate background episode simulation
        % killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
        % system(killCommand);
        % disp('Initial Episode Simulation Ended...');
        break;

    elseif VT1 >= 1 && history(1) > 3 %Both rounds of ATP already delivered:
        disp(['VT1 Called: Available Therapies Unsuccessful - Shock Required!', num2str(history)])
        %Terminate background episode simulation
        % killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
        % system(killCommand);
        % disp('Initial Episode Simulation Ended...');
        break;
    end
end