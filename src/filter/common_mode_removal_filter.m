function filtered_data = common_mode_removal_filter(data, time_array, config)
% COMMON_MODE_REMOVAL_FILTER - Remove common mode noise using reference window normalization
%
% This filter removes systematic vertical banding (common mode noise) by normalizing
% the data using a reference period where minimal activity occurs.
%
% Input:
%   data        - DAS data [time x channels]
%   time_array  - Time array corresponding to data rows
%   config      - Configuration structure with filter parameters
%
% Output:
%   filtered_data - DAS data with common mode noise removed [time x channels]
%
% Configuration Parameters:
%   config.ref_start_time    - Reference window start time (datetime)
%   config.ref_end_time      - Reference window end time (datetime)
%   config.smooth_reference  - Smooth reference signal (default: true)
%   config.smooth_window     - Smoothing window for reference (default: 3)

fprintf('  Applying common mode removal filter...\n');

% Get configuration parameters
ref_start_time = get_param(config, 'ref_start_time', []);
ref_end_time = get_param(config, 'ref_end_time', []);
smooth_reference = get_param(config, 'smooth_reference', true);
smooth_window = get_param(config, 'smooth_window', 3);

% Validate reference time window
if isempty(ref_start_time) || isempty(ref_end_time)
    error('Reference time window must be specified in config (ref_start_time, ref_end_time)');
end

fprintf('    Reference window: %s to %s\n', ref_start_time, ref_end_time);

% Find reference window indices
ref_mask = time_array >= ref_start_time & time_array <= ref_end_time;
ref_indices = find(ref_mask);

if length(ref_indices) < 2
    error('Reference window too short or not found in time array');
end

fprintf('    Reference window: %d time points\n', length(ref_indices));

% Calculate depth-averaged reference signal for each time step
% This captures the common mode component
reference_signal = mean(data(ref_indices, :), 2);  % Average across depths (channels)

% Optional: smooth the reference signal to avoid amplifying noise
if smooth_reference
    reference_signal = movmean(reference_signal, smooth_window, 'omitnan');
    fprintf('    Smoothed reference signal with %d-point window\n', smooth_window);
end

% Handle potential zero-crossings in reference signal
% Add small epsilon to avoid division by zero
epsilon = 1e-10;
reference_signal = reference_signal + epsilon * sign(reference_signal);

% Apply normalization: divide each depth by the reference signal
filtered_data = zeros(size(data));
for t = 1:size(data, 1)
    if ref_mask(t)  % Within reference window
        % Use the reference signal directly
        filtered_data(t, :) = data(t, :) ./ reference_signal(t - ref_indices(1) + 1);
    else
        % For times outside reference window, use interpolated reference
        % Find the closest reference time point
        [~, closest_idx] = min(abs(time_array(t) - time_array(ref_indices)));
        ref_time_idx = ref_indices(closest_idx);
        ref_signal_idx = closest_idx;
        
        filtered_data(t, :) = data(t, :) ./ reference_signal(ref_signal_idx);
    end
end

% Report results
fprintf('    Common mode removal complete\n');
fprintf('    Data range: [%.3f, %.3f] -> [%.3f, %.3f]\n', ...
    min(data(:)), max(data(:)), min(filtered_data(:)), max(filtered_data(:)));

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end

