function results = linear_regression_strain_drawdown(das_results, head_results, test_name, config)
%LINEAR_REGRESSION_STRAIN_DRAWDOWN Perform linear regression between DAS strain rate and drawdown rate
%
% Inputs:
%   das_results - Structure with DAS correlation results
%   head_results - Structure with head correlation results
%   test_name - Name of test (e.g., 'PT01c_Recovery_short')
%   config - Configuration structure with fields:
%            .timing_correction_sec - Time shift to apply to head data (seconds backward)
%            .zone - Zone to analyze (default: 'z5')
%            .show_plots - Whether to generate plots (default: true)
%
% Outputs:
%   results - Structure containing:
%            .slope - Regression slope (1/s per ft/s)
%            .intercept - Regression intercept (1/s)
%            .R - Correlation coefficient
%            .R_squared - R^2
%            .RMSE - Root mean square error
%            .strain_rate - Clean strain rate data (1/s)
%            .drawdown_rate - Clean drawdown rate data (ft/s)
%            .time - Time vector for aligned data
%            .timing_correction - Applied timing correction (sec)

% Set defaults
if ~isfield(config, 'zone'), config.zone = 'z5'; end
if ~isfield(config, 'show_plots'), config.show_plots = true; end
if ~isfield(config, 'timing_correction_sec'), config.timing_correction_sec = 7.5; end

%% Extract data
fprintf('\n=== LINEAR REGRESSION: STRAIN RATE vs DRAWDOWN RATE ===\n');
fprintf('Test: %s\n', test_name);
fprintf('Zone: %s\n', config.zone);

das_filtered = das_results.(test_name);
head_filtered = head_results.(test_name);

fprintf('DAS data: %d time points\n', length(das_filtered.analysis_time));
fprintf('Head data: %d time points\n', length(head_filtered.zones.(config.zone).recovery_data.Date));

%% Get DAS strain rate using correct formula: ε̇ = [u̇(z+L) - u̇(z)] / L
% NOTE: analysis_strain_rate is MISLABELED - it's actually displacement rate in nm/s!
% We need the full matrix to calculate the difference across gauge length
gauge_length_m = 10;  % DAS gauge length in meters
spatial_resolution_m = 0.25;  % Spatial resolution per channel
channels_per_gauge = round(gauge_length_m / spatial_resolution_m);  % ~40 channels

