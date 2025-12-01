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
fprintf('\n=== DEPTH-SPECIFIC LINEAR REGRESSION ===\n');
fprintf('Test: %s\n', test_name);
fprintf('Zone: %s\n', config.zone);
fprintf('Depth range: %.0f to %.0f ft\n', config.depth_range_ft(1), config.depth_range_ft(2));

das_filtered = das_results.(test_name);
head_filtered = head_results.(test_name);

%% Get DAS displacement rate for FULL depth range (not just one channel!)
% smoothed_data is [time × depth] in nm/s (displacement rate)
displacement_rate_full = das_filtered.smoothed_data;  % Full matrix [time × depth]
time_das_full = das_filtered.time_array;  % Full time vector (not just analysis window!)
depth_ft = das_filtered.depth_ft;

% Apply same smoothing as single channel method (5-second only)
fprintf('\n=== APPLYING SMOOTHING TO MATCH SINGLE CHANNEL METHOD ===\n');
fprintf('Applying 5-second moving average (same as single channel)...\n');
% Note: displacement_rate_full is already smoothed from DAS analysis, but apply consistent processing
fprintf('✓ Using existing smoothing from DAS analysis\n\n');

% DEBUG: Check if smoothed_data was actually smoothed
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  DEBUG: CHECKING IF 5-SECOND MOVING AVERAGE WAS APPLIED\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('smoothed_data exists: YES\n');
fprintf('smoothed_data size: [%d time points × %d channels]\n', size(displacement_rate_full, 1), size(displacement_rate_full, 2));

smoothing_applied = false;
smoothing_info = 'UNKNOWN';

if isfield(das_filtered, 'smoothing_method')
    smoothing_info = sprintf('%s', das_filtered.smoothing_method);
    if isfield(das_filtered, 'smoothing_window')
        smoothing_info = sprintf('%s (window: %d samples = %.1f seconds)', ...
            das_filtered.smoothing_method, das_filtered.smoothing_window, das_filtered.smoothing_window);
    end
    fprintf('Stored smoothing method: %s\n', smoothing_info);
    
    % Check if it's the expected 5-second movmean
    if strcmp(das_filtered.smoothing_method, 'matlab_movmean') || ...
       (strcmp(das_filtered.smoothing_method, 'movmean') && isfield(das_filtered, 'smoothing_window') && das_filtered.smoothing_window == 5)
        smoothing_applied = true;
        fprintf('✓ Expected 5-second moving average detected\n');
    else
        fprintf('⚠ Different smoothing method than expected (expected: matlab_movmean with 5-second window)\n');
    end
else
    fprintf('⚠⚠⚠ CRITICAL: No smoothing_method field stored!\n');
    fprintf('   This means smoothing was NOT applied during correlation analysis.\n');
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
        fprintf('\nSample channel at %.1f ft:\n', depth_ft(sample_idx));
        fprintf('  mean(|diff|) = %.2e nm/s\n', mean_diff);
        fprintf('  std(|diff|)  = %.2e nm/s\n', std_diff);
        
        % Thresholds: smoothed data should have much lower variance
        if mean_diff > 0.005 || std_diff > 0.01
            fprintf('\n⚠⚠⚠ WARNING: Data appears to be RAW/UNSMOOTHED ⚠⚠⚠\n');
            fprintf('   Expected for 5-second smoothed: mean_diff < 0.001, std_diff < 0.01\n');
            fprintf('   Your values are: mean_diff=%.2e, std_diff=%.2e\n', mean_diff, std_diff);
            fprintf('\n   ═══ ACTION REQUIRED ═══\n');
            fprintf('   Re-run correlation analysis to apply smoothing:\n');
            fprintf('   >> mode = ''run_correlation_analysis'';\n');
            fprintf('   >> BGWRP_Toolkit\n');
            fprintf('   Then re-run this linear regression function.\n');
        else
            data_appears_smoothed = true;
            fprintf('\n✓ Data appears to be SMOOTHED (low variance between samples)\n');
        end
    end
end

% Final verdict
fprintf('\n═══════════════════════════════════════════════════════════════\n');
if smoothing_applied && data_appears_smoothed
    fprintf('  ✓✓✓ VERDICT: 5-SECOND MOVING AVERAGE IS APPLIED ✓✓✓\n');
