% Compare pressure vs depth for pumping well

csv_file = 'E:/Transducer Data 10_24_2023/Prepped/PT-01a/PT-01a_SDT_PT-01a_2023-11-07_08-00-00.csv';

opts = detectImportOptions(csv_file);
opts.DataLine = 30;
opts.VariableNamingRule = 'preserve';
data = readtable(csv_file, opts);

timestamps = datetime(data{:,1}, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
pressure_psi = data{:,2};
depth_ft = data{:,3};

% Convert pressure to ft (1 psi ≈ 2.31 ft of water)
pressure_ft = pressure_psi * 2.31;

fprintf('=== PRESSURE vs DEPTH COMPARISON ===\n');
fprintf('Pressure range: %.2f to %.2f psi (%.2f to %.2f ft)\n', ...
    min(pressure_psi), max(pressure_psi), min(pressure_ft), max(pressure_ft));
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('\nPressure total change: %.2f ft\n', max(pressure_ft) - min(pressure_ft));
fprintf('Depth total change: %.2f ft\n', max(depth_ft) - min(depth_ft));

figure('Position', [50, 50, 1400, 800]);

subplot(2,1,1);
plot(timestamps, pressure_ft, 'r-', 'LineWidth', 1.5);
ylabel('Pressure (ft of water)');
title('Pressure Sensor Reading');
grid on;

subplot(2,1,2);
plot(timestamps, depth_ft, 'b-', 'LineWidth', 1.5);
ylabel('Depth (ft)');
xlabel('DateTime');
title('Depth Sensor Reading');
grid on;

fprintf('\n⚠ Which one has values matching your reference (~24 ft max)?\n');
