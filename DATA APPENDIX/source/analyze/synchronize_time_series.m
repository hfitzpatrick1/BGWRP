function [data1_sync, data2_sync, sync_time] = synchronize_time_series(data1, time1, data2, time2)
%SYNCHRONIZE_TIME_SERIES Synchronize two time series to common time grid
%
% Inputs:
%   data1, time1 - First time series data and time vector
%   data2, time2 - Second time series data and time vector
%
% Outputs:
%   data1_sync, data2_sync - Synchronized data arrays
%   sync_time - Common time vector

% Find common time range
start_time = max(time1(1), time2(1));
end_time = min(time1(end), time2(end));

% Create common time grid (1-second intervals)
sync_time = start_time:seconds(1):end_time;

% Interpolate both datasets to common time grid
data1_sync = interp1(time1, data1, sync_time, 'linear', 'extrap');
data2_sync = interp1(time2, data2, sync_time, 'linear', 'extrap');

% Remove any NaN values
valid_mask = ~isnan(data1_sync) & ~isnan(data2_sync);
data1_sync = data1_sync(valid_mask);
data2_sync = data2_sync(valid_mask);
sync_time = sync_time(valid_mask);
end
