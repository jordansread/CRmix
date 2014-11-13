function buoyMetWrite


clc
close all
varN   = 'wnd';
year  = '2012';

fileInput = 'CrystalLake_AuxilaryTable.dat';
if strcmp(year,'2011')
    fileInput = ['2011\2011' fileInput];
end
airT = struct('varI',5,'rmv',NaN);
rh   = struct('varI',6,'rmv',NaN);
wnd = struct('varI',7,'rmv',NaN);

varStruct = struct('airT',airT,'rh',rh,'wnd',wnd);

fileOut   = ['Data/Crystal_' year '.' varN];

rootFolder = [getenv('USERPROFILE') '\Desktop\CRmix\Data\'];
delim  = ',';
auxVar = '%s %f %s %f %f %f %f %f %f';
varI = varStruct.(varN).varI;

%% loop through vars

fID = fopen([rootFolder fileInput]);
heads= textscan(fID,'%s',(length(auxVar)+1)/3,...
    'HeaderLines',1,'Delimiter',delim);

heads{1} = regexprep(heads{1}, '"', '');
disp(['pivoting and writing ' heads{1}{varI} ' to ' fileOut]);
data = textscan(fID,auxVar,'HeaderLines',4,...
    'Delimiter',delim,'treatAsEmpty','"NAN"');
if strcmp(data{1}(end),'')
    data{1} = data{1}(1:end-1);
end
datesC = regexprep(data{1}, '"', '');
dates = datenum(datesC,'yyyy-mm-dd HH:MM');
timeO = dates;
varO = data{varI};

plot(timeO,varO); pause(1)
gFileSave(fileOut,timeO, varO, varN, 1,'overwrite')

end

