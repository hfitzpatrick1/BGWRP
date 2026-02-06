%% Test Silixa Concatenation Method with Existing Plotting
% This script uses the simple Silixa concatenation approach
% but uses existing BGWRP plotting functions to visualize results
%
% Does NOT modify any core code - standalone test only

clear all;
close all;
clc;

fprintf('=== TESTING SILIXA CONCATENATION METHOD ===\n\n');

%% Configuration
% Input: Individual MAT files (after TDMS conversion, before concatenation)
input_directory = 'C:\Coding\BGWRP\data\_BATCH\_tdms_to_mat\PT01a_Recovery_short\_das';
output_directory = 'C:\Coding\BGWRP\_TEST';
output_filename = 'silixa_concat_test';

% PT01a calibration parameters
C1 = 513;
MperChan = 0.250;

%% Step 1: Simple Silixa-style Concatenation
fprintf('STEP 1: Concatenating with Silixa method...\n');
files = dir(fullfile(input_directory, '*.mat'));
lf = length(files);

if lf == 0
    error('No MAT files found in: %s', input_directory);
end

fprintf('  Found %d MAT files\n', lf);

% Initialize arrays
full_data = [];
f_ind = 1:lf;
cnt = 0;

for nn = f_ind
    cnt = cnt + 1;
    if mod(cnt, 5) == 1 || cnt == lf
        fprintf('  Processing File %i of %i\n', cnt, length(f_ind));
    end
    
    % Load and Concatenate Data (Silixa method)
    filename = files(nn).name;
    file_path = fullfile(input_directory, filename);
    load(file_path, 'data')      
    full_data = vertcat(full_data, data);  
end

fprintf('  ✓ Concatenation complete: [%d x %d]\n', size(full_data, 1), size(full_data, 2));

%% Step 2: Save with -v7.3 format (Silixa method)
fprintf('\nSTEP 2: Saving with -v7.3 format...\n');
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end
save(fullfile(output_directory, output_filename), 'full_data', '-v7.3');
fprintf('  ✓ Saved: %s.mat\n', fullfile(output_directory, output_filename));

%% Step 3: Create visualization using existing toolkit approach
fprintf('\nSTEP 3: Visualizing results...\n');

% Calculate depth array (PT01a calibration)
channels = 1:size(full_data, 2);
depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
depth_m = depth_ft * 0.3048;

% Create time array (assuming 1 Hz)
fs = 1;  % 1 Hz
n_samples = size(full_data, 1);
time_seconds = (0:n_samples-1) / fs;
% Use a reference time (Nov 7, 2023, 20:35:10 UTC)
reference_time = datetime('2023-11-07 20:35:10', 'TimeZone', 'UTC');
time_array = reference_time + seconds(time_seconds);

fprintf('  Data: [%d samples x %d channels]\n', n_samples, size(full_data, 2));
fprintf('  Time range: %s to %s\n', datestr(time_array(1)), datestr(time_array(end)));
fprintf('  Depth range: %.1f to %.1f ft\n', min(depth_ft), max(depth_ft));
fprintf('  Data range: %.2f to %.2f nm/s\n', min(full_data(:)), max(full_data(:)));

%% Step 4: Simple waterfall plot (no filtering - RAW visualization)
fprintf('\nSTEP 4: Creating waterfall plot (raw, no filtering)...\n');

figure('Position', [100, 100, 1200, 800]);

% Plot full data
pcolor(time_array, depth_m, full_data');
shading interp;
colormap(jet);
colorbar;
clim([min(full_data(:)), max(full_data(:))]);

xlabel('Time (UTC)');
ylabel('Depth (m)');
title('Silixa Concatenation Test - RAW Data (No Filtering)');
datetick('x', 'HH:MM:SS', 'keeplimits');

% Limit depth display to reasonable range
ylim([50, 200]);

fprintf('  ✓ Figure created\n');

% Save the figure
fprintf('  Saving figure...\n');
saveas(gcf, fullfile(output_directory, 'silixa_concat_waterfall.png'));
saveas(gcf, fullfile(output_directory, 'silixa_concat_waterfall.fig'));
fprintf('  ✓ Figure saved to: %s\n', output_directory);

%% Summary
fprintf('\n=== TEST COMPLETE ===\n');
fprintf('Results:\n');
fprintf('  - Concatenated file: %s.mat\n', fullfile(output_directory, output_filename));
fprintf('  - Method: Simple vertcat() with -v7.3 save (Silixa method)\n');
fprintf('  - Visualization: Raw data, no filtering applied\n');
fprintf('  - Compare this plot to your existing plots to see if concatenation method matters\n');
fprintf('\nNext steps:\n');
fprintf('  1. Examine the waterfall plot for banding artifacts\n');
fprintf('  2. Compare with plots from your current pipeline\n');
fprintf('  3. If banding is similar, concatenation is not the issue\n');
fprintf('  4. If banding differs, concatenation method may be contributing\n');
