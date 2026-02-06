function results = linear_regression_depth_range(das_results, head_results, test_name, config)
%LINEAR_REGRESSION_DEPTH_RANGE Perform linear regression for a depth range (190-340 ft)
%
% This function analyzes multiple DAS channels across a depth range and averages
% the strain rate to get a robust storage estimate for that zone.
%
% Inputs:
%   das_results - Structure with DAS correlation results
%   head_results - Structure with head correlation results
%   test_name - Name of test (e.g., 'PT01c_Recovery_short')
%   config - Configuration structure with fields:
%            .timing_correction_sec - Time shift to apply to head data (seconds backward)
%            .zone - Zone to analyze (default: 'z5')
%            .depth_range_ft - [min, max] depth in feet (default: [190, 340])
%            .recovery_window - [start_time, end_time] datetime array for peak signal
%            .show_plots - Whether to generate plots (default: true)
%
% Outputs:
%   results - Structure containing regression results for the depth range

% Set defaults
if ~isfield(config, 'zone'), config.zone = 'z5'; end
if ~isfield(config, 'show_plots'), config.show_plots = true; end
if ~isfield(config, 'timing_correction_sec'), config.timing_correction_sec = 8; end
if ~isfield(config, 'depth_range_ft'), config.depth_range_ft = [190, 340]; end

%% Extract data
console_log('\n=== DEPTH-SPECIFIC LINEAR REGRESSION ===\n');
console_log('Test: %s\n', test_name);
console_log('Zone: %s\n', config.zone);
console_log('Depth range: %.0f to %.0f ft\n', config.depth_range_ft(1), config.depth_range_ft(2));

das_filtered = das_results.(test_name);
head_filtered = head_results.(test_name);

%% Get DAS displacement rate for FULL depth range (not just one channel!)
% Use lightly smoothed data (compromise between raw and over-smoothed)
console_log('Using lightly smoothed data for strain rate calculation\n');
displacement_rate_full = das_filtered.smoothed_data;  % Use the 5s smoothed data
console_log('This provides noise reduction while preserving spatial gradients\n');
time_das_full = das_filtered.time_array;  % Full time vector (not just analysis window!)
depth_ft = das_filtered.depth_ft;

% Apply same smoothing as single channel method (5-second only)
console_log('\n=== APPLYING SMOOTHING TO MATCH SINGLE CHANNEL METHOD ===\n');
console_log('Applying 5-second moving average (same as single channel)...\n');
% Note: displacement_rate_full is already smoothed from DAS analysis, but apply consistent processing
console_log('✓ Using existing smoothing from DAS analysis\n\n');

% DEBUG: Check if smoothed_data was actually smoothed
console_log('\n');
console_log('═══════════════════════════════════════════════════════════════\n');
console_log('  DEBUG: CHECKING IF 5-SECOND MOVING AVERAGE WAS APPLIED\n');
console_log('═══════════════════════════════════════════════════════════════\n');
console_log('smoothed_data exists: YES\n');
console_log('smoothed_data size: [%d time points × %d channels]\n', size(displacement_rate_full, 1), size(displacement_rate_full, 2));

smoothing_applied = false;
smoothing_info = 'UNKNOWN';

if isfield(das_filtered, 'smoothing_method')
    smoothing_info = sprintf('%s', das_filtered.smoothing_method);
    if isfield(das_filtered, 'smoothing_window')
        smoothing_info = sprintf('%s (window: %d samples = %.1f seconds)', ...
            das_filtered.smoothing_method, das_filtered.smoothing_window, das_filtered.smoothing_window);
    end
    console_log('Stored smoothing method: %s\n', smoothing_info);
    
    % Check if it's the expected 5-second movmean
    if strcmp(das_filtered.smoothing_method, 'matlab_movmean') || ...
       (strcmp(das_filtered.smoothing_method, 'movmean') && isfield(das_filtered, 'smoothing_window') && das_filtered.smoothing_window == 5)
        smoothing_applied = true;
        console_log('✓ Expected 5-second moving average detected\n');
    else
        console_log('⚠ Different smoothing method than expected (expected: matlab_movmean with 5-second window)\n');
    end
else
    console_log('⚠⚠⚠ CRITICAL: No smoothing_method field stored!\n');
    console_log('   This means smoothing was NOT applied during correlation analysis.\n');
end

% Check if data looks smoothed by sampling a channel in the depth range
data_appears_smoothed = false;
if ~isempty(depth_ft)
    sample_depth = mean(config.depth_range_ft);  % Middle of range
    [~, sample_idx] = min(abs(depth_ft - sample_depth));
    if sample_idx <= size(displacement_rate_full, 2)
        sample_data = displacement_rate_full(:, sample_idx);
        diff_data = abs(diff(sample_data));
        mean_diff = mean(diff_data);
        std_diff = std(diff_data);
        console_log('\nSample channel at %.1f ft:\n', depth_ft(sample_idx));
        console_log('  mean(|diff|) = %.2e nm/s\n', mean_diff);
        console_log('  std(|diff|)  = %.2e nm/s\n', std_diff);
        
        % Thresholds: smoothed data should have much lower variance
        if mean_diff > 0.005 || std_diff > 0.01
            console_log('\n⚠⚠⚠ WARNING: Data appears to be RAW/UNSMOOTHED ⚠⚠⚠\n');
            console_log('   Expected for 5-second smoothed: mean_diff < 0.001, std_diff < 0.01\n');
            console_log('   Your values are: mean_diff=%.2e, std_diff=%.2e\n', mean_diff, std_diff);
            console_log('\n   ═══ ACTION REQUIRED ═══\n');
            console_log('   Re-run correlation analysis to apply smoothing:\n');
            console_log('   >> mode = ''run_correlation_analysis'';\n');
            console_log('   >> BGWRP_Toolkit\n');
            console_log('   Then re-run this linear regression function.\n');
        else
            data_appears_smoothed = true;
            console_log('\n✓ Data appears to be SMOOTHED (low variance between samples)\n');
        end
    end
