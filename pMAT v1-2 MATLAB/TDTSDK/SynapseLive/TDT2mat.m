function data = TDT2mat(tank, block, varargin)
%TDT2MAT  TDT tank data extraction.
%   data = TDT2mat(TANK, BLOCK), where TANK and BLOCK are strings, retrieve
%   all data from specified block in struct format.
%
%   data = TDT2mat(BLOCKPATH), where BLOCKPATH is the folder location of 
%   the block
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   raw data, and sampling rate)
%   data.streams    contains all continuous data (sampling rate and raw
%                   data)
%   data.scalars    contains all scalar data (samples and timestamps)
%   data.info       contains additional information about the block
%
%   data = TDT2mat(TANK, BLOCK,'parameter',value,...)
%
%   'parameter', value pairs
%      'SERVER'     string, data tank server (default = 'Local')
%      'T1'         scalar, retrieve data starting at T1 (default = 0 for
%                       beginning of recording)
%      'T2'         scalar, retrieve data ending at T2 (default = 0 for end
%                       of recording). Can be negative to remove time from
%                       end of recording.
%      'SORTNAME'   string, specify sort ID to use when extracting snippets
%      'VERBOSE'    boolean, set to false to disable console output
%      'TYPE'       array of scalars or cell array of strings, specifies 
%                       what type of data stores to retrieve from the tank
%                   1: all (default)
%                   2: epocs
%                   3: snips
%                   4: streams
%                   5: scalars
%                   TYPE can also be cell array of any combination of 
%                       'epocs', 'streams', 'scalars', 'snips', 'all'
%                   examples:
%                       data = TDT2mat('MyTank','Block-1','TYPE',[1 2]);
%                           > returns only epocs and snips
%                       data = TDT2mat('MyTank','Block-1','TYPE',{'epocs','snips'});
%                           > returns only epocs and snips
%      'BITWISE'    string, specify an epoc store or scalar store that 
%                       contains individual bits packed into a 32-bit 
%                       integer. Onsets/offsets from individual bits will
%                       be extracted.
%      'RANGES'     array of valid time range column vectors
%      'NODATA'     boolean, only return timestamps, channels, and sort 
%                       codes for snippets, no waveform data (default = false)
%      'STORE'      string, specify a single store to extract
%                   cell of strings, specify cell arrow of stores to extract
%      'CHANNEL'    integer, choose a single channel to extract from stream
%                       or snippet events (default = 0 for all channels).
%      'TTX'        COM.TTank_X object that is already connected to a tank/block
%      'JUSTBLOCKS' boolean, only return block names for given tank name
%                       (default = false)
%

data = struct('epocs', [], 'snips', [], 'streams', [], 'scalars', []);

% defaults
T1       = 0;
T2       = 0;
RANGES   = [];
VERBOSE  = 1;
TYPE     = 1;
SORTNAME = 'TankSort';
SERVER   = 'Local';
NODATA   = false;
CHANNEL  = 0;
STORE    = '';
BITWISE  = '';
TTX      = [];
JUSTBLOCKS = false;

MAXEVENTS = 1e6;
MAXCHANNELS = 1024;

