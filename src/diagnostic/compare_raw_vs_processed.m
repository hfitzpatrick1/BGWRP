function compare_raw_vs_processed(dataset_name)
% COMPARE_RAW_VS_PROCESSED - Definitive visual comparison of raw TDMS vs processed data
% This will definitively show if grid patterns are in raw TDMS or introduced by processing
%
% Usage: compare_raw_vs_processed('TEST')

if nargin < 1
    dataset_name = 'TEST';
end

console_log('=== DEFINITIVE RAW vs PROCESSED COMPARISON ===\n');
console_log('Dataset: %s\n', dataset_name);

% Get the current directory structure  
data_path = 'C:\Coding\BGWRP\data\_BATCH';

% Define file paths
tdms_file = fullfile(data_path, '_raw', dataset_name, '_das', 'PM07StepPT01c_UTC_20231024_191036.338.tdms');
mat_file = fullfile(data_path, '_tdms_to_mat', dataset_name, '_das', 'PM07StepPT01c_UTC_20231024_191036.338.mat');

% Check if files exist
if ~exist(tdms_file, 'file')
    error('Raw TDMS file not found: %s', tdms_file);
end
if ~exist(mat_file, 'file')
    error('Processed MAT file not found: %s', mat_file);
end

console_log('Loading raw TDMS: %s\n', tdms_file);

% Load raw TDMS data (truly raw ADC values)
arg.loading = 'data';
raw_data = TDMS_Adv_Read(tdms_file, arg);
console_log('Raw TDMS loaded: [%d x %d], Range: [%.3f, %.3f]\n', ...
    size(raw_data,1), size(raw_data,2), min(raw_data(:)), max(raw_data(:)));

console_log('Loading processed MAT: %s\n', mat_file);

% Load post-Silixa processed data
mat_contents = load(mat_file);
if isfield(mat_contents, 'data')
    processed_data = mat_contents.data;
elseif isfield(mat_contents, 'displacement_rate')
    processed_data = mat_contents.displacement_rate;
else
    fields = fieldnames(mat_contents);
    processed_data = mat_contents.(fields{1});
end

console_log('Processed MAT loaded: [%d x %d], Range: [%.3f, %.3f]\n', ...
    size(processed_data,1), size(processed_data,2), min(processed_data(:)), max(processed_data(:)));

% Create comparison plot
figure('Position', [100 100 1600 800]);

% Determine plot region (first 1000 samples, up to 200 channels)
max_samples = min(1000, min(size(raw_data,1), size(processed_data,1)));
max_channels = min(200, min(size(raw_data,2), size(processed_data,2)));

console_log('Plotting region: [%d x %d]\n', max_samples, max_channels);

% Plot 1: Raw TDMS (ADC values)
subplot(1,2,1);
raw_region = raw_data(1:max_samples, 1:max_channels);
imagesc(raw_region');
colorbar;
title(sprintf('RAW TDMS (ADC Values)\nRange: [%.1f, %.1f]', min(raw_region(:)), max(raw_region(:))));
xlabel('Time Samples');
ylabel('Channel');
set(gca, 'YDir', 'normal');

% Plot 2: Post-Silixa (Physical Units)
subplot(1,2,2);
processed_region = processed_data(1:max_samples, 1:max_channels);
imagesc(processed_region');
colorbar;
title(sprintf('POST-SILIXA (Physical Units)\nRange: [%.3f, %.3f]', min(processed_region(:)), max(processed_region(:))));
xlabel('Time Samples');
ylabel('Channel');
set(gca, 'YDir', 'normal');

% Add overall title
sgtitle(sprintf('DEFINITIVE COMPARISON: %s - Raw TDMS vs Post-Silixa Processing', dataset_name));

% Print analysis
console_log('\n=== VISUAL ANALYSIS GUIDE ===\n');
console_log('Look for:\n');
console_log('• Grid patterns/pixelation in either plot\n');
console_log('• Horizontal or vertical striping\n');
console_log('• Regular patterns that look artificial\n');
console_log('• Differences in texture between left and right plots\n');
console_log('\nIf grid patterns appear ONLY in the right plot → Processing artifacts\n');
console_log('If grid patterns appear in BOTH plots → Real sensor characteristics\n');

% Calculate basic pattern metrics for comparison
console_log('\n=== QUANTITATIVE COMPARISON ===\n');

% Simple pattern detection - look for regular variations
raw_std_time = std(raw_region, 0, 2);  % Std across channels for each time
processed_std_time = std(processed_region, 0, 2);

raw_pattern_strength = std(raw_std_time) / mean(raw_std_time) * 100;
processed_pattern_strength = std(processed_std_time) / mean(processed_std_time) * 100;

console_log('Raw TDMS pattern variability: %.2f%%\n', raw_pattern_strength);
console_log('Processed pattern variability: %.2f%%\n', processed_pattern_strength);
console_log('Pattern increase during processing: %.2f%%\n', processed_pattern_strength - raw_pattern_strength);

end
