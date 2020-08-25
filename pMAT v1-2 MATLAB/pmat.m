%% Based on code created by David J. Barker for Morales Laboratory
% Beta Release 7-6-2018; Contact djamesbarker@gmail.com
% Modified by Carissa A. Bruno for the Barker Lab at Rutgers University
% 09-06-2019.
%Updated By David J. Barker on 08-19-20 for bug fixes, to include external
%import of CSV files, and to finalize before initial release.

function varargout = pmat(varargin)
% PMAT MATLAB code for pmat.fig
%      PMAT, by itself, creates a new PMAT or raises the existing
%      singleton*.
%
%      H = PMAT returns the handle to a new PMAT or the handle to
%      the existing singleton*.
%
%      PMAT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PMAT.M with the given input arguments.
%
%      PMAT('Property','Value',...) creates a new PMAT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pmat_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pmat_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pmat

% Last Modified by GUIDE v2.5 20-Aug-2020 22:48:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pmat_OpeningFcn, ...
                   'gui_OutputFcn',  @pmat_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%FEATURES TO ADD:
%%Ability for user to upload a spreadsheet with their data instead of a TDT Block.
%%Stretch PETH option.

% --- Executes just before pmat is made visible.
function pmat_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for pmat:
handles.output = hObject;
%Variables in the “handles” structure will get passed along between the different sections of the GUI.
%Create arrays of related components to easily enable or disable GUI
%buttons in groups:
handles.PETHPanel = [handles.DeltaFCheck, handles.ZScoreCheck, handles.AUCDataCheck, ...
    handles.AUCGraphCheck, handles.PETHContinueButton, handles.BinInput,handles.BinText handles.BL_StartInput, ...
    handles.BL_WidthInput, handles.BLWidthText,handles.BLStartText, handles.PreInput, ...
    handles.PostInput, handles.ZScoreCheck, handles.DeltaFCheck, handles.PreText, ...
    handles.PostText, handles.PETHEventList, handles.BLStartText, handles.BLWidthText, ...
    handles.AUCTable, handles.AUCGo, handles.AUCGraphToggle,handles.PETHNameInput, ...
    handles.TrialTraceCheck,handles.TraceDataCheck];
handles.DataExportPanel = [handles.Ca2DataCheck,handles.SelectedEventDataCheck,handles.EventDataCheck, ...
    handles.ExportEventList,handles.OutputDataButton,handles.ExpSelectToggle,handles.TickTipText,handles.TickTipText2];
handles.EventTickOptionsPanel = [handles.Ev1Check, handles.Ev2Check,...
    handles.PlotEv1PopUp,handles.PlotEv2PopUp,handles.PlotEv1NameInput,handles.PlotEv2NameInput];
handles.TraceEventNamePanel =[handles.PlotEv1NameInput, handles.PlotEv2NameInput, handles.EvExText];
handles.PlotPanel = [handles.PlotGCaMPCheck, handles.PlotControlCheck, ...
    handles.PlotGCaMPCtrlCheck,handles.PlotGCaMPFitCtrlCheck, handles.PlotDeltaFCheck,...
    handles.PlotDeltaFZScoreCheck, handles.PlotSaveButton, handles.PlotSelectToggle];
handles.NamePrefixPanel = [handles.EditPrefix, handles.FileExample];
%Create an array with the names of all the checkboxes throughout the GUI.
%This is used to search and save the status of each checkbox when
%resetting,saving, or uploading custom settings to search for the values of
%the variable matching each string in this array. 
%Note that if any checkboxes are added at a later date, the settings function will not work
%properly if their tags are not added here.
handles.Checkboxes=["DeltaFCheck","ZScoreCheck","AUCDataCheck", ...
    "AUCGraphCheck","Ca2DataCheck","SelectedEventDataCheck","EventDataCheck", ...
    "Ev1Check","Ev2Check", "PlotGCaMPCheck","PlotControlCheck", ...
    "PlotGCaMPCtrlCheck","PlotGCaMPFitCtrlCheck","PlotDeltaFCheck",...
    "PlotDeltaFZScoreCheck","Ev1Check","Ev2Check","TraceDataCheck","TrialTraceCheck"];
handles.LastFold='C:\';
%Most parts of the GUI are disabled before data is uploaded.
set(handles.PETHPanel,'Enable','off');
set(handles.PETHContinueButton,'Enable','off');
set(handles.DataExportPanel, 'Enable','off');
set(handles.PlotPanel, 'Enable', 'off');
set(handles.EventTickOptionsPanel,'Enable','off');
set(handles.NamePrefixPanel, 'Enable','off');
set(handles.TraceEventNamePanel,'Enable','off');


%Set the default values:
set(handles.FilePath, 'String', '');
set(handles.EditPrefix,'String','');
set(handles.PreInput,'String',"-5");
set(handles.PostInput,'String',"10");
set(handles.EditPrefix,'String','');
set(handles.PlotEv1NameInput,'String','Ev1');
set(handles.PlotEv2NameInput,'String','Ev2');
set(handles.FileExample,'string','ex. Prefix_ControlPlot.jpg');
set(handles.PETHNameInput,'String','ex. Shock, Tone, etc.');

%Tooltips are text displayed when a user mouses over that component of the
%GUI.
set(handles.BLStartText,'TooltipString','Sample Start Time: Time before raster to start taking the baseline.')
set(handles.BL_StartInput,'TooltipString','Sample Start Time: Time before raster to start the baseline.')
set(handles.BLWidthText,'TooltipString','Window Duration: Duration of the baseline.')
set(handles.BL_WidthInput,'TooltipString','Window Duration: Duration of the baseline.')

%handles.startstop stores the default values for the AUC table.
handles.startstop={-5.0,-2.5,[],[];0.0,2.5,[],[];5.0,7.5,[],[];[],[],[],[];[],[],[],[];[],[],[],[]};
set(handles.AUCTable,'Data',handles.startstop);

set(handles.RunAllButton,'BackgroundColor',[0.902 0.902 0.902]);
%Update handles structure:
handles.MyGUI=gcf;
guidata(hObject, handles);

%UIWAIT makes pmat wait for user response (see UIRESUME)
%uiwait(handles.pmat);

% --- Outputs from this function are returned to the command line.
function varargout = pmat_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

%% Uploading Data
%Data can be uploaded as either a single data set (see DataUploadButton_Callback) 
%or a data batch folder (see BatchLoadButton_Callback).
%For a single data set, select the TDT data block file saved within the
%outer tank file. For batch processing, select a folder that contains
%multiple tank files that contains an individual data block file
%containing the word "Photometry" in the file name.

% --- Executes on button press in DataUploadButton.
function DataUploadButton_Callback(hObject, eventdata, handles)
handles.data=[];handles.Ch490=[];handles.Ch405=[];
handles.Fs=[];handles.Ts=[];handles.fields=[];
handles.Beh=[];handles.epoclist=[];handles.fields=[];

