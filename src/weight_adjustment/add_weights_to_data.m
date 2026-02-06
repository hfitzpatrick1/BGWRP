function add_weights_to_data(input_csv, output_csv, weight_ranges)
%ADD_WEIGHTS_TO_DATA Add custom weights to observation data for AQTESOLV
%
% Usage: add_weights_to_data(input_csv, output_csv, weight_ranges)
%
% weight_ranges: Cell array of {start_time, end_time, weight}
%
% Example:
%   weights = {
%       0,     1000,  0.5;    % Early time - lower weight
%       1000,  5000,  1.0;    % Good data - full weight
%       5000,  10000, 0.3;    % Noisy section - low weight
%       10000, 20000, 1.0     % Recovery - full weight
%   };
%   add_weights_to_data('input.csv', 'output.csv', weights);

fprintf('=== ADDING WEIGHTS TO DATA ===\n');

%% Load data
data = readtable(input_csv);
time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

fprintf('Loaded %d points\n', length(time_sec));

%% Initialize weights (default = 1.0)
weights = ones(length(time_sec), 1);

%% Apply weight ranges
for i = 1:size(weight_ranges, 1)
    start_time = weight_ranges{i, 1};
    end_time = weight_ranges{i, 2};
    weight_value = weight_ranges{i, 3};
    
    % Find points in this range
    mask = time_sec >= start_time & time_sec <= end_time;
    weights(mask) = weight_value;
    
    fprintf('Range %.0f-%.0f sec: weight=%.2f (%d points)\n', ...
        start_time, end_time, weight_value, sum(mask));
end

%% Plot to visualize weights
figure('Position', [50, 50, 1600, 800]);

subplot(2,1,1);
plot(time_sec, drawdown_ft, 'b-', 'LineWidth', 1.5);
ylabel('Drawdown (ft)');
title('Drawdown Data');
grid on;

subplot(2,1,2);
plot(time_sec, weights, 'r-', 'LineWidth', 2);
ylabel('Weight');
xlabel('Time (seconds)');
title('Observation Weights');
ylim([0, 1.2]);
grid on;

% Add weight range labels
hold on;
for i = 1:size(weight_ranges, 1)
    start_time = weight_ranges{i, 1};
    end_time = weight_ranges{i, 2};
    weight_value = weight_ranges{i, 3};
    mid_time = (start_time + end_time) / 2;
    text(mid_time, weight_value + 0.05, sprintf('%.2f', weight_value), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);
end

%% Export with weights
export_table = table(time_sec, drawdown_ft, weights, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft', 'Weight'});

writetable(export_table, output_csv);

fprintf('\n✓ Exported to: %s\n', output_csv);
fprintf('✓ Ready for AQTESOLV with custom weights!\n');

end