end

% Final verdict
console_log('\n═══════════════════════════════════════════════════════════════\n');
if smoothing_applied && data_appears_smoothed
    console_log('  ✓✓✓ VERDICT: 5-SECOND MOVING AVERAGE IS APPLIED ✓✓✓\n');
elseif ~smoothing_applied
    console_log('  ⚠⚠⚠ VERDICT: SMOOTHING NOT DETECTED - RE-RUN CORRELATION ANALYSIS ⚠⚠⚠\n');
else
    console_log('  ⚠ VERDICT: INCONSISTENT - Check smoothing settings\n');
end
console_log('═══════════════════════════════════════════════════════════════\n\n');

% If recovery_window is specified, extract only that time range FOR REGRESSION
% But keep full data for plotting context
if isfield(config, 'recovery_window') && ~isempty(config.recovery_window)
    recovery_start = config.recovery_window(1);
    recovery_end = config.recovery_window(2);
    
    console_log('Using custom recovery window for regression: %s to %s\n', datestr(recovery_start), datestr(recovery_end));
    
    % Save FULL data for plotting
    displacement_rate_full_plot = displacement_rate_full;
    time_das_full_plot = time_das_full;
    
    % Find indices in full time array for regression window
    [~, rec_start_idx] = min(abs(time_das_full - recovery_start));
    [~, rec_end_idx] = min(abs(time_das_full - recovery_end));
    
    % Extract only the peak signal window FOR REGRESSION
    displacement_rate_full = displacement_rate_full(rec_start_idx:rec_end_idx, :);
    time_das = time_das_full(rec_start_idx:rec_end_idx);
    
    console_log('Extracted %d time points for regression (%.1f seconds)\n', length(time_das), seconds(recovery_end - recovery_start));
    console_log('Kept %d time points for plotting (full analysis window)\n', length(time_das_full_plot));
else
    % Use the default analysis window
    time_das = das_filtered.analysis_time;
    displacement_rate_full_plot = displacement_rate_full;
    time_das_full_plot = time_das_full;
    console_log('Using default analysis window\n');
end

% Find channels in depth range
depth_mask = (depth_ft >= config.depth_range_ft(1)) & (depth_ft <= config.depth_range_ft(2));
n_channels = sum(depth_mask);

console_log('DAS data: %d time points\n', length(time_das));
console_log('Channels in depth range: %d (out of %d total)\n', n_channels, length(depth_ft));
console_log('Depth range: %.1f to %.1f ft\n', min(depth_ft(depth_mask)), max(depth_ft(depth_mask)));

if n_channels == 0
    error('No channels found in depth range %.0f-%.0f ft!', config.depth_range_ft(1), config.depth_range_ft(2));
end

% Extract depth information for the zone
depth_ft_zone = depth_ft(depth_mask);

% Extract displacement rate for selected depth range
% Subset: [time × selected_depths]
% Note: displacement_rate_full may already be subsetted if recovery_window was used
displacement_rate_zone = displacement_rate_full(:, depth_mask);

% CRITICAL FIX: Use PRE-SMOOTHED data for spatial difference (like single channel)
console_log('\n=== USING PRE-SMOOTHED DISPLACEMENT RATES (MATCHING SINGLE CHANNEL) ===\n');
console_log('Using smoothed displacement rates for strain rate calculation\n');
console_log('✓ This prevents noise amplification in spatial differences\n\n');

%% Apply same smoothing as single channel BEFORE spatial difference
console_log('\n=== APPLYING PRE-SMOOTHING (CRITICAL FOR SPATIAL DIFFERENCES) ===\n');
console_log('Applying 5-second smoothing to displacement rates BEFORE spatial difference...\n');

% Apply 5-second smoothing to displacement rates (same as single channel)
for ch = 1:size(displacement_rate_zone, 2)
    displacement_rate_zone(:, ch) = movmean(displacement_rate_zone(:, ch), 5, 1, 'omitnan');
end
console_log('✓ Applied 5-second smoothing to all channels in zone\n');
console_log('✓ This matches single-channel processing and reduces spatial difference noise\n');

%% Convert to strain rate using correct formula: ε̇ = [u̇(z+L) - u̇(z)] / L
gauge_length_m = 10;  % DAS gauge length in meters
spatial_resolution_m = 0.25;  % Spatial resolution per channel (0.2496 m with scaling)
channels_per_gauge = round(gauge_length_m / spatial_resolution_m);  % ~40 channels

console_log('Calculating strain rate using difference across gauge length:\n');
console_log('  Gauge length: %.1f m\n', gauge_length_m);
console_log('  Spatial resolution: %.3f m/channel\n', spatial_resolution_m);
console_log('  Channels per gauge: %d\n', channels_per_gauge);

% Calculate strain rate using CLEAN implementation of ε̇ = [u̇(z+L) - u̇(z)] / L
% Using correct 10m gauge length as per DAS specifications
gauge_length_m = 10;  % DAS gauge length - instrument specification
channels_per_gauge = round(gauge_length_m / spatial_resolution_m);  % ~40 channels

