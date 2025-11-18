%TEST_ALL_SMOOTHING_OPTIONS Test all smoothing options for strain rate
% This script tests all combinations of smoothing methods to find the best match
% for displacement rate smoothness

clear all;
close all;

fprintf('\n=== TESTING ALL SMOOTHING OPTIONS FOR STRAIN RATE ===\n\n');

% Base configuration
base_config.timing_correction_sec = 1;
base_config.zone = 'z5';
base_config.use_displacement_rate = false;
base_config.show_plots = false;  % We'll create our own comparison plots

% Test configurations
test_configs = {};

% Test 1: Default (5-second movmean)
test_configs{1} = base_config;
test_configs{1}.name = 'Default (5s movmean)';
test_configs{1}.strain_rate_smoothing_window = 5;
test_configs{1}.strain_rate_smoothing_method = 'movmean';

% Test 2: Larger window movmean
test_configs{2} = base_config;
test_configs{2}.name = '10s movmean';
test_configs{2}.strain_rate_smoothing_window = 10;
test_configs{2}.strain_rate_smoothing_method = 'movmean';

% Test 3: Even larger window
test_configs{3} = base_config;
test_configs{3}.name = '15s movmean';
test_configs{3}.strain_rate_smoothing_window = 15;
test_configs{3}.strain_rate_smoothing_method = 'movmean';

% Test 4: Pre-diff smoothing + post-diff
test_configs{4} = base_config;
test_configs{4}.name = 'Pre-diff 5s + Post 10s movmean';
test_configs{4}.pre_diff_smoothing_window = 5;
test_configs{4}.strain_rate_smoothing_window = 10;
test_configs{4}.strain_rate_smoothing_method = 'movmean';

% Test 5: Double pass
test_configs{5} = base_config;
test_configs{5}.name = '10s double_pass';
test_configs{5}.strain_rate_smoothing_window = 10;
test_configs{5}.strain_rate_smoothing_method = 'double_pass';

% Test 6: Triple pass
test_configs{6} = base_config;
test_configs{6}.name = '10s triple_pass';
test_configs{6}.strain_rate_smoothing_window = 10;
test_configs{6}.strain_rate_smoothing_method = 'triple_pass';

% Test 7: Gaussian
test_configs{7} = base_config;
test_configs{7}.name = '10s gaussian';
test_configs{7}.strain_rate_smoothing_window = 10;
test_configs{7}.strain_rate_smoothing_method = 'gaussian';

% Test 8: Double Gaussian
test_configs{8} = base_config;
test_configs{8}.name = '10s gaussian_double';
test_configs{8}.strain_rate_smoothing_window = 10;
test_configs{8}.strain_rate_smoothing_method = 'gaussian_double';

% Test 9: Median filter
test_configs{9} = base_config;
test_configs{9}.name = '10s movmedian';
test_configs{9}.strain_rate_smoothing_window = 10;
test_configs{9}.strain_rate_smoothing_method = 'movmedian';

% Test 10: Savitzky-Golay
test_configs{10} = base_config;
test_configs{10}.name = '11s savgol';
test_configs{10}.strain_rate_smoothing_window = 11;  % Must be odd
test_configs{10}.strain_rate_smoothing_method = 'savgol';

% Test 11: Lowpass filter
test_configs{11} = base_config;
test_configs{11}.name = '10s lowpass';
test_configs{11}.strain_rate_smoothing_window = 10;
test_configs{11}.strain_rate_smoothing_method = 'lowpass';

% Test 12: Exponential smoothing
test_configs{12} = base_config;
test_configs{12}.name = '10s exp_smooth';
test_configs{12}.strain_rate_smoothing_window = 10;
test_configs{12}.strain_rate_smoothing_method = 'exp_smooth';

% Test 13: Spatial averaging
test_configs{13} = base_config;
test_configs{13}.name = 'Spatial 3 pairs + 10s movmean';
test_configs{13}.strain_rate_spatial_averaging = 3;
test_configs{13}.strain_rate_smoothing_window = 10;
test_configs{13}.strain_rate_smoothing_method = 'movmean';

% Test 14: Pre-diff + Spatial + Post-diff
test_configs{14} = base_config;
test_configs{14}.name = 'Pre-diff 5s + Spatial 3 + Post 10s';
test_configs{14}.pre_diff_smoothing_window = 5;
test_configs{14}.strain_rate_spatial_averaging = 3;
test_configs{14}.strain_rate_smoothing_window = 10;
test_configs{14}.strain_rate_smoothing_method = 'movmean';

% Test 15: Maximum smoothness
test_configs{15} = base_config;
test_configs{15}.name = 'MAX: Pre 5s + Spatial 5 + Post 15s triple';
test_configs{15}.pre_diff_smoothing_window = 5;
test_configs{15}.strain_rate_spatial_averaging = 5;
test_configs{15}.strain_rate_smoothing_window = 15;
test_configs{15}.strain_rate_smoothing_method = 'triple_pass';

