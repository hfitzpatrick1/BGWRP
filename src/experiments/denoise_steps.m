function denoise_steps(input_csv, output_csv, smooth_window)
%DENOISE_STEPS Apply light smoothing to reduce noise while preserving steps
%
% Usage: denoise_steps(input_csv, output_csv, smooth_window)
%
% smooth_window: smoothing window in points (default: 5-10 for light smoothing)

if nargin < 3
    smooth_window = 7;  % Light smoothing
end

fprintf('=== DENOISING WITH %d-POINT SMOOTHING ===\n', smooth_window);

%% Load data
data = readtable(input_csv);
col_names = data.Properties.VariableNames;

time_sec = data.(col_names{1});
drawdown_ft = data.(col_names{2});

%% Apply light moving average smoothing
drawdown_smoothed = movmean(drawdown_ft, smooth_window, 'omitnan');

fprintf('Original data range: %.4f to %.4f ft\n', min(drawdown_ft), max(drawdown_ft));
fprintf('Smoothed data range: %.4f to %.4f ft\n', min(drawdown_smoothed), max(drawdown_smoothed));

%% Plot comparison
figure('Position', [50, 50, 1600, 800]);

subplot(2,1,1);
plot(time_sec, drawdown_ft, 'b-', 'LineWidth', 1);
yline(0, 'r--', 'Zero', 'LineWidth', 1.5);
ylabel('Drawdown (ft)');
title('ORIGINAL - with noise');
grid on;

subplot(2,1,2);
plot(time_sec, drawdown_smoothed, 'b-', 'LineWidth', 1.5);
yline(0, 'r--', 'Zero', 'LineWidth', 1.5);
xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title(sprintf('DENOISED - %d-point smoothing (steps preserved)', smooth_window));
grid on;

%% Export
export_table = table(time_sec, drawdown_smoothed, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_csv);

fprintf('\nExported to: %s\n', output_csv);
fprintf('Steps preserved with reduced noise!\n');

end
