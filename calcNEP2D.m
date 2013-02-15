function calcNEP2D

% -- variables 
tWin    = 7;    % day fraction
rootDir = 'Data/';
dt      = 1/24; % time step of input data

[dates,DOall,heads] = gFileOpen([rootDir 'Crystal_2012.doobs']);

depths = 0:17;
DOall = DOall(:,1:18);

%% open bathy 
fID = fopen([rootDir 'Crystal.bth']);

dat = textscan(fID,'%f %f','Delimiter',',','HeaderLines',1);
bthA = dat{2};  
bthZ = dat{1};
bthA = interp1(bthZ,bthA,depths);

%% calc volumetric DO at all depths

volDO = DOall*NaN;
for z = 1:length(bthA);
    volDO(:,z) = DOall(:,z)*bthA(z);
end


%% timestep eval




end

