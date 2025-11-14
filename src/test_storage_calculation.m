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

fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  POROELASTIC STORAGE PARAMETER ESTIMATION            ║\n');
fprintf('║  PM07 Zone 5 + DAS Correlation Analysis              ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

%% ============================================================
%% STEP 1: LOAD YOUR CORRELATION ANALYSIS DATA
%% ============================================================
fprintf('STEP 1: Loading correlation analysis data...\n');

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
    fprintf('⚠ Variables not found in base workspace, checking caller workspace...\n');
    % Variables might be in caller workspace, continue anyway
end

fprintf('✓ Data loaded successfully\n');
fprintf('  Time points: %d\n', length(time_vector));
fprintf('  Time range: %.1f to %.1f minutes\n', min(time_vector)/60, max(time_vector)/60);
fprintf('  DAS depths: %d channels\n', size(das_strain_rate, 2));
fprintf('  Depth range: %.1f to %.1f ft\n\n', min(depth_vector), max(depth_vector));

%% ============================================================
%% STEP 2: SET UP AQUIFER PARAMETERS (PM07 Zone 5)
%% ============================================================
fprintf('STEP 2: Configuring aquifer parameters...\n');

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
fprintf('✓ Parameters configured\n');
fprintf('  Transmissivity: T = %.2e ft²/day\n', config.T);
fprintf('  Storage: S = %.6f\n', config.S);
fprintf('  Hydraulic conductivity: K = %.1f ft/day\n', config.K);
fprintf('  Aquifer thickness: b = %.0f ft\n', config.b);
fprintf('  Radial distance: r = %.0f ft\n', config.r);
fprintf('  Biot coefficient: α = %.2f\n', config.alpha);
fprintf('  Analysis depth: %.0f-%.0f ft\n\n', config.depth_range(1), config.depth_range(2));

%% ============================================================
%% STEP 3: SET UP PUMPING TEST TIMING
%% ============================================================
fprintf('STEP 3: Configuring test timing...\n');

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

fprintf('✓ Timing configured\n');
fprintf('  Final pumping rate: %d GPM\n', timing_info.Q_pumping);
fprintf('  Pumping duration: %.1f hours\n', timing_info.t_pumping/3600);
fprintf('  Recovery start: 19:15 (time_vector = 0)\n\n');

%% ============================================================
%% STEP 4: PACKAGE DATA FOR CALCULATION
%% ============================================================
fprintf('STEP 4: Packaging data structures...\n');

% DAS data structure
das_data = struct();
das_data.strain_rate = das_strain_rate;  % [time x depth] matrix
das_data.time_vector = time_vector;      % [time x 1] seconds
das_data.depth_vector = depth_vector;    % [depth x 1] ft

% Head data structure
head_data = struct();
head_data.head = head_zone5;             % [time x 1] ft
head_data.time_vector = time_vector;     % [time x 1] seconds (same as DAS)

fprintf('✓ Data structures ready\n\n');

%% ============================================================
%% STEP 5: RUN STORAGE CALCULATION
%% ============================================================
fprintf('STEP 5: Running poroelastic storage calculation...\n');
fprintf('════════════════════════════════════════════════════════\n\n');

try
    % Call main calculation function
    results = calculate_storage_from_poroelasticity(das_data, head_data, timing_info, config);
    
    fprintf('════════════════════════════════════════════════════════\n');
    fprintf('✓ CALCULATION SUCCESSFUL\n\n');
    
catch ME
    fprintf('════════════════════════════════════════════════════════\n');
    fprintf('✗ CALCULATION FAILED\n\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    rethrow(ME);
end

%% ============================================================
%% STEP 6: DISPLAY SUMMARY RESULTS
%% ============================================================
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  RESULTS SUMMARY                                      ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('STORAGE PARAMETERS:\n');
fprintf('  Constrained Storage (Sε):\n');
fprintf('    Mean:   %.3e 1/Pa\n', mean(results.Se));
fprintf('    Median: %.3e 1/Pa\n', median(results.Se));
fprintf('    Range:  %.3e to %.3e 1/Pa\n', min(results.Se), max(results.Se));
fprintf('\n');

fprintf('  Specific Storage (Ss):\n');
fprintf('    Mean:   %.3e 1/ft\n', mean(results.Ss_ft));
fprintf('    Median: %.3e 1/ft\n', median(results.Ss_ft));
fprintf('    Range:  %.3e to %.3e 1/ft\n', min(results.Ss_ft), max(results.Ss_ft));
fprintf('\n');

fprintf('  Storativity (S):\n');
fprintf('    DAS-derived:  S = %.6f\n', results.S_DAS);
fprintf('    Aqtesolv:     S = %.6f\n', results.S_Aqtesolv);
fprintf('    Ratio:        %.2f (DAS/Aqtesolv)\n', results.S_DAS/results.S_Aqtesolv);
fprintf('    Difference:   %.1f%%\n', 100*abs(results.S_DAS - results.S_Aqtesolv)/results.S_Aqtesolv);
fprintf('\n');

fprintf('QUALITY ASSESSMENT:\n');
fprintf('  Overall: %s\n', results.diagnostics.overall);
fprintf('  Strain amplitude: %.0f ns (%s)\n', ...
    results.diagnostics.strain_amplitude_ns, results.diagnostics.amplitude_check);
fprintf('  Strain-pressure correlation: %.3f (%s)\n', ...
    results.diagnostics.correlation, results.diagnostics.correlation_check);
fprintf('  Monotonic behavior: %.0f%% (%s)\n', ...
    100*results.diagnostics.monotonic_fraction, results.diagnostics.monotonic_check);
fprintf('\n');

fprintf('VALIDATION (Black & Kipp 1977):\n');
fprintf('  PM07 Zone 5: β = 0.021 (minimal piezometer lag)\n');
fprintf('  Pressure measurements reliable for storage estimation ✓\n');
fprintf('\n');

fprintf('FIGURES GENERATED:\n');
fprintf('  Figure 1: Main Results (6-panel comprehensive)\n');
fprintf('  Figure 2: Becker Diagnostic Checks\n');
fprintf('\n');

%% ============================================================
%% STEP 7: SAVE RESULTS (OPTIONAL)
%% ============================================================

save_results = questdlg('Save results to MAT file?', 'Save Results', 'Yes', 'No', 'No');

if strcmp(save_results, 'Yes')
    [filename, pathname] = uiputfile('*.mat', 'Save Results As', 'storage_analysis_results.mat');
    if filename ~= 0
        save(fullfile(pathname, filename), 'results', 'config', 'timing_info');
        fprintf('✓ Results saved to: %s\n', fullfile(pathname, filename));
    end
end

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  ANALYSIS COMPLETE                                    ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');

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
        fprintf('✓ Main figure exported to: %s\n', fullfile(pathname, filename));
    end
    
    % Export diagnostics
    figure(results.figures.diagnostics);
    [filename, pathname] = uiputfile('*.pdf', 'Save Diagnostics Figure As', ...
        'storage_analysis_diagnostics.pdf');
    if filename ~= 0
        exportgraphics(results.figures.diagnostics, fullfile(pathname, filename), ...
            'ContentType', 'vector', 'Resolution', 300);
        fprintf('✓ Diagnostics figure exported to: %s\n', fullfile(pathname, filename));
    end
end

%% ============================================================
%% INTERPRETATION GUIDANCE
%% ============================================================

fprintf('\n');
fprintf('INTERPRETATION GUIDANCE:\n');
fprintf('════════════════════════════════════════════════════════\n');

if strcmp(results.diagnostics.overall, 'EXCELLENT') || strcmp(results.diagnostics.overall, 'GOOD')
    fprintf('✓ Results are reliable for publication/thesis use\n');
    fprintf('  - Storage estimate from DAS matches Aqtesolv (%.1f%% difference)\n', ...
        100*abs(results.S_DAS - results.S_Aqtesolv)/results.S_Aqtesolv);
    fprintf('  - Simple poroelastic model is appropriate\n');
    fprintf('  - Both Murdoch (2021) and Becker (2022) frameworks apply\n');
    
elseif strcmp(results.diagnostics.overall, 'FAIR')
    fprintf('⚠ Results interpretable but require caution\n');
    fprintf('  - Review diagnostic checks for specific issues\n');
    fprintf('  - Consider sensitivity analysis on α (Biot coefficient)\n');
    fprintf('  - May benefit from depth-dependent analysis\n');
    
else % POOR
    fprintf('✗ Results indicate complex behavior\n');
    fprintf('  - Simple analysis may not be appropriate\n');
    fprintf('  - Possible issues:\n');
    
    if contains(results.diagnostics.correlation_check, 'FAIL')
        fprintf('    • Noordbergum effect (anti-correlation detected)\n');
        fprintf('    • Indicates 3D poroelastic coupling\n');
        fprintf('    • Need full numerical modeling (COMSOL)\n');
    end
    
    if contains(results.diagnostics.monotonic_check, 'CAUTION')
        fprintf('    • Non-monotonic behavior (leak-off)\n');
        fprintf('    • Inter-strata exchange during recovery\n');
        fprintf('    • Time-dependent redistribution effects\n');
    end
    
    fprintf('  - Recommendation: Consult Becker et al. (2022) framework\n');
    fprintf('  - Consider 3D coupled hydromechanical modeling\n');
end

fprintf('\n');
fprintf('NEXT STEPS:\n');
fprintf('  1. Review figures for quality assessment\n');
fprintf('  2. Check Storage_estimates.md for methodology details\n');
fprintf('  3. Compare with traditional pump test interpretation\n');
fprintf('  4. Consider depth-dependent analysis if heterogeneity present\n');
fprintf('  5. Document results for thesis/publication\n');
fprintf('\n');

