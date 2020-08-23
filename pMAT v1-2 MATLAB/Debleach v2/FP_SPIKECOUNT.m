function [Post_Spikes,Prelim_Spikes,SpikeperMin,TotalSpikes] = FP_SPIKECOUNT(DF_DEBLEACHED,Threshold, Hold_Constant, ZERO_RULE)
%% By David Estrin & David Barker for the Barker Laboratory
% Code is written for ____ et al., 2020
% The purpose of this code is to take debleached calcium signal previously
% calculated in FP_DEBBLEACHED.m function and determine what is and is not
% a calcium transient ("spike"). 

%% The following are Inputs:
% 1--DF_DEBLEACHED- A debleached/detrended calcium trace
% 2--Threshold- Enter manual threshold value (typically set to 2.5 standard
%    devisions)
% 3--Hold_Constant- The miminum amount of time between two calcium
%    transients to be considered seperate events (in seconds). If set to 0,
%    this feature will be skipped.
% 4--ZERO_RULE- Enter 0 (no, do not use) or 1 (Yes, use zero rule) to use
%    the zero rule. The zero rule means that a calcium transient must go back
%    to 0 before a new calcium transient can be counted.

%% The following are Outputs:
% 1-- Post_Spikes- matrix of onsets and offsets for calcium transients that
%     were determined as true spikes after appplying the hold constant
% 2-- Prelim_Spikes- matrix of onsets and offsets for calcium transients 
% 3-- SpikeperMin- simple calculation for average rate (spikes/min) from 
%     the input trace
% 4-- TotalSpikes- simple calculation counting the total spikes for the
%     trace

%% Example use of this function:
%  [Fiber_Photometry_Trace]=DeltaF(Ch490,Ch405); %Get Trace 
%
%  [Fiber_Photometry_Trace_Debleached_1, Fiber_Photometry_Trace_Debleached_2] = ...
%       FP_DEBLEACHED(Fiber_Photometry_Trace, 15, 100); %Debleach Trace
%   
%  [Spikes,SpikeperMin,TotalSpikes] = ...
%       FP_SPIKECOUNT(Fiber_Photometry_Trace_Debleached_2,3, 1, 1); %Get
%       spikes
%


