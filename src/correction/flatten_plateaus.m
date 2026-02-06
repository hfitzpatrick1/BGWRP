function flatten_plateaus(input_csv, output_csv, pump_start_elapsed)
%FLATTEN_PLATEAUS Force plateaus to be perfectly flat at each pump rate
%
% Usage: flatten_plateaus(input_csv, output_csv, pump_start_elapsed)
%
% Creates perfectly flat horizontal lines for each pump rate period

fprintf('=== FLATTENING PLATEAUS ===\n');

%% Load data
data = readtable(input_csv);
data = data(~isnan(data.Time_sec), :);

time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

fprintf('Loaded %d points\n', length(time_sec));

%% Define pump rate periods
pump_times = pump_start_elapsed + [0, 3600, 7200, 10800, 14400, 18000];  % Add end buffer
rates = [50, 80, 110, 150, 0];

%% First apply heavy smoothing to entire dataset
drawdown_smooth = movmean(drawdown_ft, 100, 'omitnan');  % Heavy smoothing first

%% Then flatten each plateau
drawdown_flat = drawdown_smooth;

for i = 1:length(rates)
    % Define plateau period (skip first 3 min and last 3 min of each period)
    period_start = pump_times(i) + 180;  % 3 min after rate change
    period_end = pump_times(i+1) - 180;  % 3 min before next change
    
    % Find points in this plateau
    plateau_mask = time_sec >= period_start & time_sec <= period_end;
    
    if sum(plateau_mask) > 0
        % Calculate mean of the MIDDLE 50% of this plateau (most stable part)
        plateau_values = drawdown_smooth(plateau_mask);
        sorted_vals = sort(plateau_values);
        mid_start = floor(length(sorted_vals) * 0.25);
        mid_end = ceil(length(sorted_vals) * 0.75);
        plateau_value = mean(sorted_vals(mid_start:mid_end), 'omitnan');
        
        % Replace with perfectly flat value
        drawdown_flat(plateau_mask) = plateau_value;
        
        fprintf('Plateau %d (%d GPM): Flattened %d points at %.4f ft\n', ...
            i, rates(i), sum(plateau_mask), plateau_value);
    end
end

%% Smooth transitions 
% Apply moderate smoothing to transition regions for clean steps
drawdown_final = drawdown_flat;

% Smooth transition regions (between plateaus)
transition_window = 10;
for i = 1:length(time_sec)
    % Check if this point is in a plateau
    in_plateau = false;
    for j = 1:length(rates)
        period_start = pump_times(j) + 180;
        period_end = pump_times(j+1) - 180;
        if time_sec(i) >= period_start && time_sec(i) <= period_end
            in_plateau = true;
            break;
        end
    end
    
    % If in transition, apply smoothing
    if ~in_plateau && i > transition_window && i <= length(time_sec) - transition_window
        window_idx = (i-transition_window):(i+transition_window);
        drawdown_final(i) = mean(drawdown_flat(window_idx), 'omitnan');
    end
end

%% Plot
figure('Position', [50, 50, 1600, 800]);

subplot(2,1,1);
plot(time_sec, drawdown_ft, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);
ylabel('Displacement (ft)');
title('ORIGINAL - with oscillations');
grid on;

subplot(2,1,2);
plot(time_sec, drawdown_final, 'b-', 'LineWidth', 2);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 2);

% Add pump rate labels
for i = 1:length(rates)
    if rates(i) > 0
        period_mid = (pump_times(i) + pump_times(i+1)) / 2;
        if period_mid <= max(time_sec)
            text(period_mid, max(ylim)*0.5, sprintf('%d GPM', rates(i)), ...
                'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', 'yellow', ...
                'HorizontalAlignment', 'center');
        end
    end
end

xlabel('Time (seconds)');
ylabel('Displacement (ft)');
title('FLATTENED - Perfectly flat plateaus');
grid on;

%% Export
export_table = table(time_sec, drawdown_final, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_csv);

fprintf('\nExported to: %s\n', output_csv);
fprintf('Plateaus are now perfectly flat!\n');

end
