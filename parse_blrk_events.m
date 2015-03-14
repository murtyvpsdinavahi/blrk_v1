function DigitalEvents = parse_blrk_events(fname,sRate)    

if nargin==2
    mrkFile = [fname(1:(end-4)) '.nev'];

    if exist(mrkFile, 'file') ~= 2
        warndlg2('No .nev (marker) file in the specified location. Select .nev file to load markers.');
        fileExt = {'*.nev'};
        [hdrfile,path] = uigetfile2(fileExt, 'Select .nev (marker) file');
        if hdrfile(1) == 0
           warndlg2('No Marker File Selected. Hence no events loaded. Events can be loaded later from menu item File/Import event info.');
           disp('No marker file associated with the data file. Hence no parsed events.')
           DigitalEvents=[];
           return;
        end    
        mrkFile = [path hdrfile];
    end
else
    fileExt = {'*.nev'};
    [hdrfile,path] = uigetfile2(fileExt, 'Select .nev (marker) file');
    if hdrfile(1) == 0
       warndlg2('No Marker File Selected. Hence no events loaded.');
       disp('No marker file associated with the data file. Hence no parsed events.')
       DigitalEvents=[];
       return;
    end  
    mrkFile = [path hdrfile];
    sRate = evalin('base','EEG.srate');
end

disp('Loading marker file and parsing markers...');
NEV = openNEV(mrkFile,'read','nosave','nomat','nomultinsp');

digitalEvents = NEV.Data.SerialDigitalIO.UnparsedData;
digitalPos = NEV.Data.SerialDigitalIO.TimeStamp;
digitalTimeStamps = NEV.Data.SerialDigitalIO.TimeStampSec;

% Blackrock collects data at 30,000 samples per second. Sometimes a digital
% code transition takes longer than this, and is counted twice. First we
% find out the double counts.

deltaLimit = 1.5/30000; 
dt = diff(digitalTimeStamps);
badDTPos = find(dt<=deltaLimit);

if ~isempty(badDTPos)
    disp([num2str(length(badDTPos)) ' of ' num2str(length(digitalTimeStamps)) ' (' num2str(100*length(badDTPos)/length(digitalTimeStamps),2) '%) are repeats and will be discarded']);
    digitalTimeStamps(badDTPos)=[];
    digitalEvents(badDTPos)=[];
end

% First, find the reward signals
rewardOnPos = find(rem(digitalEvents,2)==0);
rewardOffPos = find(digitalEvents==2^16-1);

if length(rewardOnPos)~=length(rewardOffPos)
    disp('Unequal number of reward on and reward off!!');
else
    rewardPos = [rewardOnPos(:) ; rewardOffPos(:)];
    disp([num2str(length(rewardPos)) ' are reward signals and will be discarded' ]);
    digitalEvents(rewardPos)=[];
    digitalTimeStamps(rewardPos)=[];
end
digitalEvents=digitalEvents-1;

ModDigiEventIndex=find(digitalEvents>32768);

% All digital codes all start with a leading 1, which means that they are greater than hex2dec(8000) = 32768.
DigitalEvents = [];

for i=1:length(ModDigiEventIndex)
DigiCode = digitalEvents(ModDigiEventIndex(i)) - 32768;
BinCode=dec2bin(DigiCode,16);
DigitalEvents(i).code = DigiCode;
DigitalEvents(i).type = [char(bin2dec(BinCode(2:8))) char(bin2dec(BinCode(9:15)))];
DigitalEvents(i).value = (digitalEvents(ModDigiEventIndex(i)+1));
DigitalEvents(i).time_sec = (digitalTimeStamps(ModDigiEventIndex(i)));
DigitalEvents(i).latency = DigitalEvents(i).time_sec*sRate;
allCodesInDec(i) = DigitalEvents(i).code;
end


uniqueCodesInDec = unique(allCodesInDec);
uniqueCodesInStr = unique({DigitalEvents.type});
disp(['Number of distinct codes: ' num2str(length(uniqueCodesInStr))]);

clear identifiedDigitalCodes badDigitalCodes
count=1; badCount=1;

for i=1:length(uniqueCodesInDec)
    if ~digitalCodeDictionary_blrk(uniqueCodesInStr{1,i})
        disp(['Unidentified digital code: ' uniqueCodesInStr(i,:) ', bin: ' dec2bin(uniqueCodesInDec(i),16) ', dec: ' num2str(uniqueCodesInDec(i)) ', occured ' num2str(length(find(allCodesInDec==uniqueCodesInDec(i))))]);
        badDigitalCodes(badCount) = uniqueCodesInDec(i);
        badCount=badCount+1;
    end
end

if badCount>1
    error(['The following Digital Codes are bad: ' num2str(badDigitalCodes)]);
end
end