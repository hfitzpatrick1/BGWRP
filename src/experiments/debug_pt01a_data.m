%% Debug PT01a Data Availability
% This script checks if PT01a data exists and what fields are in das_results

clear; clc;
fprintf('=== DEBUGGING PT01a DATA ===\n\n');

%% Step 1: Check if data files exist
fprintf('STEP 1: Checking for PT01a data files...\n');
base_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short';

% Check _das directory
das_dir = fullfile(base_path, '_das');
if exist(das_dir, 'dir')
    fprintf('✓ _das directory exists: %s\n', das_dir);
    mat_files = dir(fullfile(das_dir, '*.mat'));
    if ~isempty(mat_files)
        fprintf('  Found %d MAT file(s):\n', length(mat_files));
        for i = 1:length(mat_files)
            fprintf('    %s\n', mat_files(i).name);
        end
    else
        fprintf('  ✗ No MAT files found!\n');
    end
else
    fprintf('✗ _das directory NOT found: %s\n', das_dir);
end

% Check _das_timing directory
timing_dir = fullfile(base_path, '_das_timing');
if exist(timing_dir, 'dir')
    fprintf('✓ _das_timing directory exists: %s\n', timing_dir);
    m_files = dir(fullfile(timing_dir, '*.m'));
    if ~isempty(m_files)
        fprintf('  Found %d timing config(s):\n', length(m_files));
        for i = 1:length(m_files)
            fprintf('    %s\n', m_files(i).name);
        end
    else
        fprintf('  ✗ No timing config files found!\n');
    end
else
    fprintf('✗ _das_timing directory NOT found: %s\n', timing_dir);
end

% Check _head directory
head_dir = fullfile(base_path, '_head');
if exist(head_dir, 'dir')
    fprintf('✓ _head directory exists: %s\n', head_dir);
    head_files = dir(fullfile(head_dir, '*.mat'));
    if ~isempty(head_files)
        fprintf('  Found %d head data file(s):\n', length(head_files));
        for i = 1:length(head_files)
            fprintf('    %s\n', head_files(i).name);
        end
    else
        fprintf('  ✗ No head data files found!\n');
    end
else
    fprintf('✗ _head directory NOT found: %s\n', head_dir);
end

%% Step 2: Try running correlation analysis
fprintf('\n\nSTEP 2: Running correlation analysis to check das_results...\n');
addpath(genpath('src'));

try
    mode = 'run_correlation_analysis';
    BGWRP_Toolkit;
    
    fprintf('\n\nSTEP 3: Checking das_results structure...\n');
    if exist('das_results', 'var')
        fprintf('✓ das_results exists in workspace\n');
        fprintf('Fields in das_results:\n');
        fields = fieldnames(das_results);
        for i = 1:length(fields)
            fprintf('  - %s\n', fields{i});
            
            % Check if this field has an error
            if isfield(das_results.(fields{i}), 'error')
                fprintf('    ⚠ ERROR: %s\n', das_results.(fields{i}).error);
            end
        end
        
        % Specifically check for PT01a_Recovery_short
        if isfield(das_results, 'PT01a_Recovery_short')
            fprintf('\n✓ PT01a_Recovery_short found in das_results\n');
            if isfield(das_results.PT01a_Recovery_short, 'error')
                fprintf('  ⚠ But it has an error: %s\n', das_results.PT01a_Recovery_short.error);
            else
                fprintf('  ✓ No errors - data looks good!\n');
            end
        else
            fprintf('\n✗ PT01a_Recovery_short NOT found in das_results\n');
            fprintf('Available fields: %s\n', strjoin(fields, ', '));
        end
    else
        fprintf('✗ das_results does NOT exist in workspace\n');
    end
    
    fprintf('\n\nSTEP 4: Checking head_results structure...\n');
    if exist('head_results', 'var')
        fprintf('✓ head_results exists in workspace\n');
        fprintf('Fields in head_results:\n');
        fields = fieldnames(head_results);
        for i = 1:length(fields)
            fprintf('  - %s\n', fields{i});
        end
    else
        fprintf('✗ head_results does NOT exist in workspace\n');
    end
    
catch ME
    fprintf('\n✗ ERROR during correlation analysis:\n');
    fprintf('  %s\n', ME.message);
    fprintf('  Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

fprintf('\n=== DEBUGGING COMPLETE ===\n');
