%% Setup PT01a_Recovery_short Directory
% Creates proper directory structure and timing config

fprintf('=== SETTING UP PT01a_Recovery_short DIRECTORY ===\n\n');

base_dir = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short';

%% Step 1: Create directory structure
fprintf('STEP 1: Creating directory structure...\n');

das_dir = fullfile(base_dir, '_das');
timing_dir = fullfile(base_dir, '_das_timing');
head_dir = fullfile(base_dir, '_head');

if ~exist(das_dir, 'dir')
    mkdir(das_dir);
    fprintf('✓ Created: %s\n', das_dir);
else
    fprintf('✓ Already exists: %s\n', das_dir);
end

if ~exist(timing_dir, 'dir')
    mkdir(timing_dir);
    fprintf('✓ Created: %s\n', timing_dir);
else
    fprintf('✓ Already exists: %s\n', timing_dir);
end

if ~exist(head_dir, 'dir')
    mkdir(head_dir);
    fprintf('✓ Created: %s\n', head_dir);
else
    fprintf('✓ Already exists: %s\n', head_dir);
end

%% Step 2: Create timing configuration file
fprintf('\nSTEP 2: Creating timing configuration...\n');

timing_file = fullfile(timing_dir, 'get_timing_PT01a_Recovery_short.m');

timing_content = [...
'function timing = get_timing_PT01a_Recovery_short()\n' ...
'%% Timing configuration for PT01a Recovery test\n' ...
'% Test date: November 7, 2023\n' ...
'% Recovery period: 20:34-20:54 UTC (20 minutes)\n' ...
'% Source: Manual configuration\n\n' ...
'timing.start = datetime(2023, 11, 7, 20, 34, 0, ''TimeZone'', ''UTC'');\n' ...
'timing.end = datetime(2023, 11, 7, 20, 54, 0, ''TimeZone'', ''UTC'');\n' ...
'timing.duration_minutes = 20;\n' ...
'timing.num_files = 21;  % Estimated based on typical file count\n' ...
'timing.source = ''manual'';\n' ...
'timing.first_file = ''PM07StepPT01a_Recovery_UTC_20231107_203400.754.tdms'';\n\n' ...
'end\n'];

fid = fopen(timing_file, 'w');
fprintf(fid, timing_content);
fclose(fid);

fprintf('✓ Created timing config: %s\n', timing_file);

%% Step 3: Search for PT01a data file
fprintf('\nSTEP 3: Searching for PT01a DAS data file...\n');

% Search entire BGWRP directory for PT01a MAT files
search_base = 'C:\Coding\BGWRP';
fprintf('Searching in: %s\n', search_base);

mat_files = dir(fullfile(search_base, '**', '*PT01a*.mat'));

if ~isempty(mat_files)
    fprintf('Found %d potential PT01a MAT files:\n', length(mat_files));
    for i = 1:length(mat_files)
        file_path = fullfile(mat_files(i).folder, mat_files(i).name);
        file_size = mat_files(i).bytes / (1024*1024);
        fprintf('  %d. %s (%.1f MB)\n', i, file_path, file_size);
    end
    
    fprintf('\nWhich file would you like to use?\n');
    fprintf('Enter the number (1-%d), or 0 to skip: ', length(mat_files));
    choice = input('');
    
    if choice > 0 && choice <= length(mat_files)
        source_file = fullfile(mat_files(choice).folder, mat_files(choice).name);
        dest_file = fullfile(das_dir, mat_files(choice).name);
        
        fprintf('\nCopying file...\n');
        fprintf('  From: %s\n', source_file);
        fprintf('  To: %s\n', dest_file);
        
        copyfile(source_file, dest_file);
        fprintf('✓ File copied successfully!\n');
    else
        fprintf('Skipping file copy.\n');
    end
else
    fprintf('⚠ No PT01a MAT files found.\n');
    fprintf('\nYou need to:\n');
    fprintf('  1. Run prep mode if you have TDMS files, OR\n');
    fprintf('  2. Manually copy your PT01a data file to:\n');
    fprintf('     %s\n', das_dir);
end

%% Step 4: Summary
fprintf('\n=== SETUP COMPLETE ===\n');
fprintf('\nDirectory structure created:\n');
fprintf('  %s\\_das\\\n', base_dir);
fprintf('  %s\\_das_timing\\\n', base_dir);
fprintf('  %s\\_head\\\n', base_dir);
fprintf('\n✓ Timing configuration created\n');

% Check if we have everything we need
has_data = ~isempty(dir(fullfile(das_dir, '*.mat')));
has_timing = exist(timing_file, 'file');
has_head = ~isempty(dir(fullfile(head_dir, '*.mat')));

fprintf('\nStatus check:\n');
if has_data
    fprintf('  ✓ DAS data file present\n');
else
    fprintf('  ✗ DAS data file MISSING\n');
end

if has_timing
    fprintf('  ✓ Timing config present\n');
else
    fprintf('  ✗ Timing config MISSING\n');
end

if has_head
    fprintf('  ✓ Head data present\n');
else
    fprintf('  ⚠ Head data missing (optional)\n');
end

if has_data && has_timing
    fprintf('\n✓ Ready for analysis!\n');
    fprintf('\nYou can now run:\n');
    fprintf('  cd(''C:\\Coding\\BGWRP'')\n');
    fprintf('  run_PT01a_thesis_analysis_zone2\n');
else
    fprintf('\n⚠ Not ready yet. You need to add the DAS data file.\n');
end
