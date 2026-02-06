%% Timing Correction Optimization Script
% Systematically test different timing corrections to maximize R²

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

console_log('╔═══════════════════════════════════════════════════════════════╗\n');
console_log('║  TIMING CORRECTION OPTIMIZATION (Coherence + Bourdet)         ║\n');
console_log('╚═══════════════════════════════════════════════════════════════╝\n\n');

% Test range: 13s to 22s in 1s increments
timing_values = 13:1:22;
results_matrix = zeros(length(timing_values), 4);  % [timing, R², slope, RMSE]

console_log('Testing timing corrections: %ds to %ds\n\n', min(timing_values), max(timing_values));
console_log('%-10s | %-10s | %-12s | %-12s\n', 'Timing(s)', 'R²', 'Slope', 'RMSE');
console_log('%s\n', repmat('-', 1, 60));

for i = 1:length(timing_values)
    timing_sec = timing_values(i);
    
    % Set up ROI analysis configuration
    lr_config = struct();
    lr_config.zone = 'z5';
    lr_config.depth_range_ft = [250, 350];
    lr_config.timing_correction_sec = timing_sec;
    lr_config.show_plots = false;  % Disable plots for speed
    
    % Focus on peak region
    lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                                datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];
    
    % Run ROI analysis (suppress output)
    try
        roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);
        
        % Store results
        results_matrix(i, 1) = timing_sec;
        results_matrix(i, 2) = roi_results.R_squared;
        results_matrix(i, 3) = roi_results.slope;
        results_matrix(i, 4) = roi_results.RMSE;
        
        % Print result
        console_log('%-10d | %-10.4f | %-12.4e | %-12.4e', timing_sec, roi_results.R_squared, roi_results.slope, roi_results.RMSE);
        
        % Highlight best so far
        if results_matrix(i, 2) == max(results_matrix(1:i, 2))
            console_log(' ← BEST');
        end
        console_log('\n');
        
    catch ME
        console_log('%-10d | ERROR: %s\n', timing_sec, ME.message);
        results_matrix(i, :) = [timing_sec, NaN, NaN, NaN];
    end
end

console_log('%s\n', repmat('-', 1, 60));

% Find optimal timing
[max_r2, best_idx] = max(results_matrix(:, 2));
optimal_timing = results_matrix(best_idx, 1);
optimal_slope = results_matrix(best_idx, 3);
optimal_rmse = results_matrix(best_idx, 4);

console_log('\n');
console_log('╔═══════════════════════════════════════════════════════════════╗\n');
console_log('║  OPTIMAL TIMING CORRECTION FOUND                              ║\n');
console_log('╚═══════════════════════════════════════════════════════════════╝\n\n');
console_log('  Optimal Timing: %d seconds\n', optimal_timing);
console_log('  Best R²: %.4f (%.2f%%)\n', max_r2, max_r2*100);
console_log('  Slope: %.4e (1/s)/(m/s)\n', optimal_slope);
console_log('  RMSE: %.4e 1/s\n', optimal_rmse);
console_log('\n');

% Run final analysis with optimal timing and PLOTS ENABLED
console_log('Running final analysis with optimal timing (%ds) and plots...\n\n', optimal_timing);

lr_config = struct();
lr_config.zone = 'z5';
lr_config.depth_range_ft = [250, 350];
lr_config.timing_correction_sec = optimal_timing;
lr_config.show_plots = true;  % Enable plots for final run

lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                            datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];

% Final run with plots
roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);

console_log('\n✓ Timing optimization complete! Use %ds timing correction for best results.\n', optimal_timing);


