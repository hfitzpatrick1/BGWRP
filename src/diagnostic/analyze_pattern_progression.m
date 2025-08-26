function analyze_pattern_progression(dataset_name)
%ANALYZE_PATTERN_PROGRESSION Quantify grid pattern strength across pipeline stages
%
% Usage: analyze_pattern_progression('PT01c_Recovery_short')
%
% Traces pattern strength through: raw TDMS -> TDMS-to-MAT -> concatenated
% Provides quantitative metrics to see if artifacts increase during processing

if nargin < 1
    dataset_name = 'PT01c_Recovery_short';
end

fprintf('=== PATTERN PROGRESSION ANALYSIS ===\n');
fprintf('Dataset: %s\n', dataset_name);
fprintf('Tracing pattern strength through pipeline stages...\n\n');

% Storage for results
results = struct();
stages = {'raw', 'tdms_to_mat', 'concatenated'};

%% Analyze each pipeline stage
for i = 1:length(stages)
    stage = stages{i};
    fprintf('--- STAGE %d: %s ---\n', i, upper(stage));
    
    try
        % Load data for this stage
        [data, info] = load_stage_data(dataset_name, stage);
        
        % Calculate pattern metrics
        metrics = calculate_pattern_metrics(data, info, stage);
        
        % Store results
        results.(stage) = metrics;
        
        % Display summary
        display_stage_summary(stage, metrics);
        
    catch ME
        fprintf('✗ Failed to analyze stage %s: %s\n', stage, ME.message);
        results.(stage) = struct('error', ME.message);
    end
    
    fprintf('\n');
end

%% Compare across stages
fprintf('=== PATTERN PROGRESSION SUMMARY ===\n');
compare_pattern_progression(results);

%% Create visualization
create_progression_plots(results, dataset_name);

end

function [data, info] = load_stage_data(dataset_name, stage)
%LOAD_STAGE_DATA Load data from specific pipeline stage

base_path = 'C:\Coding\BGWRP\data\_BATCH\';

switch lower(stage)
    case 'raw'
        % Load raw TDMS (modified to keep truly raw)
        tdms_dir = fullfile(base_path, '_raw', dataset_name, '_das');
        if ~exist(tdms_dir, 'dir')
            error('Raw TDMS directory not found: %s', tdms_dir);
        end
        
        tdms_files = dir(fullfile(tdms_dir, '*.tdms'));
        if isempty(tdms_files)
            error('No TDMS files found');
        end
        
        % Load first file (sample)
        sample_file = fullfile(tdms_dir, tdms_files(1).name);
        fprintf('Loading: %s\n', sample_file);
        
        [~, fileinfo] = TDMS_Adv_Read(sample_file);
        max_samples = min(1000, fileinfo.ChannelLength);
        max_channels = min(200, fileinfo.n_ch);
        
        arg.ch_start = 1;
        arg.ch_stop = max_channels;
        arg.t_start = 1;
        arg.t_stop = max_samples;
        arg.loading = 'data';
        
        data = TDMS_Adv_Read(sample_file, arg);
        % KEEP TRULY RAW - NO SCALING
        
        info.sampling_rate = 100;
        info.note = sprintf('Raw ADC: %d x %d from %s', size(data,1), size(data,2), tdms_files(1).name);
        
    case 'tdms_to_mat'
        % Load 100Hz MAT data (with scaling applied)
        mat_dir = fullfile(base_path, '_tdms_to_mat', dataset_name, '_das');
        if ~exist(mat_dir, 'dir')
            error('TDMS-to-MAT directory not found: %s', mat_dir);
        end
        
        mat_files = dir(fullfile(mat_dir, '*.mat'));
        if isempty(mat_files)
            error('No MAT files found');
        end
        
        sample_file = fullfile(mat_dir, mat_files(1).name);
        fprintf('Loading: %s\n', sample_file);
        
        loaded = load(sample_file);
        if isfield(loaded, 'data')
            data = loaded.data;
            info.sampling_rate = 100;
            info.note = sprintf('Scaled 100Hz: %d x %d from %s', size(data,1), size(data,2), mat_files(1).name);
        else
            error('No data field found in MAT file');
        end
        
    case 'concatenated'
        % Load 1Hz processed data
        data_file = fullfile(base_path, '_concatenated', dataset_name, sprintf('Dataset_%s_1Hz.mat', dataset_name));
        if ~exist(data_file, 'file')
            error('Concatenated data file not found: %s', data_file);
        end
        
        fprintf('Loading: %s\n', data_file);
        loaded = load(data_file);
        
        if isfield(loaded, 'decdata')
            data = loaded.decdata;
            info.sampling_rate = 1;
            info.note = sprintf('Decimated 1Hz: %d x %d', size(data,1), size(data,2));
        else
            error('No decdata field found');
        end
        
    otherwise
        error('Unknown stage: %s', stage);