if isfield(handles,'LastFold')==0 || ~isfield(handles,'TDTFold');
    handles.TDTFold=uigetdir ('C:\','Open TDT Block Folder');
elseif isfield(handles,'CSVFold');
    handles.TDTFold=uigetdir (handles.CSVFold,'Open TDT Block Folder');
elseif handles.TDTFold==0;
    handles.TDTFold=uigetdir ('C:\','Open TDT Block Folder');
else
    handles.TDTFold=uigetdir (handles.LastFold,'Open TDT Block Folder');
end

handles.LastFold=handles.TDTFold;
%In order to interact with most of the GUI functions, you first need to
%load in data from a TDT data block file. These are saved within the data
%tank files.
if handles.TDTFold~=0
    %The value of handles.DataType determines whether data will be
    %processed as a batch of data files or a single folder of data.
    handles.DataType="Single";
    set(handles.RunAllButton,'BackgroundColor',[0.902 0.902 0.902]);
    cd(handles.TDTFold);
    [Tank,Block,~]=fileparts(cd);
    %Convert data into a Matlab structure format. Variables saved in the
    %"handles" structure will get passed between the various components of
    %the GUI code.
    FileCheck=dir('*.tev');
    if isempty(FileCheck)
    msgbox("No .tev files found. Please select the directory containing your recording data", 'Error','warn')
    else
    disp(['Processing Block: ', Tank,'\',Block]);
    set(gcf,'Pointer','watch');
    drawnow;
    handles.data=TDTbin2mat([Tank,'\',Block]);
    set(gcf,'Pointer','arrow')
    drawnow;  % Cursor won't change right away unless you do this.
    end
    %Immediately after selecting a data block, a dialogue box will prompt the user to set a buffer at the 
    %start and end of data streams. Data from before the start sample and after the end sample will
    %not be uploaded. By default, 2000 samples from the start and end of the stream will
    %be excluded.
    prompt={'Add time buffer at start and end of streams for LED rise/fall. Number of samples to eliminate at start:', ...
        'Number of samples to eliminate at end:'};
    definput={'2000','2000'}; dlgtitle='Sample Buffer'; dims=[1 35];
    BufferInput=inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(BufferInput)
        BufferInput={'2000','2000'}; end
    StartBuffer=str2double(BufferInput{1});
    EndBuffer=str2double(BufferInput{2});
    
    %Our default gCaMP channel is x90R (490 nm) and control channel is x05R
    %(405 nm). If either of these data streams aren't present, the user will be
    %required to selected their gCaMP and/or control channels from a
    %listbox populated with the names of the variables found in
    %handles.data.streams
    handles.streamlist=fieldnames(handles.data.streams);
    if isfield(handles.data.streams,'x490R')
        handles.Fs=handles.data.streams.x490R.fs;
        %Determine the timestamps for each value in the channel stream
        %based on the sampling frequency.
        Ts=((1:numel(handles.data.streams.x490R.data(1,:))) /handles.Fs);
        %Extract data from samples between the specified start and end times:
        EndTime=length(handles.data.streams.x490R.data)-EndBuffer;
        handles.Ts=Ts(StartBuffer:EndTime);
        handles.Ch490=handles.data.streams.x490R.data(StartBuffer:EndTime);
    else
        %indx stores the location of the user's selection on the list
        %dialogue. If the user cancels or closes out of the dialogue
        %before making a selection, tf will equal zero and the user
        %will not be able to proceed.
        [indx,tf]=listdlg('PromptString','Select your signal channel:','SelectionMode','single', ...
            'ListString',handles.streamlist);
        if tf==0
            msgbox("You must select a signal channel to continue", 'Error','warn')
            return
        end
        %Code follows the same steps as above, using the index location of
        %the selected channel from handles.streamlist instead of "x90R".
        handles.Fs=handles.data.streams.(handles.streamlist{indx}).fs;
        Ts=((1:numel(handles.data.streams.(handles.streamlist{indx}).data(1,:))) ...
            /handles.Fs);
        EndTime=length(handles.data.streams.(handles.streamlist{indx}).data)-EndBuffer;
        handles.Ts=Ts(StartBuffer:EndTime);
        handles.Ch490=handles.data.streams.(handles.streamlist{indx}).data(StartBuffer:EndTime);
    end

    if isfield(handles.data.streams,'x405R')
        %This is repeated if a control stream is not found with the
        %expected name.
        Ch405=handles.data.streams.x405R.data;
        handles.Ch405=Ch405(StartBuffer:EndTime);
    else
        A=1:length(handles.streamlist);
        B=setdiff(A,indx);
        [indx,tf]=listdlg('PromptString','Select your control channel:','SelectionMode','single', ...
            'ListString',handles.streamlist(B));
        if tf==0
           msgbox("You must select a control channel to continue", 'Error','warn')
            return
        end
        indx=B(indx);
        handles.Ch405=handles.data.streams.(handles.streamlist{indx}).data(StartBuffer:EndTime);
    end

    %Epocs include the onset and offset times for the different event
    %types, which are typically assigned a unique value depending on how
    %data is collected. Determine the fieldnames for epocs in this data set:
    handles.fields = fieldnames(handles.data.epocs);
    %Create handles.MasterArray to be populated with event names, onset,
    %and offset data for each field in handles.data.epocs after each loop:
    handles.MasterArray=[];
    for i=1:numel(handles.fields)
            fieldlist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
            fieldlist(:)=handles.fields(i);
            increment=[];
            increment=diff(handles.data.epocs.(handles.fields{i}).data);
            if ~isempty (increment)& increment(:,1)==ones(length(increment),1)
                GroupData=questdlg([ 'The data in ' handles.fields{i} ' appear to belong to the same behavior. Would you like to group these data?'],...
                    'Group Data','Yes');
            else
                GroupData='No';
            end
            
            if strcmp(GroupData,'Yes')
            epoclist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
            epoclist(:)=handles.fields(i);
            handles.data.epocs.(handles.fields{i}).data=epoclist;
            %Using num2str with cellfun converts each element of the onset and offset arrays from
            %numbers into strings.
            onset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).onset),'un',0);
            offset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).offset),'un',0);
            %Create a new matrix for current epoc:
            BehData.(handles.fields{i})=[epoclist onset offset];
            %Add onto the end of handles.MasterArray:
            handles.MasterArray= [handles.MasterArray; BehData.(handles.fields{i})];
            elseif strcmp(GroupData,'No')
            epoclist=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).data), 'un',0);
            %Create unique designations for each event type by appending its
            %numerical designation to corresponding port/epoc name using strcat:
            strs=strcat(fieldlist,epoclist);
            handles.data.epocs.(handles.fields{i}).data=strs;
            %Create matrix for this epoc and add it onto the end of
            %handles.MasterArray at the end of each loop:
            onset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).onset),'un',0);
            offset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).offset),'un',0);
            BehData.(handles.fields{i})=[handles.data.epocs.(handles.fields{i}).data onset offset];
            handles.MasterArray=[handles.MasterArray; BehData.(handles.fields{i})];
            elseif strcmp(GroupData,'Cancel')
            msgbox("Importing of data has been cancelled", 'Error','warn')
            break
            end
    end
    
    %Populate listboxes and dropdown menus with these unique event identifiers:
    handles.BitListStr=cellstr(string(unique(handles.MasterArray(:,1))));
    set(handles.PETHEventList,'String',handles.BitListStr);
    set(handles.ExportEventList,'String',handles.BitListStr);
    set(handles.PlotEv1PopUp,'String',handles.BitListStr);
    set(handles.PlotEv2PopUp,'String',handles.BitListStr);
    %Display the file path at the top of the GUI:
    set(handles.FilePath,'String', handles.TDTFold);
    %Most GUI functions are enabled once data has been successfully
    %imported:
    set(handles.PETHPanel,'Enable','on');
    set(handles.PlotPanel,'Enable','on');
    set(handles.DataExportPanel,'Enable','on');
    set(handles.NamePrefixPanel,'Enable','on');
    set(handles.CopyFilePath,'Enable','on');
    set(handles.RunAllButton,'Enable','on');
    set(handles.CloseAll,'Enable','on');
    set(handles.AUCGraphCheck,'Enable','on');
    %Clear any text from the handles.EditPrefix user input box:
    handles.UserPrefix={};
    set(handles.EditPrefix,'String','');
    %Set default text in other text input and static text boxes:
    set(handles.PlotEv1NameInput,'String','Ev1');
    set(handles.PlotEv2NameInput,'String','Ev2');
    set(handles.FileExample,'string','ex. Prefix_ControlPlot.jpg');
    set(handles.PETHNameInput,'String','ex. Shock, Tone, etc.');
    handles.subjectID=[];
else
    msgbox("Please select a TDT data block folder to continue.", 'Error','warn')
end
guidata(hObject,handles);


% --- Executes on button press in BatchLoadButton.
function BatchLoadButton_Callback(hObject, eventdata, handles)
handles.data=[];handles.Ch490=[];handles.Ch405=[];
handles.Fs=[];handles.Ts=[];handles.fields=[];
handles.Beh=[];handles.epoclist=[];handles.fields=[];

