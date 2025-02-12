function NSR_temp = NSR_temp_build(EGM)
%%Function to generate an NSR Morphology Template to call within the
%%feature extraction portion of the ICD algorithm

%Extract the events using ICD sense 
[~, NSR_events, ~, ~] = icd_sense_new(EGM, 'bsc', [], 2);

%Set the window size and the number of beats to average over to ge the
%template
%beatWindowSize = 10;
nb_averaged_beats = 15;

%Generate the Morphology template and save it 
NSR_ICD_state = initialize_icd('bsc');
NSR_ICD_state = acquire_VTC_template(NSR_events, NSR_ICD_state, EGM, nb_averaged_beats);
NSR_temp = NSR_ICD_state.NSR_temp;

end