classdef SynapseAPI < handle
%   Available SynapseAPI methods:
%   --------------------------------------------------------
%   Legend:
%   b = bool, s = string, c = cell, i = int, f = float,
%   d = double, t = struct
%   --------------------------------------------------------
%   return value    function call
%   --------------------------------------------------------
%   bSuccess        appendExperimentMemo(sExperiment, sMemo)
%   bSuccess        appendSubjectMemo(sSubject, sMemo)
%   bSuccess        appendUserMemo(sUser, sMemo)
%   bSuccess        createSubject(varargin)
%   bSuccess        createTank(sTankPath)
%   sBlock          getCurrentBlock()
%   sExperiment     getCurrentExperiment()
%   sSubject        getCurrentSubject()
%   sTank           getCurrentTank()
%   sUser           getCurrentUser()
%   cNotes          getExperimentMemos(varargin)
%   cGizmos         getGizmoNames(varargin)
%   cGizmoInfo      getGizmoInfo(sGizmoName)
%   sGizmoParent    getGizmoParent(sGizmoName)
%   cBlocks         getKnownBlocks()
%   cExperiments    getKnownExperiments()
%   cSubjects       getKnownSubjects()
%   cTanks          getKnownTanks()
%   cUsers          getKnownUsers()
%   iMode           getMode()
%   sMode           getModeStr()
%   tParameterInfo  getParameterInfo(sGizmo, sParameter)
%   sParameters     getParameterNames(sGizmo)
%   dValue          getParameterSize(sGizmo, sParameter)
%   dValue          getParameterValue(sGizmo, sParameter)
%   fValues         getParameterValues(varargin)
%   sMode           getPersistMode()
%   cModes          getPersistModes()
%   tSamplingRates  getSamplingRates()
%   cNotes          getSubjectMemos(varargin)
%   tStatus         getSystemStatus()
%   cNotes          getUserMemos(varargin)
%   bSuccess        issueTrigger(iTriggerId)
%   bSuccess        setCurrentBlock(sBlock)
%   bSuccess        setCurrentExperiment(sExperiment)
%   bSuccess        setCurrentSubject(sSubject)
%   bSuccess        setCurrentTank(sTank)
%   bSuccess        setCurrentUser(varargin)
%   bSuccess        setMode(iNewMode)
%   bSuccess        setModeStr(sNewMode)
%   bSuccess        setParameterValue(sGizmo, sParameter, dValue)
%   bSuccess        setParameterValues(varargin)
%   bSuccess        setPersistMode(sMode)
%   
%   %%%%%
%   Please see the SynapseAPI manual for more detailed explanations
%   of these functions and some examples
%   %%%%%
    
    properties
        MODES = {'Idle', 'Standby', 'Preview', 'Record'};
        PERSIST = {'Last', 'Best', 'Fresh'};
        SERVER = '';
        PORT = 24414;
        synCon = '';
        lastReqStr = '';
        output = '';
        extras = '';
        useFastJsonParser = ~verLessThan('matlab', '8.6');
    end
    
    methods
        function obj = SynapseAPI(varargin)
            
            [folder, name, ext] = fileparts(which('SynapseAPI'));
            %addpath('C:\TDT\Synapse\SynapseAPI\Matlab\support')
            addpath([folder '\support']);
            
            if numel(varargin) < 1
                obj.SERVER = 'localhost';
            else
                obj.SERVER = varargin{1};
            end

            %self.lastReqStr = ''
            %self.reSueTank = re.compile('subject|user|experiment|tank|block')
            obj.synCon = ['http://' obj.SERVER ':' num2str(obj.PORT)];           
        
        end
        
        function delete(obj)
            %obj.synCon.close();
        end
        
        function retval = exceptMsg(obj)
            retval = '';
            
            if strfind('params',obj.lastReqStr)
                retval = '\nSynapse may need to be in non-Idle mode';
            %elseif obj.reSueTank.search(obj.lastReqStr) ~= ''
            %    retval = '\nSynapse may need to be in Idle mode';
            end
        end
        
        function retval = getResp(obj)              
            % success
            if obj.extras.status.value == 200
                if isempty(obj.output)
                    retval = 1;
                else
                    retval = obj.json2struct(obj.output);
                end
            else
                retval = 0;
                %warning('%d : %s', obj.extras.status.value, obj.extras.status.msg);
            end
        end
        
        function sendRequest(obj, reqTypeStr, reqStr, varargin)
            %
            %reqTypeStr = HTTP methods, e.g. 'GET', 'PUT', 'OPTIONS'
            %reqData = JSON formatted data
            %
            
            if numel(varargin) > 0
                reqData = varargin{1};
            else
                reqData = '';
            end
            
            if strcmp(reqData, '')
                urlChar = [obj.synCon reqStr];
                try
                    [obj.output, obj.extras] = urlread2(urlChar, reqTypeStr);
                catch ME
                    if ~isempty(strfind(ME.message, 'java.net.ConnectException'))
                        disp('Connection error, make sure Synapse Server is enabled.')
                    end
                    throw(ME)
                end
                   
            else
                urlChar = [obj.synCon reqStr];
                headersIn = struct('name','Content-type','value','application/json');
                [obj.output, obj.extras] = urlread2(urlChar, reqTypeStr, reqData, headersIn, 'FOLLOW_REDIRECTS', false);
            end
            obj.lastReqStr = reqStr;
        end
        
        function retval = sendGet(obj, reqStr, varargin)
            respKey = '';
            reqData = '';
            if numel(varargin) > 0
                respKey = varargin{1};
            end
            if numel(varargin) > 1
                reqData = varargin{2};
            end

            obj.sendRequest('GET', reqStr, reqData);
            resp = obj.getResp();
            
            if ~strcmp(resp, '')
                if ~obj.extras.isGood
                    retval = 0;
                elseif strcmp(respKey, '')
                    retval = resp;
                else
                    try
                        if iscell(resp.(respKey))
                            if ischar(resp.(respKey){1})
                                retval = resp.(respKey);
                            else
                                retval = cellfun(@double, resp.(respKey));
                            end
                        else
                            if ischar(resp.(respKey))
                                retval = resp.(respKey);
                            else
                                retval = double(resp.(respKey));
                            end
                        end
                    catch
                        retval = 0;
                    end
                end
            else
                retval = '';
            end
        end
        
        function retval = sendPut(obj, reqStr, reqData)
            obj.sendRequest('PUT', reqStr, reqData);
            % we must read and 'clear' response
            % otherwise subsequent HTTP request may fail
            x = obj.getResp();
            if isa(x, 'double')
                retval = x;
            else
                retval = 1;
            end
        end
        
        function retval = sendOptions(obj, reqStr, respKey)
            obj.sendRequest('OPTIONS', reqStr);
            
            try
                retval = obj.getResp();
                retval = retval.(respKey);
            catch
                retval = [];
            end
        end

        function retval = struct2json(obj, s)
            if obj.useFastJsonParser
                retval = matlab.internal.webservices.toJSON(s);
            else
                retval = tojson(s);
            end
        end
        
        function retval = json2struct(obj, s)
            if obj.useFastJsonParser
                retval = matlab.internal.webservices.fromJSON(s);
            else
                retval = fromjson(s);
            end
        end
        
        function sField = device2field(obj, sDevice)
            sField = strrep(sDevice, '_0x28_', '_');
            sField = strrep(sField, '_0x29_', '_');
            sField = strrep(sField, '(', '_');
            sField = strrep(sField, ')', '_');
            if strcmp(sField(end), '_')
                sField = sField(1:end-1);
            end
        end
        
        function iMode = getMode(obj)
            %-1: Error
            % 0: Idle
            % 1: Standby
            % 2: Preview
            % 3: Record
            iMode = -1;
            ind = strfind(obj.MODES, obj.getModeStr());
            ind = find(not(cellfun('isempty', ind)));
            if ~isempty(ind)
                if ind > 0 && ind < 5
                    iMode = ind-1;
                end
            end
        end
        
        function sMode = getModeStr(obj)
            % (Error), 'Idle', 'Standby', 'Preview', 'Record'
            sMode = obj.sendGet('/system/mode', 'mode');
        end
        
        function bSuccess = setMode(obj, iNewMode)            
            % mode must be an integer between 0 and 3, inclusive
            bSuccess = 0;
            if any(iNewMode == 0:3)
                bSuccess = obj.sendPut('/system/mode', obj.struct2json(struct('mode', obj.MODES(iNewMode+1))));
            else
                %error('invalid call to setMode()')
            end
        end
        
        function bSuccess = setModeStr(obj, sNewMode)
            % string equivalent of setMode()
            if ~any(cellfun(@(x)strcmp(x,sNewMode), obj.MODES))
                error('Allowed modes are: ''Idle'', ''Standby'', ''Preview'', or ''Record''')
            end
            bSuccess = obj.sendPut('/system/mode', obj.struct2json(struct('mode', sNewMode)));
        end
        
        function tStatus = getSystemStatus(obj)
            resp = obj.sendGet('/system/status');

            sysStat = struct('sysLoad','','uiLoad','','errors','','dataRate','','recDur','');
            fields = fieldnames(resp);
            for key = 1:numel(fields)
                if isfield(resp, fields{key})
                    sysStat.(fields{key}) = resp.(fields{key});
                end
            end
            
            % Synapse internal keys : user friendly keys
            keyMap = struct('sysLoad','iSysLoad','uiLoad','iUiLoad','errors','iErrorCount','dataRate','fRateMbps','recDur','iRecordSecs');
            fields = fieldnames(sysStat);
            for key = 1:numel(fields)
                field = fields{key};
                if strcmp(field, 'dataRate')
                    % '0.00 MB/s'
                    sss = strfind(sysStat.(field), ' ');
                    xxx = sysStat.(field);
                    tStatus.(keyMap.(field)) = str2double(xxx(1:sss));
                elseif strcmp(field, 'recDur')
                    % 'HH:MM:SSs'
                    testStr = sysStat.(field)(1:end-1);
                    ind = strfind(testStr,':');
                    hr = testStr(1:ind(1)-1);
                    mn = testStr(ind(1)+1:ind(2)-1);
                    sec = testStr(ind(2)+1:end);
                    tStatus.(keyMap.(field)) = str2double(hr) * 3600 + str2double(mn) * 60 + str2double(sec);
                elseif strcmp(field, 'errors')
                    value = str2double(sysStat.(field));
                    if isnan(value)
                        tStatus.(keyMap.(field)) = 0;
                    else
                        tStatus.(keyMap.(field)) = str2double(sysStat.(field));
                    end
                else
                    tStatus.(keyMap.(field)) = str2double(sysStat.(field));
                end
            end
        end
        
        function bSuccess = issueTrigger(obj, iTriggerId)
            bSuccess = obj.sendPut(['/trigger/' num2str(iTriggerId)], '');
        end
        
        function cGizmos = getGizmoNames(obj, varargin)
            % additional argument is bool
            % if true, return only the names of objects with any SynapseAPI
            % parameters enabled
            apiOnly = false;
            if numel(varargin) > 0
                apiOnly = logical(varargin{1});
            end
            if apiOnly
                cGizmos = obj.sendOptions('/gizmos/api', 'gizmos');
            else
                cGizmos = obj.sendOptions('/gizmos', 'gizmos');
            end
        end

        function cGizmoInfo = getGizmoInfo(obj, sGizmoName)
            % info should have type, desc, cat and icon
            % icon is a string of base64-encoded text
            cGizmoInfo = obj.sendGet(sprintf('/gizmos/%s', sGizmoName));
        end
        
        function sParameters = getParameterNames(obj, sGizmo)
            sParameters = obj.sendOptions(['/params/' sGizmo], 'parameters');
        end
        
        function tParameterInfo = getParameterInfo(obj, sGizmo, sParameter)
            info = obj.sendGet(sprintf('/params/info/%s.%s', sGizmo, sParameter), 'info');
            keys = {'Name', 'Unit', 'Min', 'Max', 'Access', 'Type', 'Array'};

            tParameterInfo = struct();
            for i = 1:numel(keys)
                key = keys{i};
                tParameterInfo.(key) = info{i};
                if strcmp(key, 'Array') && ~strcmp(info{i}, 'No') && ~strcmp(info{i}, 'Yes')
                    tParameterInfo.(key) = str2double(info{i});
                elseif strcmp(key, 'Min') || strcmp(key, 'Max')
                    tParameterInfo.(key) = str2double(info{i});
                elseif strcmp(key, 'Unit')
                    if isempty(info{i})
                        tParameterInfo.(key) = '';
                    end
                end
            end
        end

        function dValue = getParameterSize(obj, sGizmo, sParameter)
            dValue = obj.sendGet(sprintf('/params/size/%s.%s', sGizmo, sParameter), 'value');
        end

        function dValue = getParameterValue(obj, sGizmo, sParameter)
            dValue = obj.sendGet(sprintf('/params/%s.%s', sGizmo, sParameter), 'value');
        end

        function bSuccess = setParameterValue(obj, sGizmo, sParameter, dValue)
            bSuccess = obj.sendPut(sprintf('/params/%s.%s', sGizmo, sParameter), obj.struct2json(struct('value', dValue)));
        end

        function fValues = getParameterValues(obj, sGizmo, sParameter, varargin)
            iCount = -1;
            iOffset = 0;
            if numel(varargin) > 0
                iCount = double(varargin{1});
            end
            if numel(varargin) > 1
                iOffset = double(varargin{2});
            end
            
            if iCount == -1
                iCount = double(obj.getParameterSize(sGizmo, sParameter));
            end
            
            iCount = int64(iCount);
            iOffset = int64(iOffset);
            
            fValues = obj.sendGet(sprintf('/params/%s.%s', sGizmo, sParameter), 'values', obj.struct2json(struct('count',iCount,'offset',iOffset)));
            fValues = fValues(1:min(uint32(iCount), numel(fValues)));
        end

        function bSuccess = setParameterValues(obj, sGizmo, sParameter, fValues, varargin)
            if numel(varargin) > 0
                iOffset = varargin{1};
            else
                iOffset = 0;
            end
            bSuccess = obj.sendPut(sprintf('/params/%s.%s', sGizmo, sParameter), obj.struct2json(struct('offset', iOffset, 'values', fValues)));
        end

        function cModes = getPersistModes(obj)
            cModes = obj.sendOptions('/system/persist', 'modes');
        end

        function tSamplingRates = getSamplingRates(obj)
            tSamplingRates = obj.sendGet('/processor/samprate');
            
            devices = fieldnames(tSamplingRates);
            newStruct = struct();
            for i = 1:numel(devices)
                oldField = devices{i};
                newField = obj.device2field(oldField);
                [newStruct.(newField)] = tSamplingRates.([oldField]);
            end
            tSamplingRates = newStruct;
        end
        
        function sGizmoParent = getGizmoParent(obj, sGizmoName)
            sGizmoParent = obj.sendGet(['/experiment/processor/' sGizmoName], 'processor');
            sGizmoParent = obj.device2field(sGizmoParent);
        end
        
        function cExperiments = getKnownExperiments(obj)
            cExperiments = obj.sendOptions('/experiment/name', 'experiments');
        end

        function cSubjects = getKnownSubjects(obj)
            cSubjects = obj.sendOptions('/subject/name', 'subjects');
        end

        function cUsers = getKnownUsers(obj)
            cUsers = obj.sendOptions('/user/name', 'users');
        end

        function sExperiment = getCurrentExperiment(obj)
            sExperiment = obj.sendGet('/experiment/name', 'experiment');
        end

        function sSubject = getCurrentSubject(obj)
            sSubject = obj.sendGet('/subject/name', 'subject');
        end

        function sUser = getCurrentUser(obj)
            sUser = obj.sendGet('/user/name', 'user');
        end

        function sTank = getCurrentTank(obj)
            sTank = obj.sendGet('/tank/name', 'tank');
        end

        function sBlock = getCurrentBlock(obj)
            sBlock = obj.sendGet('/block/name', 'block');
            if sBlock == 0
                if obj.getMode() < 2
                    warning('Synapse is not in a run time mode')
                end
            end
        end

        function sMode = getPersistMode(obj)
            sMode = obj.sendGet('/system/persist', 'mode');
        end
        
        function cTanks = getKnownTanks(obj)
            cTanks = obj.sendOptions('/tank/name', 'tanks');
        end

        function cBlocks = getKnownBlocks(obj)
            cBlocks = obj.sendOptions('/block/name', 'blocks');
        end

        function bSuccess = createTank(obj, sTankPath)
            bSuccess = obj.sendPut('/tank/path', obj.struct2json(struct('tank', sTankPath)));
        end

        function bSuccess = createSubject(obj, sName, varargin)
            if numel(varargin) == 0
                desc = '';
                icon = 'mouse';
            elseif numel(varargin) == 2
                desc = varargin{1};
                icon = varargin{2};
            else
                error('createSubject accepts 0 or 2 optional arguments')
            end
            bSuccess = obj.sendPut('/subject/name/new', obj.struct2json(struct('subject', sName, 'desc', desc, 'icon', icon)));
        end
        
        function bSuccess = setCurrentExperiment(obj, sExperiment)
            bSuccess = obj.sendPut('/experiment/name', obj.struct2json(struct('experiment', sExperiment)));
        end
        
        function bSuccess = setCurrentSubject(obj, sSubject)
            bSuccess = obj.sendPut('/subject/name', obj.struct2json(struct('subject', sSubject)));
        end
        
        function bSuccess = setCurrentUser(obj, sUser, varargin)
            if numel(varargin) < 1
                password = '';
            else
                password = varargin{1};
            end
            bSuccess = obj.sendPut('/user/name', obj.struct2json(struct('user', sUser, 'pwd', password)));
        end

        function bSuccess = setCurrentTank(obj, sTank)
            bSuccess = obj.sendPut('/tank/name', obj.struct2json(struct('tank', sTank)));
        end

        function bSuccess = setCurrentBlock(obj, sBlock)
            bSuccess = obj.sendPut('/block/name', obj.struct2json(struct('block', sBlock)));
        end
        
        function bSuccess = setPersistMode(obj, sMode)
            if ~any(cellfun(@(x)strcmp(x, sMode), obj.PERSIST))
                error('Allowed persistences are: ''Best'', ''Last'', or ''Fresh''')
            end
            bSuccess = obj.sendPut('/system/persist', obj.struct2json(struct('mode', sMode)));
        end

        function cNotes = getExperimentMemos(obj, sExperiment, varargin)
            % cNotes = syn.getExperimentMemos(obj, sExperiment, 'parameter', value,...)
            % 'parameter', value pairs
            %    'STARTTIME'  double, filter by log time stamp (%Y%m%d%H%M%S)
            %    'ENDTIME'    double, filter by log time stamp (%Y%m%d%H%M%S)
            % filtering is inclusive. all memos for experiment are returned if no filter given
            
            STARTTIME = -1;
            ENDTIME = -1;
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end

            reqStr = ['/experiment/notes/' sExperiment];
            if STARTTIME > 2e13 || ENDTIME > 2e13
                reqStr = [reqStr '/range/'];
                if STARTTIME == -1
                    reqStr = [reqStr '00000000000000/'];
                else
                    reqStr = [reqStr num2str(STARTTIME) '/'];
                end
                if ENDTIME == -1
                    reqStr = [reqStr '00000000000000'];
                else
                    reqStr = [reqStr num2str(ENDTIME)];
                end
            end

            cNotes = obj.sendGet(reqStr, 'notes');
        end

        function cNotes = getSubjectMemos(obj, sSubject, varargin)
            % cNotes = syn.getSubjectMemos(obj, sSubject, 'parameter', value,...)
            % 'parameter', value pairs
            %    'STARTTIME'  double, filter by log time stamp (%Y%m%d%H%M%S)
            %    'ENDTIME'    double, filter by log time stamp (%Y%m%d%H%M%S)
            % filtering is inclusive. all memos for subject are returned if no filter given
            
            STARTTIME = -1;
            ENDTIME = -1;
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end

            reqStr = ['/subject/notes/' sSubject];
            if STARTTIME > 2e13 || ENDTIME > 2e13
                reqStr = [reqStr '/range/'];
                if STARTTIME == -1
                    reqStr = [reqStr '00000000000000/'];
                else
                    reqStr = [reqStr num2str(STARTTIME) '/'];
                end
                if ENDTIME == -1
                    reqStr = [reqStr '00000000000000'];
                else
                    reqStr = [reqStr num2str(ENDTIME)];
                end
            end

            cNotes = obj.sendGet(reqStr, 'notes');
        end

        function cNotes = getUserMemos(obj, sUser, varargin)
            % cNotes = syn.getUserMemos(obj, sUser, 'parameter', value,...)
            % 'parameter', value pairs
            %    'STARTTIME'  double, filter by log time stamp (%Y%m%d%H%M%S)
            %    'ENDTIME'    double, filter by log time stamp (%Y%m%d%H%M%S)
            % filtering is inclusive. all memos for user are returned if no filter given
            
            STARTTIME = -1;
            ENDTIME = -1;
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end

            reqStr = ['/user/notes/' sUser];
            if STARTTIME > 2e13 || ENDTIME > 2e13
                reqStr = [reqStr '/range/'];
                if STARTTIME == -1
                    reqStr = [reqStr '00000000000000/'];
                else
                    reqStr = [reqStr num2str(STARTTIME) '/'];
                end
                if ENDTIME == -1
                    reqStr = [reqStr '00000000000000'];
                else
                    reqStr = [reqStr num2str(ENDTIME)];
                end
            end

            cNotes = obj.sendGet(reqStr, 'notes');
        end
        
        function bSuccess = appendSubjectMemo(obj, sSubject, sMemo)
            bSuccess = obj.sendPut('/subject/notes', obj.struct2json(struct('experiment', sSubject, 'memo', sMemo)));
        end

        function bSuccess = appendUserMemo(obj, sUser, sMemo)
            bSuccess = obj.sendPut('/user/notes', obj.struct2json(struct('experiment', sUser, 'memo', sMemo)));
        end

        function bSuccess = appendExperimentMemo(obj, sExperiment, sMemo)
            bSuccess = obj.sendPut('/experiment/notes', obj.struct2json(struct('experiment', sExperiment, 'memo', sMemo)));
        end

    end
end