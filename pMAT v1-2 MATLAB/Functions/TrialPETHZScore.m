function TrialPETHZScore( Fs, Ts, Pre, Post, EventTS,Ch490,Ch405,prefix, varargin)
%Original code by David J. Barker; Modified for use with PhotometryGUI by
%Carissa A. Bruno for the Barker Lab at Rutgers University.

%Trial Analysis: This code will take inputs and create Photometry
%Raster-PETH. The Raster PETH is a Heat map. The PETH is really a line
%curve (not a histogram). The FinalData output will posses a number of
%columns that analyse the data in different ways. Be weary of
%photobleaching and its effects on photometry data. We have adjusted for
%this by selecting a Y Fit function that changes per trial. 


%The following are Inputs:
% 1--FS-Sampling Frequency of Data
% 2--TS- Corresponding timestamp for GCAMP channel
% 3--Pre-Window to take before event
% 4--Post-Window to take after Event
% 5--EventTS--Event of interest
% 7--Ch490- Original GCAMP Data
% 8-Ch405-Originalo control channel (405 excitation) data
% VARIABLE INPUT OPTIONS FOR VARARGIN:
% 7--Title- Title for plot and savename for figure file.
% 8-- Bin constant (How many cells to median bin).
% 8--X Value for vertical Line 1 in PETH
% 9--X Value for vertical line 2 in PETH
%10--BaseLine Width Window. Default size is 5 seconds. 
%11--Baseline time start. Default time is -5s 

% The following are Outputs:
% 1--FinalData- Matrix of binned final data set. 


%% Set Up BaseLine Window Length
for i=1
    if length(varargin)<5
        if length(varargin)<6
            BL=5; %Baseline Widow start Default
        else
            BL=cell2mat(varargin(6));
        end 
        BaselineWind=round(BL*Fs); 
        BaselineWind2=5; %Defult Baseline Size 
    else
        if length(varargin)<6
            BL=5; %Baseline Widow Length Default
        else
            BL=cell2mat(varargin(6));
        end 
        BaselineWind=round(BL*Fs); 
        BL2=cell2mat(varargin(5));
        BaselineWind2=round(BL2*Fs); 
    end 
end 

%% %% %% %% %% %% %% 

 str=varargin(1); % String to name the PET
 
 % ADD DEFAULT BIN!~
 %% Create Window Size and eliminate events that overlap within a given window
            PreWind=round(Pre*Fs);
            PostWind=round(Post*Fs);
            
 % Eliminate events with overlapping windows.
 %NEED TO REMOVE -1 IF POSSIBLE!!!

    tmp=[];CurrEvent=EventTS(1);
    %REMOVE -1 HERE
    for i=1:length(EventTS)-1
        if EventTS(i+1)-CurrEvent>Pre+Post
            tmp(end+1,1)=CurrEvent;
            CurrEvent=EventTS(i+1);
        else
        end
    end

    tmp(end+1,1)=EventTS(length(EventTS),1);
    EventTS=tmp;

    %Find Time=0 for the event within the photometry data
    CSidx=[];
    %Ts=Ts'; %FIX FOR WRONG ARRAY ORIENTATION-REMOVED AND FIXED BELOW
    for i=1:length(EventTS)
        [MinVal, CSidx(i,1)]=min(abs(Ts(:,:)-EventTS(i)));
    end

