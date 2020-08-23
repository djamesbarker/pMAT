function [Delta490] = DeltaFevent(Ch490,Ch405,Ts,Event,name,varargin)
% Smooth and process 490 channel and control channel data for fiber
% photometry. 

%Inputs:
% 1--Ch490-GCamp Channel
% 2--Ch405-isosbestic control channel
% 3--Ts-Series of timestamps related to te Ch405 and 490 channels
% 4--Event-Two column data format with start and end times for events
% 5--name-Name of event for which tic marks are being added

%Varargin
% 1--Second Event to include as well
% 2--Start time- Set a specific sample to start at
% 3--End time-specify a specific ending sample

if length(varargin)==1
Event2=varargin{1};
end
if length(varargin)==3
    Ch490=Ch490(1,varargin{1}:end)'; %GCaMP
    Ch405=Ch405(1,varargin{1}:end)'; %Isosbestic Control
elseif length(varargin)==4
    Ch490=Ch490(1,varargin{1}:varargin{2})'; %GCaMP
    Ch405=Ch405(1,varargin{1}:varargin{2})'; %Isosbestic Control
end

F490=smooth(Ch490,0.002,'lowess'); 
F405=smooth(Ch405,0.002,'lowess');

%%Moving Average instead of Lowess.
% F490=smooth(Ch490,299,'moving'); 
% F405=smooth(Ch405,299,'moving');

% subplot (1,2,1);plot(Ch490);hold on;plot(Ch405);
% %subplot (1,3,2);plot(Z490);hold on;plot(Z405);
% subplot (1,2,2);plot(F490);hold on;plot(F405);
% hold off
% FastPrint('RawAndSmoothedChannels');

bls=polyfit(F405(1:end),F490(1:end),1);
%scatter(F405(10:end-10),F490(10:end-10))
Y_Fit=bls(1).*F405+bls(2);
%figure
Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);

%% % Delta F/F
figure
plot(Ts,Delta490.*100)
ylabel('% \Delta F/F')
xlabel('Time (Seconds)')
title('\Delta F/F for Recording ')
hold on


Peak=max(Delta490(Ts(:,1)>=Event(1,1)-10 & Ts(:,1)<=Event(end,2)+15));
for i=1:length(Event)
    x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
    y= [Peak*110 Peak*115 Peak*115 Peak*110];
    %y = [20 21 21 20];
    patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none')    
end

if length(varargin)==1
    for i=1:length(Event2)
        x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
        y= [Peak*105 Peak*110 Peak*110 Peak*105];
        patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none')
    end
end
    

xlim ([Event(1,1)-10 Event(end,2)+15])
FastPrint(['WholeSession_',name,'_Trace']);

%% Normalized Delta F/F
figure
plot(Ts,zscore(Delta490))
ylabel('Normalized \Delta F/F')
xlabel('Time (Seconds)')
title('Normalized \Delta F/F for Recording ')
hold on

Peak=max(zscore(Delta490(Ts(:,1)>=Event(1,1)-10 & Ts(:,1)<=Event(end,2)+15)));
for i=1:length(Event)
    x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
    y= [Peak*1.10 Peak*1.15 Peak*1.15 Peak*1.10];
    %y = [20 21 21 20];
    patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none')
end

if length(varargin)==1
    for i=1:length(Event2)
        x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
        y= [Peak*1.05 Peak*1.10 Peak*1.10 Peak*1.05];
        patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none')
    end
end
    

xlim ([Event(1,1)-10 Event(end,2)+15])
FastPrint(['WholeSession_',name,'_Trace-Zscore']);

%% Whole Patch Window
figure
Delta490=Delta490(Ts(:,1)>=Event(1,1)-10 & Ts(:,1)<=Event(end,2)+15);
Ts=Ts(Ts(:,1)>=Event(1,1)-10 & Ts(:,1)<=Event(end,2)+15);
plot(Ts,zscore(Delta490))
ylabel('Normalized \Delta F/F')
xlabel('Time (Seconds)')
title('Normalized \Delta F/F for Recording ')
hold on
yl=ylim;

Peak=max(zscore(Delta490(Ts(:,1)>=Event(1,1)-10 & Ts(:,1)<=Event(end,2)+15)));
for i=1:length(Event)
    x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
    y= [yl(1) yl(2) yl(2) yl(1)];
    %y = [20 21 21 20];
    patch(x,y,'black','FaceAlpha',0.25,'EdgeColor','none')
end

if length(varargin)==1
    for i=1:length(Event2)
        x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
        y= [yl(1) yl(2) yl(2) yl(1)];
        patch(x,y,'red','FaceAlpha',0.25,'EdgeColor','none')
    end
end
    

xlim ([Event(1,1)-10 Event(end,2)+15])
FastPrint(['WholeSession_',name,'_Trace-ZscorePatch']);



end

