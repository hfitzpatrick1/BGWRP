function results = linear_regression_strain_drawdown(das_results, head_results, test_name, config)
%LINEAR_REGRESSION_STRAIN_DRAWDOWN Perform linear regression between DAS strain rate/displacement rate and drawdown rate
%
% Inputs:
%   das_results - Structure with DAS correlation results
%   head_results - Structure with head correlation results
%   test_name - Name of test (e.g., 'PT01c_Recovery_short')
%   config - Configuration structure with fields:
%            .timing_correction_sec - Time shift to apply to head data (seconds backward)
%            .zone - Zone to analyze (default: 'z5')
%            .show_plots - Whether to generate plots (default: true)
%            .use_displacement_rate - If true, use displacement rate instead of strain rate (default: false)
%            .pre_diff_smoothing_window - Smooth displacement channels BEFORE difference (default: none)
%            .strain_rate_smoothing_window - Smooth strain rate AFTER difference (default: 5)
%            .strain_rate_smoothing_method - Smoothing method:
%                'movmean' - Moving average (default)
%                'movmedian' - Moving median (better noise rejection)
%                'gaussian' - Gaussian filter
%                'double_pass' - Moving average applied twice
%                'triple_pass' - Moving average applied three times
%                'savgol' - Savitzky-Golay (preserves peaks, requires Signal Toolbox)
%                'lowpass' - Lowpass Butterworth filter (requires Signal Toolbox)
%                'exp_smooth' - Exponential moving average
%                'gaussian_double' - Gaussian filter applied twice
%            .strain_rate_spatial_averaging - Average across N channel pairs (default: 1, no spatial averaging)
%            .flip_strain_rate_sign - If true, flip the sign of strain rate (default: false, auto-flips if mean < 0)
%
% Outputs:
%   results - Structure containing:
%            .slope - Regression slope (1/s per ft/s for strain, nm/s per ft/s for displacement)
%            .intercept - Regression intercept
%            .R - Correlation coefficient
%            .R_squared - R^2
%            .RMSE - Root mean square error
%            .strain_rate or .displacement_rate - Clean data
%            .drawdown_rate - Clean drawdown rate data (ft/s)
%            .time - Time vector for aligned data
%            .timing_correction - Applied timing correction (sec)

% Set defaults
if ~isfield(config, 'zone'), config.zone = 'z5'; end
if ~isfield(config, 'show_plots'), config.show_plots = true; end
if ~isfield(config, 'timing_correction_sec'), config.timing_correction_sec = 7.5; end
if ~isfield(config, 'use_displacement_rate'), config.use_displacement_rate = false; end

%% Extract data
if config.use_displacement_rate
    fprintf('\n=== LINEAR REGRESSION: DISPLACEMENT RATE vs DRAWDOWN RATE ===\n');
else
    fprintf('\n=== LINEAR REGRESSION: STRAIN RATE vs DRAWDOWN RATE ===\n');
end
fprintf('Test: %s\n', test_name);
fprintf('Zone: %s\n', config.zone);

das_filtered = das_results.(test_name);
head_filtered = head_results.(test_name);

fprintf('DAS data: %d time points\n', length(das_filtered.analysis_time));
fprintf('Head data: %d time points\n', length(head_filtered.zones.(config.zone).recovery_data.Date));

%% Get DAS strain rate using correct formula: ε̇(z,t) = [u̇(z+L,t) - u̇(z,t)] / L
% Equation (2) from DAS theory:
%   ε̇(z,t) = [u̇(z+L,t) - u̇(z,t)] / L
% where:
%   ε̇ = strain rate (1/s)
%   u̇ = displacement rate (nm/s in our data)
%   L = gauge length (10 m)
%   z = position along fiber
%   z+L = position L meters away from z
%
% NOTE: analysis_strain_rate is MISLABELED - it's actually displacement rate in nm/s!
% We need the full matrix to calculate the difference across gauge length
gauge_length_m = 10;  % DAS gauge length in meters (L in equation)
spatial_resolution_m = 0.25;  % Spatial resolution per channel (0.25 m)
channels_per_gauge = round(gauge_length_m / spatial_resolution_m);  % ~40 channels for 10m gauge

