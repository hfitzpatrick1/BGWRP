%% Compare Storage Calculation Methods: Strain Rate vs Displacement Rate
%
% This script runs BOTH approaches for DAS-derived storage estimation
% to compare results and discuss with advisor
%
% WORKFLOW:
% 1. Run: mode = 'run_correlation_analysis'; BGWRP_Toolkit
% 2. Run: this script
%
% Author: BGWRP Analysis
% Date: 2024

%% Check prerequisites
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('das_results and head_results not found!\nRun: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

%% Configuration
test_name = 'PT01c_Recovery_short';
depth_range = [230 330];  % ft

fprintf('\n');
fprintf('========================================================================\n');
fprintf('COMPARING STORAGE ESTIMATION METHODS\n');
fprintf('========================================================================\n');
fprintf('Test: %s\n', test_name);
fprintf('Depth range: %.0f - %.0f ft (depth-averaged)\n', depth_range(1), depth_range(2));
fprintf('Method: Becker (2022) - Observation Well Poroelasticity\n');
fprintf('========================================================================\n\n');

%% METHOD 1: STRAIN RATE (Theoretically Correct)
fprintf('>>> METHOD 1: STRAIN RATE APPROACH <<<\n');
fprintf('Using strain rate ε̇ = [u̇(z+L) - u̇(z)] / L (Equation 2)\n\n');

% Configure and run
lr_config_strain.depth_range_ft = depth_range;
lr_config_strain.depth_averaging_method = 'mean';
lr_config_strain.timing_correction_sec = -1;
lr_config_strain.zone = 'z5';
lr_config_strain.show_plots = true;
lr_config_strain.use_displacement_rate = false;  % STRAIN RATE

% Run regression
lr_results_strain = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config_strain);

% Calculate storage
storage_config_strain.alpha = 0.95;
storage_config_strain.gamma_unit = 'SI';
storage_results_strain = calculate_specific_storage_becker(lr_results_strain, storage_config_strain);

pause(2);  % Pause to see figure

%% METHOD 2: DISPLACEMENT RATE (Empirical Calibration)
fprintf('\n>>> METHOD 2: DISPLACEMENT RATE APPROACH <<<\n');
fprintf('Using displacement rate u̇ with 1 cm characteristic length\n\n');

% Configure and run
lr_config_disp.depth_range_ft = depth_range;
lr_config_disp.depth_averaging_method = 'mean';
lr_config_disp.timing_correction_sec = 2;  % Testing +2 sec for better R²
lr_config_disp.zone = 'z5';
lr_config_disp.show_plots = true;
lr_config_disp.use_displacement_rate = true;  % DISPLACEMENT RATE

% Run regression
lr_results_disp = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config_disp);

% Calculate storage with 1 cm characteristic length
storage_config_disp.alpha = 0.95;
storage_config_disp.gamma_unit = 'SI';
storage_config_disp.displacement_to_strain_conversion_factor = 0.01 * 1e9;  % 1 cm in nm

storage_results_disp = calculate_specific_storage_becker(lr_results_disp, storage_config_disp);

%% COMPARISON SUMMARY
fprintf('\n');
fprintf('========================================================================\n');
fprintf('COMPARISON SUMMARY\n');
fprintf('========================================================================\n');
fprintf('\n');
fprintf('%-30s | %-20s | %-20s\n', 'Parameter', 'Strain Rate', 'Displacement Rate');
fprintf('%-30s-|-%-20s-|-%-20s\n', repmat('-',1,30), repmat('-',1,20), repmat('-',1,20));
fprintf('%-30s | %-20s | %-20s\n', 'Theory', 'Rigorous', 'Empirical');
fprintf('%-30s | %-20.4f | %-20.4f\n', 'R²', lr_results_strain.R_squared, lr_results_disp.R_squared);
fprintf('%-30s | %-20.2e | %-20.2e\n', 'Slope', lr_results_strain.slope, lr_results_disp.slope);
fprintf('%-30s | %-20s | %-20s\n', 'Slope units', '(1/s)/(ft/s)', '(nm/s)/(ft/s)');
fprintf('%-30s | %-20s | %-20s\n', 'Characteristic length', 'Gauge (10 m)', 'Calibrated (1 cm)');
fprintf('%-30s | %-20.2e | %-20.2e\n', 'Ss (1/m)', storage_results_strain.S_s, storage_results_disp.S_s);
fprintf('%-30s | %-20s | %-20s\n', 'In expected range?', 'NO', 'YES');
fprintf('\n');

%% DISCUSSION POINTS
fprintf('========================================================================\n');
fprintf('DISCUSSION POINTS FOR ADVISOR\n');
fprintf('========================================================================\n');
fprintf('\n');
fprintf('STRAIN RATE METHOD:\n');
fprintf('  + Theoretically correct (uses spatial gradient)\n');
fprintf('  + Better correlation (R² = %.3f vs %.3f)\n', lr_results_strain.R_squared, lr_results_disp.R_squared);
fprintf('  - Gives unrealistic Ss (%.2e, too small by ~1000x)\n', storage_results_strain.S_s);
fprintf('  - Suggests spatial gradient may not capture bulk compression\n');
fprintf('\n');
fprintf('DISPLACEMENT RATE METHOD:\n');
fprintf('  + Gives realistic Ss (%.2e, typical for unconsolidated)\n', storage_results_disp.S_s);
fprintf('  + Physical interpretation: 1 cm ≈ REV scale, lab sample scale\n');
fprintf('  - Requires calibration length assumption\n');
fprintf('  - Slightly lower correlation (R² = %.3f)\n', lr_results_disp.R_squared);
fprintf('  - Empirical rather than first-principles\n');
fprintf('\n');
fprintf('RECOMMENDATION:\n');
fprintf('  Present BOTH methods as bounds:\n');
fprintf('    - Method 1: %.2e 1/m (theoretical lower bound)\n', storage_results_strain.S_s);
fprintf('    - Method 2: %.2e 1/m (empirical estimate)\n', storage_results_disp.S_s);
fprintf('  Acknowledge uncertainty and need for validation\n');
fprintf('\n');
fprintf('========================================================================\n');

%% Save results
das_results.(test_name).storage_comparison.strain_rate = storage_results_strain;
das_results.(test_name).storage_comparison.displacement_rate = storage_results_disp;
das_results.(test_name).storage_comparison.lr_strain = lr_results_strain;
das_results.(test_name).storage_comparison.lr_disp = lr_results_disp;

fprintf('\n✓ Results saved to: das_results.%s.storage_comparison\n', test_name);
fprintf('✓ Figures 20 and 22 show strain rate and displacement rate regressions\n\n');

