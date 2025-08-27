function [drawdown_rate, time_for_rate] = calculate_drawdown_rate(time_data, head_data, units)
%CALCULATE_DRAWDOWN_RATE Calculate drawdown rate from head level data
%
% Converts head level time series to drawdown rate for better comparison
% with DAS displacement rate data.
%
% Inputs:
%   time_data - datetime array of time points
%   head_data - numeric array of head levels (same length as time_data)
%   units     - string: 'ft_per_sec', 'ft_per_min', 'm_per_sec' (default: 'ft_per_min')
%
% Outputs:
%   drawdown_rate - numeric array of drawdown rates
%   time_for_rate - datetime array for rate data (one element shorter)
%
% Example:
%   [rate, time] = calculate_drawdown_rate(Date, Drawdownft, 'ft_per_min');

if nargin < 3
    units = 'ft_per_min';
end

% Validate inputs
if length(time_data) ~= length(head_data)
    error('Time and head data must have the same length');
end

if length(time_data) < 2
    error('Need at least 2 data points to calculate rate');
end

% Remove any NaN values
valid_mask = ~isnan(head_data) & ~isnat(time_data);
time_clean = time_data(valid_mask);
head_clean = head_data(valid_mask);

if length(time_clean) < 2
    error('Need at least 2 valid data points after removing NaN values');
end

% Convert time to seconds for calculation
time_seconds = seconds(time_clean - time_clean(1));

% Calculate rate using gradient (more robust than diff for noisy data)
% gradient automatically handles the time spacing
drawdown_rate_ft_per_sec = gradient(head_clean, time_seconds);

% Time points for rate data (same length as gradient output)
time_for_rate = time_clean;

% Convert to requested units
switch lower(units)
    case 'ft_per_sec'
        drawdown_rate = drawdown_rate_ft_per_sec;
        
    case 'ft_per_min'
        drawdown_rate = drawdown_rate_ft_per_sec * 60;  % Convert ft/s to ft/min
        
    case 'm_per_sec'
        drawdown_rate = drawdown_rate_ft_per_sec * 0.3048;  % Convert ft/s to m/s
        
    otherwise
        error('Unknown units: %s. Use: ft_per_sec, ft_per_min, m_per_sec', units);
end

% Optional: Apply light smoothing to reduce noise in the derivative
% This helps since derivatives amplify noise
if length(drawdown_rate) >= 5
    % Use a 5-point moving average to smooth the rate data
    drawdown_rate = movmean(drawdown_rate, min(5, length(drawdown_rate)));
end

end
