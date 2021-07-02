classdef TDEV < handle
    %TDEV  TDevAccX wrapper
    %   obj = TDEV() connects to Workbench server
    %
    %   obj.TD   TDevAccX object
    %
    %   obj = TDEV('parameter',value,...)
    %
    %   'parameter', value pairs
    %      'SERVER'  string, data tank server (default 'Local')
    %      'VERBOSE'    bool, show log statements (default true)
    %
    %   Set Workbench mode:
    %      obj.idle
    %      obj.standby
    %      obj.preview
    %      obj.run (or obj.record)
    %
    %   Get Workbench mode:
    %      mode = obj.mode
    %
    %   Set Tank name:
    %      obj.set_tank('NewTankName')
    %
    %   Get Tank name:
    %     tank_name = obj.tank
    %
    %   Write to parameter tag:
    %      result = obj.write(TAGNAME, VALUE), where TAGNAME and VALUE
    %      are strings, write the value(s) to parameter tag
    %
    %      result   1 if successful, 0 otherwise
    %
    %      result = obj.write(TAGNAME,VALUE,'parameter',value,...)
    %
    %      'parameter', value pairs
    %          'DEVICE'  string, name of device. If missing, the
    %                    previously used device_name will be used.
    %                    If set, this will become the new default
    %          'FORMAT'  string, destination format (array only)
    %                    options are 'F32' (default) 'I32' 'I16' 'I8'
    %          'OFFSET'  scalar, offset into buffer (array only).
    %                    default is 0.
    %
    %   Read parameter tag:
    %      value = obj.read(TAGNAME), where TAGNAME is a string, reads
    %      the values from parameter tag
    %
    %      value   value(s) read from hardware tag
    %
    %      obj.read(TAGNAME,'parameter',value,...)
    %
    %      'parameter', value pairs
    %          'DEVICE'  string, name of device. If missing, the
    %                    previously used device_name will be used.
    %                    If set, this will become the new default
    %          'SOURCE'  string, source format (array only)
    %                    options are 'F32' (default) 'I32' 'I16' 'I8'
    %          'DEST'    string, destination format (array only)
    %                    options are 'F64' 'F32' (default) 'I32' 'I16' 'I8'
    %          'SIZE'    scalar, number of words to read (array only).
    %                    default is the entire buffer.
    %          'OFFSET'  scalar, offset into buffer (array only).
    %                    default is 0.
    %          'NCHAN'   scalar, number of channels in buffer (array
    %                    only). Used for de-interlacing data. Default is 1.
    %
    
    properties
        % default parameters
        SERVER = 'Local';
        VERBOSE = 1;
        TD;
        DEVICE_NAMES = {};
        DEVICE_TYPES = {};
        DEVICE_RCOS = {};
        PARTAG = {};
        FS = {};
    end
    properties % (SetAccess=private)
        DEVICE_NAME = '';
        DEVICE_TYPE = '';
        MODES = {'Idle', 'Standby', 'Preview', 'Run'};
    end
    
    methods %(Access=private)
        function obj = setup(obj)
            % create map of tags and their sizes for all devices
            types = [68 73 76 80 83 65];
            obj.PARTAG = {};
            obj.FS = {};
            ind1 = 1;
            for nm = obj.DEVICE_NAMES
                nm = nm{1};
                obj.PARTAG{ind1} = {};
                ind2 = 1;
                for i = types
                    tag_name = obj.TD.GetNextTag(nm, i, 1);
                    while ~strcmp(tag_name, '')
                        tn = [nm '.' tag_name];
                        obj.PARTAG{ind1}{ind2}.tag_size = obj.TD.GetTargetSize(tn);
                        obj.PARTAG{ind1}{ind2}.tag_type = char(obj.TD.GetTargetType(tn));
                        obj.PARTAG{ind1}{ind2}.tag_name = tag_name;
                        tag_name = obj.TD.GetNextTag(nm, i, 0);
                        ind2 = ind2 + 1;
                    end
                end
                obj.FS = cat(2, obj.FS, obj.TD.GetDeviceSF(nm));
                ind1 = ind1 + 1;
            end
        end
        
        function obj = set_mode(obj, new_mode)
            mode_str = obj.MODES{new_mode+1};
            if new_mode == obj.mode()
                warning(['Workbench is already in ' mode_str ' mode']);
                if new_mode > 0 && isempty(obj.FS)
                    obj.setup();
                end
                return
            end
            if obj.VERBOSE
                disp(['Switching to ' mode_str ' mode'])
            end
            result = obj.TD.SetSysMode(new_mode);
            if result == 0
                warning('System mode change failed')
                return
            end
            ct = 0; tic;
            while obj.mode() ~= new_mode
                pause(.1); ct = ct + 1;
                if ct >= 50 && ~mod(ct,20)
                    warning('System mode hasn''t changed after %.1f seconds', toc);
                end
            end
            if new_mode > 0
                obj.setup();
            end
        end
    end
    
    methods
        
        function obj = TDEV(varargin)
            if nargin > 1
                % parse varargin
                for i = 1:2:length(varargin)
                    eval(['obj.' upper(varargin{i}) '=varargin{i+1};']);
                end
            end
            
            %First instantiate a variable for the ActiveX wrapper interface
            obj.TD = actxserver('TDevAcc.X');
            
            % Then connect to a server
            device_name = '';
            while strcmp(device_name, '')
                if obj.TD.ConnectServer('Local') ~= 1
                    error('%s OpenEx server not found', obj.SERVER);
                end
                device_name = obj.TD.GetDeviceName(0);
                pause(0.1)
            end
            obj.DEVICE_NAMES = {};
            obj.DEVICE_RCOS = {};
            obj.DEVICE_TYPES = {};
            ind = 1;
            while ~strcmp(device_name,'')
                obj.DEVICE_TYPE = obj.TD.GetDeviceType(device_name);
                obj.DEVICE_TYPES = cat(2, obj.DEVICE_TYPES, obj.DEVICE_TYPE);
                obj.DEVICE_RCOS = cat(2, obj.DEVICE_RCOS, obj.TD.GetDeviceRCO(obj.DEVICE_NAME));
                obj.DEVICE_NAMES = cat(2, obj.DEVICE_NAMES, device_name);
                
                device_name = obj.TD.GetDeviceName(ind);
                ind = ind + 1;
            end
            if strcmp(obj.DEVICE_NAME,'')
                obj.DEVICE_NAME = obj.DEVICE_NAMES{1};
            end
            if obj.VERBOSE
                disp(['using Workbench device ' obj.DEVICE_NAME]);
            end
            if obj.mode()
                obj.setup();
            end
        end
        
        % print all tag names
        function tags(obj)
            tags = obj.PARTAG{1};
            for i = 1:numel(tags)
                t = tags{1,i};
                if t.tag_size > 1
                    fprintf('%s\t%s\t%d\n', t.tag_type, t.tag_name, t.tag_size)
                else
                    fprintf('%s\t%s\n', t.tag_type, t.tag_name)
                end
            end
        end
        
        function tankname = tank(obj)
            tankname = obj.TD.GetTankName();
        end
        
        function obj = preview(obj)
            obj.set_mode(2);
        end
        
        function obj = run(obj)
            obj.set_mode(3);
        end
        
        function obj = record(obj)
            obj.set_mode(3);
        end
        
        function obj = idle(obj)
            obj.set_mode(0);
        end
        
        function obj = standby(obj)
            obj.set_mode(1);
        end
        
        function result = mode(obj)
            result = obj.TD.GetSysMode();
        end
        
        function result = status(obj)
            result = obj.TD.CheckServerConnection();
        end
        
        function obj = set_tank(obj, new_tank)
            if obj.mode() > 1
                warning('Workbench is running and can''t change tank, switch to Idle or Standby first');
                return
            end
            result = obj.TD.SetTankName(new_tank);
            if result == 1 && strcmp(obj.tank(), new_tank)
                if obj.VERBOSE
                    disp(['New tank name is ' new_tank]);
                end
            else
                disp('Error setting new tank name');
            end
        end
        
        function result = trig(obj, tagname, varargin)
            result1 = obj.write(tagname, 1, varargin{:});
            pause(.1)
            result2 = obj.write(tagname, 0, varargin{:});
            result = result1 & result2;
        end
        
        function result = write(obj, tagname, value, varargin)
            
            % defaults
            FORMAT = 'F32';
            OFFSET = 0;
            DEVICE = obj.DEVICE_NAME;
            old_device_name = obj.DEVICE_NAME;
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end
            
            obj.DEVICE_NAME = DEVICE;
            
            % check if tagname is in PARTAG property and get array size
            sz = obj.find('partag', DEVICE, tagname);
   
            % if array is not a row, make it a row
