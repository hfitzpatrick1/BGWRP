%% Calculate Specific Storage from Linear Regression Results (Becker Method)
%
% This script applies the Becker (2022) simplified poroelasticity approach
% for observation wells where the Darcy flux term is negligible:
%
%   α (∂ε/∂t) + S_ε γ (∂h/∂t) = 0
%
% Solving for: S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)]
%
% WORKFLOW:
% 1. Run: mode = 'run_correlation_analysis'; BGWRP_Toolkit
% 2. Run: this script


%% Check if results exist
if ~exist('das_results', 'var')
    error('No das_results found! Run correlation analysis first:\n  mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

%% Configuration
test_name = 'PT01c_Recovery_short';
zone = 'z5';

% Check if linear regression results exist
if ~isfield(das_results, test_name) || ~isfield(das_results.(test_name), 'linear_regression')
    console_log('Linear regression results not found. Running linear regression now...\n');
    
    % Check if head_results exists
    if ~exist('head_results', 'var')
        error('No head_results found! Run correlation analysis first:\n  mode = ''run_correlation_analysis''; BGWRP_Toolkit');
    end
    
    % Run linear regression
    lr_config = struct();
    lr_config.zone = zone;
    % Use middle of screened zone: 260-310 ft -> center at 285 ft
    lr_config.depth_range_ft = [284.5, 285.5];  % Center of 260-310 ft screened zone
    lr_config.depth_averaging_method = 'representative';
    lr_config.use_amplitude = true;
    lr_config.use_displacement_rate = false;  % Use strain rate
    
    console_log('Running linear regression for %s (zone %s)...\n', test_name, zone);
    lr_results = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config);
    
    % Store results in das_results
    das_results.(test_name).linear_regression = lr_results;
    console_log('✓ Linear regression complete (R=%.3f, R²=%.3f)\n', lr_results.R, lr_results.R_squared);
else
    lr_results = das_results.(test_name).linear_regression;
    console_log('Using existing linear regression results (R=%.3f, R²=%.3f)\n', lr_results.R, lr_results.R_squared);
end

%% Set up storage calculation configuration
storage_config.alpha = 0.9;  % Biot-Willis coefficient (0.9-1.0 for unconsolidated)
storage_config.gamma_unit = 'SI';  % Use SI units
storage_config.aquifer_thickness_ft = 380;  % PM07 Zone 5 thickness

% No characteristic length scaling (advisor doesn't use it)
% storage_config.strain_rate_characteristic_length_m = 1.0;  % Disabled
storage_config.poisson_ratio = 0.30;  % Typical for sand/sandstone

% Traditional pump test value for comparison (PM07 Zone 5 from Aqtesolv)
storage_config.S_traditional = 0.002955;

%% Calculate specific storage
storage_results = calculate_specific_storage_becker(lr_results, storage_config);

%% Save results
das_results.(test_name).storage_becker = storage_results;

console_log('\n=== RESULTS SAVED ===\n');
console_log('Storage results saved to: das_results.%s.storage_becker\n', test_name);

%% Optional: Save to file
save_results = input('\nSave results to file? (y/n): ', 's');
if strcmpi(save_results, 'y')
    save_path = 'C:\Coding\BGWRP Lit Review\Thesis\storage_results.mat';
    save(save_path, 'storage_results', 'lr_results', 'storage_config');
    console_log('Results saved to: %s\n', save_path);
end

%% Display summary
console_log('\n========================================\n');
console_log('SUMMARY: DAS-DERIVED STORAGE PARAMETERS\n');
console_log('========================================\n');
console_log('Method: Becker (2022) - Observation Well\n');
console_log('Test: %s\n', test_name);
console_log('Zone: %s\n', zone);
console_log('Aquifer thickness: %.0f ft\n', storage_config.aquifer_thickness_ft);
console_log('\n');
console_log('RESULTS:\n');
console_log('  S_s = %.4e 1/m\n', storage_results.S_s);
console_log('  S   = %.4e (dimensionless)\n', storage_results.S);
console_log('\n');
console_log('COMPARISON:\n');
console_log('  DAS-derived:  S = %.4e\n', storage_results.S);
console_log('  Traditional:  S = %.4e\n', storage_config.S_traditional);
console_log('  Ratio:           %.2f\n', storage_results.S / storage_config.S_traditional);
console_log('\n');
console_log('QUALITY:\n');
console_log('  R² = %.4f\n', storage_results.R_squared);
console_log('========================================\n');

