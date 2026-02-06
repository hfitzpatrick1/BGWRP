%% Find PT01a Files
% Comprehensive search for PT01a data

console_log('=== SEARCHING FOR PT01a DATA ===\n\n');

%% Check 1: Active directory structure
console_log('CHECK 1: Active directory structure\n');
active_base = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short';

if exist(active_base, 'dir')
    console_log('✓ PT01a_Recovery_short directory exists\n');
    
    % Check _das subdirectory
    das_dir = fullfile(active_base, '_das');
    if exist(das_dir, 'dir')
        console_log('  ✓ _das directory exists\n');
        mat_files = dir(fullfile(das_dir, '*.mat'));
        console_log('    Found %d MAT files:\n', length(mat_files));
        for i = 1:length(mat_files)
            info = dir(fullfile(das_dir, mat_files(i).name));
            console_log('      - %s (%.1f MB)\n', mat_files(i).name, info.bytes/1024/1024);
        end
    else
        console_log('  ✗ _das directory NOT found\n');
    end
    
    % Check _das_timing subdirectory
    timing_dir = fullfile(active_base, '_das_timing');
    if exist(timing_dir, 'dir')
        console_log('  ✓ _das_timing directory exists\n');
        m_files = dir(fullfile(timing_dir, '*.m'));
        console_log('    Found %d timing files:\n', length(m_files));
        for i = 1:length(m_files)
            console_log('      - %s\n', m_files(i).name);
        end
    else
        console_log('  ✗ _das_timing directory NOT found\n');
    end
    
    % Check _head subdirectory
    head_dir = fullfile(active_base, '_head');
    if exist(head_dir, 'dir')
        console_log('  ✓ _head directory exists\n');
        head_files = dir(fullfile(head_dir, '*.mat'));
        console_log('    Found %d head files:\n', length(head_files));
        for i = 1:length(head_files)
            console_log('      - %s\n', head_files(i).name);
        end
    else
        console_log('  ✗ _head directory NOT found\n');
    end
else
    console_log('✗ PT01a_Recovery_short directory NOT found: %s\n', active_base);
end

%% Check 2: Search for TDMS files
console_log('\n\nCHECK 2: Searching for PT01a TDMS files\n');

search_paths = {
    'C:\Coding\BGWRP\data\_BATCH\_raw';
    'C:\Coding\BGWRP\data\_BATCH';
    'C:\Coding\BGWRP\data';
    'E:\PM_07 Step Test\MATLAB\recovery_extract';
};

found_tdms = false;
for i = 1:length(search_paths)
    if exist(search_paths{i}, 'dir')
        console_log('  Checking: %s\n', search_paths{i});
        tdms_files = dir(fullfile(search_paths{i}, '**', '*PT01a*.tdms'));
        if ~isempty(tdms_files)
            found_tdms = true;
            console_log('    ✓ Found %d PT01a TDMS files:\n', length(tdms_files));
            for j = 1:min(5, length(tdms_files))
                console_log('      %s\n', fullfile(tdms_files(j).folder, tdms_files(j).name));
            end
            if length(tdms_files) > 5
                console_log('      ... and %d more\n', length(tdms_files) - 5);
            end
        end
    end
end

if ~found_tdms
    console_log('  ✗ No PT01a TDMS files found in any search path\n');
end

%% Check 3: Search for intermediate MAT files
console_log('\n\nCHECK 3: Searching for intermediate PT01a MAT files\n');

mat_search_paths = {
    'C:\Coding\BGWRP\data\_BATCH\_tdms_to_mat';
    'C:\Coding\BGWRP\data\_BATCH\_concatenated';
};

for i = 1:length(mat_search_paths)
    if exist(mat_search_paths{i}, 'dir')
        console_log('  Checking: %s\n', mat_search_paths{i});
        pt01a_dirs = dir(fullfile(mat_search_paths{i}, '*PT01a*'));
        if ~isempty(pt01a_dirs)
            for j = 1:length(pt01a_dirs)
                if pt01a_dirs(j).isdir
                    dir_path = fullfile(mat_search_paths{i}, pt01a_dirs(j).name);
                    console_log('    Found directory: %s\n', pt01a_dirs(j).name);
                    mat_files = dir(fullfile(dir_path, '**', '*.mat'));
                    console_log('      Contains %d MAT files\n', length(mat_files));
                end
            end
        end
    end
end

console_log('\n=== SEARCH COMPLETE ===\n');
console_log('\nRECOMMENDATION:\n');
console_log('If you have TDMS files, they need to be in:\n');
console_log('  C:\\Coding\\BGWRP\\data\\_BATCH\\_raw\\PT01a_Recovery_short\\_das\\\n');
console_log('\nOr if you only have the final MAT file, you need to create timing manually.\n');