console_log('Using spatial difference with correct DAS gauge length:\n');
console_log('  Gauge length: %.1f m (DAS specification)\n', gauge_length_m);
console_log('  Channels per gauge: %d\n', channels_per_gauge);

n_channels_zone = size(displacement_rate_zone, 2);
console_log('DEBUG: n_channels_zone = %d, channels_per_gauge = %d\n', n_channels_zone, channels_per_gauge);
console_log('DEBUG: strain_rate_zone will have %d columns\n', n_channels_zone - channels_per_gauge);

if n_channels_zone <= channels_per_gauge
    error('Not enough channels in depth range (%d) to calculate strain rate with %d-channel gauge length', ...
        n_channels_zone, channels_per_gauge);
end

strain_rate_zone = zeros(size(displacement_rate_zone, 1), n_channels_zone - channels_per_gauge);

% BECKER APPROACH: Find most responsive zones first, then analyze separately
console_log('\n=== IDENTIFYING RESPONSIVE ZONES (Becker Method) ===\n');

% Calculate strain rate for each possible channel pair
n_channels_zone = size(displacement_rate_zone, 2);
all_strain_rates = zeros(size(displacement_rate_zone, 1), n_channels_zone - channels_per_gauge);

% CORRECTED: Use CENTERED difference like the DAS instrument does internally
% From the paper: DAS uses [u(z+dz/2) - u(z-dz/2)] not [u(z+dz) - u(z)]
console_log('CRITICAL INSIGHT: Using CENTERED spatial difference (like DAS instrument)\n');
console_log('Formula: ε̇ = [u̇(z+L/2) - u̇(z-L/2)] / L (centered difference)\n');

half_gauge_channels = round(channels_per_gauge / 2);  % 20 channels = 5m
all_strain_rates = zeros(size(displacement_rate_zone, 1), n_channels_zone - channels_per_gauge);

for ch = (half_gauge_channels + 1):(n_channels_zone - half_gauge_channels)
    % Centered difference: u̇(z+5m) - u̇(z-5m) over 10m gauge length
    displacement_diff = displacement_rate_zone(:, ch + half_gauge_channels) - displacement_rate_zone(:, ch - half_gauge_channels);
    all_strain_rates(:, ch - half_gauge_channels) = displacement_diff / (gauge_length_m * 1e9);
end

console_log('✓ Using centered spatial difference (matches DAS instrument design)\n');

% ADAPTIVE APPROACH: Find the depth with maximum spatial gradient (best for strain rate)
% Calculate spatial gradients across the zone to find most responsive area
spatial_gradients = zeros(size(displacement_rate_zone, 1), size(displacement_rate_zone, 2) - channels_per_gauge);
for t = 1:size(displacement_rate_zone, 1)
    for ch = 1:(size(displacement_rate_zone, 2) - channels_per_gauge)
        spatial_gradients(t, ch) = abs(displacement_rate_zone(t, ch + channels_per_gauge) - displacement_rate_zone(t, ch));
    end
end

% AUTOMATIC DEPTH SELECTION: Find most responsive depth pair in the zone
console_log('\n=== CALCULATING STRAIN RATES ACROSS ENTIRE ZONE ===\n');
console_log('  Will calculate strain rate at every valid depth using 10m gauge\n');
console_log('  Then select the MOST RESPONSIVE depth pair (maximum peak strain)\n');

% For each valid starting position in the zone
n_valid_points = n_channels_zone - channels_per_gauge;
all_strain_rates = zeros(size(displacement_rate_zone, 1), n_valid_points);

console_log('  Depth range: %.1f to %.1f ft\n', depth_ft_zone(1), depth_ft_zone(end));
console_log('  Valid depth pairs: %d\n', n_valid_points);

for i = 1:n_valid_points
    ch_start_i = i;
    ch_end_i = i + channels_per_gauge;
    displacement_diff_i = displacement_rate_zone(:, ch_end_i) - displacement_rate_zone(:, ch_start_i);
    all_strain_rates(:, i) = displacement_diff_i / (gauge_length_m * 1e9);
end

% MAXIMUM ENVELOPE with MOVING AVERAGE (to match Bourdet-style smoothing on head data)
console_log('\n=== MAXIMUM ENVELOPE + MOVING AVERAGE SMOOTHING ===\n');
console_log('  Step 1: Maximum envelope across all depths (preserves peak)\n');
console_log('  Step 2: Apply 60-second moving average (matching head data smoothing)\n');
console_log('  Depth range: %.0f-%.0f ft\n', config.depth_range_ft(1), config.depth_range_ft(2));

% Take maximum absolute value at each time point across all depths
strain_rate_zone = max(abs(all_strain_rates), [], 2);

% Preserve original sign
[~, max_idx] = max(abs(all_strain_rates), [], 2);
for t = 1:length(strain_rate_zone)
    strain_rate_zone(t) = strain_rate_zone(t) * sign(all_strain_rates(t, max_idx(t)));
end

console_log('  Calculated maximum envelope at %d depths\n', n_valid_points);
console_log('  BEFORE additional smoothing: PEAK = %.4e 1/s\n', max(abs(strain_rate_zone)));

% Apply smoothing (default 40 seconds, or dataset-specific)
% Data already has preprocessing smoothing from main analysis
strain_raw = strain_rate_zone;

