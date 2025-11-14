function results = calculate_storage_from_poroelasticity(das_data, head_data, timing_info, config)
%CALCULATE_STORAGE_FROM_POROELASTICITY Estimate storage parameters from DAS-pressure coupling
%
% Uses poroelasticity diffusion equation (Wang 2000, Eqn 4.6s) to calculate
% constrained storage (Sε), specific storage (Ss), and storativity (S) from
% coupled DAS strain rate and pressure transducer measurements.
%
% Methodology validated by:
%   - Becker et al. (2022): DAS-based poroelastic aquifer characterization
%   - Murdoch et al. (2021): Type-curve strain analysis
%   - Wang (2000): Poroelasticity theory
%   - Black & Kipp (1977): Observation well response validation
%
% INPUTS:
%   das_data     - Structure with fields:
%                  .strain_rate [time x depth] - DAS strain rate (1/s)
%                  .time_vector [time x 1] - Time since recovery start (s)
%                  .depth_vector [depth x 1] - Depth locations (ft)
%   head_data    - Structure with fields:
%                  .head [time x 1] - Zone 5 head measurements (ft)
%                  .time_vector [time x 1] - Time vector (s)
%   timing_info  - Structure with fields:
%                  .t_pumping - Total pumping duration (s)
%                  .Q_pumping - Final pumping rate before recovery (GPM)
%   config       - Structure with aquifer and calculation parameters:
%                  .T - Transmissivity (ft²/day)
%                  .S - Storage coefficient (dimensionless)
%                  .K - Hydraulic conductivity (ft/day)
%                  .b - Aquifer thickness (ft)
%                  .r - Radial distance to observation point (ft)
%                  .alpha - Biot coefficient (default: 0.7)
%                  .depth_range - [min max] depth for analysis (ft)
%
% OUTPUTS:
%   results      - Structure with fields:
%                  .Se - Constrained storage (1/Pa) [time x 1]
%                  .Ss_ft - Specific storage (1/ft) [time x 1]
%                  .S_DAS - DAS-derived storativity (dimensionless)
%                  .S_Aqtesolv - Reference storativity from pump test
%                  .diagnostics - Quality control metrics
%                  .figures - Figure handles
%
% THEORY:
%   Poroelasticity diffusion equation:
%   α·(∂ε/∂t) + Sε·(∂p/∂t) = (k/μ)·∇²p
%
%   Solving for constrained storage:
%   Sε = [(k/μ)·∇²p - α·(∂ε/∂t)] / (∂p/∂t)
%
%   Where:
%   - α: Biot coefficient (volumetric strain coupling)
%   - ∂ε/∂t: Strain rate from DAS
%   - ∂p/∂t: Pressure rate from transducer
%   - ∇²p: Pressure Laplacian from Theis recovery solution
%   - k: Hydraulic conductivity
%   - μ: Water dynamic viscosity
%
% EXAMPLE:
%   results = calculate_storage_from_poroelasticity(das, head, timing, cfg);
%   fprintf('Storage from DAS: S = %.6f\n', results.S_DAS);
%   fprintf('Storage from Aqtesolv: S = %.6f\n', results.S_Aqtesolv);
%
% See also: analyze_das_data, run_storage_analysis

% Author: Generated for BGWRP Toolkit
% Date: 2024
% References: Storage_estimates.md, PM07_beta_calculation.md

%% Input validation
validateattributes(das_data.strain_rate, {'numeric'}, {'2d', 'finite'});
validateattributes(head_data.head, {'numeric'}, {'vector', 'finite'});
assert(length(das_data.time_vector) == length(head_data.head), ...
    'DAS and head data must have same time length');

%% Extract parameters
T = config.T;           % ft²/day
S = config.S;           % dimensionless
K = config.K;           % ft/day
b = config.b;           % ft
r = config.r;           % ft
t_pumping = timing_info.t_pumping;  % seconds
Q_pumping = timing_info.Q_pumping;  % GPM

% Set defaults
if ~isfield(config, 'alpha')
    config.alpha = 0.7;  % Biot coefficient (literature value for sediments)
