function BandPassFilt = bpf_for_egm_sensing
%Band-pass filter

%%% The frequencies in the comments don't match the ones given in the
%%% function!!!
%%I've made an edit here to change the band pass filtering. 


A_stop1 = 60;		% Attenuation in the first stopband = 60 dB
F_stop1 = 5;		% Edge of the stopband = 8400 Hz
%F_pass1 = 10;	% Edge of the passband = 10800 Hz
F_pass1 = 20;	% Edge of the passband = 10800 Hz
%F_pass2 = 50;	% Closing edge of the passband = 15600 Hz
F_pass2 = 85;	% Closing edge of the passband = 15600 Hz
%F_stop2 = 55;	% Edge of the second stopband = 18000 Hz
F_stop2 = 100;	% Edge of the second stopband = 18000 Hz
A_stop2 = 60;		% Attenuation in the second stopband = 60 dB
A_pass = 1;		% Amount of ripple allowed in the passband = 1 dB
fs=1000;




BandPassSpecObj = ...
    fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
    F_stop1, F_pass1, F_pass2, F_stop2, A_stop1, A_pass, ...
    A_stop2, fs);

BandPassFilt = design(BandPassSpecObj, 'kaiserwin');