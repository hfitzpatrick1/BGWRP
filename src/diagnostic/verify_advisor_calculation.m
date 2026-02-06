%VERIFY_ADVISOR_CALCULATION Verify the advisor's calculation method
% This helps understand the 10x difference in slope

clear all
close all
clc

console_log('=== VERIFYING ADVISOR''S CALCULATION ===\n\n');

% Advisor's values
displacement_rate_amplitude = 1.3;  % nm/s (amplitude = max - min)
gauge_length_m = 10;  % m
head_rate_amplitude_ft_per_min = 0.09;  % ft/min

% Step 1: Calculate strain rate amplitude
strain_rate_amplitude = displacement_rate_amplitude / (gauge_length_m * 1e9);  % 1/s
console_log('Step 1: Strain rate amplitude\n');
console_log('  Displacement rate amplitude: %.2f nm/s\n', displacement_rate_amplitude);
console_log('  Gauge length: %.1f m = %.0e nm\n', gauge_length_m, gauge_length_m * 1e9);
console_log('  Strain rate = %.2f nm/s / %.0e nm = %.4e 1/s\n', ...
    displacement_rate_amplitude, gauge_length_m * 1e9, strain_rate_amplitude);

% Step 2: Convert head rate to ft/s
head_rate_amplitude_ft_per_s = head_rate_amplitude_ft_per_min / 60;  % ft/s
console_log('\nStep 2: Head rate amplitude\n');
console_log('  Head rate amplitude: %.2f ft/min = %.4f ft/s\n', ...
    head_rate_amplitude_ft_per_min, head_rate_amplitude_ft_per_s);

% Step 3: Calculate slope
slope_advisor = strain_rate_amplitude / head_rate_amplitude_ft_per_s;  % (1/s)/(ft/s)
console_log('\nStep 3: Slope calculation\n');
console_log('  Slope = strain rate / head rate\n');
console_log('  Slope = %.4e 1/s / %.4f ft/s = %.4e (1/s)/(ft/s)\n', ...
    strain_rate_amplitude, head_rate_amplitude_ft_per_s, slope_advisor);
console_log('  Advisor reported: 2.8434e-07 (1/s)/(ft/s)\n');
console_log('  Difference: %.2fx\n', 2.8434e-07 / slope_advisor);

% Check if there's a unit conversion issue
console_log('\n=== CHECKING FOR UNIT CONVERSION ISSUES ===\n');
console_log('If advisor uses different units:\n');

% Maybe advisor converts to m/s instead of ft/s?
head_rate_m_per_s = head_rate_amplitude_ft_per_s * 0.3048;  % m/s
slope_m_per_s = strain_rate_amplitude / head_rate_m_per_s;  % (1/s)/(m/s)
console_log('  If head rate in m/s: %.4e m/s\n', head_rate_m_per_s);
console_log('  Slope (1/s)/(m/s): %.4e\n', slope_m_per_s);
console_log('  To convert to (1/s)/(ft/s): multiply by 0.3048\n');
console_log('  Slope (1/s)/(ft/s): %.4e\n', slope_m_per_s * 0.3048);

% Maybe advisor uses different gauge length?
console_log('\n=== TESTING DIFFERENT GAUGE LENGTHS ===\n');
for L_test = [1, 5, 10]
    strain_test = displacement_rate_amplitude / (L_test * 1e9);
    slope_test = strain_test / head_rate_amplitude_ft_per_s;
    console_log('  L = %.1f m: strain = %.4e 1/s, slope = %.4e (1/s)/(ft/s)\n', ...
        L_test, strain_test, slope_test);
end

% Check if advisor's calculation matches
console_log('\n=== REVERSE CALCULATION ===\n');
console_log('If advisor''s slope = 2.8434e-07 and strain = 1.3e-10:\n');
head_rate_calc = strain_rate_amplitude / 2.8434e-07;  % ft/s
head_rate_calc_ft_per_min = head_rate_calc * 60;  % ft/min
console_log('  Required head rate: %.4f ft/s = %.2f ft/min\n', ...
    head_rate_calc, head_rate_calc_ft_per_min);
console_log('  Advisor reported: 0.09 ft/min\n');
console_log('  Difference: %.2fx\n', head_rate_calc_ft_per_min / 0.09);

console_log('\n=== CONCLUSION ===\n');
console_log('Your calculation gives: %.4e (1/s)/(ft/s)\n', slope_advisor);
console_log('Advisor reports: 2.8434e-07 (1/s)/(ft/s)\n');
console_log('Difference: %.2fx\n', 2.8434e-07 / slope_advisor);
console_log('\nPossible causes:\n');
console_log('  1. Different head rate amplitude (advisor might use different time window)\n');
console_log('  2. Different displacement rate amplitude (advisor might use different channel/depth)\n');
console_log('  3. Unit conversion issue\n');
console_log('  4. Advisor might be using characteristic length scaling\n');