%% Obtain the DeltaF/F for each event window
    CS405=[];CSTS=[];CS490=[] ;
    Ch490=Ch490';
    Ch405=Ch405';
    counter=1;
    for i=1:length(CSidx)
        %%NEED TO CHECK IF INDEX IS <0 or GREATER THAN LENGTH OF DELTA490, NOT
        %%IF THE VALUE IS LESS THAN 0 OR GREATER THAN THE MAX VALUE OF DELTA490
        if CSidx(i)-(BaselineWind+BaselineWind2)<=0 || CSidx(i)+PostWind > length(Ts)
        else
            %Obtain data within baseline and event window for 405
            %and 490 channels.
            CSTS=(-PreWind:PostWind)./Fs;
            CSBL(1,:)=Ch490((CSidx(i)-(BaselineWind+BaselineWind2)):(CSidx(i)-(BaselineWind))); 
            CSBL2(1,:)=Ch405((CSidx(i)-(BaselineWind+BaselineWind2)):(CSidx(i)-(BaselineWind)));
           
            if i>length(CSidx)
             break
            elseif i<=length(CSidx) 
            CS405(1,:)=Ch405((CSidx(i)-PreWind):(CSidx(i)+PostWind)); 
            CS490(1,:)=Ch490((CSidx(i)-PreWind):(CSidx(i)+PostWind)); 
            end

            %Smooth to eliminate high frequency noise.
            F490=smooth(CS490,0.002,'lowess');  %Was 0.002- DJB
            F405=smooth(CS405,0.002,'lowess');
            F490CSBL=smooth(CSBL,0.002,'lowess');  %Was 0.002- DJB
            F405CSBL=smooth(CSBL2,0.002,'lowess');


            %Scale and fit data
            bls=polyfit(F405(1:end),F490(1:end),1);
            blsbase=polyfit(F405CSBL(1:end),F490CSBL(1:end),1);
            Y_Fit=bls(1).*F405+bls(2);
            Y_Fit_base=blsbase(1).*F405CSBL+blsbase(2);

            %Center data and generate Delta F/F (DF_F) by dividing
            %event window by median of baseline window.
            DF_Event(:,i)=(F490(:,1)-Y_Fit(:,1));
            DF_F(:,i)=DF_Event(:,i)./(Y_Fit); %Delta F/F
            DF_F(:,i)=DF_F(:,i)-DF_F(1,i);
            
            DF_Event(:,i)=(F490(:,1)-Y_Fit(:,1));
            DF_Event(:,i)=DF_Event(:,i)-DF_Event(1,i); %zero first point
            DF_Base(:,i)=(F490CSBL(:,1)-Y_Fit_base(:,1));
            DF_Base(:,i)=DF_Base(:,i)-DF_Base(1,i); %zero to first point
            DF_ZScore(:,counter)=(DF_Event(:,i)-median(DF_Base(:,i)))./mad(DF_Base(:,i)); %Z-Score
            counter=counter+1;
           %%Plot Function to compare Robust Z-Score to DF/F            
%             figure; plot(DF_F(:,i)*100);
%             hold on; plot(DF_ZScore(:,i));
%             pause
%             close all
            %%% Clearing variables to reset for the next trial        
            clear CS405 CS490 F490 F405 bls Y_Fit

        end
    end

%% %%%%%%%%%%%%%%%PLOTTING & BINNING OF ALL DATA%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     Z-SCORE     %%%%%%%%%%%%%%%%%%%%%%%%%%%%
DF_ZScore=DF_ZScore';
if length(varargin)>=2
    bin=varargin{2};
tmp=[];tmp2=[];
    for i=1:bin:length(CSTS)
        if i+bin>length(CSTS)
        tmp(1,end+1)=median(CSTS(i:end));
        tmp2(:,end+1)=median(DF_ZScore(:,i:end),2);
        else
        tmp(1,end+1)=median(CSTS(i:i+bin));
        tmp2(:,end+1)=median(DF_ZScore(:,i:i+bin),2);
        end
    end
    CSTS2=tmp;
    DF_ZScore=tmp2;
else
end


figure;
h=subplot(2,1,1);
imagesc(CSTS2,[1:size(DF_ZScore,1)],(DF_ZScore)); 
% colorbar('SouthOutside');
ylabel('Trial #','fontsize', 18)
% set(h,'XTick',[])
if length(varargin)>=1
    title([varargin{1}],'Interpreter','none','fontsize', 18)
else
    title('Photometry PETH','fontsize', 18)
end
xlim([-Pre Post])
set(gca,'fontsize',18);
%colormap('jet')
CSTrace1=(mean(DF_ZScore,1));
CSmax=max(max(CSTrace1));
CSmin=min(min(CSTrace1));
if CSmax<0
    CSmax=0.1;
end


subplot(2,1,2), 
plot(CSTS2,CSTrace1,'LineWidth',3)
title('Z-Score PETH', 'Fontsize', 18);
xlim([-Pre Post])
xlabel('Time (s)', 'FontSize',18)
ylabel('Z-score','fontsize', 18);
ylim([CSmin CSmax*1.25]);
hold on
plot([0,0],[CSmin,CSmax*1.25],':r')

if length(varargin)==3
    X1=varargin{3};
    plot([X1 X1], [CSmin CSmax*1.25], '--r','LineWidth',2)
elseif length(varargin)==4
    X1=varargin{3};X2=varargin{4};
    plot([X1 X1], [CSmin CSmax*1.25], '--r','LineWidth',2)
    plot([X2 X2], [CSmin CSmax*1.25], '--r','LineWidth',2)
end
set(gca,'fontsize',18);

filenamebase="ZScorePETH";
FastPrintv2(prefix,filenamebase);

end
