function data = TDTfilter(data, epoc, varargin)
%TDTFILTER  TDT tank data filter.
%   data = TDTfilter(DATA, EPOC, 'parameter', value, ...), where DATA is
%   the output of TDTbin2mat or TDT2mat, EPOC is the name of the epoc to 
%   filter on, and parameter value pairs define the filtering conditions.
%
%   If no parameters are specified, then the time range of the EPOC event
%   is used as a time filter.
%
%   Also creates data.filter, a string that describes the filter applied.
%
%   'parameter', value pairs
%      'VALUES', specify array of allowed values
%         ex: tempdata = TDTfilter(data, 'Freq', 'VALUES', [9000, 10000]);
%               > retrieves data when Freq = 9000 or Freq = 10000
%      'MODIFIERS', specify array of allowed modifier values.  For example,
%             only allow time ranges when allowed modifier occurred
%             sometime during that event, e.g. a correct animal response.
%         ex: tempdata = TDTfilter(data, 'Resp', 'MODIFIERS', [1]);
%               > retrieves data when Resp = 1 sometime during the allowed
%               time range.
%      'TIME', specify onset/offset pairs relative to EPOC onsets. If the
%             offset is not provided, the EPOC offset is used.
%         ex: tempdata = TDTfilter(data, 'Freq', 'TIME', [-0.1, 0.5]);
%               > retrieves data from 0.1 seconds before Freq onset to 0.4
%                 seconds after Freq onset. Negative time ranges are
%                 discarded.
%      'TIMEREF', all timestamps relative to EPOC onsets
%         ex: tempdata = TDTfilter(data, 'Freq', 'TIMEREF', 1);
%               > sets snip timestamps relative to Freq onset
%      'KEEPDATA', keep the original stream data array and add a new 
%              cell array called 'filtered' that holds the data from each
%              valid time range. Defaults to true
%
%  IMPORTANT! Use a TIME filter only after all VALUE filters have been set

% defaults
VALUES	  = [];
MODIFIERS = [];
TIME      = [];
TIMEREF   = 0;
KEEPDATA  = 1;

filter_string = '';

VALID_PARS = {'VALUES','MODIFIERS','TIME','TIMEREF','KEEPDATA'};

% parse varargin
for ii = 1:2:length(varargin)
    if ~ismember(upper(varargin{ii}), VALID_PARS)
        error('%s is not a valid parameter. See help TDTfilter.', upper(varargin{ii}));
    end
    eval([upper(varargin{ii}) '=varargin{ii+1};']);
end

if isempty(data.epocs)
    error('no epocs found');
end

fff = fieldnames(data.epocs);
match = '';
all_names = {};
for i = 1:numel(fff)
    all_names{i} = data.epocs.(fff{i}).name;
    if strcmp(data.epocs.(fff{i}).name, epoc)
        match = fff{i};
    end
end

