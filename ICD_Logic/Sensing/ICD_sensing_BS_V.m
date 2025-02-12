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
function [signal, V_in, ICD_sense_state, ICD_sense_param]=ICD_sensing_BS_V(...
    ICD_sense_state, ICD_sense_param,...
    signal)

V_in=0;
signal=abs(signal); %TODO check why this is done!
ICD_sense_state.DebugClock=ICD_sense_state.DebugClock+1;
ICD_sense_param.DebugClock=ICD_sense_param.DebugClock+1;


%AGC
if(ICD_sense_state.VState==1)
    %records an event if the signal goes above threshold. 
    if(signal(1,:)>=ICD_sense_state.VThres)
        ICD_sense_state.VState=2;
        ICD_sense_state.VStateClock=0;
        ICD_sense_state.VStateClockLim=ICD_sense_param.VAbsBlankPeriod;
        ICD_sense_state.VAGCOn=0;
        if(ICD_sense_state.VPace==0)
            ICD_sense_state.VSense=1;
            V_in=-1;
            
        end

        %define the type of event detected. 

        if(ICD_sense_state.VPace==0)
            
            ICD_sense_state.VType=1;
        else
            ICD_sense_state.VType=2;
        end
    else
        ICD_sense_state.VStateClock=ICD_sense_state.VStateClock+1;

        
        
    end
    
   
    %PeakTracking
elseif(ICD_sense_state.VState==2)
    ICD_sense_state.VStateClock=ICD_sense_state.VStateClock+1;
%     if(ICD_sense_state.VSense==1)%TODO: Does this need to be here?
%         ICD_sense_state.VSense=0;
%     end
    if(signal<ICD_sense_state.VThres)
        ICD_sense_state.VStateClock=0;
        ICD_sense_state.VStateClockLim=ICD_sense_param.VAbsBlankPeriod;
        ICD_sense_state.VState=3;
        
        %update peak
        %ICD_sense_state.VAvg=ICD_sense_state.VAvg*(3/4)+signal*(1/4);
        ICD_sense_state.VAvg=ICD_sense_state.VAvg*(3/4)+ICD_sense_state.VThres*(1/4);
        ICD_sense_state.PrevV=ICD_sense_state.VThres;
        ICD_sense_state.VThresMin=max([ICD_sense_state.VAvg*(1/8); ICD_sense_param.VAGCNomThres]);
        ICD_sense_state.VThresMax=ICD_sense_state.VAvg*(3/2);
    else
        %while peak is going up
        ICD_sense_state.VThres=signal;
    end
    
    %AbsoluteBlanking
elseif(ICD_sense_state.VState==3)
    if(ICD_sense_state.VStateClock>=ICD_sense_state.VStateClockLim)
        ICD_sense_state.VStateClock=0;
        ICD_sense_state.VStateClockLim=ICD_sense_param.VNoiseWindow;
        %ICD_sense_state.VThres=ICD_sense_state.VThres*.75;
        ICD_sense_state.VState=4;
    else
        ICD_sense_state.VStateClock=ICD_sense_state.VStateClock+1;
    end
    


    %Noise window
elseif(ICD_sense_state.VState==4)
    if(ICD_sense_state.VStateClock>=ICD_sense_state.VStateClockLim)
        ICD_sense_state.VStateClock=0;
        ICD_sense_state.VStateClockLim=ICD_sense_param.VFixedRefPeriod;
        ICD_sense_state.VState=5;
    else
        %TODO: something to repeat noise window if noise detected
        ICD_sense_state.VStateClock=ICD_sense_state.VStateClock+1;
    end
    
    
    %Fixed Refractory
elseif(ICD_sense_state.VState==5)
    if(ICD_sense_state.VStateClock>=ICD_sense_state.VStateClockLim)
        ICD_sense_state.VThres=ICD_sense_state.VThres*.75;
        ICD_sense_state.VStateClock=0;
        if(ICD_sense_state.VType==1)
            ICD_sense_state.VStateClockLim=ICD_sense_param.VSAGCPeriod;
        elseif(ICD_sense_state.VType==2)
            ICD_sense_state.VStateClockLim=ICD_sense_param.VPAGCPeriod;
        end
        ICD_sense_state.VStateClockLim=ICD_sense_param.VFixedRefPeriod;
        ICD_sense_state.VState=1;
                ICD_sense_state.VAGCOn=1;
        ICD_sense_state.VAGCClock=0;
        
        %V_in=1;
    else
        %TODO: something to during fixed refractory
        ICD_sense_state.VStateClock=ICD_sense_state.VStateClock+1;
    end
end


%AGC
if(ICD_sense_state.VAGCOn==1)
    ICD_sense_state.VAGCClock=ICD_sense_state.VAGCClock+1;
    if(ICD_sense_state.VAGCClock>=ICD_sense_state.VAGCClockLim)
        %check if minimum threshold
        ICD_sense_state.VAGCClock=0;
        ICD_sense_state.VThres=ICD_sense_state.VThres*(7/8);
        if(ICD_sense_state.VThres<=(ICD_sense_state.VThresMin))
            ICD_sense_state.VThres=ICD_sense_state.VThresMin;
        end
        %if(ICD_sense_state.VThres<ICD_sense_param.VThresMin)
        %    ICD_sense_state.VThres=ICD_sense_param.VThresMin;
        %end
    end
    
end
end