%CHECK_STRAIN_CALCULATION Verify strain rate calculation using the correct formula
%
% Equation: ε̇(z,t) = [u̇(z + L, t) - u̇(z, t)] / L
%
% Where:
% - u̇ is displacement rate
% - L is gauge length (10 m)
% - ε̇ is strain rate

fprintf('\n=== STRAIN RATE CALCULATION CHECK ===\n\n');

fprintf('Correct formula: ε̇ = [u̇(z + L) - u̇(z)] / L\n\n');

gauge_length_m = 10;
spatial_resolution_m = 0.25;  % 0.2496 m per channel
channels_per_gauge = gauge_length_m / spatial_resolution_m;

fprintf('System parameters:\n');
fprintf('  Gauge length (L): %.1f m\n', gauge_length_m);
fprintf('  Spatial resolution: %.4f m per channel\n', spatial_resolution_m);
fprintf('  Channels per gauge length: %.1f channels\n', channels_per_gauge);
fprintf('  Scaling factor: 0.9997\n\n');

fprintf('Current calculation:\n');
fprintf('  strain = displacement_rate / (L * 1e9)\n');
fprintf('  This assumes displacement_rate is already the DIFFERENCE\n');
fprintf('  OR we''re using a single channel incorrectly\n\n');

% Example: if displacement rate at channel z is 0.1 nm/s
displacement_z = 0.1;  % nm/s at channel z
displacement_z_plus_L = 0.2;  % nm/s at channel z+L (example)

% Correct calculation
difference_nm_per_s = displacement_z_plus_L - displacement_z;
strain_correct = difference_nm_per_s / (gauge_length_m * 1e9);  % Convert nm to m

fprintf('Example calculation:\n');
fprintf('  u̇(z) = %.2f nm/s\n', displacement_z);
fprintf('  u̇(z+L) = %.2f nm/s\n', displacement_z_plus_L);
fprintf('  Difference = %.2f nm/s\n', difference_nm_per_s);
fprintf('  ε̇ = %.2f / (%.0f * 1e9) = %.2e 1/s\n', difference_nm_per_s, gauge_length_m, strain_correct);

% Current (wrong if using single channel)
strain_wrong = displacement_z / (gauge_length_m * 1e9);
fprintf('\nIf we used single channel (WRONG):\n');
fprintf('  ε̇ = %.2f / (%.0f * 1e9) = %.2e 1/s\n', displacement_z, gauge_length_m, strain_wrong);
fprintf('  This is %.1f× smaller than correct!\n', strain_correct / strain_wrong);

fprintf('\n=== KEY QUESTION ===\n');
fprintf('Does your DAS system output:\n');
fprintf('  A) Single-point displacement rate at each channel?\n');
fprintf('  B) Already-calculated difference across gauge length?\n');
fprintf('  C) Strain rate directly?\n\n');

fprintf('If A: We need to calculate difference between channels L apart\n');
fprintf('If B: Current calculation should be correct\n');
fprintf('If C: No conversion needed!\n');

