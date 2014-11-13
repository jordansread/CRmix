function gFileSave(fileName, dates, data, variable, depths, overwrite)
%GFILESAVE Summary of this function goes here
%   Detailed explanation goes here

    if(nargin < 4)
        error('First four function parameters required');
    elseif(nargin == 4)
        depths = NaN;
        overwrite = '';
    elseif(nargin == 5)
        overwrite = '';
    end

    headers = 'DateTime';
    dataFormat = '%s';
    for i=1:length(depths)
        dataFormat = strcat(dataFormat,'\t%0.5g');
        if(isnan(depths(i)))
            headers = sprintf('%s\t%s',headers,variable);
        else
            headers = sprintf('%s\t%s_%s',headers,variable,num2str(depths(i)));
        end
    end
    headers = strcat(headers,'\n');
    dataFormat = strcat(dataFormat,'\n');

    if(strcmpi(overwrite,'overwrite'))
        fid = fopen(fileName,'W+');
    else
        if(exist(fileName,'file'))
            error('File exists and overwrite no specified!');
        end
        fid = fopen(fileName,'W');
    end

    dates = datestr(dates,'yyyy-mm-dd HH:MM:SS');

    fprintf(fid,headers);

    for i=1:size(data,1)
        fprintf(fid,dataFormat,dates(i,:),data(i,:));
    end
    fclose(fid);

end

