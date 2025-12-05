%% ROI Timing Optimization Script
% Find optimal timing correction for maximum envelope method

if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first');
end

fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║  ROI TIMING OPTIMIZATION (Maximum Envelope Method)            ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n\n');

% Test range: 15s to 25s
timing_values = 15:1:25;
results_matrix = zeros(length(timing_values), 4);

fprintf('Testing timing corrections: %ds to %ds\n\n', min(timing_values), max(timing_values));
fprintf('%-10s | %-10s | %-12s | %-12s\n', 'Timing(s)', 'R²', 'Slope', 'Peak Strain');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:length(timing_values)
    timing_sec = timing_values(i);
    
    lr_config = struct();
    lr_config.zone = 'z5';
    lr_config.depth_range_ft = [255, 315];
    lr_config.timing_correction_sec = timing_sec;
    lr_config.show_plots = false;
    lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                                datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];
    
    try
        roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);
        
        results_matrix(i, 1) = timing_sec;
        results_matrix(i, 2) = roi_results.R_squared;
        results_matrix(i, 3) = roi_results.slope;
        results_matrix(i, 4) = max(abs(roi_results.strain_rate));
        
        fprintf('%-10d | %-10.4f | %-12.4e | %-12.4e', timing_sec, roi_results.R_squared, roi_results.slope, max(abs(roi_results.strain_rate)));
        
        if results_matrix(i, 2) == max(results_matrix(1:i, 2))
            fprintf(' ← BEST');
        end
        fprintf('\n');
        
    catch ME
        fprintf('%-10d | ERROR: %s\n', timing_sec, ME.message);
        results_matrix(i, :) = [timing_sec, NaN, NaN, NaN];
    end
end

fprintf('%s\n', repmat('-', 1, 60));

% Find optimal timing
[max_r2, best_idx] = max(results_matrix(:, 2));
optimal_timing = results_matrix(best_idx, 1);
optimal_slope = results_matrix(best_idx, 3);
optimal_peak = results_matrix(best_idx, 4);

fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║  OPTIMAL TIMING FOUND                                         ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n\n');
fprintf('  Optimal Timing: %d seconds\n', optimal_timing);
fprintf('  Best R²: %.4f (%.2f%%)\n', max_r2, max_r2*100);
fprintf('  Slope: %.4e (1/s)/(m/s)\n', optimal_slope);
fprintf('  Peak Strain: %.4e 1/s\n', optimal_peak);
fprintf('\n');

% Run final analysis with optimal timing and PLOTS
fprintf('Running final analysis with optimal timing (%ds)...\n\n', optimal_timing);

lr_config = struct();
lr_config.zone = 'z5';
lr_config.depth_range_ft = [255, 315];
lr_config.timing_correction_sec = optimal_timing;
lr_config.show_plots = true;
lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                            datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];

roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);

fprintf('\n✓ Timing optimization complete! Use %ds for best R².\n', optimal_timing);

