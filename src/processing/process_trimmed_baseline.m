function process_trimmed_baseline(input_csv, output_csv, smooth_window)
%PROCESS_TRIMMED_BASELINE Process manually trimmed baseline data
%
% Usage: process_trimmed_baseline(input_csv, output_csv, smooth_window)

if nargin < 3
    smooth_window = 50;  % Heavy smoothing for flat plateaus
end

fprintf('=== PROCESSING TRIMMED BASELINE DATA ===\n');

%% Load data
data = readtable(input_csv);

% Remove any empty rows
data = data(~isnan(data.Time_sec), :);

time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

fprintf('Loaded %d points\n', length(time_sec));
fprintf('Time range: %.1f to %.1f seconds\n', min(time_sec), max(time_sec));

%% Apply smoothing
% Use both moving average AND Savitzky-Golay for maximum flatness
drawdown_smoothed = movmean(drawdown_ft, smooth_window, 'omitnan');
drawdown_smoothed = sgolayfilt(drawdown_smoothed, 2, min(smooth_window*2+1, 201));  % Polynomial smoothing

fprintf('Applied %d-point smoothing + Savitzky-Golay\n', smooth_window);
fprintf('Max value: %.4f ft\n', max(drawdown_smoothed));

%% Plot
figure('Position', [50, 50, 1600, 600]);
plot(time_sec, drawdown_smoothed, 'b-', 'LineWidth', 2);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 2);
xlabel('Time (seconds)');
ylabel('Displacement (ft)');
title(sprintf('Trimmed & Smoothed (%d-point) - Ready for AQTESOLV', smooth_window));
grid on;

%% Export
export_table = table(time_sec, drawdown_smoothed, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_csv);

fprintf('\nExported to: %s\n', output_csv);
fprintf('Ready for AQTESOLV!\n');

end
