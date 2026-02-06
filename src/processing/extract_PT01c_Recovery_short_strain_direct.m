function extract_PT01c_Recovery_short_strain_direct()
%EXTRACT_PT01C_RECOVERY_SHORT_STRAIN_DIRECT Extract strain matrix directly from data files
%
% This function loads the PT01c_Recovery_short data directly and extracts
% the strain matrix without needing das_results in workspace

fprintf('=== EXTRACTING PT01c_Recovery_short STRAIN DATA (DIRECT) ===\n');

% Set up paths directly (avoiding config function issues)
dataset_name = 'PT01c_Recovery_short';
base_input = 'C:\Coding\BGWRP\data\_BATCH';

% Find the data file
dataset_dirs = {
    fullfile(base_input, '_active', dataset_name);
    fullfile(base_input, '_concatenated', dataset_name);
};

das_filepath = '';
for dir_idx = 1:length(dataset_dirs)
    dataset_dir = dataset_dirs{dir_idx};
    if exist(dataset_dir, 'dir')
        mat_files = dir(fullfile(dataset_dir, '*.mat'));
        % Filter out timing config files
        data_files = mat_files(~contains({mat_files.name}, 'get_timing'));
        
        if length(data_files) == 1
            das_filepath = fullfile(dataset_dir, data_files(1).name);
            fprintf('Found data file: %s\n', data_files(1).name);
            break;
        elseif length(data_files) > 1
            error('Multiple data MAT files found in %s - cannot determine which to use', dataset_dir);
        end
    end
end

if isempty(das_filepath)
    error('DAS data file not found for %s', dataset_name);
end

fprintf('Loading DAS data: %s\n', das_filepath);

% Load DAS data
loaded_data = load(das_filepath);
if isfield(loaded_data, 'decdata')
    data1Hz = loaded_data.decdata;
    fprintf('  Loaded decimated data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
elseif isfield(loaded_data, 'data1Hz')
    data1Hz = loaded_data.data1Hz;
    fprintf('  Loaded 1Hz data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
else
    error('No recognized data field found in %s', das_filepath);
end

% PT01c calibration parameters
C1 = 140;
MperChan = 0.263;
zone_min_ft = 260;
zone_max_ft = 310;

fprintf('Using PT01c calibration: C1=%d, MperChan=%.3f\n', C1, MperChan);

% Calculate depth array
channels = 1:size(data1Hz, 2);
depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;

% Set analysis window directly (19:14-19:19 UTC as configured)
analysis_start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
analysis_end = datetime(2023,10,24,19,19,00,00,'TimeZone','UTC');

% Create time array
n_samples = size(data1Hz, 1);
time_array = analysis_start + seconds(0:n_samples-1);

% Apply smoothing (5-second moving average as per your mode)
smooth_window = 5;
smoothed_data = movmean(data1Hz, smooth_window, 1, 'omitnan');
fprintf('Applied 5-second moving average smoothing\n');

% Find representative channel in pumping zone
zone_mid_ft = (zone_min_ft + zone_max_ft) / 2;
[~, channel_idx] = min(abs(depth_ft - zone_mid_ft));

% Get analysis window
analysis_mask = time_array >= analysis_start & time_array <= analysis_end;

% Extract strain data
strain_matrix = smoothed_data;
analysis_strain = smoothed_data(analysis_mask, channel_idx);
analysis_time = time_array(analysis_mask);

% Display information
fprintf('Full strain matrix size: %d time points x %d channels\n', size(strain_matrix,1), size(strain_matrix,2));
fprintf('Analysis window strain size: %d time points\n', length(analysis_strain));
fprintf('Time range: %s to %s\n', time_array(1), time_array(end));
fprintf('Analysis window: %s to %s\n', analysis_time(1), analysis_time(end));
fprintf('Depth range: %.1f to %.1f ft\n', min(depth_ft), max(depth_ft));
fprintf('Representative channel: %d at %.1f ft\n', channel_idx, depth_ft(channel_idx));

% Save full dataset
filename_full = 'PT01c_Recovery_short_strain_matrix_full.mat';
save(filename_full, 'strain_matrix', 'time_array', 'depth_ft');
fprintf('✓ Full strain matrix saved to: %s\n', filename_full);

% Save analysis window dataset
filename_analysis = 'PT01c_Recovery_short_strain_matrix_analysis_window.mat';
save(filename_analysis, 'analysis_strain', 'analysis_time', 'depth_ft');
fprintf('✓ Analysis window strain data saved to: %s\n', filename_analysis);

% Also save as CSV for easy viewing
csv_filename = 'PT01c_Recovery_short_strain_matrix.csv';
% Convert datetime to string for CSV
time_strings = string(time_array);
% Create header with time and depth info
header = ['Time_UTC', arrayfun(@(x) sprintf('Depth_%.1f_ft', x), depth_ft, 'UniformOutput', false)];
% Combine time and strain data
csv_data = [time_strings, strain_matrix];
% Write CSV
writematrix(csv_data, csv_filename);
fprintf('✓ Strain matrix also saved as CSV: %s\n', csv_filename);

fprintf('\n=== EXTRACTION COMPLETE ===\n');
fprintf('Files created for your advisor:\n');
fprintf('  - %s (full dataset)\n', filename_full);
fprintf('  - %s (analysis window only)\n', filename_analysis);
fprintf('  - %s (CSV format)\n', csv_filename);

end
