% Quick plot of pumping well data

csv_file = 'E:/Transducer Data 10_24_2023/Prepped/PT-01a/PT-01a_SDT_PT-01a_2023-11-07_08-00-00.csv';

% Read data
opts = detectImportOptions(csv_file);
opts.DataLine = 30;
opts.VariableNamingRule = 'preserve';
data = readtable(csv_file, opts);

% Extract
timestamps = datetime(data{:,1}, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
depth_ft = data{:,3};

% Plot
figure('Position', [50, 50, 1400, 600]);
plot(timestamps, depth_ft, 'b-', 'LineWidth', 1.5);
xlabel('DateTime');
ylabel('Depth to Water (ft)');
title('Pumping Well PT-01a - Depth vs Time');
grid on;

console_log('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
console_log('Total change: %.2f ft\n', max(depth_ft) - min(depth_ft));
