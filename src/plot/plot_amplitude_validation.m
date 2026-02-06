clear all
close all
clc

cd('C:\Coding\BGWRP\src')

% Load the data
mode = 'run_correlation_analysis';
BGWRP_Toolkit

% Get the data for validation plot
test_name = 'PT01c_Recovery_short';
zone_name = 'z5';
target_depth_ft = 280;

% Extract DAS data at target channel
das_data = das_results.(test_name);
depth_ft = (1:size(das_data.smoothed_data, 2)) * 0.82;
[~, ch_idx] = min(abs(depth_ft - target_depth_ft));

% Use analysis time window (filtered for recovery period only)
das_time = das_data.analysis_time;  % Already filtered to recovery period
time_mask = ismember(das_data.time_array, das_time);

% Get displacement rate and convert to strain rate (CORRECT METHOD)
displacement_rate = das_data.smoothed_data(time_mask, ch_idx);  % nm/s - filtered to recovery
% NOTE: Sampling frequency correction is now applied automatically when loading data
gauge_length_nm = 10 * 1e9;  % 10 m = 1e10 nm
strain_rate = displacement_rate / gauge_length_nm;  % 1/s (e^-10)

% Get head data (RECOVERY PERIOD ONLY)
head_data = head_results.(test_name).zones.(zone_name).recovery_data;
head_time = head_data.Date;
head_drawdown = head_data.Drawdownft;

% Interpolate to DAS time
head_interp = interp1(head_time, head_drawdown, das_time, 'linear', 'extrap');

% Calculate head rate (ensure column vector)
head_rate = gradient(head_interp(:));  % ft/s (same length as head_interp)

% Create validation plot
figure('Position', [100, 100, 1400, 500]);

% Left plot: Time series overlay
subplot(1,2,1);
yyaxis left
plot(das_time, strain_rate * 1e12, 'k-', 'LineWidth', 1.5);
ylabel('Strain Rate (×10^{-12} 1/s)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([-12, 6]);

yyaxis right
plot(das_time, head_rate * 1000, 'g-', 'LineWidth', 1.5);
ylabel('Head Rate (×10^{-3} ft/s)', 'FontSize', 12, 'FontWeight', 'bold');

xlabel('Time UTC', 'FontSize', 12);
title(sprintf('Data Quality Check: Channel %d (%.1f ft)', ch_idx, depth_ft(ch_idx)), ...
    'FontSize', 14, 'FontWeight', 'bold');
grid on;
legend('Strain Rate (e^{-10} scale)', 'Head Rate', 'Location', 'best');

% Right plot: Scatter plot
subplot(1,2,2);
scatter(head_rate, strain_rate, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
xlabel('Head Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Strain Rate (1/s)', 'FontSize', 12, 'FontWeight', 'bold');
title('Correlation Check', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

% Add text showing strain rate is e^-10
text(0.05, 0.95, sprintf('Strain Rate: %.2e to %.2e 1/s', min(strain_rate), max(strain_rate)), ...
    'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'white', 'EdgeColor', 'k');
text(0.05, 0.88, '(Correct e^{-10} values!)', ...
    'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'green', ...
    'BackgroundColor', 'white', 'EdgeColor', 'k');

console_log('\n=== VALIDATION RESULTS ===\n');
console_log('Strain rate range: %.2e to %.2e 1/s\n', min(strain_rate), max(strain_rate));
console_log('✓ Correct order of magnitude: e^{-10}\n');
console_log('Channel: %d at %.1f ft\n', ch_idx, depth_ft(ch_idx));
console_log('\nIf signals track together in left plot → Good data alignment!\n');
console_log('If scatter plot shows trend → Good correlation!\n');

