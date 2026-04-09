function bounds = calculate_dynamic_bounds(data, mode, varargin)
%CALCULATE_DYNAMIC_BOUNDS Calculate intelligent bounds for plot data
%
% Calculates dynamic bounds using various methods to reduce noise sensitivity
% while preserving signal characteristics.
%
% Inputs:
%   data - Numeric array or cell array of datasets
%   mode - String specifying calculation method:
%          'percentile' - Use percentile-based bounds (default)
%          'std_dev'    - Use standard deviation scaling
%          'robust'     - Use interquartile range with padding
%          'hybrid'     - Combine percentiles with minimum range
%          'minmax'     - Simple min/max (original behavior)
%
% Optional Parameters (name-value pairs):
%   'Percentiles'    - [lower, upper] percentiles (default: [10, 90])
%   'StdDevFactor'   - Standard deviation multiplier (default: 2)
%   'RobustPadding'  - IQR padding factor (default: 0.5)
%   'MinRange'       - Minimum range guarantee (default: auto)
%   'Symmetric'      - Force symmetric bounds around center (default: false)
%
% Output:
%   bounds - [lower_bound, upper_bound]

% Default parameters
p = inputParser;
addRequired(p, 'data');
addRequired(p, 'mode', @ischar);
addParameter(p, 'Percentiles', [10, 90], @(x) isnumeric(x) && length(x)==2);
addParameter(p, 'StdDevFactor', 2, @isnumeric);
addParameter(p, 'RobustPadding', 0.5, @isnumeric);
addParameter(p, 'MinRange', [], @isnumeric);
addParameter(p, 'Symmetric', false, @islogical);
parse(p, data, mode, varargin{:});

% Convert cell array of datasets to single array
if iscell(data)
    combined_data = [];
    for i = 1:length(data)
        if isnumeric(data{i}) && ~isempty(data{i})
            combined_data = [combined_data; data{i}(:)];
        end
    end
    data = combined_data;
else
    data = data(:);  % Flatten to column vector
end

% Remove NaN and Inf values
data = data(isfinite(data));
if isempty(data)
    bounds = [0, 1];
    warning('No finite data found, using default bounds [0, 1]');
    return;
end

% Calculate bounds based on method
switch lower(mode)
    case 'percentile'
        bounds = calculate_percentile_bounds(data, p.Results.Percentiles);
        
    case 'std_dev'
        bounds = calculate_std_bounds(data, p.Results.StdDevFactor);
        
    case 'robust'
        bounds = calculate_robust_bounds(data, p.Results.RobustPadding);
        
    case 'hybrid'
        bounds = calculate_hybrid_bounds(data, p.Results.Percentiles, p.Results.MinRange);
        
    case 'minmax'
        bounds = [min(data), max(data)];
        
    otherwise
        error('Unknown mode: %s. Use percentile, std_dev, robust, hybrid, or minmax', mode);
end

% Apply minimum range if specified
if ~isempty(p.Results.MinRange)
    current_range = bounds(2) - bounds(1);
    if current_range < p.Results.MinRange
        center = mean(bounds);
        half_range = p.Results.MinRange / 2;
        bounds = [center - half_range, center + half_range];
    end
end

% Apply symmetric bounds if requested
if p.Results.Symmetric
    max_abs = max(abs(bounds));
    bounds = [-max_abs, max_abs];
end

end

function bounds = calculate_percentile_bounds(data, percentiles)
%CALCULATE_PERCENTILE_BOUNDS Use percentile-based bounds
lower_bound = prctile(data, percentiles(1));
upper_bound = prctile(data, percentiles(2));
bounds = [lower_bound, upper_bound];
end

function bounds = calculate_std_bounds(data, std_factor)
%CALCULATE_STD_BOUNDS Use standard deviation scaling
data_median = median(data);
data_std = std(data);
lower_bound = data_median - std_factor * data_std;
upper_bound = data_median + std_factor * data_std;
bounds = [lower_bound, upper_bound];
end

function bounds = calculate_robust_bounds(data, padding_factor)
%CALCULATE_ROBUST_BOUNDS Use interquartile range with padding
q25 = prctile(data, 25);
q75 = prctile(data, 75);
iqr = q75 - q25;
lower_bound = q25 - padding_factor * iqr;
upper_bound = q75 + padding_factor * iqr;
bounds = [lower_bound, upper_bound];
end

function bounds = calculate_hybrid_bounds(data, percentiles, min_range)
%CALCULATE_HYBRID_BOUNDS Combine percentiles with minimum range
% Start with percentile bounds
bounds = calculate_percentile_bounds(data, percentiles);

% Auto-determine minimum range if not specified
if isempty(min_range)
    data_range = max(data) - min(data);
    min_range = data_range * 0.1;  % 10% of full data range
end

% Ensure minimum range
current_range = bounds(2) - bounds(1);
if current_range < min_range
    center = mean(bounds);
    half_range = min_range / 2;
    bounds = [center - half_range, center + half_range];
end
end