if ~isfield(data.epocs, match)
    error([epoc ' is not a valid epoc event, valid events are: ' strjoin(all_names', ', ')])
end

if ~isempty(TIME)
    if numel(TIME) > 2
        error('''TIME'' vector must have 1 or 2 elements')
    end
end

d = data.epocs.(match);

% VALUE FILTER, only use time ranges where epoc value is in filter array
if ~isempty(VALUES)
    
    % find valid time ranges
    valid = zeros(size(d.data));
    %valid = ismember(d.data,VALUES); % newer Matlab only..
    
    % use special value filter if this is the note epoc and we are doing
    % string filter
    if strcmp(match, 'Note') 
        for i = 1:numel(d.notes)
            if iscell(VALUES)
                for j = 1:numel(VALUES)
                    if strcmp(d.notes{i}, VALUES{c})
                        valid(i) = 1;
                        break
                    end
                end
            elseif ischar(VALUES)
                if strcmp(d.notes{i}, VALUES)
                    valid(i) = 1;
                end
            end
        end
    else
        for i = 1:numel(d.data)
            for j = 1:numel(VALUES)
                if abs(d.data(i) - VALUES(j)) < 1e-8
                    valid(i) = 1;
                    break
                end
            end
        end
    end
    
    time_ranges = [d.onset(valid==1)';d.offset(valid==1)'];
    
    if isempty(time_ranges)
        warning('No valid time ranges found')
        data = NaN;
        return
    end
    
    % create filter string
    filter_string = sprintf('%s: VALUE in [', epoc);
    if iscell(VALUES)
        for j = 1:numel(VALUES)
            filter_string = strcat(filter_string, sprintf('%s,', VALUES{i}));
        end
    elseif ischar(VALUES)
        filter_string = strcat(filter_string, sprintf('%s,', VALUES));
    else
        for i = 1:length(VALUES)
            filter_string = strcat(filter_string, sprintf('%.1f,', VALUES(i)));
        end
    end
    filter_string(end:end+1) = '];';

    % AND time_range with existing time ranges
    if isfield(data, 'time_ranges')
        time_ranges = timerange2(time_ranges, data.time_ranges, 'AND');
        data.time_ranges = time_ranges;
    end
end

% MODIFIERS FILTER, only use time ranges where modifier epoc value is in array
if ~isempty(MODIFIERS)
    
    if ~isfield(data, 'time_ranges')
        warning('no valid time ranges to modify');
        return
    end
    
    time_ranges = data.time_ranges;
    
    % only look at epocs in our modifier set
    d.onset = d.onset(ismember(d.data,MODIFIERS));
    
    % loop through all current time ranges
    keep = zeros(size(time_ranges,2));
    for i = 1:size(time_ranges,2)
        % if valid modifier is in this time range, keep it
        for j = 1:length(d.onset)
            if d.onset(j) >= time_ranges(1,i) && d.onset(j) < time_ranges(2,i)
                keep(i) = 1;
            end
        end
    end
    
    % remove duplicates
    data.time_ranges = time_ranges(:, keep == 1);
    
    % create filter string
    filter_string = sprintf('%s: MODIFIER in [', epoc);
    for i = 1:length(MODIFIERS)
        filter_string = strcat(filter_string, sprintf('%.1f,', MODIFIERS(i)));
    end
    filter_string(end:end+1) = '];';
end

t1 = 0;
t2 = NaN;
if ~isempty(TIME)
    t1 = TIME(1);
    if numel(TIME) == 2
        t2 = TIME(2);
    end
    
    if ~exist('time_ranges','var')
        % preallocate
        time_ranges = zeros(2, length(d.onset));
        for j = 1:length(d.onset)
            time_ranges(:, j) = [d.onset(j); d.offset(j)];
        end
    else
        time_ranges = data.time_ranges;
    end
    
    % find valid time ranges
    for j = 1:size(time_ranges,2)
        if isnan(t2)
            time_ranges(:, j) = [time_ranges(1,j)+t1; time_ranges(2,j)];
        else
            time_ranges(:, j) = [time_ranges(1,j)+t1; time_ranges(1,j)+t1+t2];
        end
    end
    
    % throw away negative time ranges
    if all(~isnan(time_ranges))
        time_ranges = time_ranges(:,time_ranges(1,:)>0);
    end
    
    % create filter string
    if isnan(t2)
        filter_string = sprintf('TIME: %s [%.2f:];', epoc, t1);
    else
        filter_string = sprintf('TIME: %s [%.2f:%.2f];', epoc, t1, t2);
    end
    data.time_ranges = time_ranges;
    data.time_ref = [t1, t2];
end

if TIMEREF
    filter_string = strcat(filter_string, sprintf('%s REF', epoc));
    if numel(TIMEREF) > 1
        t1 = TIMEREF(1);
    end
end

if nargin == 2
    % no filter specified, use EPOC time ranges
    time_ranges = [d.onset,d.offset]';
    
    % AND time_range with existing time ranges
    if isfield(data, 'time_ranges')
        time_ranges = timerange2(time_ranges, data.time_ranges, 'AND');
        data.time_ranges = time_ranges;
    end
    filter_string = sprintf('EPOC: %s;', epoc);
end
    
% set filter string
if isfield(data, 'filter')
    data.filter = strcat(data.filter, filter_string);
else
    data.filter = filter_string;
end

time_ranges = data.time_ranges;

% FILTER ALL EXISTING DATA ON THESE TIME RANGES
% filter streams
if ~isempty(data.streams)
    n = fieldnames(data.streams);
    for i = 1:length(n)
        fs = data.streams.(n{i}).fs;
        sf = 1/(2.56e-6*fs);
        td_sample = double(uint64(data.streams.(n{i}).startTime/2.56e-6));
        filtered = [];
        max_ind = max(size(data.streams.(n{i}).data));
        good_index = 1;
        for j = 1:size(time_ranges,2)
            tlo_sample = double(uint64(time_ranges(1,j)/2.56e-6));
            onset = max(round((tlo_sample-td_sample)/sf),0)+1;
            if isinf(time_ranges(2,j))
                offset = inf;
            else
                thi_sample = double(uint64(time_ranges(2,j)/2.56e-6));
                offset = max(round((thi_sample-td_sample)/sf),0);
            end
            
            % throw it away if onset or offset extends beyond recording window
            if isinf(offset)
                if onset <= max_ind && onset > 0
                    filtered{good_index} = data.streams.(n{i}).data(:,onset:end);
                    break
                end
            else
                if offset <= max_ind && offset > 0 && onset <= max_ind && onset > 0
                    filtered{good_index} = data.streams.(n{i}).data(:,onset:offset);
                    good_index = good_index + 1;
                end
            end
        end
        if KEEPDATA
            data.streams.(n{i}).filtered = filtered;
        else
            data.streams.(n{i}).data = filtered;
            data.streams.(n{i}).filtered = [];
        end
    end
end

% filter snips
if ~isempty(data.snips)
    n = fieldnames(data.snips);
    warning_value = -1;
    for i = 1:length(n)
        ts = data.snips.(n{i}).ts;
        
        % preallocate
        keep = zeros(1, length(ts));
        diffs = zeros(1, length(ts)); % for relative timestamps
        keep_ind = 0;
        
        for j = 1:numel(ts)
            ts_ind = find(ts(j) > time_ranges(1,:) & ts(j) < time_ranges(2,:) == 1);
            
            if ts_ind
                if numel(ts_ind) > 1
                    min_diff = min(abs(time_ranges(1, ts_ind(1))-time_ranges(1, ts_ind(2))), abs(time_ranges(2, ts_ind(1))-time_ranges(2, ts_ind(2))));
                    warning_value = min_diff;
                    continue
                end
                keep_ind = keep_ind + 1;
                keep(keep_ind) = j;
                diffs(keep_ind) = ts(j) - time_ranges(1, ts_ind) + t1; % relative ts
            end
        end
        
        if warning_value > 0
            warning('time range overlap, consider a maximum time range of %.2fs', warning_value)
        end
        
        % truncate
        keep = keep(1:keep_ind)';
        diffs = diffs(1:keep_ind)';
        
        if isfield(data.snips.(n{i}), 'data')
            if ~isempty(data.snips.(n{i}).data)
                data.snips.(n{i}).data = data.snips.(n{i}).data(keep,:);
            end
        end
        if TIMEREF
            data.snips.(n{i}).ts = diffs;
        else
            data.snips.(n{i}).ts = data.snips.(n{i}).ts(keep);
        end
        % if there are any extra fields, keep those
        fff = fieldnames(data.snips.(n{i}));
        for j = 1:numel(fff)
            if strcmp(fff{j}, 'ts') || strcmp(fff{j}, 'name') || strcmp(fff{j}, 'data')|| strcmp(fff{j}, 'sortname') || strcmp(fff{j}, 'fs')
                continue
            end
            if numel(data.snips.(n{i}).(fff{j})) >= max(keep)
                data.snips.(n{i}).(fff{j}) = data.snips.(n{i}).(fff{j})(keep);
            end
        end
    end
end

% filter scalars, include if timestamp falls in valid time range
if ~isempty(data.scalars)
    n = fieldnames(data.scalars);
    for i = 1:length(n)
        ts = data.scalars.(n{i}).ts;
        keep = get_valid_ind(ts, time_ranges);
        if keep
            % scalars can have multiple rows
            data.scalars.(n{i}).data = data.scalars.(n{i}).data(:,keep);
            data.scalars.(n{i}).ts = data.scalars.(n{i}).ts(keep);
        else
            data.scalars.(n{i}).data = [];
            data.scalars.(n{i}).ts = [];
        end
    end
end

% filter epocs, include if onset falls in valid time range
if ~isempty(data.epocs)
    n = fieldnames(data.epocs);
    for i = 1:length(n)
        ts = data.epocs.(n{i}).onset;
        keep = get_valid_ind(ts, time_ranges);
        if keep
            data.epocs.(n{i}).data = data.epocs.(n{i}).data(keep);
            data.epocs.(n{i}).onset = data.epocs.(n{i}).onset(keep);
            if isfield(data.epocs.(n{i}), 'notes')
                if isstruct(data.epocs.(n{i}).notes)
                    if isfield(data.epocs.(n{i}).notes, 'ts')
                        keep2 = get_valid_ind(data.epocs.(n{i}).notes.ts, time_ranges);
                        data.epocs.(n{i}).notes.ts = data.epocs.(n{i}).notes.ts(keep2);
                        data.epocs.(n{i}).notes.index = data.epocs.(n{i}).notes.index(keep2);
                        data.epocs.(n{i}).notes.notes = data.epocs.(n{i}).notes.notes(keep2);
                    end
                else
                    data.epocs.(n{i}).notes = data.epocs.(n{i}).notes(keep);
                end
            end
            if isfield(data.epocs.(n{i}), 'offset')
                data.epocs.(n{i}).offset = data.epocs.(n{i}).offset(keep);
            end
        else
            data.epocs.(n{i}).data = [];
            data.epocs.(n{i}).onset = [];
            if isfield(data.epocs.(n{i}), 'offset')
                data.epocs.(n{i}).offset = [];
            end
            if isfield(data.epocs.(n{i}), 'notes')
                data.epocs.(n{i}).notes = {};
            end
        end
    end
end
end

function valid_ranges = timerange2(tr1, tr2, logic)
% AND or OR two given time ranges

if size(tr1, 1) ~= 2 || size(tr2, 1) ~= 2
    error('invalid time range size');
end

max_ranges_possible = size(tr1,2) + size(tr2,2);
valid_ranges = zeros(2,max_ranges_possible);

% start with first time range, check the end timestamps
valid_ind = 0;
if strcmpi(logic, 'AND')
    % put them in order
    [x, id] = sort(tr1,2);
    tr1 = tr1(:, id(1,:));
    [x, id] = sort(tr2,2);
    tr2 = tr2(:, id(1,:));
    for ii = 1:size(tr1,2)
        start1 = tr1(1,ii);
        stop1 = tr1(2,ii);
        for jj = 1:size(tr2,2)
            start2 = tr2(1,jj);
            stop2 = tr2(2,jj);
            if start2 > stop1
                % we're already passed the end of tr1
                % stop checking and move to next one
                break
            end
            if stop2 <= start1
                % tr2 ends before the beginning of tr1, skip
                continue
            end
            if valid_ind > 0
                if start1 > valid_ranges(1,valid_ind) && start1 < valid_ranges(2, valid_ind)
                    valid_ranges(1, valid_ind) = start1;
                    % if start1 is within last valid range, use it
                    % check end time
                    valid_ranges(2, valid_ind) = min(valid_ranges(2, valid_ind), stop1);
                    continue
                end
            end
            start_valid = max(start1, start2);
            stop_valid = min(stop1, stop2);
            valid_ind = valid_ind + 1;
            valid_ranges(:,valid_ind) = [start_valid;stop_valid];
        end
    end
elseif strcmpi(logic, 'OR')
    % put all time ranges in order of starting time stamp
    all_ranges = [tr1 tr2];
    [x, id] = sort(all_ranges,2);
    all_ranges = all_ranges(:, id(1,:));
    for ii = 1:size(all_ranges, 2)
        start1 = all_ranges(1, ii);
        stop1 = all_ranges(2, ii);
        
        if ii == 1
            % first range is starting valid range
            curr_start_valid = start1;
            curr_stop_valid = stop1;
            valid_ind = valid_ind + 1;
            valid_ranges(:,1) = [curr_start_valid;curr_stop_valid];
            continue
        end
        if start1 <= curr_stop_valid && stop1 > curr_stop_valid
            % if new time range is inside old one but end overlaps, use new end
            curr_stop_valid = stop1;
            valid_ranges(2,valid_ind) = curr_stop_valid;
            continue
        end
        if start1 > curr_stop_valid
           % create new valid
           curr_start_valid = start1;
           curr_stop_valid = stop1;
           valid_ind = valid_ind + 1;
           valid_ranges(:,valid_ind) = [curr_start_valid;curr_stop_valid];
        end            
    end
else
    error('Logic input ''%s'' is not valid, use ''OR'' or ''AND''', logic)
end

valid_ranges = valid_ranges(:,1:valid_ind);
end

function keep = get_valid_ind(ts, time_ranges)
    % preallocate
    keep = zeros(1, length(ts));
    keep_ind = 0;
    
    for j = 1:numel(ts)
        overlap = find(ts(j) >= time_ranges(1,:) & ts(j) < time_ranges(2,:));
        if any(overlap)
            keep_ind = keep_ind + 1;
            keep(keep_ind) = j;
        end
    end
    
    for j = 1:numel(ts)
        ts_ind = find(ts(j) >= time_ranges(1,:) & ts(j) < time_ranges(2,:) == 1);
        if ts_ind
            keep_ind = keep_ind + 1;
            keep(keep_ind) = j;
        end
    end
    
    % truncate
    keep = keep(1:keep_ind);
    
    %keep
    % 'stable' is a newer option that isn't supported in older versions of
    % Matlab (2007b)
    %keep = unique(keep, 'stable');
    [junk, index] = unique(keep, 'first');
    keep = keep(sort(index));
end