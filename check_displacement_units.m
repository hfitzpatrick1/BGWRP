%CHECK_DISPLACEMENT_UNITS Check if displacement rate units are correct
%
% If displacement is actually in µm/s instead of nm/s, that would cause
% exactly a 1000× error (since 1 µm = 1000 nm)

fprintf('\n=== DISPLACEMENT RATE UNIT CHECK ===\n\n');

% Example displacement values
displacement_nm_per_s = 0.1;  % If this is what we think it is
displacement_um_per_s = 0.1;  % If it's actually in µm/s

gauge_length_m = 10;

% Current calculation (assuming nm/s)
strain_current = displacement_nm_per_s / (gauge_length_m * 1e9);
fprintf('If displacement = %.2f nm/s:\n', displacement_nm_per_s);
fprintf('  Strain = %.2e 1/s\n', strain_current);

% If actually in µm/s
strain_if_um = displacement_um_per_s / (gauge_length_m * 1e6);  % µm/s / (m * 1e6)
fprintf('\nIf displacement = %.2f µm/s (1000× larger):\n', displacement_um_per_s);
fprintf('  Strain = %.2e 1/s (%.0f× larger)\n', strain_if_um, strain_if_um/strain_current);

% Check typical DAS displacement rate ranges
fprintf('\nTypical DAS displacement rate ranges:\n');
fprintf('  If in nm/s: 0.01 to 1.0 nm/s\n');
fprintf('  If in µm/s: 0.01 to 1.0 µm/s (would appear as 0.01 to 1.0 if misread as nm/s)\n');
fprintf('  If in m/s: 1e-11 to 1e-9 m/s\n\n');

fprintf('QUESTION: What are typical displacement rate values in your data?\n');
fprintf('  - If 0.1-1.0 range: likely nm/s or µm/s\n');
fprintf('  - If 1e-9 to 1e-11 range: likely m/s\n');
fprintf('  - If 0.1-1.0 and you get 1000× error: probably µm/s, not nm/s!\n');

