%% Quick Silixa Concatenation Test - First 2 Minutes Only
% Plots raw 100 Hz data (no decimation) but only first 2 minutes
% to avoid crashing - checks for banding artifacts

clear all;
close all;
clc;

console_log('=== QUICK SILIXA CONCATENATION TEST (2 minutes) ===\n\n');

%% Load the already concatenated data
console_log('Loading concatenated data...\n');
load('C:\Coding\BGWRP\_TEST\silixa_concat_test.mat', 'full_data');
console_log('  Full data size: [%d x %d]\n', size(full_data, 1), size(full_data, 2));

%% Take first 2 minutes only (12,000 samples at 100 Hz)
samples_to_plot = 12000;  % 120 seconds at 100 Hz
if size(full_data, 1) > samples_to_plot
    plot_data = full_data(1:samples_to_plot, :);
else
    plot_data = full_data;
end

console_log('  Plotting first %d samples (%.1f seconds)\n', size(plot_data, 1), size(plot_data, 1)/100);

%% Apply 50-second smoothing (same as toolkit)
console_log('Applying 50-second moving average to reduce noise...\n');
window_size = 50 * 100;  % 50 seconds at 100 Hz = 5000 samples
smoothed_data = movmean(plot_data, window_size, 1, 'omitnan');
console_log('  Smoothed data range: %.2f to %.2f nm/s\n', min(smoothed_data(:)), max(smoothed_data(:)));

%% PT01a calibration
C1 = 513;
MperChan = 0.250;
channels = 1:size(plot_data, 2);
depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
depth_m = depth_ft * 0.3048;

%% Create time array
fs = 100;  % 100 Hz
time_seconds = (0:size(plot_data,1)-1) / fs;
reference_time = datetime('2023-11-07 20:35:10', 'TimeZone', 'UTC');
time_array = reference_time + seconds(time_seconds);

%% Plot using imagesc (faster than pcolor)
console_log('Creating waterfall plot...\n');
figure('Position', [100, 100, 1200, 800]);

imagesc(time_array, depth_m, smoothed_data');
axis xy;  % Flip y-axis to normal orientation
colormap(jet);
colorbar;
clim([0, 0.2]);  % Match toolkit bounds to reveal banding

xlabel('Time (UTC)');
ylabel('Depth (m)');
title('Silixa Concatenation Test - 50s Smoothed (First 2 Minutes)');
datetick('x', 'HH:MM:SS', 'keeplimits');
ylim([50, 200]);

console_log('  Data range: %.2f to %.2f nm/s\n', min(plot_data(:)), max(plot_data(:)));

%% Save figure
console_log('Saving figure...\n');
saveas(gcf, 'C:\Coding\BGWRP\_TEST\silixa_concat_quick.png');
console_log('  ✓ Saved to: C:\\Coding\\BGWRP\\_TEST\\silixa_concat_quick.png\n');

console_log('\n=== COMPLETE ===\n');
console_log('Examine the plot for horizontal/vertical banding artifacts\n');
