function ICD_state= acquire_VTC_template(events,ICD_state,egm, nb_averaged_beats)
% VTC template
t=200;
window_width = 100;
VTC_win=zeros(nb_averaged_beats,2*window_width+1);
nb_acquired_beats=1;
while t<=length(egm.ASigRaw)-1
    t=t+1;    
    if events.Vin(t)
        VTC_win(nb_acquired_beats,:)=egm.Shock(t-window_width:t+window_width)';
        nb_acquired_beats=nb_acquired_beats+1;
        if nb_acquired_beats==nb_averaged_beats
            NSR_temp.raw=sum(VTC_win,1)./nb_averaged_beats;
            break;
        end
    end
    
end


if nb_acquired_beats < nb_averaged_beats
    warning('Did not find 16 beats for VTC')
    [~, ~, WS] = get_single_beats(egm,'fixed window',nb_averaged_beats, 0.75, 'raw');
    nb_returned_beats = size(WS,1);
    y = zeros(WS(1,2)-WS(1,1)+1,1);
    for w=1:nb_returned_beats
        y = y + egm.Shock(WS(w,1):WS(w,2));
    end
    y = y/nb_returned_beats;
    NSR_temp.raw = y';
end

x=1:25:200;
NSR_temp.refx=x;
NSR_temp.refy=NSR_temp.raw(x);
ICD_state.NSR_temp = NSR_temp;
