function [DF_norm, DF_MAD] = FP_DEBLEACHED(DeltaFlour,Window, ITERATIONS)
%% By David Estrin & David Barker for the Barker Laboratory
% Code is written for ____ et al., 2020
% The purpose of this code is to take a calcium trace from fiber
% photometry and detrend/debleach the trace.

%% The following are Inputs:
% 1--DeltaFlour- Experimental Channel
% 2--Threshold-Enter Manual Threshold Value. This will change depending on if you are
% using normal Z Score or the Robust Z Score (DF_MAD). 
% 3--Window- Change the amount of time to bin and debleach. 
% 4--ITERATIONS- Number of times this code will calculate a debleached
% calcium signal. These interations will be averaged at the end. 

%% The following are Outputs:
% 1--DF_norm- The de-bleached Z score normal line 
% 2--DF_MAD- The de-bleached robuse Z score line

%% Example use of this function:
%
%  [Fiber_Photometry_Trace]=DeltaF(Ch490,Ch405); Get trace
%
%  [Fiber_Photometry_Trace_Debleached_1, Fiber_Photometry_Trace_Debleached_2] = ...
%       FP_DEBLEACHED(Fiber_Photometry_Trace, 15, 100); Get debleached
%       trace
%


DF=DeltaFlour;
Parse=Window*1000; % 15000 Miliseconds (15 Seconds) is what we are dividing data into. 
cuts=round(Parse/ITERATIONS); 

for l=1:Parse:length(DF) % Loop through Percentiles
        if l+Parse>length(DF) %Based on the parsing, cut off some of the data at end of recording, typicall few points 
            MEAN=mean(DF(l:end)); % Find mean of moving window
            DF_Transpose(l:length(DF),1)=(DF(l:length(DF),1)-MEAN); %This will be the rescalled version of DF
            
            MEDIAN=median(DF(l:end)); %% Median Absolute Deviation
            DF_MAD(l:length(DF),1)=((DF(l:length(DF),1)-MEDIAN)); %% Median Absolute Deviation  
            
            break
        end  
       MEAN=mean(DF(l:(l+Parse))); % Find mean of moving window
       DF_Transpose(l:(l+Parse),1)=(DF(l:(l+Parse),1)-MEAN); %This will be the rescalled version of DF
       MEDIAN=median(DF(l:(l+Parse))); %% Median Absolute Deviation
       DF_MAD(l:(l+Parse),1)=((DF(l:(l+Parse),1)-MEDIAN)); %% Median Absolute Deviation  
end 
MAD_MATRIX(:,1)=DF_MAD;
clear DF_MAD;

tic
matrix=zeros(length(DF), ITERATIONS);
parfor k=1:(ITERATIONS-1)
    DF_MAD=zeros(length(DF),1); 
    for l=(k*cuts):Parse:length(DF) % Loop through Percentiles
            if l+Parse>length(DF) %Based on the parsing, cut off some of the data at end of recording, typicall few points 
                MEDIAN=median(DF(l:end)); %% Median Absolute Deviation
                DF_MAD(l:length(DF),1)=((DF(l:length(DF))-MEDIAN)); %% Median Absolute Deviation  
                break
            end  
            if l==(k*cuts)
            MEDIAN=median(DF(1:l)); %% Median Absolute Deviation
            DF_MAD(1:l,1)=((DF(1:l,1)-MEDIAN)); %% Median Absolute Deviation  
            end
           MEDIAN=median(DF(l:(l+Parse))); %% Median Absolute Deviation
           DF_MAD(l:(l+Parse),1)=((DF(l:(l+Parse),1)-MEDIAN)); %% Median Absolute Deviation    
    end 
    matrix(:,k)=DF_MAD;    
end 
VeryMad=median(matrix');
toc
clear matrix DF_MAD matrix2 DF_Z DF_Slope matrix3;
VeryMad=VeryMad';
VeryMad=VeryMad./mad(VeryMad); %De-bleached Robust Normalized Delta F
DF_MAD=VeryMad;
DF_norm=DF_Transpose./std(DF_Transpose); %De-bleached Normalized Delta F.
end

