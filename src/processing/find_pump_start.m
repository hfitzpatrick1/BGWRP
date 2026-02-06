% Find where pump actually starts in the DENOISED file
data = readtable('E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_DENOISED.csv');
time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

% Find first point where drawdown > 0.01 ft
pump_start_idx = find(drawdown_ft > 0.01, 1, 'first');
pump_start_time = time_sec(pump_start_idx);

console_log('=== PUMP START DETECTION ===\n');
console_log('Pump starts at: %.0f seconds (line %d)\n', pump_start_time, pump_start_idx);
console_log('Time range in file: %.0f to %.0f sec\n', min(time_sec), max(time_sec));
console_log('\n✓ Use this value: %.0f\n', pump_start_time);

% Plot to verify
figure('Position', [50, 50, 1400, 600]);
plot(time_sec, drawdown_ft, 'b-', 'LineWidth', 1.5);
hold on;
xline(pump_start_time, 'r--', 'Pump Start', 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');
xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title('Finding Pump Start Time');
grid on;
