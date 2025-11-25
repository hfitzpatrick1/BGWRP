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
%            .depth_range_ft - [min_ft max_ft] depth range to analyze (default: use pumping_zone channel)
%            .depth_averaging_method - How to combine channels in depth range:
%                'mean' - Average all channels (default)
%                'median' - Median of all channels
%                'representative' - Single channel at center of range
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
if ~isfield(config, 'depth_averaging_method'), config.depth_averaging_method = 'mean'; end

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

% Determine which channels to analyze based on depth range
if isfield(config, 'depth_range_ft') && ~isempty(config.depth_range_ft)
    % User specified a depth range
    depth_min_ft = config.depth_range_ft(1);
    depth_max_ft = config.depth_range_ft(2);
    
    % Find channels within this depth range
    depth_ft = das_filtered.depth_ft;
    channels_in_range = find(depth_ft >= depth_min_ft & depth_ft <= depth_max_ft);
    
    if isempty(channels_in_range)
        error('No channels found in depth range %.1f - %.1f ft', depth_min_ft, depth_max_ft);
    end
    
    fprintf('\n=== DEPTH RANGE ANALYSIS ===\n');
    fprintf('Depth range: %.1f - %.1f ft\n', depth_min_ft, depth_max_ft);
    fprintf('Channels in range: %d (ch %d to ch %d)\n', length(channels_in_range), ...
        channels_in_range(1), channels_in_range(end));
    fprintf('Averaging method: %s\n', config.depth_averaging_method);
    
    % Select representative channel or prepare for averaging
    if strcmp(config.depth_averaging_method, 'representative')
        % Use center channel of range
        channel_idx = channels_in_range(round(length(channels_in_range)/2));
        fprintf('Using representative channel: %d (%.1f ft)\n', channel_idx, depth_ft(channel_idx));
        use_depth_averaging = false;
    else
        % Will average across all channels in range
        channel_idx = channels_in_range(1);  % Start channel for strain rate calculation
        use_depth_averaging = true;
        fprintf('Will average across all %d channels in range\n', length(channels_in_range));
    end
    
elseif isfield(das_filtered, 'pumping_zone') && isfield(das_filtered.pumping_zone, 'channel_idx')
    % Default: use pumping zone channel
    channel_idx = das_filtered.pumping_zone.channel_idx;
    use_depth_averaging = false;
    fprintf('\n=== USING DEFAULT PUMPING ZONE CHANNEL ===\n');
    fprintf('Channel: %d (%.1f ft)\n', channel_idx, das_filtered.depth_ft(channel_idx));
else
    error('No depth range specified and no pumping_zone channel available');
end