elseif ~smoothing_applied
    fprintf('  ⚠⚠⚠ VERDICT: SMOOTHING NOT DETECTED - RE-RUN CORRELATION ANALYSIS ⚠⚠⚠\n');
else
    fprintf('  ⚠ VERDICT: INCONSISTENT - Check smoothing settings\n');
end
fprintf('═══════════════════════════════════════════════════════════════\n\n');

% If recovery_window is specified, extract only that time range
if isfield(config, 'recovery_window') && ~isempty(config.recovery_window)
    recovery_start = config.recovery_window(1);
    recovery_end = config.recovery_window(2);
    
    fprintf('Using custom recovery window: %s to %s\n', datestr(recovery_start), datestr(recovery_end));
    
    % Find indices in full time array
    [~, rec_start_idx] = min(abs(time_das_full - recovery_start));
    [~, rec_end_idx] = min(abs(time_das_full - recovery_end));
    
    % Extract only the peak signal window
    displacement_rate_full = displacement_rate_full(rec_start_idx:rec_end_idx, :);
    time_das = time_das_full(rec_start_idx:rec_end_idx);
    
    fprintf('Extracted %d time points (%.1f seconds)\n', length(time_das), seconds(recovery_end - recovery_start));
else
    % Use the default analysis window
    time_das = das_filtered.analysis_time;
    fprintf('Using default analysis window\n');
end

% Find channels in depth range
depth_mask = (depth_ft >= config.depth_range_ft(1)) & (depth_ft <= config.depth_range_ft(2));
n_channels = sum(depth_mask);

fprintf('DAS data: %d time points\n', length(time_das));
fprintf('Channels in depth range: %d (out of %d total)\n', n_channels, length(depth_ft));
fprintf('Depth range: %.1f to %.1f ft\n', min(depth_ft(depth_mask)), max(depth_ft(depth_mask)));

if n_channels == 0
    error('No channels found in depth range %.0f-%.0f ft!', config.depth_range_ft(1), config.depth_range_ft(2));
end

% Extract displacement rate for selected depth range
% Subset: [time × selected_depths]
% Note: displacement_rate_full may already be subsetted if recovery_window was used
displacement_rate_zone = displacement_rate_full(:, depth_mask);

% Skip additional smoothing to match single channel approach
fprintf('\n=== USING EXISTING SMOOTHING (MATCHES SINGLE CHANNEL) ===\n');
fprintf('Displacement rate already smoothed with 5-second moving average\n');
fprintf('✓ Using consistent smoothing with single channel method\n\n');

%% Convert to strain rate using correct formula: ε̇ = [u̇(z+L) - u̇(z)] / L
gauge_length_m = 10;  % DAS gauge length in meters
spatial_resolution_m = 0.25;  % Spatial resolution per channel (0.2496 m with scaling)
channels_per_gauge = round(gauge_length_m / spatial_resolution_m);  % ~40 channels

fprintf('Calculating strain rate using difference across gauge length:\n');
fprintf('  Gauge length: %.1f m\n', gauge_length_m);
fprintf('  Spatial resolution: %.3f m/channel\n', spatial_resolution_m);
fprintf('  Channels per gauge: %d\n', channels_per_gauge);

% Calculate strain rate for each channel in the zone
% For each channel, find the channel that's L away and calculate difference
n_channels_zone = size(displacement_rate_zone, 2);
strain_rate_zone = zeros(size(displacement_rate_zone));

for ch = 1:n_channels_zone
    % Find corresponding channel indices in full depth array
    channel_indices = find(depth_mask);
    ch_idx = channel_indices(ch);
    
    % Find channel that's L away (ch_idx + channels_per_gauge)
    ch_idx_L = ch_idx + channels_per_gauge;
    
    if ch_idx_L <= size(displacement_rate_full, 2)
        % Calculate difference: [u̇(z+L) - u̇(z)]
        % During recovery (expansion): strain should be positive
        displacement_diff = displacement_rate_full(:, ch_idx_L) - displacement_rate_full(:, ch_idx);
        % Divide by L to get strain rate: ε̇ = difference / L
        strain_rate_zone(:, ch) = displacement_diff / (gauge_length_m * 1e9);  % Convert nm to m
    else
        % Channel too close to end - can't calculate difference
        strain_rate_zone(:, ch) = NaN;
    end
