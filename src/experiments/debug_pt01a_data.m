%% Debug PT01a Data Availability
% This script checks if PT01a data exists and what fields are in das_results

clear; clc;
console_log('=== DEBUGGING PT01a DATA ===\n\n');

%% Step 1: Check if data files exist
console_log('STEP 1: Checking for PT01a data files...\n');
base_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short';

% Check _das directory
das_dir = fullfile(base_path, '_das');
if exist(das_dir, 'dir')
    console_log('✓ _das directory exists: %s\n', das_dir);
    mat_files = dir(fullfile(das_dir, '*.mat'));
    if ~isempty(mat_files)
        console_log('  Found %d MAT file(s):\n', length(mat_files));
        for i = 1:length(mat_files)
            console_log('    %s\n', mat_files(i).name);
        end
    else
        console_log('  ✗ No MAT files found!\n');
    end
else
    console_log('✗ _das directory NOT found: %s\n', das_dir);
end

% Check _das_timing directory
timing_dir = fullfile(base_path, '_das_timing');
if exist(timing_dir, 'dir')
    console_log('✓ _das_timing directory exists: %s\n', timing_dir);
    m_files = dir(fullfile(timing_dir, '*.m'));
    if ~isempty(m_files)
        console_log('  Found %d timing config(s):\n', length(m_files));
        for i = 1:length(m_files)
            console_log('    %s\n', m_files(i).name);
        end
    else
        console_log('  ✗ No timing config files found!\n');
    end
else
    console_log('✗ _das_timing directory NOT found: %s\n', timing_dir);
end

% Check _head directory
head_dir = fullfile(base_path, '_head');
if exist(head_dir, 'dir')
    console_log('✓ _head directory exists: %s\n', head_dir);
    head_files = dir(fullfile(head_dir, '*.mat'));
    if ~isempty(head_files)
        console_log('  Found %d head data file(s):\n', length(head_files));
        for i = 1:length(head_files)
            console_log('    %s\n', head_files(i).name);
        end
    else
        console_log('  ✗ No head data files found!\n');
    end
else
    console_log('✗ _head directory NOT found: %s\n', head_dir);
end

%% Step 2: Try running correlation analysis
console_log('\n\nSTEP 2: Running correlation analysis to check das_results...\n');
addpath(genpath('src'));

try
    mode = 'run_correlation_analysis';
    BGWRP_Toolkit;
    
    console_log('\n\nSTEP 3: Checking das_results structure...\n');
    if exist('das_results', 'var')
        console_log('✓ das_results exists in workspace\n');
        console_log('Fields in das_results:\n');
        fields = fieldnames(das_results);
        for i = 1:length(fields)
            console_log('  - %s\n', fields{i});
            
            % Check if this field has an error
            if isfield(das_results.(fields{i}), 'error')
                console_log('    ⚠ ERROR: %s\n', das_results.(fields{i}).error);
            end
        end
        
        % Specifically check for PT01a_Recovery_short
        if isfield(das_results, 'PT01a_Recovery_short')
            console_log('\n✓ PT01a_Recovery_short found in das_results\n');
            if isfield(das_results.PT01a_Recovery_short, 'error')
                console_log('  ⚠ But it has an error: %s\n', das_results.PT01a_Recovery_short.error);
            else
                console_log('  ✓ No errors - data looks good!\n');
            end
        else
            console_log('\n✗ PT01a_Recovery_short NOT found in das_results\n');
            console_log('Available fields: %s\n', strjoin(fields, ', '));
        end
    else
        console_log('✗ das_results does NOT exist in workspace\n');
    end
    
    console_log('\n\nSTEP 4: Checking head_results structure...\n');
    if exist('head_results', 'var')
        console_log('✓ head_results exists in workspace\n');
        console_log('Fields in head_results:\n');
        fields = fieldnames(head_results);
        for i = 1:length(fields)
            console_log('  - %s\n', fields{i});
        end
    else
        console_log('✗ head_results does NOT exist in workspace\n');
    end
    
catch ME
    console_log('\n✗ ERROR during correlation analysis:\n');
    console_log('  %s\n', ME.message);
    console_log('  Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

console_log('\n=== DEBUGGING COMPLETE ===\n');
