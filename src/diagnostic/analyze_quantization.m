function analyze_quantization(dataset_name)
%ANALYZE_QUANTIZATION Analyze data quantization levels to identify pixelation source
%
% Usage: analyze_quantization('PT01c_Recovery_short')

if nargin < 1
    dataset_name = 'PT01c_Recovery_short';
end

console_log('=== QUANTIZATION ANALYSIS ===\n');
console_log('Dataset: %s\n', dataset_name);

%% Load processed data
base_path = 'C:\Coding\BGWRP\data\_BATCH\';

% Try _concatenated first (where 1Hz processed data lives)
data_file = fullfile(base_path, '_concatenated', dataset_name, sprintf('Dataset_%s_1Hz.mat', dataset_name));

if ~exist(data_file, 'file')
    % Fallback: try _active directory
    data_file = fullfile(base_path, '_active', dataset_name, '_das', sprintf('Dataset_%s_1Hz.mat', dataset_name));
    
    if ~exist(data_file, 'file')
        error('Data file not found in either _concatenated or _active: %s', dataset_name);
    end
end

console_log('Loading: %s\n', data_file);
loaded = load(data_file);

if isfield(loaded, 'decdata')
    data = loaded.decdata;
else
    error('No decdata field found in file');
end

console_log('Data size: [%d x %d]\n', size(data));
console_log('Data range: [%.6f, %.6f]\n', min(data(:)), max(data(:)));
console_log('Data type: %s\n', class(data));

%% Analyze a sample channel (middle of array)
mid_channel = round(size(data, 2) / 2);
channel_data = data(:, mid_channel);

console_log('\n=== CHANNEL %d ANALYSIS ===\n', mid_channel);
console_log('Channel range: [%.6f, %.6f]\n', min(channel_data), max(channel_data));

%% Look for quantization steps
unique_vals = unique(channel_data);
console_log('Unique values: %d out of %d samples (%.1f%% unique)\n', ...
    length(unique_vals), length(channel_data), ...
    100 * length(unique_vals) / length(channel_data));

if length(unique_vals) < length(channel_data) * 0.8
    console_log('⚠ LOW UNIQUENESS - Quantization likely present\n');
    
    % Calculate step sizes
    step_sizes = diff(sort(unique_vals));
    step_sizes = step_sizes(step_sizes > 1e-10); % Remove floating point noise
    
    if ~isempty(step_sizes)
        min_step = min(step_sizes);
        mode_step = mode(round(step_sizes / min_step)) * min_step;
        
        console_log('Minimum step size: %.8f nm/sample\n', min_step);
        console_log('Modal step size: %.8f nm/sample\n', mode_step);
        
        % Check if this matches expected ADC quantization
        expected_step = 116/8192;
        console_log('Expected ADC step: %.8f nm/sample\n', expected_step);
        
        if abs(mode_step - expected_step) / expected_step < 0.01
            console_log('✓ MATCHES ADC quantization (116/8192)\n');
        else
            console_log('✗ Does not match expected ADC quantization\n');
        end
    end
else
    console_log('✓ High uniqueness - No obvious quantization\n');
end

%% Create histogram
figure('Name', sprintf('Quantization Analysis - %s', dataset_name));

subplot(2,1,1);
histogram(channel_data, 100);
title(sprintf('Data Distribution - Channel %d', mid_channel));
xlabel('Value (nm/sample)');
ylabel('Count');
grid on;

subplot(2,1,2);
plot(channel_data);
title(sprintf('Time Series - Channel %d', mid_channel));
xlabel('Sample');
ylabel('Value (nm/sample)');
grid on;

%% Check multiple channels for consistency
console_log('\n=== MULTI-CHANNEL ANALYSIS ===\n');
sample_channels = round(linspace(1, size(data, 2), 5));

for i = 1:length(sample_channels)
    ch = sample_channels(i);
    ch_data = data(:, ch);
    unique_count = length(unique(ch_data));
    uniqueness = 100 * unique_count / length(ch_data);
    
    console_log('Channel %4d: %4d unique values (%.1f%% unique)\n', ...
        ch, unique_count, uniqueness);
end

console_log('\n=== ANALYSIS COMPLETE ===\n');

end
