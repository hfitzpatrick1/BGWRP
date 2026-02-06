% Flatten pumping well plateaus for AQTESOLV
% Creates perfectly flat steps like the observation well

input_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PT01a_PUMPING_WELL_AQTESOLV.csv';
output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PT01a_PUMPING_WELL_FLAT.csv';

%% Load processed pumping well data
data = readtable(input_file);
time_sec = data.Time_sec;
drawdown_ft = data.Drawdown_ft;

console_log('=== FLATTENING PUMPING WELL PLATEAUS ===\n');

%% Define pump rate periods and flatten each
pump_times = [0, 3600, 7200, 10800, 14400, 18000];
rates = [50, 80, 110, 150, 0];

drawdown_flat = drawdown_ft;

% First, apply heavy smoothing to get stable plateau values
drawdown_smooth = movmean(drawdown_ft, 100, 'omitnan');

for i = 1:length(rates)
    % Define plateau period - skip only 10 seconds for sharp transitions
    period_start = pump_times(i) + 10;
    period_end = pump_times(i+1) - 10;
    
    % Find points in this plateau
    plateau_mask = time_sec >= period_start & time_sec <= period_end;
    
    if sum(plateau_mask) > 10
        % Get median of middle 80% for best stability
        plateau_values = drawdown_smooth(plateau_mask);
        sorted_vals = sort(plateau_values);
        mid_start = floor(length(sorted_vals) * 0.1);
        mid_end = ceil(length(sorted_vals) * 0.9);
        plateau_value = median(sorted_vals(mid_start:mid_end), 'omitnan');
        
        % Make PERFECTLY FLAT - replace entire plateau
        drawdown_flat(plateau_mask) = plateau_value;
        
        console_log('Rate %d GPM: Flattened at %.3f ft (%d points)\n', ...
            rates(i), plateau_value, sum(plateau_mask));
    end
end

%% Create sharp vertical transitions
drawdown_final = drawdown_flat;

% For transition regions (10 seconds before each rate change), 
% create sharp vertical steps
for i = 2:length(pump_times)-1
    trans_start = pump_times(i) - 5;
    trans_end = pump_times(i) + 5;
    trans_mask = time_sec >= trans_start & time_sec <= trans_end;
    
    if sum(trans_mask) > 0
        % Get values before and after
        before_val = drawdown_flat(find(time_sec < trans_start, 1, 'last'));
        after_val = drawdown_flat(find(time_sec > trans_end, 1, 'first'));
        
        % Create sharp step
        trans_times = time_sec(trans_mask);
        mid_time = pump_times(i);
        drawdown_final(trans_mask) = before_val + ...
            (after_val - before_val) * (trans_times >= mid_time);
    end
end

%% Export
export_table = table(time_sec, drawdown_final, ...
    'VariableNames', {'Time_sec', 'Drawdown_ft'});

writetable(export_table, output_file);

console_log('\n✓ Exported: %s\n', output_file);
console_log('✓ Perfectly flat plateaus for AQTESOLV!\n');

%% Plot (AQTESOLV style with Displacement)
figure('Position', [50, 50, 1400, 600]);

% Downsample for cleaner plotting (plot every 10th point as marker)
plot_every = 10;
time_plot = time_sec(1:plot_every:end);
disp_plot = drawdown_final(1:plot_every:end);

plot(time_plot, disp_plot, 'ko', 'MarkerSize', 3, 'MarkerFaceColor', 'k');
hold on;
plot(time_sec, drawdown_final, 'b-', 'LineWidth', 1.5);

% Add vertical lines at rate changes
for i = 2:length(pump_times)-1
    if pump_times(i) <= max(time_sec)
        xline(pump_times(i), 'b-', 'LineWidth', 0.5);
    end
end

xlabel('Time (sec)', 'FontSize', 12);
ylabel('Displacement (ft)', 'FontSize', 12);
title('Pumping Well PT-01a - Displacement vs Time', 'FontSize', 14);
grid on;
set(gca, 'FontSize', 11);

% Set nice axis limits
xlim([0, max(time_sec)]);
ylim([0, max(drawdown_final)*1.1]);

console_log('\n=== FILES FOR AQTESOLV ===\n');
console_log('1. Pumping Well: PT01a_PUMPING_WELL_FLAT.csv\n');
console_log('2. Observation Well: PM7_Zone2_FINAL_AQTESOLV.csv\n');
console_log('3. Pump Schedule: Pump_Schedule_AQTESOLV.csv\n');
