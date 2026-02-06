%% Quick Silixa Concatenation Test - First 2 Minutes Only
% Plots raw 100 Hz data (no decimation) but only first 2 minutes
% to avoid crashing - checks for banding artifacts

clear all;
close all;
clc;

fprintf('=== QUICK SILIXA CONCATENATION TEST (2 minutes) ===\n\n');

%% Load the already concatenated data
fprintf('Loading concatenated data...\n');
load('C:\Coding\BGWRP\_TEST\silixa_concat_test.mat', 'full_data');
fprintf('  Full data size: [%d x %d]\n', size(full_data, 1), size(full_data, 2));

%% Take first 2 minutes only (12,000 samples at 100 Hz)
samples_to_plot = 12000;  % 120 seconds at 100 Hz
if size(full_data, 1) > samples_to_plot
    plot_data = full_data(1:samples_to_plot, :);
else
    plot_data = full_data;
end

fprintf('  Plotting first %d samples (%.1f seconds)\n', size(plot_data, 1), size(plot_data, 1)/100);

%% Apply 50-second smoothing (same as toolkit)
fprintf('Applying 50-second moving average to reduce noise...\n');
window_size = 50 * 100;  % 50 seconds at 100 Hz = 5000 samples
smoothed_data = movmean(plot_data, window_size, 1, 'omitnan');
fprintf('  Smoothed data range: %.2f to %.2f nm/s\n', min(smoothed_data(:)), max(smoothed_data(:)));

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
fprintf('Creating waterfall plot...\n');
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

fprintf('  Data range: %.2f to %.2f nm/s\n', min(plot_data(:)), max(plot_data(:)));

%% Save figure
fprintf('Saving figure...\n');
saveas(gcf, 'C:\Coding\BGWRP\_TEST\silixa_concat_quick.png');
fprintf('  ✓ Saved to: C:\\Coding\\BGWRP\\_TEST\\silixa_concat_quick.png\n');

fprintf('\n=== COMPLETE ===\n');
fprintf('Examine the plot for horizontal/vertical banding artifacts\n');