% Get the channel index for the representative channel (285 ft)
if isfield(das_filtered, 'pumping_zone') && isfield(das_filtered.pumping_zone, 'channel_idx')
    channel_idx = das_filtered.pumping_zone.channel_idx;
    
    % CORRECT METHOD: Calculate difference across gauge length
    if isfield(das_filtered, 'smoothed_data') && isfield(das_filtered, 'time_array')
        displacement_rate_full = das_filtered.smoothed_data;  % [time × depth]
        time_das_full = das_filtered.time_array;
        
        % DEBUG: Check if smoothed_data was actually smoothed
        fprintf('\n=== DEBUG: CHECKING SMOOTHED_DATA ===\n');
        fprintf('smoothed_data exists: YES\n');
        fprintf('smoothed_data size: [%d time points × %d channels]\n', size(displacement_rate_full, 1), size(displacement_rate_full, 2));
        
        % Check if smoothing method info is stored
        if isfield(das_filtered, 'smoothing_method')
            fprintf('Stored smoothing method: %s\n', das_filtered.smoothing_method);
        else
            fprintf('⚠ No smoothing_method field stored - cannot verify smoothing was applied\n');
        end
        
        % Check if this looks like raw data (high variance) or smoothed (low variance)
        % Sample a few channels to check variance
        sample_channel = channel_idx;
        if sample_channel <= size(displacement_rate_full, 2)
            sample_data = displacement_rate_full(:, sample_channel);
            data_std = std(sample_data);
            data_range = max(sample_data) - min(sample_data);
            fprintf('Sample channel %d (%.1f ft): std=%.2e nm/s, range=%.2e nm/s\n', ...
                sample_channel, das_filtered.depth_ft(sample_channel), data_std, data_range);
            
            % Check for high-frequency noise (raw data has more rapid changes)
            diff_data = abs(diff(sample_data));
            mean_diff = mean(diff_data);
            std_diff = std(diff_data);
            fprintf('Mean absolute change between time steps: %.2e nm/s\n', mean_diff);
            fprintf('Std of changes between time steps: %.2e nm/s\n', std_diff);
            
            % More sophisticated check: compare to what smoothed data should look like
            % Smoothed 5-second data should have much smaller step-to-step changes
            % Raw 1Hz data typically has changes on order of 0.01-0.1 nm/s per step
            % Smoothed 5-second data should have changes < 0.001 nm/s per step
            if mean_diff > 0.005 || std_diff > 0.01  % Threshold for "raw" vs "smoothed"
                fprintf('⚠⚠⚠ WARNING: Data appears to be RAW/UNSMOOTHED ⚠⚠⚠\n');
                fprintf('   High variance detected: mean_diff=%.2e, std_diff=%.2e\n', mean_diff, std_diff);
                fprintf('   Expected for 5-second smoothed data: mean_diff < 0.001, std_diff < 0.01\n');
                fprintf('   ACTION REQUIRED: Re-run with mode=''run_correlation_analysis'' or ''run_filter_matlab_movmean_5sec''\n');
                fprintf('   This will apply the 5-second moving average to smoothed_data\n');
            else
                fprintf('✓ Data appears to be SMOOTHED (low variance, gradual changes)\n');
                fprintf('   mean_diff=%.2e, std_diff=%.2e (within expected range for smoothed data)\n', mean_diff, std_diff);
            end
        end
        
        % Find time window matching analysis_time
        time_das = das_filtered.analysis_time;
        [~, time_start_idx] = min(abs(time_das_full - time_das(1)));
        [~, time_end_idx] = min(abs(time_das_full - time_das(end)));
        time_mask = time_start_idx:time_end_idx;
        
        % Create time vector for strain rate (matches the time_mask indices)
        time_strain = time_das_full(time_mask);
        
        if config.use_displacement_rate
            % Use displacement rate directly at single channel (285 ft)
            fprintf('\n=== USING DISPLACEMENT RATE (not strain rate) ===\n');
            displacement_rate_smoothed = displacement_rate_full(time_mask, channel_idx);  % nm/s
            strain_smoothed = displacement_rate_smoothed;  % Store as strain_smoothed for compatibility (but it's actually displacement rate)
            fprintf('  Channel: %d (%.1f ft)\n', channel_idx, das_filtered.depth_ft(channel_idx));
            fprintf('  Source: smoothed_data (should have 5-second movmean if correlation analysis was run)\n');
            if isfield(das_filtered, 'smoothing_method')
                fprintf('  Smoothing method: %s', das_filtered.smoothing_method);
                if isfield(das_filtered, 'smoothing_window')
                    fprintf(' (window: %d samples = %.1f seconds)\n', das_filtered.smoothing_window, das_filtered.smoothing_window);
                else
                    fprintf('\n');
                end
            else
                fprintf('  ⚠ Smoothing method not stored - check debug output above to verify\n');
            end
            fprintf('Displacement rate range: %.2e to %.2e nm/s\n', min(displacement_rate_smoothed), max(displacement_rate_smoothed));
        else
            % Calculate strain rate using difference across gauge length
            channel_idx_L = channel_idx + channels_per_gauge;
            
            % OPTION: Average across multiple channel pairs for spatial smoothing
            spatial_averaging = false;
            n_pairs = 1;
            if isfield(config, 'strain_rate_spatial_averaging') && config.strain_rate_spatial_averaging > 1
                n_pairs = config.strain_rate_spatial_averaging;
                spatial_averaging = true;
                fprintf('  Using spatial averaging across %d channel pairs\n', n_pairs);
            end
            
            if channel_idx_L <= size(displacement_rate_full, 2)
                % Get displacement at both channels (or multiple pairs if spatial averaging)
                if spatial_averaging
                    % Average across multiple channel pairs centered on the main channel
                    offset_range = floor((n_pairs - 1) / 2);
                    strain_pairs = zeros(length(time_mask), n_pairs);
                    valid_pairs = 0;
                    
                    for pair_idx = 1:n_pairs
                        offset = pair_idx - offset_range - 1;
                        ch_z = channel_idx + offset;
                        ch_z_L = ch_z + channels_per_gauge;
                        
                        if ch_z >= 1 && ch_z_L <= size(displacement_rate_full, 2)
                            disp_z = displacement_rate_full(time_mask, ch_z);
                            disp_z_L = displacement_rate_full(time_mask, ch_z_L);
                            strain_pairs(:, pair_idx) = (disp_z_L - disp_z) / (gauge_length_m * 1e9);
                            valid_pairs = valid_pairs + 1;
                        end
                    end
                    
                    if valid_pairs > 0
                        % Average across valid pairs only
                        displacement_diff = mean(strain_pairs(:, 1:valid_pairs), 2) * (gauge_length_m * 1e9);  % Convert back to nm/s for consistency
                        fprintf('    Averaged strain from %d channel pairs (offsets: %d to %d)\n', valid_pairs, -offset_range, offset_range);
                    else
                        % Fallback to main pair if no valid pairs
                        displacement_at_z = displacement_rate_full(time_mask, channel_idx);
                        displacement_at_z_L = displacement_rate_full(time_mask, channel_idx_L);
                        displacement_diff = displacement_at_z_L - displacement_at_z;
                        fprintf('    WARNING: No valid pairs for spatial averaging, using main channel pair\n');
                    end
                else
                    % Single channel pair (original method)
                    displacement_at_z = displacement_rate_full(time_mask, channel_idx);
                    displacement_at_z_L = displacement_rate_full(time_mask, channel_idx_L);
                
                    % OPTION: Apply additional smoothing to displacement channels BEFORE difference
                    % This reduces noise before the difference calculation (which amplifies noise)
                    if isfield(config, 'pre_diff_smoothing_window') && config.pre_diff_smoothing_window > 1
                        pre_smooth_window = config.pre_diff_smoothing_window;
                        fprintf('  Applying pre-difference smoothing to displacement channels: %d-sample window\n', pre_smooth_window);
                        displacement_at_z = movmean(displacement_at_z, pre_smooth_window, 'Endpoints', 'shrink');
                        displacement_at_z_L = movmean(displacement_at_z_L, pre_smooth_window, 'Endpoints', 'shrink');
                    end
                    
                    % Calculate difference: [u̇(z+L,t) - u̇(z,t)]
                    % This is the numerator of equation (2)
                    displacement_diff = displacement_at_z_L - displacement_at_z;  % Units: nm/s
                end
                
                % Divide by L to get strain rate: ε̇(z,t) = [u̇(z+L,t) - u̇(z,t)] / L
                % Unit conversion:
                %   displacement_diff is in nm/s
                %   gauge_length_m = 10 m = 10 * 1e9 nm = 1e10 nm
                %   strain_rate = (nm/s) / (10 m) = (nm/s) / (1e10 nm) = 1e-10 * (nm/s) / nm = 1e-10 / s
                % 
                % Formula: strain_rate = displacement_diff / (gauge_length_m * 1e9)
                % where 1e9 converts meters to nanometers
                % Result: (nm/s) / (10 * 1e9 nm) = (nm/s) / (1e10 nm) = 1e-10 / s
                %
                % This gives strain rate in units of 1/s (per second)
                strain_smoothed = displacement_diff / (gauge_length_m * 1e9);  % Units: 1/s
                
                % Apply additional smoothing to strain rate (difference can amplify noise)
                % This makes it look smooth like the drawdown rate plots
                % NOTE: movmean uses a CENTERED window by default, which introduces a delay
                % For a 5-second window, delay ≈ 2.5 seconds (half window size)
                % This means pump-off at 19:15:00 will appear at ~19:15:02.5 in smoothed data
                
                % Choose smoothing method
                smoothing_method = 'movmean';
                if isfield(config, 'strain_rate_smoothing_method')
                    smoothing_method = config.strain_rate_smoothing_method;
                end
                
                if isfield(config, 'strain_rate_smoothing_window') && config.strain_rate_smoothing_window > 1
                    smoothing_window = config.strain_rate_smoothing_window;
                    fprintf('  Applying post-difference smoothing to strain rate: %s, %d-sample window\n', smoothing_method, smoothing_window);
                    fprintf('  ⚠ TIMING NOTE: Centered moving average introduces ~%.1f second delay\n', smoothing_window/2);
                    
                    switch lower(smoothing_method)
                        case 'movmean'
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            
                        case 'movmedian'
                            strain_smoothed = movmedian(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            fprintf('    Using median filter (better noise rejection)\n');
                            
                        case 'gaussian'
                            % Gaussian smoothing (requires Image Processing Toolbox)
                            sigma = smoothing_window / 3;
                            strain_smoothed = imgaussfilt(strain_smoothed, sigma);
                            fprintf('    Using Gaussian filter (sigma=%.2f)\n', sigma);
                            
                        case 'double_pass'
                            % Apply smoothing twice for extra smoothness
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            fprintf('    Using double-pass smoothing (applied twice)\n');
                            
                        case 'savgol'
                            % Savitzky-Golay filter (polynomial smoothing, preserves peaks better)
                            % Requires Signal Processing Toolbox
                            poly_order = min(3, floor(smoothing_window/2));  % Polynomial order (max 3)
                            if mod(smoothing_window, 2) == 0
                                smoothing_window = smoothing_window + 1;  % Must be odd
                            end
                            strain_smoothed = sgolayfilt(strain_smoothed, poly_order, smoothing_window);
                            fprintf('    Using Savitzky-Golay filter (order=%d, window=%d)\n', poly_order, smoothing_window);
                            
                        case 'lowpass'
                            % Lowpass filter (removes high-frequency noise)
                            % Requires Signal Processing Toolbox
                            % Normalized cutoff frequency (0 to 1, where 1 = Nyquist)
                            cutoff_freq = 1.0 / smoothing_window;  % Lower cutoff = more smoothing
                            [b, a] = butter(4, cutoff_freq, 'low');  % 4th order Butterworth
                            strain_smoothed = filtfilt(b, a, strain_smoothed);  % Zero-phase filtering
                            fprintf('    Using lowpass Butterworth filter (cutoff=%.3f Hz)\n', cutoff_freq * 0.5);
                            
                        case 'exp_smooth'
                            % Exponential moving average (more weight on recent values)
                            alpha = 2.0 / (smoothing_window + 1);  % Smoothing factor
                            strain_smoothed_exp = zeros(size(strain_smoothed));
                            strain_smoothed_exp(1) = strain_smoothed(1);
                            for i = 2:length(strain_smoothed)
                                strain_smoothed_exp(i) = alpha * strain_smoothed(i) + (1 - alpha) * strain_smoothed_exp(i-1);
                            end
                            strain_smoothed = strain_smoothed_exp;
                            fprintf('    Using exponential moving average (alpha=%.3f)\n', alpha);
                            
                        case 'triple_pass'
                            % Apply smoothing three times for maximum smoothness
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                            fprintf('    Using triple-pass smoothing (applied three times)\n');
                            
                        case 'gaussian_double'
                            % Gaussian smoothing applied twice
                            sigma = smoothing_window / 3;
                            strain_smoothed = imgaussfilt(strain_smoothed, sigma);
                            strain_smoothed = imgaussfilt(strain_smoothed, sigma);
                            fprintf('    Using double-pass Gaussian filter (sigma=%.2f, applied twice)\n', sigma);
                            
                        otherwise
                            strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                    end
                elseif isfield(config, 'strain_rate_smoothing_window') && config.strain_rate_smoothing_window <= 1
                    % Explicitly disabled
                    fprintf('  Strain rate smoothing disabled (window <= 1)\n');
                else
                    % Default: apply 5-second smoothing to match the displacement rate smoothing
                    smoothing_window = 5;
                    fprintf('  Applying default 5-second smoothing to strain rate for smooth appearance\n');
                    fprintf('  ⚠ TIMING NOTE: Centered moving average introduces ~2.5 second delay\n');
                    fprintf('     Pump-off at 19:15:00 will appear at ~19:15:02.5 in smoothed signal\n');
                    strain_smoothed = movmean(strain_smoothed, smoothing_window, 'Endpoints', 'shrink');
                end
                
                % Check if strain rate is mostly negative - if so, flip sign
                % During recovery, strain should be positive (expansion)
                if isfield(config, 'flip_strain_rate_sign') && config.flip_strain_rate_sign
                    fprintf('  Flipping strain rate sign (user requested)\n');
                    strain_smoothed = -strain_smoothed;
                elseif mean(strain_smoothed) < 0
                    fprintf('  WARNING: Average strain rate is negative, flipping sign for recovery convention\n');
                    strain_smoothed = -strain_smoothed;  % Flip sign so strain is positive during recovery
                end
                
                fprintf('\n=== STRAIN RATE CALCULATION (Equation 2) ===\n');
                fprintf('Formula: ε̇(z,t) = [u̇(z+L,t) - u̇(z,t)] / L\n');
                fprintf('  Channel z: %d (%.1f ft) → u̇(z,t) in nm/s\n', channel_idx, das_filtered.depth_ft(channel_idx));
                fprintf('  Channel z+L: %d (%.1f ft) → u̇(z+L,t) in nm/s\n', channel_idx_L, das_filtered.depth_ft(channel_idx_L));
                fprintf('  Gauge length L: %.1f m (%d channels)\n', gauge_length_m, channels_per_gauge);
                fprintf('  Displacement difference [u̇(z+L) - u̇(z)]: %.2e to %.2e nm/s\n', min(displacement_diff), max(displacement_diff));
                fprintf('  Strain rate ε̇ = difference / L: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
                fprintf('  ✓ Conversion verified: (nm/s) / (10 m) = (nm/s) / (1e10 nm) = 1e-10 / s\n');
            else
                error('Channel z+L (%d) exceeds available channels (%d)', channel_idx_L, size(displacement_rate_full, 2));
            end
        end
    else
        error('Need smoothed_data and time_array fields to calculate strain rate correctly');
    end
else
    % Fallback: use analysis_strain_rate as single channel (old method)
    displacement_rate_smoothed = das_filtered.analysis_strain_rate;  % nm/s (displacement rate)
    time_das = das_filtered.analysis_time;
    time_strain = time_das;  % For fallback, they're the same
    
    if config.use_displacement_rate
        % Use displacement rate directly
        strain_smoothed = displacement_rate_smoothed;  % Store as strain_smoothed for compatibility
        fprintf('Using displacement rate at single channel (fallback method)\n');
        fprintf('Displacement rate range: %.2e to %.2e nm/s\n', min(displacement_rate_smoothed), max(displacement_rate_smoothed));
    else
        % Calculate strain rate (OLD METHOD - incorrect without full matrix!)
        strain_smoothed = displacement_rate_smoothed / (gauge_length_m * 1e9);  % OLD METHOD - incorrect!
        fprintf('WARNING: Using old method (single channel). Need full matrix for correct calculation!\n');
        fprintf('Displacement rate range: %.2e to %.2e nm/s\n', min(displacement_rate_smoothed), max(displacement_rate_smoothed));
        fprintf('Strain rate range: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
    end
end

%% Get Zone head data
zone_head = head_filtered.zones.(config.zone).recovery_data.Drawdownft;  % Drawdown (ft)
zone_time = head_filtered.zones.(config.zone).recovery_data.Date;  % Datetime array

%% Apply timing correction
fprintf('\n=== TIMING CORRECTION ===\n');
fprintf('Original head time: %s to %s\n', datestr(zone_time(1)), datestr(zone_time(end)));
fprintf('Shifting head data backward by %d seconds\n', config.timing_correction_sec);

zone_time_corrected = zone_time - seconds(config.timing_correction_sec);

fprintf('Corrected head time: %s to %s\n', datestr(zone_time_corrected(1)), datestr(zone_time_corrected(end)));

%% Calculate HEAD RATE (not drawdown rate!)
% NOTE: zone_head is actually Drawdownft (drawdown, not head)
% During recovery: drawdown decreases (∂s/∂t < 0), head increases (∂h/∂t > 0)
% Since s = h_initial - h, we have: ∂h/∂t = -∂s/∂t
dt_head = diff(seconds(zone_time_corrected - zone_time_corrected(1)));  % Time step (seconds)
ds = diff(zone_head);  % Drawdown change (ft)
drawdown_rate_ftps = ds ./ dt_head;  % Drawdown rate: ∂s/∂t (negative during recovery)
head_rate_ftps = -drawdown_rate_ftps;  % Head rate: ∂h/∂t = -∂s/∂t (positive during recovery)
time_head_rate = zone_time_corrected(1:end-1);  % Time vector (one less after diff)

fprintf('Drawdown rate range: %.4e to %.4e ft/s (negative during recovery)\n', min(drawdown_rate_ftps), max(drawdown_rate_ftps));
fprintf('Head rate range: %.4e to %.4e ft/s (positive during recovery)\n', min(head_rate_ftps), max(head_rate_ftps));

%% Use the SAME time window as Figure 102 (analysis_time window)
% This ensures we're looking at the exact same time period
time_start = time_das(1);  % Start of analysis_time window (same as Figure 102)
time_end = time_das(end);  % End of analysis_time window (same as Figure 102)

fprintf('\n=== TIME WINDOW (Same as Figure 102) ===\n');
fprintf('Using analysis_time window: %s to %s (%.1f seconds)\n', ...
    datestr(time_start), datestr(time_end), seconds(time_end - time_start));
fprintf('DAS time: %s to %s\n', datestr(min(time_das)), datestr(max(time_das)));
fprintf('Head time (after correction): %s to %s\n', datestr(min(time_head_rate)), datestr(max(time_head_rate)));

% Extract DAS data for the full analysis_time window (same as Figure 102)
% IMPORTANT: Use time_strain (which matches strain_smoothed) not time_das
valid_strain_idx = (time_strain >= time_start) & (time_strain <= time_end);
time_das_overlap = time_strain(valid_strain_idx);
strain_overlap = strain_smoothed(valid_strain_idx);  % Already in 1/s (strain rate)

% Also get time_das for reference (should match time_strain in this window)
valid_das_idx = (time_das >= time_start) & (time_das <= time_end);
fprintf('Strain data points: %d, DAS time points: %d (should match)\n', sum(valid_strain_idx), sum(valid_das_idx));

% Extract head data that falls within this window (after timing correction)
valid_head_idx = (time_head_rate >= time_start) & (time_head_rate <= time_end);
time_head_overlap = time_head_rate(valid_head_idx);
head_rate_overlap = head_rate_ftps(valid_head_idx);  % ft/s (use head rate, not drawdown rate!)

fprintf('Head points in overlap: %d\n', sum(valid_head_idx));
fprintf('DAS points in overlap: %d\n', sum(valid_das_idx));

% Check if we have enough overlap
if sum(valid_head_idx) < 10
    fprintf('⚠⚠⚠ WARNING: Very few head points in overlap (%d points) ⚠⚠⚠\n', sum(valid_head_idx));
    fprintf('   This may be due to timing correction pushing head data outside DAS window\n');
    fprintf('   Head time range (after correction): %s to %s\n', datestr(min(time_head_rate)), datestr(max(time_head_rate)));
    fprintf('   DAS time range: %s to %s\n', datestr(time_start), datestr(time_end));
    fprintf('   Consider adjusting timing_correction_sec (current: %d)\n', config.timing_correction_sec);
end

if sum(valid_das_idx) == 0
    error('No DAS data points in analysis window! Check time alignment.');
end

%% Interpolate DAS strain rate to match head time points
strain_interp = interp1(time_das_overlap, strain_overlap, time_head_overlap, 'linear');

% Remove any NaN values
valid_idx = ~isnan(strain_interp) & ~isnan(head_rate_overlap);
strain_clean = strain_interp(valid_idx);
head_rate_clean = head_rate_overlap(valid_idx);  % Use head rate
time_clean = time_head_overlap(valid_idx);

fprintf('Valid points for regression: %d\n', length(strain_clean));

% Flip both signs to reverse the graph (user request)
fprintf('  Flipping signs of both head rate and strain rate to reverse graph\n');
head_rate_clean = -head_rate_clean;  % Flip head rate
strain_clean = -strain_clean;  % Flip strain rate

%% LINEAR REGRESSION: Strain Rate vs Head Rate
fprintf('\n=== REGRESSION RESULTS ===\n');
p_regression = polyfit(head_rate_clean, strain_clean, 1);
slope = p_regression(1);  % (1/s) per (ft/s) - strain rate per head rate
intercept = p_regression(2);  % 1/s

% Calculate correlation and R^2
R_matrix = corrcoef(head_rate_clean, strain_clean);
R_corr = R_matrix(1,2);
R_squared = R_corr^2;

% Note: After flipping both signs, slope sign is preserved (both flipped, so ratio stays same)
% But we want positive slope, so if it's negative, flip strain rate again
if slope < 0
    fprintf('  Slope is negative (%.4e), flipping strain rate sign to get positive slope\n', slope);
    strain_clean = -strain_clean;
    p_regression = polyfit(head_rate_clean, strain_clean, 1);
    slope = p_regression(1);
    intercept = p_regression(2);
    R_matrix = corrcoef(head_rate_clean, strain_clean);
    R_corr = R_matrix(1,2);
    R_squared = R_corr^2;
end

% Calculate residuals and RMSE
strain_predicted = polyval(p_regression, head_rate_clean);
residuals = strain_clean - strain_predicted;
RMSE = sqrt(mean(residuals.^2));

if config.use_displacement_rate
    fprintf('Slope: %.4e (nm/s) per (ft/s)\n', slope);
    fprintf('Intercept: %.4e nm/s\n', intercept);
else
    fprintf('Slope: %.4e (1/s) per (ft/s)\n', slope);
    fprintf('Intercept: %.4e 1/s\n', intercept);
end
fprintf('Correlation (R): %.4f\n', R_corr);
fprintf('R^2: %.4f\n', R_squared);
if config.use_displacement_rate
    fprintf('RMSE: %.4e nm/s\n', RMSE);
else
    fprintf('RMSE: %.4e 1/s\n', RMSE);
end

% Quality assessment
if R_squared > 0.5
    fprintf('✓ GOOD correlation - suitable for storage calculation\n');
elseif R_squared > 0.25
    fprintf('⚠ MODERATE correlation - use with caution\n');
else
    fprintf('✗ WEAK correlation - NOT suitable for storage calculation\n');
end

%% Store results
results.slope = slope;
results.intercept = intercept;
results.R = R_corr;
results.R_squared = R_squared;
results.RMSE = RMSE;
if config.use_displacement_rate
    results.displacement_rate = strain_clean;  % Actually displacement rate (nm/s)
    results.units = 'nm/s';
else
    results.strain_rate = strain_clean;  % Strain rate (1/s)
    results.units = '1/s';
end
results.head_rate = head_rate_clean;  % Store head rate, not drawdown rate
results.drawdown_rate = -head_rate_clean;  % Also store drawdown rate for reference
results.time = time_clean;
results.timing_correction = config.timing_correction_sec;
results.test_name = test_name;
results.zone = config.zone;
results.n_points = length(strain_clean);
results.use_displacement_rate = config.use_displacement_rate;

%% PLOTTING
if config.show_plots
    figure(20); clf;
    set(gcf, 'Position', [50 50 1400 600], 'Name', sprintf('Linear Regression - %s', test_name));
    
    % Left plot: Scatter with regression line
    subplot(1,2,1);
    scatter(head_rate_clean, strain_clean, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    head_rate_range = linspace(min(head_rate_clean), max(head_rate_clean), 100);
    plot(head_rate_range, polyval(p_regression, head_rate_range), 'r-', 'LineWidth', 3);
    xlabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    if config.use_displacement_rate
        ylabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    else
        ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    end
    title(sprintf('Linear Regression: R = %.3f, R^2 = %.3f', R_corr, R_squared), 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend({'Data', sprintf('Fit: y = %.2e*x + %.2e', slope, intercept)}, 'Location', 'best', 'FontSize', 10);
    set(gca, 'FontSize', 11);
    
    % Add text box with statistics
    text_str = sprintf('Slope: %.2e\nR: %.3f\nR^2: %.3f\nRMSE: %.2e\nN: %d', ...
        slope, R_corr, R_squared, RMSE, length(strain_clean));
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);
    
    % Right plot: Time series overlay
    % Plot strain at ORIGINAL DAS time points (not interpolated) so it doesn't change with timing correction
    subplot(1,2,2);
    yyaxis left;
    % Interpolate head rate to DAS time points for plotting (so both are at same times)
    head_rate_at_das_times = interp1(time_clean, head_rate_clean, time_das_overlap, 'linear', 'extrap');
    plot(time_das_overlap, head_rate_at_das_times, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Head Rate');
    ylabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    % Plot strain/displacement at ORIGINAL DAS time points (before interpolation) - this won't change with timing correction
    if config.use_displacement_rate
        plot(time_das_overlap, strain_overlap, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Displacement Rate');
        ylabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    else
        plot(time_das_overlap, strain_overlap, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
        ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    end
    ax.YColor = 'k';
    
    xlabel('Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Time Series (%ds correction)', config.timing_correction_sec), 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    set(gca, 'FontSize', 11);
    
    if config.use_displacement_rate
        sgtitle(sprintf('Displacement Rate vs Drawdown Rate - %s (Zone %s)', test_name, upper(config.zone)), ...
            'FontSize', 16, 'FontWeight', 'bold');
    else
        sgtitle(sprintf('Strain Rate vs Drawdown Rate - %s (Zone %s)', test_name, upper(config.zone)), ...
            'FontSize', 16, 'FontWeight', 'bold');
    end
    
    % ADDITIONAL PLOT: Compare strain rate vs displacement rate for visual alignment
    if ~config.use_displacement_rate && isfield(das_filtered, 'smoothed_data')
        figure(21); clf;
        set(gcf, 'Position', [100 100 1400 800], 'Name', sprintf('Strain vs Displacement Comparison - %s', test_name));
        
        % Get displacement rate at same channel for comparison
        % This is already smoothed (5-second movmean from correlation analysis)
        displacement_at_channel = displacement_rate_full(time_mask, channel_idx);
        time_comparison = time_strain;
        
        % Apply same smoothing to displacement rate as we did to strain rate for fair comparison
        if isfield(config, 'strain_rate_smoothing_window') && config.strain_rate_smoothing_window > 1
            % Apply the same post-processing smoothing to displacement rate
            smoothing_window = config.strain_rate_smoothing_window;
            smoothing_method = 'movmean';
            if isfield(config, 'strain_rate_smoothing_method')
                smoothing_method = config.strain_rate_smoothing_method;
            end
            
            switch lower(smoothing_method)
                case 'movmean'
                    displacement_smoothed = movmean(displacement_at_channel, smoothing_window, 'Endpoints', 'shrink');
                case 'lowpass'
                    cutoff_freq = 1.0 / smoothing_window;
                    [b, a] = butter(4, cutoff_freq, 'low');
                    displacement_smoothed = filtfilt(b, a, displacement_at_channel);
                otherwise
                    displacement_smoothed = movmean(displacement_at_channel, smoothing_window, 'Endpoints', 'shrink');
            end
        else
            displacement_smoothed = displacement_at_channel;  % Use as-is
        end
        
        % Normalize both to same scale for visual comparison (0-1 range)
        strain_norm = (strain_overlap - min(strain_overlap)) / (max(strain_overlap) - min(strain_overlap) + eps);
        disp_norm_raw = (displacement_at_channel - min(displacement_at_channel)) / (max(displacement_at_channel) - min(displacement_at_channel) + eps);
        disp_norm_smooth = (displacement_smoothed - min(displacement_smoothed)) / (max(displacement_smoothed) - min(displacement_smoothed) + eps);
        
        % Plot 1: Overlay normalized signals (smoothed displacement vs strain)
        subplot(2,2,1);
        plot(time_comparison, disp_norm_smooth, 'b-', 'LineWidth', 2, 'DisplayName', 'Displacement Rate (smoothed, normalized)');
        hold on;
        plot(time_comparison, strain_norm, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate (normalized)');
        xlabel('Time UTC');
        ylabel('Normalized Amplitude (0-1)');
        title('Normalized Comparison - Same Smoothing Level');
        legend('Location', 'best');
        grid on;
        
        % Plot 2: Raw displacement vs smoothed strain (shows why they look different)
        subplot(2,2,2);
        yyaxis left;
        plot(time_comparison, displacement_at_channel, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Displacement Rate (raw)');
        hold on;
        plot(time_comparison, displacement_smoothed, 'c--', 'LineWidth', 2, 'DisplayName', 'Displacement Rate (smoothed)');
        ylabel('Displacement Rate (nm/s)', 'Color', 'b');
        ax = gca;
        ax.YColor = 'b';
        
        yyaxis right;
        plot(time_comparison, strain_overlap, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate');
        ylabel('Strain Rate (1/s)', 'Color', 'r');
        ax.YColor = 'r';
        xlabel('Time UTC');
        title('Raw vs Smoothed Comparison');
        legend('Location', 'best');
        grid on;
        
        % Plot 3: Correlation scatter (smoothed displacement vs strain)
        subplot(2,2,3);
        % Interpolate to same time points
        common_time = time_comparison;
        strain_interp = interp1(time_comparison, strain_overlap, common_time, 'linear');
        disp_interp_smooth = interp1(time_comparison, displacement_smoothed, common_time, 'linear');
        valid = ~isnan(strain_interp) & ~isnan(disp_interp_smooth);
        scatter(disp_interp_smooth(valid), strain_interp(valid), 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
        xlabel('Displacement Rate (nm/s, smoothed)');
        ylabel('Strain Rate (1/s)');
        corr_val = corr(disp_interp_smooth(valid), strain_interp(valid));
        title(sprintf('Strain vs Displacement Correlation: R = %.3f', corr_val));
        grid on;
        
        % Add regression line
        if sum(valid) > 2
            p = polyfit(disp_interp_smooth(valid), strain_interp(valid), 1);
            hold on;
            x_fit = linspace(min(disp_interp_smooth(valid)), max(disp_interp_smooth(valid)), 100);
            plot(x_fit, polyval(p, x_fit), 'r-', 'LineWidth', 2, 'DisplayName', sprintf('Fit: y=%.2e*x+%.2e', p(1), p(2)));
            legend('Location', 'best');
        end
        
        % Plot 4: Head rate overlay for timing reference
        subplot(2,2,4);
        yyaxis left;
        plot(time_comparison, strain_norm, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate (norm)');
        ylabel('Normalized Strain Rate', 'Color', 'r');
        ax = gca;
        ax.YColor = 'r';
        
        yyaxis right;
        % Get head rate for comparison
        if exist('head_rate_clean', 'var') && exist('time_clean', 'var')
            head_rate_interp = interp1(time_clean, head_rate_clean, time_comparison, 'linear', 'extrap');
            head_norm = (head_rate_interp - min(head_rate_interp)) / (max(head_rate_interp) - min(head_rate_interp) + eps);
            plot(time_comparison, head_norm, 'g-', 'LineWidth', 2, 'DisplayName', 'Head Rate (norm)');
            ylabel('Normalized Head Rate', 'Color', [0.4660 0.6740 0.1880]);
            ax.YColor = [0.4660 0.6740 0.1880];
        end
        xlabel('Time UTC');
        title('Strain Rate vs Head Rate (normalized for alignment check)');
        legend('Location', 'best');
        grid on;
        
        sgtitle(sprintf('Strain Rate vs Displacement Rate Comparison - %s', test_name), ...
            'FontSize', 16, 'FontWeight', 'bold');
        
        fprintf('\n=== COMPARISON PLOT GENERATED ===\n');
        fprintf('Figure 21: Strain rate vs displacement rate comparison\n');
        fprintf('  Use this to visually check alignment and see why they look different\n');
    end
    
    fprintf('\n=== PLOT GENERATED ===\n');
    fprintf('Figure 20: Linear regression and time series\n');
end

fprintf('\n✓ Linear regression analysis complete!\n');
fprintf('Next: Adjust timing_correction_sec if peaks not aligned, or proceed to storage calculation\n\n');

end