end

fprintf('Data size: [%d x %d], Range: [%.3f, %.3f]\n', ...
    size(data,1), size(data,2), min(data(:)), max(data(:)));

end

function metrics = calculate_pattern_metrics(data, info, stage)
%CALCULATE_PATTERN_METRICS Quantify pattern strength and characteristics

metrics = struct();
metrics.stage = stage;
metrics.data_size = size(data);
metrics.sampling_rate = info.sampling_rate;
metrics.data_range = [min(data(:)), max(data(:))];

% Take middle region for analysis
t_mid = round(size(data, 1) / 2);
c_mid = round(size(data, 2) / 2);

% Sample region size based on data size
sample_t = min(100, floor(size(data, 1) / 2));
sample_c = min(50, floor(size(data, 2) / 2));

t_start = max(1, t_mid - sample_t);
t_end = min(size(data, 1), t_mid + sample_t - 1);
c_start = max(1, c_mid - sample_c);
c_end = min(size(data, 2), c_mid + sample_c - 1);

sample_data = data(t_start:t_end, c_start:c_end);
metrics.sample_region = [t_start, t_end, c_start, c_end];

%% Temporal Pattern Analysis
temporal_profile = mean(sample_data, 2);
temporal_fft = fft(temporal_profile);
N_t = length(temporal_profile);
freq_temporal = (0:N_t-1) / (N_t / info.sampling_rate);

% Find dominant temporal frequencies
[pks_t, locs_t] = findpeaks(abs(temporal_fft(1:floor(N_t/2))), ...
    'MinPeakHeight', 0.1*max(abs(temporal_fft)), 'SortStr', 'descend');

if length(pks_t) >= 3
    % Top 3 dominant frequencies
    metrics.temporal_freqs = freq_temporal(locs_t(1:3));
    metrics.temporal_powers = pks_t(1:3);
    metrics.temporal_strength = sum(pks_t(1:3)) / sum(abs(temporal_fft));
else
    metrics.temporal_freqs = [];
    metrics.temporal_powers = [];
    metrics.temporal_strength = 0;
end

%% Spatial Pattern Analysis  
spatial_profile = mean(sample_data, 1);
spatial_fft = fft(spatial_profile);
N_s = length(spatial_profile);
freq_spatial = (0:N_s-1) / N_s; % Normalized spatial frequency

[pks_s, locs_s] = findpeaks(abs(spatial_fft(1:floor(N_s/2))), ...
    'MinPeakHeight', 0.1*max(abs(spatial_fft)), 'SortStr', 'descend');

if length(pks_s) >= 3
    metrics.spatial_freqs = freq_spatial(locs_s(1:3));
    metrics.spatial_powers = pks_s(1:3);
    metrics.spatial_strength = sum(pks_s(1:3)) / sum(abs(spatial_fft));
else
    metrics.spatial_freqs = [];
    metrics.spatial_powers = [];
    metrics.spatial_strength = 0;
end

%% Pattern Coherence Metrics
% Measure how consistent patterns are across channels
channel_correlations = [];
for i = 1:min(10, size(sample_data, 2)-1)
    corr_val = corrcoef(sample_data(:, i), sample_data(:, i+1));
    channel_correlations(end+1) = corr_val(1,2);
end

metrics.channel_coherence = mean(channel_correlations);
metrics.pattern_regularity = std(temporal_profile) / mean(abs(temporal_profile));

%% Overall Pattern Strength Score
% Composite metric: higher = more prominent patterns
temporal_score = metrics.temporal_strength * 100;
spatial_score = metrics.spatial_strength * 100;
coherence_score = abs(metrics.channel_coherence) * 100;

metrics.overall_pattern_strength = temporal_score + spatial_score + coherence_score;

end

function display_stage_summary(stage, metrics)
%DISPLAY_STAGE_SUMMARY Show key metrics for this stage

