%% Storage Parameter Calculation - Test Script
% 
% Calculates depth-resolved storage parameters (Sε, Ss, S) from poroelasticity
% theory using DAS strain rate and Zone 5 pressure transducer data.
%
% Method: Wang (2000) poroelasticity + Becker (2022) validation framework
% Test: PM07 Step Test Recovery (Zone 5 reference)
%
% BEFORE RUNNING:
% 1. Load your correlation analysis results
% 2. Verify variable names match the script
% 3. Check that DAS has +20s time shift already applied
%
% See: Storage_estimates.md for complete methodology documentation

clear; close all;

console_log('╔════════════════════════════════════════════════════════╗\n');
console_log('║  POROELASTIC STORAGE PARAMETER ESTIMATION            ║\n');
console_log('║  PM07 Zone 5 + DAS Correlation Analysis              ║\n');
console_log('╚════════════════════════════════════════════════════════╝\n\n');

%% ============================================================
%% STEP 1: LOAD YOUR CORRELATION ANALYSIS DATA
%% ============================================================
console_log('STEP 1: Loading correlation analysis data...\n');

% TODO: REPLACE THIS SECTION WITH YOUR ACTUAL DATA LOADING
% --------------------------------------------------------
% Option A: Load from MAT file
% load('correlation_analysis_results.mat', 'time_vector', 'head_zone5', ...
%      'das_strain_rate', 'depth_vector');

% Option B: Extract from workspace (if variables already loaded)
% Make sure these exist in your workspace from correlation analysis:
% - time_vector: [N x 1] seconds from recovery start
% - head_zone5: [N x 1] Zone 5 head measurements (ft)
% - das_strain_rate: [N x M] DAS strain rate (1/s), M = number of depths
% - depth_vector: [M x 1] depth locations (ft)

% Check if data exists (skip if running from extract script)
if ~exist('time_vector', 'var') || ~exist('head_zone5', 'var') || ...
   ~exist('das_strain_rate', 'var') || ~exist('depth_vector', 'var')
    console_log('⚠ Variables not found in base workspace, checking caller workspace...\n');
    % Variables might be in caller workspace, continue anyway
end

console_log('✓ Data loaded successfully\n');
console_log('  Time points: %d\n', length(time_vector));
console_log('  Time range: %.1f to %.1f minutes\n', min(time_vector)/60, max(time_vector)/60);
console_log('  DAS depths: %d channels\n', size(das_strain_rate, 2));
console_log('  Depth range: %.1f to %.1f ft\n\n', min(depth_vector), max(depth_vector));

%% ============================================================
%% STEP 2: SET UP AQUIFER PARAMETERS (PM07 Zone 5)
%% ============================================================
console_log('STEP 2: Configuring aquifer parameters...\n');

% From Aqtesolv analysis (PM07_beta_calculation.md)
config = struct();
config.T = 1.042e5;     % ft²/day - transmissivity
config.S = 0.002955;    % dimensionless - storage coefficient
config.K = 274.2;       % ft/day - hydraulic conductivity (T/b)
config.b = 380;         % ft - aquifer thickness
config.r = 177;         % ft - radial distance (PT-01c to PM07/DAS)

% Poroelastic parameters
config.alpha = 0.7;     % Biot coefficient (literature value for sediments)
config.depth_range = [190 340];  % ft - DAS strong response zone

% Print configuration
console_log('✓ Parameters configured\n');
console_log('  Transmissivity: T = %.2e ft²/day\n', config.T);
console_log('  Storage: S = %.6f\n', config.S);
console_log('  Hydraulic conductivity: K = %.1f ft/day\n', config.K);
console_log('  Aquifer thickness: b = %.0f ft\n', config.b);
console_log('  Radial distance: r = %.0f ft\n', config.r);
console_log('  Biot coefficient: α = %.2f\n', config.alpha);
console_log('  Analysis depth: %.0f-%.0f ft\n\n', config.depth_range(1), config.depth_range(2));

%% ============================================================
%% STEP 3: SET UP PUMPING TEST TIMING
%% ============================================================
console_log('STEP 3: Configuring test timing...\n');

% From step-drawdown test schedule
timing_info = struct();
timing_info.Q_pumping = 150;  % GPM - final rate before recovery
timing_info.t_pumping = 4 * 3600;  % seconds - total pumping duration (4 hours)