end
if ~isfield(config, 'depth_range')
    config.depth_range = [190 340];  % ft (default strong response zone)
end

alpha = config.alpha;
depth_range = config.depth_range;

%% Physical constants
mu_water = 0.001002;  % Pa·s (dynamic viscosity at 20°C)

fprintf('\n=== POROELASTIC STORAGE CALCULATION ===\n');
fprintf('Method: Wang (2000) coupled DAS-pressure analysis\n');
fprintf('Validation: Becker et al. (2022), β = 0.021 (Zone 5)\n\n');

fprintf('Aquifer Parameters:\n');
fprintf('  T = %.2e ft²/day\n', T);
fprintf('  S = %.6f\n', S);
fprintf('  K = %.1f ft/day\n', K);
fprintf('  b = %.0f ft\n', b);
fprintf('  r = %.0f ft\n', r);
fprintf('  α = %.2f (Biot coefficient)\n', alpha);
fprintf('  Q = %.0f GPM (final pumping rate)\n', Q_pumping);
fprintf('  Pumping duration = %.0f min\n\n', t_pumping/60);

%% Step 1: Calculate pressure time derivative
fprintf('=== STEP 1: Pressure Time Derivative ===\n');

time_vector = das_data.time_vector;  % seconds
head_zone5 = head_data.head;         % ft

dt = time_vector(2) - time_vector(1);  % seconds (assuming uniform sampling)
p_dot = gradient(head_zone5) / dt;     % ft/s

fprintf('Time step: %.2f s\n', dt);
fprintf('Pressure rate range: %.2e to %.2e ft/s\n', min(p_dot), max(p_dot));
fprintf('Mean pressure rate: %.2e ft/s\n', mean(p_dot));
fprintf('Sign check: ');
if mean(p_dot) > 0
    fprintf('✓ Positive (pressure rising during recovery)\n\n');
else
    fprintf('✗ Negative (unexpected for recovery)\n\n');
end

%% Step 2: Calculate pressure Laplacian (Theis recovery)
fprintf('=== STEP 2: Pressure Laplacian (Theis Recovery) ===\n');

% Convert pumping rate to ft³/s
Q_cfs = Q_pumping * 0.002228;  % GPM to ft³/s

% Time vectors for Theis solution
t_total = time_vector + t_pumping;     % total time since pump started (s)
t_recovery = time_vector;              % recovery time (s)

% Convert to days for T compatibility
t_total_days = t_total / 86400;
t_recovery_days = t_recovery / 86400;

% Theis well function arguments
u1 = (r^2 * S) ./ (4 * T * t_total_days);      % total time
u2 = (r^2 * S) ./ (4 * T * t_recovery_days);   % recovery time

% Handle singularity at t=0
u2(1) = inf;

% Calculate Theis well functions W(u)
% MATLAB expint(x) = Ei(x), and W(u) = -Ei(-u) = -expint(-u)
W_u1 = zeros(size(u1));
W_u2 = zeros(size(u2));

for i = 1:length(u1)
    if u1(i) < 100  % expint overflows for large arguments
        W_u1(i) = -expint(u1(i));
    end
    if u2(i) < 100 && ~isinf(u2(i))
        W_u2(i) = -expint(u2(i));
    end
end

% Pressure Laplacian (∇²p) in 1/ft²
del2_p = (Q_cfs / (4 * pi * T)) * (W_u1 - W_u2);

fprintf('Well function u₁ range: %.2e to %.2e\n', min(u1), max(u1));
fprintf('Well function u₂ range: %.2e to %.2e\n', min(u2(2:end)), max(u2(2:end)));
fprintf('∇²p range: %.2e to %.2e 1/ft²\n', min(del2_p), max(del2_p));
fprintf('Sign check: ');
if mean(del2_p) < 0
    fprintf('✓ Negative (pressure cone relaxing)\n\n');
else
    fprintf('✗ Positive (unexpected for recovery)\n\n');
end

%% Step 3: Extract DAS strain rate
fprintf('=== STEP 3: DAS Strain Rate Extraction ===\n');

depth_vector = das_data.depth_vector;
strain_rate_matrix = das_data.strain_rate;

