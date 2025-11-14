%% Extract Correlation Data for Storage Analysis
%
% This script extracts data from correlation analysis results and prepares
% variables for storage parameter calculation.
%
% BEFORE RUNNING:
% 1. Run correlation analysis: mode = 'run_correlation_analysis'; BGWRP_Toolkit
% 2. Ensure das_results and head_results are in workspace
% 3. Set the test name below
%
% OUTPUTS:
% - time_vector: [N x 1] seconds from recovery start
% - head_zone5: [N x 1] Zone 5 head data (ft)
% - das_strain_rate: [N x M] DAS strain rate matrix (1/s)
% - depth_vector: [M x 1] depth locations (ft)

clear time_vector head_zone5 das_strain_rate depth_vector

fprintf('=== EXTRACTING DATA FOR STORAGE ANALYSIS ===\n\n');

%% ============================================================
%% CONFIGURATION: Set your test name here
%% ============================================================

% CHANGE THIS FOR EACH TEST:
test_name = 'PT01c_Recovery_short';  % Options: PT01a_Recovery, PT01b_Recovery, PT01c_Recovery_short

fprintf('Test: %s\n\n', test_name);

%% ============================================================
%% STEP 1: Extract DAS data
%% ============================================================
fprintf('Step 1: Extracting DAS data...\n');

% Check if results exist
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('das_results and head_results not found in workspace!\nRun: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

% Extract DAS structure
das = das_results.(test_name);

% Convert datetime to seconds from start
time_vector = seconds(das.analysis_time - das.analysis_time(1));

% Find time indices for analysis window
full_time = das.time_array;
[~, start_idx] = min(abs(full_time - das.analysis_time(1)));
[~, end_idx] = min(abs(full_time - das.analysis_time(end)));

% Extract displacement rate and convert to strain rate [time x depth]
% smoothed_data is in nm/s (displacement rate), need to convert to strain rate (1/s)
gauge_length_m = 10;  % DAS gauge length in meters
displacement_rate = das.smoothed_data(start_idx:end_idx, :);  % nm/s
das_strain_rate = displacement_rate / (gauge_length_m * 1e9);  % Convert to 1/s
% Keep ALL depths - the storage function will select the responsive zone

% Get depth vector
depth_vector = das.depth_ft;

fprintf('  ✓ DAS data extracted and converted\n');
fprintf('    Time points: %d\n', length(time_vector));
fprintf('    Time range: %.1f to %.1f minutes\n', min(time_vector)/60, max(time_vector)/60);
fprintf('    Depths: %d channels\n', length(depth_vector));
fprintf('    Depth range: %.1f to %.1f ft\n', min(depth_vector), max(depth_vector));
fprintf('    Strain rate size: [%d x %d]\n', size(das_strain_rate, 1), size(das_strain_rate, 2));
fprintf('    Strain rate range: %.2e to %.2e 1/s (converted from nm/s)\n\n', min(das_strain_rate(:)), max(das_strain_rate(:)));

%% ============================================================
%% STEP 2: Extract Zone 5 head data
%% ============================================================
fprintf('Step 2: Extracting Zone 5 head data...\n');

% Extract head structure
head = head_results.(test_name);

% Extract Zone 5 recovery data
z5_time = head.zones.z5.recovery_data.Date;
z5_drawdown = head.zones.z5.recovery_data.Drawdownft;  % Note: typo in original field name

% Convert Zone 5 time to seconds from start
z5_time_seconds = seconds(z5_time - z5_time(1));

% Interpolate to match DAS time vector
% (Zone 5 has fewer samples than DAS, typically ~60 vs 300)
head_zone5 = interp1(z5_time_seconds, z5_drawdown, time_vector, 'linear', 'extrap');

fprintf('  ✓ Zone 5 data extracted and interpolated\n');
fprintf('    Original Zone 5 points: %d\n', length(z5_drawdown));
fprintf('    Interpolated to: %d points (matching DAS)\n', length(head_zone5));
fprintf('    Head range: %.2f to %.2f ft\n\n', min(head_zone5), max(head_zone5));

%% ============================================================
%% STEP 3: Quality checks
%% ============================================================
fprintf('Step 3: Quality checks...\n');

% Check for NaN or Inf
if any(isnan(das_strain_rate(:)))
    warning('NaN values detected in DAS strain rate');
end
if any(isnan(head_zone5))
    warning('NaN values detected in Zone 5 head data');
end
if any(isinf(das_strain_rate(:)))
    warning('Inf values detected in DAS strain rate');
end
if any(isinf(head_zone5))
    warning('Inf values detected in Zone 5 head data');
end

% Check dimensions
assert(length(time_vector) == size(das_strain_rate, 1), ...
    'Time vector length must match DAS strain rate rows');
assert(length(time_vector) == length(head_zone5), ...
    'Time vector length must match Zone 5 head data length');
assert(length(depth_vector) == size(das_strain_rate, 2), ...
    'Depth vector length must match DAS strain rate columns');

fprintf('  ✓ All quality checks passed\n\n');

%% ============================================================
%% STEP 4: Save data
%% ============================================================
fprintf('Step 4: Saving correlation results...\n');

% Construct filename with test name
output_filename = sprintf('C:\\Coding\\BGWRP Lit Review\\Thesis\\correlation_results_%s.mat', test_name);

% Save
save(output_filename, 'time_vector', 'head_zone5', 'das_strain_rate', 'depth_vector', 'test_name');

fprintf('  ✓ Data saved to:\n    %s\n\n', output_filename);

%% ============================================================
%% STEP 5: Display summary
%% ============================================================
fprintf('=== EXTRACTION COMPLETE ===\n\n');
fprintf('Variables ready for storage analysis:\n');
fprintf('  time_vector:      [%d x 1] seconds\n', length(time_vector));
fprintf('  head_zone5:       [%d x 1] ft\n', length(head_zone5));
fprintf('  das_strain_rate:  [%d x %d] 1/s\n', size(das_strain_rate, 1), size(das_strain_rate, 2));
fprintf('  depth_vector:     [%d x 1] ft\n\n', length(depth_vector));

fprintf('NEXT STEP:\n');
fprintf('  cd(''C:\\Coding\\BGWRP\\src'')\n');
fprintf('  load(''%s'')\n', output_filename);
fprintf('  test_storage_calculation\n\n');

%% ============================================================
%% OPTIONAL: Auto-run storage calculation
%% ============================================================

run_now = questdlg('Run storage calculation now?', 'Run Analysis', 'Yes', 'No', 'Yes');

if strcmp(run_now, 'Yes')
    fprintf('Running storage calculation...\n\n');
    cd('C:\Coding\BGWRP\src');
    test_storage_calculation
end

