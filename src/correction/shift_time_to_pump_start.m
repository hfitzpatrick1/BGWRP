function shift_time_to_pump_start(input_csv, output_csv, pump_start_elapsed)
%SHIFT_TIME_TO_PUMP_START Reset time so pump start = 0
%
% Usage: shift_time_to_pump_start(input_csv, output_csv, 31500)

console_log('=== SHIFTING TIME TO PUMP START ===\n');

%% Load data
data = readtable(input_csv);

% Check if there's a Weight column
if ismember('Weight', data.Properties.VariableNames)
    has_weights = true;
    weights = data.Weight;
else
    has_weights = false;
end

time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

%% Shift time
time_adjusted = time_sec - pump_start_elapsed;

console_log('Original time range: %.1f to %.1f sec\n', min(time_sec), max(time_sec));
console_log('Adjusted time range: %.1f to %.1f sec\n', min(time_adjusted), max(time_adjusted));

%% Only keep data from pump start onward (positive times)
mask = time_adjusted >= 0;
time_final = time_adjusted(mask);
drawdown_final = drawdown_ft(mask);

if has_weights
    weights_final = weights(mask);
end

console_log('Kept %d points (removed %d baseline points)\n', sum(mask), sum(~mask));

%% Export
if has_weights
    export_table = table(time_final, drawdown_final, weights_final, ...
        'VariableNames', {'Time_sec', 'Drawdown_ft', 'Weight'});
else
    export_table = table(time_final, drawdown_final, ...
        'VariableNames', {'Time_sec', 'Drawdown_ft'});
end

writetable(export_table, output_csv);

console_log('\n✓ Exported to: %s\n', output_csv);
console_log('✓ Time now starts at pump start (t=0)\n');

%% Plot
figure('Position', [50, 50, 1400, 600]);
plot(time_final, drawdown_final, 'b-', 'LineWidth', 2);
xlabel('Time since pump start (seconds)');
ylabel('Drawdown (ft)');
title('Time-adjusted for AQTESOLV (t=0 at pump start)');
grid on;
xline(0, 'r--', 'Pump ON', 'LineWidth', 2);

end
