function storage_results = calculate_specific_storage_becker(lr_results, config)
%CALCULATE_SPECIFIC_STORAGE_BECKER Calculate specific storage using Becker (2022) approach
%
% This applies the simplified poroelasticity equation at an observation well
% where the Darcy flux term is negligible:
%
%   α (∂ε/∂t) + S_ε γ (∂h/∂t) = 0
%
% Solving for S_ε:
%   S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)]
%
% NOTE: Linear regression can use either:
%   - HEAD rate (∂h/∂t): slope = (∂ε/∂t) / (∂h/∂t)
%     Then: S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)] = -α × slope / γ
%   - DRAWDOWN rate (∂s/∂t): slope = (∂ε/∂t) / (∂s/∂t)
%     Since ∂h/∂t = -∂s/∂t: S_ε = -α (∂ε/∂t) / [γ (-∂s/∂t)] = +α × slope / γ
%
% Function checks for head_rate first, then uses drawdown_rate if not available
%
% Inputs:
%   lr_results - Linear regression results structure with fields:
%                .slope - Regression slope (strain_rate / drawdown_rate)
%                .R - Correlation coefficient
%                .strain_rate - Strain rate data (1/s)
%                .drawdown_rate - Drawdown rate (ft/s)
%   config - Configuration structure with fields:
%            .alpha - Biot-Willis coefficient (default: 0.95 for clean sand/gravelly sand)
%            .gamma_unit - 'SI' or 'imperial' (default: 'SI')
%            .displacement_to_strain_conversion_factor - Custom conversion factor (NOT RECOMMENDED - use strain rate instead)
%
% Outputs:
%   storage_results - Structure containing:
%                    .S_epsilon - Strain-constrained specific storage (1/Pa or 1/psf)
%                    .S_s - Specific storage (1/m or 1/ft)
%                    .alpha - Biot-Willis coefficient used
%                    .gamma - Specific weight used
%                    .slope_raw - Original slope (1/s per ft/s)
%                    .slope_converted - Slope in consistent units
%                    .R - Correlation coefficient
%                    .R_squared - R^2

%% Set defaults
if ~isfield(config, 'alpha')
    config.alpha = 0.95;  % Typical for clean sand/gravelly sand alluvium (0.9-1.0)
end
if ~isfield(config, 'gamma_unit')
    config.gamma_unit = 'SI';  % Default to SI units
end
if ~isfield(config, 'poisson_ratio')
    config.poisson_ratio = 0.30;  % Typical for sand/sandstone (0.25-0.35)
end
% No aquifer_thickness needed - stopping at specific storage

%% Constants
if strcmp(config.gamma_unit, 'SI')
    gamma = 9810;  % N/m³ (specific weight of water in SI)
    console_log('\n=== SPECIFIC STORAGE CALCULATION (Becker 2022 Method) ===\n');
    console_log('Using SI units\n');
else
    gamma = 62.4;  % lb/ft³ (specific weight of water in imperial)
    console_log('\n=== SPECIFIC STORAGE CALCULATION (Becker 2022 Method) ===\n');
    console_log('Using Imperial units\n');
end

%% Extract linear regression slope
% slope units: (strain_rate) / (drawdown_rate)
%            = (1/s) / (ft/s)
% NOTE: Linear regression now outputs strain rate directly (already converted from nm/s)
%       and drawdown rate in ft/s (matching strain rate units)
%
% If displacement_rate was used, we need to convert the slope:
%   displacement_rate slope: (nm/s) per (ft/s)
%   To convert to strain rate slope: divide by characteristic length
%   But this is NOT recommended - use strain rate for proper physical meaning

slope_raw = lr_results.slope;  % (1/s) per (ft/s) for strain rate, or (nm/s) per (ft/s) for displacement rate

% Check if displacement rate was used instead of strain rate
using_displacement_rate = isfield(lr_results, 'use_displacement_rate') && lr_results.use_displacement_rate;

