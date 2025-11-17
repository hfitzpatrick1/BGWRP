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
    error('No linear regression results found for %s!\nMake sure correlation analysis completed successfully.', test_name);
end

lr_results = das_results.(test_name).linear_regression;

%% Set up storage calculation configuration
storage_config.alpha = 0.9;  % Biot-Willis coefficient (0.9-1.0 for unconsolidated)
storage_config.gamma_unit = 'SI';  % Use SI units
storage_config.aquifer_thickness_ft = 380;  % PM07 Zone 5 thickness

% Traditional pump test value for comparison (PM07 Zone 5 from Aqtesolv)
storage_config.S_traditional = 0.002955;

%% Calculate specific storage
storage_results = calculate_specific_storage_becker(lr_results, storage_config);

%% Save results
das_results.(test_name).storage_becker = storage_results;

fprintf('\n=== RESULTS SAVED ===\n');
fprintf('Storage results saved to: das_results.%s.storage_becker\n', test_name);

%% Optional: Save to file
save_results = input('\nSave results to file? (y/n): ', 's');
if strcmpi(save_results, 'y')
    save_path = 'C:\Coding\BGWRP Lit Review\Thesis\storage_results.mat';
    save(save_path, 'storage_results', 'lr_results', 'storage_config');
    fprintf('Results saved to: %s\n', save_path);
end

%% Display summary
fprintf('\n========================================\n');
fprintf('SUMMARY: DAS-DERIVED STORAGE PARAMETERS\n');
fprintf('========================================\n');
fprintf('Method: Becker (2022) - Observation Well\n');
fprintf('Test: %s\n', test_name);
fprintf('Zone: %s\n', zone);
fprintf('Aquifer thickness: %.0f ft\n', storage_config.aquifer_thickness_ft);
fprintf('\n');
fprintf('RESULTS:\n');
fprintf('  S_s = %.4e 1/m\n', storage_results.S_s);
fprintf('  S   = %.4e (dimensionless)\n', storage_results.S);
fprintf('\n');
fprintf('COMPARISON:\n');
fprintf('  DAS-derived:  S = %.4e\n', storage_results.S);
fprintf('  Traditional:  S = %.4e\n', storage_config.S_traditional);
fprintf('  Ratio:           %.2f\n', storage_results.S / storage_config.S_traditional);
fprintf('\n');
fprintf('QUALITY:\n');
fprintf('  R² = %.4f\n', storage_results.R_squared);
fprintf('========================================\n');

