%% Process Recovery Extract Data - Wrapper Script
% This script processes all three recovery extract datasets by calling
% the original Silixa_TDMSDataToPhysicalDispRate.m script with different parameters

clear all;

%% Configuration
fprintf('=== PROCESSING RECOVERY EXTRACT DATA ===\n');

% Define test datasets
tests = {'PT01a_Recovery', 'PT01b_Recovery', 'PT01c_Recovery'};
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};

% Base directories
base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';
base_output = 'E:\PM_07 Step Test\MATLAB\recovery_extract_out\';

% Create output directory if it doesn't exist
if ~exist(base_output, 'dir')
    mkdir(base_output);
    fprintf('Created output directory: %s\n', base_output);
end

%% Process each test dataset
for i = 1:length(tests)
    % Store variables that will be cleared by Silixa script
    current_tests = tests;
    current_test_names = test_names;
    current_base_input = base_input;
    current_base_output = base_output;
    
    fprintf('\n=== PROCESSING %s ===\n', current_test_names{i});
    
    % Set parameters for Silixa script
    directory = [current_base_input current_tests{i} '\'];
    filesearch = '*.tdms';
    fileindex = []; % Process all files
    save_data = 1;
    save_directory = current_base_output;
    
    % Verify input directory exists
    if ~exist(directory, 'dir')
        fprintf('WARNING: Input directory not found: %s\n', directory);
        fprintf('Skipping %s\n', current_test_names{i});
        continue;
    end
    
    % Check how many files we'll process
    files = dir([directory filesearch]);
    fprintf('Found %d TDMS files in %s\n', length(files), directory);
    
    if length(files) == 0
        fprintf('No TDMS files found, skipping %s\n', current_test_names{i});
        continue;
    end
    
    % Run the original Silixa script
    fprintf('Starting processing...\n');
    try
        run('Silixa_TDMSDataToPhysicalDispRate.m');
        fprintf('✓ Processing completed successfully\n');
    catch ME
        fprintf('✗ Error during processing: %s\n', ME.message);
        fprintf('Full error details:\n');
        disp(ME);
    end
end

fprintf('\n=== ALL RECOVERY EXTRACT PROCESSING COMPLETE ===\n');
fprintf('Output directory: %s\n', base_output);