% Get the channel index for the representative channel (285 ft)
if isfield(das_filtered, 'pumping_zone') && isfield(das_filtered.pumping_zone, 'channel_idx')
    channel_idx = das_filtered.pumping_zone.channel_idx;
    
    % CORRECT METHOD: Calculate difference across gauge length
    if isfield(das_filtered, 'smoothed_data') && isfield(das_filtered, 'time_array')
        displacement_rate_full = das_filtered.smoothed_data;  % [time × depth]
        time_das_full = das_filtered.time_array;
        
        % Find time window matching analysis_time
        time_das = das_filtered.analysis_time;
        [~, time_start_idx] = min(abs(time_das_full - time_das(1)));
        [~, time_end_idx] = min(abs(time_das_full - time_das(end)));
        time_mask = time_start_idx:time_end_idx;
        
        % Get displacement rate at channel z and channel z+L
        channel_idx_L = channel_idx + channels_per_gauge;
        
        if channel_idx_L <= size(displacement_rate_full, 2)
            % Calculate difference: [u̇(z+L) - u̇(z)]
            displacement_at_z = displacement_rate_full(time_mask, channel_idx);
            displacement_at_z_L = displacement_rate_full(time_mask, channel_idx_L);
            displacement_diff = displacement_at_z_L - displacement_at_z;
            
            % Divide by L to get strain rate: ε̇ = difference / L
            strain_smoothed = displacement_diff / (gauge_length_m * 1e9);  % Convert nm to m
            
            fprintf('Calculating strain rate using difference across gauge length:\n');
            fprintf('  Channel z: %d (%.1f ft)\n', channel_idx, das_filtered.depth_ft(channel_idx));
            fprintf('  Channel z+L: %d (%.1f ft)\n', channel_idx_L, das_filtered.depth_ft(channel_idx_L));
            fprintf('  Gauge length: %.1f m (%d channels)\n', gauge_length_m, channels_per_gauge);
            fprintf('Displacement difference range: %.2e to %.2e nm/s\n', min(displacement_diff), max(displacement_diff));
            fprintf('Strain rate range: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
        else
            error('Channel z+L (%d) exceeds available channels (%d)', channel_idx_L, size(displacement_rate_full, 2));
        end
    else
        error('Need smoothed_data and time_array fields to calculate strain rate correctly');
    end
else
    % Fallback: use analysis_strain_rate as single channel (old method)
    displacement_rate_smoothed = das_filtered.analysis_strain_rate;  % nm/s (displacement rate)
    strain_smoothed = displacement_rate_smoothed / (gauge_length_m * 1e9);  % OLD METHOD - incorrect!
    time_das = das_filtered.analysis_time;
    fprintf('WARNING: Using old method (single channel). Need full matrix for correct calculation!\n');
    fprintf('Displacement rate range: %.2e to %.2e nm/s\n', min(displacement_rate_smoothed), max(displacement_rate_smoothed));
    fprintf('Strain rate range: %.2e to %.2e 1/s\n', min(strain_smoothed), max(strain_smoothed));
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

%% Calculate drawdown RATE (derivative of head)
dt_head = diff(seconds(zone_time_corrected - zone_time_corrected(1)));  % Time step (seconds)
dh = diff(zone_head);  % Head change (ft)
drawdown_rate_ftps = dh ./ dt_head;  % ft/s (keep in ft/s to match strain rate 1/s)
time_head_rate = zone_time_corrected(1:end-1);  % Time vector (one less after diff)

fprintf('Drawdown rate range: %.4e to %.4e ft/s\n', min(drawdown_rate_ftps), max(drawdown_rate_ftps));

%% Find overlapping time range (CRITICAL - avoids extrapolation)
time_start = max(min(time_das), min(time_head_rate));
time_end = min(max(time_das), max(time_head_rate));

fprintf('\n=== OVERLAPPING TIME RANGE ===\n');
fprintf('DAS time: %s to %s\n', datestr(min(time_das)), datestr(max(time_das)));
fprintf('Head time: %s to %s\n', datestr(min(time_head_rate)), datestr(max(time_head_rate)));
fprintf('Overlap: %s to %s (%.1f seconds)\n', datestr(time_start), datestr(time_end), seconds(time_end - time_start));

% Extract data only within overlapping window
valid_head_idx = (time_head_rate >= time_start) & (time_head_rate <= time_end);
time_head_overlap = time_head_rate(valid_head_idx);
drawdown_overlap = drawdown_rate_ftps(valid_head_idx);  % ft/s

valid_das_idx = (time_das >= time_start) & (time_das <= time_end);
time_das_overlap = time_das(valid_das_idx);
strain_overlap = strain_smoothed(valid_das_idx);  % Already in 1/s (strain rate)

fprintf('Head points in overlap: %d\n', sum(valid_head_idx));
fprintf('DAS points in overlap: %d\n', sum(valid_das_idx));

%% Interpolate DAS strain rate to match head time points
strain_interp = interp1(time_das_overlap, strain_overlap, time_head_overlap, 'linear');

% Remove any NaN values
valid_idx = ~isnan(strain_interp) & ~isnan(drawdown_overlap);
strain_clean = strain_interp(valid_idx);
drawdown_clean = drawdown_overlap(valid_idx);
time_clean = time_head_overlap(valid_idx);

fprintf('Valid points for regression: %d\n', length(strain_clean));

%% LINEAR REGRESSION: Strain Rate vs Drawdown Rate
fprintf('\n=== REGRESSION RESULTS ===\n');
p_regression = polyfit(drawdown_clean, strain_clean, 1);
slope = p_regression(1);  % (1/s) per (ft/s) - true strain rate!
intercept = p_regression(2);  % 1/s

% Calculate correlation and R^2
R_matrix = corrcoef(drawdown_clean, strain_clean);
R_corr = R_matrix(1,2);
R_squared = R_corr^2;

% Calculate residuals and RMSE
strain_predicted = polyval(p_regression, drawdown_clean);
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
    fprintf('✗ WEAK correlation - NOT suitable for storage calculation\n');
end

%% Store results
results.slope = slope;
results.intercept = intercept;
results.R = R_corr;
results.R_squared = R_squared;
results.RMSE = RMSE;
results.strain_rate = strain_clean;
results.drawdown_rate = drawdown_clean;
results.time = time_clean;
results.timing_correction = config.timing_correction_sec;
results.test_name = test_name;
results.zone = config.zone;
results.n_points = length(strain_clean);

%% PLOTTING
if config.show_plots
    figure(20); clf;
    set(gcf, 'Position', [50 50 1400 600], 'Name', sprintf('Linear Regression - %s', test_name));
    
    % Left plot: Scatter with regression line
    subplot(1,2,1);
    scatter(drawdown_clean, strain_clean, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    drawdown_range = linspace(min(drawdown_clean), max(drawdown_clean), 100);
    plot(drawdown_range, polyval(p_regression, drawdown_range), 'r-', 'LineWidth', 3);
    xlabel('Drawdown Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
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
    subplot(1,2,2);
    yyaxis left;
    plot(time_clean, drawdown_clean, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate');
    ylabel('Drawdown Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    plot(time_clean, strain_clean, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
    ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ax.YColor = 'k';
    
    xlabel('Time UTC', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Time Series (%ds correction)', config.timing_correction_sec), 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    set(gca, 'FontSize', 11);
    
    sgtitle(sprintf('Strain Rate vs Drawdown Rate - %s (Zone %s)', test_name, upper(config.zone)), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    fprintf('\n=== PLOT GENERATED ===\n');
    fprintf('Figure 20: Linear regression and time series\n');
end

fprintf('\n✓ Linear regression analysis complete!\n');
fprintf('Next: Adjust timing_correction_sec if peaks not aligned, or proceed to storage calculation\n\n');

end