handles.GroupFold=uigetdir ('C:\','Select folder containing TDT data tanks:');

if handles.GroupFold~=0
    handles.DataType="Batch"; 
    %The value of handles.DataType determines whether data will be
    %processed as a batch of data files or a single folder of data.
    cd(handles.GroupFold);
    %handles.Subjects=dir(handles.GroupFold);%Create a list of files in the folder
    handles.Subjects=dir('**/*.tev');%Create a list of files in the folder
    cd(handles.Subjects(1).folder); 
    [Tank,Block,~]=fileparts(cd); %List full directory for Tank and Block
    disp(['Processing Block: ', Tank,'\',Block]);
    handles.data=TDTbin2mat([Tank,'\',Block]); %Use TDT2Mat to extract data.
    
    prompt={'Add time buffer at start and end of streams for LED rise/fall. Number of samples to eliminate at start:', ...
        'Number of samples to eliminate at end:'};
    definput={'2000','2000'}; dlgtitle='Sample Buffer'; dims=[1 35];
    BufferInput=inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(BufferInput)
        BufferInput={'2000','2000'}; 
    end
    handles.StartBuffer=str2double(BufferInput{1});
    handles.EndBuffer=str2double(BufferInput{2});
    
    %Populate lisbox and popup menus with fields based on the epocs found
    %in the first data set:
    handles.fields = fieldnames(handles.data.epocs);
    SampleMaster=[]; 
    for i=1:numel(handles.fields)
        if handles.fields{i}=="Tick" || handles.fields{i}=="Vid1"
            epoclist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
            epoclist(:)=handles.fields(i);
            SampleMaster=[SampleMaster; epoclist];
        else
            fieldlist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
            fieldlist(:)=handles.fields(i);
            epoclist=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).data), 'un',0);
            strs=strcat(fieldlist,epoclist);
            SampleMaster=[SampleMaster; strs];
        end
    end
    
    %Populate listboxes and dropdown menus with these unique event identifiers:
    handles.BitListStr=cellstr(string(unique(SampleMaster)));
    set(handles.PETHEventList,'String',handles.BitListStr);
    set(handles.ExportEventList,'String',handles.BitListStr);
    set(handles.PlotEv1PopUp,'String',handles.BitListStr);
    set(handles.PlotEv2PopUp,'String',handles.BitListStr);
    %Display the file path at the top of the GUI:
    set(handles.FilePath,'String', handles.GroupFold);
    %Most GUI functions are enabled once data has been successfully
    %imported. However, when uploading a batch file, user must use the "Run
    %All" button instead of individual panel buttons.
    set(handles.PETHPanel,'Enable','on');
    set(handles.PETHContinueButton,'Enable','off');
    set(handles.AUCGo,'Enable','off');
    set(handles.PlotPanel,'Enable','on');
    set(handles.PlotSaveButton,'Enable','off');
    set(handles.DataExportPanel,'Enable','on');
    set(handles.OutputDataButton,'Enable','off');
    set(handles.NamePrefixPanel,'Enable','on');
    set(handles.CopyFilePath,'Enable','on');
    set(handles.RunAllButton,'Enable','on');
    %Clear any text from the handles.EditPrefix user input box:
    handles.UserPrefix={};
    set(handles.EditPrefix,'String','');
    %Set default text in other text input and static text boxes:
    set(handles.PlotEv1NameInput,'String','Ev1');
    set(handles.PlotEv2NameInput,'String','Ev2');
    set(handles.FileExample,'string','ex. Prefix_ControlPlot.jpg');
    set(handles.PETHNameInput,'String','ex. Shock, Tone, etc.');
    set(handles.RunAllButton,'BackgroundColor',[1 0.722 0.162]);
else
    msgbox("Please select a folder to continue.", 'Error','warn')
end
guidata(hObject,handles);


% --- Executes on button press in CopyFilePath.
function CopyFilePath_Callback(hObject, eventdata, handles)
% hObject    handle to CopyFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%User can copy the filepath for the folder currently uploaded.
%This can be pasted into the file explorer to see contents of the folder
%directly. This is where any figures or excel files generated by the GUI
%will be uploaded. For batch processing, files will be saved in the
%individual block folders for each trial.
text=(get(handles.FilePath,'String'));
clipboard('copy',text);
guidata(hObject,handles)


%% Options Panel

function EditPrefix_Callback(hObject, eventdata, handles)
% hObject    handle to EditPrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of EditPrefix as text
%        str2double(get(hObject,'String')) returns contents of EditPrefix as a double

%Users can specify a prefix, such as the subject name, to the filenames for .csv and .jpg
%files saved from the GUI. Note that without a prefix, filenames will
%begin with an underscore.
handles.EditPrefix.String=get(hObject,'String');
handles.UserPrefix=get(hObject,'String');

%The static text showing an example of how files will be saved will update
%when user clicks outside of the text edit box. This indicates the prefix
%has been updated.
if (~isempty(handles.EditPrefix.String))
    set(handles.FileExample,'string',strjoin(['ex. ' string(handles.UserPrefix), '_ControlPlot.jpg'],''));
else
    set(handles.FileExample,'string',"ex. _ControlPlot.jpg");
end

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function EditPrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditPrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in DefaultButton.
function DefaultButton_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.PreInput,'string',"-5");
set(handles.PostInput,'string',"10");
set(handles.BL_StartInput,'string',"-5");
set(handles.BL_WidthInput,'string',"5");
set(handles.BinInput,'string',"100");
set(handles.PlotEv1NameInput,'String','Ev1');
set(handles.PlotEv2NameInput,'String','Ev2');
set(handles.AUCTable,'Data', handles.startstop);
handles.UserPrefix=[];
set(handles.EditPrefix,'String','');
set(handles.FileExample,'String','ex. Prefix_ControlPlot.jpg');
set(handles.PETHNameInput,'String','ex. Shock, Tone, etc.');
set(handles.ExportEventList,'Value',1);
set(handles.PETHEventList,'Value',1);
set(handles.PlotEv1PopUp,'Value',1);
set(handles.PlotEv2PopUp,'Value',1);
set(handles.EventTickOptionsPanel,'Enable','off');

%Search for the fields that match the strings in the handles.Checkboxes
%array and change all their values to 0 (i.e. uncheck them).
for i=1:numel(handles.Checkboxes)
    set(handles.(handles.Checkboxes{i}),'value',0);end

guidata(hObject, handles);

% --- Executes on button press in UserSettingsSave.
function UserSettingsSave_Callback(hObject, eventdata, handles)
% hObject    handle to UserSettingsSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Create a new structure to save the current settings for each listed
%variable:
UserSettings=struct;
UserSettings.PreInput=get(handles.PreInput,'String');
UserSettings.PostInput=get(handles.PostInput,'String');
UserSettings.BL_StartInput=get(handles.BL_StartInput,'String');
UserSettings.BL_WidthInput=get(handles.BL_WidthInput,'String');
UserSettings.BinInput=get(handles.BinInput,'String');
UserSettings.startstop=handles.AUCTable.Data;
UserSettings.prefix=get(handles.EditPrefix,'String');
%Save pop up and listbox menu selections based on the index value of the selected
%item(s).
UserSettings.ExportEvent=get(handles.ExportEventList,'Value');
UserSettings.PETHEvent=get(handles.PETHEventList,'Value');
UserSettings.PlotEv1=get(handles.PlotEv1PopUp,'Value');
UserSettings.PlotEv2=get(handles.PlotEv2PopUp,'Value');
UserSettings.Ev1Name=get(handles.PlotEv1NameInput,'String');
UserSettings.Ev2Name=get(handles.PlotEv2NameInput,'String');
UserSettings.PETHName=get(handles.PETHNameInput,'String');
if isfield(handles,'LastFold')
UserSettings.LastFold=handles.LastFold;
end

UserSettings.CheckboxValues=[];
for i=1:numel(handles.Checkboxes)
    UserSettings.CheckboxValues(i)=get(handles.(handles.Checkboxes{i}),'value');
end

%Save this new structure as a .mat file in the location selected by the
%user:
[filename,pathname]=uiputfile('PhotometryUserSettings.mat','Save Workspace Variables As');
if pathname~=0
    newfilename=fullfile(pathname, filename);
    save(newfilename, 'UserSettings');
else
    msgbox('Settings not saved.','Error','warn');
end

if isdir('C:\pmat-BarkerLab')
    cd('C:\pmat-BarkerLab')
else
    cd('C:\')
    mkdir('pmat-BarkerLab')
    cd('C:\pmat-BarkerLab')
end

%Note that the start and stop buffer sample size setting can only be
%changed by the user upon first uploading data, and so will not be saved
%along with the other user settings.

guidata(hObject,handles)

% --- Executes on button press in SetUserSettings.
function SetUserSettings_Callback(hObject, eventdata, handles)
% hObject    handle to SetUserSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Select a previously saved user settings file. This will upload the
%UserSettings structure, and items in the handles structure will be updated
%to represent the saved values.
if isdir('C:\pmat-BarkerLab')
    cd('C:\pmat-BarkerLab');
end

[settingsname, settingspath]=uigetfile('*.mat');
if settingsname~=0
    load(fullfile(settingspath,settingsname));
    set(handles.PreInput,'String',UserSettings.PreInput);
    set(handles.PostInput,'String',UserSettings.PostInput);
    set(handles.BL_StartInput,'String',UserSettings.BL_StartInput);
    set(handles.BL_WidthInput,'String',UserSettings.BL_WidthInput);
    set(handles.AUCTable,'Data',UserSettings.startstop);
    set(handles.ExportEventList,'Value',UserSettings.ExportEvent);
    set(handles.PETHEventList,'Value',UserSettings.PETHEvent);
    set(handles.PlotEv1PopUp,'Value',UserSettings.PlotEv1);
    set(handles.PlotEv2PopUp,'Value',UserSettings.PlotEv2);
    set(handles.PlotEv1NameInput,'String',UserSettings.Ev1Name);
    set(handles.PlotEv2NameInput,'String',UserSettings.Ev2Name);
    set(handles.PETHNameInput,'String',UserSettings.PETHName);
    if isfield(UserSettings,'LastFold')
    handles.LastFold=UserSettings.LastFold;
    %set(handles.FilePath,'String',UserSettings.LastFold)
    end
    for i=1:numel(UserSettings.CheckboxValues)
        set(handles.(handles.Checkboxes{i}),'value', UserSettings.CheckboxValues(i));
    end
    handles.UserPrefix=[];
    set(handles.EditPrefix,'String','');
    set(handles.FileExample,'string','ex. Prefix_ControlPlot.jpg');
    handles.EditPrefix.String=UserSettings.prefix;
    set(handles.UserPrefix,'String',UserSettings.prefix);
else
    msgbox ...
        ('Please select a .mat file to load previously saved PhotometryGUI settings. To save your current settings, click the "Save Current Settings" button above.',...
        'Error','warn');
end
guidata(hObject,handles)


%% Export Data Panel
%User can select from a series of checkboxes (handles.Ca2DataCheck,
%handles.SelectedEventDataCheck, handles.EventDataCheck). 

% --- Executes on button press in Ca2DataCheck.
function Ca2DataCheck_Callback(hObject, eventdata, handles)
% hObject    handle to Ca2DataCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of Ca2DataCheck
guidata(hObject,handles);


% --- Executes on button press in SelectedEventDataCheck.
function SelectedEventDataCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function EventDataCheck_Callback(hObject, eventdata, handles)

guidata(hObject,handles);
    
% --- Executes on selection change in ExportEventList.
function ExportEventList_Callback(hObject, eventdata, handles)

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function ExportEventList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ExpSelectToggle.
function ExpSelectToggle_Callback(hObject, eventdata, handles)
%Select or deselect all options in the data export window. This will also
%select all of the individual events in the listbox.
if get(handles.ExpSelectToggle,'value')==1
    for i=1:numel(handles.ExportEventList.String)
        handles.ExportEventList.Value(i)=i;
    end
    set(handles.Ca2DataCheck,'value',1);
    set(handles.EventDataCheck,'value',1);
    set(handles.SelectedEventDataCheck,'value',1);
end

if get(handles.ExpSelectToggle,'value')==0
    handles.ExportEventList.Value=1;
    set(handles.Ca2DataCheck,'value',0);
    set(handles.EventDataCheck,'value',0);
    set(handles.SelectedEventDataCheck,'value',0);
end
guidata(hObject,handles)

% --- Executes on button press in OutputDataButton.
function OutputDataButton_Callback(hObject, eventdata, handles)
handles.MyGUI=gcf;
set(handles.MyGUI,'Pointer','watch')
drawnow;  % Cursor won't change right away unless you do this.

if get(handles.Ca2DataCheck,'value')==0 && get(handles.EventDataCheck,'value')==0 ...
    && get(handles.SelectedEventDataCheck,'value')==0
    msgbox('Please select at least one.', 'Error','warn');
end

if isempty(handles.subjectID)
    newprefix=handles.UserPrefix;
else
    newprefix=strjoin([string(handles.UserPrefix),'_',string(handles.subjectID)],'');
end

if get(handles.Ca2DataCheck,'value')== 1 %If "Ca2+ Data" is selected:
    if size(handles.Ts,1)<size(handles.Ts,2)
    tmp=[handles.Ts', handles.Ch490', handles.Ch405'];
    else
    tmp=[handles.Ts, handles.Ch490, handles.Ch405];
    end
    header=["TimeStamp","Signal","Control"];
    tmp2=cellstr([header;tmp]);
    T=table(tmp2);
    name='Ca2Data';
    ExcelPrint(string(newprefix), name, T);
end

if get(handles.EventDataCheck,'value')==1 %If "All Event Data" is selected:
    %This will exclude rows containing "Vid1" and "Tick" data, but these
    %can be saved as individual spreadsheets by selecting the Individual
    %Event Data and selected them in the listbox.
    tmp=[handles.MasterArray(handles.MasterArray(:,1)~="Vid1" & handles.MasterArray(:,1)~="Tick",:)];
    header={'Event','Onset','Offset'};
    tmp2=[header;tmp];
    T=table(tmp2);
    name='BehData';
    ExcelPrint(string(newprefix),name,T);
end

if get(handles.SelectedEventDataCheck,'value')== 1 %If "Individual Event Data" is selected:
    %The location of each selected item in the handles.ExportEventList
    %listbox will be saved in handles.ExportEventList.Value, which correspond to the event names
    %stored in handles.ExportEventList.String. Rows where the first column
    %is equal to those strings are filtered out of handles.MasterArray and
    %saved as a new spreadsheet.
    %This loop will repeat for each event that is selected using the command
    %numel(handles.ExportEventList.Value).
    for i=1:numel(handles.ExportEventList.Value)
        EventList1Str=string(handles.ExportEventList.String(handles.ExportEventList.Value(i)));
        tmp=[handles.MasterArray(handles.MasterArray(:,1)==EventList1Str,:)];
        header={'Event','Onset','Offset'};
        tmp2=[header;tmp];
        T=table(tmp2);
        SpecNameStr=strjoin([string(EventList1Str),'EventData'],'');
        ExcelPrint(string(newprefix), SpecNameStr, T);
    end
end
handles.subjectID=[];

f = msgbox('The files have been saved in the working directory under the data folder.','Save Successful!');
set(handles.MyGUI,'Pointer','arrow')
drawnow;  % Cursor won't change right away unless you do this.
guidata(hObject,handles);


%% Plot Trace Data Panel

% --- Executes on button press in PlotGCaMPCheck.
function PlotGCaMPCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);

% --- Executes on button press in PlotControlCheck.
function PlotControlCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in PlotGCaMPCtrlCheck.
function PlotGCaMPCtrlCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in PlotGCaMPFitCtrlCheck.
function PlotGCaMPFitCtrlCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in PlotDeltaFCheck.
function PlotDeltaFCheck_Callback(hObject, eventdata, handles)
if get(hObject,'value')==1 || get(handles.PlotDeltaFZScoreCheck,'value')==1
    set(handles.Ev1Check,'Enable','on');
    set(handles.Ev2Check,'Enable','on');
else
    set(handles.EventTickOptionsPanel,'Enable','off')
    set(handles.Ev1Check,'Value',0);
    set(handles.Ev2Check,'Value',0);
end
guidata(hObject,handles);


% --- Executes on button press in PlotSelectToggle.
function PlotSelectToggle_Callback(hObject, eventdata, handles)
if get(handles.PlotSelectToggle, 'value')==1
    set(handles.PlotGCaMPCheck,'value',1);
    set(handles.PlotControlCheck,'value',1);
    set(handles.PlotGCaMPCtrlCheck,'value',1);
    set(handles.PlotGCaMPFitCtrlCheck,'value',1);
    set(handles.PlotDeltaFCheck,'value',1);
    set(handles.PlotDeltaFZScoreCheck,'value',1);
    set(handles.Ev1Check,'Enable','on');
    set(handles.Ev2Check,'Enable','on'); 
else
    set(handles.PlotGCaMPCheck,'value',0);
    set(handles.PlotControlCheck,'value',0);
    set(handles.PlotGCaMPCtrlCheck,'value',0);
    set(handles.PlotGCaMPFitCtrlCheck,'value',0);
    set(handles.PlotDeltaFCheck,'value',0);
    set(handles.PlotDeltaFZScoreCheck,'value',0);
    set(handles.Ev1Check,'Enable','off');
    set(handles.Ev1Check,'value',0);
    set(handles.Ev2Check,'Enable','off');
    set(handles.Ev2Check,'value',0);
end
guidata(hObject,handles);
    

% --- Executes on button press in Ev1Check.
function Ev1Check_Callback(hObject, eventdata, handles)
if get(hObject,'value')==1
    set(handles.PlotEv1PopUp,'Enable','on');
    set(handles.PlotEv1NameInput,'Enable','on');
else
    set(handles.PlotEv1PopUp,'Enable','off');
    set(handles.PlotEv1NameInput,'Enable','off');
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function Ev1Check_CreateFcn(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in Ev2Check.
function Ev2Check_Callback(hObject, eventdata, handles)
if get(hObject,'value')==1
    set(handles.PlotEv2PopUp,'Enable','on');
    set(handles.PlotEv2NameInput,'Enable','on');
else
    set(handles.PlotEv2PopUp,'Enable','off');
    set(handles.PlotEv2NameInput,'Enable','off');
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function Ev2Check_CreateFcn(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on selection change in PlotEv1PopUp.
function PlotEv1PopUp_Callback(hObject, eventdata, handles)
if get(handles.Ev1Check,'value')==1
    set(handles.PlotEv1PopUp,'Enable','on');
else
    set(handles.PlotEv1PopUp,'Enable','off');
end
contents=cellstr(get(hObject,'String'));
handles.PlotEv1Selection=contents{get(hObject,'Value')};
guidata(hObject,handles); 


% --- Executes during object creation, after setting all properties.
function PlotEv1PopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
guidata(hObject,handles);


% --- Executes on selection change in PlotEv2PopUp.
function PlotEv2PopUp_Callback(hObject, eventdata, handles)
if get(handles.Ev2Check,'value')==1
    set(handles.PlotEv2PopUp,'Enable','on');
else
    set(handles.PlotEv2PopUp,'Enable','off');
end
contents=cellstr(get(hObject,'String'));
handles.PlotEv2Selection=contents{get(hObject,'Value')};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function PlotEv2PopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PlotEv1NameInput_Callback(hObject, eventdata, handles)
if get(handles.Ev1Check,'value')==1
    set(handles.PlotEv1NameInput,'Enable','on');
else
    set(handles.PlotEv1NameInput,'Enable','off');
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function PlotEv1NameInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PlotEv2NameInput_Callback(hObject, eventdata, handles)
if get(handles.Ev2Check,'value')==1
    set(handles.PlotEv2NameInput,'Enable','on');
else
    set(handles.PlotEv2NameInput,'Enable','off');
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function PlotEv2NameInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in PlotSaveButton.
function PlotSaveButton_Callback(hObject, eventdata, handles)
handles.MyGUI=gcf;
set(handles.MyGUI,'Pointer','watch')
drawnow;  % Cursor won't change right away unless you do this.

if get(handles.PlotGCaMPCheck,'value')==0 && get(handles.PlotControlCheck,'value')==0 ...
        && get(handles.PlotGCaMPCtrlCheck,'value')==0 && get(handles.PlotGCaMPFitCtrlCheck,'value')==0 ...
        && get(handles.PlotDeltaFCheck,'value')==0 && get(handles.PlotDeltaFZScoreCheck,'value')==0
    msgbox('Please select at least one.', 'Error','warn');
end

%If the "GCaMP Channel" checkbox is selected:
if get(handles.PlotGCaMPCheck,'value')==1
    figure;
    plot(handles.Ts,handles.Ch490);hold on;
    xlim([handles.Ts(1) handles.Ts(end)]);
    xlabel('Time (seconds)');
    title('Signal Channel Recording');
    FastPrintv2(handles.UserPrefix,'SignalChannel');
    hold off;
end

%If the "Control Channel" checkbox is selected:
if get(handles.PlotControlCheck,'value')==1
    figure
    plot(handles.Ts,handles.Ch405)
    xlim([handles.Ts(1) handles.Ts(end)]);
    title('Control Recording');
    xlabel('Time (seconds)');
    FastPrintv2(handles.UserPrefix,'ControlPlot');
end

%If the "GCaMP vs. Control" checkbox is selected:
if get(handles.PlotGCaMPCtrlCheck, 'value')==1
    figure;
    plot(handles.Ts,handles.Ch490);
    hold on
    plot(handles.Ts,handles.Ch405);
    xlim([handles.Ts(1) handles.Ts(end)]);
    xlabel('Time (seconds)');
    title('Signal vs Control');
    FastPrintv2(handles.UserPrefix,'Ch490Plus405Data');
end

%If the "GCaMP vs. Fitted Control" checkbox is selected:
if get(handles.PlotGCaMPFitCtrlCheck,'value')==1
    figure;
    F490=smooth(handles.Ch490,0.002,'lowess'); 
    F405=smooth(handles.Ch405,0.002,'lowess');
    bls=polyfit(F405(1:end),F490(1:end),1);
    Y_Fit=bls(1).*F405+bls(2);
    plot(handles.Ts,handles.Ch490);
    hold on;
    plot(handles.Ts, Y_Fit);
    xlim([handles.Ts(1) handles.Ts(end)]);
    xlabel('Time (seconds)');
    title('Signal vs Fitted Control');
    FastPrintv2(handles.UserPrefix,'SignalvsFitCtrl');
end

%If "Delta F/F" is selected, but not the "Plot Event Ticks" checkboxes:
if get(handles.PlotDeltaFCheck,'value')==1 && get(handles.Ev1Check,'value')==0 ...
        && get(handles.Ev2Check,'value')==0

    F490=smooth(handles.Ch490,0.002,'lowess'); 
    F405=smooth(handles.Ch405,0.002,'lowess');

    bls=polyfit(F405(1:end),F490(1:end),1);
    %scatter(F405(10:end-10),F490(10:end-10))
    Y_Fit=bls(1).*F405+bls(2);
    %figure
    Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);
    figure
    plot(handles.Ts,Delta490.*100)
    xlim([handles.Ts(1) handles.Ts(end)]);
    ylabel('% \Delta F/F');
    xlabel('Time (Seconds)');
    title('\Delta F/F for Recording ');
    FastPrintv2(handles.UserPrefix,'WholeTracePlotLF');
end

%If the "Delta F/F" checkbox is selcted and at least one of the "Plot
%Events Ticks" checkboxes, the following section will determine which names
%to use in the figure legend. If no custom event names have been entered,
%the legend will default to the selected event code string shown in the lisbox.
if get(handles.PlotDeltaFCheck,'value')==1 && (get(handles.Ev1Check,'value')==1 ...
        || get(handles.Ev2Check,'value')==1)
    if get(handles.Ev1Check,'value')==1
        if ~isfield(handles,'PlotEv1Selection')
            handles.PlotEv1Selection= handles.BitListStr{1};
        end
        if ~isnumeric(handles.MasterArray{2,1})
        Ev1=str2double(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2)); 
        Event= [Ev1 Ev1+5];
        else
        Ev1=cell2mat((handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2))); 
        Event= [Ev1 Ev1+5];    
        end
        
        if all(isnan(Ev1))
        Ev1=cell2mat((handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2))); 
        Event= [Ev1 Ev1+5];
        end
        
        if isempty(get(handles.PlotEv1NameInput,'String')) | get(handles.PlotEv1NameInput,'String')=="Ev1"
            Ev1Name=string(handles.PlotEv1Selection);
        else
            Ev1Name=get(handles.PlotEv1NameInput,'String');
        end
    end
    if get(handles.Ev2Check,'value')==1
        if ~isfield(handles,'PlotEv2Selection')
            handles.PlotEv2Selection =handles.BitListStr{1};
        end
        if ~isnumeric(handles.MasterArray{2,1})
        Ev2=str2double(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2));
        Event2 =[Ev2 Ev2+5];
        else
        Ev2=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2));
        Event2 =[Ev2 Ev2+5];
        end
        
        if all(isnan(Ev2))
        Ev2=cell2mat((handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2))); 
        Event2= [Ev2 Ev2+5];
        end


        if isempty(get(handles.PlotEv2NameInput,'String')) | get(handles.PlotEv2NameInput,'String')=="Ev2"
            Ev2Name=string(handles.PlotEv2Selection);
        else
            Ev2Name=get(handles.PlotEv2NameInput,'String');
        end
    end
    
    %Before adding any ticks, Delta F/F is plotted, as above:
    F490=smooth(handles.Ch490,0.002,'lowess'); 
    F405=smooth(handles.Ch405,0.002,'lowess');

    bls=polyfit(F405(1:end),F490(1:end),1);
    % scatter(F405(10:end-10),F490(10:end-10))
    Y_Fit=bls(1).*F405+bls(2);
    figure;
    Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);

    plot(handles.Ts,Delta490.*100)
    xlim([handles.Ts(1) handles.Ts(end)]);
    ylabel('% \Delta F/F')
    xlabel('Time (Seconds)')
    title('\Delta F/F for Recording ')
    hold on

    if get(handles.Ev1Check,'value')==1 && get(handles.Ev2Check,'value')==0
        % Peak=max(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15));
        Peak=max(Delta490);
        for i=1:length(Event)
            x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
            % y=[Peak*110 Peak*115 Peak*115 Peak*110];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p1= patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none');    
        end
        % xlim([Event(1,1)-10 Event(end,2)+15])
        xlim([handles.Ts(1) handles.Ts(end)]);
        legend([p1],{Ev1Name},'Interpreter','none');
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv1Selection)],'');
        FastPrintv2(prefix,'WholeSessionTrace');
    end
    
    if get(handles.Ev2Check,'value')==1 && get(handles.Ev1Check,'value')==0
        Event=Event2;
        % Peak=max(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15));
        Peak=max(Delta490);
        for i=1:length(Event2)
            x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
            % y=[Peak*105 Peak*110 Peak*110 Peak*105];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p2=patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none');
        end
        % xlim ([Event(1,1)-10 Event(end,2)+15]);
        xlim([handles.Ts(1) handles.Ts(end)]);
        legend([p2],{Ev2Name},'Interpreter','none');
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv2Selection)],'');
        FastPrintv2(prefix,'WholeSessionTrace');
    end
    
    if get(handles.Ev2Check,'value')==1 && get(handles.Ev1Check,'value')==1
        % Peak=max(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15));
        Peak=max(Delta490);
        for i=1:length(Event)
            x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
            % y=[Peak*110 Peak*115 Peak*115 Peak*110];
            y=[Peak+7.5 Peak+8.5 Peak+8.5 Peak+7.5];
            p1=patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none');    
        end
        for i=1:length(Event2)
            x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
            % y=[Peak*105 Peak*110 Peak*110 Peak*105];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p2=patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none');
        end
        legend([p1 p2],{Ev1Name,Ev2Name},'Interpreter','none','Location','eastoutside');
        % xlim ([Event(1,1)-10 Event(end,2)+15])
        xlim([handles.Ts(1) handles.Ts(end)]);
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv1Selection) '-' string(handles.PlotEv2Selection)],'');
        FastPrintv2(prefix,'WholeSessionTrace');
    end
