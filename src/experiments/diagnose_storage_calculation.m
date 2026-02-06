%DIAGNOSE_STORAGE_CALCULATION Check storage calculation for unit errors
%
% This script helps diagnose why DAS storage values might be 3 orders of
% magnitude too low

console_log('\n=== DIAGNOSTIC: Storage Calculation ===\n\n');

%% Current values from your analysis
slope_raw = 4.32e-09;  % (1/s) per (ft/s)
alpha = 0.95;
gamma = 9810;  % N/m³

console_log('Current Analysis:\n');
console_log('  Slope: %.4e (1/s) per (ft/s)\n', slope_raw);

%% Convert to SI
ft_to_m = 0.3048;
slope_si = slope_raw / ft_to_m;  % (1/s) per (m/s)
console_log('  Slope (SI): %.4e (1/s) per (m/s)\n', slope_si);

%% Calculate storage
S_epsilon = alpha * slope_si / gamma;
S_s = S_epsilon * gamma;

console_log('  S_epsilon: %.4e 1/Pa\n', S_epsilon);
console_log('  S_s: %.4e 1/m\n', S_s);

%% Compare to Aqtesolv
S_s_aqtesolv = 2.56e-5;
ratio = S_s / S_s_aqtesolv;
console_log('\nComparison:\n');
console_log('  DAS S_s: %.4e 1/m\n', S_s);
console_log('  Aqtesolv S_s: %.4e 1/m\n', S_s_aqtesolv);
if ratio < 1
    direction = 'lower';
else
    direction = 'higher';
end
console_log('  Ratio: %.4e (%.0f× %s)\n', ratio, 1/abs(ratio), direction);

%% If we need to be 1000× larger, what would the slope need to be?
target_S_s = S_s_aqtesolv;  % Or maybe 1e-5?
required_S_epsilon = target_S_s / gamma;
required_slope_si = required_S_epsilon * gamma / alpha;
required_slope_raw = required_slope_si * ft_to_m;

console_log('\nTo match Aqtesolv (%.4e 1/m):\n', S_s_aqtesolv);
console_log('  Required slope (SI): %.4e (1/s) per (m/s)\n', required_slope_si);
console_log('  Required slope (raw): %.4e (1/s) per (ft/s)\n', required_slope_raw);
console_log('  Current slope: %.4e (1/s) per (ft/s)\n', slope_raw);
console_log('  Factor needed: %.1f×\n', required_slope_raw / slope_raw);

%% Check gauge length conversion
console_log('\nGauge Length Check:\n');
displacement_example = 0.1;  % nm/s (typical value)
gauge_length_current = 10;  % m
strain_current = displacement_example / (gauge_length_current * 1e9);
console_log('  Current: displacement = %.2f nm/s, gauge = %.0f m\n', displacement_example, gauge_length_current);
console_log('    → strain = %.2e 1/s\n', strain_current);

% What if gauge length is wrong?
gauge_length_alt = 0.01;  % 1 cm
strain_alt = displacement_example / (gauge_length_alt * 1e9);
console_log('  Alternative: displacement = %.2f nm/s, gauge = %.2f m\n', displacement_example, gauge_length_alt);
console_log('    → strain = %.2e 1/s (%.0f× larger)\n', strain_alt, strain_alt/strain_current);

% What if displacement is in m/s not nm/s?
displacement_m_per_s = displacement_example * 1e-9;  % Convert nm/s to m/s
strain_from_m_per_s = displacement_m_per_s / gauge_length_current;
console_log('  If displacement in m/s: %.2e m/s, gauge = %.0f m\n', displacement_m_per_s, gauge_length_current);
console_log('    → strain = %.2e 1/s (%.0f× larger)\n', strain_from_m_per_s, strain_from_m_per_s/strain_current);

console_log('\n=== RECOMMENDATIONS ===\n');
console_log('1. Verify gauge length for your DAS system (is it really 10 m?)\n');
console_log('2. Verify displacement rate units from interrogator (nm/s or m/s?)\n');
console_log('3. Check if there''s a calibration factor in the DAS data\n');
console_log('4. Compare strain rate values to expected ranges for your aquifer\n');

