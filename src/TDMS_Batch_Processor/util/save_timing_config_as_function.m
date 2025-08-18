function save_timing_config_as_function(test_config, source_folder, output_dir)
%SAVE_TIMING_CONFIG_AS_FUNCTION Save timing configuration as MATLAB function
%
% Inputs:
%   test_config   - Timing configuration structure
%   source_folder - Source folder name (for function naming)
%   output_dir    - Output directory for the function file

% Create function name
func_name = sprintf('get_timing_%s', source_folder);
func_filename = sprintf('%s.m', func_name);
func_filepath = fullfile(output_dir, func_filename);

% Create the function file
fid = fopen(func_filepath, 'w');
if fid == -1
    error('Could not create function file: %s', func_filepath);
end

% Write function header
fprintf(fid, 'function timing_config = %s()\n', func_name);
fprintf(fid, '%%GET_TIMING_%s Timing configuration for %s\n', upper(source_folder), source_folder);
fprintf(fid, '%%\n');
fprintf(fid, '%% Auto-generated timing configuration\n');
fprintf(fid, '%% Generated: %s\n', datetime('now'));
fprintf(fid, '%%\n');
fprintf(fid, '%% Output:\n');
fprintf(fid, '%%   timing_config - Timing configuration structure\n\n');

% Write configuration data
fprintf(fid, '%% Dataset Information\n');
fprintf(fid, 'timing_config.dataset_name = ''%s'';\n', source_folder);
fprintf(fid, 'timing_config.source = ''%s'';\n', test_config.source);
fprintf(fid, 'timing_config.num_files = %d;\n', test_config.num_files);

if isfield(test_config, 'first_file')
    fprintf(fid, 'timing_config.first_file = ''%s'';\n', test_config.first_file);
end

fprintf(fid, '\n%% Timing Information\n');
% Use datestr/datevec approach for better compatibility
start_vec = datevec(test_config.start);
fprintf(fid, 'timing_config.start = datetime(%d, %d, %d, %d, %d, %.3f, ''TimeZone'', ''UTC'');\n', ...
    start_vec(1), start_vec(2), start_vec(3), start_vec(4), start_vec(5), start_vec(6));

if isfield(test_config, 'end')
    end_vec = datevec(test_config.end);
    fprintf(fid, 'timing_config.end = datetime(%d, %d, %d, %d, %d, %.3f, ''TimeZone'', ''UTC'');\n', ...
        end_vec(1), end_vec(2), end_vec(3), end_vec(4), end_vec(5), end_vec(6));
    fprintf(fid, 'timing_config.duration_minutes = %.1f;\n', test_config.duration_minutes);
end

% Add dataset-specific parameters based on source folder
fprintf(fid, '\n%% Dataset-Specific Parameters\n');
if contains(upper(source_folder), 'PT01C') || contains(upper(source_folder), '_C_')
    fprintf(fid, '%% PT-01c specific parameters\n');
    fprintf(fid, 'timing_config.head_timing_adjustment = 10;  %% seconds\n');
    fprintf(fid, 'timing_config.das_timing_adjustment = 90;   %% seconds\n');
    fprintf(fid, 'timing_config.C1 = 110;\n');
    fprintf(fid, 'timing_config.pumping_zone_min_ft = 260;\n');
    fprintf(fid, 'timing_config.pumping_zone_max_ft = 310;\n');
elseif contains(upper(source_folder), 'PT01A') || contains(upper(source_folder), '_A_')
    fprintf(fid, '%% PT-01a specific parameters\n');
    fprintf(fid, 'timing_config.head_timing_adjustment = 0;   %% seconds\n');
    fprintf(fid, 'timing_config.das_timing_adjustment = 0;    %% seconds\n');
    fprintf(fid, 'timing_config.C1 = 513;\n');
    fprintf(fid, 'timing_config.pumping_zone_min_ft = 450;\n');
    fprintf(fid, 'timing_config.pumping_zone_max_ft = 510;\n');
elseif contains(upper(source_folder), 'PT01B') || contains(upper(source_folder), '_B_')
    fprintf(fid, '%% PT-01b specific parameters\n');
    fprintf(fid, 'timing_config.head_timing_adjustment = 0;   %% seconds\n');
    fprintf(fid, 'timing_config.das_timing_adjustment = 120;  %% seconds\n');
    fprintf(fid, 'timing_config.C1 = 513;\n');
    fprintf(fid, 'timing_config.pumping_zone_min_ft = 350;\n');
    fprintf(fid, 'timing_config.pumping_zone_max_ft = 400;\n');
else
    fprintf(fid, '%% Default parameters\n');
    fprintf(fid, 'timing_config.head_timing_adjustment = 0;   %% seconds\n');
    fprintf(fid, 'timing_config.das_timing_adjustment = 0;    %% seconds\n');
    fprintf(fid, 'timing_config.C1 = 513;\n');
    fprintf(fid, 'timing_config.pumping_zone_min_ft = 300;\n');
    fprintf(fid, 'timing_config.pumping_zone_max_ft = 500;\n');
end

fprintf(fid, '\nend\n');

fclose(fid);

fprintf('✓ Saved timing configuration function: %s\n', func_filename);

end
