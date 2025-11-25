%VERIFY_ADVISOR_CALCULATION Verify the advisor's calculation method
% This helps understand the 10x difference in slope

clear all
close all
clc

fprintf('=== VERIFYING ADVISOR''S CALCULATION ===\n\n');

% Advisor's values
displacement_rate_amplitude = 1.3;  % nm/s (amplitude = max - min)
gauge_length_m = 10;  % m
head_rate_amplitude_ft_per_min = 0.09;  % ft/min

% Step 1: Calculate strain rate amplitude
strain_rate_amplitude = displacement_rate_amplitude / (gauge_length_m * 1e9);  % 1/s
fprintf('Step 1: Strain rate amplitude\n');
fprintf('  Displacement rate amplitude: %.2f nm/s\n', displacement_rate_amplitude);
fprintf('  Gauge length: %.1f m = %.0e nm\n', gauge_length_m, gauge_length_m * 1e9);
fprintf('  Strain rate = %.2f nm/s / %.0e nm = %.4e 1/s\n', ...
    displacement_rate_amplitude, gauge_length_m * 1e9, strain_rate_amplitude);

% Step 2: Convert head rate to ft/s
head_rate_amplitude_ft_per_s = head_rate_amplitude_ft_per_min / 60;  % ft/s
fprintf('\nStep 2: Head rate amplitude\n');
fprintf('  Head rate amplitude: %.2f ft/min = %.4f ft/s\n', ...
    head_rate_amplitude_ft_per_min, head_rate_amplitude_ft_per_s);

% Step 3: Calculate slope
slope_advisor = strain_rate_amplitude / head_rate_amplitude_ft_per_s;  % (1/s)/(ft/s)
fprintf('\nStep 3: Slope calculation\n');
fprintf('  Slope = strain rate / head rate\n');
fprintf('  Slope = %.4e 1/s / %.4f ft/s = %.4e (1/s)/(ft/s)\n', ...
    strain_rate_amplitude, head_rate_amplitude_ft_per_s, slope_advisor);
fprintf('  Advisor reported: 2.8434e-07 (1/s)/(ft/s)\n');
fprintf('  Difference: %.2fx\n', 2.8434e-07 / slope_advisor);

% Check if there's a unit conversion issue
fprintf('\n=== CHECKING FOR UNIT CONVERSION ISSUES ===\n');
fprintf('If advisor uses different units:\n');

% Maybe advisor converts to m/s instead of ft/s?
head_rate_m_per_s = head_rate_amplitude_ft_per_s * 0.3048;  % m/s
slope_m_per_s = strain_rate_amplitude / head_rate_m_per_s;  % (1/s)/(m/s)
fprintf('  If head rate in m/s: %.4e m/s\n', head_rate_m_per_s);
fprintf('  Slope (1/s)/(m/s): %.4e\n', slope_m_per_s);
fprintf('  To convert to (1/s)/(ft/s): multiply by 0.3048\n');
fprintf('  Slope (1/s)/(ft/s): %.4e\n', slope_m_per_s * 0.3048);

% Maybe advisor uses different gauge length?
fprintf('\n=== TESTING DIFFERENT GAUGE LENGTHS ===\n');
for L_test = [1, 5, 10]
    strain_test = displacement_rate_amplitude / (L_test * 1e9);
    slope_test = strain_test / head_rate_amplitude_ft_per_s;
    fprintf('  L = %.1f m: strain = %.4e 1/s, slope = %.4e (1/s)/(ft/s)\n', ...
        L_test, strain_test, slope_test);
end

% Check if advisor's calculation matches
fprintf('\n=== REVERSE CALCULATION ===\n');
fprintf('If advisor''s slope = 2.8434e-07 and strain = 1.3e-10:\n');
head_rate_calc = strain_rate_amplitude / 2.8434e-07;  % ft/s
head_rate_calc_ft_per_min = head_rate_calc * 60;  % ft/min
fprintf('  Required head rate: %.4f ft/s = %.2f ft/min\n', ...
    head_rate_calc, head_rate_calc_ft_per_min);
fprintf('  Advisor reported: 0.09 ft/min\n');
fprintf('  Difference: %.2fx\n', head_rate_calc_ft_per_min / 0.09);

fprintf('\n=== CONCLUSION ===\n');
fprintf('Your calculation gives: %.4e (1/s)/(ft/s)\n', slope_advisor);
fprintf('Advisor reports: 2.8434e-07 (1/s)/(ft/s)\n');
fprintf('Difference: %.2fx\n', 2.8434e-07 / slope_advisor);
fprintf('\nPossible causes:\n');
fprintf('  1. Different head rate amplitude (advisor might use different time window)\n');
fprintf('  2. Different displacement rate amplitude (advisor might use different channel/depth)\n');
fprintf('  3. Unit conversion issue\n');
fprintf('  4. Advisor might be using characteristic length scaling\n');