%% (#1) Set up variables
clearvars -except DF_DEBLEACHED Threshold  Hold_Constant ZERO_RULE
DF=DF_DEBLEACHED; % Debleached trace we just loaded in
DF(:,2)=(DF(:,1)>Threshold); %Apply threshold to debleached trace
Spikes(:,1)=find(DF(:,2)==1); %Preliminary variable for spikes
DF_ZERO=find(floor(DF)==0); %Find where debleached trace equals zero

%% (#2) Apply the "Zero Rule" or not
if ZERO_RULE ==1
    %% (#2-1) Find Spike onsets
    counter=2;
    Spike_series_onsets(1,1)=Spikes(1,1);
    for loop=1:length(Spikes)
        if (Spikes(loop+1,1)-Spikes(loop,1))~=1
        Spike_series_onsets(counter,1)=Spikes(loop+1,1);
        counter=counter+1;
        end 
        if (loop+1)==length(Spikes)
            break
        end 
    end 
    %% (#2-2) Find the offsets for spikes via Zero Rule
    for loop=1:length(Spike_series_onsets)
        Closest_end=(DF_ZERO-Spike_series_onsets(loop));
        Spike_series_offsets(loop,1)=Spike_series_onsets(loop)+min(Closest_end(Closest_end>0));
    end 
    %% (#2-3) Determine final list of spikes
    Zero_rule_spikes=zeros(length(Spike_series_offsets),3);
    Zero_rule_spikes(1,3)=1;
    for loop=1:length(Spike_series_offsets)
        if Spike_series_offsets(loop+1,1)~=Spike_series_offsets(loop,1)
            Zero_rule_spikes(loop+1,3)=1;
        end 
        if (loop+1)==length(Spike_series_offsets)
            break
        end 
    end 
    Zero_rule_spikes(:,1)=Spike_series_onsets(:,1);
    Zero_rule_spikes(:,2)=Spike_series_offsets(:,1);
    Zero_rule_spikes((Zero_rule_spikes(:,3)==0),:)=[];
    Zero_rule_spikes(:,3)=[];
    
    %% (2-4) Plot results of spikes.
    DF_DEBLEACHED_ZERO=zeros(length(DF_DEBLEACHED),2);
    DF_DEBLEACHED_ZERO(:,1)=DF_DEBLEACHED(:,1);
    for loop=1:length(Zero_rule_spikes)
        DF_DEBLEACHED_ZERO(Zero_rule_spikes(loop,1):Zero_rule_spikes(loop,2),2)=1;
    end
    DF=DF_DEBLEACHED_ZERO;
    DF_DEBLEACHED_ZERO(:,2)= DF_DEBLEACHED_ZERO(:,2)-5;
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'color','w');
    plot(DF_DEBLEACHED_ZERO(:,1)', 'LineWidth',2)
    hold on
    plot(DF_DEBLEACHED_ZERO(:,2)', 'LineWidth',2)
    plot([0 length(DF_DEBLEACHED_ZERO)],[Threshold Threshold],'--k','LineWidth',2)
    xlim([0 length(DF_DEBLEACHED_ZERO)])
    set(gca,'box','off');
    xlabel('TIME');
    ylabel('Normalized dF/F');
    set(findall(gcf,'-property','FontSize'),'FontSize',18)
    FastPrint('SPIKES_FOR_DEBLEACHED_DF_ZERO_RULE.fig');
    close all
    Spikes=Zero_rule_spikes;
    Prelim_Spikes=Spikes;
else
    %% (2-5) Find Spike onsets and offsets
        counter=2;
        counter2=1;
        Spike_series_onsets(1,1)=Spikes(1,1);
        Spike_series_offsets=[];
        for loop=1:length(Spikes)
            if (Spikes(loop+1,1)-Spikes(loop,1))~=1
            Spike_series_onsets(counter,1)=Spikes(loop+1,1);
            Spike_series_offsets(counter2,1)=Spikes(loop,1);
            counter=counter+1; counter2=counter2+1;
            end 
            if (loop+1)==length(Spikes)
                break
            end 
        end 
        
        if length(Spike_series_onsets)> length(Spike_series_offsets)
        Spike_series_onsets(end,1)=NaN;
        Spike_series_onsets(isnan(Spike_series_onsets)==1)=[];
        end 
        Spikes=[];
        Spikes=Spike_series_onsets;
        Spikes(:,2)=Spike_series_offsets;
        Prelim_Spikes=Spikes;
    %% (2-6) Plot results of spikes
    DF_DEBLEACHED_ZERO=zeros(length(DF_DEBLEACHED),2);
    DF_DEBLEACHED_ZERO(:,1)=DF_DEBLEACHED(:,1); 
    for loop=1:length(Spikes)
        DF_DEBLEACHED_ZERO(Spikes(loop,1):Spikes(loop,2),2)=1;
    end
    DF=DF_DEBLEACHED_ZERO;
    DF_DEBLEACHED_ZERO(:,2)= DF_DEBLEACHED_ZERO(:,2)-5;
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'color','w');
    plot(DF_DEBLEACHED_ZERO(:,1)', 'LineWidth',2)
    hold on
    plot(DF_DEBLEACHED_ZERO(:,2)', 'LineWidth',2)
    plot([0 length(DF_DEBLEACHED_ZERO)],[Threshold Threshold],'--k','LineWidth',2)
    xlim([0 length(DF_DEBLEACHED_ZERO)])
    set(gca,'box','off');
    xlabel('TIME');
    ylabel('Normalized dF/F');
    set(findall(gcf,'-property','FontSize'),'FontSize',18)
    FastPrint('SPIKES_FOR_DEBLEACHED_DF_ZERO_RULE.fig');
    close all

end 

%% (#3) APPLY HOLD CONSTANT TO DF
    HOLD_CONSTANT=Hold_Constant*1000;
    counter=1;
    %% (#3-1) Find spikes that are less than hold_constant seperated a part
    for loop=1:length(Spikes(:,1))
        Spikes_hold(counter,1)=((Spikes(loop+1,1)-Spikes(loop,2))<HOLD_CONSTANT);
        if loop==(length(Spikes)-1)
            break
        end 
    end
    Spike_conv=[1 0];
    Spike_conv2=[0 1];
    Index  = strfind(Spikes_hold', Spike_conv);
    Index2  = strfind(Spikes_hold', Spike_conv2);
 if isempty(Index)==0    
     
    %% (#3-1) Generate a new spikes matrix with changed onsets and offsets 
    Index=Index';
    Index2=Index2';
    Index2=Index2+1;
    Indexies=sort([Index;Index2]);
    Indexies(:,2)=Indexies(:,1)+1;
    for loop=1:length(Indexies)
        if Indexies(loop+1,1)==(Indexies(loop)+1)
           Indexies(loop,2)=Indexies(loop+1,2);
           Indexies(loop+1,1)=NaN;
        end 
        if (loop+1)==length(Indexies)
            break
        end 
    end 
    Indexies(isnan(Indexies(:,1)),:)=[];
    in_question=[];
    for loop=1:length(Indexies)
        in_question=[in_question;(Indexies(loop,1):Indexies(loop,2))'];
    end 
    Spikes_reform=Spikes;
    for loop=1:length(Indexies)
        Spikes_to_add(loop,1)=Spikes(Indexies(loop,1));
        Spikes_to_add(loop,2)=Spikes(Indexies(loop,2));
    
    end 
    Spikes_reform(in_question,:)=[];
    Spikes_reform=[Spikes_reform;Spikes_to_add];
    Spike_hold=Spikes_reform; 
    
%% (#4) Plot spike results with hold constant
    DF_DEBLEACHED_ZERO=zeros(length(DF_DEBLEACHED),2);
    DF_DEBLEACHED_ZERO(:,1)=DF_DEBLEACHED(:,1); 
    for loop=1:length(Spike_hold)
        DF_DEBLEACHED_ZERO(Spike_hold(loop,1):Spike_hold(loop,2),2)=1;
    end
    DF=DF_DEBLEACHED_ZERO;
    DF_DEBLEACHED_ZERO(:,2)= DF_DEBLEACHED_ZERO(:,2)-5;

    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'color','w');
    plot(DF_DEBLEACHED_ZERO(:,1)', 'LineWidth',2)
    hold on
    plot(DF_DEBLEACHED_ZERO(:,2)', 'LineWidth',2)
    plot([0 length(DF_DEBLEACHED_ZERO)],[Threshold Threshold],'--k','LineWidth',2)
    xlim([0 length(DF_DEBLEACHED_ZERO)])
    set(gca,'box','off');
    xlabel('TIME');
    ylabel('Normalized dF/F');
    set(findall(gcf,'-property','FontSize'),'FontSize',18)
    FastPrint('SPIKES_FOR_DEBLEACHED_DF_HOLD_RULE.fig');
    close all
    Post_Spikes=Spike_hold;
 else
 %% (#5) If Hold_Constant did not change spike generation
     Post_Spikes=Spikes;
     fprintf('The Hold_Constant was not applied for spike generation \n');
     fprintf('Change Hold_Variable size if not satisfied with results \n');
 end 
     
%% (#5) Basic statistics on spike data
TotalSpikes=size(Prelim_Spikes,1); %Total Number of Spikes
SpikeperMin=TotalSpikes/(length(DF)/60000); %Spikes per minute   
end