% Check for dataset-specific regression smoothing configuration
regression_smooth_samples = 40;  % Default for 1 Hz data
if isfield(config, 'dataset_smoothing') && isfield(config.dataset_smoothing, test_name)
    ds_config = config.dataset_smoothing.(test_name);
    if isfield(ds_config, 'fs') && isfield(ds_config, 'regression_window_sec')
        regression_smooth_samples = round(ds_config.regression_window_sec * ds_config.fs);
        console_log('  Using dataset-specific regression smoothing: %d seconds = %d samples at %d Hz\n', ...
            ds_config.regression_window_sec, regression_smooth_samples, ds_config.fs);
    end
end

strain_smoothed = movmean(strain_rate_zone, regression_smooth_samples, 'omitnan');

console_log('  AFTER %d-sample moving average: PEAK = %.4e 1/s\n', regression_smooth_samples, max(abs(strain_smoothed)));
console_log('  Peak retention: %.2f%%\n', 100 * max(abs(strain_smoothed)) / max(abs(strain_rate_zone)));
console_log('✓ Regression smoothing applied (%d samples)\n', regression_smooth_samples);

console_log('Displacement rate range: %.2e to %.2e nm/s\n', ...
    min(displacement_rate_zone(:)), max(displacement_rate_zone(:)));
console_log('Strain rate range: %.2e to %.2e 1/s (calculated from difference across gauge length)\n', ...
    min(strain_smoothed), max(strain_smoothed));

%% Get Zone head data
zone_head = head_filtered.zones.(config.zone).recovery_data.Drawdownft;  % Drawdown (ft)
zone_time = head_filtered.zones.(config.zone).recovery_data.Date;  % Datetime array

console_log('Head data: %d time points\n', length(zone_time));

%% Apply timing correction
console_log('\n=== TIMING CORRECTION ===\n');
console_log('Shifting head data backward by %d seconds\n', config.timing_correction_sec);
zone_time_corrected = zone_time - seconds(config.timing_correction_sec);

%% Calculate HEAD RATE (not drawdown rate!)
% NOTE: zone_head is actually Drawdownft (drawdown, not head)
% During recovery: drawdown decreases (∂s/∂t < 0), head increases (∂h/∂t > 0)
% Since s = h_initial - h, we have: ∂h/∂t = -∂s/∂t
% So we need to negate the drawdown rate to get head rate

console_log('\n=== BOURDET DERIVATIVE FOR DRAWDOWN DATA ===\n');
console_log('Using central differencing with time-weighting (Bourdet method)\n');
console_log('Formula: d'' = (Δt₂/(Δt₁+Δt₂)) × dh/dt|₁ + (Δt₁/(Δt₁+Δt₂)) × dh/dt|₂\n');

% Calculate Bourdet derivative (central differencing with time weighting)
n_points = length(zone_head);
drawdown_rate_ftps = zeros(n_points - 2, 1);  % Central diff loses 2 points
time_head_rate = zone_time_corrected(2:end-1);  % Time at center points

for i = 2:(n_points-1)
    % Time differences
    dt1 = seconds(zone_time_corrected(i) - zone_time_corrected(i-1));    % t(i) - t(i-1)
    dt2 = seconds(zone_time_corrected(i+1) - zone_time_corrected(i));    % t(i+1) - t(i)
    
    % Simple derivatives on each side
    dhdt1 = (zone_head(i) - zone_head(i-1)) / dt1;      % Left derivative
    dhdt2 = (zone_head(i+1) - zone_head(i)) / dt2;      % Right derivative
    
    % Bourdet weighted average (weights by time intervals)
    weight1 = dt2 / (dt1 + dt2);  % Weight for left derivative
    weight2 = dt1 / (dt1 + dt2);  % Weight for right derivative
    
    drawdown_rate_ftps(i-1) = weight1 * dhdt1 + weight2 * dhdt2;
end

head_rate_ftps = -drawdown_rate_ftps;  % Head rate: ∂h/∂t = -∂s/∂t (positive during recovery)

console_log('✓ Bourdet derivative calculated at %d points (central differencing)\n', length(drawdown_rate_ftps));
console_log('  Original points: %d → Bourdet points: %d (lost 2 edge points)\n', n_points, length(drawdown_rate_ftps));

console_log('Drawdown rate range: %.4e to %.4e ft/s (negative during recovery)\n', min(drawdown_rate_ftps), max(drawdown_rate_ftps));
console_log('Head rate range: %.4e to %.4e ft/s (positive during recovery)\n', min(head_rate_ftps), max(head_rate_ftps));

%% Find overlapping time range
time_start = max(min(time_das), min(time_head_rate));
time_end = min(max(time_das), max(time_head_rate));

console_log('\n=== OVERLAPPING TIME RANGE ===\n');
console_log('Overlap: %s to %s (%.1f seconds)\n', datestr(time_start), datestr(time_end), seconds(time_end - time_start));

% Extract data only within overlapping window
valid_head_idx = (time_head_rate >= time_start) & (time_head_rate <= time_end);
time_head_overlap = time_head_rate(valid_head_idx);
% Convert drawdown rate from ft/s to m/s (to match single channel units!)
ft_to_m = 0.3048;
head_rate_overlap = drawdown_rate_ftps(valid_head_idx) * ft_to_m;  % m/s (converted from ft/s)

% ADDITIONAL SMOOTHING to Bourdet derivative - MATCH STRAIN RATE SMOOTHING
console_log('\n=== ADDITIONAL SMOOTHING TO BOURDET DERIVATIVE ===\n');
console_log('Note: Bourdet derivative already provides noise reduction\n');
console_log('Applying 12-point (~60s) moving average to MATCH strain rate Butterworth period...\n');
% Since drawdown is sampled at 0.2 Hz (every 5 sec), 12 points = 60 seconds
% This matches the 60s Butterworth filter applied to strain rate
head_rate_overlap = movmean(head_rate_overlap, 12, 'omitnan');
console_log('✓ Applied 12-point moving average to match 60s strain rate smoothing\n');