end

if get(handles.PlotDeltaFZScoreCheck,'value')==1 && get(handles.Ev1Check,'value')==0 ...
        && get(handles.Ev2Check,'value')==0
    F490=smooth(handles.Ch490,0.002,'lowess'); 
    F405=smooth(handles.Ch405,0.002,'lowess');
   

    bls=polyfit(F405(1:end),F490(1:end),1);
    %scatter(F405(10:end-10),F490(10:end-10))
    Y_Fit=bls(1).*F405+bls(2);
    %figure
    Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);
    figure
    plot(handles.Ts,zscore(Delta490))
    xlim([handles.Ts(1) handles.Ts(end)]);
    ylabel('Normalized \Delta F/F (z-score)');
    xlabel('Time (Seconds)');
    title('Normalized \Delta F/F for Recording ');
    FastPrintv2(handles.UserPrefix,'WholeTracePlotZScore');
end
    
if get(handles.PlotDeltaFZScoreCheck,'value')==1 && (get(handles.Ev1Check,'value')==1 ||...
        get(handles.Ev2Check,'value')==1)
    if get(handles.Ev1Check,'value')==1
        if ~isfield(handles,'PlotEv1Selection')
            handles.PlotEv1Selection= handles.BitListStr{1};
        end
        if ~isnumeric(handles.MasterArray{2,1})
        Ev1=str2double(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2)); 
        Event= [Ev1 Ev1+5];
        else
        Ev1=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2)); 
        Event= [Ev1 Ev1+5];
        end
        
        if all(isnan(Ev1))
        Ev1=cell2mat((handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv1Selection),2))); 
        Event= [Ev1 Ev1+5];
        end
        
        if isempty(get(handles.PlotEv1NameInput,'String')) | get(handles.PlotEv1NameInput,'String')=="Ev1"
            Ev1Name=string(handles.PlotEv1Selection);
        else
            Ev1Name=get(handles.PlotEv1NameInput,'String');
        end
    end
    if get(handles.Ev2Check,'value')==1
        if ~isfield(handles,'PlotEv2Selection')
            handles.PlotEv2Selection =handles.BitListStr{1};
        end
        if ~isnumeric(handles.MasterArray{2,1})
        Ev2=str2double(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2));
        Event2 =[Ev2 Ev2+5];
        else
        Ev2=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2));
        Event2 =[Ev2 Ev2+5];
        end
        
        if all(isnan(Ev2))
        Ev2=cell2mat((handles.MasterArray(handles.MasterArray(:,1)==string(handles.PlotEv2Selection),2))); 
        Event2= [Ev2 Ev2+5];
        end
            
        if isempty(get(handles.PlotEv2NameInput,'String')) | get(handles.PlotEv2NameInput,'String')=="Ev2"
            Ev2Name=string(handles.PlotEv2Selection);
        else
            Ev2Name=get(handles.PlotEv2NameInput,'String');
        end
    end

    F490=smooth(handles.Ch490,0.002,'lowess'); 
    F405=smooth(handles.Ch405,0.002,'lowess');

    bls=polyfit(F405(1:end),F490(1:end),1);
    %scatter(F405(10:end-10),F490(10:end-10))
    Y_Fit=bls(1).*F405+bls(2);
    figure;
    Delta490=(F490(:)-Y_Fit(:))./Y_Fit(:);

    % % Delta F/F
    plot(handles.Ts,zscore(Delta490))
    xlim([handles.Ts(1) handles.Ts(end)]);
    ylabel('Normalized \Delta F/F (z-score)')
    xlabel('Time (Seconds)')
    title('Normalized \Delta F/F for Recording ')
    hold on

    if get(handles.Ev1Check,'value')==1 && get(handles.Ev2Check,'value')==0
        % Peak=max(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15));
        Peak=max(Delta490);
        for i=1:length(Event)
            x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
            % y= [Peak*110 Peak*115 Peak*115 Peak*110];
            % y = [20 21 21 20];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p1=patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none');
        end
        % xlim ([Event(1,1)-10 Event(end,2)+15])
        xlim([handles.Ts(1) handles.Ts(end)]);
        legend([p1],{Ev1Name},'Interpreter','none');
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv1Selection)],'');
        FastPrintv2(prefix,'WholeSessionTraceZScore');
    end
    
    if get(handles.Ev2Check,'value')==1 && get(handles.Ev1Check,'value')==0
        Event=Event2;
        % Peak=max(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15));
        Peak=max(Delta490);
        for i=1:length(Event2)
            x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
            % y=[Peak*105 Peak*110 Peak*110 Peak*105];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p2=patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none');
        end
        % xlim ([Event(1,1)-10 Event(end,2)+15]);
        xlim([handles.Ts(1) handles.Ts(end)]);
        legend([p2],{Ev2Name},'Interpreter','none');
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv2Selection)],'');
        FastPrintv2(prefix,'WholeSessionTraceZScore');
    end
    
    if get(handles.Ev2Check,'value')==1 && get(handles.Ev1Check,'value')==1
        % Peak=max(zscore(Delta490(handles.Ts(:,1)>=Event(1,1)-10 & handles.Ts(:,1)<=Event(end,2)+15)));
        Peak=max(zscore(Delta490));
        for i=1:length(Event)
            x = [Event(i,1) Event(i,1) Event(i,2) Event(i,2)];
            % y=[Peak*1.10 Peak*1.15 Peak*1.15 Peak*1.10];
            y=[Peak+7.5, Peak+8.5, Peak+8.5, Peak+7.5];
            p1=patch(x,y,'black','FaceAlpha',0.5,'EdgeColor','none');
        end
        
        for i=1:length(Event2)
            x = [Event2(i,1) Event2(i,1) Event2(i,2) Event2(i,2)];
            % y=[Peak*1.05 Peak*1.10 Peak*1.10 Peak*1.05];
            y=[Peak+7 Peak+8 Peak+8 Peak+7];
            p2=patch(x,y,'red','FaceAlpha',0.5,'EdgeColor','none');
        end
        xlim([handles.Ts(1) handles.Ts(end)])
        legend([p1,p2],{Ev1Name,Ev2Name},'Interpreter','none','Location','eastoutside');
        % xlim([Event(1,1)-10 Event(end,2)+15])
        prefix=strjoin([handles.UserPrefix '_' string(handles.PlotEv1Selection) '-' string(handles.PlotEv2Selection)],'');
        FastPrintv2(prefix,'WholeSessionTraceZScore');
    end