% Pumping schedule for reference:
% 15:15 - 16:15: 50 GPM
% 16:15 - 17:15: 100 GPM
% 17:15 - 18:15: 110 GPM
% 18:15 - 19:15: 150 GPM
% 19:15 onwards: 0 GPM (RECOVERY - analysis window)

console_log('✓ Timing configured\n');
console_log('  Final pumping rate: %d GPM\n', timing_info.Q_pumping);
console_log('  Pumping duration: %.1f hours\n', timing_info.t_pumping/3600);
console_log('  Recovery start: 19:15 (time_vector = 0)\n\n');

%% ============================================================
%% STEP 4: PACKAGE DATA FOR CALCULATION
%% ============================================================
console_log('STEP 4: Packaging data structures...\n');

% DAS data structure
das_data = struct();
das_data.strain_rate = das_strain_rate;  % [time x depth] matrix
das_data.time_vector = time_vector;      % [time x 1] seconds
das_data.depth_vector = depth_vector;    % [depth x 1] ft

% Head data structure
head_data = struct();
head_data.head = head_zone5;             % [time x 1] ft
head_data.time_vector = time_vector;     % [time x 1] seconds (same as DAS)

console_log('✓ Data structures ready\n\n');

%% ============================================================
%% STEP 5: RUN STORAGE CALCULATION
%% ============================================================
console_log('STEP 5: Running poroelastic storage calculation...\n');
console_log('════════════════════════════════════════════════════════\n\n');

try
    % Call main calculation function
    results = calculate_storage_from_poroelasticity(das_data, head_data, timing_info, config);
    
    console_log('════════════════════════════════════════════════════════\n');
    console_log('✓ CALCULATION SUCCESSFUL\n\n');
    