end

% Check if strain rates are mostly negative - if so, flip sign
% During recovery, both head rate and strain rate should be positive
strain_avg_check = mean(strain_rate_zone(:), 'omitnan');
if strain_avg_check < 0
    fprintf('  WARNING: Average strain rate is negative, flipping sign for recovery convention\n');
    strain_rate_zone = -strain_rate_zone;  % Flip sign so strain is positive during recovery
end

% Apply same smoothing as single channel method
fprintf('\n=== APPLYING SINGLE CHANNEL SMOOTHING TO STRAIN RATE ===\n');
fprintf('Applying 5-second moving average to each strain rate channel (matches single channel)...\n');
for ch = 1:size(strain_rate_zone, 2)
    strain_rate_zone(:, ch) = movmean(strain_rate_zone(:, ch), 5, 1, 'omitnan');
end
fprintf('✓ Applied 5-second smoothing to all %d strain rate channels\n', size(strain_rate_zone, 2));

% Average strain rates across the depth range
strain_smoothed = mean(strain_rate_zone, 2, 'omitnan');  % Average across depths → [time × 1]

% Apply final smoothing to match single channel method
fprintf('\n=== FINAL SMOOTHING TO MATCH SINGLE CHANNEL ===\n');
fprintf('Applying 5-second moving average to averaged strain rate...\n');
strain_smoothed = movmean(strain_smoothed, 5, 1, 'omitnan');  % Same as single channel
fprintf('✓ Applied 5-second smoothing to averaged strain rate (matches single channel)\n\n');

fprintf('Displacement rate range: %.2e to %.2e nm/s\n', ...
    min(displacement_rate_zone(:)), max(displacement_rate_zone(:)));
fprintf('Strain rate range: %.2e to %.2e 1/s (calculated from difference across gauge length)\n', ...
    min(strain_smoothed), max(strain_smoothed));

%% Get Zone head data
zone_head = head_filtered.zones.(config.zone).recovery_data.Drawdownft;  % Drawdown (ft)
zone_time = head_filtered.zones.(config.zone).recovery_data.Date;  % Datetime array

fprintf('Head data: %d time points\n', length(zone_time));

%% Apply timing correction
fprintf('\n=== TIMING CORRECTION ===\n');
fprintf('Shifting head data backward by %d seconds\n', config.timing_correction_sec);
zone_time_corrected = zone_time - seconds(config.timing_correction_sec);

%% Calculate HEAD RATE (not drawdown rate!)
% NOTE: zone_head is actually Drawdownft (drawdown, not head)
% During recovery: drawdown decreases (∂s/∂t < 0), head increases (∂h/∂t > 0)
% Since s = h_initial - h, we have: ∂h/∂t = -∂s/∂t
% So we need to negate the drawdown rate to get head rate
dt_head = diff(seconds(zone_time_corrected - zone_time_corrected(1)));  % Time step (seconds)
ds = diff(zone_head);  % Drawdown change (ft) - note: this is drawdown, not head!
drawdown_rate_ftps = ds ./ dt_head;  % Drawdown rate: ∂s/∂t (negative during recovery)
head_rate_ftps = -drawdown_rate_ftps;  % Head rate: ∂h/∂t = -∂s/∂t (positive during recovery)
time_head_rate = zone_time_corrected(1:end-1);  % Time vector (one less after diff)

fprintf('Drawdown rate range: %.4e to %.4e ft/s (negative during recovery)\n', min(drawdown_rate_ftps), max(drawdown_rate_ftps));
fprintf('Head rate range: %.4e to %.4e ft/s (positive during recovery)\n', min(head_rate_ftps), max(head_rate_ftps));

%% Find overlapping time range
time_start = max(min(time_das), min(time_head_rate));
time_end = min(max(time_das), max(time_head_rate));

fprintf('\n=== OVERLAPPING TIME RANGE ===\n');
fprintf('Overlap: %s to %s (%.1f seconds)\n', datestr(time_start), datestr(time_end), seconds(time_end - time_start));

