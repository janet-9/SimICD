%ICD Sensing Function
%input: TBD
% % parameter struct
% (initial settings)
%ICD_sense_state
%State: 1 - sensing/AGC
%       2 - peak tracking
%       3 - absolute blanking
%       4 - noise window
%       5 - fixed refractory
% ICD_sense_state.State=1;
% ICD_sense_state.VPace=0;
% ICD_sense_state.VSense=0;
% ICD_sense_state.APace=0;
% ICD_sense_state.ASense=0;
% ICD_sense_state.StateClock=0;
% ICD_sense_state.StateClockLim=0;
% ICD_sense_state.RefPeriodClock=0;
% ICD_sense_state.VThres=vThresMin;
% ICD_sense_state.VType=1;
% ICD_sense_state.VAvg=vThresMin;%TODO: could be different initial value
% ICD_sense_state.DebugClock=0;

% current state
% current waveform sample (vector)
%output: TBD
% input waveform
% current threshold
%TODO: what happens when there is a VPACE event, but it is not sensed?
function [Asignal, V_in, A_in, A_blank,ICD_sense_state, ICD_sense_param]=ICD_sensing_BS_A(...
    ICD_sense_state, ICD_sense_param,...
    signal)

V_in=0;
A_in=0;
A_blank=0;
Asignal=abs(signal);

ICD_sense_state.DebugClock=ICD_sense_state.DebugClock+1;
ICD_sense_param.DebugClock=ICD_sense_param.DebugClock+1;
%Assumptions
%If there is a VSense, no matter the state, will go into smartsense
%After blanking, reset AGC to 3/8 --> compass book
%TODO: It could be possible to do a different fixed cross-chamber blanking
%rather than "SMARTSensing"

if((ICD_sense_state.VSense==1)||(ICD_sense_state.VPace==1)&&ICD_sense_state.AState~=6)
    ICD_sense_state.AState=6;
    ICD_sense_state.AAGCOn=0;
    
    if(ICD_sense_state.VSense==1)
        ICD_sense_state.VSense=0;
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.ACCBlankPeriod;
        ICD_sense_state.PrevA=ICD_sense_state.AThres;
    end
    %assuming that in the case that there is a vsense as well as a vpace,
    %preference will be given to the pace
    if (ICD_sense_state.VPace==1)
        ICD_sense_state.VPace=0;
        %TODO: Something for adjust for VPACE, for now just keep same
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.ACCBlankPeriod;
    end
    
end

%Sensing
if(ICD_sense_state.AState==1)
    
    if(Asignal>=ICD_sense_state.AThres)
        ICD_sense_state.AState=2;
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.AAbsBlankPeriod;
        ICD_sense_state.AAGCOn=0;
        if(ICD_sense_state.APace==0)
            ICD_sense_state.ASense=1;
            A_in=1;
            
        end
        if(ICD_sense_state.APace==0)
            
            ICD_sense_state.AType=1;
        else
            ICD_sense_state.AType=2;
        end
    else
        ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;

        
        
    end
    
    
    %PeakTracking
elseif(ICD_sense_state.AState==2)
    ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;
    if(ICD_sense_state.ASense==1)
        ICD_sense_state.ASense=0;
    end
    if(signal<ICD_sense_state.AThres)
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.AAbsBlankPeriod;
        ICD_sense_state.AState=3;
        
        %update peak
        %ICD_sense_state.AAvg=ICD_sense_state.AAvg*(3/4)+signal*(1/4);
        ICD_sense_state.AAvg=ICD_sense_state.AAvg*(3/4)+ICD_sense_state.AThres*(1/4);
        ICD_sense_state.PrevA=ICD_sense_state.AThres;
        ICD_sense_state.AThresMin=max([ICD_sense_state.AAvg*(1/8);ICD_sense_param.AAGCNomThres]);
        ICD_sense_state.AThresMax=ICD_sense_state.AAvg*(3/2);
    else
        %while peak is going up
        ICD_sense_state.AThres=signal;
    end
    
    %AbsoluteBlanking
