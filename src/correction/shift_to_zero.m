function shift_to_zero(input_csv, output_csv, shift_value)
%SHIFT_TO_ZERO Add a constant shift to normalize baseline to zero
%
% Usage: shift_to_zero(input_csv, output_csv, shift_value)
%
% shift_value: amount to add to each point (e.g., 0.05)

console_log('=== SHIFTING DATA BY %.4f ft ===\n', shift_value);

%% Load data
data = readtable(input_csv);
col_names = data.Properties.VariableNames;

time_sec = data.(col_names{1});
drawdown_ft = data.(col_names{2});

%% Shift
drawdown_shifted = drawdown_ft + shift_value;

console_log('Original range: %.4f to %.4f ft\n', min(drawdown_ft), max(drawdown_ft));
console_log('Shifted range: %.4f to %.4f ft\n', min(drawdown_shifted), max(drawdown_shifted));

%% Export
export_table = table(time_sec, drawdown_shifted, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_csv);

console_log('\nExported to: %s\n', output_csv);

% Quick plot
figure('Position', [100, 100, 1400, 600]);
plot(time_sec, drawdown_shifted, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Zero (Baseline)', 'LineWidth', 2);
xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title(sprintf('Shifted by %.4f ft - Baseline at zero', shift_value));
grid on;

end
