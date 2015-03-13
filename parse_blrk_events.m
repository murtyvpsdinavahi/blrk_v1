function DigitalEvents = parse_blrk_events(sRate)

NEV = openNEV('read','nosave','nomat');

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

useSingleITC18Flag = 1;
modifiedDigitalEvents = digitalEvents(digitalEvents>32768) - 32768;
allCodesInDec = unique(modifiedDigitalEvents);
disp(['Number of distinct codes: ' num2str(length(allCodesInDec))]);
allCodesInStr = convertDecCodeToStr(allCodesInDec,useSingleITC18Flag);

% All digital codes all start with a leading 1, which means that they are greater than hex2dec(8000) = 32768.
DigitalEvents = [];
for i=1:length(ModDigiEventIndex)
DigitalEvents(i).code = digitalEvents(ModDigiEventIndex(i)) - 32768;
DigitalEvents(i).type = (convertDecCodeToStr(digitalEvents(ModDigiEventIndex(i)) - 32768));
DigitalEvents(i).value = (digitalEvents(ModDigiEventIndex(i)+1));
DigitalEvents(i).time_sec = (digitalTimeStamps(ModDigiEventIndex(i)));
DigitalEvents(i).latency = DigitalEvents(i).time_sec*sRate;
% DigitalEvents(i).latencyBK = (digitalPos(ModDigiEventIndex(i)));
end

clear identifiedDigitalCodes badDigitalCodes
count=1; badCount=1;
for i=1:length(allCodesInDec)
    if ~digitalCodeDictionary(allCodesInStr(i,:))
        disp(['Unidentified digital code: ' allCodesInStr(i,:) ', bin: ' dec2bin(allCodesInDec(i),16) ', dec: ' num2str(allCodesInDec(i)) ', occured ' num2str(length(find(modifiedDigitalEvents==allCodesInDec(i))))]);
        badDigitalCodes(badCount) = allCodesInDec(i);
        badCount=badCount+1;
    else
        identifiedDigitalCodes(count) = allCodesInDec(i);
        count=count+1;
    end
end

if badCount>1
    error(['The following Digital Codes are bad: ' num2str(badDigitalCodes)]);
end
end