elseif(ICD_sense_state.AState==3)
    if(ICD_sense_state.AStateClock>=ICD_sense_state.AStateClockLim)
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.ANoiseWindow;
        %ICD_sense_state.VThres=ICD_sense_state.VThres*.75;
        ICD_sense_state.AState=4;
    else
        ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;
    end
    
    %Noise window
elseif(ICD_sense_state.AState==4)
    if(ICD_sense_state.AStateClock>=ICD_sense_state.AStateClockLim)
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AStateClockLim=ICD_sense_param.AFixedRefPeriod;
        ICD_sense_state.AState=5;
    else
        %TODO: something to repeat noise window is noise detected
        ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;
    end

    
    %Fixed Refractory
elseif(ICD_sense_state.AState==5)
    if(ICD_sense_state.AStateClock>=ICD_sense_state.AStateClockLim)
        ICD_sense_state.AThres=ICD_sense_state.AThres*.75;
        ICD_sense_state.AStateClock=0;
        if(ICD_sense_state.AType==1)
            ICD_sense_state.AStateClockLim=ICD_sense_param.ASAGCPeriod;
            ICD_sense_state.AAGCClockLim=ICD_sense_param.ASAGCPeriod;
        elseif(ICD_sense_state.AType==2)
            ICD_sense_state.AStateClockLim=ICD_sense_param.APAGCPeriod;
            ICD_sense_state.AAGCClockLim=ICD_sense_param.APAGCPeriod;
        end
        ICD_sense_state.AStateClockLim=ICD_sense_param.AFixedRefPeriod;
        ICD_sense_state.AState=1;
        ICD_sense_state.AAGCOn=1;
        ICD_sense_state.AAGCClock=0;
        
        %V_in=1;
    else
        %TODO: something to during fixed refractory
        ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;
    end


    %Smart cross-chamber blanking
elseif(ICD_sense_state.AState==6)
    if(ICD_sense_state.AStateClock>=ICD_sense_state.AStateClockLim)
        %restart AGC at 3/8 previous A Peak
        ICD_sense_state.AThres=ICD_sense_state.PrevA*(3/8);
        if(ICD_sense_state.AThres<=(ICD_sense_state.AThresMin))
            ICD_sense_state.AThres=ICD_sense_state.AThresMin;
        end
        
        if(ICD_sense_state.AType==1)
            ICD_sense_state.AStateClockLim=ICD_sense_param.ASAGCPeriod;
            ICD_sense_state.AAGCClockLim=ICD_sense_param.ASAGCPeriod;
        elseif(ICD_sense_state.AType==2)
            ICD_sense_state.AStateClockLim=ICD_sense_param.APAGCPeriod;
            ICD_sense_state.AAGCClockLim=ICD_sense_param.APAGCPeriod;
        end
        %Change state back to 1
        ICD_sense_state.AState=1;
        %restart AGC Clock
        ICD_sense_state.AAGCClock=0;
        ICD_sense_state.AStateClock=0;
        ICD_sense_state.AAGCOn=1;
        
    else
        ICD_sense_state.AStateClock=ICD_sense_state.AStateClock+1;
        A_blank=ICD_sense_state.AThres;
    end
end



%AGC
if(ICD_sense_state.AAGCOn==1)
    ICD_sense_state.AAGCClock=ICD_sense_state.AAGCClock+1;
    if(ICD_sense_state.AAGCClock>=ICD_sense_state.AAGCClockLim)
        %check if minimum threshold
        ICD_sense_state.AAGCClock=0;
        ICD_sense_state.AThres=ICD_sense_state.AThres*(7/8);
        if(ICD_sense_state.AThres<=(ICD_sense_state.AThresMin))
            ICD_sense_state.AThres=ICD_sense_state.AThresMin;
        end
        %if(ICD_sense_state.VThres<ICD_sense_param.VThresMin)
        %    ICD_sense_state.VThres=ICD_sense_param.VThresMin;
        %end
    end
    
end
end