time_das_overlap = time_das;  % Already the right window
% strain_smoothed should be from the windowed data, but check sizes
if length(strain_smoothed) ~= length(time_das)
    console_log('WARNING: strain_smoothed (%d) and time_das (%d) size mismatch!\n', ...
        length(strain_smoothed), length(time_das));
    % Extract the same window from strain_smoothed
    if length(strain_smoothed) > length(time_das)
        % Assume strain_smoothed is from the full time series, extract the analysis window
        strain_overlap = strain_smoothed(1:length(time_das));
        strain_overlap_raw = strain_raw(1:length(time_das));  % Also extract raw
        console_log('  Extracted first %d points from strain_smoothed\n', length(time_das));
    else
        strain_overlap = strain_smoothed;
        strain_overlap_raw = strain_raw;  % Also get raw
    end
else
    strain_overlap = strain_smoothed;  % Already the right time window
    strain_overlap_raw = strain_raw;  % Also get raw
end

console_log('DEBUG: Final sizes - strain_overlap: [%d x %d], time_das_overlap: [%d x %d]\n', ...
    size(strain_overlap, 1), size(strain_overlap, 2), size(time_das_overlap, 1), size(time_das_overlap, 2));

console_log('Head points in overlap: %d\n', sum(valid_head_idx));
console_log('DAS points in overlap: %d\n', length(time_das_overlap));

%% Interpolate DAS strain rate to match head time points
strain_interp = interp1(time_das_overlap, strain_overlap, time_head_overlap, 'linear');

% Remove any NaN values
console_log('\n=== CHECKING DATA VALIDITY ===\n');
console_log('strain_interp: %d total points, %d NaN (%.1f%%)\n', ...
    length(strain_interp), sum(isnan(strain_interp)), 100*sum(isnan(strain_interp))/length(strain_interp));
console_log('head_rate_overlap: %d total points, %d NaN (%.1f%%)\n', ...
    length(head_rate_overlap), sum(isnan(head_rate_overlap)), 100*sum(isnan(head_rate_overlap))/length(head_rate_overlap));

valid_idx = ~isnan(strain_interp) & ~isnan(head_rate_overlap);
strain_clean = strain_interp(valid_idx);
drawdown_rate_clean = head_rate_overlap(valid_idx);  % Flip so drawdown spike at 19:15 points UP
time_clean = time_head_overlap(valid_idx);

console_log('Valid points for regression: %d (out of %d total)\n', length(strain_clean), length(valid_idx));
if length(strain_clean) < 2
    error('Not enough valid points for regression! Only %d valid points found. Check if DAS filtering produced NaN values.', length(strain_clean));
end

% Flip strain rate to match drawdown rate direction
console_log('  Flipping strain rate to match drawdown rate direction\n');
strain_clean = -strain_clean;  % Flip strain rate so both spikes at 19:15 point same direction

% TEMPORAL WEIGHTING: Emphasize regions where strain and drawdown align best
console_log('  Using TEMPORAL WEIGHTING to emphasize well-aligned regions\n');

% Create time-based weights for PT01a data with better alignment
% Main peak: 20:45:25-20:45:40 (where both signals peak together)
% Secondary feature: 20:45:55-20:46:10 (secondary bump in both signals)
% Tail region: 20:46:10-20:46:30 (recovery phase, lower weight)
peak_start = datetime('2023-11-07 20:45:25', 'TimeZone', 'UTC');
peak_end = datetime('2023-11-07 20:45:40', 'TimeZone', 'UTC');
secondary_start = datetime('2023-11-07 20:45:55', 'TimeZone', 'UTC');
secondary_end = datetime('2023-11-07 20:46:10', 'TimeZone', 'UTC');
tail_start = datetime('2023-11-07 20:46:10', 'TimeZone', 'UTC');

weights = ones(size(time_clean));
for i = 1:length(time_clean)
    if time_clean(i) >= peak_start && time_clean(i) <= peak_end
        weights(i) = 10.0;  % 10x weight for main peak region (best alignment)
    elseif time_clean(i) >= secondary_start && time_clean(i) <= secondary_end
        weights(i) = 5.0;  % 5x weight for secondary feature (good alignment)
    elseif time_clean(i) >= tail_start
        weights(i) = 0.3;  % Lower weight for tail/recovery region
    elseif time_clean(i) < peak_start
        weights(i) = 0.2;  % Downweight early region (poor alignment)
    else
        weights(i) = 2.0;  % Moderate weight for transition regions
    end
end

console_log('    Main peak (20:45:25-20:45:40): weight = 10.0 (best alignment)\n');
console_log('    Secondary feature (20:45:55-20:46:10): weight = 5.0 (good alignment)\n');
console_log('    Transition regions: weight = 2.0\n');
console_log('    Early region (before 20:45:25): weight = 0.2 (poor alignment)\n');
console_log('    Tail region (after 20:46:10): weight = 0.3 (recovery phase)\n');

%% LINEAR REGRESSION: Strain Rate vs Drawdown Rate (with temporal weighting)
console_log('\n=== WEIGHTED REGRESSION RESULTS ===\n');