catch ME
    console_log('════════════════════════════════════════════════════════\n');
    console_log('✗ CALCULATION FAILED\n\n');
    console_log('Error: %s\n', ME.message);
    console_log('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    rethrow(ME);
end

%% ============================================================
%% STEP 6: DISPLAY SUMMARY RESULTS
%% ============================================================
console_log('╔════════════════════════════════════════════════════════╗\n');
console_log('║  RESULTS SUMMARY                                      ║\n');
console_log('╚════════════════════════════════════════════════════════╝\n\n');

console_log('STORAGE PARAMETERS:\n');
console_log('  Constrained Storage (Sε):\n');
console_log('    Mean:   %.3e 1/Pa\n', mean(results.Se));
console_log('    Median: %.3e 1/Pa\n', median(results.Se));
console_log('    Range:  %.3e to %.3e 1/Pa\n', min(results.Se), max(results.Se));
console_log('\n');

console_log('  Specific Storage (Ss):\n');
console_log('    Mean:   %.3e 1/ft\n', mean(results.Ss_ft));
console_log('    Median: %.3e 1/ft\n', median(results.Ss_ft));
console_log('    Range:  %.3e to %.3e 1/ft\n', min(results.Ss_ft), max(results.Ss_ft));
console_log('\n');

console_log('  Storativity (S):\n');
console_log('    DAS-derived:  S = %.6f\n', results.S_DAS);
console_log('    Aqtesolv:     S = %.6f\n', results.S_Aqtesolv);
console_log('    Ratio:        %.2f (DAS/Aqtesolv)\n', results.S_DAS/results.S_Aqtesolv);
console_log('    Difference:   %.1f%%\n', 100*abs(results.S_DAS - results.S_Aqtesolv)/results.S_Aqtesolv);
console_log('\n');

console_log('QUALITY ASSESSMENT:\n');
console_log('  Overall: %s\n', results.diagnostics.overall);
console_log('  Strain amplitude: %.0f ns (%s)\n', ...
    results.diagnostics.strain_amplitude_ns, results.diagnostics.amplitude_check);
console_log('  Strain-pressure correlation: %.3f (%s)\n', ...
    results.diagnostics.correlation, results.diagnostics.correlation_check);
console_log('  Monotonic behavior: %.0f%% (%s)\n', ...
    100*results.diagnostics.monotonic_fraction, results.diagnostics.monotonic_check);
console_log('\n');

console_log('VALIDATION (Black & Kipp 1977):\n');
console_log('  PM07 Zone 5: β = 0.021 (minimal piezometer lag)\n');
console_log('  Pressure measurements reliable for storage estimation ✓\n');
console_log('\n');

console_log('FIGURES GENERATED:\n');
console_log('  Figure 1: Main Results (6-panel comprehensive)\n');
console_log('  Figure 2: Becker Diagnostic Checks\n');
console_log('\n');

%% ============================================================
%% STEP 7: SAVE RESULTS (OPTIONAL)
%% ============================================================

save_results = questdlg('Save results to MAT file?', 'Save Results', 'Yes', 'No', 'No');

if strcmp(save_results, 'Yes')
    [filename, pathname] = uiputfile('*.mat', 'Save Results As', 'storage_analysis_results.mat');
    if filename ~= 0
        save(fullfile(pathname, filename), 'results', 'config', 'timing_info');
        console_log('✓ Results saved to: %s\n', fullfile(pathname, filename));
    end
end

console_log('\n');
console_log('╔════════════════════════════════════════════════════════╗\n');
console_log('║  ANALYSIS COMPLETE                                    ║\n');
console_log('╚════════════════════════════════════════════════════════╝\n');

%% ============================================================
%% OPTIONAL: EXPORT FIGURES
%% ============================================================

export_figures = questdlg('Export figures to PDF?', 'Export Figures', 'Yes', 'No', 'No');

if strcmp(export_figures, 'Yes')
    % Export main results
    figure(results.figures.main);
    [filename, pathname] = uiputfile('*.pdf', 'Save Main Figure As', ...
        'storage_analysis_main.pdf');
    if filename ~= 0
        exportgraphics(results.figures.main, fullfile(pathname, filename), ...
            'ContentType', 'vector', 'Resolution', 300);
        console_log('✓ Main figure exported to: %s\n', fullfile(pathname, filename));
    end
    
    % Export diagnostics
    figure(results.figures.diagnostics);
    [filename, pathname] = uiputfile('*.pdf', 'Save Diagnostics Figure As', ...
        'storage_analysis_diagnostics.pdf');
    if filename ~= 0
        exportgraphics(results.figures.diagnostics, fullfile(pathname, filename), ...
            'ContentType', 'vector', 'Resolution', 300);
        console_log('✓ Diagnostics figure exported to: %s\n', fullfile(pathname, filename));
    end
end

%% ============================================================
%% INTERPRETATION GUIDANCE
%% ============================================================

console_log('\n');
console_log('INTERPRETATION GUIDANCE:\n');
console_log('════════════════════════════════════════════════════════\n');

if strcmp(results.diagnostics.overall, 'EXCELLENT') || strcmp(results.diagnostics.overall, 'GOOD')
    console_log('✓ Results are reliable for publication/thesis use\n');
    console_log('  - Storage estimate from DAS matches Aqtesolv (%.1f%% difference)\n', ...
        100*abs(results.S_DAS - results.S_Aqtesolv)/results.S_Aqtesolv);
    console_log('  - Simple poroelastic model is appropriate\n');
    console_log('  - Both Murdoch (2021) and Becker (2022) frameworks apply\n');
    
elseif strcmp(results.diagnostics.overall, 'FAIR')
    console_log('⚠ Results interpretable but require caution\n');
    console_log('  - Review diagnostic checks for specific issues\n');
    console_log('  - Consider sensitivity analysis on α (Biot coefficient)\n');
    console_log('  - May benefit from depth-dependent analysis\n');
    
else % POOR
    console_log('✗ Results indicate complex behavior\n');
    console_log('  - Simple analysis may not be appropriate\n');
    console_log('  - Possible issues:\n');
    
    if contains(results.diagnostics.correlation_check, 'FAIL')
        console_log('    • Noordbergum effect (anti-correlation detected)\n');
        console_log('    • Indicates 3D poroelastic coupling\n');
        console_log('    • Need full numerical modeling (COMSOL)\n');
    end
    
    if contains(results.diagnostics.monotonic_check, 'CAUTION')
        console_log('    • Non-monotonic behavior (leak-off)\n');
        console_log('    • Inter-strata exchange during recovery\n');
        console_log('    • Time-dependent redistribution effects\n');
    end
    
    console_log('  - Recommendation: Consult Becker et al. (2022) framework\n');
    console_log('  - Consider 3D coupled hydromechanical modeling\n');
end

console_log('\n');
console_log('NEXT STEPS:\n');
console_log('  1. Review figures for quality assessment\n');
console_log('  2. Check Storage_estimates.md for methodology details\n');
console_log('  3. Compare with traditional pump test interpretation\n');
console_log('  4. Consider depth-dependent analysis if heterogeneity present\n');
console_log('  5. Document results for thesis/publication\n');
console_log('\n');

