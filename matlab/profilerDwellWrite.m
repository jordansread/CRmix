function profilerDwellWrite


clc
close all
varN   = 'dosat';
year  = '2012';

fileInput = 'CrystalLake_SondeTable.dat';
if strcmp(year,'2011')
    fileInput = ['2011\2011' fileInput];
end
wtr = struct('varI',4,'rmv',3);
chla = struct('varI',6,'rmv',2);
doobs = struct('varI',7,'rmv',16);
dosat = struct('varI',8,'rmv',16);

varStruct = struct('wtr',wtr,'chla',chla,'doobs',doobs,'dosat',dosat);

numRmv = varStruct.(varN).rmv;
fileOut   = ['Data/Crystal_1m_' year '.' varN];

rootFolder = [getenv('USERPROFILE') '\Desktop\CRmix\Data\'];
delim  = ',';
sonVar = '%s %f %f %f %f %f %f %f %f';
varI = varStruct.(varN).varI;
zI   = 3;
zInt = 1;
zOff = 0.5;

%% loop through vars

fID = fopen([rootFolder fileInput]);
heads= textscan(fID,'%s',(length(sonVar)+1)/3,...
    'HeaderLines',1,'Delimiter',delim);

heads{1} = regexprep(heads{1}, '"', '');
disp(['pivoting and writing ' heads{1}{varI} ' to ' fileOut]);
data = textscan(fID,sonVar,'HeaderLines',4,...
    'Delimiter',delim,'treatAsEmpty','"NAN"');
if strcmp(data{1}(end),'')
    data{1} = data{1}(1:end-1);
end
datesC = regexprep(data{1}, '"', '');
dates = datenum(datesC,'yyyy-mm-dd HH:MM');

[timeO,varO] = profilerToSurface(dates,data{zI},data{varI},zInt,zOff,numRmv);

plot(timeO,varO); pause(1)
gFileSave(fileOut,timeO, varO, varN, 1,'overwrite')

end

