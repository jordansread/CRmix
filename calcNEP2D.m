function [time,NEP] = calcNEP2D(year)

%close all
% -- variables 
tWin    = 14;    % day fraction, for delT
stWin  = 3;    % stepping forward window
rootDir = 'Data/';

if eq(nargin,0)
    year = '2012';
end

atmP = 715;
dt      = 1/24; % time step of input data
k600= 0.4;  % should be timeseries

[dates,DOall] = gFileOpen([rootDir 'Crystal_' year '.doobs']);

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


% total DO

DOall = dates*NaN;
for j = 1:length(dates);
    valD = volDO(j,:);
    DOall(j) = sum(valD);
end
% remove/smooth outliers
rmvI = isnan(DOall);
DOall(rmvI) = [];
dates(rmvI) = [];
nDates = min(dates):dt:max(dates);
DOall = interp1(dates,DOall,nDates);

%% supplemental sets
[dates,dosat] = gFileOpen([rootDir 'Crystal_1m_' year '.dosat']);
dosat = interp1(dates,dosat(:,1),nDates);

[dates,wtr_s] = gFileOpen([rootDir 'Crystal_1m_' year '.wtr']);
wtr_s = interp1(dates,wtr_s(:,1),nDates);



%% timestep eval

stpWin = tWin/dt;

delDO = NaN(length(nDates)-stpWin,1);
F = delDO;
tmeWin = delDO;

for j = stpWin:stWin/dt:length(nDates)
    i_1 = j-stpWin+1;
    i_2 = j;
    DO2 = DOall(i_2)/bthA(1)*1000/(15.999*2); %convert to uM;
    DO1 = DOall(i_1)/bthA(1)*1000/(15.999*2); %convert to uM;
    
    tmeWin(i_1) = mean([nDates(i_1) nDates(i_2)]);
    delTm = nDates(i_2)-nDates(i_1);
    delDO(i_1) = (DO2-DO1)/delTm;
    gasLoss = NaN(length(i_1:i_2),1);
    
    for iz = i_1:i_2
        
        SDO2 = Sat2Conc(dosat(iz), wtr_s(iz));
        DOuMs = SatdConc(wtr_s(iz),atmP);
        schmidt = schmidtFromTemp(wtr_s(iz));
        kO2 = k600*(schmidt/600)^-0.5;
        if eq(iz,1)
            dts = nDates(2)-nDates(1);
        else
            dts = nDates(iz)-nDates(iz-1);
        end
        gasLoss(iz-i_1+1) = kO2*dts*(DOuMs-SDO2);
    end
    gasLoss = gasLoss(~isnan(gasLoss));
    F(i_1) = sum(gasLoss)/delTm;
end


%% remove or add via gas flux


%schmidt = (1800.6-120.1*Temp)+(3.7818*Temp^2)-0.047608*Temp^3;
%Wind10 = Wind/(WindHeight/10)^0.15; %wind at 10m, from wind at 2m
%k02 = k600*(schmidt/600)^-0.5;

%%  
    function schmidt = schmidtFromTemp(Temp)
        schmidt = (1800.6-120.1*Temp)+(3.7818*Temp^2)-0.047608*Temp^3;
    end

    function [SDO2uM] = Sat2Conc(SDO2sat, SDtemp)
        
        SDO2mgL=(SDO2sat/100)*(-0.00000002057759*SDtemp^5+0.000002672016*SDtemp^4+(-0.0001884085)*SDtemp^3+0.009778012*SDtemp^2+(-0.4147241)*SDtemp+14.621);
        SDO2uM=SDO2mgL*1000/(15.999*2);
    end

    function [DOuM] = SatdConc(celcius, mmHg)
		% Weiss 1970 Deep Sea Res. 17:721-735
		%ln DO = A1 + A2 100/T + A3 ln T/100 + A4 T/100...
		%   + S [B1 + B2 T/100 + B3 (T/100)2]
		%where DO is ml/L; convert to mg/L by mult by 1.4276
		%where
		A1=-173.4292; 
		A2=249.6339;
		A3=143.3483;
		A4 = -21.8492;
		%and T = temperature degrees K (C + 273.15) S=salinity (g/kg, o/oo)
		T=celcius+273.15;
		DOt=(exp(((A1 + (A2*100/T) + A3*log(T/100) + A4*(T/100)))));
		%pressure correction:
		%from USGS memo #81.11 and 81.15 1981, based on empiracal data in Handbook
		%of Chemistry and Physics, 1964.
		u=10^(8.10765 - (1750.286/(235+celcius)));
		DOsat=(DOt*((mmHg-u)/(760-u))); %ml/L
		DOsat=DOsat/1000; %L/L
		%conversion factor
		%convert using standard temperature and pressure.  Similar to calculating
		%saturation DO at STP in ml/L, converting to mg?L (at STP), and then doing
		%the above temperature and pressure conversions.
		R=0.082057; % L atm deg-1 mol-1
		O2molwt=15.999*2;
		convfactor=O2molwt*(1/R)*(1/273.15)*(760/760); %g/L
		DOmgL=DOsat*convfactor*1000; %mg/L
		DOuM=DOmgL*1000/(15.999*2); %convert to uM
    end

figure

usI= ~isnan(delDO);
time = tmeWin(usI);
NEP  = delDO(usI)-F(usI);

end

