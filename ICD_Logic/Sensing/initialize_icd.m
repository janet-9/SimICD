function [ICD_state, ICD_param] = initialize_icd(icdtype)

if strcmp(icdtype, 'bsc')
    BSC_state.g_clk=0;
    BSC_state.A_clk=0;
    BSC_state.V_clk=0;
    BSC_state.AS=0;
    BSC_state.AR=0;
    BSC_state.ABlk=0;
    BSC_state.VS=0;
    BSC_state.VT=0;
    BSC_state.VF=0;
    BSC_state.VBlk=0;
    BSC_state.V_win=Inf.*ones(10,1);
    BSC_state.A_win=Inf.*ones(10,1);
    BSC_state.VTC_win=ones(10,1);
    BSC_state.VFduration=0;
    BSC_state.VFdur_count=0;
    BSC_state.VTduration=0;
    BSC_state.VTdur_count=0;
    BSC_state.VTC_morph=[];
    
    BSC_param.PVAB=50;
    BSC_param.PAVB=40;
    BSC_param.PVARP=200;
    
    % old parameters
   
%     BSC_param.VF_th=350;%VF parameter change
%     BSC_param.VT_th=400;
%     BSC_param.zone_num=2;
%     BSC_param.Afib_th=200;
%     BSC_param.VT_dur=9000;%VT/VF Duration change
%     BSC_param.VF_dur=9000;%VT/VF Duration change
%     BSC_param.VTC_corr_th=0.94;
%     BSC_param.stab=20;
    BSC_param.VF_th=300;%VF parameter change
    BSC_param.VT_th=400;
    BSC_param.zone_num=2;
    BSC_param.Afib_th=353;
    BSC_param.VT_dur=1000;%VT/VF Duration change
    BSC_param.VF_dur=2500;%VT/VF Duration change
    BSC_param.VTC_corr_th=0.94;
    BSC_param.stab=20;
    
    ICD_state = BSC_state;
    ICD_param = BSC_param;
    
elseif strcmp(icdtype, 'med')
    Med_state.A_clk=0;
    Med_state.V_clk=0;
    Med_state.AS=0;
    Med_state.VS=0;
    Med_state.VT=0;
    Med_state.VF=0;
    Med_state.VBlk=0;
    Med_state.V_win=Inf.*ones(1,24);
    Med_state.A_win=Inf.*ones(1,12);
    Med_state.NOA_win=ones(1,5);
    Med_state.VTC_win=ones(1,10);
    Med_state.PRpattern='AAAAA';
    Med_state.PRwin=Inf.*ones(1,8);
    Med_state.PRassociate=ones(1,8);
    Med_state.FFRW_win=zeros(1,12);
    Med_state.FFRW=0;
    
    Med_state.STcount=0;
    Med_state.OtherSVT=0;
    Med_state.AFevidence=0;
    Med_state.RRreg=18;
    
    Med_state.SecondLastRR=[];
    Med_state.LastRR=[];
    
    Med_state.ConVT=0;
    Med_param.VF_length=10;
    Med_param.VF_thresh=320;%VF threshold
    Med_param.VT_thresh=400;
    Med_param.AFib_thresh=200;
    Med_param.SVTlim=320;%VF Threshold
    %paramaters and state for morphology
    Med_param.wave_match_thres=0.7;
    Med_param.morph_thres=3;
    Med_param.wave_win_len=128;
    Med_param.shock_buf_len=Med_param.wave_win_len*2;
    
    Med_state.wave_win_array=zeros(Med_param.wave_win_len,8);
    Med_state.shock_buf=[];
    Med_state.shock_buf_ind=1;
    Med_state.wave_win_count=1;
    
    % Med_param.wave_match_thres=0.7;
    % Med_param.morph_thres=3;
    % Med_param.wave_win_len=128;
    % Med_state.shock_buf=[];
    % Med_param.shock_buf_len=Med_param.wave_win_len*2;
    % Med_state.shock_buf_ind=1;
    % Med_state.wave_win_array=zeros(Med_param.wave_win_len,8);
    % Med_state.wave_win_count=1;   
    
    ICD_state = Med_state;
    ICD_param = Med_param;
else
    error('Unsupported ICD type %s\n', icdtype)
end






