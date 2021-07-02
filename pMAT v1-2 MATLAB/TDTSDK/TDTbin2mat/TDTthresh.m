function data = TDTthresh(data, STREAM, varargin)
%TDTTHRESH  TDT snippet extractor.
%   data = TDTthresh(DATA, STREAM, 'parameter', value, ...), where DATA is
%   the output of TDTbin2mat, STREAM is the name of the stream store to 
%   convert to snippets, and parameter value pairs define the snippet
%   extraction conditions. There are two possible extraction methods:
%
%       1) In 'manual' mode, extract snippets of length NPTS from all
%       channels in data.streams.(STREAM).data where the given THRESHOLD is
%       crossed. 1/4 of the waveform occurs before the threshold crossing.
%
%       2) In 'auto' mode, extract snippets of length NPTS using a
%       threshold that automatically adjusts to changes in each channel's
%       baseline noise floor. The previous TAU seconds of data are used in
%       the calculation. The baseline noise floor is multiplied by the STD
%       parameter to set the current threshold.
%
%   output.snips.Snip    contains all snippet store data (timestamps, 
%                        channels, raw data, and sampling rate)
%
%   'parameter', value pairs
%       'MODE'      string, threshold mode. Can be 'auto' or 'manual'
%                       (default = 'manual')
%       'NPTS'      scalar, number of points per snippet (default = 30)
%       'TETRODE'   bool, treat groups of four channels as a tetrode. If 
%                       true, a threshold crossing on one channel in the
%                       tetrode will trigger a snippet on all four channels
%                       in the tetrode (default = false)
%       'THRESH'    scalar, absolute threshold for extracting snippets in
%                       'manual' mode (default = 100e-6). Can be negative
%                       for negative-first spike detection.
%       'REJECT'    scalar, defines artifact rejection level. If absolute
%                       value of candidate spike goes beyond this level, it
%                       is rejected (default = Inf)
%       'TAU',      scalar, defines size of moving window for 'auto'
%                       thresholding mode, in seconds (default = 5)
%       'STD'       scalar, sets the number of standard deviations from the
%                       baseline noise floor to use as the threshold in
%                       'auto' thresholding mode (default = 6).
%       'POLARITY', scalar, set polarity for auto threshold mode. Can
%                       be 1 or -1 (default = -1)
%       'OVERLAP',  bool, if true, multiple threshold crossings within one
%                       NPTS window are treated as distinct snippets. If
%                       'TETRODE' is true, the double-crossings are
%                       discarded before the tetrode extraction occurs.
%                       (default = true)
%       'VERBOSE',  bool, set to false to disable console output
%                       (default = true)
%
%   Example
%      data = TDTbin2mat(BLOCKPATH);
%      data = TDTdigitalfilter(data, 'Wav1', [300 5000]);
%      data = TDTthresh(data, 'Wav1', 'MODE', 'manual', 'THRESH', 150e-6);
%      plot(data.snips.Snip.data')
%

data.snips.Snip = struct('data', [], 'chan', [], 'sortcode', [], 'ts', [], 'fs', 0);

% defaults
MODE       = 'manual';
POLARITY   = -1;
NPTS       = 30;
THRESH     = 100e-6;
TAU        = 5;
OVERLAP    = 1;
VERBOSE    = 1;
SNIP       = 'Snip';
REJECT     = Inf;
STD        = 6;
TETRODE    = 0;

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

if ~isfield(data, 'streams')
    error('no streams found in input data.')
end

if ~isfield(data.streams, STREAM)
    error('%s is not in data.streams.', STREAM)
end

if VERBOSE
    fprintf('window size is %d, ', NPTS);
    if OVERLAP
        fprintf('overlap is allowed.\n');
    else
        fprintf('without overlap.\n');
    end
end    

pre_wave = floor(NPTS/4)-1;
post_wave = NPTS - pre_wave-1;
[nchan, nsamples] = size(data.streams.(STREAM).data);
data.snips.(SNIP).fs = data.streams.(STREAM).fs;

if strcmpi(MODE, 'manual')
    if VERBOSE
        fprintf('using absolute threshold method, set to %.2fuV.\n', THRESH*1e6);
    end
    thresh = THRESH;
    POLARITY = sign(THRESH);
else
    if VERBOSE
        fprintf('using auto threshold method, with polarity %d, %.2f x std, and tau=%.2fs.\n', POLARITY, STD, TAU);
    end
    data.streams.DUMMY = data.streams.(STREAM);
    data.streams.DUMMY.data = sqrt(data.streams.DUMMY.data.*conj(data.streams.DUMMY.data));
    data = TDTdigitalfilter(data, 'DUMMY', 1/TAU, 'TYPE', 'low');
    thresh = STD*POLARITY*data.streams.DUMMY.data;
    data.streams = rmfield(data.streams, 'DUMMY');
end
    
if POLARITY > 0
    [idx, idy] = find(data.streams.(STREAM).data >= thresh);
else
    [idx, idy] = find(data.streams.(STREAM).data <= thresh);
end

% can't have a crossing on the first sample
ind = idy==1;
idx(ind) = [];
idy(ind) = [];

% find indicies where crossing occurred
if POLARITY > 0
    if numel(thresh) == 1
        ind = find(data.streams.(STREAM).data(sub2ind([nchan, nsamples], idx, idy-1)) < thresh);
    else
        ind = find(data.streams.(STREAM).data(sub2ind([nchan, nsamples], idx, idy-1)) < thresh(sub2ind([nchan, nsamples], idx, idy-1)));
    end
else
    if numel(thresh) == 1
        ind = find(data.streams.(STREAM).data(sub2ind([nchan, nsamples], idx, idy-1)) > thresh);
    else
        ind = find(data.streams.(STREAM).data(sub2ind([nchan, nsamples], idx, idy-1)) > thresh(sub2ind([nchan, nsamples], idx, idy-1)));
    end
end
idy = idy(ind);
idx = idx(ind);

% can't have negative indicies, or indicies beyond the end of the waveform
ind = idy <= pre_wave | idy >= nsamples - post_wave;
idx(ind) = [];
idy(ind) = [];

% if overlap is not allowed, remove double-crossings within a single window
if OVERLAP == 0
    channels = unique(idx);
    for chan = 1:length(channels)
        index = find(idx==channels(chan));
        diffs = diff(reshape(idy(index), 1, []));
        bad = diffs < NPTS;
        while (any(bad))
            % find where an overlap snippet occurs right after a known good snippet
            good = diffs >= NPTS;
            test = [true good(1:end-1)];
            ttt = [false bad & test];

            % remove it
            idy(index(ttt)) = [];
            idx(index(ttt)) = [];

            % retest
            index = find(idx==channels(chan));
            diffs = diff(reshape(idy(index), 1, []));
            bad = diffs < NPTS;
        end
    end
end

if TETRODE == 1
    fprintf('performing tetrode extraction\n')
    if nchan < 4
        error('tetrode extraction requires more than 4 channels');
    end
    if mod(nchan, 4) > 0
        fprintf('tetrode extraction works on groups of 4 channels.\nchannels %s will be ignored\n', num2str((nchan-mod(nchan,4))+1:nchan))
    end
    append_x = cell(nchan, 4);
    append_y = cell(nchan, 4);
    for tetrode = 0:(floor(nchan/4)-1)
        % iterate over the channels in the tetrode
        for ii = 1:4
            test_ch = ii + tetrode*4;
            
            % find y indices where this channel fired
            index = idy(idx == test_ch);
            
            % add y indices for the other channels
            for jj = 1:4
                if jj == ii
                    continue
                end
                other_ch = jj + tetrode*4;
                append_x{test_ch, jj} = other_ch*ones(1, numel(index));
                append_y{test_ch, jj} = index';
            end
        end
    end
    idx = [idx;[append_x{:}]'];
    idy = [idy;[append_y{:}]'];
end

if nchan == 1
    data.snips.(SNIP).chan = idx(1);
    idy = idy';
else
    data.snips.(SNIP).chan = int16(idx);
end

data.snips.(SNIP).ts = idy / data.snips.(SNIP).fs;

if strcmpi(MODE, 'auto')
    if VERBOSE
        fprintf('ignoring the first tau=%.1f seconds\n', TAU)
    end
    ind = find(data.snips.(SNIP).ts < TAU);
    data.snips.(SNIP).ts(ind) = [];
    idx(ind) = [];
    idy(ind) = [];
end

% everything should already be sorted by time, unless we extracted tetrodes
if TETRODE
    [data.snips.(SNIP).ts, sort_ind] = sort(data.snips.(SNIP).ts);
    data.snips.(SNIP).chan = data.snips.(SNIP).chan(sort_ind);
    idy = idy(sort_ind);
    idx = idx(sort_ind);
end

nwaves = numel(idy);
if nchan == 1
    idx = ones(NPTS*nwaves,1);
else
    idx = kron(idx, ones(NPTS,1));
end

%idy = idy .* ones( nwaves, NPTS) + repmat(-pre_wave:post_wave, nwaves, 1); % newer Matlab 
indicies = ones( nwaves, NPTS) + repmat(-pre_wave:post_wave, nwaves, 1); % for Matlab 2007b support
for i = 1:size(indicies, 2)
    indicies(:,i) = indicies(:,i) + idy;
end

indicies = reshape(indicies', [], 1);
data.snips.(SNIP).data = reshape(data.streams.(STREAM).data(sub2ind([nchan, nsamples], idx, indicies)), NPTS, nwaves)';

% remove artifacts
[tempx, tempy] = find(abs(data.snips.(SNIP).data) > REJECT);
remove = unique(tempx);
data.snips.(SNIP).data(remove,:) = [];
data.snips.(SNIP).ts(remove) = [];
data.snips.(SNIP).chan(remove) = [];

data.snips.(SNIP).sortcode = zeros(size(data.snips.(SNIP).ts), 'int16');
data.snips.(SNIP).name = SNIP;
data.snips.(SNIP).sortname = '';

data.snips.(SNIP).thresh = thresh;
