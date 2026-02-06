function analyze_grid_pattern(dataset_name, data_source)
%ANALYZE_GRID_PATTERN Analyze the regular grid pattern in DAS data
%
% Usage: 
%   analyze_grid_pattern('PT01c_Recovery_short', 'concatenated')  % 1Hz processed data
%   analyze_grid_pattern('PT01c_Recovery_short', 'raw')          % Raw TDMS data  
%   analyze_grid_pattern('PT01c_Recovery_short', 'tdms_to_mat')  % 100Hz MAT data
%
% Inputs:
%   dataset_name - Name of dataset to analyze
%   data_source  - 'concatenated', 'raw', 'tdms_to_mat' (default: 'concatenated')

if nargin < 1
    dataset_name = 'PT01c_Recovery_short';
end
if nargin < 2
    data_source = 'concatenated';
end

console_log('=== GRID PATTERN ANALYSIS ===\n');
console_log('Dataset: %s\n', dataset_name);
console_log('Data source: %s\n', data_source);

%% Load data based on source type
switch lower(data_source)
    case 'concatenated'
        [data, info] = load_concatenated_data(dataset_name);
        
    case 'raw'
        [data, info] = load_raw_tdms_data(dataset_name);
        console_log('*** ANALYZING TRULY RAW ADC VALUES (no scaling applied) ***\n');
        
    case 'tdms_to_mat'
        [data, info] = load_tdms_to_mat_data(dataset_name);
        
    otherwise
        error('Unknown data source: %s. Use: concatenated, raw, tdms_to_mat', data_source);
end

console_log('Data size: [%d x %d] (time x channels)\n', size(data));
console_log('Sampling rate: %d Hz\n', info.sampling_rate);
if isfield(info, 'note')
    console_log('Note: %s\n', info.note);
end

%% Analyze grid pattern in a sample region
% Take middle section of data for analysis
t_mid = round(size(data, 1) / 2);
c_mid = round(size(data, 2) / 2);

% Extract a 100x100 sample region
t_start = max(1, t_mid - 50);
t_end = min(size(data, 1), t_mid + 49);
c_start = max(1, c_mid - 50);
c_end = min(size(data, 2), c_mid + 49);

sample_data = data(t_start:t_end, c_start:c_end);
console_log('Sample region: time %d:%d, channels %d:%d\n', t_start, t_end, c_start, c_end);

%% Analyze horizontal (temporal) patterns
console_log('\n=== TEMPORAL PATTERN ANALYSIS ===\n');
% Take mean across channels to see temporal patterns
temporal_profile = mean(sample_data, 2);
temporal_diff = diff(temporal_profile);

% Look for periodic patterns
[temporal_fft, f_temporal] = analyze_periodicity(temporal_profile, 1, 'Temporal');

%% Analyze vertical (spatial) patterns  
console_log('\n=== SPATIAL PATTERN ANALYSIS ===\n');
% Take mean across time to see spatial patterns
spatial_profile = mean(sample_data, 1);
spatial_diff = diff(spatial_profile);