% Select depth interval
depth_idx = find(depth_vector >= depth_range(1) & depth_vector <= depth_range(2));
fprintf('Selected depth range: %.1f to %.1f ft\n', ...
    min(depth_vector(depth_idx)), max(depth_vector(depth_idx)));
fprintf('Number of channels: %d\n', length(depth_idx));

% Average strain rate across responsive interval
strain_rate_avg = mean(strain_rate_matrix(:, depth_idx), 2);  % [time x 1]

fprintf('Strain rate range: %.2e to %.2e 1/s\n', ...
    min(strain_rate_avg), max(strain_rate_avg));
fprintf('Mean strain rate: %.2e 1/s\n', mean(strain_rate_avg));
fprintf('Sign check: ');
if mean(strain_rate_avg) > 0
    fprintf('✓ Positive (aquifer expanding during recovery)\n\n');
else
    fprintf('✗ Negative (unexpected for recovery)\n\n');
end

%% Step 4: Calculate constrained storage Sε
fprintf('=== STEP 4: Constrained Storage Calculation ===\n');

% Convert to SI units for consistency
K_SI = K * (0.3048 / 86400);        % ft/day to m/s
del2_p_SI = del2_p / (0.3048^2);   % 1/ft² to 1/m²
p_dot_SI = p_dot * 0.3048;          % ft/s to m/s
b_SI = b * 0.3048;                  % ft to m

% Calculate poroelasticity equation terms
diffusion_term = (K_SI / mu_water) * del2_p_SI;  % 1/s
strain_term = alpha * strain_rate_avg;            % 1/s

% Solve for Sε: Sε = [(k/μ)∇²p - α·ε̇] / ṗ
Se = (diffusion_term - strain_term) ./ p_dot_SI;  % 1/Pa

fprintf('Diffusion term range: %.2e to %.2e 1/s\n', ...
    min(diffusion_term), max(diffusion_term));
fprintf('Strain term range: %.2e to %.2e 1/s\n', ...
    min(strain_term), max(strain_term));
fprintf('Sε range: %.2e to %.2e 1/Pa\n', min(Se), max(Se));
fprintf('Sε mean: %.2e 1/Pa\n', mean(Se));
fprintf('Sε median: %.2e 1/Pa\n\n', median(Se));

%% Step 5: Convert to specific storage
fprintf('=== STEP 5: Specific Storage Conversion ===\n');

% Specific storage Ss (1/m then convert to 1/ft)
Ss_SI = Se / b_SI;           % 1/m
Ss_ft = Ss_SI * 0.3048;      % 1/ft

fprintf('Ss range: %.2e to %.2e 1/ft\n', min(Ss_ft), max(Ss_ft));
fprintf('Ss mean: %.2e 1/ft\n', mean(Ss_ft));
fprintf('Ss median: %.2e 1/ft\n\n', median(Ss_ft));

%% Step 6: Calculate storativity and compare
fprintf('=== STEP 6: Storativity Comparison ===\n');

% DAS-derived storativity
S_DAS = mean(Ss_ft) * b;  % dimensionless

fprintf('Aqtesolv: S = %.6f\n', S);
fprintf('DAS:      S = %.6f\n', S_DAS);
fprintf('Ratio (DAS/Aqtesolv): %.2f\n', S_DAS / S);
fprintf('Difference: %.1f%%\n\n', 100 * abs(S_DAS - S) / S);

%% Step 7: Becker-style diagnostic checks
fprintf('=== STEP 7: BECKER DIAGNOSTIC CHECKS ===\n');

diagnostics = struct();

% Diagnostic 1: Strain amplitude
strain_integrated = cumtrapz(time_vector, strain_rate_avg);
strain_amplitude_ns = (max(strain_integrated) - min(strain_integrated)) * 1e9;
diagnostics.strain_amplitude_ns = strain_amplitude_ns;

fprintf('Check 1: Strain Amplitude\n');
fprintf('  Measured: %.0f nanostrain\n', strain_amplitude_ns);
fprintf('  Expected: 100-2000 ns (Becker range)\n');
if strain_amplitude_ns >= 100 && strain_amplitude_ns <= 2000
    fprintf('  Status: ✓ PASS\n\n');
    diagnostics.amplitude_check = 'PASS';