if using_displacement_rate
    console_log('\n⚠⚠⚠ WARNING: Using DISPLACEMENT RATE instead of STRAIN RATE ⚠⚠⚠\n');
    console_log('  Storage calculations require STRAIN RATE for correct physical meaning\n');
    console_log('  Displacement rate slope: %.4e (nm/s)/(ft/s)\n', slope_raw);
    
    % Check if user provided custom conversion factor
    if isfield(config, 'displacement_to_strain_conversion_factor') && config.displacement_to_strain_conversion_factor > 0
        conversion_factor = config.displacement_to_strain_conversion_factor;
        console_log('  Using CUSTOM conversion factor: %.2e\n', conversion_factor);
    else
        % Default conversion: divide by gauge length
        % But this might be too small - user can override
        gauge_length_m = 10;  % DAS gauge length
        characteristic_length_m = gauge_length_m;
        conversion_factor = characteristic_length_m * 1e9;  % 1e10
        
        console_log('  Using default conversion (gauge length): L = %.1f m\n', characteristic_length_m);
        console_log('  ⚠ NOTE: Using single-channel approximation for strain rate calculation\n');
    end
    
    % Convert: (nm/s) / (ft/s) → (1/s) / (ft/s)
    slope_raw = slope_raw / conversion_factor;
    
    console_log('  Converted slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    console_log('  ⚠ This is an APPROXIMATION - use strain rate for accurate results\n');
    
    % Also need to create strain_rate field for compatibility
    if isfield(lr_results, 'displacement_rate')
        % Convert displacement rate to strain rate equivalent
        lr_results.strain_rate = lr_results.displacement_rate / conversion_factor;
    end
end

% Check if strain rate characteristic length scaling is requested
if ~using_displacement_rate && isfield(config, 'strain_rate_characteristic_length_m') && config.strain_rate_characteristic_length_m > 0
    L_char = config.strain_rate_characteristic_length_m;
    L_gauge = 10;  % DAS gauge length in meters
    scaling_factor = L_gauge / L_char;
    
    console_log('\n📏 APPLYING CHARACTERISTIC LENGTH SCALING TO STRAIN RATE 📏\n');
    console_log('  Strain rate calculated with gauge length: %.1f m\n', L_gauge);
    console_log('  Rescaling to characteristic length: %.4f m\n', L_char);
    console_log('  Scaling factor: %.1f (= %.1fm / %.4fm)\n', scaling_factor, L_gauge, L_char);
    console_log('  Original slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    
    % Apply scaling
    slope_raw = slope_raw * scaling_factor;
    
    console_log('  Scaled slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    console_log('  ⚠ This is an EMPIRICAL SCALING - assumes effective compression over %.2f cm\n', L_char*100);
end

% Apply Poisson's ratio correction: Convert axial strain to volumetric strain
% DAS measures axial strain εzz, but poroelasticity needs volumetric strain εkk
% For isotropic, confined aquifer: εkk = εzz × (1 + 2ν/(1-ν))
% NOTE: DISABLED for anisotropic aquifers (sedimentary formations)
%       In stratified aquifers, the isotropic Poisson correction is not valid
if isfield(config, 'apply_poisson_correction') && config.apply_poisson_correction && isfield(config, 'poisson_ratio') && config.poisson_ratio > 0
    nu = config.poisson_ratio;
    poisson_correction = 1 + (2*nu)/(1-nu);
    
    console_log('\n📐 APPLYING POISSON''S RATIO CORRECTION (ISOTROPIC) 📐\n');
    console_log('  ⚠ WARNING: This assumes ISOTROPIC aquifer conditions\n');
    console_log('  DAS measures: Axial strain rate (∂εzz/∂t)\n');
    console_log('  Poroelasticity needs: Volumetric strain rate (∂εkk/∂t)\n');
    console_log('  Poisson''s ratio (ν): %.2f\n', nu);
    console_log('  Conversion factor: εkk/εzz = 1 + 2ν/(1-ν) = %.3f\n', poisson_correction);
    console_log('  Original slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    
    % Apply correction to slope
    slope_raw = slope_raw * poisson_correction;
    
    console_log('  Corrected slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    console_log('  ✓ Now represents volumetric strain rate\n');
else
    console_log('\n📐 POISSON CORRECTION: DISABLED 📐\n');
    console_log('  Aquifer is ANISOTROPIC (stratified sediments)\n');
    console_log('  Using vertical strain directly without isotropic correction\n');
    console_log('  This is appropriate for confined, stratified aquifers\n');
end

% Check if we're using head rate or drawdown rate
using_head_rate = isfield(lr_results, 'head_rate') && ~isempty(lr_results.head_rate);

console_log('\nLinear Regression Results:\n');
if using_head_rate
    console_log('  Using HEAD RATE (∂h/∂t) - slope = (∂ε/∂t) / (∂h/∂t)\n');
    console_log('  Slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    console_log('  Becker eq: S_ε = -α × slope / γ\n');
else
    console_log('  Using DRAWDOWN RATE (∂s/∂t) - slope = (∂ε/∂t) / (∂s/∂t)\n');
    console_log('  Slope: %.4e (1/s)/(ft/s)\n', slope_raw);
    console_log('  Becker eq: S_ε = +α × slope / γ (signs cancel)\n');
end
console_log('  R: %.4f\n', lr_results.R);
console_log('  R^2: %.4f\n', lr_results.R_squared);

%% Unit conversion
% Convert to consistent units:
% - Strain rate: already in 1/s (converted in linear_regression function)
% - Drawdown rate: already in ft/s (matching strain rate units)
% - For SI: convert ft/s → m/s
% - For Imperial: keep ft/s
% - Head change → Pressure change using γ

if strcmp(config.gamma_unit, 'SI')
    % Convert ft/s → m/s
    ft_to_m = 0.3048;
    drawdown_rate_conversion = ft_to_m;  % ft/s → m/s
    
    % slope units after conversion:
    % (1/s) / (m/s) = dimensionless time ratio
    slope_converted = slope_raw / drawdown_rate_conversion;  % (1/s) / (m/s)
    
    % Pressure rate: γ × (∂h/∂t) has units of Pa/s
    % So: (∂ε/∂t) / (∂h/∂t) = (1/s) / (m/s)
    % NOTE: Using drawdown rate (∂s/∂t) instead of head rate (∂h/∂t)
    % Since ∂h/∂t = -∂s/∂t, the negative sign cancels:
    % S_ε = -α × (∂ε/∂t) / [γ × (-∂s/∂t)] = +α × (∂ε/∂t) / [γ × (∂s/∂t)]
    
    if using_head_rate
        % Becker eq: S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)] = -α × slope / γ
        S_epsilon = -config.alpha * slope_converted / gamma;  % 1/Pa
        % Ensure positive (storage must be positive)
        if S_epsilon < 0
            console_log('  WARNING: S_epsilon is negative, using absolute value\n');
            S_epsilon = abs(S_epsilon);
        end
    else
        S_epsilon = config.alpha * slope_converted / gamma;  % 1/Pa (positive for drawdown rate)
    end
    S_s = S_epsilon * gamma;  % 1/m (specific storage)
    
    console_log('\nUnit Conversions:\n');
    console_log('  Strain rate: %.4e 1/s (already converted)\n', mean(abs(lr_results.strain_rate)));
    if using_head_rate
        console_log('  Head rate: %.4e ft/s → %.4e m/s\n', mean(abs(lr_results.head_rate)), mean(abs(lr_results.head_rate))*drawdown_rate_conversion);
    else
        console_log('  Drawdown rate: %.4e ft/s → %.4e m/s\n', mean(abs(lr_results.drawdown_rate)), mean(abs(lr_results.drawdown_rate))*drawdown_rate_conversion);
    end
    console_log('  γ = %.1f N/m³\n', gamma);
    
else  % Imperial
    % Already in ft/s - no conversion needed
    drawdown_rate_conversion = 1.0;  % ft/s → ft/s (no conversion)
    
    slope_converted = slope_raw;  % (1/s) / (ft/s) - already in correct units
    
    % Pressure rate: γ × (∂h/∂t) has units of psf/s (pounds per square foot per second)
    % NOTE: Using drawdown rate, so sign is positive (see SI section comment)
    if using_head_rate
        % Becker eq: S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)] = -α × slope / γ
        S_epsilon = -config.alpha * slope_converted / gamma;  % 1/psf
        % Ensure positive (storage must be positive)
        if S_epsilon < 0
            console_log('  WARNING: S_epsilon is negative, using absolute value\n');
            S_epsilon = abs(S_epsilon);
        end
    else
        S_epsilon = config.alpha * slope_converted / gamma;  % 1/psf (positive for drawdown rate)
    end
    S_s = S_epsilon * gamma;  % 1/ft
    
    console_log('\nUnit Conversions:\n');
    console_log('  Strain rate: %.4e 1/s (already converted)\n', mean(abs(lr_results.strain_rate)));
    if using_head_rate
        console_log('  Head rate: %.4e ft/s (already in correct units)\n', mean(abs(lr_results.head_rate)));
    else
        console_log('  Drawdown rate: %.4e ft/s (already in correct units)\n', mean(abs(lr_results.drawdown_rate)));
    end
    console_log('  γ = %.1f lb/ft³\n', gamma);
end

%% Display results
console_log('\n=== STORAGE PARAMETERS (Becker Method) ===\n');
console_log('Biot-Willis coefficient (α): %.2f\n', config.alpha);
if strcmp(config.gamma_unit, 'SI')
    console_log('S_ε (strain-constrained): %.4e 1/Pa\n', S_epsilon);
    console_log('S_s (specific storage): %.4e 1/m\n', S_s);
else
    console_log('S_ε (strain-constrained): %.4e 1/psf\n', S_epsilon);
    console_log('S_s (specific storage): %.4e 1/ft\n', S_s);
end

%% Quality assessment
console_log('\n=== QUALITY METRICS ===\n');
console_log('Correlation (R): %.4f\n', lr_results.R);
console_log('R^2: %.4f\n', lr_results.R_squared);
if lr_results.R_squared > 0.7
    console_log('✓ Strong correlation - reliable estimate\n');
elseif lr_results.R_squared > 0.4
    console_log('⚠ Moderate correlation - use with caution\n');
else
    console_log('✗ Weak correlation - results may be unreliable\n');
end

%% Package results
storage_results.S_epsilon = S_epsilon;
storage_results.S_s = S_s;
storage_results.alpha = config.alpha;
storage_results.gamma = gamma;
storage_results.gamma_unit = config.gamma_unit;
storage_results.poisson_ratio = config.poisson_ratio;
storage_results.slope_raw = slope_raw;
storage_results.slope_converted = slope_converted;
storage_results.R = lr_results.R;
storage_results.R_squared = lr_results.R_squared;

end