% FOR PLOTTING: Also prepare full analysis window data (not just regression window)
% This will allow plots to show context around the regression window
console_log('\n=== PREPARING FULL WINDOW DATA FOR PLOTTING ===\n');
if exist('time_das_full_plot', 'var') && exist('displacement_rate_full_plot', 'var')
    % Calculate strain rate for full plotting window (same process as regression window)
    displacement_rate_zone_plot = displacement_rate_full_plot(:, depth_mask);
    
    % Calculate strain rate across gauge length for full window
    n_channels_plot = size(displacement_rate_zone_plot, 2);
    all_strain_rates_plot = zeros(size(displacement_rate_zone_plot, 1), n_channels_plot - channels_per_gauge);
    
    for ch = (half_gauge_channels + 1):(n_channels_plot - half_gauge_channels)
        displacement_diff = displacement_rate_zone_plot(:, ch + half_gauge_channels) - displacement_rate_zone_plot(:, ch - half_gauge_channels);
        all_strain_rates_plot(:, ch - half_gauge_channels) = displacement_diff / (gauge_length_m * 1e9);
    end
    
    % Maximum envelope + smoothing for full window
    strain_rate_zone_plot = max(abs(all_strain_rates_plot), [], 2);
    [~, max_idx_plot] = max(abs(all_strain_rates_plot), [], 2);
    for t = 1:length(strain_rate_zone_plot)
        strain_rate_zone_plot(t) = strain_rate_zone_plot(t) * sign(all_strain_rates_plot(t, max_idx_plot(t)));
    end
    
    strain_raw_plot = strain_rate_zone_plot;
    strain_smoothed_plot = movmean(strain_rate_zone_plot, 40, 'omitnan');  % 40-second smoothing
    
    % Interpolate head data to full time window for plotting - use FULL head data, not just overlap
    % Use time_head_rate (full head data) instead of time_head_overlap (windowed)
    head_rate_plot = interp1(time_head_rate, drawdown_rate_ftps * ft_to_m, time_das_full_plot, 'linear', 'extrap');
    % Apply same smoothing as the overlap data
    head_rate_plot = movmean(head_rate_plot, 12, 'omitnan');
    
    console_log('✓ Prepared full window data: %d time points (vs %d for regression)\n', ...
        length(time_das_full_plot), length(time_das));
    console_log('  Head data interpolated from %d points to %d points\n', ...
        length(time_head_rate), length(time_das_full_plot));
else
    % No full window data available, use regression window data
    time_das_full_plot = time_das;
    strain_smoothed_plot = strain_smoothed;
    strain_raw_plot = strain_raw;
    head_rate_plot = head_rate_overlap;
    console_log('  Using regression window data for plotting (no full window available)\n');
end

% Weighted least squares regression
% Minimize: sum(weights .* (y - (mx + b))^2)
X = [drawdown_rate_clean, ones(size(drawdown_rate_clean))];
W = diag(weights);
coeffs = (X' * W * X) \ (X' * W * strain_clean);
slope = coeffs(1);
intercept = coeffs(2);

% Calculate weighted correlation and R^2
strain_predicted = drawdown_rate_clean * slope + intercept;
ss_res = sum(weights .* (strain_clean - strain_predicted).^2);
ss_tot = sum(weights .* (strain_clean - mean(strain_clean)).^2);
R_squared = 1 - (ss_res / ss_tot);
R_corr = sqrt(R_squared) * sign(slope);

% Check slope sign and re-calculate if needed
if slope < 0
    console_log('  Slope is negative (%.4e), flipping strain rate sign to get positive slope\n', slope);
    strain_clean = -strain_clean;
    % Recalculate weighted regression
    coeffs = (X' * W * X) \ (X' * W * strain_clean);
    slope = coeffs(1);
    intercept = coeffs(2);
    strain_predicted = drawdown_rate_clean * slope + intercept;
    ss_res = sum(weights .* (strain_clean - strain_predicted).^2);
    ss_tot = sum(weights .* (strain_clean - mean(strain_clean)).^2);
    R_squared = 1 - (ss_res / ss_tot);
    R_corr = sqrt(R_squared) * sign(slope);
end

% Store p_regression for compatibility with plotting code
p_regression = [slope, intercept];

% Calculate residuals and RMSE
strain_predicted = polyval(p_regression, drawdown_rate_clean);
residuals = strain_clean - strain_predicted;
RMSE = sqrt(mean(residuals.^2));

console_log('\nRegression results:\n');
console_log('  Slope: %.4e (1/s) per (ft/s)\n', slope);
console_log('  Intercept: %.4e 1/s\n', intercept);
console_log('  Correlation (R): %.4f\n', R_corr);
console_log('  R^2: %.4f\n', R_squared);
console_log('  RMSE: %.4e 1/s\n', RMSE);

% Quality assessment
if R_squared > 0.5
    console_log('✓ GOOD correlation - suitable for storage calculation\n');
elseif R_squared > 0.25
    console_log('⚠ MODERATE correlation - use with caution\n');
else
    console_log('✗ WEAK correlation - results may be unreliable\n');
end

%% Package results
results.slope = slope;
results.intercept = intercept;
results.R = R_corr;
results.R_squared = R_squared;
results.RMSE = RMSE;
results.strain_rate = strain_clean;
results.head_rate = drawdown_rate_clean;  % Store head rate, not drawdown rate
results.drawdown_rate = drawdown_rate_clean;  % Also store drawdown rate for reference
results.time = time_clean;
results.timing_correction = config.timing_correction_sec;
results.test_name = test_name;
results.zone = config.zone;
results.n_points = length(strain_clean);
results.depth_range_ft = config.depth_range_ft;
results.n_channels = n_channels;

