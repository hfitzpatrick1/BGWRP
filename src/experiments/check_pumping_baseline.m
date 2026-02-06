% Check pumping well baseline calculation

csv_file = 'E:/Transducer Data 10_24_2023/Prepped/PT-01a/PT-01a_SDT_PT-01a_2023-11-07_08-00-00.csv';

% Read data
opts = detectImportOptions(csv_file);
opts.DataLine = 30;
opts.VariableNamingRule = 'preserve';
data = readtable(csv_file, opts);

timestamps = datetime(data{:,1}, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
depth_ft = data{:,3};

console_log('=== PUMPING WELL BASELINE CHECK ===\n');
console_log('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
console_log('Total depth change: %.2f ft\n', max(depth_ft) - min(depth_ft));
console_log('\nFirst 10 values (baseline):\n');
disp(depth_ft(1:10));
console_log('\nLast 10 values (max pumping):\n');
disp(depth_ft(end-9:end));

% Check if we should use min or max as baseline
baseline_min = min(depth_ft);
baseline_max = max(depth_ft);

console_log('\nIf baseline = %.2f ft (minimum):\n', baseline_min);
console_log('  Max drawdown = %.2f ft\n', baseline_max - baseline_min);

console_log('\nIf baseline = %.2f ft (maximum during pumping):\n', baseline_max);
console_log('  This would be NEGATIVE drawdown\n');

% Plot to visualize
figure;
plot(timestamps, depth_ft, 'b-', 'LineWidth', 1.5);
xlabel('DateTime');
ylabel('Depth (ft)');
title('Raw Pumping Well Depth - Which is baseline?');
grid on;