end

f = msgbox('The files have been saved in the working directory under the figures folder.','Save Successful!');
set(handles.MyGUI,'Pointer','arrow')
drawnow;  % Cursor won't change right away unless you do this.
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function TickTipText2_CreateFcn(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function TickTipText_CreateFcn(hObject, eventdata, handles)



%% ACU and PETH Panel

% --- Executes on selection change in PETHEventList.
function PETHEventList_Callback(hObject, eventdata, handles)
contents=cellstr(get(hObject,'String'));
handles.PETHListSelection = contents{get(hObject, 'Value')};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function PETHEventList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PreInput_Callback(hObject, eventdata, handles)
handles.PreInput.String = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function PreInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PostInput_Callback(hObject, eventdata, handles)
handles.PostInput.String = get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function PostInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function BL_WidthInput_Callback(hObject, eventdata, handles)
handles.BL_WidthInput.String=get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function BL_WidthInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function BL_StartInput_Callback(hObject, eventdata, handles)
handles.BL_StartInput.String = get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function BL_StartInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function BinInput_Callback(hObject, eventdata, handles)
handles.BinInput.String=get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function BinInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AUCDataCheck.
function AUCDataCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in AUCGraphCheck.
function AUCGraphCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in ZScoreCheck.
function ZScoreCheck_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes on button press in DeltaFCheck.
function DeltaFCheck_Callback(hObject, eventdata, handles)
if get(handles.DeltaFCheck,'value')==1 || get(handles.PlotDeltaFZScoreCheck,'value')==1
    set(handles.Ev1Check,'Enable','on'); set(handles.Ev2Check,'Enable','on');
else
    set(handles.Ev1Check,'Enable','off'); set(handles.Ev2Check,'Enable','off');
    set(handles.Ev1Check,'value',0); set(handles.Ev2Check,'value',0);
end
guidata(hObject,handles);


% --- Executes on button press in AUCGraphToggle.
function AUCGraphToggle_Callback(hObject, eventdata, handles)
if get(handles.AUCGraphToggle, 'value')==1
    set(handles.AUCDataCheck,'value',1);
    set(handles.AUCGraphCheck,'value',1);
    set(handles.ZScoreCheck,'value',1);
    set(handles.DeltaFCheck,'value',1);
    set(handles.TrialTraceCheck,'value',1);
    set(handles.TraceDataCheck,'value',1);
else
    set(handles.AUCDataCheck,'value',0);
    set(handles.AUCGraphCheck,'value',0);
    set(handles.ZScoreCheck,'value',0);
    set(handles.DeltaFCheck,'value',0);
    set(handles.TrialTraceCheck,'value',0);
    set(handles.TraceDataCheck,'value',0);
end
guidata(hObject,handles)


% --- Executes when entered data in editable cell(s) in AUCTable.
function AUCTable_CellEditCallback(hObject, eventdata, handles)
for i=1:6
    if isnan(handles.AUCTable.Data{i,1})==1
        handles.AUCTable.Data{i,1}=[];end
    if isnan(handles.AUCTable.Data{i,2})==1
        handles.AUCTable.Data{i,2}=[];end
end
guidata(hObject,handles)


% --- Executes on button press in AUCGo.
function AUCGo_Callback(hObject, eventdata, handles)
if (isempty(handles.PreInput.String))
    set(handles.PreInput,'String','-5'); end
if (isempty(handles.PostInput.String))
    set(handles.PostInput,'String','10'); end
if (isempty(handles.BL_WidthInput.String))
    set(handles.BL_WidthInput,'String',"5"); end
if (isempty(handles.BL_StartInput.String))
    set(handles.BL_StartInput,'String',"-5"); end
if (isempty(handles.BinInput.String))
    set(handles.BinInput,'String',"100"); end

Pre=str2double(handles.PreInput.String); %Time to sample for Raster-    PETH before event
if Pre < 0
    Pre = abs(Pre); 
end

Post=str2double(handles.PostInput.String); %Time to sample for raster-PETH after event.
if Post < 0
    Post = abs(Post);
    set(handles.PostInput,'String',Post);
    msgbox('Please enter a positive post-event time.','Error','warn');
    pause; 
end

BL_Width=str2double(handles.BL_WidthInput.String); %Set the duration of the baseline
BL_Start=abs(str2double(handles.BL_StartInput.String)); %Time before raster to start taking baseline
Bin=str2double(handles.BinInput.String);
    
if isfield(handles,'PETHListSelection')
   PETHEventStr=string(handles.PETHListSelection);
   if ~isnumeric(handles.MasterArray{2,1})
   EventTS=str2double(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
   else
   EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2))
   end 
    if all(isnan(EventTS))
    EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
    end
    