else
    fprintf('  Status: ⚠ CAUTION (outside typical range)\n\n');
    diagnostics.amplitude_check = 'CAUTION';
end

% Diagnostic 2: Strain-pressure correlation
corr_coef = corr(strain_rate_avg, p_dot);
diagnostics.correlation = corr_coef;

fprintf('Check 2: Strain-Pressure Correlation\n');
fprintf('  Correlation coefficient: %.3f\n', corr_coef);
if corr_coef > 0.5
    fprintf('  Status: ✓ PASS (strong positive, normal poroelastic response)\n\n');
    diagnostics.correlation_check = 'PASS';
elseif corr_coef < -0.3
    fprintf('  Status: ✗ FAIL (negative correlation, Noordbergum effect)\n');
    fprintf('  This indicates reverse strain response - complex 3D coupling\n\n');
    diagnostics.correlation_check = 'FAIL_NOORDBERGUM';
else
    fprintf('  Status: ⚠ CAUTION (weak correlation)\n\n');
    diagnostics.correlation_check = 'CAUTION';
end

% Diagnostic 3: Monotonic behavior
strain_smooth = movmean(strain_integrated, 10);
d_strain = gradient(strain_smooth);
monotonic_fraction = sum(d_strain > -0.1*max(d_strain)) / length(d_strain);
diagnostics.monotonic_fraction = monotonic_fraction;

fprintf('Check 3: Monotonic Recovery Behavior\n');
fprintf('  Monotonic fraction: %.1f%%\n', 100*monotonic_fraction);
if monotonic_fraction > 0.95
    fprintf('  Status: ✓ PASS (smooth recovery)\n\n');
    diagnostics.monotonic_check = 'PASS';
else
    fprintf('  Status: ⚠ CAUTION (non-monotonic, possible leak-off)\n\n');
    diagnostics.monotonic_check = 'CAUTION';
end

% Diagnostic 4: Diffusive time scale
t_diffusion = (r^2 * S) / (4 * T / 86400);  % seconds
diagnostics.t_diffusion = t_diffusion;

fprintf('Check 4: Time Scale Assessment\n');
fprintf('  Diffusion time: %.0f s (%.1f min)\n', t_diffusion, t_diffusion/60);
fprintf('  Analysis duration: %.0f s (%.1f min)\n', max(time_vector), max(time_vector)/60);
if max(time_vector) > 0.5 * t_diffusion
    fprintf('  Status: ✓ PASS (covers diffusive regime)\n\n');
    diagnostics.timescale_check = 'PASS';
else
    fprintf('  Status: ⚠ CAUTION (early elastic regime)\n\n');
    diagnostics.timescale_check = 'CAUTION';
end

% Diagnostic 5: Storage sign and magnitude
fprintf('Check 5: Storage Parameter Validation\n');
fprintf('  Mean Sε: %.2e 1/Pa (should be ~1e-5 to 1e-4)\n', mean(Se));
fprintf('  Mean Ss: %.2e 1/ft (should be ~1e-6 to 1e-5)\n', mean(Ss_ft));

all_positive = all(Se > 0);
reasonable_magnitude = (mean(Se) > 1e-6) && (mean(Se) < 1e-3);

if all_positive && reasonable_magnitude
    fprintf('  Status: ✓ PASS (all positive, reasonable magnitude)\n\n');
    diagnostics.storage_check = 'PASS';
elseif ~all_positive
    fprintf('  Status: ✗ FAIL (negative storage detected)\n');
    fprintf('  Check sign conventions and calculation\n\n');
    diagnostics.storage_check = 'FAIL_SIGN';
else
    fprintf('  Status: ⚠ CAUTION (magnitude unusual)\n\n');
    diagnostics.storage_check = 'CAUTION';
end

% Overall assessment
fprintf('=== OVERALL DIAGNOSTIC ASSESSMENT ===\n');
checks = {diagnostics.amplitude_check, diagnostics.correlation_check, ...
          diagnostics.monotonic_check, diagnostics.timescale_check, ...
          diagnostics.storage_check};
