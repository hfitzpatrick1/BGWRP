function plot_csv_quick(csv_file, pump_start_elapsed)
%PLOT_CSV_QUICK Quick plot of time series CSV
%
% Usage: plot_csv_quick(csv_file, pump_start_elapsed)
%
% pump_start_elapsed: time in seconds when pump starts (optional)

% Read the CSV
data = readtable(csv_file);

% Get column names
col_names = data.Properties.VariableNames;

% Assume first column is time, second is the value
time_col = data.(col_names{1});
value_col = data.(col_names{2});

% Create figure
figure('Position', [100, 100, 1400, 600]);

% Plot
plot(time_col, value_col, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Zero', 'LineWidth', 1.5);

% Add pump schedule markers (if time is in seconds and pump_start provided)
if nargin >= 2 && max(time_col) > 10000  % Likely in seconds
    pump_times = pump_start_elapsed + [0, 3600, 7200, 10800, 14400];
    rates = [50, 80, 110, 150, 0];
    
    for i = 1:length(pump_times)
        if pump_times(i) >= 0 && pump_times(i) <= max(time_col)
            xline(pump_times(i), 'k--', 'LineWidth', 1);
            if rates(i) > 0
                text(pump_times(i), max(ylim)*0.95, sprintf('%d GPM', rates(i)), ...
                    'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');
            else
                text(pump_times(i), max(ylim)*0.95, 'OFF', ...
                    'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');
            end
        end
    end
elseif nargin < 2
    console_log('Note: Pump schedule markers not shown (provide pump_start_elapsed as 2nd argument)\n');
end

xlabel(sprintf('%s', col_names{1}), 'FontSize', 12);
ylabel(sprintf('%s', col_names{2}), 'FontSize', 12);
title(sprintf('Plot: %s', csv_file), 'Interpreter', 'none', 'FontSize', 12);
grid on;

console_log('Plotted %d points\n', length(time_col));
console_log('Time range: %.1f to %.1f %s\n', min(time_col), max(time_col), col_names{1});
console_log('Value range: %.4f to %.4f %s\n', min(value_col), max(value_col), col_names{2});
console_log('Mean: %.4f, Max: %.4f\n', mean(value_col), max(value_col));

end