else
    firstevent=string(handles.BitListStr{1});
    if ~isnumeric(handles.MasterArray{2,1})
    EventTS=str2double(handles.MasterArray(handles.MasterArray(:,1)==firstevent,2));
    else
    EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==firstevent,2));
    end
    
    if all(isnan(EventTS))
    EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==firstevent,2));
    end
    
end

[ToneTrace, ~]=TrialPETHAUC( handles.Fs, handles.Ts, Pre, Post, ...
    EventTS,handles.Ch490,handles.Ch405, 'AUC',Bin,0,5, BL_Width,BL_Start );

AUC=[]; MaxValue=[];
for i=1:6
    if ~isempty(handles.AUCTable.Data{i,1}) & ~isempty(handles.AUCTable.Data{i,2})
        if handles.AUCTable.Data{i,1}>=handles.AUCTable.Data{i,2}
            msgbox('End time must be a larger value than start time.','Error','warn');
        else
            if handles.AUCTable.Data{i,1} > Post || handles.AUCTable.Data{i,1} < str2double(handles.PreInput.String) ...
                    || handles.AUCTable.Data{i,2} > Post || handles.AUCTable.Data{i,2} < str2double(handles.PreInput.String)
                msgbox('Start/end time entered outside of pre/post event range.','Error','warn');
            end
            str=string(i);
            str1=strjoin(['start' str],'');
            str2=strjoin(['end' str],'');
            handles.(str1)=handles.AUCTable.Data{i,1};
            handles.(str2)=handles.AUCTable.Data{i,2};
            AUC(1,i)=trapz(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
            MaxValue(1,i)=max(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
            handles.AUCTable.Data{i,3}=AUC(1,i);
            handles.AUCTable.Data{i,4}=MaxValue(1,i);
        end
    end
end
guidata(hObject,handles)


function PETHContinueButton_Callback(hObject, eventdata, handles)

if isempty(handles.PreInput.String)
    set(handles.PreInput,'String','-5'); end
if isempty(handles.PostInput.String)
    set(handles.PostInput,'String','10'); end
if isempty(handles.BL_WidthInput.String)
    set(handles.BL_WidthInput,'String',"5"); end
if isempty(handles.BL_StartInput.String)
    set(handles.BL_StartInput,'String',"-5"); end
if isempty(handles.BinInput.String)
    set(handles.BinInput,'String',"100"); end
    
if get(handles.ZScoreCheck,'value')==0 && get(handles.DeltaFCheck,'value')==0 ...
        && get(handles.AUCDataCheck,'value')==0 && get(handles.AUCGraphCheck,'value')==0 ...
        && get(handles.TrialTraceCheck,'value')==0 && get(handles.TraceDataCheck,'value')==0
    msgbox('Please select at least one.', 'Error','warn');
else
    Pre=str2double(handles.PreInput.String); %Time to sample for Raster-PETH before event
    if Pre < 0
        Pre = abs(Pre);
    end
    Post=str2double(handles.PostInput.String); %Time to sample for raster-PETH after event.
    if Post < 0
        Post = abs(Post);
        set(handles.PostInput,'String',Post);
        msgbox('Please enter a positive post-event time.','Error','warn');
        pause;
    end
    
    BL_Width=str2double(handles.BL_WidthInput.String); %Set the duration of the baseline
    BL_StartA=str2double(handles.BL_WidthInput.String); %Time before raster to start taking baseline
    BL_Start=abs(BL_StartA);
    Bin=str2double(handles.BinInput.String);
    
    
    if isfield(handles,'PETHListSelection')
        PETHEventStr=string(handles.PETHListSelection);
        if ~isnumeric(handles.MasterArray{2,1})
        EventTS=str2double(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
        else
        EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
        end
        
        if all(isnan(EventTS))
        EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
        end
        
    else
        PETHEventStr=string(handles.BitListStr{1});
        if ~isnumeric(handles.MasterArray{2,1})
        EventTS=str2double(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
        else
        EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));    
        end
        
        if all(isnan(EventTS))
        EventTS=cell2mat(handles.MasterArray(handles.MasterArray(:,1)==PETHEventStr,2));
        end
    end
    
    %     newprefix=strjoin([string(handles.UserPrefix),'_', PETHEventStr],'');
    if (isempty(handles.PETHNameInput.String)) | handles.PETHNameInput.String =="ex. Shock, Tone, etc."
        PETHName=PETHEventStr;
    else
        PETHName=handles.PETHNameInput.String;
    end
    prefix = strjoin([string(handles.UserPrefix),'_', string(PETHName)],'');
    
    if get(handles.ZScoreCheck,'value') == 1
        %         prefix = strjoin([string(handles.UserPrefix),'_', string(PETHName)],'');
        FigTitle= strjoin([string(PETHName),' Z-Score PETH']);
        TrialPETHZScore(handles.Fs, handles.Ts, Pre,...
            Post, EventTS, handles.Ch490, handles.Ch405,...
            prefix,FigTitle,Bin,0,5, BL_Width, BL_Start);
    end
    if get(handles.DeltaFCheck,'value') == 1
        %         prefix = strjoin([string(handles.UserPrefix),'_', string(PETHName)],'');
        FigTitle=strjoin([string(PETHName),' Delta F PETH']);
        TrialPETHDeltaF(handles.Fs, handles.Ts, Pre,...
            Post, EventTS, handles.Ch490, handles.Ch405,...
            prefix,FigTitle,Bin,0,5, BL_Width, BL_Start);
    end
    
    if get(handles.AUCGraphCheck,'value')==1
        [ToneTrace]=AUCPeak( handles.Fs, handles.Ts, Pre, Post, ...
            EventTS,handles.Ch490,handles.Ch405, 'AUC',Bin,0,5, BL_Width,BL_Start );
        AUC=[]; MaxValue=[];
        breakdown=[];
        xlabels={};
        for i=1:6
            if ~isempty(handles.AUCTable.Data{i,1}) & ~isempty(handles.AUCTable.Data{i,2})
                if handles.AUCTable.Data{i,1}>=handles.AUCTable.Data{i,2}
                    msgbox('End time must be a larger value than start time.','Error','warn');
                    breakdown=1;
                else
                    if handles.AUCTable.Data{i,1} > Post || handles.AUCTable.Data{i,1} < str2double(handles.PreInput.String) ...
                            || handles.AUCTable.Data{i,2} > Post || handles.AUCTable.Data{i,2} < str2double(handles.PreInput.String)
                        msgbox('Start/end time entered outside of pre/post event range.','Error','warn');
                    end
                    str=string(i);
                    str1=strjoin(['start' str],'');
                    str2=strjoin(['end' str],'');
                    xlabels{i}=strjoin([string(handles.AUCTable.Data{i,1}), "s to", string(handles.AUCTable.Data{i,2}),"s"]);
                    handles.(str1)=handles.AUCTable.Data{i,1};
                    handles.(str2)=handles.AUCTable.Data{i,2};
                    AUC(1,i)=trapz(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
                    MaxValue(1,i)=max(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
                    handles.AUCTable.Data{i,3}=AUC(1,i);
                    handles.AUCTable.Data{i,4}=MaxValue(1,i);
                end
            end
        end
        
        if isempty(breakdown)
            if (isempty(handles.PETHNameInput.String)) | handles.PETHNameInput.String =="ex. Shock, Tone, etc."
                Title=PETHEventStr;
            else
                Title=get(handles.PETHNameInput,'String');
            end
            
            figure;
            bar(AUC);
            set(gca,'xticklabel',xlabels);
            hold on;
            title(strjoin(["Area under the curve (AUC) (",Title,")"]),'Interpreter','none');
            FastPrintv2(prefix,'AUC');
            hold off;
            figure;
            bar(MaxValue);
            set(gca,'xticklabel',xlabels);
            hold on;
            title(strjoin(["Peak Value (",Title,")"]),'Interpreter','none');
            FastPrintv2(prefix,'MaxValue');
            hold off;
        end
    end
    
    if get(handles.AUCDataCheck,'value')==1
        [ToneTrace]=AUCPeak( handles.Fs, handles.Ts, Pre, Post,...
            EventTS,handles.Ch490,handles.Ch405, 'AUC',Bin,0,5, BL_Width,BL_Start );
        AUC=[]; MaxValue=[];
        breakdown=[];
        for i=1:6
            if ~isempty(handles.AUCTable.Data{i,1}) && ~isempty(handles.AUCTable.Data{i,2})
                if handles.AUCTable.Data{i,1}>=handles.AUCTable.Data{i,2}
                    msgbox('End time must be a larger value than start time.','Error','warn');
                    breakdown=1;
                else
                    if handles.AUCTable.Data{i,1} > Post || handles.AUCTable.Data{i,1} < str2double(handles.PreInput.String) ...
                            || handles.AUCTable.Data{i,2} > Post || handles.AUCTable.Data{i,2} < str2double(handles.PreInput.String)
                        msgbox('Start/end time entered outside of pre/post event range.','Error','warn');
                    end
                    str=string(i);
                    str1=strjoin(['start' str],'');
                    str2=strjoin(['end' str],'');
                    handles.(str1)=handles.AUCTable.Data{i,1};
                    handles.(str2)=handles.AUCTable.Data{i,2};
                    AUC(1,i)=trapz(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
                    MaxValue(1,i)=max(ToneTrace(ToneTrace(:,1)>=handles.(str1) & ToneTrace(:,1)<= handles.(str2),2));
                    handles.AUCTable.Data{i,3}=AUC(1,i);
                    handles.AUCTable.Data{i,4}=MaxValue(1,i);
                    handles.AUCTable.Data{i,3}=AUC(1,i);
                    handles.AUCTable.Data{i,4}=MaxValue(1,i);
                end
            end
        end
        
        if isempty(breakdown)
            T=cell2table(handles.AUCTable.Data);
            T.Properties.VariableNames={'Start','End','AUC','MaxValue'};
            mydir=cd;
            if isfolder([mydir '/Data'])==0
                mkdir('Data')
            end
            
            newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_AUCData','.csv'],'');
            a= [cd,'\Data'];
            mydir=cd;
            cd(a)
            fullName=fullfile(a,newname);
            i=1;
            while exist(string(fullName),'file')
                newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_AUCData',string(i),'.csv'],'');
                fullName=fullfile(a,newname);
                i=i+1;
            end
            writetable(T,newname);
            cd (mydir)
        end
    end
    
    if get(handles.TrialTraceCheck,'value')==1 || get(handles.TraceDataCheck,'value')==1
        [FinalData, TrialData] = TrialPETHTrace(handles.Fs, handles.Ts, Pre, ...
            Post, EventTS,handles.Ch490,handles.Ch405,'-',Bin,0,5, BL_Width, BL_Start);
       if get(handles.TrialTraceCheck,'value')==1 
           T=table(TrialData);
           mydir=cd;
           if isfolder([mydir '/Data'])==0
               mkdir('Data')
           end
           newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_TrialTraceData','.csv'],'');
           if newname{1}(1)=="_"
               newname=string(newname{1}(2:end));
           end
           a=[cd,'\Data'];
           mydir=cd;
           cd(a)
           fullName=fullfile(a,newname);
           i=1;
           while exist(string(fullName),'file')
               newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_TrialTraceData',string(i),'.csv'],'');
               fullName=fullfile(a,newname);
               i=i+1;
           end
           writetable(T,newname);
           cd(mydir)
       end
       
       if get(handles.TraceDataCheck,'value')==1
           tmp=[FinalData];
           Columns=["TimeStamp","ZScore","DeltaF/F"];
           tmp2=cellstr([Columns; tmp]);
           T=table(tmp2);
           mydir=cd;
           if isfolder([mydir '/Data'])==0
               mkdir('Data')
           end
           newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_AverageTraceData','.csv'],'');
           if newname{1}(1)=="_"
               newname=string(newname{1}(2:end));
           end
           a=[cd,'\Data'];
           mydir=cd;
           cd(a)
           fullName=fullfile(a,newname);
           i=1;
           while exist(string(fullName),'file')
               newname=strjoin([handles.UserPrefix,'_',PETHEventStr,'_AverageTraceData',string(i),'.csv'],'');
               fullName=fullfile(a,newname);
               i=i+1;
           end
           writetable(T,newname,'WriteVariableNames',false);
           cd(mydir)
       end
    end
end
guidata(hObject,handles);


% --- Executes on button press in PlotDeltaFZScoreCheck.
function PlotDeltaFZScoreCheck_Callback(hObject, eventdata, handles)
if get(handles.DeltaFCheck,'value')==1 || get(hObject,'value')==1
    set(handles.Ev1Check,'Enable','on'); set(handles.Ev2Check,'Enable','on');
else
    set(handles.Ev1Check,'Enable','off'); set(handles.Ev2Check,'Enable','off');
    set(handles.Ev1Check,'value',0); set(handles.Ev2Check,'value',0);
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function BinPanel_CreateFcn(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function BinText_CreateFcn(hObject, eventdata, handles)

function PETHNameInput_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function PETHNameInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RunAllButton.
function RunAllButton_Callback(hObject, eventdata, handles)
if handles.DataType=="Single" 
    %Single data set processing runs through each panel where at least one
    %box is checked, using the settings for that panel.
    if get(handles.Ca2DataCheck,'value') + get(handles.EventDataCheck,'value') + ...
            get(handles.SelectedEventDataCheck,'value') >=1
        OutputDataButton_Callback(hObject,eventdata,handles);
    end
    
    if get(handles.PlotGCaMPCheck,'value') + get(handles.PlotControlCheck,'value') + ...
            get(handles.PlotGCaMPCtrlCheck,'value') + get(handles.PlotGCaMPFitCtrlCheck,'value') + ...
            get(handles.PlotDeltaFCheck,'value') +get(handles.PlotDeltaFZScoreCheck,'value') >=1
        PlotSaveButton_Callback(hObject,eventdata,handles);
    end
    
    if get(handles.ZScoreCheck,'value') + get(handles.DeltaFCheck,'value') + ...
            get(handles.AUCDataCheck,'value') + get(handles.AUCGraphCheck,'value') >=1
        PETHContinueButton_Callback(hObject,eventdata,handles);
    end
end

if handles.DataType=="Batch"
    %Batch processing first imports data from each file before running
    %through the panels.
    for s=1:length(handles.Subjects)
        cd(handles.GroupFold);
        cd(handles.Subjects(s).folder);
        handles.subjectID=strtok(handles.Subjects(s).name,'-');
        [Tank,Block,~]=fileparts(cd);
        disp(['Processing Block: ', Tank,'\',Block]);
        handles.data=TDTbin2mat([Tank,'\',Block]);
        handles.streamlist=fieldnames(handles.data.streams);
        if isfield(handles.data.streams,'x490R')
            Ts=((1:numel(handles.data.streams.x490R.data(1,:))) /handles.data.streams.x490R.fs);
            Ch490=handles.data.streams.x490R.data;
            EndTime=length(Ch490)-handles.EndBuffer;
            handles.Fs=handles.data.streams.x490R.fs;
            handles.Ts=Ts(handles.StartBuffer:EndTime);
            handles.Ch490=Ch490(handles.StartBuffer:EndTime);
        elseif isfield(handles, 'Ch490indx') && ~isempty(handles.Ch490indx)
            indx=handles.Ch490indx;
            Ts=((1:numel(handles.data.streams.(handles.streamlist{indx}).data(1,:))) ...
                /handles.data.streams.(handles.streamlist{indx}).fs);
            Ch490=handles.data.streams.(handles.streamlist{indx}).data;
            EndTime=length(Ch490)-handles.EndBuffer;
            handles.Fs=handles.data.streams.(handles.streamlist{indx}).fs;
            handles.Ts=Ts(handles.StartBuffer:EndTime);
            handles.Ch490=Ch490(handles.StartBuffer:EndTime);
        else
            [indx,tf]=listdlg('PromptString','Select your Signal channel:','SelectionMode','single', ...
                'ListString',handles.streamlist);
            while tf==0
                [indx,tf]=listdlg('PromptString','Select your Signal channel:','SelectionMode','single', ...
                    'ListString',handles.streamlist);
            end
            handles.Ch490indx=indx;
            Ts=((1:numel(handles.data.streams.(handles.streamlist{indx}).data(1,:))) ...
                /handles.data.streams.(handles.streamlist{indx}).fs);
            Ch490=handles.data.streams.(handles.streamlist{indx}).data;
            EndTime=length(Ch490)-handles.EndBuffer;
            handles.Fs=handles.data.streams.(handles.streamlist{indx}).fs;
            handles.Ts=Ts(handles.StartBuffer:EndTime);
            handles.Ch490=Ch490(handles.StartBuffer:EndTime);
        end
        
        if isfield(handles.data.streams,'x405R')
            Ch405=handles.data.streams.x405R.data;
            handles.Ch405=Ch405(handles.StartBuffer:EndTime);
        elseif isfield(handles, 'Ch405indx') && ~isempty(handles.Ch405indx)
            indx=handles.Ch405indx;
            Ch405=handles.data.streams.(handles.streamlist{indx}).data;
            handles.Ch405=Ch405(handles.StartBuffer:EndTime);
        else
            [indx,tf]=listdlg('PromptString','Select your control channel:','SelectionMode','single', ...
                'ListString',handles.streamlist);
            while tf==0
                [indx,tf]=listdlg('PromptString','Select your control channel:','SelectionMode', ...
                    'single','ListString',handles.streamlist);
            end
            handles.Ch405indx=indx;
            Ch405=handles.data.streams.(handles.streamlist{indx}).data;
            handles.Ch405=Ch405(handles.StartBuffer:EndTime);
        end
        
        handles.fields = fieldnames(handles.data.epocs);
        handles.MasterArray=[];
        
        for i=1:numel(handles.fields)
            if handles.fields{i}=="Tick" || handles.fields{i}=="Vid1"
                epoclist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
                epoclist(:)=handles.fields(i);
                handles.data.epocs.(handles.fields{i}).data=epoclist;
                onset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).onset),'un',0);
                offset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).offset),'un',0);
                BehData.(handles.fields{i})=[epoclist onset offset];
                handles.MasterArray= [handles.MasterArray; BehData.(handles.fields{i})];
            else
                fieldlist=cell(numel(handles.data.epocs.(handles.fields{i}).data),1);
                fieldlist(:)=handles.fields(i);
                epoclist=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).data), 'un',0);
                strs=strcat(fieldlist,epoclist);
                handles.data.epocs.(handles.fields{i}).data=strs;
                onset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).onset),'un',0);
                offset=cellfun(@num2str, num2cell(handles.data.epocs.(handles.fields{i}).offset),'un',0);
                BehData.(handles.fields{i})=[handles.data.epocs.(handles.fields{i}).data onset offset];
                handles.MasterArray=[handles.MasterArray; BehData.(handles.fields{i})];
            end
        end
        
        if get(handles.Ca2DataCheck,'value') + get(handles.EventDataCheck,'value') + ...
                get(handles.SelectedEventDataCheck,'value') >=1
            OutputDataButton_Callback(hObject,eventdata,handles);
        end
        
        if get(handles.PlotGCaMPCheck,'value') + get(handles.PlotControlCheck,'value') + ...
                get(handles.PlotGCaMPCtrlCheck,'value') + get(handles.PlotGCaMPFitCtrlCheck,'value') + ...
                get(handles.PlotDeltaFCheck,'value') +get(handles.PlotDeltaFZScoreCheck,'value') >=1
            PlotSaveButton_Callback(hObject,eventdata,handles);
        end
        
        if get(handles.ZScoreCheck,'value') + get(handles.DeltaFCheck,'value') + ...
                get(handles.AUCDataCheck,'value') + get(handles.AUCGraphCheck,'value') >=1
            PETHContinueButton_Callback(hObject,eventdata,handles);
        end
    end
