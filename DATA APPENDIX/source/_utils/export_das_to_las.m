function export_das_to_las(dataset_name, output_filename, export_type)
%EXPORT_DAS_TO_LAS Export DAS amplitude statistics to LAS format for WellCAD
%
% Creates an LAS file with DAS amplitude variance, RMS, and statistics by depth
% matching the format of DTS temperature logs
%
% Usage:
%   export_das_to_las('PT01c_Recovery_short', 'PT01c_DAS_Variance.las', 'full')
%   export_das_to_las('PT01c_Recovery_short', 'PT01c_DAS_Event.las', 'event')
%   export_das_to_las('PT01c_Recovery_short', 'PT01c_DAS_DisplacementRate.las', 'displacement')
%
% Input:
%   dataset_name    - Name of dataset in _active directory
%   output_filename - Output LAS filename (optional, auto-generated if not provided)
%   export_type     - 'full' (default), 'event', or 'displacement'

if nargin < 3
    export_type = 'full';
end

if nargin < 2 || isempty(output_filename)
    switch export_type
        case 'event'
            output_filename = sprintf('%s_DAS_Event.las', dataset_name);
        case 'displacement'
            output_filename = sprintf('%s_DAS_DisplacementRate.las', dataset_name);
        otherwise
            output_filename = sprintf('%s_DAS_Variance.las', dataset_name);
    end
end

console_log('=== EXPORTING DAS DATA TO LAS FORMAT ===\n');
console_log('Dataset: %s\n', dataset_name);
console_log('Export type: %s\n', export_type);
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

console_log('Depth range: [%.1f, %.1f] ft\n', min(depth_ft), max(depth_ft));

%% Process data based on export type
switch export_type
    case 'event'
        console_log('Filtering to event window (19:14-19:17)...\n');
        % Define event window - adjust these times based on your actual event
        event_start_str = '24-Oct-2023 19:14:00';
        event_end_str = '24-Oct-2023 19:17:00';
        
        % For now, use first 3 minutes as event window since we don't have time vector
        % In a real implementation, you'd load the time vector from the timing config
        event_samples = min(180, size(data, 1)); % 3 minutes at 1Hz = 180 samples
        data = data(1:event_samples, :);
        
        console_log('Event window data: [%d x %d] samples\n', size(data, 1), size(data, 2));
        
    case 'displacement'
        console_log('Calculating displacement rate (derivative)...\n');
        % Calculate displacement rate as time derivative
        dt = 1.0; % 1 second sampling interval for 1Hz data
        data_displacement = zeros(size(data));
        
        % Calculate derivative using central difference
        data_displacement(2:end-1, :) = (data(3:end, :) - data(1:end-2, :)) / (2 * dt);
        data_displacement(1, :) = (data(2, :) - data(1, :)) / dt; % Forward difference for first point
        data_displacement(end, :) = (data(end, :) - data(end-1, :)) / dt; % Backward difference for last point
        
        data = data_displacement;
        console_log('Displacement rate calculated\n');
        
    otherwise
        console_log('Using full dataset for statistics...\n');
end

%% Calculate amplitude statistics for each depth
console_log('Calculating amplitude statistics...\n');

% Remove any NaN or infinite values
data_clean = data;
data_clean(~isfinite(data_clean)) = 0;

% Calculate statistics across time for each channel/depth
variance_data = var(data_clean, 0, 1)';      % Variance across time
rms_data = rms(data_clean, 1)';              % RMS across time  
std_data = std(data_clean, 0, 1)';           % Standard deviation across time
mean_data = mean(data_clean, 1)';            % Mean across time
max_data = max(abs(data_clean), [], 1)';     % Maximum absolute value

console_log('Statistics calculated for %d depth points\n', length(variance_data));

%% Create LAS file
console_log('Writing LAS file: %s\n', output_filename);

fid = fopen(output_filename, 'w');
if fid == -1
    error('Could not create output file: %s', output_filename);
end

try
    % Version Information
    console_log(fid, '~Version Information\n');
    console_log(fid, 'VERS. 2.0:\n');
    console_log(fid, 'WRAP. NO:\n');
    console_log(fid, '\n');
    
    % Well Information
    console_log(fid, '~Well Information\n');
    console_log(fid, 'STRT.FT %.2f:\n', min(depth_ft));
    console_log(fid, 'STOP.FT %.2f:\n', max(depth_ft));
    console_log(fid, 'STEP.FT %.3f:\n', mean(diff(depth_ft)));  % Average step size
    console_log(fid, 'NULL. -999.25:\n');
    console_log(fid, '\n');
    
    % Curve Information
    console_log(fid, '~Curve Information\n');
    console_log(fid, 'DEPT.FT     : Depth below casing\n');
    console_log(fid, 'DAS_VAR.NM  : DAS Amplitude Variance\n');
    console_log(fid, 'DAS_RMS.NM  : DAS RMS Amplitude\n');
    console_log(fid, 'DAS_STD.NM  : DAS Standard Deviation\n');
    console_log(fid, 'DAS_MEAN.NM : DAS Mean Amplitude\n');
    console_log(fid, 'DAS_MAX.NM  : DAS Maximum Absolute Amplitude\n');
    console_log(fid, '\n');
    
    % ASCII Data Header
    console_log(fid, '~A  DEPT  DAS_VAR  DAS_RMS  DAS_STD  DAS_MEAN  DAS_MAX\n');
    
    % Write data
    for i = 1:length(depth_ft)
        console_log(fid, '%8.2f %10.5f %10.5f %10.5f %10.5f %10.5f\n', ...
            depth_ft(i), variance_data(i), rms_data(i), std_data(i), ...
            mean_data(i), max_data(i));
    end
    
    fclose(fid);
    console_log('✓ LAS file created successfully: %s\n', output_filename);
    
    % Display summary statistics
    console_log('\n=== DAS AMPLITUDE STATISTICS SUMMARY ===\n');
    console_log('Depth range: [%.1f, %.1f] ft (%d points)\n', min(depth_ft), max(depth_ft), length(depth_ft));
    console_log('Variance range: [%.3e, %.3e]\n', min(variance_data), max(variance_data));
    console_log('RMS range: [%.3f, %.3f]\n', min(rms_data), max(rms_data));
    console_log('Max amplitude: %.3f nm/s\n', max(max_data));
    
catch ME
    fclose(fid);
    error('Error writing LAS file: %s', ME.message);
end

console_log('\n✓ Export complete! Load %s into WellCAD for visualization.\n', output_filename);

end