% Look for periodic patterns (assume 0.25m channel spacing)
[spatial_fft, f_spatial] = analyze_periodicity(spatial_profile', 0.25, 'Spatial');

%% Create visualization
figure('Name', sprintf('Grid Pattern Analysis - %s', dataset_name));

subplot(2,3,1);
imagesc(sample_data');
title('Sample Data Region');
xlabel('Time (samples)');
ylabel('Channel');
colorbar;

subplot(2,3,2);
plot(temporal_profile);
title('Temporal Profile (avg across channels)');
xlabel('Time (samples)');
ylabel('Amplitude');
grid on;

subplot(2,3,3);
plot(spatial_profile);
title('Spatial Profile (avg across time)');
xlabel('Channel');
ylabel('Amplitude');
grid on;

subplot(2,3,4);
plot(temporal_diff);
title('Temporal Gradient');
xlabel('Time (samples)');
ylabel('Gradient');
grid on;

subplot(2,3,5);
plot(spatial_diff);
title('Spatial Gradient');
xlabel('Channel');
ylabel('Gradient');
grid on;

subplot(2,3,6);
% Plot both FFTs
yyaxis left;
semilogy(f_temporal, abs(temporal_fft));
ylabel('Temporal FFT Magnitude');
xlabel('Frequency');
yyaxis right;
semilogy(f_spatial, abs(spatial_fft));
ylabel('Spatial FFT Magnitude');
title('Frequency Analysis');
legend('Temporal', 'Spatial');
grid on;

console_log('\n=== ANALYSIS COMPLETE ===\n');

end

%% Helper functions for loading different data sources

function [data, info] = load_concatenated_data(dataset_name)
%LOAD_CONCATENATED_DATA Load 1Hz processed data from _concatenated directory

base_path = 'C:\Coding\BGWRP\data\_BATCH\';
data_file = fullfile(base_path, '_concatenated', dataset_name, sprintf('Dataset_%s_1Hz.mat', dataset_name));

if ~exist(data_file, 'file')
    error('Concatenated data file not found: %s', data_file);
end

console_log('Loading concatenated: %s\n', data_file);
loaded = load(data_file);

if isfield(loaded, 'decdata')
    data = loaded.decdata;
    info.sampling_rate = 1;  % 1Hz
    info.file_path = data_file;
else
    error('No decdata field found in concatenated file');
end
end

function [data, info] = load_raw_tdms_data(dataset_name)
%LOAD_RAW_TDMS_DATA Load raw TDMS data from input directory

% Use hardcoded base path for now - could be improved with discovery system
base_path = 'C:\Coding\BGWRP\data\_BATCH\';
tdms_dir = fullfile(base_path, '_raw', dataset_name, '_das');

if ~exist(tdms_dir, 'dir')
    error('Raw TDMS directory not found: %s', tdms_dir);
end

% Get first TDMS file as sample
tdms_files = dir(fullfile(tdms_dir, '*.tdms'));
if isempty(tdms_files)
    error('No TDMS files found in: %s', tdms_dir);
end

% Load first file as sample (analyzing all would be too much)
sample_file = fullfile(tdms_dir, tdms_files(1).name);
console_log('Loading raw TDMS sample: %s\n', sample_file);

% Use EXACT same approach as Silixa_TDMSDataToPhysicalDispRate.m
try
    % Load file info exactly like the pipeline
    [~, fileinfo] = TDMS_Adv_Read(sample_file);
    n_ch = fileinfo.n_ch;
    n_samp = fileinfo.ChannelLength;
    
    console_log('TDMS file: %d channels, %d samples\n', n_ch, n_samp);
    
    % Load subset for analysis (first 1000 samples, first 100 channels)
    max_samples = min(1000, n_samp);
    max_channels = min(100, n_ch);
    
    arg.ch_start = 1;
    arg.ch_stop = max_channels;
    arg.t_start = 1;
    arg.t_stop = max_samples;
    
    % Load data exactly like pipeline
    arg.loading = 'data';
    data = TDMS_Adv_Read(sample_file, arg);
    
    % MODIFIED: Keep truly raw ADC values - NO SCALING
    console_log('Loaded RAW ADC values: [%d x %d]\n', size(data));
    console_log('Raw ADC range: [%.0f, %.0f] counts\n', min(data(:)), max(data(:)));
    console_log('Raw ADC data type: %s\n', class(data));
    
    info.sampling_rate = 100;  % 100Hz
    info.file_path = sample_file;
    info.note = sprintf('RAW ADC: %d samples x %d channels from file 1 of %d (NO SCALING APPLIED)', size(data,1), size(data,2), length(tdms_files));
    
catch ME
    error('Failed to load TDMS file: %s', ME.message);
end
end

function [data, info] = load_tdms_to_mat_data(dataset_name)
%LOAD_TDMS_TO_MAT_DATA Load 100Hz MAT data from _tdms_to_mat directory

base_path = 'C:\Coding\BGWRP\data\_BATCH\';
mat_dir = fullfile(base_path, '_tdms_to_mat', dataset_name, '_das');

if ~exist(mat_dir, 'dir')
    error('TDMS-to-MAT directory not found: %s', mat_dir);
end

% Get first MAT file as sample  
mat_files = dir(fullfile(mat_dir, '*.mat'));
if isempty(mat_files)
    error('No MAT files found in: %s', mat_dir);
end

sample_file = fullfile(mat_dir, mat_files(1).name);
console_log('Loading 100Hz MAT sample: %s\n', sample_file);

loaded = load(sample_file);
if isfield(loaded, 'data')
    data = loaded.data;
    info.sampling_rate = 100;  % 100Hz
    info.file_path = sample_file;
    info.note = sprintf('Sample file 1 of %d MAT files', length(mat_files));
else
    error('No data field found in MAT file');
end
end

function [fft_result, frequencies] = analyze_periodicity(signal, sampling_interval, label)
%ANALYZE_PERIODICITY Look for periodic patterns in the signal

N = length(signal);
fft_result = fft(signal);
frequencies = (0:N-1) / (N * sampling_interval);

% Find dominant frequencies
[~, peak_indices] = findpeaks(abs(fft_result(1:floor(N/2))), 'MinPeakHeight', 0.1*max(abs(fft_result)));

if ~isempty(peak_indices)
    console_log('%s dominant frequencies:\n', label);
    for i = 1:min(5, length(peak_indices))
        freq = frequencies(peak_indices(i));
        period = 1/freq;
        console_log('  %.4f Hz (period: %.2f %s)\n', freq, period, label);
    end
else
    console_log('%s: No dominant periodic patterns found\n', label);
end

end
