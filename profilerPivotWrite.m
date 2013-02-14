function profilerPivotWrite

clc
close all
fileInput = '2011\2011CrystalLake_SondeTable.dat';
varN   = 'wtr';
fileOut   = ['Data/Crystal_2011.' varN];

rootFolder = [getenv('USERPROFILE') '\Desktop\CRmix\Data\'];
delim  = ',';
sonVar = '%s %f %f %f %f %f %f %f %f';
varI = 4;
zI   = 3;
zInt = 1;
tInt = 1/24;    % day frac
zOff = 0;

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

[timeO,depthO,varO] = profilerTo2D(dates,data{zI},data{varI},zInt,zOff,tInt);

var = data{varI};
dep = data{zI};
useI = gt(dep,0) & lt(dep,1);

plot(timeO,varO);
datetick;
hold on;
plot(dates(useI),var(useI),'c.')
gFileSave(fileOut,timeO, varO, varN, depthO,'overwrite')
end

