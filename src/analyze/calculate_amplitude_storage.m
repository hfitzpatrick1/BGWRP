function results = calculate_amplitude_storage(das_results, head_results, test_name, config)
%CALCULATE_AMPLITUDE_STORAGE Simple amplitude-based storage calculation
%
% This function implements the simplified amplitude method for calculating
% specific storage without complex regression. It uses:
%   1. Single channel at target depth (no averaging)
%   2. Peak-to-trough amplitude (max - min)
%   3. Simple strain rate calculation
%
% Inputs:
%   das_results  - DAS data structure from correlation analysis
%   head_results - Head data structure
%   test_name    - Name of test (e.g., 'PT01c_Recovery_short')
%   config       - Configuration with fields:
%                  .amplitude_target_depth_ft - Target depth (default: 285 ft)
%                  .amplitude_zone - Zone name (default: 'z5')
%                  .amplitude_time_period_sec - Time period for rate calc (default: 60 s)
%
% Outputs:
%   results - Structure with:
%            .channel_idx - Channel index used
%            .depth_ft - Actual depth of channel
%            .dz_amplitude - Displacement rate amplitude (nm/s)
%            .strain_rate_amplitude - Strain rate amplitude (1/s)
%            .drawdown_range - Total drawdown range (ft)
%            .head_rate - Head rate (ft/s)
%            .slope - Slope (1/s)/(ft/s)
%            .Se - Constrained specific storage (1/Pa)
%            .Ss - Specific storage (1/m)

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║  AMPLITUDE-BASED STORAGE CALCULATION (Single Channel Method)  ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');

%% Get configuration parameters
target_depth_ft = config.amplitude_target_depth_ft;
zone_name = config.amplitude_zone;
time_period = config.amplitude_time_period_sec;

% Poroelastic parameters
alpha = 0.95;  % Biot-Willis coefficient
gamma = 9810;  % N/m³ - specific weight of water

fprintf('\nConfiguration:\n');
fprintf('  Target depth: %.1f ft\n', target_depth_ft);
fprintf('  Zone: %s\n', zone_name);
fprintf('  Time period for rate: %.0f seconds\n', time_period);
fprintf('  Alpha (Biot-Willis): %.2f\n', alpha);
fprintf('  Gamma (water): %.0f N/m³\n', gamma);

%% Extract data
das_data = das_results.(test_name);
head_data = head_results.(test_name).zones.(zone_name).recovery_data;

%% Find channel closest to target depth
% Approximate depth calculation: channel spacing is 0.25m = 0.82 ft
depth_ft = (1:size(das_data.smoothed_data, 2)) * 0.82;
[~, ch_idx] = min(abs(depth_ft - target_depth_ft));
actual_depth = depth_ft(ch_idx);

fprintf('\n=== CHANNEL SELECTION ===\n');
fprintf('  Requested depth: %.1f ft\n', target_depth_ft);
fprintf('  Closest channel: %d\n', ch_idx);
fprintf('  Actual depth: %.1f ft\n', actual_depth);

%% Calculate displacement rate amplitude
displacement_rate = das_data.smoothed_data(:, ch_idx);  % nm/s

dz_max = max(displacement_rate);
dz_min = min(displacement_rate);
dz_amplitude = dz_max - dz_min;

fprintf('\n=== DISPLACEMENT RATE (Single Channel) ===\n');
fprintf('  Max: %.4e nm/s\n', dz_max);
fprintf('  Min: %.4e nm/s\n', dz_min);
fprintf('  Amplitude (max-min): %.4e nm/s\n', dz_amplitude);

%% Calculate strain rate amplitude
% Strain rate = displacement rate / gauge length
% gauge length = 10 m = 10 * 1e9 nm
gauge_length_m = 10;
gauge_length_nm = gauge_length_m * 1e9;

strain_rate_amplitude = dz_amplitude / gauge_length_nm;  % 1/s

fprintf('\n=== STRAIN RATE ===\n');
fprintf('  Gauge length: %.1f m = %.2e nm\n', gauge_length_m, gauge_length_nm);
fprintf('  Strain rate amplitude: %.4e 1/s\n', strain_rate_amplitude);
fprintf('  (Expected range: 1e-10 to 1e-11 for unconsolidated sediment)\n');

%% Calculate head rate
drawdown_ft = head_data.Drawdownft;

drawdown_max = max(drawdown_ft);
drawdown_min = min(drawdown_ft);
drawdown_range = drawdown_max - drawdown_min;  % Total change in ft

% Average rate = total change / time period
head_rate = drawdown_range / time_period;  % ft/s

fprintf('\n=== HEAD RATE ===\n');
fprintf('  Drawdown max: %.4f ft\n', drawdown_max);
fprintf('  Drawdown min: %.4f ft\n', drawdown_min);
fprintf('  Drawdown range: %.4f ft\n', drawdown_range);
fprintf('  Time period: %.0f seconds\n', time_period);
fprintf('  Head rate: %.4e ft/s\n', head_rate);
fprintf('  (= %.4e ft/min)\n', head_rate * 60);

%% Calculate slope
slope = strain_rate_amplitude / head_rate;  % (1/s) / (ft/s) = 1/ft

fprintf('\n=== SLOPE ===\n');
fprintf('  Slope = strain_rate / head_rate\n');
fprintf('  Slope: %.4e (1/s)/(ft/s)\n', slope);

% Convert to SI units
slope_SI = slope / 0.3048;  % Convert from 1/ft to 1/m

fprintf('  Slope (SI): %.4e 1/m\n', slope_SI);

%% Calculate specific storage
% Se = (alpha / gamma) * slope
Se = (alpha / gamma) * slope_SI;  % 1/Pa

fprintf('\n=== SPECIFIC STORAGE CALCULATION ===\n');
fprintf('  Sε = (α / γ) × slope\n');
fprintf('  Sε = (%.2f / %.0f) × %.4e\n', alpha, gamma, slope_SI);
fprintf('  Sε (constrained): %.4e 1/Pa\n', Se);

% Ss = Se * gamma
Ss = Se * gamma;  % 1/m

fprintf('\n  Ss = Sε × γ\n');
fprintf('  Ss = %.4e × %.0f\n', Se, gamma);
fprintf('  Ss (specific storage): %.4e 1/m\n', Ss);

%% Compare to expected ranges
fprintf('\n=== QUALITY CHECK ===\n');
fprintf('  Expected Ss for unconsolidated alluvium: 1e-07 to 1e-04 1/m\n');
fprintf('  Your Ss: %.2e 1/m\n', Ss);

if Ss >= 1e-07 && Ss <= 1e-04
    fprintf('  ✓ GOOD: Within expected range for unconsolidated sediment\n');
elseif Ss < 1e-07
    fprintf('  ⚠ WARNING: Too low - typical of consolidated rock\n');
else
    fprintf('  ⚠ WARNING: Too high - check calculation\n');
end

%% Store results
results.channel_idx = ch_idx;
results.depth_ft = actual_depth;
results.dz_amplitude = dz_amplitude;
results.strain_rate_amplitude = strain_rate_amplitude;
results.drawdown_range = drawdown_range;
results.head_rate = head_rate;
results.slope = slope;
results.slope_SI = slope_SI;
results.Se = Se;
results.Ss = Ss;
results.alpha = alpha;
results.gamma = gamma;
results.gauge_length_m = gauge_length_m;
results.time_period_sec = time_period;

fprintf('\n');
fprintf('╔═══════════════════════════════════════╗\n');
fprintf('║  AMPLITUDE CALCULATION COMPLETE!      ║\n');
fprintf('╚═══════════════════════════════════════╝\n');
fprintf('\n');

end