% put the slashes in the correct direction.
tank = strrep(tank, '/', '\');
if tank(end) == '\'
    tank(end) = [];
end
    
% if block wasn't passed, extract it from tank path
if mod(nargin, 2) == 1
    if exist('block', 'var')
        varargin = {block, varargin{:}};
    end
    sss = strfind(tank, filesep);
    block = tank(sss(end)+1:end);
    tank = tank(1:sss(end)-1);
end

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

ALLOWED_TYPES = {'ALL','EPOCS','SNIPS','STREAMS','SCALARS'};

if iscell(TYPE)
    types = zeros(1, numel(TYPE));
    for i = 1:numel(TYPE)
        ind = find(strcmpi(ALLOWED_TYPES, TYPE{i}));
        if isempty(ind)
            error('Unrecognized type: %s\nAllowed types are: %s', TYPE{i}, sprintf('%s ', ALLOWED_TYPES{:}))
        end
        if ind == 1
            types = 1:5;
            break;
        end
        types(i) = ind;
    end
else
    if ~isnumeric(TYPE), error('TYPE must be a scalar, number vector, or cell array of strings'), end
    if TYPE == 1
        types = 1:5;
    else
        types = TYPE;
    end
end
TYPE = unique(types);

ReadEventsOptions = 'ALL';
if NODATA, ReadEventsOptions = 'NODATA'; end
if ~isscalar(CHANNEL), error('CHANNEL must be a scalar'), end
if CHANNEL < 0, error('CHANNEL must be non-negative'), end
CHANNEL = int32(CHANNEL);

bUseOutsideTTX = ~isempty(TTX);

if ~bUseOutsideTTX
    % create TTankX object
    try
        TTX = actxserver('TTank.X');
    catch ME
        if (strcmp(ME.identifier,'MATLAB:COM:InvalidProgid'))
            error(sprintf('TTankX ActiveX control not found.\nMake sure OpenDeveloper is installed, reboot your computer, and try again'));
        end
        rethrow(ME)
    end

    % connect to server
    if TTX.ConnectServer(SERVER, 'TDT2mat') ~= 1
        error(['Problem connecting to server: ' SERVER])
    end
    
    if JUSTBLOCKS
        % return all block names from the tank
        tank = [tank filesep block];
        if TTX.OpenTank(tank, 'R') ~= 1
            error(['Problem opening tank: ' tank]);
        end
        blocks{1} = TTX.QueryBlockName(0);
        i = 1;
        while strcmp(blocks{i}, '') == 0
            i = i+1;
            blocks{i} = TTX.QueryBlockName(i); %#ok<AGROW>
        end
        blocks(end) = [];

        % make sure blocks are in ascending order
        bidx = cellfun(@(x) str2num(x(find(x=='-',1,'last')+1:end)),blocks); %#ok<ST2NM>
        [temp,i] = sort(bidx);
        blocks = blocks(i);

        data = blocks;
        return
    end
    
    % open tank
    if TTX.OpenTank(tank, 'R') ~= 1
        TTX.ReleaseServer;
        error(['Problem opening tank: ' tank]);
    end
    
    % select block
    if TTX.SelectBlock(['~' block]) ~= 1
        block_name = TTX.QueryBlockName(0);
        block_ind = 1;
        while strcmp(block_name, '') == 0
            block_ind = block_ind+1;
            block_name = TTX.QueryBlockName(block_ind);
            if strcmp(block_name, block)
                error(['Block found, but problem selecting it: ' block sprintf('\n') ...
                    'Bad TBK file? Try running the TankRestore tool to correct. See https://www.tdt.com/technotes/#0935.htm']);
            end
        end
        error(['Block not found: ' block]);
    end
end

% set info fields
start = TTX.CurBlockStartTime;
stop = TTX.CurBlockStopTime;
total = stop-start;

if T2 < 0
    T2 = total + T2;
end

data.info.tankpath = TTX.GetTankItem(tank, 'PT');
data.info.blockname = block;
data.info.date = TTX.FancyTime(start, 'Y-O-D');
data.info.starttime = TTX.FancyTime(start, 'H:M:S');
data.info.stoptime = TTX.FancyTime(stop, 'H:M:S');
if stop > 0
    data.info.duration = TTX.FancyTime(total, 'H:M:S');
end
data.info.streamchannel = CHANNEL;
data.info.snipchannel = CHANNEL;

%data.info.notes = {};

%ind = 1;
%note = TTX.GetNote(ind);
%while ~strcmp(note, '')
%    data.info.notes{ind} = note;
%    ind = ind + 1;
%    note = TTX.GetNote(ind);
%end

if VERBOSE
    fprintf('\nTank Name:\t%s\n', tank);
    fprintf('Tank Path:\t%s\n', data.info.tankpath);
    fprintf('Block Name:\t%s\n', data.info.blockname);
    fprintf('Start Date:\t%s\n', data.info.date);
    fprintf('Start Time:\t%s\n', data.info.starttime);
    if stop > 0
        fprintf('Stop Time:\t%s\n', data.info.stoptime);
        fprintf('Total Time:\t%s\n', data.info.duration);
    else
        fprintf('==Block currently recording==\n');
    end
end

% set global tank server defaults
TTX.SetGlobalV('WavesMemLimit',1e7);
TTX.SetGlobalV('MaxReturn',MAXEVENTS);
TTX.SetGlobalV('T1', T1);
TTX.SetGlobalV('T2', T2);

ranges_size = size(RANGES,2);

if ranges_size > 0
    data.time_ranges = RANGES;
else
    data.time_ranges = [0;Inf];
end

% parse stores
lStores = TTX.GetEventCodes(0);
for i = 1:length(lStores)
    name = TTX.CodeToString(lStores(i));
    if VERBOSE, fprintf('\nStore Name:\t%s\n', name); end
    varname = name;
    for ii = 1:numel(varname)
        if ii == 1
            if ~isstrprop(varname(ii), 'alpha')
                varname = ['x' varname];
            end
        end
        if ~isstrprop(varname(ii), 'alphanum')
            varname(ii) = '_';
        end
    end
    %TODO: use this instead in 2014+
    %varname = matlab.lang.makeValidName(name);
    if ~isvarname(name) && VERBOSE
        warning('%s is not a valid Matlab variable name, changing to %s', name, varname);
    end
    
    if ~strcmp(name, 'xWav')
        if TTX.GetCodeSpecs(lStores(i))
            type = TTX.EvTypeToString(TTX.EvType);
        else
            TTX.GetCodeSpecsLazy(lStores(i));
            type = TTX.EvTypeToString(TTX.EvType);
        end
        % catch RS4 header (33073)
        if bitand(TTX.EvType, 33025) == 33025, type = 'Stream'; end
    else
        type = 'Stream';
    end     
    
    if VERBOSE, fprintf('EvType:\t\t%s\n', type); end
    
    switch type
        case 'Strobe+'
            if ~any(TYPE==2)
                if VERBOSE, disp('skipping'), end
                continue
            end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            
            if ranges_size > 0
                for ff = 1:ranges_size
                    d = TTX.GetEpocsV(name, RANGES(1, ff), RANGES(2, ff), MAXEVENTS)';
                    if ~any(isnan(d))
                        data.epocs.(varname).data{ff} = d(:,1);
                        data.epocs.(varname).onset{ff} = d(:,2);
                        %data.epocs.(name).note{ff} = zeros(size(d(:,2))); % TODO: fix
                        if d(:,3) == zeros(size(d(:,3)))
                            d(:,3) = [d(2:end,2); inf];
                        end
                        data.epocs.(name).offset{ff} = d(:,3);
                    end
                end
                if ~isfield(data.epocs, varname), continue; end
                data.epocs.(varname).data = cat(1, data.epocs.(varname).data{:});
                data.epocs.(varname).onset = cat(1, data.epocs.(varname).onset{:});
                data.epocs.(varname).offset = cat(1, data.epocs.(varname).offset{:});
                %data.epocs.(name).note = zeros(size(data.epocs.(name).offset)); % TODO: fix
                
                % get rid of Infs in middle of data set
                ind = strfind(data.epocs.(varname).offset', Inf);
                ind = ind(ind < size(data.epocs.(varname).offset,1));
                data.epocs.(varname).offset(ind) = data.epocs.(varname).onset(min(size(data.epocs.(varname).onset,1),ind+1));
            else
                d = TTX.GetEpocsV(name, T1, T2, MAXEVENTS)';
                if numel(d) == 1  % store exists but there are no timestamps (nan?)
                    data.epocs.(varname).data = d;
                    data.epocs.(varname).onset = d;
                    data.epocs.(varname).offset = d;
                    %data.epocs.(name).note = d; % TODO: check
                else
                    data.epocs.(varname).data = d(:,1);
                    data.epocs.(varname).onset = d(:,2);
                    if d(:,3) == zeros(size(d(:,3)))
                        d(:,3) = [d(2:end,2); inf];
                    end
                    data.epocs.(varname).offset = d(:,3);
                    %data.epocs.(name).note = zeros(size(d(:,3))); % TODO: default
                end
            end
            data.epocs.(varname).name = name;
        case 'Scalar'
            if ~any(TYPE==5)
                if VERBOSE, disp('skipping'), end
                continue
            end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            if ranges_size > 0
                for ff = 1:ranges_size
                    TTX.SetGlobalV('T1', RANGES(1, ff));
                    TTX.SetGlobalV('T2', RANGES(2, ff));
                    
                    N = TTX.ReadEventsSimple(name);
                    if N > 0
                        data.scalars.(varname).data{ff} = TTX.ParseEvV(0, N)'';
                        data.scalars.(varname).ts{ff} = TTX.ParseEvInfoV(0, N, 6)'';
                        channels = TTX.ParseEvInfoV(0, N, 4)'';
                        
                        % reorganize data array by channel
                        maxchannel = max(channels);
                        newdata = zeros(maxchannel, numel(data.scalars.(varname).data{ff})/maxchannel);
                        for xx = 1:maxchannel
                            arr = data.scalars.(varname).data{ff};
                            newdata(xx,:) = arr(channels == xx);
                        end
                        data.scalars.(varname).data{ff} = newdata;
                        
                        % decimate timestamps, only use channel 1
                        os = data.scalars.(varname).ts{ff};
                        data.scalars.(varname).ts{ff} = os(channels == 1);
                        clear newdata;
                    end
                end
                % reset T1, T2
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                
                if ~isfield(data.scalars, varname), continue; end
                data.scalars.(varname).data = cat(2, data.scalars.(varname).data{:});
                data.scalars.(varname).ts = cat(2, data.scalars.(varname).ts{:});
            else
                N = TTX.ReadEventsSimple(name);
                if N > 0
                    if N == MAXEVENTS
                        if VERBOSE, fprintf('Max Total Events (%d) Reached. Looping through time\n', MAXEVENTS), end
                        firstloop = 1;

                        time_slices = 10;
                        if T2 < 0.00001, T2 = total + 3; end
                        dT = (T2-T1)/time_slices;
                        currT1 = T1;
                        currT2 = currT1+dT;
                        for dt = 1:time_slices+1
                            NTIME = TTX.ReadEventsV(MAXEVENTS, name, CHANNEL, 0, currT1, currT2, ReadEventsOptions);
                            if NTIME > 0
                                if NTIME == MAXEVENTS
                                    warning(sprintf('Max Events (%d) reached on time slice %d, contact TDT\n', MAXEVENTS, dt));
                                else
                                    if firstloop
                                        if ~NODATA
                                            data.scalars.(varname).data = TTX.ParseEvV(0, NTIME)';
                                        end
                                        channels = TTX.ParseEvInfoV(0, NTIME, 4)';
                                        data.scalars.(varname).ts = TTX.ParseEvInfoV(0, NTIME, 6)';
                                        firstloop = 0;
                                    else
                                        if ~NODATA
                                            data.scalars.(varname).data = cat(1, data.scalars.(varname).data, TTX.ParseEvV(0, NTIME)');
                                        end
                                        channels = cat(1, channels, TTX.ParseEvInfoV(0, NTIME, 4)');
                                        data.scalars.(varname).ts = cat(1, data.scalars.(varname).ts, TTX.ParseEvInfoV(0, NTIME, 6)');
                                    end
                                end
                            end
                            currT1 = currT2;
                            currT2 = currT1+dT;
                        end
                    else
                        data.scalars.(varname).data = TTX.ParseEvV(0, N)'';
                        data.scalars.(varname).ts = TTX.ParseEvInfoV(0, N, 6)'';
                        channels = TTX.ParseEvInfoV(0, N, 4)'';
                    end
                    % organize data by channel
                    maxchannel = max(channels);
                    newdata = zeros(maxchannel, numel(data.scalars.(varname).data)/maxchannel);
                    for xx = 1:maxchannel
                        newdata(xx,:) = data.scalars.(varname).data(channels == xx);
                    end
                    data.scalars.(varname).data = newdata;
                    
                    % decimate timestamps, only use channel 1
                    data.scalars.(varname).ts = data.scalars.(varname).ts(channels == 1);
                    clear newdata;
                end
            end
            if N > 0, data.scalars.(varname).name = name; end
        case 'Stream'
            if ~any(TYPE==4)
                if VERBOSE, disp('skipping'), end
                continue
            end
            
            % if looking for a particular store and this isn't it, skip it
            if iscell(STORE)
                if all(~strcmp(STORE, name)), continue; end
            else
                if ~strcmp(STORE, '') && ~strcmp(STORE, name), continue; end
            end
            
            if VERBOSE, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq), end
            
            % read some events to see how many channels there are
            N = TTX.ReadEventsV(10000, name, 0, 0, 0, 0, 'NODATA');
            if (N < 1), continue; end
            num_channels = max(TTX.ParseEvInfoV(0, N, 4));
            if VERBOSE, fprintf('Channels:\t%d\n', num_channels), end                

            % skip if we don't have this channel in the data store
            if CHANNEL > 0 && num_channels < CHANNEL
                continue
            end
            
            % loop through ranges, if there are any
            TTX.SetGlobalV('Channel', CHANNEL);
            if ranges_size > 0
                for ff = 1:ranges_size
                    TTX.SetGlobalV('T1', RANGES(1, ff));
                    TTX.SetGlobalV('T2', RANGES(2, ff));
                    d = TTX.ReadWavesV(name)';
                    if numel(d) > 1
                        data.streams.(varname).filtered{ff} = d;
                    end
                end
                % reset when done
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                TTX.SetGlobalV('Channel', 0);
            else
                data.streams.(varname).data = TTX.ReadWavesV(name)';
                nancheck = numel(data.streams.(varname).data) == 1;
                if nancheck
                    chunk_size = 2;  % try chunk size 1/2 length
                    if T2 > 0
                        approx_length = ceil((T2-T1) * TTX.EvSampFreq); % samples
                    else
                        approx_length = ceil(total * TTX.EvSampFreq); % samples
                    end

                    try
                        data.streams.(varname).data = zeros(num_channels,approx_length);
                    catch ME
                        if (strcmp(ME.identifier,'MATLAB:nomem'))
                            error(sprintf(['Out of computer memory (RAM) to create stream store array.\n\n' ...
                                'Try using the ''T1'' and ''T2'' parameters to read only between thosetimestamps.\n' ...
                                '\tdata = TDT2mat(tank, block, ''T1'', 0, ''T2'', 100);\n\n' ...
                                'Or use the ''CHANNEL'' and/or ''STORE'' parameters to read a particular stream store and/or channel.\n' ...
                                '\tdata = TDT2mat(tank, block, ''STORE'', ''Wave'');\n' ...
                                '\tdata = TDT2mat(tank, block, ''STORE'', ''Wave'', ''CHANNEL'', 1);\n']));
                        end
                        rethrow(ME)
                    end
                end
                while nancheck
                    step_size = approx_length / TTX.EvSampFreq /chunk_size;
                    warning('ReadWavesV returned NaN for %s, attempting step size %.2f', name, step_size);
                    if step_size < 0.1, error('step size < .1 second, adjust WavesMemLimit'), end
                    ind = 1;
                    for c = 0:chunk_size-1
                        new_T1 = T1 + c*step_size;
                        new_T2 = T1 + (c+1)*step_size;
                        TTX.SetGlobalV('T1', new_T1);
                        TTX.SetGlobalV('T2', new_T2);
                        temp_data = TTX.ReadWavesV(name)';
                        nancheck = numel(temp_data) == 1;
                        if nancheck
                            break;
                        end
                        if CHANNEL ~= 0
                            data.streams.(varname).data(CHANNEL,ind:ind+size(temp_data,2)-1) = temp_data;
                        else
                            data.streams.(varname).data(:,ind:ind+size(temp_data,2)-1) = temp_data;
                        end
                        ind = ind + size(temp_data,2);
                    end
                    chunk_size = chunk_size * 2;
                end
                % reset when done
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                TTX.SetGlobalV('Channel', 0);
            end
            data.streams.(varname).fs = TTX.EvSampFreq;
            data.streams.(varname).name = name;
            if CHANNEL ~= 0
                data.streams.(varname).channel = CHANNEL;
            end
        case 'Snip'
            if ~any(TYPE==3)
                if VERBOSE, disp('skipping'), end
                continue
            end
            if VERBOSE, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq), end
            if VERBOSE, fprintf('Data Size:\t%d\n',TTX.EvDataSize), end
            
            TTX.SetUseSortName(SORTNAME);
            
            if ranges_size > 0
                for ff = 1:ranges_size
                    N = TTX.ReadEventsV(MAXEVENTS, name, CHANNEL, 0, RANGES(1, ff), RANGES(2, ff), ReadEventsOptions);
                    if N > 0
                        if N == MAXEVENTS
                            warning('Max Total Events (%d) Reached during range extraction, contact TDT\n', MAXEVENTS);
                        else
                            if ~NODATA
                                data.snips.(varname).data{ff} = TTX.ParseEvV(0, N)';
                            else
                                data.snips.(varname).data{ff} = [];
                            end
                            data.snips.(varname).chan{ff} = TTX.ParseEvInfoV(0, N, 4)';
                            data.snips.(varname).sortcode{ff} = TTX.ParseEvInfoV(0, N, 5)';
                            data.snips.(varname).ts{ff} = TTX.ParseEvInfoV(0, N, 6)';
                            if ~isfield(data.snips.(varname), 'fs')
                                data.snips.(varname).fs = TTX.ParseEvInfoV(0, 1, 9);
                            end
                        end
                    end
                end
                if ~isfield(data.snips, varname), continue; end
                if ~NODATA
                    data.snips.(varname).data = cat(1, data.snips.(varname).data{:});
                else
                    data.snips.(varname).data = [];
                end
                data.snips.(varname).chan = cat(1, data.snips.(varname).chan{:});
                data.snips.(varname).sortcode = cat(1, data.snips.(varname).sortcode{:});
                data.snips.(varname).ts = cat(1, data.snips.(varname).ts{:});
            else
                N = TTX.ReadEventsV(MAXEVENTS, name, CHANNEL, 0, T1, T2, ReadEventsOptions);
                if N > 0
                    if N == MAXEVENTS && CHANNEL == 0
                        if VERBOSE, fprintf('Max Total Events (%d) Reached. Looping through channels\n', MAXEVENTS), end
                        firstchan = 1;
                        
                        skipct = 0;
                        for chan = 1:MAXCHANNELS
                            NCHAN = TTX.ReadEventsV(MAXEVENTS, name, chan, 0, T1, T2, ReadEventsOptions);
                            if chan == 1
                                if VERBOSE, fprintf('Reading channel %d', chan), end
                            else
                                if VERBOSE, fprintf(' %d', chan), end
                            end
                            if NCHAN > 0
                                if NCHAN == MAXEVENTS
                                    warning(sprintf('Max Events (%d) reached on channel %d. Looping through time..\n', MAXEVENTS, chan));
                                    time_slices = 10;
                                    if T2 < 0.00001, T2 = total + 3; end
                                    dT = (T2-T1)/time_slices;
                                    currT1 = T1;
                                    currT2 = currT1+dT;
                                    for dt = 1:time_slices+1
                                        NTIME = TTX.ReadEventsV(MAXEVENTS, name, chan, 0, currT1, currT2, ReadEventsOptions);
                                        if NTIME > 0
                                            if NTIME == MAXEVENTS
                                                warning(sprintf('Max Events (%d) reached on channel %d time slice %d, contact TDT\n', MAXEVENTS, chan, dt));
                                            else
                                                if firstchan
                                                    if ~NODATA
                                                        data.snips.(varname).data = TTX.ParseEvV(0, NTIME)';
                                                    end
                                                    data.snips.(varname).chan = TTX.ParseEvInfoV(0, NTIME, 4)';
                                                    data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, NTIME, 5)';
                                                    data.snips.(varname).ts = TTX.ParseEvInfoV(0, NTIME, 6)';
                                                    if ~isfield(data.snips.(varname), 'fs')
                                                        data.snips.(varname).fs = TTX.ParseEvInfoV(0, 1, 9);
                                                    end
                                                    firstchan = 0;
                                                else
                                                    if ~NODATA
                                                        data.snips.(varname).data = cat(1, data.snips.(varname).data, TTX.ParseEvV(0, NTIME)');
                                                    end
                                                    data.snips.(varname).chan = cat(1, data.snips.(varname).chan, TTX.ParseEvInfoV(0, NTIME, 4)');
                                                    data.snips.(varname).sortcode = cat(1, data.snips.(varname).sortcode, TTX.ParseEvInfoV(0, NTIME, 5)');
                                                    data.snips.(varname).ts = cat(1, data.snips.(varname).ts, TTX.ParseEvInfoV(0, NTIME, 6)');
                                                end
                                            end
                                        end
                                        currT1 = currT2;
                                        currT2 = currT1+dT;
                                    end
                                else
                                    if firstchan
                                        if ~NODATA
                                            data.snips.(varname).data = TTX.ParseEvV(0, NCHAN)';
                                        end
                                        data.snips.(varname).chan = TTX.ParseEvInfoV(0, NCHAN, 4)';
                                        data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, NCHAN, 5)';
                                        data.snips.(varname).ts = TTX.ParseEvInfoV(0, NCHAN, 6)';
                                        if ~isfield(data.snips.(varname), 'fs')
                                            data.snips.(varname).fs = TTX.ParseEvInfoV(0, 1, 9);
                                        end
                                        firstchan = 0;
                                    else
                                        if ~NODATA
                                            data.snips.(varname).data = cat(1,data.snips.(varname).data, TTX.ParseEvV(0, NCHAN)');
                                        end
                                        data.snips.(varname).chan = cat(1,data.snips.(varname).chan, TTX.ParseEvInfoV(0, NCHAN, 4)');
                                        data.snips.(varname).sortcode = cat(1,data.snips.(varname).sortcode, TTX.ParseEvInfoV(0, NCHAN, 5)');
                                        data.snips.(varname).ts = cat(1,data.snips.(varname).ts, TTX.ParseEvInfoV(0, NCHAN, 6)');
                                    end
                                    if mod(chan, 16) == 0 && VERBOSE
                                        fprintf('\n')
                                    end
                                end
                                % reset skip counter
                                skipct = 0;
                            else
                                skipct = skipct + 1;
                                if skipct == 10
                                    if VERBOSE, fprintf('\nNo events found on last 10 channels, exiting loop\n'), end
                                    break;
                                end
                            end
                        end
                        % sort the data based on timestamp
                        [data.snips.(varname).ts, ind] = sort(data.snips.(varname).ts);
                        data.snips.(varname).chan = data.snips.(varname).chan(ind);
                        data.snips.(varname).sortcode = data.snips.(varname).sortcode(ind);
                        if ~NODATA
                            data.snips.(varname).data = data.snips.(varname).data(ind,:);
                        else
                            data.snips.(varname).data = [];
                        end
                    elseif N == MAXEVENTS && CHANNEL > 0
                        warning('Max events reached on a single channel.  Contact TDT.')    
                    else
                        if ~NODATA
                            data.snips.(varname).data = TTX.ParseEvV(0, N)';
                        else
                            data.snips.(varname).data = [];
                        end
                        data.snips.(varname).chan = TTX.ParseEvInfoV(0, N, 4)';
                        data.snips.(varname).sortcode = TTX.ParseEvInfoV(0, N, 5)';
                        data.snips.(varname).ts = TTX.ParseEvInfoV(0, N, 6)';
                        if ~isfield(data.snips.(varname), 'fs')
                            data.snips.(varname).fs = TTX.ParseEvInfoV(0, 1, 9);
                        end
                    end
                end
            end
            if N > 0
                data.snips.(varname).name = name;
                data.snips.(varname).sortname = SORTNAME;
            end
    end
end

if ~strcmp(BITWISE , '')
    if ~(isfield(data.epocs, BITWISE) || isfield(data.scalars, BITWISE))
        error(['Specified BITWISE store name ' BITWISE ' is not in epocs or scalars']);
    end
    nbits = 32;
    if isfield(data.epocs, BITWISE)
        bitwisetype = 'epocs';
    else
        bitwisetype = 'scalars';
    end
    
    data.(bitwisetype).(BITWISE).bitwise = [];
    
    % create big array of all states
    sz = numel(data.(bitwisetype).(BITWISE).data);
    big_array = zeros(nbits+1, sz);
    if strcmpi(bitwisetype, 'epocs')
        big_array(1,:) = data.(bitwisetype).(BITWISE).onset;
    else
        big_array(1,:) = data.(bitwisetype).(BITWISE).ts;
    end
    
    data.(bitwisetype).(BITWISE).bitwise = struct();
    
    % loop through all states
    prev_state = zeros(32,1);
    for i = 1:sz
        xxx = typecast(int32(data.(bitwisetype).(BITWISE).data(i)), 'uint32');
        bbb = dec2bin(xxx(1), 32);
        curr_state = str2num(bbb');          %#ok<ST2NM>
        big_array(2:nbits+1,i) = curr_state;
        
        % look for changes from previous state
        changes = find(xor(prev_state, curr_state));
        
        % add timestamp to onset or offset depending on type of state change
        for j = 1:numel(changes)
            ind = changes(j);
            ffield = ['bit' num2str(nbits-ind)];
            if bbb(ind) == '1'
                % nbits-ind reverses it so b0 is bbb(end)
                if isfield(data.(bitwisetype).(BITWISE).bitwise, ffield)
                    data.(bitwisetype).(BITWISE).bitwise.(ffield).onset = [data.(bitwisetype).(BITWISE).bitwise.(ffield).onset big_array(1,i)];
                else
                    data.(bitwisetype).(BITWISE).bitwise.(ffield).onset = big_array(1,i);
                    data.(bitwisetype).(BITWISE).bitwise.(ffield).offset = [];
                end
            else
                data.(bitwisetype).(BITWISE).bitwise.(ffield).offset = [data.(bitwisetype).(BITWISE).bitwise.(ffield).offset big_array(1,i)];
            end
        end
        prev_state = curr_state;
   end
        
   % add 'inf' to offsets that need them
   for i = 0:nbits-1
       ffield = ['bit' num2str(i)];
       if isfield(data.(bitwisetype).(BITWISE).bitwise, ffield)
           if numel(data.(bitwisetype).(BITWISE).bitwise.(ffield).onset) - 1 == numel(data.(bitwisetype).(BITWISE).bitwise.(ffield).offset)
               data.(bitwisetype).(BITWISE).bitwise.(ffield).offset = [data.(bitwisetype).(BITWISE).bitwise.(ffield).offset inf];
           end
       end
   end
end

% % check for SEV files (don't do this during run-time!)
% if any(TYPE==4)
%     
%     blockpath = sprintf('%s%s\\%s\\', data.info.tankpath, tank, block);
%     
%     file_list = dir([blockpath '*.sev']);
%     if length(file_list) < 3
%         %if VERBOSE, disp(['info: no sev files found in ' blockpath]), end
%     else
%         eventNames = SEV2mat(blockpath, 'JUSTNAMES', true, 'VERBOSE', false);
%         for i = 1:length(eventNames)
%             if strcmp(STORE, '') ~= 1 && strcmp(eventNames{i}, STORE) ~= 1
%                 continue
%             end
%             varname = eventNames{i};
%             for ii = 1:numel(varname)
%                 if ii == 1
%                     if isstrprop(varname(ii), 'digit')
%                         varname(ii) = 'x';
%                     end
%                 end
%                 if ~isstrprop(varname(ii), 'alphanum')
%                     varname(ii) = '_';
%                 end
%             end
%             %varname = matlab.lang.makeValidName(eventNames{i});
%             if ~isvarname(eventNames{i}) && VERBOSE
%                 warning('%s is not a valid Matlab variable name, changing to %s', eventNames{i}, varname);
%             end
%     
%             if ~isfield(data.streams, varname)
%                 if VERBOSE
%                     fprintf('SEVs found in %s.\nrunning SEV2mat to extract %s', ...
%                         blockpath, eventNames{i})
%                 end
%                 sev_data = SEV2mat(blockpath, 'EVENTNAME', eventNames{i}, 'VERBOSE', VERBOSE, 'RANGES', RANGES);
%                 
%                 if isfield(data.streams, varname)
%                     data.streams.(varname) = sev_data.eventNames{i};
%                 end
%             end
%         end
%     end
% end

if ~bUseOutsideTTX
    TTX.CloseTank;
    TTX.ReleaseServer;
end