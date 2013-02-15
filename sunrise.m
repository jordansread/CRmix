function sr = sunrise(lat, day)
% takes lattitude (deg south should be negative, north positive) and a
% matlab datenum (days since year 0) and returns the time of sunrise as a
% day fraction (e.g., 0.5 would be noon, 0 would be midnight)


%% From Luke W email:
% This is how he does it
% dayAngle <- 2*pi*(day-1)/365
% 
% #Declination of the sun "delta" (radians). Iqbal 1983 Eq. 1.3.1
% dec <- 0.006918 - 0.399912*cos(dayAngle) + 0.070257*sin(dayAngle) - 0.006758*cos(2*dayAngle) +  0.000907*sin(2*dayAngle) - 0.002697*cos(3*dayAngle) + 0.00148*sin(3*dayAngle)
% 
% #Sunrise hour angle "omega" (degrees). Iqbal 1983 Eq. 1.5.4
% latRad <- lat*degToRad
% sunriseHourAngle <- acos(-tan(latRad)*tan(dec))*radToDeg
% 
% #Sunrise and sunset times (decimal hours, relative to solar time) Iqbal 1983 Ex. 1.5.1
% sunrise <- 12 - sunriseHourAngle/15
% sunset <- 12 + sunriseHourAngle/15
% 
% I think he's just assuming the times are in "solar time", i.e., noon is when the sun is directly overhead, which basically is a way to estimate longitude and that is why it doesn't come up in the r code. I'd be happy just using this algorithm.

date = datevec(day);

%get dayofyear by subtracting datenum for jan 0 of that year
day = day - datenum([date(1) 1 0]);

numDays = datenum(date(1)+1,1,0)-datenum(date(1),1,0);

dayAngle = 2*pi*(day-1)/numDays;


degToRad = 2*pi/360;
radToDeg = 180/pi;

%Declination of the sun "delta" (radians). Iqbal 1983 Eq. 1.3.1
dec = 0.006918 - 0.399912*cos(dayAngle) + 0.070257*sin(dayAngle) - 0.006758*cos(2*dayAngle) +  0.000907*sin(2*dayAngle) - 0.002697*cos(3*dayAngle) + 0.00148*sin(3*dayAngle);

%Sunrise hour angle "omega" (degrees). Iqbal 1983 Eq. 1.5.4
latRad = lat*degToRad;
sunriseHourAngle = acos(-tan(latRad)*tan(dec))*radToDeg;

%Sunrise and sunset times (decimal hours, relative to solar time) Iqbal 1983 Ex. 1.5.1
sr = 12 - sunriseHourAngle/15;
%convert to day frac
sr = sr/24;

