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
% No aquifer_thickness needed - stopping at specific storage

%% Constants
if strcmp(config.gamma_unit, 'SI')
    gamma = 9810;  % N/m³ (specific weight of water in SI)
    fprintf('\n=== SPECIFIC STORAGE CALCULATION (Becker 2022 Method) ===\n');
    fprintf('Using SI units\n');
else
    gamma = 62.4;  % lb/ft³ (specific weight of water in imperial)
    fprintf('\n=== SPECIFIC STORAGE CALCULATION (Becker 2022 Method) ===\n');
    fprintf('Using Imperial units\n');
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
    fprintf('\n⚠⚠⚠ WARNING: Using DISPLACEMENT RATE instead of STRAIN RATE ⚠⚠⚠\n');
    fprintf('  Storage calculations require STRAIN RATE for correct physical meaning\n');
    fprintf('  Displacement rate slope: %.4e (nm/s) per (ft/s)\n', slope_raw);
    
    % Check if user provided custom conversion factor
    if isfield(config, 'displacement_to_strain_conversion_factor') && config.displacement_to_strain_conversion_factor > 0
        conversion_factor = config.displacement_to_strain_conversion_factor;
        fprintf('  Using CUSTOM conversion factor: %.2e\n', conversion_factor);
    else
        % Default conversion: divide by gauge length
        % But this might be too small - user can override
        gauge_length_m = 10;  % DAS gauge length
        characteristic_length_m = gauge_length_m;
        conversion_factor = characteristic_length_m * 1e9;  % 1e10
        
        fprintf('  Using default conversion (gauge length): L = %.1f m\n', characteristic_length_m);
        fprintf('  ⚠ NOTE: This conversion is approximate - displacement rate at single point\n');
        fprintf('    cannot be directly converted to strain rate without spatial gradient\n');
    end
    
    % Convert: (nm/s) / (ft/s) → (1/s) / (ft/s)
    slope_raw = slope_raw / conversion_factor;
    
    fprintf('  Converted slope: %.4e (1/s) per (ft/s)\n', slope_raw);
    fprintf('  ⚠ This is an APPROXIMATION - use strain rate for accurate results\n');
    
    % Also need to create strain_rate field for compatibility
    if isfield(lr_results, 'displacement_rate')
        % Convert displacement rate to strain rate equivalent
        lr_results.strain_rate = lr_results.displacement_rate / conversion_factor;
    end
end

% Check if we're using head rate or drawdown rate
using_head_rate = isfield(lr_results, 'head_rate') && ~isempty(lr_results.head_rate);

fprintf('\nLinear Regression Results:\n');
if using_head_rate
    fprintf('  Using HEAD RATE (∂h/∂t) - slope = (∂ε/∂t) / (∂h/∂t)\n');
    fprintf('  Slope: %.4e (1/s) per (ft/s)\n', slope_raw);
    fprintf('  Becker eq: S_ε = -α × slope / γ\n');
else
    fprintf('  Using DRAWDOWN RATE (∂s/∂t) - slope = (∂ε/∂t) / (∂s/∂t)\n');
    fprintf('  Slope: %.4e (1/s) per (ft/s)\n', slope_raw);
    fprintf('  Becker eq: S_ε = +α × slope / γ (signs cancel)\n');
end
fprintf('  R: %.4f\n', lr_results.R);
fprintf('  R^2: %.4f\n', lr_results.R_squared);

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
            fprintf('  WARNING: S_epsilon is negative, using absolute value\n');
            S_epsilon = abs(S_epsilon);
        end
    else
        S_epsilon = config.alpha * slope_converted / gamma;  % 1/Pa (positive for drawdown rate)
    end
    S_s = S_epsilon * gamma;  % 1/m (specific storage)
    
    fprintf('\nUnit Conversions:\n');
    fprintf('  Strain rate: %.4e 1/s (already converted)\n', mean(abs(lr_results.strain_rate)));
    if using_head_rate
        fprintf('  Head rate: %.4e ft/s → %.4e m/s\n', mean(abs(lr_results.head_rate)), mean(abs(lr_results.head_rate))*drawdown_rate_conversion);
    else
        fprintf('  Drawdown rate: %.4e ft/s → %.4e m/s\n', mean(abs(lr_results.drawdown_rate)), mean(abs(lr_results.drawdown_rate))*drawdown_rate_conversion);
    end
    fprintf('  γ = %.1f N/m³\n', gamma);
    
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
            fprintf('  WARNING: S_epsilon is negative, using absolute value\n');
            S_epsilon = abs(S_epsilon);
        end
    else
        S_epsilon = config.alpha * slope_converted / gamma;  % 1/psf (positive for drawdown rate)
    end
    S_s = S_epsilon * gamma;  % 1/ft
    
    fprintf('\nUnit Conversions:\n');
    fprintf('  Strain rate: %.4e 1/s (already converted)\n', mean(abs(lr_results.strain_rate)));
    if using_head_rate
        fprintf('  Head rate: %.4e ft/s (already in correct units)\n', mean(abs(lr_results.head_rate)));
    else
        fprintf('  Drawdown rate: %.4e ft/s (already in correct units)\n', mean(abs(lr_results.drawdown_rate)));
    end
    fprintf('  γ = %.1f lb/ft³\n', gamma);
end

%% Display results
fprintf('\n=== STORAGE PARAMETERS (Becker Method) ===\n');
fprintf('Biot-Willis coefficient (α): %.2f\n', config.alpha);
if strcmp(config.gamma_unit, 'SI')
    fprintf('S_ε (strain-constrained): %.4e 1/Pa\n', S_epsilon);
    fprintf('S_s (specific storage): %.4e 1/m\n', S_s);
else
    fprintf('S_ε (strain-constrained): %.4e 1/psf\n', S_epsilon);
    fprintf('S_s (specific storage): %.4e 1/ft\n', S_s);
end

%% Quality assessment
fprintf('\n=== QUALITY METRICS ===\n');
fprintf('Correlation (R): %.4f\n', lr_results.R);
fprintf('R^2: %.4f\n', lr_results.R_squared);
if lr_results.R_squared > 0.7
    fprintf('✓ Strong correlation - reliable estimate\n');
elseif lr_results.R_squared > 0.4
    fprintf('⚠ Moderate correlation - use with caution\n');
else
    fprintf('✗ Weak correlation - results may be unreliable\n');
end

%% Package results
storage_results.S_epsilon = S_epsilon;
storage_results.S_s = S_s;
storage_results.alpha = config.alpha;
storage_results.gamma = gamma;
storage_results.gamma_unit = config.gamma_unit;
storage_results.slope_raw = slope_raw;
storage_results.slope_converted = slope_converted;
storage_results.R = lr_results.R;
storage_results.R_squared = lr_results.R_squared;

end

