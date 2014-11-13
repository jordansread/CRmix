function [time,DOsun] = getDOsunrise( lakeN,year )

if eq(nargin,0)
    lakeN = 'Sparkling';
    year = '2011';
end
% year is string
% lakeN is string
rootDir = 'Data/';

[dates,DO_s] = gFileOpen([rootDir lakeN '_1m_' year '.dosat']);

days = floor(min(dates)):floor(max(dates));

sunR = sunrise(46, days);

DOsun = interp1(dates,DO_s,days+sunR);

time = days+sunR;
rmvI = isnan(DOsun);
DOsun(rmvI) = [];
time(rmvI)  = [];


end

