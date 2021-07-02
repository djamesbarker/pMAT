function data = TDTdigitalfilter(data, STREAM, FC, varargin)
%TDTDIGITALFILTER  applies a digital filter to continuous data
%   data = TDTdigitalfilter(DATA, STREAM, FC, 'parameter', 'value', ... ),
%   where DATA is the output of TDTbin2mat, STREAM is the name of the
%   stream store to filter, FC is the cutoff frequency. If FC is a two-
%   element vector, a bandpass filter is applied by default.
%
%   data    contains updated STREAM data store with digital filter applied
%
%   data = TDTdigitalfilter(data, STREAM, FC, 'parameter', value, ... )
%   data = TDTdigitalfilter(DATA, STREAM, 'NOTCH', [60 120])
%
%   'parameter', value pairs
%       'TYPE'      string, specifies the TYPE of filter to use
%                       'band': bandpass filter (default if FC is two element)
%                       'stop': bandstop filter
%                       'low': low pass butterworth (default if FC is scalar)
%                       'high': high pass butterworth 
%       'ORDER'     scalar, filter order for high pass and low pass filters
%                       (default = 2). If the high pass cutoff frequency is
%                       low enough (usually below ~2 Hz), a custom filter
%                       is applied.
%       'NOTCH'     scalar or array, frequencies to apply notch filter. The
%                       notch filters are always 1st order filters.
%
%   Example
%      data = TDTbin2mat('C:\TDT\OpenEx\Tanks\DEMOTANK2\Block-1');
%      data = TDTdigitalfilter(data, 'Wav1', [300 5000], 'NOTCH', [60 120]);
%      data = TDTdigitalfilter(data, 'Wav2', 10, 'TYPE', 'high', 'ORDER', 4);
%      data = TDTdigitalfilter(data, 'Wav3', 'NOTCH', 60);
%

% defaults
TYPE = 'band';
ORDER = 2;
NOTCH = [];

% catch if no FC is used, only notch
if strcmp(FC, 'NOTCH')
    varargin = [{'NOTCH'}, varargin];
    TYPE = 'NULL';
    FC = [];
end

% parse varargin
VALID_PARS = {'TYPE','ORDER','NOTCH'};
for ii = 1:2:length(varargin)
    if ~ismember(upper(varargin{ii}), VALID_PARS)
        error('%s is not a valid parameter. See help TDTdigitalfilter', upper(varargin{ii}));
    end
    eval([upper(varargin{ii}) '=varargin{ii+1};']);
end

% validate inputs
if length(FC) == 1
    if ~strcmp(TYPE, 'high') && ~strcmp(TYPE, 'low')
        warning('invalid TYPE for scalar FC, assuming ''low''')
        TYPE = 'low';
    end
elseif length(FC) == 2
    if ~strcmp(TYPE, 'band') && ~strcmp(TYPE, 'stop')
        warning('invalid TYPE for two-dimensional vector, assuming ''band''')
        TYPE = 'band';
    end
end

if ~isfield(data.streams.(STREAM), 'filter')
    data.streams.(STREAM).filter = '';
end

if ~isempty(NOTCH)
    for i = 1:numel(NOTCH)
        BW = 0.05;
        pre_notch_string = data.streams.(STREAM).filter;
        data = TDTdigitalfilter(data, STREAM, NOTCH(i)*[1-BW,1+BW], 'TYPE', 'stop', 'ORDER', 1);
        filter_string = sprintf('Notch %.1fHz;', NOTCH(i));
        data.streams.(STREAM).filter = strcat(pre_notch_string, filter_string);
    end
end

if strcmp(TYPE, 'band')
    data = TDTdigitalfilter(data, STREAM, FC(2), 'TYPE', 'low', 'ORDER', ORDER);
    data = TDTdigitalfilter(data, STREAM, FC(1), 'TYPE', 'high', 'ORDER', ORDER);
    return
end

if strcmp(TYPE, 'NULL')
    return
end

Alpha = single(1-exp(-6.283 * FC(1) / 24414.0625));
if strcmp(TYPE, 'high') && Alpha <= 0.0005
    if FC(1) > 0
        %%% Emulate MCSmooth HP filter
        fprintf('Using alpha smoothing for the high pass filter\n');
        for chan = 1:size(data.streams.(STREAM).data,1)
            if size(data.streams.(STREAM).data,1) == 1
                r2 = zeros(size(data.streams.(STREAM).data));
                r2(1) = data.streams.(STREAM).data(1);
            else
                r2 = zeros(size(data.streams.(STREAM).data(chan,:)));
                r2(1) = data.streams.(STREAM).data(chan,1);
            end
            for i = 2:length(data.streams.(STREAM).data)
                r2(i) = Alpha*data.streams.(STREAM).data(chan,i) + (1-Alpha)*r2(i-1);
            end
            data.streams.(STREAM).data(chan,:) = data.streams.(STREAM).data(chan,:) - r2;
        end

        % set filter string
        filter_string = sprintf('SMhigh %.1fHz;', FC(1));
    else
        % set filter string
        filter_string = 'high 0Hz;';
    end
else
    Fs = data.streams.(STREAM).fs; %sampling rate
    [Z, P, K] = butter(ORDER, FC./(Fs/2), TYPE);    
    SOS = zp2sos(Z, P, K);
    
    data.streams.(STREAM).data = double(data.streams.(STREAM).data);
    for channel = 1:size(data.streams.(STREAM).data, 1)
        % use filtfilt here to remove phase distortion
        data.streams.(STREAM).data(channel, :) = sosfilt(SOS, data.streams.(STREAM).data(channel, :));
    end

    if length(FC) == 1
        filter_string = sprintf('%s %.1fHz;', TYPE, FC);
    else
        filter_string = sprintf('%s %.1f-%.1fHz;', TYPE, FC);
    end
end

data.streams.(STREAM).filter = strcat(data.streams.(STREAM).filter, filter_string);