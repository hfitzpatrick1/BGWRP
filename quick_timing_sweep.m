%% Quick timing sweep for 250-350 ft with 5s movmean

if ~exist('das_results', 'var')
    error('Run correlation analysis first');
end

fprintf('Testing timing: 10s to 20s\n');
timing_vals = 10:2:20;
results = zeros(length(timing_vals), 2);

for i = 1:length(timing_vals)
    lr_config = struct();
    lr_config.zone = 'z5';
    lr_config.depth_range_ft = [250, 350];
    lr_config.timing_correction_sec = timing_vals(i);
    lr_config.show_plots = false;
    lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                                datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];
    
    roi = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);
    results(i, :) = [timing_vals(i), roi.R_squared];
    fprintf('%2ds: R² = %.4f\n', timing_vals(i), roi.R_squared);
end

[best_r2, idx] = max(results(:, 2));
fprintf('\nBest: %ds with R² = %.4f\n', results(idx, 1), best_r2);