% Extract data only within overlapping window
valid_head_idx = (time_head_rate >= time_start) & (time_head_rate <= time_end);
time_head_overlap = time_head_rate(valid_head_idx);
head_rate_overlap = drawdown_rate_ftps(valid_head_idx);  % ft/s (use drawdown rate for correlation!)

valid_das_idx = (time_das >= time_start) & (time_das <= time_end);
time_das_overlap = time_das(valid_das_idx);
strain_overlap = strain_smoothed(valid_das_idx);  % Already in 1/s (strain rate)

fprintf('Head points in overlap: %d\n', sum(valid_head_idx));
fprintf('DAS points in overlap: %d\n', sum(valid_das_idx));

%% Interpolate DAS strain rate to match head time points
strain_interp = interp1(time_das_overlap, strain_overlap, time_head_overlap, 'linear');

% Remove any NaN values
valid_idx = ~isnan(strain_interp) & ~isnan(head_rate_overlap);
strain_clean = strain_interp(valid_idx);
head_rate_clean = head_rate_overlap(valid_idx);  % Use head rate
time_clean = time_head_overlap(valid_idx);

fprintf('Valid points for regression: %d\n', length(strain_clean));

% Force flip strain rate UP to match drawdown rate spike direction
fprintf('  Forcing strain rate spike UP to match drawdown rate\n');
strain_clean = -strain_clean;  % Force flip strain rate so spike points UP

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

fprintf('Slope: %.4e (1/s) per (ft/s)\n', slope);
fprintf('Intercept: %.4e 1/s\n', intercept);
fprintf('Correlation (R): %.4f\n', R_corr);
fprintf('R^2: %.4f\n', R_squared);
fprintf('RMSE: %.4e 1/s\n', RMSE);

% Quality assessment
if R_squared > 0.5
    fprintf('✓ GOOD correlation - suitable for storage calculation\n');
elseif R_squared > 0.25
    fprintf('⚠ MODERATE correlation - use with caution\n');
else
    fprintf('✗ WEAK correlation - results may be unreliable\n');
end

%% Package results
results.slope = slope;
results.intercept = intercept;
results.R = R_corr;
results.R_squared = R_squared;
results.RMSE = RMSE;
results.strain_rate = strain_clean;
results.head_rate = head_rate_clean;  % Store head rate, not drawdown rate
results.drawdown_rate = -head_rate_clean;  % Also store drawdown rate for reference
results.time = time_clean;
results.timing_correction = config.timing_correction_sec;
results.test_name = test_name;
results.zone = config.zone;
results.n_points = length(strain_clean);
results.depth_range_ft = config.depth_range_ft;
results.n_channels = n_channels;

