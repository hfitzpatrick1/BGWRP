function export_corrected_to_csv(mat_file, output_csv, use_displacement)
%EXPORT_CORRECTED_TO_CSV Export corrected MAT data to CSV
%
% Usage:
%   export_corrected_to_csv(mat_file, output_csv, use_displacement)
%
% use_displacement = true: outputs Displacement (depth change, + = water dropped)
% use_displacement = false: outputs Drawdown (traditional pump test convention)

if nargin < 3
    use_displacement = false;
end

% Load the corrected data
data = load(mat_file);

% Extract variables
timestamps = data.Date;

% Calculate elapsed time in seconds from first timestamp
elapsed_time_sec = seconds(timestamps - timestamps(1));

if use_displacement
    % Displacement = actual depth change from baseline
    % Positive = water level dropped (depth increased)
    % This is for DAS correlation
    displacement_ft = -data.Drawdownft;  % Flip sign: drawdown was baseline - depth, displacement is depth - baseline
    displacement_m = displacement_ft * 0.3048;
    
    export_table = table(elapsed_time_sec, displacement_ft, displacement_m, ...
        'VariableNames', {'Time_sec', 'Displacement_ft', 'Displacement_m'});
    
    writetable(export_table, output_csv);
    
    fprintf('Exported %d points to: %s\n', height(export_table), output_csv);
    fprintf('Columns: Time_sec, Displacement_ft, Displacement_m\n');
    fprintf('Time range: 0 to %.1f seconds (%.1f hours)\n', max(elapsed_time_sec), max(elapsed_time_sec)/3600);
    fprintf('Max displacement: %.4f ft (%.4f m)\n', max(displacement_ft), max(displacement_m));
    fprintf('Convention: Positive = water level dropped\n');
else
    % Traditional drawdown for AQTESOLV
    drawdown_ft = data.Drawdownft;
    drawdown_m = drawdown_ft * 0.3048;
    
    export_table = table(elapsed_time_sec, drawdown_ft, drawdown_m, ...
        'VariableNames', {'Time_sec', 'Drawdown_ft', 'Drawdown_m'});
    
    writetable(export_table, output_csv);
    
    fprintf('Exported %d points to: %s\n', height(export_table), output_csv);
    fprintf('Columns: Time_sec, Drawdown_ft, Drawdown_m\n');
    fprintf('Time range: 0 to %.1f seconds (%.1f hours)\n', max(elapsed_time_sec), max(elapsed_time_sec)/3600);
    fprintf('Max drawdown: %.4f ft (%.4f m)\n', max(drawdown_ft), max(drawdown_m));
    fprintf('Convention: Traditional pump test (positive = drawdown)\n');
end

fprintf('\nExport complete!\n');

end
