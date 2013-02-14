function [timeO,varO] = profilerToSurface(time,depth,var,zInt,zOff)

% converts 1D profiler data into 2D matrix of data

% time:     vector of time points for depth and var measurements
% depth:    vector of depth measurements
% var:      vector of measurements of the variable to be converted to 2D
% zInt:     scalar of interval spacing that the profiler uses
% zOff:     scalar offset of depth interval (z = z_meas+zOff)
% tInt:     scalar (day frac) of binning for output

mxDat = 200;
%% convert data:
depth = depth+zOff;             % now set near actual reading
depth = round(depth*zInt)*zInt; % now rounded to values

% ---throw out points during the rise cycle (points that aren't surrounded by
% similar points---
% should be increasing or staying the same, except to start new dwell at 0

% --remove errant data--
rmvI = gt(var,mxDat) | isnan(var) | isnan(depth);
time = time(~rmvI);
depth= depth(~rmvI);
var  = var(~rmvI);

% --remove upward travel-- *assumes profiler is not errant
dif = depth(2:end)-depth(1:end-1);
dif(end+1) = 0;
moveI = lt(dif,0)&ne(depth,max(depth));
moveI(end+1)= false;
depth(moveI) = [];
time(moveI) = [];
var(moveI) = [];
useI = eq(depth,1);
timeO = time(useI);
varO = var(useI);

gap = timeO(2:end)-timeO(1:end-1)