% Test 16: Lowpass with pre-diff
test_configs{16} = base_config;
test_configs{16}.name = 'Pre 5s + 10s lowpass';
test_configs{16}.pre_diff_smoothing_window = 5;
test_configs{16}.strain_rate_smoothing_window = 10;
test_configs{16}.strain_rate_smoothing_method = 'lowpass';

fprintf('Testing %d smoothing configurations...\n\n', length(test_configs));

% Store all results
all_results = cell(length(test_configs), 1);
all_configs = cell(length(test_configs), 1);

% Run all tests
for i = 1:length(test_configs)
    fprintf('\n--- Test %d/%d: %s ---\n', i, length(test_configs), test_configs{i}.name);
    
    try
        % Extract config (without name field)
        config = test_configs{i};
        config_name = config.name;
        config = rmfield(config, 'name');
        
        % Run linear regression
        results = linear_regression_strain_drawdown(das_results, head_results, 'PT01c_Recovery_short', config);
        
        % Store results
        all_results{i} = results;
        all_configs{i} = config;
        all_configs{i}.name = config_name;
        
        fprintf('  ✓ Completed: R² = %.3f, R = %.3f\n', results.R_squared, results.R);
        
    catch ME
        fprintf('  ✗ Failed: %s\n', ME.message);
        all_results{i} = [];
        all_configs{i} = test_configs{i};
    end
end

% Create comparison plots
fprintf('\n=== CREATING COMPARISON PLOTS ===\n');

% Plot 1: Time series comparison (all methods)
figure(100); clf;
set(gcf, 'Position', [50 50 1600 1000], 'Name', 'Strain Rate Smoothing Comparison - Time Series');

n_plots = length(test_configs);
n_cols = 4;
n_rows = ceil(n_plots / n_cols);

for i = 1:length(test_configs)
    if isempty(all_results{i})
        continue;
    end
    
    subplot(n_rows, n_cols, i);
    results = all_results{i};
    
    % Plot strain rate
    plot(results.time, results.strain_rate, 'k-', 'LineWidth', 1.5);
    xlabel('Time UTC');
    ylabel('Strain Rate (1/s)');
    title(all_configs{i}.name, 'FontSize', 9, 'Interpreter', 'none');
    grid on;
    
    % Add R² in corner
    text(0.02, 0.98, sprintf('R²=%.3f', results.R_squared), ...
        'Units', 'normalized', 'VerticalAlignment', 'top', ...
        'BackgroundColor', 'white', 'FontSize', 8);
end

sgtitle('Strain Rate Smoothing Comparison - All Methods', 'FontSize', 14, 'FontWeight', 'bold');

% Plot 2: R² comparison bar chart
figure(101); clf;
set(gcf, 'Position', [100 100 1400 600], 'Name', 'Smoothing Method Performance Comparison');

valid_idx = ~cellfun(@isempty, all_results);
valid_results = all_results(valid_idx);
valid_configs = all_configs(valid_idx);

R_squared = cellfun(@(r) r.R_squared, valid_results);
R_corr = cellfun(@(r) r.R, valid_results);
names = cellfun(@(c) c.name, valid_configs, 'UniformOutput', false);

subplot(1,2,1);
bar(R_squared);
ylabel('R²');
title('R² Comparison', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 45, 'FontSize', 8);
grid on;
ylim([0, max(R_squared) * 1.1]);

subplot(1,2,2);
bar(R_corr);
ylabel('Correlation (R)');
title('Correlation Comparison', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 45, 'FontSize', 8);
grid on;
ylim([0, max(R_corr) * 1.1]);

% Plot 3: Best 5 methods overlay
figure(102); clf;
set(gcf, 'Position', [150 150 1400 600], 'Name', 'Top 5 Smoothing Methods - Overlay');

[~, sort_idx] = sort(R_squared, 'descend');
top_5_idx = sort_idx(1:min(5, length(sort_idx)));

colors = lines(length(top_5_idx));
hold on;
for j = 1:length(top_5_idx)
    idx = top_5_idx(j);
    results = valid_results{idx};
    plot(results.time, results.strain_rate, 'Color', colors(j,:), ...
        'LineWidth', 2, 'DisplayName', valid_configs{idx}.name);
end
xlabel('Time UTC');
ylabel('Strain Rate (1/s)');
title('Top 5 Smoothing Methods (by R²)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on;

% Summary table
fprintf('\n=== SUMMARY TABLE ===\n');
fprintf('%-40s | %8s | %8s | %10s\n', 'Method', 'R²', 'R', 'RMSE');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:length(valid_results)
    results = valid_results{i};
    fprintf('%-40s | %8.3f | %8.3f | %10.2e\n', ...
        valid_configs{i}.name, results.R_squared, results.R, results.RMSE);
end

% Find best method
[best_R2, best_idx] = max(R_squared);
fprintf('\n=== BEST METHOD ===\n');
fprintf('Method: %s\n', valid_configs{best_idx}.name);
fprintf('R²: %.3f\n', best_R2);
fprintf('R: %.3f\n', R_corr(best_idx));
fprintf('RMSE: %.2e\n', valid_results{best_idx}.RMSE);

fprintf('\n=== COMPARISON COMPLETE ===\n');
fprintf('Check figures 100, 101, and 102 for visual comparisons\n');

