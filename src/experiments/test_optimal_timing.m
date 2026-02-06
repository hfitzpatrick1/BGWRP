% Optimal timing correction determined empirically
% Date: 2024-11-15
% Test: PT01c_Recovery_short
% Result: timing_correction_sec = 8 seconds gives R = 0.724, R^2 = 0.525

lr_config.timing_correction_sec = 8;  % OPTIMAL VALUE
lr_config.zone = 'z5';
lr_config.show_plots = true;

results = linear_regression_strain_drawdown(das_results, head_results, 'PT01c_Recovery_short', lr_config);

fprintf('\n=== OPTIMAL TIMING CORRECTION ===\n');
fprintf('Correction: %.1f seconds\n', lr_config.timing_correction_sec);
fprintf('R = %.3f\n', results.R);
fprintf('R^2 = %.3f\n', results.R_squared);
fprintf('Slope = %.3e ns/s per ft/min\n', results.slope);
fprintf('Intercept = %.3e ns/s\n', results.intercept);
fprintf('N = %d data points\n', results.N);
