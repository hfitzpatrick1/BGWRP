%% Process Recovery Extract Data - Simple Approach
% Process each dataset separately to avoid variable clearing issues

fprintf('=== PROCESSING ALL RECOVERY EXTRACT DATA ===\n');

base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';

%% Process PT-01a
fprintf('\n=== PROCESSING PT-01a ===\n');
directory = [base_input 'PT01a_Recovery\'];
filesearch = '*.tdms';
fileindex = [];
save_data = 1;
save_directory = base_input;

if exist(directory, 'dir')
    files = dir([directory filesearch]);
    fprintf('Found %d TDMS files\n', length(files));
    if length(files) > 0
        fprintf('Starting PT-01a processing...\n');
        run('Silixa_TDMSDataToPhysicalDispRate.m');
        fprintf('✓ PT-01a completed\n');
    end
else
    fprintf('⚠ PT-01a directory not found\n');
end

%% Process PT-01b  
fprintf('\n=== PROCESSING PT-01b ===\n');
base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';
base_output = 'E:\PM_07 Step Test\MATLAB\recovery_extract_out\';
directory = [base_input 'PT01b_Recovery\'];
filesearch = '*.tdms';
fileindex = [];
save_data = 1;
save_directory = base_input;

if exist(directory, 'dir')
    files = dir([directory filesearch]);
    fprintf('Found %d TDMS files\n', length(files));
    if length(files) > 0
        fprintf('Starting PT-01b processing...\n');
        run('Silixa_TDMSDataToPhysicalDispRate.m');
        fprintf('✓ PT-01b completed\n');
    end
else
    fprintf('⚠ PT-01b directory not found\n');
end

%% Process PT-01c
fprintf('\n=== PROCESSING PT-01c ===\n');
base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';
base_output = 'E:\PM_07 Step Test\MATLAB\recovery_extract_out\';
directory = [base_input 'PT01c_Recovery\'];
filesearch = '*.tdms';
fileindex = [];
save_data = 1;
save_directory = base_input;

if exist(directory, 'dir')
    files = dir([directory filesearch]);
    fprintf('Found %d TDMS files\n', length(files));
    if length(files) > 0
        fprintf('Starting PT-01c processing...\n');
        run('Silixa_TDMSDataToPhysicalDispRate.m');
        fprintf('✓ PT-01c completed\n');
    end
else
    fprintf('⚠ PT-01c directory not found\n');
end

fprintf('\n=== ALL PROCESSING COMPLETE ===\n');
fprintf('Files saved within input directory structure\n');