fprintf('Data: [%d x %d] @ %d Hz\n', metrics.data_size(1), metrics.data_size(2), metrics.sampling_rate);
fprintf('Range: [%.3f, %.3f]\n', metrics.data_range(1), metrics.data_range(2));

if ~isempty(metrics.temporal_freqs)
    fprintf('Top temporal frequencies: ');
    for i = 1:length(metrics.temporal_freqs)
        period = 1/metrics.temporal_freqs(i);
        fprintf('%.3f Hz (%.1fs) ', metrics.temporal_freqs(i), period);
    end
    fprintf('\n');
    fprintf('Temporal strength: %.1f%%\n', metrics.temporal_strength * 100);
else
    fprintf('No significant temporal patterns\n');
end

if ~isempty(metrics.spatial_freqs)
    fprintf('Spatial strength: %.1f%%\n', metrics.spatial_strength * 100);
else
    fprintf('No significant spatial patterns\n');
end

fprintf('Channel coherence: %.3f\n', metrics.channel_coherence);
fprintf('Overall pattern strength: %.1f\n', metrics.overall_pattern_strength);

end

function compare_pattern_progression(results)
%COMPARE_PATTERN_PROGRESSION Show how patterns change across stages

stages = {'raw', 'tdms_to_mat', 'concatenated'};
valid_stages = {};
strengths = [];

fprintf('Stage Comparison:\n');
fprintf('%-15s %-15s %-15s %-15s\n', 'Stage', 'Overall Score', 'Temporal', 'Coherence');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:length(stages)
    stage = stages{i};
    if isfield(results, stage) && ~isfield(results.(stage), 'error')
        valid_stages{end+1} = stage;
        strengths(end+1) = results.(stage).overall_pattern_strength;
        
        fprintf('%-15s %-15.1f %-15.1f %-15.3f\n', ...
            upper(stage), ...
            results.(stage).overall_pattern_strength, ...
            results.(stage).temporal_strength * 100, ...
            results.(stage).channel_coherence);
    else
        fprintf('%-15s %-15s\n', upper(stage), 'ERROR');
    end
end

if length(strengths) > 1
    fprintf('\nPattern Progression:\n');
    for i = 2:length(strengths)
        change = strengths(i) - strengths(i-1);
        pct_change = (change / strengths(i-1)) * 100;
        
        if change > 0
            direction = '↑ INCREASE';
        elseif change < 0
            direction = '↓ DECREASE';  
        else
            direction = '→ NO CHANGE';
        end
        
        fprintf('%s → %s: %.1f %s (%.1f%%)\n', ...
            upper(valid_stages{i-1}), upper(valid_stages{i}), ...
            abs(change), direction, abs(pct_change));
    end
end

end

function create_progression_plots(results, dataset_name)
%CREATE_PROGRESSION_PLOTS Visualize pattern progression

figure('Name', sprintf('Pattern Progression - %s', dataset_name));

stages = {'raw', 'tdms_to_mat', 'concatenated'};
valid_stages = {};
strengths = [];
temporal_strengths = [];
coherences = [];

% Collect valid data
for i = 1:length(stages)
    stage = stages{i};
    if isfield(results, stage) && ~isfield(results.(stage), 'error')
        valid_stages{end+1} = stage;
        strengths(end+1) = results.(stage).overall_pattern_strength;
        temporal_strengths(end+1) = results.(stage).temporal_strength * 100;
        coherences(end+1) = abs(results.(stage).channel_coherence);
    end
end

if length(valid_stages) < 2
    fprintf('Insufficient valid stages for plotting\n');
    return;
end

% Plot progression
plot(1:length(valid_stages), strengths, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot(1:length(valid_stages), temporal_strengths, 's--', 'LineWidth', 1.5);
plot(1:length(valid_stages), coherences*100, '^:', 'LineWidth', 1.5);

xlabel('Pipeline Stage');
ylabel('Pattern Strength');
title(sprintf('Pattern Progression: %s', dataset_name));
legend({'Overall Score', 'Temporal Strength', 'Coherence x100'}, 'Location', 'best');
grid on;

% Set x-axis labels
set(gca, 'XTick', 1:length(valid_stages));
set(gca, 'XTickLabel', cellfun(@upper, valid_stages, 'UniformOutput', false));

end
