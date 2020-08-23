function [Delta490, DeltaFlour] = DeltaF(Ch490,Ch405,Smoothing_Value,varargin)
% Smooth and process 490 channel and control channel data for fiber
% photometry. 

%Inputs:
% 1--Ch490-GCamp Channel
% 2--Ch405-isosbestic control channel
% 3--Start time- Set a specific sample to start at
% 4--End time-specify a specific ending sample


if length(varargin)==1
    Ch490=Ch490(1,varargin{1}:end)'; %GCaMP
    Ch405=Ch405(1,varargin{1}:end)'; %Isosbestic Control
elseif length(varargin)==2
    Ch490=Ch490(1,varargin{1}:varargin{2})'; %GCaMP
    Ch405=Ch405(1,varargin{1}:varargin{2})'; %Isosbestic Control
end

F490=smooth(Ch490,Smoothing_Value,'lowess'); 
F405=smooth(Ch405,Smoothing_Value,'lowess');

subplot (1,2,1);plot(Ch490);hold on;plot(Ch405);
subplot (1,2,2);plot(F490);hold on;plot(F405);
hold off
try
FastPrint('RawAndSmoothedChannels');
catch
    fprintf('could not print raw and smooth');
end 
bls=polyfit(F405(1:end),F490(1:end),1);
Y_Fit=bls(1).*F405+bls(2);
Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);

bls2=polyfit(Ch405(1:end),Ch490(1:end),1);
Y_Fit2=bls2(1).*Ch405+bls2(2);
DeltaFlour=(Ch490(:)-Y_Fit2(:));          %%% DJE EDIT %%%%

figure
plot(Delta490.*100)
ylabel('% \Delta F/F')
xlabel('Time (Seconds)')
title('\Delta F/F for Recording ')
try
FastPrint('WholeSessionTrace');
catch
    fprintf('Could not print whole session trace');
end 

end