n_pass = sum(strcmp(checks, 'PASS'));
n_fail = sum(contains(checks, 'FAIL'));

fprintf('Checks passed: %d/5\n', n_pass);
fprintf('Checks failed: %d/5\n', n_fail);

if n_pass >= 4 && n_fail == 0
    fprintf('Quality: ✓ EXCELLENT - Simple analysis applicable\n');
    diagnostics.overall = 'EXCELLENT';
elseif n_pass >= 3 && n_fail == 0
    fprintf('Quality: ✓ GOOD - Results reliable with minor cautions\n');
    diagnostics.overall = 'GOOD';
elseif n_fail > 0
    fprintf('Quality: ✗ POOR - Complex behavior, need advanced modeling\n');
    diagnostics.overall = 'POOR';
else
    fprintf('Quality: ⚠ FAIR - Results interpretable with caution\n');
    diagnostics.overall = 'FAIR';
end
fprintf('\n');

%% Generate visualizations
fprintf('=== GENERATING FIGURES ===\n');

figs = struct();

% Figure 1: Main results (6-panel comprehensive)
figs.main = figure('Position', [100 100 1400 1000], 'Name', 'Storage Analysis Results');

% Panel 1: Constrained storage evolution
subplot(3,2,1);
plot(time_vector / 60, Se, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('Constrained Storage S_\varepsilon (1/Pa)', 'FontSize', 10);
title('Constrained Storage Evolution', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
xlim([0 max(time_vector/60)]);

% Panel 2: Specific storage with Aqtesolv comparison
subplot(3,2,2);
plot(time_vector / 60, Ss_ft, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
hold on;
yline(S/b, 'r--', 'LineWidth', 2, 'DisplayName', 'Aqtesolv S_s');
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('Specific Storage S_s (1/ft)', 'FontSize', 10);
title('Specific Storage (DAS vs Aqtesolv)', 'FontSize', 11, 'FontWeight', 'bold');
legend('DAS-derived', 'Aqtesolv', 'Location', 'best', 'FontSize', 9);
grid on;
xlim([0 max(time_vector/60)]);

% Panel 3: Pressure derivative
subplot(3,2,3);
plot(time_vector / 60, p_dot, 'LineWidth', 2, 'Color', [0.4940 0.1840 0.5560]);
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('dh/dt (ft/s)', 'FontSize', 10);
title('Zone 5 Pressure Rate', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
xlim([0 max(time_vector/60)]);

% Panel 4: DAS strain rate
subplot(3,2,4);
plot(time_vector / 60, strain_rate_avg * 1e9, 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]);
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('Strain Rate (nanostrain/s)', 'FontSize', 10);
title(sprintf('DAS Strain Rate (%.0f-%.0f ft)', depth_range(1), depth_range(2)), ...
      'FontSize', 11, 'FontWeight', 'bold');
grid on;
xlim([0 max(time_vector/60)]);

% Panel 5: Poroelasticity equation terms
subplot(3,2,5);
plot(time_vector / 60, diffusion_term, 'LineWidth', 2, 'DisplayName', '(k/\mu)\nabla^2p');
hold on;
plot(time_vector / 60, strain_term, 'LineWidth', 2, 'DisplayName', '\alpha\epsilon_\cdot');
plot(time_vector / 60, diffusion_term - strain_term, 'k--', 'LineWidth', 1.5, ...
     'DisplayName', 'Net (S_\varepsilon\cdotp)');
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('Rate (1/s)', 'FontSize', 10);
title('Poroelasticity Equation Terms', 'FontSize', 11, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 8);
grid on;
xlim([0 max(time_vector/60)]);

% Panel 6: Storage distribution histogram
subplot(3,2,6);
histogram(Ss_ft, 30, 'Normalization', 'probability', 'FaceColor', [0.3010 0.7450 0.9330]);
hold on;
xline(S/b, 'r--', 'LineWidth', 2, 'Label', 'Aqtesolv', 'LabelVerticalAlignment', 'bottom');
xline(mean(Ss_ft), 'k-', 'LineWidth', 2, 'Label', 'DAS Mean', 'LabelVerticalAlignment', 'top');
xlabel('Specific Storage S_s (1/ft)', 'FontSize', 10);
ylabel('Probability', 'FontSize', 10);
title('S_s Distribution', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

sgtitle(sprintf('Poroelastic Storage Analysis | DAS: S=%.5f | Aqtesolv: S=%.5f | Ratio: %.2f', ...
        S_DAS, S, S_DAS/S), 'FontSize', 13, 'FontWeight', 'bold');

% Figure 2: Becker-style diagnostic plots
figs.diagnostics = figure('Position', [150 150 1200 800], 'Name', 'Becker Diagnostic Checks');

% Panel 1: Integrated strain vs time
subplot(2,2,1);
plot(time_vector / 60, strain_integrated * 1e9, 'LineWidth', 2);
xlabel('Recovery Time (minutes)', 'FontSize', 10);
ylabel('Integrated Strain (nanostrain)', 'FontSize', 10);
title(sprintf('Strain Amplitude: %.0f ns (Becker: 100-2000 ns)', strain_amplitude_ns), ...
      'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Panel 2: Strain rate vs pressure rate (correlation check)
subplot(2,2,2);
scatter(p_dot, strain_rate_avg * 1e9, 20, time_vector/60, 'filled');
colormap(jet);
cb = colorbar;
cb.Label.String = 'Time (min)';
xlabel('Pressure Rate dh/dt (ft/s)', 'FontSize', 10);
ylabel('Strain Rate d\epsilon/dt (nanostrain/s)', 'FontSize', 10);
title(sprintf('Strain-Pressure Coupling | r = %.3f', corr_coef), ...
      'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Panel 3: Phase plot (strain vs head)
subplot(2,2,3);
plot(head_zone5, strain_integrated * 1e9, 'LineWidth', 1.5);
xlabel('Head (ft)', 'FontSize', 10);
ylabel('Integrated Strain (nanostrain)', 'FontSize', 10);
title('Strain-Pressure Phase Plot', 'FontSize', 11, 'FontWeight', 'bold');
grid on;

% Panel 4: Diagnostic summary
subplot(2,2,4);
axis off;
text(0.1, 0.9, 'DIAGNOSTIC SUMMARY', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.75, sprintf('Amplitude: %s', diagnostics.amplitude_check), 'FontSize', 10);
text(0.1, 0.65, sprintf('Correlation: %s', diagnostics.correlation_check), 'FontSize', 10);
text(0.1, 0.55, sprintf('Monotonic: %s', diagnostics.monotonic_check), 'FontSize', 10);
text(0.1, 0.45, sprintf('Time Scale: %s', diagnostics.timescale_check), 'FontSize', 10);
text(0.1, 0.35, sprintf('Storage: %s', diagnostics.storage_check), 'FontSize', 10);
text(0.1, 0.20, sprintf('Overall Quality: %s', diagnostics.overall), ...
     'FontSize', 11, 'FontWeight', 'bold');
text(0.1, 0.05, sprintf('Passed: %d/5 | Failed: %d/5', n_pass, n_fail), 'FontSize', 10);

sgtitle('Becker et al. (2022) Diagnostic Framework', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('✓ Figures generated\n\n');

%% Package results
results = struct();
results.Se = Se;
results.Ss_ft = Ss_ft;
results.Ss_SI = Ss_SI;
results.S_DAS = S_DAS;
results.S_Aqtesolv = S;
results.time_vector = time_vector;
results.strain_integrated = strain_integrated;
results.parameters.T = T;
results.parameters.S = S;
results.parameters.K = K;
results.parameters.b = b;
results.parameters.r = r;
results.parameters.alpha = alpha;
results.parameters.Q_pumping = Q_pumping;
results.parameters.t_pumping = t_pumping;
results.diagnostics = diagnostics;
results.figures = figs;
results.intermediate.diffusion_term = diffusion_term;
results.intermediate.strain_term = strain_term;
results.intermediate.p_dot = p_dot;
results.intermediate.del2_p = del2_p;

fprintf('=== CALCULATION COMPLETE ===\n');
fprintf('Results returned in structure with %d fields\n', length(fieldnames(results)));

end



