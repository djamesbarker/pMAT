function [DSDeltaF, DTs, DFs] = DownSample(Signal,Fs,varargin)
%Signal-- the Delta F/F or Raw signal to be processed
%FS--The sampling frequency

%Variable Input Arguments:
%1-Size of Sample Group--median of n samples will be taken in order to
% downsample the data. New sampling frequency = old Fs/n. Default is 10
% samples.

if isempty(varargin)
    Group=10;
else
    Group=varargin{1};
end

Ts = ((1:(length(Signal)))/ Fs)';
DTs(:,1)=Ts(1:Group:end);

DFs=Fs/Group;

DSDeltaF=[];
for i=1:Group:length(Signal)
    if i+Group-1> length(Signal)
        DSDeltaF(end+1,1)=median(Signal(i:length(Signal)));
    else
        DSDeltaF(end+1,1)=median(Signal(i:i+(Group-1)));
    end
end