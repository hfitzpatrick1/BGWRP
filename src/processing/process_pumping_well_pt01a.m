% Process pumping well PT-01a data for AQTESOLV

%% Load data
csv_file = 'E:/Transducer Data 10_24_2023/Prepped/PT-01a/PT-01a_SDT_PT-01a_2023-11-07_08-00-00.csv';

% Read with header skip
opts = detectImportOptions(csv_file);
opts.DataLine = 30;  % Data starts at line 30
opts.VariableNamingRule = 'preserve';  % Keep original names

data = readtable(csv_file, opts);

% Extract columns (access by column number)
timestamps = datetime(data{:,1}, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
pressure_psi = data{:,2};
depth_ft_sensor = data{:,3};  % Not used - use pressure instead!
temp_c = data{:,4};

% Convert pressure to feet of water (1 psi = 2.31 ft)
depth_ft = pressure_psi * 2.31;

console_log('=== PUMPING WELL PT-01a DATA ===\n');
console_log('Total points: %d\n', length(timestamps));
console_log('Time range: %s to %s\n', timestamps(1), timestamps(end));
console_log('Pressure range: %.2f to %.2f psi\n', min(pressure_psi), max(pressure_psi));
console_log('Depth (from pressure): %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));

%% Find pump start - use known time (8:45 AM)
% File starts at 08:00:00, pump starts at 08:45:00 = 45 minutes = 2700 seconds
file_start = timestamps(1);
pump_start_time = file_start + minutes(45);

% Find closest timestamp
[~, pump_start_idx] = min(abs(timestamps - pump_start_time));
pump_start_time = timestamps(pump_start_idx);

% Baseline is first 30 minutes (before pump starts)
baseline_mask = timestamps < (file_start + minutes(30));
baseline_depth = median(depth_ft(baseline_mask), 'omitnan');

console_log('\nFile starts: %s\n', file_start);
console_log('Pump starts: %s (index %d)\n', pump_start_time, pump_start_idx);
console_log('Baseline depth: %.2f ft\n', baseline_depth);
console_log('Max depth during pumping: %.2f ft\n', max(depth_ft));
console_log('Total depth change: %.2f ft\n', max(depth_ft) - baseline_depth);

%% Calculate elapsed time from pump start
elapsed_time_sec = seconds(timestamps - pump_start_time);

% Only keep data from pump start onward
mask = elapsed_time_sec >= 0;
time_final = elapsed_time_sec(mask);
depth_final = depth_ft(mask);
baseline_depth_final = baseline_depth;

% Calculate drawdown (positive = water level drop = pressure drop)
% Pressure DROPS during pumping, so drawdown = baseline - current
drawdown_ft = baseline_depth_final - depth_final;
console_log('Using PRESSURE data (converted to ft)\n');

% MINIMAL smoothing to preserve steps (5-point moving average only)
drawdown_ft = movmean(drawdown_ft, 5, 'omitnan');

console_log('\nKept %d points from pump start\n', sum(mask));
console_log('Drawdown range: %.2f to %.2f ft\n', min(drawdown_ft), max(drawdown_ft));
console_log('Applied minimal 5-point smoothing to preserve steps\n');

%% Export for AQTESOLV
output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PT01a_PUMPING_WELL_AQTESOLV.csv';

export_table = table(time_final, drawdown_ft, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_file);

console_log('\n✓ Exported to: %s\n', output_file);
console_log('✓ Ready for AQTESOLV as PUMPING WELL data!\n');

%% Plot
figure('Position', [50, 50, 1400, 800]);

subplot(2,1,1);
plot(timestamps, depth_ft, 'b-', 'LineWidth', 1);
hold on;
xline(pump_start_time, 'r--', 'Pump Start', 'LineWidth', 2);
xlabel('DateTime');
ylabel('Depth to Water (ft)');
title('Pumping Well PT-01a - Raw Data');
grid on;

subplot(2,1,2);
plot(time_final, drawdown_ft, 'b-', 'LineWidth', 1.5);
xlabel('Time since pump start (seconds)');
ylabel('Drawdown (ft)');
title('Pumping Well Drawdown (for AQTESOLV)');
grid on;

% Mark pump rate changes
hold on;
pump_changes = [0, 3600, 7200, 10800, 14400];
rates = [50, 80, 110, 150, 0];
for i = 1:length(pump_changes)
    if pump_changes(i) <= max(time_final)
        xline(pump_changes(i), 'g--', sprintf('%d GPM', rates(i)), 'LineWidth', 1.5);
    end
end

console_log('\n=== NEXT STEPS ===\n');
console_log('1. Import PT01a_PUMPING_WELL_AQTESOLV.csv as PUMPING WELL\n');
console_log('2. Import PM7_Zone2_FINAL_AQTESOLV.csv as OBSERVATION WELL\n');
console_log('3. Use Pump_Schedule_AQTESOLV.csv for pump schedule\n');
console_log('4. AQTESOLV will use both wells to estimate parameters!\n');
