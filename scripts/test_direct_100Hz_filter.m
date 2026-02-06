%% Direct 100 Hz Data Analysis - Bypass Discovery Logic
% This script directly loads your 100 Hz data file and applies anti-aliasing

clear all;
close all;
clc;

console_log('=== DIRECT 100 Hz DATA ANALYSIS ===\n\n');

%% Step 1: Load the data file directly
data_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_100\Dataset_PT01a_Recovery_100.mat';

console_log('Loading data file directly: %s\n', data_file);
loaded = load(data_file);

% Show what variables are in the file
console_log('Variables in file:\n');
disp(fieldnames(loaded));

% Extract the data
raw_data = loaded.fulldata;

console_log('Data size: [%d time points x %d channels]\n', size(raw_data, 1), size(raw_data, 2));
console_log('Data range: [%.3e, %.3e]\n', min(raw_data(:)), max(raw_data(:)));

%% Step 2: Apply anti-aliasing filter
console_log('\nApplying anti-aliasing filter (cutoff 0.5 Hz)...\n');

addpath(genpath('C:\Coding\BGWRP\src'));

% Configure filter
config = struct();
config.decimation_factor = 100;  % Simulate 100x decimation filter

% Apply filter
filtered_data = resample_antialias_filter(raw_data, config);

console_log('Filtered data range: [%.3e, %.3e]\n', min(filtered_data(:)), max(filtered_data(:)));

%% Step 3: Show results
console_log('\n=== FILTER RESULTS ===\n');
console_log('Original data std: %.3e\n', std(raw_data(:), 'omitnan'));
console_log('Filtered data std: %.3e\n', std(filtered_data(:), 'omitnan'));
console_log('Noise reduction: %.1f%%\n', (1 - std(filtered_data(:))/std(raw_data(:))) * 100);

console_log('\n✓ Anti-aliasing filter applied successfully!\n');
console_log('Next: Integrate this into full analysis pipeline\n');