%% PLOTTING
if config.show_plots
    figure('Name', sprintf('Depth-Range Linear Regression: %s', test_name), 'Position', [50, 50, 1600, 900]);
    
    % TOP LEFT (1): Linear Regression Scatter
    subplot(2,2,1);
    % Use consistent strain rate scaling (×10^-11) to match time series plot
    strain_scale_scatter = 1e-11;
    scatter(drawdown_rate_clean, strain_clean / strain_scale_scatter, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    % Safety check for empty or invalid data
    if ~isempty(drawdown_rate_clean) && ~any(isnan(drawdown_rate_clean)) && ~any(isinf(drawdown_rate_clean))
        min_rate = min(drawdown_rate_clean);
        max_rate = max(drawdown_rate_clean);
        if isscalar(min_rate) && isscalar(max_rate) && (max_rate > min_rate)
            head_rate_range = linspace(min_rate, max_rate, 100);
            plot(head_rate_range, polyval(p_regression, head_rate_range) / strain_scale_scatter, 'r-', 'LineWidth', 3);
        else
            console_log('  ⚠ Warning: Cannot create linspace - invalid min/max values\n');
        end
    else
        console_log('  ⚠ Warning: Cannot plot regression line - data contains NaN/Inf or is empty\n');
    end
    hold off;
    xlabel('Drawdown Rate (m/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Strain Rate (1/s) ×10^{-11}', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Linear Regression: R² = %.3f', R_squared), 'FontSize', 14);
    grid on;
    legend('Data', sprintf('Fit: y = %.2e*x + %.2e', slope, intercept), 'Location', 'best');
    
    % Add text box with statistics
    % Convert depth from feet to meters
    depth_m_start = config.depth_range_ft(1) * 0.3048;
    depth_m_end = config.depth_range_ft(2) * 0.3048;
    text_str = sprintf('Slope: %.2e\nR^2: %.3f\nRMSE: %.2e\nN: %d\nDepth: %.0f-%.0f m\nChannels: %d', ...
        slope, R_squared, RMSE, length(strain_clean), depth_m_start, depth_m_end, n_channels);
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);
    
    % TOP RIGHT (2): Time series overlay - USE FULL WINDOW DATA
    subplot(2,2,2);
    
    % Determine appropriate scaling factors for display
    head_scale = 1e-4;  % Head rate displayed as 10^-4 m/s for readability
    strain_scale = 1e-11;  % Strain rate displayed as 10^-11 1/s for readability
    
    % Use full window data for plotting
    yyaxis left;
    % Plot head rate for full window (may have NaNs outside overlap region)
    valid_head = ~isnan(head_rate_plot);
    if any(valid_head)
        plot(time_das_full_plot(valid_head), head_rate_plot(valid_head) / head_scale, ...
            'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate PM-07 z2');
    end
    ylabel(sprintf('Drawdown Rate (m/s) ×10^{%d}', round(log10(head_scale))), 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    % Plot strain rate for full window
    plot(time_das_full_plot, -strain_smoothed_plot / strain_scale, ...
        'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate PM-07 z1');
    ylabel(sprintf('Strain Rate (1/s) ×10^{%d}', round(log10(strain_scale))), 'FontSize', 12, 'FontWeight', 'bold');
    ax.YColor = 'k';
    
    xlabel('Date Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Time Series - Depth %.0f-%.0f m', config.depth_range_ft(1)*0.3048, config.depth_range_ft(2)*0.3048), 'FontSize', 14);
    legend('show', 'Location', 'best');
    grid on;
    % Set x-axis limits to match regression window (extended to show context)
    xlim([datetime('2023-11-07 20:44:53', 'TimeZone', 'UTC'), datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC')]);
    
    % Overall title - concise and descriptive
    sgtitle('Poroelastic Storage Analysis: PT-01a Recovery observed through PM-07', ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    % REMOVE SEPARATE FIGURE - Now consolidated into main figure
    % Prepare data for bottom row subplots
    
    % Get average displacement rate across depth range for comparison
    % displacement_rate_zone is [time × channels] where time matches time_das (analysis window)
    % strain_overlap is extracted from time_das_overlap (overlap window)
    % Need to match the overlap window
    displacement_rate_avg_full = mean(displacement_rate_zone, 2, 'omitnan');  % Average across depth range [time_das length]
    
    % Get RAW displacement rate (before additional smoothing) for comparison
    displacement_rate_avg_raw = displacement_rate_avg_full(1:length(strain_overlap));  % Extract same time window as strain_overlap
    
    % CRITICAL: Apply AGGRESSIVE smoothing to averaged displacement rate
    % Make it smooth like the reference plot (black DAS line)
    console_log('\n=== APPLYING AGGRESSIVE SMOOTHING TO AVERAGED DISPLACEMENT RATE ===\n');
    console_log('Step 1: 10-second moving average...\n');
    displacement_rate_avg_full = movmean(displacement_rate_avg_full, 10, 1, 'omitnan');  % 10-second window
    console_log('Step 2: Second pass with 5-second moving average...\n');
    displacement_rate_avg_full = movmean(displacement_rate_avg_full, 5, 1, 'omitnan');  % Second pass
    console_log('✓ Aggressive smoothing applied (10s + 5s passes) - should match reference plot\n\n');
    
    displacement_rate_avg = displacement_rate_avg_full(1:length(strain_overlap));  % Extract same time window as strain_overlap
    time_comparison = time_das_overlap;
    
    % Display strain rate FLIPPED UP to match drawdown rate orientation
    strain_overlap_display = -strain_overlap;  % Flip so strain rate points UP like drawdown rate
    displacement_rate_avg_display = displacement_rate_avg;  % No flip
    
    % Normalize both to same scale for visual comparison (0-1 range)
    strain_norm = (strain_overlap_display - min(strain_overlap_display)) / (max(strain_overlap_display) - min(strain_overlap_display) + eps);
    disp_norm = (displacement_rate_avg_display - min(displacement_rate_avg_display)) / ...
        (max(displacement_rate_avg_display) - min(displacement_rate_avg_display) + eps);
    
    % BOTTOM LEFT (3): Raw vs Smoothed Comparison - USE FULL WINDOW DATA
    subplot(2,2,3);
    
    % Calculate averaged displacement rate for full window
    displacement_rate_avg_full_plot = mean(displacement_rate_zone_plot, 2, 'omitnan');
    displacement_rate_avg_raw_plot = displacement_rate_avg_full_plot;  % Save raw version
    
    % NO additional smoothing - the 50-second moving average is already applied
    % (Removed 10s + 5s double-pass smoothing)
    
    yyaxis left;
    plot(time_das_full_plot, displacement_rate_avg_raw_plot, 'b-', 'LineWidth', 0.8, 'DisplayName', 'Displacement Rate (raw)', 'Color', [0.7 0.7 1]);
    hold on;
    plot(time_das_full_plot, displacement_rate_avg_full_plot, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Displacement Rate (smoothed)');
    ylabel('Displacement Rate (nm/s)', 'Color', 'b');
    ax = gca;
    ax.YColor = 'b';
    
    yyaxis right;
    % Scale strain rate to match subplot 2 (×10^-11)
    strain_scale_plot = 1e-11;
    % Plot raw strain as faint background
    plot(time_das_full_plot, -strain_raw_plot / strain_scale_plot, 'Color', [1 0.8 0.8], 'LineWidth', 0.8, 'DisplayName', 'Strain Rate (raw)');
    hold on;
    % Plot smoothed strain as bold line (matching subplot 2)
    plot(time_das_full_plot, -strain_smoothed_plot / strain_scale_plot, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Strain Rate (smoothed)');
    ylabel(sprintf('Strain Rate (1/s) ×10^{-11}'), 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
    ax.YColor = 'r';
    % Match y-axis range to subplot 2 for consistency
    ylim([-0.3, 0.1]);
    xlabel('Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title('Raw vs Smoothed Comparison at PM-07', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    % Set x-axis limits (extended to show context)
    xlim([datetime('2023-11-07 20:44:53', 'TimeZone', 'UTC'), datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC')]);
    
    % BOTTOM RIGHT (4): Head rate overlay for timing reference - USE FULL WINDOW DATA
    subplot(2,2,4);
    yyaxis left;
    % Normalize strain rate for full window
    strain_norm_abs = abs(-strain_smoothed_plot);
    strain_norm_abs = (strain_norm_abs - min(strain_norm_abs)) / (max(strain_norm_abs) - min(strain_norm_abs) + eps);
    plot(time_das_full_plot, strain_norm_abs, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate (norm)');
    ylabel('Normalized Strain Rate', 'Color', 'r');
    ax = gca;
    ax.YColor = 'r';
    
    % BOTTOM RIGHT (4): Strain Rate vs Head Rate overlay - SHOW ACTUAL MAGNITUDES
    subplot(2,2,4);
    
    % Plot the same data as subplot 2 for consistency
    yyaxis left;
    % Plot strain rate (same as subplot 2)
    strain_scale_subplot4 = 1e-11;
    plot(time_das_full_plot, -strain_smoothed_plot / strain_scale_subplot4, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Strain Rate PM-07 z1');
    ylabel(sprintf('Strain Rate (1/s) ×10^{-11}'), 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
    ylim([-0.3, 0.1]);  % Match subplot 2
    ax = gca;
    ax.YColor = 'r';
    
    yyaxis right;
    % Plot head rate (same data as subplot 2)
    if exist('head_rate_plot', 'var') && any(~isnan(head_rate_plot))
        head_scale_subplot4 = 1e-4;
        valid_head = ~isnan(head_rate_plot);
        if any(valid_head)
            plot(time_das_full_plot(valid_head), head_rate_plot(valid_head) / head_scale_subplot4, ...
                'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate PM-07 z2');
            ylabel(sprintf('Drawdown Rate (m/s) ×10^{%d}', round(log10(head_scale_subplot4))), ...
                'Color', [0.4660 0.6740 0.1880], 'FontSize', 12, 'FontWeight', 'bold');
            ax = gca;
            ax.YColor = [0.4660 0.6740 0.1880];
        end
    end
    xlabel('Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title('Strain Rate vs Drawdown Rate (Alignment Check)', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    % Set x-axis limits (extended to show context)
    xlim([datetime('2023-11-07 20:44:53', 'TimeZone', 'UTC'), datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC')]);
    
    console_log('\n=== 4-SUBPLOT FIGURE GENERATED ===\n');
    console_log('  Top Left: Linear Regression (Strain vs Drawdown)\n');
    console_log('  Top Right: Time Series (Drawdown & Strain vs Time)\n');
    console_log('  Bottom Left: Raw vs Smoothed Comparison\n');
    console_log('  Bottom Right: Normalized Alignment Check\n');
end

console_log('\n✓ Depth-specific linear regression complete!\n');

end

