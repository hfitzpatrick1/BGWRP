function export_das_mean_to_las(dataset_name, output_filename)
%EXPORT_DAS_MEAN_TO_LAS Export DAS mean displacement rate to LAS format for WellCAD
%
% Creates an LAS file with only the DAS mean displacement rate curve
% for clean comparison with DTS data in WellCAD
%
% Usage:
%   export_das_mean_to_las('PT01c_Recovery_short', 'PT01c_DAS_Mean.las')
%
% Input:
%   dataset_name    - Name of dataset in _active directory
%   output_filename - Output LAS filename (optional, auto-generated if not provided)

if nargin < 2 || isempty(output_filename)
    output_filename = sprintf('%s_DAS_Mean.las', dataset_name);
end

console_log('=== EXPORTING DAS MEAN TO LAS FORMAT ===\n');
console_log('Dataset: %s\n', dataset_name);
console_log('Output: %s\n', output_filename);

%% Load DAS data
cfg = config();
base_path = fullfile(cfg.base_input, '_active');
das_file = fullfile(base_path, dataset_name, '_das', sprintf('Dataset_%s_1Hz.mat', dataset_name));

if ~exist(das_file, 'file')
    error('DAS data file not found: %s', das_file);
end

console_log('Loading DAS data: %s\n', das_file);
loaded = load(das_file);

if isfield(loaded, 'decdata')
    data = loaded.decdata;  % [time x channels]
else
    error('No decdata field found in DAS file');
end

console_log('Loaded DAS data: [%d x %d] (time x channels)\n', size(data));

%% Load timing configuration for calibration
timing_dir = fullfile(base_path, dataset_name, '_das_timing');
m_files = dir(fullfile(timing_dir, '*.m'));

if length(m_files) == 1
    [~, func_name, ~] = fileparts(m_files(1).name);
    addpath(timing_dir);
    try
        timing_config = feval(func_name);
        console_log('Loaded timing config: %s\n', func_name);
    catch ME
        console_log('Warning: Could not load timing config: %s\n', ME.message);
        timing_config = struct();
    end
    rmpath(timing_dir);
else
    console_log('Warning: No timing config found, using default calibration\n');
    timing_config = struct();
end

%% Get calibration parameters (PT01c defaults)
if isfield(timing_config, 'C1')
    C1 = timing_config.C1;
else
    C1 = 140;  % Default for PT01c
end

if isfield(timing_config, 'MperChan')
    MperChan = timing_config.MperChan;
else
    MperChan = 0.263;  % Default for PT01c
end

console_log('Using calibration: C1=%d, MperChan=%.3f\n', C1, MperChan);

%% Calculate depth array
num_channels = size(data, 2);
channel_indices = (1:num_channels) - 1;  % 0-based indexing
depth_m = (channel_indices - C1) * MperChan;
depth_ft = depth_m * 3.28084;  % Convert to feet

% Apply depth shift correction (shift down by 50 ft)
depth_shift_ft = 50;
depth_ft = depth_ft + depth_shift_ft;

console_log('Depth range: [%.1f, %.1f] ft (shifted down by %.0f ft)\n', min(depth_ft), max(depth_ft), depth_shift_ft);

%% Calculate displacement rate (derivative)
console_log('Calculating displacement rate (derivative)...\n');
dt = 1.0; % 1 second sampling interval for 1Hz data
data_displacement = zeros(size(data));

% Calculate derivative using central difference
data_displacement(2:end-1, :) = (data(3:end, :) - data(1:end-2, :)) / (2 * dt);
data_displacement(1, :) = (data(2, :) - data(1, :)) / dt; % Forward difference for first point
data_displacement(end, :) = (data(end, :) - data(end-1, :)) / dt; % Backward difference for last point

console_log('Displacement rate calculated\n');

%% Calculate mean displacement rate for each depth
console_log('Calculating mean displacement rate by depth...\n');

% Remove any NaN or infinite values
data_clean = data_displacement;
data_clean(~isfinite(data_clean)) = 0;

% Calculate mean across time for each channel/depth
mean_data = mean(data_clean, 1)';            % Mean across time

console_log('Mean calculated for %d depth points\n', length(mean_data));

%% Create LAS file
console_log('Writing LAS file: %s\n', output_filename);

fid = fopen(output_filename, 'w');
if fid == -1
    error('Could not create output file: %s', output_filename);
end

% Write LAS header
console_log(fid, '~Version Information\n');
console_log(fid, 'VERS. 2.0:\n');
console_log(fid, 'WRAP. NO:\n');
console_log(fid, '\n');

console_log(fid, '~Well Information\n');
console_log(fid, 'STRT.FT %.2f:\n', min(depth_ft));
console_log(fid, 'STOP.FT %.2f:\n', max(depth_ft));
console_log(fid, 'STEP.FT %.3f:\n', median(diff(depth_ft)));
console_log(fid, 'NULL. -999.25:\n');
console_log(fid, '\n');

console_log(fid, '~Curve Information\n');
console_log(fid, 'DEPT.FT     : Depth below casing\n');
console_log(fid, 'DAS_MEAN.NM : DAS Mean Displacement Rate\n');
console_log(fid, '\n');

console_log(fid, '~A  DEPT  DAS_MEAN\n');

% Write data
for i = 1:length(depth_ft)
    console_log(fid, '%8.2f %12.5f\n', depth_ft(i), mean_data(i));
end

fclose(fid);

console_log('\n✓ LAS file created successfully: %s\n', output_filename);

%% Print summary
console_log('\n=== DAS MEAN DISPLACEMENT RATE SUMMARY ===\n');
console_log('Depth range: [%.1f, %.1f] ft (%d points)\n', min(depth_ft), max(depth_ft), length(depth_ft));
console_log('Mean displacement rate range: [%.3e, %.3e]\n', min(mean_data), max(mean_data));
console_log('Mean value: %.3e nm/s\n', mean(mean_data));

console_log('\n✓ Export complete! Load %s into WellCAD for visualization.\n', output_filename);

end
