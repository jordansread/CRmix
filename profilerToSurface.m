function [timeO,depthO,varO] = profilerToSurface(time,depth,var,zInt,zOff,tInt)

% converts 1D profiler data into 2D matrix of data

% time:     vector of time points for depth and var measurements
% depth:    vector of depth measurements
% var:      vector of measurements of the variable to be converted to 2D
% zInt:     scalar of interval spacing that the profiler uses
% zOff:     scalar offset of depth interval (z = z_meas+zOff)
% tInt:     scalar (day frac) of binning for output

minPt = 3;  % min points for a depth
mxDat = 200;
%% convert data:
depth = depth+zOff;             % now set near actual reading
depth = round(depth*zInt)*zInt; % now rounded to values

% ---throw out points during the rise cycle (points that aren't surrounded by
% similar points---
% should be increasing or staying the same, except to start new dwell at 0

% --remove errant data--
rmvI = gt(var,mxDat) | isnan(var);
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

% -- assign new depths -- 
depthO = unique(depth);
depthO = depthO(~isnan(depthO));
stTime = ceil(time(1)/tInt)*tInt;
timeO  = stTime:tInt:time(end);
varO   = NaN(length(timeO),length(depthO));

for i = 1:length(depthO)
    depI = eq(depth,depthO(i));        % all matching indices for this z
    if lt(sum(depI),minPt);
        depthO(i) = NaN;
    else
        [varDs,timeDs] = downsample_interval(var(depI),time(depI),tInt*86400);
        varO(:,i) = interp1(timeDs,varDs,timeO);
    end
end
nanI = isnan(depthO);
varO(:,nanI) = [];
depthO(nanI) = [];

