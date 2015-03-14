% eegplugin_blrk_io() - EEGLAB plugin for importing Blackrock
%                         .ns3 data files.
%
% Usage:
%   >> eegplugin_blrk_io(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Murty V P S Dinavahi, C/o Dr. Supratim Ray, Indian Institute of
% Science, Bangalore 06-03-2015
%
% Modified from a code by Andreas Widmann for binary import, 2004
%         Arnaud Delorme for Matlab import and EEGLAB interface
%
% See also: eegplugin_bva_io()

% Copyright (C) 2004 Andreas Widmann & Arnaud Delorme
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

function vers = eegplugin_blrk_io(fig, trystrs, catchstrs)

    vers = 'blrk_io_v1.0';
    if nargin < 3
        error('eegplugin_blrk_io requires 3 arguments');
    end;
    
    % add folder to path
    % ------------------
    if ~exist('eegplugin_blrk_io')
        p = which('eegplugin_blrk_io.m');
        p = p(1:findstr(p,'eegplugin_blrk_io.m')-1);
        addpath( p );
    end;
    
    % find import data menu
    % ---------------------
    menuiData = findobj(fig, 'tag', 'import data');
    menuiEvents = findobj(fig, 'tag', 'import event');
    
    % menu callbacks
    % --------------
    icadefs;
    versiontype = 1;
    if exist('EEGLAB_VERSION')
        if EEGLAB_VERSION(1) == '4'
            versiontype = 0;
        end;
    end;
    if versiontype == 0
        comcnt1 = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_loadblrk;'  catchstrs.new_non_empty ];
        comcnt2 = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_loadblrk_eeg;'  catchstrs.new_non_empty ];
        comcnt3 = [ trystrs.no_check '[EEGTMP LASTCOM] = pop_loadblrk_analog;'  catchstrs.new_non_empty ];
        comcnt4 = [ trystrs.no_check '[EEGTMP.event] = parse_blrk_events;'  catchstrs.new_non_empty ];
    else
        comcnt1 = [ trystrs.no_check '[EEG LASTCOM] = pop_loadblrk;'  catchstrs.new_non_empty ];
        comcnt2 = [ trystrs.no_check '[EEG LASTCOM] = pop_loadblrk_eeg;'  catchstrs.new_non_empty ];
        comcnt3 = [ trystrs.no_check '[EEG LASTCOM] = pop_loadblrk_analog;'  catchstrs.new_non_empty ];
        comcnt4 = [ trystrs.no_check '[EEG.event] = parse_blrk_events;'  catchstrs.new_non_empty ];
    end;
                
    % create menus
    % ------------
    uimenu( menuiData, 'label', 'From BlackRock .nsX file',  'callback', comcnt1, 'separator', 'on' );
    uimenu( menuiData, 'label', 'From BlackRock .nsX file, EEG data only',  'callback', comcnt2, 'separator', 'off' );
    uimenu( menuiData, 'label', 'From BlackRock .nsX file, Analog data only',  'callback', comcnt3, 'separator', 'off' );
    uimenu( menuiEvents, 'label', 'From BlackRock .nev file',  'callback', comcnt4, 'separator', 'on' );
