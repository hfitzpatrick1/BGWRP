function renormalize_to_zero(input_csv, output_csv, pump_start_elapsed, baseline_window)
%RENORMALIZE_TO_ZERO Renormalize existing data to zero baseline
%
% Usage:
%   renormalize_to_zero(input_csv, output_csv, pump_start_elapsed, baseline_window)
%
% pump_start_elapsed: time in seconds when pump starts
% baseline_window: [start_sec, end_sec] for baseline period (default: 500 sec before pump)

if nargin < 4
    % Use early stable period (first 30 min to 2 hours of data)
    baseline_window = [1800, 7200];  % 30 min to 2 hours
end

console_log('=== RENORMALIZING TO ZERO BASELINE ===\n');

%% Load data
data = readtable(input_csv);
col_names = data.Properties.VariableNames;

time_sec = data.(col_names{1});
drawdown_ft = data.(col_names{2});

%% Calculate baseline from pre-test period
baseline_mask = time_sec >= baseline_window(1) & time_sec <= baseline_window(2);
baseline_value = mean(drawdown_ft(baseline_mask), 'omitnan');

console_log('Baseline period: %.1f to %.1f seconds\n', baseline_window(1), baseline_window(2));
console_log('Original baseline value: %.4f ft\n', baseline_value);
console_log('Using %d points for baseline\n', sum(baseline_mask));

%% Normalize to zero
drawdown_normalized = drawdown_ft - baseline_value;

console_log('After normalization:\n');
console_log('  Pre-test mean: %.6f ft (should be ~0)\n', mean(drawdown_normalized(baseline_mask)));
console_log('  Max value: %.4f ft\n', max(drawdown_normalized));
console_log('  Min value: %.4f ft\n', min(drawdown_normalized));

%% Plot comparison
pump_times = pump_start_elapsed + [0, 3600, 7200, 10800, 14400];
rates = [50, 80, 110, 150, 0];

figure('Position', [50, 50, 1600, 800]);

% Original
subplot(2,1,1);
plot(time_sec, drawdown_ft, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'r--', 'Zero', 'LineWidth', 1.5);
yline(baseline_value, 'g--', 'Old Baseline', 'LineWidth', 1.5);
for i = 1:length(pump_times)
    if pump_times(i) >= 0 && pump_times(i) <= max(time_sec)
        xline(pump_times(i), 'k--', 'LineWidth', 1);
    end
end
ylabel('Drawdown (ft)');
title('ORIGINAL - Not normalized to zero');
grid on;

% Normalized
subplot(2,1,2);
plot(time_sec, drawdown_normalized, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'r--', 'Zero (Baseline)', 'LineWidth', 1.5);
for i = 1:length(pump_times)
    if pump_times(i) >= 0 && pump_times(i) <= max(time_sec)
        xline(pump_times(i), 'k--', 'LineWidth', 1.5);
        if rates(i) > 0
            text(pump_times(i), max(ylim)*0.95, sprintf('%d GPM', rates(i)), ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        else
            text(pump_times(i), max(ylim)*0.95, 'OFF', ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end
xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title('NORMALIZED - Baseline at zero');
grid on;

%% Export
export_table = table(time_sec, drawdown_normalized, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_csv);

console_log('\nExported normalized data to:\n%s\n', output_csv);
console_log('Baseline shifted by %.4f ft to normalize to zero\n', baseline_value);

end
