classdef SynapseLive < handle
    %SynapseLive  TDT online data streamer.
    %   obj = SynapseLive() connects to TTank server and opens currently
    %   recording block in Synapse
    %
    %   obj.data    reference to all available data from block
    %   obj.update  get latest data from current block
    %   obj.TT      reference to TTankX object, if custom calls are needed
    %
    
    properties
        TT;
        SYN;
        SERVER = 'Local';
        NAME = 'Matlab';
        TANK = '';
        BLOCK = '';
        TYPE = [2 3 4 5]; % see TDT2mat help for TYPE information
        MAXEVENTS = 1e6;
        TIMESTAMPSONLY = false; % see TDT2mat help for NODATA
        NEWONLY = 1; % only return new data, otherwise return all data.
        VERBOSE = 1;
        CURRTIME = 0; % placeholders for time filters
        PREVTIME = 0; % placeholders for time filters
        T1 = 0;
        T2 = 0;
        data = [];
    end
    methods
        function obj = SynapseLive(varargin)

            MODE = '';
            EXPERIMENT = '';
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end
            
            obj.SYN = SynapseAPI('localhost');
            
            if ~strcmp(EXPERIMENT, '')
                if ~strcmp(obj.SYN.getCurrentExperiment(), EXPERIMENT)
                    obj.SYN.setModeStr('Idle');
                    pause(1);
                    if obj.SYN.setCurrentExperiment(EXPERIMENT) == 0
                        error('trouble loading experiment %s', EXPERIMENT);
                    end
                end
            end
            if ~strcmp(MODE, '')
                if ~strcmp(obj.SYN.getModeStr(), MODE)
                    obj.SYN.setModeStr(MODE);
                    pause(3);
                end
            end
            
            if obj.SYN.getMode() < 2
                error('Synapse not currently recording.\nTry using SynapseLive(''Preview'') or SynapseLive(''Record'') to set the system mode','');
            end
            
            obj.TANK = obj.SYN.getCurrentTank();
            obj.BLOCK = obj.SYN.getCurrentBlock();
            
            % create TTankX object
            obj.TT = actxserver('TTank.X');
            
            % connect to server
            if obj.TT.ConnectServer(obj.SERVER, obj.NAME) ~= 1
                error(['Problem connecting to server: ' obj.SERVER])
            end
            
            % open tank
            if obj.TT.OpenTank(obj.TANK, 'r') ~= 1
                obj.TT.ReleaseServer;
                error(['Problem opening tank: ' obj.TANK]);
            end
            
            % select block            
            if obj.TT.SelectBlock(obj.BLOCK) ~= 1
                error('Problem selecting current block');
            else
                disp(['Connected to TANK: ' obj.TANK ', BLOCK: ' obj.BLOCK]);
            end

            % wait until data is available, which is after the cache delay
            % time has elapsed
            fprintf('Waiting for initial data...');
            x = obj.TT.GetValidTimeRangesV();
            while isnan(x)
                 fprintf('.');
                 pause(.5)
                 x = obj.TT.GetValidTimeRangesV();
            end
            
            fprintf('done\n');
        end
        
        function delete(obj)
            %obj.TT.CloseTank;
            %obj.TT.ReleaseServer;
        end
        
        function result = get_data(obj, storename)
            types = {'epocs', 'scalars', 'snips', 'streams'};
            result = nan;
            for x = types
                type = x{1};
                if ~isstruct(obj.data.(type))
                    continue
                end
                if ~isfield(obj.data.(type), storename)
                    continue
                end
                result = obj.data.(type).(storename);
                return
            end
        end
        
        function obj = update(obj)
            
            % get latest data
            x = obj.TT.GetValidTimeRangesV();
            
            if numel(x) == 1
                pause(.5)
                if obj.SYN.getMode() == 0
                    disp('Block has stopped.')
                    obj = [];
                    return
                else
                    error('Valid Time Range is NaN')
                end
            end
            
            obj.CURRTIME = x(2);
            if obj.NEWONLY
                obj.T1 = obj.PREVTIME;
            else
                obj.T1 = 0;
            end
            obj.T2 = obj.CURRTIME;
            
            obj.data = TDT2mat(...
                obj.TANK, ...
                obj.BLOCK, ...
                'VERBOSE', false, ...
                'TTX', obj.TT, ...
                'TYPE', obj.TYPE, ...
                'T1', obj.T1, ...
                'T2', obj.T2, ...
                'NODATA', obj.TIMESTAMPSONLY ...
                );
            obj.PREVTIME = obj.CURRTIME;
            
            % reset globals (do this inside TDT2mat?)
            obj.TT.SetGlobalV('T1', 0);
            obj.TT.SetGlobalV('T2', 0);
            
            % TODO: trim zeros from end of streams that were added by 
            % ReadWavesV?
            %for f = fields(t.data.streams)'
            %    name = f{:};
            %    obj.data.streams.(name).data
            %    if obj.data.streams.(name).data(1,end) == 0
            %end   
            
            %TODO: display # of read events if obj.VERBOSE
        end
    end
end