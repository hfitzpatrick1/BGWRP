% Diagnostic: Check what values linear regression is actually using
clear all; close all; clc;
cd('C:\Coding\BGWRP\src')

% Load the DAS results that linear regression will use
% This mimics what happens in BGWRP_Toolkit.m
test_name = 'PT01c_Recovery_short';
das_mat_file = fullfile('C:\Coding\BGWRP\results\PT01c_Recovery_short', 'das_results_filtered.mat');

if ~exist(das_mat_file, 'file')
    error('DAS results file not found! Run correlation analysis first.');
end

loaded = load(das_mat_file);
das_results = loaded.das_results;

if ~isfield(das_results, test_name)
    error('Test %s not found in das_results', test_name);
end

das_filtered = das_results.(test_name);

console_log('=== DIAGNOSTIC: What data is linear regression actually using? ===\n\n');

% Check if smoothed_data exists
if isfield(das_filtered, 'smoothed_data')
    displacement_rate_full = das_filtered.smoothed_data;
    console_log('✓ smoothed_data found: [%d time × %d channels]\n', size(displacement_rate_full, 1), size(displacement_rate_full, 2));
    
    % Check channel 341 (280 ft depth)
    channel_idx = 341;
    if channel_idx <= size(displacement_rate_full, 2)
        displacement_at_ch = displacement_rate_full(:, channel_idx);
        
        console_log('\n=== Channel %d (280 ft) displacement rate values ===\n', channel_idx);
        console_log('  Min: %.6f\n', min(displacement_at_ch));
        console_log('  Max: %.6f\n', max(displacement_at_ch));
        console_log('  Mean: %.6f\n', mean(displacement_at_ch));
        console_log('  Range: %.6f\n', max(displacement_at_ch) - min(displacement_at_ch));
        
        % Calculate what strain rate would be
        gauge_length_m = 10;
        strain_rate = displacement_at_ch / (gauge_length_m * 1e9);
        
        console_log('\n=== Calculated strain rate (what linear regression will show) ===\n');
        console_log('  Formula: strain_rate = displacement / (10m × 1e9 nm/m)\n');
        console_log('  Displacement range: %.2e to %.2e nm/s\n', min(displacement_at_ch), max(displacement_at_ch));
        console_log('  Strain rate range: %.2e to %.2e 1/s\n', min(strain_rate), max(strain_rate));
        
        % Check order of magnitude
        max_strain = max(abs(strain_rate));
        if max_strain > 1e-9
            console_log('  ❌ WARNING: Strain rate is e^-9 or larger (TOO HIGH!)\n');
        elseif max_strain > 1e-10 && max_strain <= 1e-9
            console_log('  ✓ Strain rate is e^-10 order (CORRECT!)\n');
        elseif max_strain > 1e-11 && max_strain <= 1e-10
            console_log('  ⚠ Strain rate is e^-11 order (10x too small)\n');
        elseif max_strain <= 1e-11
            console_log('  ❌ Strain rate is e^-12 or smaller (100x too small!)\n');
        end
        
        % Check if this looks like corrected or uncorrected data
        if abs(mean(displacement_at_ch)) < 0.1
            console_log('\n  ❌ Displacement values < 0.1 nm/s → data NOT corrected!\n');
            console_log('     Expected ~3 nm/s for corrected data\n');
            console_log('     ACTION: Re-run correlation analysis to apply correction\n');
        else
            console_log('\n  ✓ Displacement values ~%.1f nm/s → data appears corrected!\n', abs(mean(displacement_at_ch)));
        end
    end
else
    console_log('❌ smoothed_data NOT found in das_filtered!\n');
    console_log('   Available fields: %s\n', strjoin(fieldnames(das_filtered), ', '));
end

% Check if smoothing info is stored
if isfield(das_filtered, 'smoothing_method')
    console_log('\nSmoothing method: %s\n', das_filtered.smoothing_method);
    if isfield(das_filtered, 'smoothing_window')
        console_log('Smoothing window: %d samples\n', das_filtered.smoothing_window);
    end
else
    console_log('\n⚠ No smoothing method info stored\n');
end

console_log('\n=== END DIAGNOSTIC ===\n');