%           % not R2007b compatible
%             if iscolumn(value)
%                 value = value';
%             end
%             if ~isrow(value)
%                 error('array must be single row or column')
%             end
            if size(value,2) == 1
                value = value';
            end
            if ~(size(value, 1) == 1)
                error('array must be single row or column')
            end
            
            if numel(value) > sz
                error('Number of elements (%d) larger than tag %s can hold (%d)', numel(value), tagname, sz);
            end
            
            target = [obj.DEVICE_NAME '.' tagname];
            if isscalar(value)
                result = obj.TD.SetTargetVal(target, value);
            else
                if OFFSET > sz
                    error('Offset (%d) larger than %s tag size (%d)', OFFSET, tagname, sz);
                end
                result = obj.TD.WriteTargetVEX(target, OFFSET, FORMAT, value);
            end
        end
        
        function value = read(obj, tagname, varargin)
            % defaults
            SOURCE = 'F32';
            DEST = 'F32';
            SIZE = -1;
            OFFSET = 0;
            NCHAN = 1;
            DEVICE = obj.DEVICE_NAME;
            old_device_name = obj.DEVICE_NAME;
            
            % parse varargin
            for i = 1:2:length(varargin)
                eval([upper(varargin{i}) '=varargin{i+1};']);
            end
            
            obj.DEVICE_NAME = DEVICE;
            
            % check if device name exists
            sz = obj.find('partag', DEVICE, tagname);

            if SIZE == -1
                SIZE = sz - OFFSET;
            end
            
            if OFFSET > SIZE
                error('Offset (%d) > %s tag size (%d)', OFFSET, tagname, SIZE);
            end
            
            % do the actual reading
            tag = [obj.DEVICE_NAME '.' tagname];
            value = obj.TD.ReadTargetVEX(tag, OFFSET, SIZE, SOURCE, DEST);
        end
        
        function result = find(obj, attr, device, varargin)
            tagname = '';
            if numel(varargin) > 0
                tagname = varargin{1};
            end
            result = -1;
            target = -1;
            for i = 1:numel(obj.DEVICE_NAMES)
                if strcmp(obj.DEVICE_NAMES{i}, device)
                    target = i;
                end
            end
            if target == -1
                error('Device %s not found', device);
            end
            
            if strcmpi(attr, 'fs')
                if numel(obj.FS) >= target
                    result = obj.FS{target};
                end    
            elseif strcmpi(attr, 'device_type')
                if numel(obj.DEVICE_TYPES) >= target
                    result = obj.DEVICE_TYPES{target};
                end
            elseif strcmpi(attr, 'device_rco')
                if numel(obj.DEVICE_RCOS) >= target
                    result = obj.DEVICE_RCOS{target};
                end
            elseif strcmpi(attr, 'partag')
                % check if tagname is in PARTAG property and get array size
                if numel(obj.PARTAG) < target
                    return
                end
                tags = obj.PARTAG{target};
                tagind = -1;
                for i = 1:numel(tags)
                    if strcmp(tags{i}.tag_name, tagname)
                        tagind = i;
                        result = tags{i}.tag_size;
                    end
                end
                if tagind == -1
                    error('Tag name %s not found', tagname);
                end
            end
        end
            
        function delete(obj)
            obj.TD.CloseConnection();
        end
    end
end