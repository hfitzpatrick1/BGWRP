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
%            .slope - Regression slope (ns/s per ft/min)
%            .intercept - Regression intercept (ns/s)
%            .R - Correlation coefficient
%            .R_squared - R²
%            .RMSE - Root mean square error
%            .strain_rate - Clean strain rate data (ns/s)
%            .drawdown_rate - Clean drawdown rate data (ft/min)
%            .time - Time vector for aligned data
%            .timing_correction - Applied timing correction (sec)

% Set defaults
if ~isfield(config, 'zone'), config.zone = 'z5'; end
if ~isfield(config, 'show_plots'), config.show_plots = true; end
if ~isfield(config, 'timing_correction_sec'), config.timing_correction_sec = 21; end

%% Extract data
fprintf('\n=== LINEAR REGRESSION: STRAIN RATE vs DRAWDOWN RATE ===\n');
fprintf('Test: %s\n', test_name);
fprintf('Zone: %s\n', config.zone);

das_filtered = das_results.(test_name);
head_filtered = head_results.(test_name);

fprintf('DAS data: %d time points\n', length(das_filtered.analysis_time));
fprintf('Head data: %d time points\n', length(head_filtered.zones.(config.zone).recovery_data.Date));

%% Get DAS strain rate (already smoothed with 5-second filter)
strain_smoothed = das_filtered.analysis_strain_rate;  % Strain RATE (1/s)
time_das = das_filtered.analysis_time;  % Datetime array

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
drawdown_rate_ftps = dh ./ dt_head;  % ft/s
drawdown_rate_ftmin = drawdown_rate_ftps * 60;  % Convert to ft/min
time_head_rate = zone_time_corrected(1:end-1);  % Time vector (one less after diff)

fprintf('Drawdown rate range: %.4f to %.4f ft/min\n', min(drawdown_rate_ftmin), max(drawdown_rate_ftmin));

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
drawdown_overlap = drawdown_rate_ftmin(valid_head_idx);

valid_das_idx = (time_das >= time_start) & (time_das <= time_end);
time_das_overlap = time_das(valid_das_idx);
strain_overlap = strain_smoothed(valid_das_idx) * 1e9;  % Convert to ns/s

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
slope = p_regression(1);  % ns/s per ft/min
intercept = p_regression(2);  % ns/s

% Calculate correlation and R²
R_matrix = corrcoef(drawdown_clean, strain_clean);
R_corr = R_matrix(1,2);
R_squared = R_corr^2;

% Calculate residuals and RMSE
strain_predicted = polyval(p_regression, drawdown_clean);
residuals = strain_clean - strain_predicted;
RMSE = sqrt(mean(residuals.^2));

fprintf('Slope: %.4e ns/s per ft/min\n', slope);
fprintf('Intercept: %.4e ns/s\n', intercept);
fprintf('Correlation (R): %.4f\n', R_corr);
fprintf('R²: %.4f\n', R_squared);
fprintf('RMSE: %.4e ns/s\n', RMSE);

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
    xlabel('Drawdown Rate (ft/min)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Strain Rate (ns/s)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Linear Regression: R = %.3f, R² = %.3f', R_corr, R_squared), 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend({'Data', sprintf('Fit: y = %.2e*x + %.2e', slope, intercept)}, 'Location', 'best', 'FontSize', 10);
    set(gca, 'FontSize', 11);
    
    % Add text box with statistics
    text_str = sprintf('Slope: %.2e\nR: %.3f\nR²: %.3f\nRMSE: %.2e\nN: %d', ...
        slope, R_corr, R_squared, RMSE, length(strain_clean));
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);
    
    % Right plot: Time series overlay
    subplot(1,2,2);
    yyaxis left;
    plot(time_clean, drawdown_clean, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate');
    ylabel('Drawdown Rate (ft/min)', 'FontSize', 12, 'FontWeight', 'bold');
    ax = gca;
    ax.YColor = [0.4660 0.6740 0.1880];
    
    yyaxis right;
    plot(time_clean, strain_clean, 'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
    ylabel('Strain Rate (ns/s)', 'FontSize', 12, 'FontWeight', 'bold');
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

