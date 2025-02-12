function [nbVbeats] = count_true_beats(egm)
% An event lasts a whole millisecond so detect rising edge

%When you run this on RVin - the results are 0 because no values
%are -1 
d = egm.RVin(1:end-1) - egm.RVin(2:end);
event_time = find(d==-1);
nbVbeats = length(event_time);