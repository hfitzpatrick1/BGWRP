%% Find PT01a Files
% Comprehensive search for PT01a data

fprintf('=== SEARCHING FOR PT01a DATA ===\n\n');

%% Check 1: Active directory structure
fprintf('CHECK 1: Active directory structure\n');
active_base = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short';

if exist(active_base, 'dir')
    fprintf('✓ PT01a_Recovery_short directory exists\n');
    
    % Check _das subdirectory
    das_dir = fullfile(active_base, '_das');
    if exist(das_dir, 'dir')
        fprintf('  ✓ _das directory exists\n');
        mat_files = dir(fullfile(das_dir, '*.mat'));
        fprintf('    Found %d MAT files:\n', length(mat_files));
        for i = 1:length(mat_files)
            info = dir(fullfile(das_dir, mat_files(i).name));
            fprintf('      - %s (%.1f MB)\n', mat_files(i).name, info.bytes/1024/1024);
        end
    else
        fprintf('  ✗ _das directory NOT found\n');
    end
    
    % Check _das_timing subdirectory
    timing_dir = fullfile(active_base, '_das_timing');
    if exist(timing_dir, 'dir')
        fprintf('  ✓ _das_timing directory exists\n');
        m_files = dir(fullfile(timing_dir, '*.m'));
        fprintf('    Found %d timing files:\n', length(m_files));
        for i = 1:length(m_files)
            fprintf('      - %s\n', m_files(i).name);
        end
    else
        fprintf('  ✗ _das_timing directory NOT found\n');
    end
    
    % Check _head subdirectory
    head_dir = fullfile(active_base, '_head');
    if exist(head_dir, 'dir')
        fprintf('  ✓ _head directory exists\n');
        head_files = dir(fullfile(head_dir, '*.mat'));
        fprintf('    Found %d head files:\n', length(head_files));
        for i = 1:length(head_files)
            fprintf('      - %s\n', head_files(i).name);
        end
    else
        fprintf('  ✗ _head directory NOT found\n');
    end
else
    fprintf('✗ PT01a_Recovery_short directory NOT found: %s\n', active_base);
end

%% Check 2: Search for TDMS files
fprintf('\n\nCHECK 2: Searching for PT01a TDMS files\n');

search_paths = {
    'C:\Coding\BGWRP\data\_BATCH\_raw';
    'C:\Coding\BGWRP\data\_BATCH';
    'C:\Coding\BGWRP\data';
    'E:\PM_07 Step Test\MATLAB\recovery_extract';
};

found_tdms = false;
for i = 1:length(search_paths)
    if exist(search_paths{i}, 'dir')
        fprintf('  Checking: %s\n', search_paths{i});
        tdms_files = dir(fullfile(search_paths{i}, '**', '*PT01a*.tdms'));
        if ~isempty(tdms_files)
            found_tdms = true;
            fprintf('    ✓ Found %d PT01a TDMS files:\n', length(tdms_files));
            for j = 1:min(5, length(tdms_files))
                fprintf('      %s\n', fullfile(tdms_files(j).folder, tdms_files(j).name));
            end
            if length(tdms_files) > 5
                fprintf('      ... and %d more\n', length(tdms_files) - 5);
            end
        end
    end
end

if ~found_tdms
    fprintf('  ✗ No PT01a TDMS files found in any search path\n');
end

%% Check 3: Search for intermediate MAT files
fprintf('\n\nCHECK 3: Searching for intermediate PT01a MAT files\n');

mat_search_paths = {
    'C:\Coding\BGWRP\data\_BATCH\_tdms_to_mat';
    'C:\Coding\BGWRP\data\_BATCH\_concatenated';
};

for i = 1:length(mat_search_paths)
    if exist(mat_search_paths{i}, 'dir')
        fprintf('  Checking: %s\n', mat_search_paths{i});
        pt01a_dirs = dir(fullfile(mat_search_paths{i}, '*PT01a*'));
        if ~isempty(pt01a_dirs)
            for j = 1:length(pt01a_dirs)
                if pt01a_dirs(j).isdir
                    dir_path = fullfile(mat_search_paths{i}, pt01a_dirs(j).name);
                    fprintf('    Found directory: %s\n', pt01a_dirs(j).name);
                    mat_files = dir(fullfile(dir_path, '**', '*.mat'));
                    fprintf('      Contains %d MAT files\n', length(mat_files));
                end
            end
        end
    end
end

fprintf('\n=== SEARCH COMPLETE ===\n');
fprintf('\nRECOMMENDATION:\n');
fprintf('If you have TDMS files, they need to be in:\n');
fprintf('  C:\\Coding\\BGWRP\\data\\_BATCH\\_raw\\PT01a_Recovery_short\\_das\\\n');
fprintf('\nOr if you only have the final MAT file, you need to create timing manually.\n');
