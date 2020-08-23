%% CLEAR EVERYTHING
restoredefaultpath %Remove all extra paths
clear all; close all; clc; %Clear All
addpath('F:\MORALES_LAB\LH_VTA_PROJECT\MATLAB_SCRIPTS_AND_FUNCTIONS\FUNCTIONS') % Path with local functions
addpath('F:\BARKER_LAB\PHOTOMETRY_FUNCTIONS') % Path with local functions

%% GET PHOTOMETRY DATA
GroupFold=uigetdir;
cd(GroupFold);
Subjects=dir(GroupFold);
GroupMaster=[];GroupTrialPeak=[]; % Do we need?
Master=struct;
s=3;
cd(GroupFold)
cd(Subjects(s).name);
SubjectID=strtok(Subjects(s).name,'-');
BlockDir=dir('*nov*');
BlockDir=BlockDir.name;
cd(BlockDir);
[Tank,Block,~]=fileparts(cd);
Block_Directory=strcat(Tank, '\', Block);
data=TDTbin2mat(Block_Directory);
Ch490=data.streams.x490R.data; %GCaMP
Ch405=data.streams.x405R.data; %Isosbestic Control
Ts = ((1:numel(data.streams.x490R.data(1,:))) / data.streams.x490R.fs)'; % Get Ts for samples based on Fs
StartTime=5000; %Set the starting sample(recommend eliminating a few seconds for sensor rise time).
EndTime=length(Ch490)-1000; %Set the ending sample (again, eliminate some).
Fs=data.streams.x490R.fs; %Variable for Fs
Ts=Ts(StartTime:EndTime); % eliminate timestamps before starting sample and after ending.
Ch490=Ch490(StartTime:EndTime);
Ch405=Ch405(StartTime:EndTime);

%% FUNCTIONS UNDER REVIEW
[Delta490, DeltaFlour]=DeltaF(Ch490,Ch405, 0.002);
[DF_norm, DF_MAD] =FP_DEBLEACHED(DeltaFlour,15, 100);
[Post_spike_values,Pre_spike_values,SpikeperMin,TotalSpikes] = FP_SPIKECOUNT...
    (DF_MAD,2.5,1,1);
 