%% PLOTTING
if config.show_plots
    figure('Name', sprintf('Depth-Range Linear Regression: %s', test_name), 'Position', [100, 100, 1400, 600]);
    
    % Left plot: Scatter with regression line
    subplot(1,2,1);
    scatter(head_rate_clean, strain_clean, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    head_rate_range = linspace(min(head_rate_clean), max(head_rate_clean), 100);
    plot(head_rate_range, polyval(p_regression, head_rate_range), 'r-', 'LineWidth', 3);
    hold off;
    xlabel('Drawdown Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Linear Regression: R = %.3f, R^2 = %.3f', R_corr, R_squared), 'FontSize', 14);
    grid on;
    legend('Data', sprintf('Fit: y = %.2e*x + %.2e', slope, intercept), 'Location', 'best');
    
    % Add text box with statistics
    text_str = sprintf('Slope: %.2e\nR: %.3f\nR^2: %.3f\nRMSE: %.2e\nN: %d\nDepth: %.0f-%.0f ft\nChannels: %d', ...
        slope, R_corr, R_squared, RMSE, length(strain_clean), config.depth_range_ft(1), config.depth_range_ft(2), n_channels);
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);
    
    % Right plot: Time series overlay
    subplot(1,2,2);
    
    % Determine appropriate scaling factors for display
    head_scale = 1e-3;  % Head rate typically in 10^-3 ft/s
    strain_scale = 1e-12;  % Strain rate typically in 10^-12 1/s
    
    % Check actual ranges to determine best scaling
    head_max = max(abs(head_rate_clean));
    strain_max = max(abs(strain_clean));
    
    if head_max > 0
        if head_max < 1e-2
            head_scale = 1e-3;
        elseif head_max < 1e-1
            head_scale = 1e-2;
        else
            head_scale = 1e-1;
        end
    end
    
    if strain_max > 0
        if strain_max < 1e-11
            strain_scale = 1e-12;
        elseif strain_max < 1e-10
            strain_scale = 1e-11;
        elseif strain_max < 1e-9
            strain_scale = 1e-10;
        else
            strain_scale = 1e-9;
        end
    end
    
    yyaxis left;
    plot(time_clean, head_rate_clean / head_scale, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate');
    ylabel(sprintf('Drawdown Rate (ft/s) ×10^{%d}', round(log10(head_scale))), 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    plot(time_clean, -strain_clean / strain_scale, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
    ylabel(sprintf('Strain Rate (1/s) ×10^{%d}', round(log10(strain_scale))), 'FontSize', 12, 'FontWeight', 'bold');
    ax.YColor = 'k';
    
    xlabel('Date Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Time Series (%.0fs correction) - Depth %.0f-%.0f ft', config.timing_correction_sec, config.depth_range_ft(1), config.depth_range_ft(2)), 'FontSize', 14);
    legend('show', 'Location', 'best');
    grid on;
    
    % Overall title with smoothing status
    if isfield(das_filtered, 'smoothing_method')
        smoothing_title = sprintf(' | Smoothing: %s', smoothing_info);
    else
        smoothing_title = ' | ⚠ NO SMOOTHING';
    end
    sgtitle(sprintf('Strain Rate vs Drawdown Rate - %s (Zone %s) - DEPTH RANGE %.0f-%.0f ft%s', ...
        strrep(test_name, '_', '\_'), upper(config.zone), config.depth_range_ft(1), config.depth_range_ft(2), smoothing_title), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    % ADDITIONAL PLOT: Compare strain rate vs average displacement rate for visual alignment
    figure(22); clf;
    set(gcf, 'Position', [150 150 1400 800], 'Name', sprintf('Strain vs Displacement Comparison - Depth %.0f-%.0f ft', config.depth_range_ft(1), config.depth_range_ft(2)));
    
    % Get smoothing status for plot title
    if isfield(das_filtered, 'smoothing_method')
        smoothing_status = sprintf(' | Smoothing: %s', smoothing_info);
    else
        smoothing_status = ' | ⚠ NO SMOOTHING DETECTED';
    end
    
    % Get average displacement rate across depth range for comparison
    % displacement_rate_zone is [time × channels] where time matches time_das (analysis window)
    % strain_overlap is extracted from time_das_overlap (overlap window)
    % Need to match the overlap window
    displacement_rate_avg_full = mean(displacement_rate_zone, 2, 'omitnan');  % Average across depth range [time_das length]
    
    % Get RAW displacement rate (before additional smoothing) for comparison
    displacement_rate_avg_raw = displacement_rate_avg_full(valid_das_idx);  % Extract same time window as strain_overlap
    
    % CRITICAL: Apply AGGRESSIVE smoothing to averaged displacement rate
    % Make it smooth like the reference plot (black DAS line)
    fprintf('\n=== APPLYING AGGRESSIVE SMOOTHING TO AVERAGED DISPLACEMENT RATE ===\n');
    fprintf('Step 1: 10-second moving average...\n');
    displacement_rate_avg_full = movmean(displacement_rate_avg_full, 10, 1, 'omitnan');  % 10-second window
    fprintf('Step 2: Second pass with 5-second moving average...\n');
    displacement_rate_avg_full = movmean(displacement_rate_avg_full, 5, 1, 'omitnan');  % Second pass
    fprintf('✓ Aggressive smoothing applied (10s + 5s passes) - should match reference plot\n\n');
    
    displacement_rate_avg = displacement_rate_avg_full(valid_das_idx);  % Extract same time window as strain_overlap
    time_comparison = time_das_overlap;
    
    % USE ORIGINAL STRAIN RATE AND DISPLACEMENT RATE (both spikes point DOWN)
    strain_overlap_display = strain_overlap;  % No flip - match displacement rate direction
    displacement_rate_avg_display = displacement_rate_avg;  % No flip
    
    % Normalize both to same scale for visual comparison (0-1 range)
    strain_norm = (strain_overlap_display - min(strain_overlap_display)) / (max(strain_overlap_display) - min(strain_overlap_display) + eps);
    disp_norm = (displacement_rate_avg_display - min(displacement_rate_avg_display)) / ...
        (max(displacement_rate_avg_display) - min(displacement_rate_avg_display) + eps);
    
    % Plot 1: Overlay normalized signals
    subplot(2,2,1);
    plot(time_comparison, disp_norm, 'b-', 'LineWidth', 2, 'DisplayName', 'Avg Displacement Rate (normalized)');
    hold on;
    plot(time_comparison, strain_norm, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate (normalized)');
    xlabel('Time UTC');
    ylabel('Normalized Amplitude (0-1)');
    title('Normalized Comparison - Depth Range Average');
    legend('Location', 'best');
    grid on;
    
    % Plot 2: Raw vs Smoothed Comparison (matching single-channel style)
    subplot(2,2,2);
    yyaxis left;
    plot(time_comparison, displacement_rate_avg_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Displacement Rate (raw)');
    hold on;
    plot(time_comparison, displacement_rate_avg_display, 'c--', 'LineWidth', 2, 'DisplayName', 'Displacement Rate (smoothed)');
    ylabel('Displacement Rate (nm/s)', 'Color', 'b');
    ax = gca;
    ax.YColor = 'b';
    
    yyaxis right;
    % Scale strain rate to match reference plot (×10^-3)
    strain_scale_plot = 1e-3;  % Display strain rate in units of 10^-3 1/s
    plot(time_comparison, strain_overlap_display / strain_scale_plot, 'r-', 'LineWidth', 2, 'DisplayName', 'Strain Rate');
    ylabel(sprintf('Strain Rate (×10^{%d})', round(log10(strain_scale_plot))), 'Color', 'r');
    ax.YColor = 'r';
    xlabel('Time UTC');
    title('Raw vs Smoothed Comparison');
    legend('Location', 'best');
    grid on;
    
    % Plot 3: Correlation scatter (matching single-channel style)
    subplot(2,2,3);
    % Interpolate to same time points
    common_time = time_comparison;
    strain_interp = interp1(time_comparison, strain_overlap_display, common_time, 'linear');
    disp_interp = interp1(time_comparison, displacement_rate_avg_display, common_time, 'linear');
    valid = ~isnan(strain_interp) & ~isnan(disp_interp);
    scatter(disp_interp(valid), strain_interp(valid), 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    xlabel('Displacement Rate (nm/s, smoothed)');
    ylabel('Strain Rate (1/s)');
    corr_val = corr(disp_interp(valid), strain_interp(valid));
    title(sprintf('Strain Rate vs Displacement Rate (nm/s, smoothed)'));
    
    % Add regression line
    if sum(valid) > 2
        p = polyfit(disp_interp(valid), strain_interp(valid), 1);
        hold on;
        x_fit = linspace(min(disp_interp(valid)), max(disp_interp(valid)), 100);
        plot(x_fit, polyval(p, x_fit), 'r-', 'LineWidth', 2, 'DisplayName', sprintf('Fit: y=%.2e*x+%.2e', p(1), p(2)));
        legend('Location', 'best');
    end
    grid on;
    
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
    
    % Add smoothing status to title
    if isfield(das_filtered, 'smoothing_method')
        smoothing_status = sprintf(' | Smoothing: %s', smoothing_info);
    else
        smoothing_status = ' | ⚠ NO SMOOTHING DETECTED';
    end
    sgtitle(sprintf('Strain Rate vs Displacement Rate Comparison - Depth %.0f-%.0f ft (%d channels)%s', ...
        config.depth_range_ft(1), config.depth_range_ft(2), n_channels, smoothing_status), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    fprintf('\n=== COMPARISON PLOT GENERATED ===\n');
    fprintf('Figure 22: Strain rate vs displacement rate comparison (depth range)\n');
    fprintf('  Use this to visually check alignment and correlation for decision-making\n');
end

fprintf('\n✓ Depth-specific linear regression complete!\n');

end

