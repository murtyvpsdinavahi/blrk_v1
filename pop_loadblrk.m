% pop_loadblrk() - load .nsX format dataset and
%                return EEGLAB EEG structure
%
% Usage:
%   >> [EEG, com] = pop_loadblrk; % pop-up window mode
%   >> [EEG, com] = pop_loadblrk(path, hdrfile);
%   >> [EEG, com] = pop_loadblrk(path, hdrfile, srange);
%   >> [EEG, com] = pop_loadblrk(path, hdrfile, [], chans);
%   >> [EEG, com] = pop_loadblrk(path, hdrfile, srange, chans);
%
% Optional inputs:
%   path      - path to files
%   hdrfile   - name of Brain Vision vhdr-file (incl. extension)
%   srange    - scalar first sample to read (up to end of file) or
%               vector first and last sample to read (e.g., [7 42];
%               default: all)
%   chans     - vector channels channels to read (e.g., [1:2 4];
%               default: all)
%
% Outputs:
%   EEG       - EEGLAB EEG structure
%   com       - history string
%
% Author: Murty V P S Dinavahi, C/o Dr. Supratim Ray, Indian Institute of
% Science, Bangalore 06-03-2015
%
% This program requires Neural Processing Matlab Kit 
% available from the following github repository: 
% https://github.com/BlackrockMicrosystems/NPMK
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%

function [EEG, com] = pop_loadblrk(path, hdrfile, srange, chans)

com = '';
EEG = [];

if nargin < 2
    fileExt = {'*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.ns7;*.ns8;*.ns9'};
    [hdrfile path] = uigetfile2(fileExt, 'Select .nsX file');
    if hdrfile(1) == 0, return; end

    drawnow;
    uigeom = {[1 0.5] [1 0.5]};
    uilist = {{ 'style' 'text' 'string' 'Interval (in seconds; e.g., [start stop]; default: entire signal'} ...
              { 'style' 'edit' 'string' ''} ...
              { 'style' 'text' 'string' 'Channels (e.g., [1:2 4]; default: all channels'} ...
              { 'style' 'edit' 'string' ''}};
    result = inputgui(uigeom, uilist, 'pophelp(''pop_loadblrk'')', 'Load .nsX file');
    if isempty(result), return, end
    if ~isempty(result{1}),
        srange = str2num(result{1});
    end
    if ~isempty(result{2}),
        chans = str2num(result{2});
    end
end

fname = [path hdrfile];

% Header file
disp('pop_loadblrk(): opening file');
NSx = openNSx(fname,'read','p:double');

% Common Infos
try
    EEG = eeg_emptyset;
catch
end
EEG.comments = ['Original file: ' NSx.MetaTags.Filename];
EEG.srate = NSx.MetaTags.SamplingFreq;

% Channel Infos
if ~exist('chans', 'var')
    chans = NSx.MetaTags.ChannelID;    
elseif isempty(chans)
    chans = NSx.MetaTags.ChannelID;
else
    diffChan = setdiff(chans,NSx.MetaTags.ChannelID);
    if ~isempty(diffChan)
        error('chans out of available channel range');
    end
end

EEG.nbchan = length(chans);

% Channel locations
for chan = 1:length(chans)
    EEG.chanlocs(chan).labels = NSx.ElectrodesInfo(chan).Label;
end

disp('pop_loadblrk(): reading EEG data');

% Sample range
if ~exist('srange', 'var') || isempty(srange)
    srange = [ 0 NSx.MetaTags.DataPoints/EEG.srate];
    EEG.pnts = NSx.MetaTags.DataPoints;
elseif length(srange) == 1
    EEG.pnts = NSx.MetaTags.DataPoints - srange(1)*EEG.srate;
else
    EEG.pnts = srange(2)*EEG.srate - srange(1)*EEG.srate;
end

if any(srange*EEG.srate > NSx.MetaTags.DataPoints)
    error('srange out of available data range');
end

for datChan = 1:length(chans)
    EEG.data(datChan,:) = NSx.Data(datChan,(srange(1)*EEG.srate+1):srange(2)*EEG.srate);
    
    % Scaling EEG.data
    clear minDig minAnalog scaleMin maxDig maxAnalog scaleMax
    minDig = NSx.ElectrodesInfo(datChan).MinDigiValue;
    minAnalog = NSx.ElectrodesInfo(datChan).MinAnalogValue;
    scaleMin = double(minDig/minAnalog);
    maxDig = NSx.ElectrodesInfo(datChan).MinDigiValue;
    maxAnalog = NSx.ElectrodesInfo(datChan).MinAnalogValue;
    scaleMax = double(maxDig/maxAnalog);
    
    for q=1:size(EEG.data(datChan,:),2)
        if EEG.data(datChan,q)<0
            EEG.data(datChan,q)=EEG.data(datChan,q)/scaleMin;
        else
            EEG.data(datChan,q)=EEG.data(datChan,q)/scaleMax;
        end
    end
end

EEG.trials = 1;
EEG.xmin   = 0;
EEG.xmax   = (EEG.pnts - 1) / EEG.srate;

% Convert to EEG.data to double
EEG.data = double(EEG.data);

EEG.ref = 'common';

% Extract codes
% EEG.event = parse_blrk_events(fname,EEG.srate);
[EEG.event,stimCombTable,dataLog] = getLablibEvents_GAV(EEG.srate);
assignin('base','stimCombTable',stimCombTable);
assignin('base','dataLog',dataLog);

try
    EEG = eeg_checkset(EEG);
catch
end

if nargout == 2
    com = sprintf('EEG = pop_loadblrk(''%s'', ''%s'', %s, %s);', path, hdrfile, mat2str(srange), mat2str(chans));
end
