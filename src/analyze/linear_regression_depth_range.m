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
displacement_rate_zone = displacement_rate_full(:, depth_mask);

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
        displacement_diff = displacement_rate_full(:, ch_idx_L) - displacement_rate_full(:, ch_idx);
        % Divide by L to get strain rate: ε̇ = difference / L
        strain_rate_zone(:, ch) = displacement_diff / (gauge_length_m * 1e9);  % Convert nm to m
    else
        % Channel too close to end - can't calculate difference
        strain_rate_zone(:, ch) = NaN;
    end
end

% Average strain rates across the depth range
strain_smoothed = mean(strain_rate_zone, 2, 'omitnan');  % Average across depths → [time × 1]

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
head_rate_overlap = head_rate_ftps(valid_head_idx);  % ft/s (use head rate, not drawdown rate!)

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

%% LINEAR REGRESSION: Strain Rate vs Head Rate
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
    xlabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
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
    yyaxis left;
    plot(time_clean, head_rate_clean, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Head Rate');
    ylabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    plot(time_clean, strain_clean, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
    ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax.YColor = 'k';
    
    xlabel('Date Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Time Series (%.0fs correction) - Depth %.0f-%.0f ft', config.timing_correction_sec, config.depth_range_ft(1), config.depth_range_ft(2)), 'FontSize', 14);
    legend('show', 'Location', 'best');
    grid on;
    
    % Overall title
    sgtitle(sprintf('Strain Rate vs Drawdown Rate - %s (Zone %s) - DEPTH RANGE %.0f-%.0f ft', ...
        strrep(test_name, '_', '\_'), upper(config.zone), config.depth_range_ft(1), config.depth_range_ft(2)), ...
        'FontSize', 16, 'FontWeight', 'bold');
end

fprintf('\n✓ Depth-specific linear regression complete!\n');

end

