%DIAGNOSE_STORAGE_CALCULATION Check storage calculation for unit errors
%
% This script helps diagnose why DAS storage values might be 3 orders of
% magnitude too low

fprintf('\n=== DIAGNOSTIC: Storage Calculation ===\n\n');

%% Current values from your analysis
slope_raw = 4.32e-09;  % (1/s) per (ft/s)
alpha = 0.95;
gamma = 9810;  % N/m³

fprintf('Current Analysis:\n');
fprintf('  Slope: %.4e (1/s) per (ft/s)\n', slope_raw);

%% Convert to SI
ft_to_m = 0.3048;
slope_si = slope_raw / ft_to_m;  % (1/s) per (m/s)
fprintf('  Slope (SI): %.4e (1/s) per (m/s)\n', slope_si);

%% Calculate storage
S_epsilon = alpha * slope_si / gamma;
S_s = S_epsilon * gamma;

fprintf('  S_epsilon: %.4e 1/Pa\n', S_epsilon);
fprintf('  S_s: %.4e 1/m\n', S_s);

%% Compare to Aqtesolv
S_s_aqtesolv = 2.56e-5;
ratio = S_s / S_s_aqtesolv;
fprintf('\nComparison:\n');
fprintf('  DAS S_s: %.4e 1/m\n', S_s);
fprintf('  Aqtesolv S_s: %.4e 1/m\n', S_s_aqtesolv);
if ratio < 1
    direction = 'lower';
else
    direction = 'higher';
end
fprintf('  Ratio: %.4e (%.0f× %s)\n', ratio, 1/abs(ratio), direction);

%% If we need to be 1000× larger, what would the slope need to be?
target_S_s = S_s_aqtesolv;  % Or maybe 1e-5?
required_S_epsilon = target_S_s / gamma;
required_slope_si = required_S_epsilon * gamma / alpha;
required_slope_raw = required_slope_si * ft_to_m;

fprintf('\nTo match Aqtesolv (%.4e 1/m):\n', S_s_aqtesolv);
fprintf('  Required slope (SI): %.4e (1/s) per (m/s)\n', required_slope_si);
fprintf('  Required slope (raw): %.4e (1/s) per (ft/s)\n', required_slope_raw);
fprintf('  Current slope: %.4e (1/s) per (ft/s)\n', slope_raw);
fprintf('  Factor needed: %.1f×\n', required_slope_raw / slope_raw);

%% Check gauge length conversion
fprintf('\nGauge Length Check:\n');
displacement_example = 0.1;  % nm/s (typical value)
gauge_length_current = 10;  % m
strain_current = displacement_example / (gauge_length_current * 1e9);
fprintf('  Current: displacement = %.2f nm/s, gauge = %.0f m\n', displacement_example, gauge_length_current);
fprintf('    → strain = %.2e 1/s\n', strain_current);

% What if gauge length is wrong?
gauge_length_alt = 0.01;  % 1 cm
strain_alt = displacement_example / (gauge_length_alt * 1e9);
fprintf('  Alternative: displacement = %.2f nm/s, gauge = %.2f m\n', displacement_example, gauge_length_alt);
fprintf('    → strain = %.2e 1/s (%.0f× larger)\n', strain_alt, strain_alt/strain_current);

% What if displacement is in m/s not nm/s?
displacement_m_per_s = displacement_example * 1e-9;  % Convert nm/s to m/s
strain_from_m_per_s = displacement_m_per_s / gauge_length_current;
fprintf('  If displacement in m/s: %.2e m/s, gauge = %.0f m\n', displacement_m_per_s, gauge_length_current);
fprintf('    → strain = %.2e 1/s (%.0f× larger)\n', strain_from_m_per_s, strain_from_m_per_s/strain_current);

fprintf('\n=== RECOMMENDATIONS ===\n');
fprintf('1. Verify gauge length for your DAS system (is it really 10 m?)\n');
fprintf('2. Verify displacement rate units from interrogator (nm/s or m/s?)\n');
fprintf('3. Check if there''s a calibration factor in the DAS data\n');
fprintf('4. Compare strain rate values to expected ranges for your aquifer\n');

