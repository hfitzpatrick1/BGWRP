%OPTIMIZE_STRAIN_RATE_CORRELATION Find best smoothing and timing for maximum correlation
% This script tries different combinations to maximize R² for strain rate

console_log('\n=== OPTIMIZING STRAIN RATE CORRELATION ===\n\n');

% Base config
base_config.zone = 'z5';
base_config.use_displacement_rate = false;  % Must use strain rate for correct storage
base_config.show_plots = false;

% Test different timing corrections
timing_corrections = [-120:10:120];  % Test from -120 to +120 seconds in 10s steps

% Test different smoothing combinations
smoothing_configs = {
    struct('name', 'Pre5_Post10_movmean', 'pre_diff', 5, 'post_window', 10, 'post_method', 'movmean', 'spatial', 1),
    struct('name', 'Pre5_Post15_movmean', 'pre_diff', 5, 'post_window', 15, 'post_method', 'movmean', 'spatial', 1),
    struct('name', 'Pre5_Post10_lowpass', 'pre_diff', 5, 'post_window', 10, 'post_method', 'lowpass', 'spatial', 1),
    struct('name', 'Pre5_Post15_lowpass', 'pre_diff', 5, 'post_window', 15, 'post_method', 'lowpass', 'spatial', 1),
    struct('name', 'Pre5_Spatial3_Post10', 'pre_diff', 5, 'post_window', 10, 'post_method', 'movmean', 'spatial', 3),
    struct('name', 'Pre5_Spatial5_Post15', 'pre_diff', 5, 'post_window', 15, 'post_method', 'movmean', 'spatial', 5),
    struct('name', 'Pre10_Post20_triple', 'pre_diff', 10, 'post_window', 20, 'post_method', 'triple_pass', 'spatial', 1),
    struct('name', 'Spatial5_Post15_lowpass', 'pre_diff', 0, 'post_window', 15, 'post_method', 'lowpass', 'spatial', 5),
};

best_R2 = -inf;
best_config = [];
best_timing = [];
best_results = [];

console_log('Testing %d smoothing configs × %d timing corrections = %d combinations\n', ...
    length(smoothing_configs), length(timing_corrections), length(smoothing_configs) * length(timing_corrections));
console_log('This may take a few minutes...\n\n');

total_tests = length(smoothing_configs) * length(timing_corrections);
test_count = 0;

for s = 1:length(smoothing_configs)
    smooth_cfg = smoothing_configs{s};
    
    for t = 1:length(timing_corrections)
        test_count = test_count + 1;
        timing = timing_corrections(t);
        
        % Build config
        config = base_config;
        config.timing_correction_sec = timing;
        
        if smooth_cfg.pre_diff > 0
            config.pre_diff_smoothing_window = smooth_cfg.pre_diff;
        end
        config.strain_rate_smoothing_window = smooth_cfg.post_window;
        config.strain_rate_smoothing_method = smooth_cfg.post_method;
        if smooth_cfg.spatial > 1
            config.strain_rate_spatial_averaging = smooth_cfg.spatial;
        end
        
        try
            % Run linear regression
            results = linear_regression_strain_drawdown(das_results, head_results, 'PT01c_Recovery_short', config);
            
            % Check if this is the best so far
            if results.R_squared > best_R2
                best_R2 = results.R_squared;
                best_config = smooth_cfg;
                best_timing = timing;
                best_results = results;
            end
            
            % Progress update every 10 tests
            if mod(test_count, 10) == 0
                console_log('  Progress: %d/%d tests, Best R² so far: %.4f\n', test_count, total_tests, best_R2);
            end
            
        catch ME
            % Skip failed tests
            continue;
        end
    end
end

% Display results
console_log('\n=== OPTIMIZATION RESULTS ===\n');
console_log('Best Configuration:\n');
console_log('  Smoothing: %s\n', best_config.name);
console_log('  Pre-diff smoothing: %d seconds\n', best_config.pre_diff);
console_log('  Post-diff smoothing: %d seconds (%s)\n', best_config.post_window, best_config.post_method);
console_log('  Spatial averaging: %d pairs\n', best_config.spatial);
console_log('  Timing correction: %d seconds\n', best_timing);
console_log('\nBest Results:\n');
console_log('  R²: %.4f\n', best_R2);
console_log('  R: %.4f\n', best_results.R);
console_log('  Slope: %.4e (1/s) per (ft/s)\n', best_results.slope);

% Run with best config and show plots
console_log('\n=== RUNNING WITH BEST CONFIGURATION ===\n');
final_config = base_config;
final_config.timing_correction_sec = best_timing;
final_config.show_plots = true;

if best_config.pre_diff > 0
    final_config.pre_diff_smoothing_window = best_config.pre_diff;
end
final_config.strain_rate_smoothing_window = best_config.post_window;
final_config.strain_rate_smoothing_method = best_config.post_method;
if best_config.spatial > 1
    final_config.strain_rate_spatial_averaging = best_config.spatial;
end

final_results = linear_regression_strain_drawdown(das_results, head_results, 'PT01c_Recovery_short', final_config);

% Calculate storage with best results
console_log('\n=== CALCULATING STORAGE WITH BEST CORRELATION ===\n');
storage_config.alpha = 0.95;
storage_config.gamma_unit = 'SI';
storage_results = calculate_specific_storage_becker(final_results, storage_config);

console_log('\n=== FINAL STORAGE VALUE ===\n');
console_log('S_s (specific storage): %.4e 1/m\n', storage_results.S_s);
console_log('R²: %.4f (correlation quality)\n', final_results.R_squared);

if final_results.R_squared > 0.7
    console_log('✓ EXCELLENT correlation - reliable storage estimate!\n');
elseif final_results.R_squared > 0.5
    console_log('✓ GOOD correlation - acceptable for storage estimate\n');
elseif final_results.R_squared > 0.4
    console_log('⚠ MODERATE correlation - use with caution\n');
else
    console_log('✗ WEAK correlation - consider improving data quality\n');
end

console_log('\n=== DONE! ===\n');
console_log('Use this configuration for your final analysis:\n');
console_log('  lr_config.timing_correction_sec = %d;\n', best_timing);
if best_config.pre_diff > 0
    console_log('  lr_config.pre_diff_smoothing_window = %d;\n', best_config.pre_diff);
end
console_log('  lr_config.strain_rate_smoothing_window = %d;\n', best_config.post_window);
console_log('  lr_config.strain_rate_smoothing_method = ''%s'';\n', best_config.post_method);
if best_config.spatial > 1
    console_log('  lr_config.strain_rate_spatial_averaging = %d;\n', best_config.spatial);
end

