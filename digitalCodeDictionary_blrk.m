% digitalCodeDictionary(str);
%
% Digital Code dictionary
% This program maintains a list of all the codes that are put in the digital data
% stream by various Lablib programs.
%
% Same program created by Dr. Supratim Ray, name changed by Murty Dinavahi
% so that all functions that are used by blrk plugin are found in one
% place for ease.

function codeExistsFlag = digitalCodeDictionary_blrk(str)

if ~exist('str','var');                     str='';                     end

codeList = [...     
    'AL'; % Attend Loc
    'AO'; % Auditory Orientation
    'AS'; % Auditory SF
    'AT'; % Audio TF
    'AV'; % Audio Volume
    'AZ'; % Azimuth
    'BR'; % Break
    'CO'; % Contrast
    'CT'; % Catch Trial
    'EC'; % Eccentricity
    'EL'; % Elevation
    'FI'; % Fixate
    'FO'; % Fix On
    'IT'; % Instruct Trial
    'M0'; % Mapping 0
    'M1'; % Mapping 1
    'ON'; % Stimulus On
    'OF'; % Stimulus Off
    'OR'; % Orientation
    'PA'; % Polar Angle
    'RA'; % Radius
    'SA'; % Saccade
    'SF'; % Spatia Frequency
    'SI'; % Sigma
    'ST'; % Stim Type
    'TC'; % Trial Certify
    'TE'; % Trial End
    'TF'; % Temporal Frequency
    'TG'; % Task Gabor
    'TS'; % Trial Start
    'T0'; % Type 0
    'T1'; % Type 1
];

if isempty(str)
    disp(codeList);
    codeExistsFlag=1;
else
    codeExistsFlag=0;
    for i=1:size(codeList,1)
        if isequal(str,codeList(i,:))
            codeExistsFlag=1;
            break;
        end
    end
end