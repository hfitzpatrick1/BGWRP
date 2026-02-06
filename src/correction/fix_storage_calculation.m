%FIX_STORAGE_CALCULATION Test different approaches to fix the 1000× error
%
% The issue: DAS S_s is 1000× too low compared to Aqtesolv
% Possible fixes:
% 1. Use head rate instead of drawdown rate
% 2. Fix sign convention
% 3. Check if there's a missing factor

console_log('\n=== TESTING STORAGE CALCULATION FIXES ===\n\n');

%% Current values
slope_current = 4.32e-09;  % (1/s) per (ft/s) - positive slope
alpha = 0.95;
gamma = 9810;  % N/m³
ft_to_m = 0.3048;

%% Current calculation
slope_si_current = slope_current / ft_to_m;
S_eps_current = alpha * slope_si_current / gamma;
S_s_current = S_eps_current * gamma;

console_log('CURRENT (using positive slope as-is):\n');
console_log('  S_s = %.4e 1/m\n', S_s_current);
console_log('  Ratio to Aqtesolv: %.4e\n\n', S_s_current / 2.56e-5);

%% Option 1: Use absolute value (if slope should be negative)
slope_abs = abs(slope_current);
slope_si_abs = slope_abs / ft_to_m;
S_eps_abs = alpha * slope_si_abs / gamma;
S_s_abs = S_eps_abs * gamma;

console_log('OPTION 1 (using |slope|):\n');
console_log('  S_s = %.4e 1/m\n', S_s_abs);
console_log('  Ratio to Aqtesolv: %.4e\n');
console_log('  (Same as current - no change)\n\n', S_s_abs / 2.56e-5);

%% Option 2: Multiply by 1000 (if gauge length conversion is wrong)
% If displacement is actually in different units or gauge length is wrong
S_s_1000x = S_s_current * 1000;

console_log('OPTION 2 (multiply result by 1000):\n');
console_log('  S_s = %.4e 1/m\n', S_s_1000x);
console_log('  Ratio to Aqtesolv: %.4e\n\n', S_s_1000x / 2.56e-5);

%% Option 3: Check if we should use head rate with negative sign in Becker eq
% If we're actually using head rate (positive during recovery), then:
% S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)] with negative sign
% But slope = (∂ε/∂t) / (∂h/∂t) is positive
% So: S_ε = -α × slope / γ (with negative sign!)
S_eps_neg = -alpha * slope_si_current / gamma;
S_s_neg = S_eps_neg * gamma;

console_log('OPTION 3 (use negative sign in Becker eq):\n');
console_log('  S_s = %.4e 1/m (NEGATIVE - wrong!)\n', S_s_neg);
console_log('  (This gives negative storage - not correct)\n\n');

%% Option 4: If gauge length should be 0.01 m instead of 10 m
% This would make strain 1000× larger
gauge_length_small = 0.01;  % 1 cm
% The strain would be: displacement / (0.01 * 1e9) = displacement / 1e7
% vs current: displacement / (10 * 1e9) = displacement / 1e10
% Ratio: 1e10 / 1e7 = 1000×
% So if we multiply slope by 1000 (since strain is 1000× larger):
slope_1000x = slope_current * 1000;
slope_si_1000x = slope_1000x / ft_to_m;
S_eps_1000x = alpha * slope_si_1000x / gamma;
S_s_1000x_slope = S_eps_1000x * gamma;

console_log('OPTION 4 (if gauge length is 0.01 m, multiply slope by 1000):\n');
console_log('  S_s = %.4e 1/m\n', S_s_1000x_slope);
console_log('  Ratio to Aqtesolv: %.4e\n', S_s_1000x_slope / 2.56e-5);
console_log('  (This gets us much closer!)\n\n');

%% Recommendation
console_log('=== RECOMMENDATION ===\n');
console_log('Most likely fix: Multiply the strain rate by 1000 (or slope by 1000)\n');
console_log('This suggests:\n');
console_log('  1. Gauge length might actually be 0.01 m (1 cm) not 10 m\n');
console_log('  2. OR displacement rate needs different conversion factor\n');
console_log('  3. OR there''s a calibration factor of 1000 in the DAS system\n\n');

console_log('To implement: Change strain conversion from:\n');
console_log('  strain = displacement / (gauge_length * 1e9)\n');
console_log('to:\n');
console_log('  strain = displacement / (gauge_length * 1e6)  [for µm/s]\n');
console_log('OR:\n');
console_log('  strain = displacement * 1000 / (gauge_length * 1e9)  [multiply by 1000]\n');

