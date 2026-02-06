%% Migrate PT01a from _BATCH_old to _BATCH
% Copies PT01a data from old location to new active directory

fprintf('=== MIGRATING PT01a FROM _BATCH_old ===\n\n');

%% Step 1: Check source directory
source_base = 'C:\Coding\BGWRP\data\_BATCH_old\_raw\PT01a_Recovery_short';
fprintf('STEP 1: Checking source directory...\n');
fprintf('Source: %s\n', source_base);

if ~exist(source_base, 'dir')
    error('Source directory not found: %s', source_base);
end

% Check for TDMS files in _das subdirectory
source_das = fullfile(source_base, '_das');
if exist(source_das, 'dir')
    tdms_files = dir(fullfile(source_das, '*.tdms'));
    fprintf('✓ Found %d TDMS files in source _das directory\n', length(tdms_files));
else
    % Check for TDMS files directly in base directory
    tdms_files = dir(fullfile(source_base, '*.tdms'));
    if ~isempty(tdms_files)
        fprintf('✓ Found %d TDMS files in source base directory\n', length(tdms_files));
        source_das = source_base;  % Use base directory as source
    else
        error('No TDMS files found in source directory');
    end
end

% Check for head data
source_head = fullfile(source_base, '_head');
has_head = exist(source_head, 'dir') && ~isempty(dir(fullfile(source_head, '*.mat')));

%% Step 2: Create destination directories
dest_base = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01a_Recovery_short';
fprintf('\nSTEP 2: Creating destination directories...\n');
fprintf('Destination: %s\n', dest_base);

dest_das = fullfile(dest_base, '_das');
dest_head = fullfile(dest_base, '_head');

if ~exist(dest_das, 'dir')
    mkdir(dest_das);
    fprintf('✓ Created: %s\n', dest_das);
else
    fprintf('✓ Already exists: %s\n', dest_das);
end

if has_head && ~exist(dest_head, 'dir')
    mkdir(dest_head);
    fprintf('✓ Created: %s\n', dest_head);
end

%% Step 3: Copy TDMS files
fprintf('\nSTEP 3: Copying TDMS files...\n');
fprintf('This may take a few minutes...\n');

for i = 1:length(tdms_files)
    source_file = fullfile(source_das, tdms_files(i).name);
    dest_file = fullfile(dest_das, tdms_files(i).name);
    
    fprintf('  [%d/%d] Copying: %s\n', i, length(tdms_files), tdms_files(i).name);
    copyfile(source_file, dest_file);
end

fprintf('✓ Copied %d TDMS files\n', length(tdms_files));

%% Step 4: Copy head data if present
if has_head
    fprintf('\nSTEP 4: Copying head data...\n');
    head_files = dir(fullfile(source_head, '*.mat'));
    for i = 1:length(head_files)
        source_file = fullfile(source_head, head_files(i).name);
        dest_file = fullfile(dest_head, head_files(i).name);
        fprintf('  Copying: %s\n', head_files(i).name);
        copyfile(source_file, dest_file);
    end
    fprintf('✓ Copied %d head data files\n', length(head_files));
else
    fprintf('\nSTEP 4: No head data found (optional)\n');
end

%% Step 5: Run prep pipeline
fprintf('\n=== MIGRATION COMPLETE ===\n');
fprintf('\nNext steps:\n');
fprintf('1. Run the prep pipeline to process the TDMS files:\n');
fprintf('   cd(''C:\\Coding\\BGWRP\\src'')\n');
fprintf('   mode = ''prep''; BGWRP_Toolkit\n\n');
fprintf('2. Then run your analysis:\n');
fprintf('   cd(''C:\\Coding\\BGWRP'')\n');
fprintf('   run_PT01a_thesis_analysis_zone2\n\n');

fprintf('Would you like to run the prep pipeline now? (y/n): ');
response = input('', 's');

if strcmpi(response, 'y')
    fprintf('\nRunning prep pipeline...\n');
    cd('C:\Coding\BGWRP\src');
    mode = 'prep';
    BGWRP_Toolkit;
    
    fprintf('\n=== PREP COMPLETE ===\n');
    fprintf('Now run your analysis:\n');
    fprintf('  cd(''C:\\Coding\\BGWRP'')\n');
    fprintf('  run_PT01a_thesis_analysis_zone2\n');
else
    fprintf('\nRun prep manually when ready:\n');
    fprintf('  cd(''C:\\Coding\\BGWRP\\src'')\n');
    fprintf('  mode = ''prep''; BGWRP_Toolkit\n');
end