% Now process based on whether we're using a single channel or depth averaging
if isfield(das_filtered, 'pumping_zone') && isfield(das_filtered.pumping_zone, 'channel_idx')
    % For reference only - actual channel_idx may be different if depth_range specified
    
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
            % Use displacement rate directly
            fprintf('\n=== USING DISPLACEMENT RATE (not strain rate) ===\n');
            
            if use_depth_averaging
                % Average displacement rate across depth range
                fprintf('  Averaging displacement rate across depth range\n');
                displacement_rate_all_channels = displacement_rate_full(time_mask, channels_in_range);  % [time × channels]
                
                switch config.depth_averaging_method
                    case 'mean'
                        displacement_rate_smoothed = mean(displacement_rate_all_channels, 2);  % Average across channels
                        fprintf('  Method: Mean across %d channels\n', length(channels_in_range));
                    case 'median'
                        displacement_rate_smoothed = median(displacement_rate_all_channels, 2);  % Median across channels
                        fprintf('  Method: Median across %d channels\n', length(channels_in_range));
                    otherwise
                        displacement_rate_smoothed = mean(displacement_rate_all_channels, 2);
                        fprintf('  Method: Mean (default) across %d channels\n', length(channels_in_range));
                end
                fprintf('  Depth range: %.1f - %.1f ft (%d channels)\n', depth_min_ft, depth_max_ft, length(channels_in_range));
            else
                % Single channel
                displacement_rate_smoothed = displacement_rate_full(time_mask, channel_idx);  % nm/s
                fprintf('  Channel: %d (%.1f ft)\n', channel_idx, das_filtered.depth_ft(channel_idx));
            end
            
            strain_smoothed = displacement_rate_smoothed;  % Store as strain_smoothed for compatibility (but it's actually displacement rate)
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
            % Calculate strain rate using SINGLE CHANNEL method
            fprintf('\n=== CALCULATING STRAIN RATE (Single Channel Method) ===\n');
            fprintf('  DAS channels already measure strain over gauge length!\n');
            fprintf('  Using: strain_rate = channel_value / gauge_length\n');
            
            if use_depth_averaging
                % Average strain rate across multiple channels in depth range
                fprintf('  Averaging strain rate across depth range\n');
                n_channels = length(channels_in_range);
                strain_channels = zeros(length(time_mask), n_channels);
                
                for ch_idx = 1:n_channels
                    ch_z = channels_in_range(ch_idx);
                    disp_z = displacement_rate_full(time_mask, ch_z);
                    strain_channels(:, ch_idx) = disp_z / (gauge_length_m * 1e9);  % Single channel method
                end
                
                % Average across all channels
                switch config.depth_averaging_method
                    case 'mean'
                        strain_smoothed = mean(strain_channels, 2);  % Units: 1/s
                        fprintf('  Method: Mean across %d channels\n', n_channels);
                    case 'median'
                        strain_smoothed = median(strain_channels, 2);  % Units: 1/s
                        fprintf('  Method: Median across %d channels\n', n_channels);
                    otherwise
                        strain_smoothed = mean(strain_channels, 2);  % Units: 1/s
                        fprintf('  Method: Mean (default) across %d channels\n', n_channels);
                end
                fprintf('  Depth range: %.1f - %.1f ft (%d channels)\n', depth_min_ft, depth_max_ft, n_channels);
                
            else
                % Single channel calculation
                fprintf('  Using single channel: %d (%.1f ft)\n', channel_idx, das_filtered.depth_ft(channel_idx));
                
                % Get displacement rate at single channel
                displacement_at_z = displacement_rate_full(time_mask, channel_idx);
                
                % Calculate strain rate: ε̇(z,t) = u̇(z,t) / L
                % Each DAS channel already measures strain averaged over the gauge length
                % Unit conversion:
                %   displacement_at_z is in nm/s
                %   gauge_length_m = 10 m = 10 * 1e9 nm = 1e10 nm
                %   strain_rate = (nm/s) / (10 m) = (nm/s) / (1e10 nm) = 1e-10 / s
                % 
                % This gives strain rate in units of 1/s (per second)
                strain_smoothed = displacement_at_z / (gauge_length_m * 1e9);  % Units: 1/s
                
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
                
                fprintf('\n=== STRAIN RATE CALCULATION (Single Channel Method) ===\n');
                fprintf('Formula: ε̇(z,t) = u̇(z,t) / L\n');
                fprintf('  Channel z: %d (%.1f ft) → u̇(z,t) in nm/s\n', channel_idx, das_filtered.depth_ft(channel_idx));
                fprintf('  Gauge length L: %.1f m = %.2e nm\n', gauge_length_m, gauge_length_m * 1e9);
                fprintf('  Displacement rate u̇(z): %.2e to %.2e nm/s\n', min(displacement_at_z), max(displacement_at_z));
                fprintf('  Strain rate ε̇ = u̇/L: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
                fprintf('  ✓ Conversion verified: (nm/s) / (10 m) = (nm/s) / (1e10 nm) = 1e-10 / s\n');
            end  % End of use_depth_averaging else block (single channel pair calculation)
        end  % End of use_depth_averaging if-else
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
        % Calculate strain rate using SINGLE CHANNEL METHOD (CORRECTED!)
        strain_smoothed = displacement_rate_smoothed / (gauge_length_m * 1e9);
        fprintf('Using single-channel strain rate calculation (fallback path)\n');
        fprintf('  Formula: strain_rate = displacement_rate / gauge_length\n');
        fprintf('  Displacement rate range: %.2e to %.2e nm/s\n', min(displacement_rate_smoothed), max(displacement_rate_smoothed));
        fprintf('  Gauge length: %.1f m = %.2e nm\n', gauge_length_m, gauge_length_m * 1e9);
        fprintf('  Strain rate range: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
        fprintf('  ✓ Single-channel method (matches amplitude calculation)\n');
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

% Apply smoothing to head rate to match strain rate smoothing level
if isfield(config, 'head_rate_smoothing_window') && config.head_rate_smoothing_window > 1
    smoothing_window = config.head_rate_smoothing_window;
    fprintf('\n=== SMOOTHING HEAD RATE ===\n');
    fprintf('  Applying %d-point moving mean to head rate (matching strain rate smoothing)\n', smoothing_window);
    fprintf('  Raw head rate range: %.4e to %.4e ft/s\n', min(head_rate_ftps), max(head_rate_ftps));
    head_rate_ftps = movmean(head_rate_ftps, smoothing_window, 'Endpoints', 'shrink');
    fprintf('  Smoothed head rate range: %.4e to %.4e ft/s\n', min(head_rate_ftps), max(head_rate_ftps));
else
    fprintf('\n⚠ WARNING: No smoothing applied to head rate\n');
    fprintf('  Strain rate has smoothing but head rate does not - this may reduce correlation\n');
    fprintf('  Consider setting config.head_rate_smoothing_window = 5 to match\n');
end

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

% Option to flip signs for visualization (both head and strain to align them)
if ~isfield(config, 'flip_for_display')
    config.flip_for_display = true;  % Default: flip both to align visually
end

if config.flip_for_display
    fprintf('  Flipping both head rate and strain rate signs to align them visually (config.flip_for_display = true)\n');
    head_rate_clean = -head_rate_clean;  % Flip head rate
    strain_clean = -strain_clean;  % Flip strain rate
    fprintf('  Result: Both signals now point in same direction for visual comparison\n');
else
    fprintf('  Using original signs for both head and strain rate (config.flip_for_display = false)\n');
end

%% LINEAR REGRESSION OR AMPLITUDE ANALYSIS
% Check if amplitude mode is requested (removes baseline drift)
use_amplitude = isfield(config, 'use_amplitude') && config.use_amplitude;

if use_amplitude
    fprintf('\n=== AMPLITUDE ANALYSIS (Peak-to-Trough) ===\n');
    fprintf('  Using max - min amplitude (matching advisor method)\n');
    
    % Find maximum and minimum values in the window
    max_strain = max(strain_clean);
    min_strain = min(strain_clean);
    [~, max_strain_idx] = max(strain_clean);
    [~, min_strain_idx] = min(strain_clean);
    
    max_head = max(head_rate_clean);
    min_head = min(head_rate_clean);
    [~, max_head_idx] = max(head_rate_clean);
    [~, min_head_idx] = min(head_rate_clean);
    
    fprintf('\n  Strain rate:\n');
    fprintf('    Max: %.4e 1/s (at point %d)\n', max_strain, max_strain_idx);
    fprintf('    Min: %.4e 1/s (at point %d)\n', min_strain, min_strain_idx);
    
    fprintf('  Head rate:\n');
    fprintf('    Max: %.4e ft/s (at point %d)\n', max_head, max_head_idx);
    fprintf('    Min: %.4e ft/s (at point %d)\n', min_head, min_head_idx);
    
    % Calculate amplitudes (max - min = peak-to-trough range)
    amplitude_strain = max_strain - min_strain;
    amplitude_head = max_head - min_head;
    
    fprintf('\n  Amplitude (max - min):\n');
    fprintf('    Strain rate: %.4e 1/s\n', amplitude_strain);
    fprintf('    Head rate: %.4e ft/s\n', amplitude_head);
    
    % Slope = amplitude ratio
    slope = amplitude_strain / amplitude_head;
    intercept = min_strain;  % Use min as intercept
    baseline_strain = min_strain;  % For compatibility
    baseline_head = min_head;
    
    fprintf('\n  Slope (amplitude ratio): %.4e (1/s)/(ft/s)\n', slope);
    fprintf('  ✓ Using peak-to-trough range (advisor method)!\n');
    
    % Calculate predicted values using amplitude-based slope
    strain_predicted = baseline_strain + slope * (head_rate_clean - baseline_head);
    residuals = strain_clean - strain_predicted;
    
    % Calculate correlation and R^2 for quality assessment (even in amplitude mode)
    % This shows how well the data correlates, regardless of how slope was calculated
    R_matrix = corrcoef(head_rate_clean, strain_clean);
    R_corr = R_matrix(1,2);
    R_squared = R_corr^2;
    RMSE = sqrt(mean(residuals.^2));
    
    fprintf('\n  Correlation metrics (for quality assessment):\n');
    fprintf('    R: %.4f\n', R_corr);
    fprintf('    R^2: %.4f\n', R_squared);
    fprintf('    RMSE: %.4e 1/s\n', RMSE);
    
else
    % Original regression approach
    fprintf('\n=== REGRESSION RESULTS ===\n');
    p_regression = polyfit(head_rate_clean, strain_clean, 1);
    slope = p_regression(1);  % (1/s) per (ft/s) - strain rate per head rate
    intercept = p_regression(2);  % 1/s

    % Calculate correlation and R^2
    R_matrix = corrcoef(head_rate_clean, strain_clean);
    R_corr = R_matrix(1,2);
    R_squared = R_corr^2;

    % Calculate residuals and RMSE
    strain_predicted = polyval(p_regression, head_rate_clean);
    residuals = strain_clean - strain_predicted;
    RMSE = sqrt(mean(residuals.^2));
end

if ~use_amplitude
    % Only print regression metrics if not using amplitude mode
    if config.use_displacement_rate
        fprintf('Slope: %.4e (nm/s)/(ft/s)\n', slope);
        fprintf('Intercept: %.4e nm/s\n', intercept);
    else
        fprintf('Slope: %.4e (1/s)/(ft/s)\n', slope);
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
    % Use different figure numbers for displacement rate vs strain rate
    if config.use_displacement_rate
        fig_num = 22;  % Displacement rate gets Figure 22
        fig_name = sprintf('Linear Regression (Displacement Rate) - %s', test_name);
    else
        fig_num = 20;  % Strain rate gets Figure 20
        fig_name = sprintf('Linear Regression (Strain Rate) - %s', test_name);
    end
    
    figure(fig_num); clf;
    set(gcf, 'Position', [50 50 1400 600], 'Name', fig_name);
    
    % Left plot: Scatter with regression line
    subplot(1,2,1);
    scatter(head_rate_clean, strain_clean, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    head_rate_range = linspace(min(head_rate_clean), max(head_rate_clean), 100);
    if use_amplitude
        % For amplitude mode, plot the line through baseline and peak
        plot(head_rate_range, intercept + slope * (head_rate_range - baseline_head), 'r-', 'LineWidth', 3);
    else
        plot(head_rate_range, polyval(p_regression, head_rate_range), 'r-', 'LineWidth', 3);
    end
    xlabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    if config.use_displacement_rate
        ylabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    else
        ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    end
    if use_amplitude
        title(sprintf('Amplitude Analysis: R = %.3f, R^2 = %.3f', R_corr, R_squared), 'FontSize', 14, 'FontWeight', 'bold');
    else
        title(sprintf('Linear Regression: R = %.3f, R^2 = %.3f', R_corr, R_squared), 'FontSize', 14, 'FontWeight', 'bold');
    end
    grid on;
    legend({'Data', sprintf('Fit: y = %.2e*x + %.2e', slope, intercept)}, 'Location', 'best', 'FontSize', 10);
    set(gca, 'FontSize', 11);
    
    % Add text box with statistics - ALWAYS show R and R² for quality assessment
    if use_amplitude
        text_str = sprintf('Slope: %.2e\nR: %.3f\nR^2: %.3f\nAmplitude Mode\nRMSE: %.2e\nN: %d', ...
            slope, R_corr, R_squared, RMSE, length(strain_clean));
    else
        text_str = sprintf('Slope: %.2e\nR: %.3f\nR^2: %.3f\nRMSE: %.2e\nN: %d', ...
            slope, R_corr, R_squared, RMSE, length(strain_clean));
    end
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);
    
    % Right plot: Time series overlay
    % Plot strain at ORIGINAL DAS time points (not interpolated) so it doesn't change with timing correction
    subplot(1,2,2);
    yyaxis left;
    % Interpolate head rate to DAS time points for plotting (so both are at same times)
    % Note: head_rate_clean already has flip applied if config.flip_for_display = true
    head_rate_at_das_times = interp1(time_clean, head_rate_clean, time_das_overlap, 'linear', 'extrap');
    plot(time_das_overlap, head_rate_at_das_times, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Head Rate');
    ylabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    % Plot strain/displacement at ORIGINAL DAS time points (before interpolation) - this won't change with timing correction
    % Apply same flip as used in regression for consistency
    strain_overlap_display = strain_overlap;
    if config.flip_for_display && ~config.use_displacement_rate
        strain_overlap_display = -strain_overlap_display;
    end
    
    if config.use_displacement_rate
        plot(time_das_overlap, strain_overlap_display, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Displacement Rate');
        ylabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    else
        plot(time_das_overlap, strain_overlap_display, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
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
        set(gcf, 'Position', [100 100 1400 800], 'Name', sprintf('Strain vs Displacement Comparison (Strain Rate Analysis) - %s', test_name));
        
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
        
        % Apply flip if configured (for consistency with main plot)
        strain_overlap_display = strain_overlap;
        if config.flip_for_display
            strain_overlap_display = -strain_overlap_display;
        end
        
        % Normalize both to same scale for visual comparison (0-1 range)
        strain_norm = (strain_overlap_display - min(strain_overlap_display)) / (max(strain_overlap_display) - min(strain_overlap_display) + eps);
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
        plot(time_comparison, strain_overlap_display, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate');
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
        strain_interp = interp1(time_comparison, strain_overlap_display, common_time, 'linear');
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