end

guidata(hObject,handles);


% --- Executes on button press in TraceDataCheck.
function TraceDataCheck_Callback(hObject, eventdata, handles)

% --- Executes on button press in TrialTraceCheck.
function TrialTraceCheck_Callback(hObject, eventdata, handles)

% --- Executes when pmat is resized.
function pmat_SizeChangedFcn(hObject, eventdata, handles)

% --- Executes on key press with focus on DataUploadButton and none of its controls.
function DataUploadButton_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to DataUploadButton (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over DataUploadButton.
function DataUploadButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to DataUploadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function FilePath_CreateFcn(hObject, eventdata, handles)


% --- Executes when user attempts to close pmat.
function pmat_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to pmat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = questdlg('Would you like to save your current settings?','Save Settings',...
                  'Yes','No','Yes');
if strcmp(answer,'Yes')
    UserSettings=struct;
    UserSettings.PreInput=get(handles.PreInput,'String');
    UserSettings.PostInput=get(handles.PostInput,'String');
    UserSettings.BL_StartInput=get(handles.BL_StartInput,'String');
    UserSettings.BL_WidthInput=get(handles.BL_WidthInput,'String');
    UserSettings.BinInput=get(handles.BinInput,'String');
    UserSettings.startstop=handles.AUCTable.Data;
    UserSettings.prefix=get(handles.EditPrefix,'String');
    %Save pop up and listbox menu selections based on the index value of the selected
    %item(s).
    UserSettings.ExportEvent=get(handles.ExportEventList,'Value');
    UserSettings.PETHEvent=get(handles.PETHEventList,'Value');
    UserSettings.PlotEv1=get(handles.PlotEv1PopUp,'Value');
    UserSettings.PlotEv2=get(handles.PlotEv2PopUp,'Value');
    UserSettings.Ev1Name=get(handles.PlotEv1NameInput,'String');
    UserSettings.Ev2Name=get(handles.PlotEv2NameInput,'String');
    UserSettings.PETHName=get(handles.PETHNameInput,'String');
    if isfield(handles,'LastFold')
        UserSettings.LastFold=handles.LastFold;
    end

    UserSettings.CheckboxValues=[];
    for i=1:numel(handles.Checkboxes)
        UserSettings.CheckboxValues(i)=get(handles.(handles.Checkboxes{i}),'value');
    end

    %Save this new structure as a .mat file in the location selected by the
    %user:
    if isdir('C:\pmat-BarkerLab')
        cd('C:\pmat-BarkerLab')
    else
        cd('C:\')
        mkdir('pmat-BarkerLab')
        cd('C:\pmat-BarkerLab')
    end
    [filename,pathname]=uiputfile('PhotometryUserSettings.mat','Save Workspace Variables As');
    if pathname~=0
        newfilename=fullfile(pathname, filename);
        save(newfilename, 'UserSettings');
    else
        msgbox('Settings not saved.','Error','warn');
    end
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in CloseAll.
function CloseAll_Callback(hObject, eventdata, handles)
% hObject    handle to CloseAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fig_h = permute( findobj( 0, 'Type', 'Figure' ), [2,1] );
        for fh = fig_h
            uih = findobj( fh, 'Type', 'uicontrol' );
            if isempty( uih )
                delete( fh );
            end
        end
guidata(hObject,handles);

% --------------------------------------------------------------------
function ImportTopMenu_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function ImportCSV_Callback(hObject, eventdata, handles)
if isfield(handles,'LastCSVFold')==0
    
[handles.CSVfile handles.CSVFold]=uigetfile({'*.csv'},...
                          'Open Recording File');
                      cd(handles.CSVFold)
else
    cd(handles.LastCSVFold)
    [handles.CSVfile handles.CSVFold]=uigetfile({'*.csv'},...
                          'Open Recording File');
end

handles.LastCSVFold=handles.CSVFold;
if handles.CSVfile~=0
    set(gcf,'Pointer','watch');
    drawnow;
    handles.CSVdata=readtable(strcat(handles.CSVFold,handles.CSVfile));
    set(gcf,'Pointer','arrow')
    drawnow;  
    
    prompt={'Add time buffer at start and end of streams for LED rise/fall. Number of samples to eliminate at start:', ...
        'Number of samples to eliminate at end:'};
    definput={'2000','2000'}; dlgtitle='Sample Buffer'; dims=[1 35];
    BufferInput=inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(BufferInput)
        BufferInput={'2000','2000'}; end
    StartBuffer=str2double(BufferInput{1});
    EndBuffer=str2double(BufferInput{2});

    handles.Ts=table2array(handles.CSVdata(:,1));
    handles.Fs=(1/(mean(diff(handles.Ts))));
    EndTime=length(handles.Ts)-EndBuffer;
    handles.Ts=handles.Ts(StartBuffer:EndTime);
    handles.Ch490=table2array(handles.CSVdata(StartBuffer:EndTime,2));
    handles.Ch405=table2array(handles.CSVdata(StartBuffer:EndTime,3));
end

%% Import Behavioral Data
if isfield(handles,'LastCSVFold')==0
    
[handles.CSVBeh handles.CSVFold]=uigetfile({'*.csv'},...
                          'Open Event/Behavior File');
                      cd(handles.CSVFold);
else
    cd(handles.LastCSVFold)
    [handles.CSVBeh handles.CSVFold]=uigetfile({'*.csv'},...
                          'Open Event/Behavior File');
end

handles.LastCSVFold=handles.CSVFold;

if handles.CSVBeh~=0
    try
    handles.MasterArray=[];
    set(gcf,'Pointer','watch');
    drawnow;
    handles.CSVBehdata=readtable(strcat(handles.CSVFold,handles.CSVBeh));
    set(gcf,'Pointer','arrow')
    drawnow;   
    handles.MasterArray=table2cell(handles.CSVBehdata);
    catch
    ErrorMessage=lasterr;
    errordlg(msg)
    end
end  

    %Populate listboxes and dropdown menus with these unique event identifiers:
    handles.BitListStr=cellstr(string(unique(handles.MasterArray(:,1))));
    set(handles.PETHEventList,'String',handles.BitListStr);
    set(handles.ExportEventList,'String',handles.BitListStr);
    set(handles.PlotEv1PopUp,'String',handles.BitListStr);
    set(handles.PlotEv2PopUp,'String',handles.BitListStr);
    %Display the file path at the top of the GUI:
    set(handles.FilePath,'String', handles.CSVFold);
    %Most GUI functions are enabled once data has been successfully
    %imported:
    set(handles.PETHPanel,'Enable','on');
    set(handles.PlotPanel,'Enable','on');
    set(handles.DataExportPanel,'Enable','on');
    set(handles.NamePrefixPanel,'Enable','on');
    set(handles.CopyFilePath,'Enable','on');
    set(handles.RunAllButton,'Enable','on');
    set(handles.CloseAll,'Enable','on');
    set(handles.AUCGraphCheck,'Enable','on');
    %Clear any text from the handles.EditPrefix user input box:
    handles.UserPrefix={};
    set(handles.EditPrefix,'String','');
    %Set default text in other text input and static text boxes:
    set(handles.PlotEv1NameInput,'String','Ev1');
    set(handles.PlotEv2NameInput,'String','Ev2');
    set(handles.FileExample,'string','ex. Prefix_ControlPlot.jpg');
    set(handles.PETHNameInput,'String','ex. Shock, Tone, etc.');
    handles.subjectID=[];
    handles.DataType="Single";

guidata(hObject,handles);

% --------------------------------------------------------------------
function AppendBeh_Callback(hObject, eventdata, handles)
% hObject    handle to AppendBeh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'LastCSVFold')==0
    
[handles.CSVAppend handles.CSVFold]=uigetfile({'*.csv'},...
                          'Append Event Data');
else
    cd(handles.LastCSVFold)
    [handles.CSVAppend handles.CSVFold]=uigetfile({'*.csv'},...
                          'Append Event Data');
end

handles.LastCSVFold=handles.CSVFold;

if handles.CSVAppend~=0
    set(gcf,'Pointer','watch');
    drawnow;
    try
    handles.CSVAppendData=readtable(strcat(handles.CSVFold,handles.CSVAppend));
    catch
    ErrorMessage=lasterr;
    errordlg(msg)
    end
    set(gcf,'Pointer','arrow')
    drawnow;   
        if isfield(handles,'MasterArray')
        handles.MasterArray=[handles.MasterArray ;table2cell(handles.CSVAppendData)];
        else
        msgbox("The Main data file must be loaded before appending event data", 'Error','warn')    
        end

end

%Populate listboxes and dropdown menus with these unique event identifiers:
    handles.BitListStr=cellstr(string(unique(handles.MasterArray(:,1))));
    set(handles.PETHEventList,'String',handles.BitListStr);
    set(handles.ExportEventList,'String',handles.BitListStr);
    set(handles.PlotEv1PopUp,'String',handles.BitListStr);
    set(handles.PlotEv2PopUp,'String',handles.BitListStr);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2
