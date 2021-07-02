function [fft_data,varargout] = TDTfft(data, channel, varargin)
%TDTFFT  performs a frequency analysis of the data stream
%   [fft_data, fft_freq] = TDTfft(DATA, CHANNEL), where DATA is a stream 
%   from the output of TDT2mat and CHANNEL is an integer.
%
%   fft_data    contains power spectrum array
%   fft_freq    contains the frequency list (optional)
%
%   fft_data = TDTfft(DATA, CHANNEL, 'parameter', value,...)
%   [fft_data, fft_freq] = TDTfft(DATA, CHANNEL, 'parameter', value,...)
%
%   'parameter', value pairs
%      'PLOT'       boolean, set to false to disable figure
%      'NUMAVG'     scalar, number of subsets of data to average together
%                   in fft_data (default = 1)
%      'SPECPLOT'   boolean, include spectrogram plot (default = false)
%      'FREQ'       Two-element vector, Spectral Power within specificed
%                   frequencies will be returned instead of full scale
%                   (default = [0 FS/2])
%      'RESOLUTION' scalar, the frequency resolution, (default = 1)
%      'LEGEND'     Add a string to describe the data trace
%
%   Example
%      data = TDTbin2mat('C:\TDT\OpenEx\Tanks\DEMOTANK2\Block-1');
%	   TDTfft(data.streams.Wave, 1);

if nargout > 2
    error('too many output arguments, only 1 or 2 output arguments allowed')
end

% defaults
PLOT     = true;
NUMAVG   = 1;
SPECPLOT = false;
FREQ = [0, data.fs/2];
RESOLUTION = 1;
LEGEND = false;

VALID_PARS = {'PLOT','NUMAVG','SPECPLOT','FREQ','RESOLUTION','LEGEND'};

% parse varargin
for ii = 1:2:length(varargin)
    if ~ismember(upper(varargin{ii}), VALID_PARS)
        error('%s is not a valid parameter. See help TDTfft.', upper(varargin{ii}));
    end
    eval([upper(varargin{ii}) '=varargin{ii+1};']);
end

if length(FREQ) ~= 2
    error('FREQ must be a two-element vector');
else
    if FREQ(2) < FREQ(1)
        error('Second element of FREQ must be smaller than first element');
    end
    if FREQ(1) < 0 || FREQ(2) > data.fs/2
        error('FREQ outside of bounds (0, %.2f)', data.fs/2);
    end
end

% resample it if FREQ is specified
if FREQ(2) < data.fs/2 && 2*FREQ(2) < data.fs
    %data = TDTdigitalfilter(data, FREQ(2), 'low');
    new_fs = min(2*FREQ(2),data.fs);
    [p, q] = rat(data.fs/new_fs, 0.0001);
    y = resample(double(data.data(channel,:)), q, p);
    Fs = new_fs;
else
    y = data.data(channel,:);
    Fs = data.fs;
end

NFFT = round(Fs/RESOLUTION);
if rem(NFFT,2) ~= 0
    NFFT = NFFT+1;
end

if SPECPLOT
    numplots = 4;
else
    numplots = 3;
end

T = 1/Fs;       % Sample time
L = numel(y);   % Length of signal
t = (0:L-1)*T;  % Time vector

% do averaging here, if we are doing it
if NUMAVG > 1
    step = floor(L/NUMAVG);
    for i = 0:NUMAVG-1
        d = y(1+(i*step):(i+1)*step);
        Y = fft(d,NFFT)/numel(d);
        f = Fs/2*linspace(0,1,NFFT/2+1);
        d = 2*abs(Y(1:NFFT/2+1));
        if i == 0
            fft_data = d;
        else
            fft_data = fft_data + d;
        end
    end
    fft_data = fft_data/NUMAVG;
else
    Y = fft(y,NFFT)/L;
    f = Fs/2*linspace(0,1,NFFT/2+1);
    fft_data = 2*abs(Y(1:NFFT/2+1));    
end

if length(FREQ) == 1 
    fft_freq = f;
else
    [temp,ind1] = min(abs(f-FREQ(1)));
    [temp,ind2] = min(abs(f-FREQ(2)));
    fft_freq = f(ind1:ind2);
    fft_data = fft_data(ind1:ind2); 
end

if nargout == 2
    varargout{1} = fft_freq;
end

if ~PLOT
    return
end

figure;
subplot(numplots,1,1);

% set voltage scale
r = rms(y);
factor = 1;
if round(r*1e6) == 0
    factor = 1e9;
    y_units = 'nV';
elseif round(r*1e3) == 0
    factor = 1e6;
    y_units = 'uV';
elseif round(r) == 0
    factor = 1e3;
    y_units = 'mV';
else
    y_units = 'V';
end

% set time scale
if floor(t(end)/10) == 0
    % if less than 10 seconds, use ms
    t = t*1000;
    x_units = 'ms';
elseif floor(t(end)/600) > 0
    % if over 10 minutes, use minutes
    t = t/60;
    x_units = 'min';
else
    x_units = 's';
end

% plot raw signal
plot(t,y*factor)
xlabel(['Time (' x_units ')'])
if max(y*factor) < 0
    axis([0 t(end) min(y*factor)*1.05 max(y*factor)*.95]);
elseif min(y*factor) > 0
    axis([0 t(end) min(y*factor)*.95 max(y*factor)*1.05]);
else
    axis([0 t(end) min(y*factor)*1.05 max(y*factor)*1.05]);
end
grid on;
ylabel(y_units)
title(sprintf('Raw Signal (%.2f %srms)', r*factor, y_units))
if LEGEND
   legendstr = LEGEND; 
   legend(legendstr);
end


% plot single-sided amplitude spectrum
subplot(numplots,1,2);
semilogx(fft_freq, fft_data)
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
if length(FREQ) == 1
    axis([0 fft_freq(end) 0 max(fft_data)*1.05]);
else
    axis([FREQ(1) FREQ(2) 0 max(fft_data)*1.05]);
end

% plot power spectrum
subplot(numplots,1,3)
fft_data = 20*log10(fft_data);
semilogx(fft_freq, fft_data)
title('Power Spectrum')
xlabel('Frequency (Hz)')
ylabel('dBV')
if length(FREQ) == 1
    axis([0 fft_freq(end) min(fft_data)*1.05 max(fft_data)/1.05]);
else
    axis([FREQ(1) FREQ(2) min(fft_data)*1.05 max(fft_data)/1.05]);
end

% plot spectrogram
if ~SPECPLOT, return, end
subplot(numplots,1,4)
spectrogram(double(y),256,240,256,Fs,'yaxis'); 
title('Spectrogram')
