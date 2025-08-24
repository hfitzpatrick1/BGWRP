
%% PM-07 Recovery Analysis - Using Original Time Windows
% This script analyzes recovery periods using the same time windows as the 
% original PM07_PT01(a,b,c)_Analysis.m files
% 
% Time windows from original analysis:
% - PT-01a: 20:44-20:49 UTC (5 minutes)
% - PT-01b: 19:25-20:28 UTC (63 minutes) - using shortened plot window 19:29-19:33 UTC (4 minutes)
% - PT-01c: 19:14-19:18 UTC (4 minutes)

%% Setup
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));  % Go up two levels from _ref/Hannah_2024_08/ to BGWRP/
data_dir = fullfile(project_dir, 'data');

%% Define recovery time windows (from original analysis files)
% PT-01a recovery window
recovery_start_a = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
recovery_end_a = datetime(2023,11,7,20,48,00,00,'TimeZone','UTC');

% PT-01b recovery window  
recovery_start_b = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
recovery_end_b = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');

% PT-01b plot window (shortened for visualization)
plot_start_b = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
plot_end_b = datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');

% PT-01c recovery window
recovery_start_c = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
recovery_end_c = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

fprintf('=== RECOVERY TIME WINDOWS (from original analysis) ===\n');
fprintf('PT-01a: %s to %s (%.1f minutes)\n', recovery_start_a, recovery_end_a, minutes(recovery_end_a - recovery_start_a));
fprintf('PT-01b: %s to %s (%.1f minutes)\n', recovery_start_b, recovery_end_b, minutes(recovery_end_b - recovery_start_b));
fprintf('PT-01b plot window: %s to %s (%.1f minutes)\n', plot_start_b, plot_end_b, minutes(plot_end_b - plot_start_b));
fprintf('PT-01c: %s to %s (%.1f minutes)\n', recovery_start_c, recovery_end_c, minutes(recovery_end_c - recovery_start_c));

%% Load all head data files
fprintf('\n=== LOADING ALL HEAD DATA FILES ===\n');

% Define available head data files for each test
head_files_a = {'head_a_z2.mat', 'head_a_z3.mat', 'head_a_z4.mat', 'head_a_z5.mat'};
head_files_b = {'head_b_z2.mat', 'head_b_z3.mat', 'head_b_z4.mat', 'head_b_z5.mat'};
head_files_c = {'head_c_z2.mat', 'head_c_z3.mat', 'head_c_z4.mat', 'head_c_z5.mat'};

%% Load all PT-01a head data
fprintf('\nPT-01a head data files:\n');
data_a = struct();
for i = 1:length(head_files_a)
    file_path = fullfile(data_dir, 'head', head_files_a{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = head_files_a{i}(8:9); % Extract z1, z2, etc.
        data_a.(zone_name).Date = Date;
        data_a.(zone_name).Date.TimeZone = 'UTC';
        data_a.(zone_name).Drawdownft = Drawdownft;
        data_a.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_a.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s\n', ...
            zone_name, data_a.(zone_name).Depthft, data_a.(zone_name).n_points, ...
            min(Date), max(Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', head_files_a{i});
    end
end

%% Load all PT-01b head data
fprintf('\nPT-01b head data files:\n');
data_b = struct();
for i = 1:length(head_files_b)
    file_path = fullfile(data_dir, 'head', head_files_b{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = head_files_b{i}(8:9); % Extract z1, z2, etc.
        data_b.(zone_name).Date = Date;
        data_b.(zone_name).Date.TimeZone = 'UTC';
        data_b.(zone_name).Drawdownft = Drawdownft;
        data_b.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_b.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s\n', ...
            zone_name, data_b.(zone_name).Depthft, data_b.(zone_name).n_points, ...
            min(Date), max(Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', head_files_b{i});
    end
end

%% Load all PT-01c head data
fprintf('\nPT-01c head data files:\n');
data_c = struct();
for i = 1:length(head_files_c)
    file_path = fullfile(data_dir, 'head', head_files_c{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = head_files_c{i}(8:9); % Extract z2, z3, etc.
        
        % Adjust PT-01c head data timestamps by +10 seconds to account for transducer delay
        data_c.(zone_name).Date = Date + seconds(10);
        data_c.(zone_name).Date.TimeZone = 'UTC';
        data_c.(zone_name).Drawdownft = Drawdownft;
        data_c.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_c.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s (adjusted +10s)\n', ...
            zone_name, data_c.(zone_name).Depthft, data_c.(zone_name).n_points, ...
            min(data_c.(zone_name).Date), max(data_c.(zone_name).Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', head_files_c{i});
    end
end

%% Load DAS data
fprintf('\n=== LOADING DAS DATA ===\n');

% PT-01a DAS data
load(fullfile(data_dir, 'DAS Data', 'PM07_01a_1Hz.mat'));
data1Hz_a = decdata;
DASStart_a = datetime(2023,11,7,16,45,36,00,'TimeZone','UTC');
C1_a = 513;
MperChan_a = 0.25;

% PT-01b DAS data
load(fullfile(data_dir, 'DAS Data', 'PM07_01b_1Hz.mat'));
data1Hz_b = decdata;
DASStart_b = datetime(2023,10,31,15,29,36,00,'TimeZone','UTC');
C1_b = 513;
MperChan_b = 0.25;

% PT-01c DAS data
load(fullfile(data_dir, 'DAS Data', 'PM07_01c_1Hz.mat'));
if exist('decdata', 'var')
    data1Hz_c = decdata;
else
    data1Hz_c = data1Hz;
end
DASStart_c = datetime(2023,10,24,15,02,36,00,'TimeZone','UTC');
C1_c = 110;
MperChan_c = 0.25;

fprintf('DAS data loaded successfully for all three tests\n');

%% Calculate recovery drawdown rates for all zones
fprintf('\n=== CALCULATING RECOVERY DRAWDOWN RATES ===\n');

smooth_window = 10;  % 10-point moving average

% Function to calculate recovery drawdown rate for a zone
function [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(Date, Drawdownft, recovery_start, recovery_end, smooth_window)
    % Filter to recovery period
    recovery_mask = Date >= recovery_start & Date <= recovery_end;
    recovery_data.Date = Date(recovery_mask);
    recovery_data.Drawdownft = Drawdownft(recovery_mask);
    
    if length(recovery_data.Date) < 2
        recovery_rate_ms = [];
        recovery_time = [];
        return;
    end
    
    % Calculate recovery rate (positive = recovery, negative = continued drawdown)
    drawdown_smooth = movmean(recovery_data.Drawdownft, smooth_window);
    recovery_rate = diff(drawdown_smooth) ./ seconds(diff(recovery_data.Date));
    recovery_rate_ms = recovery_rate * 0.3048;  % Convert to m/s (ft/min * 0.3048 m/ft / 60 s/min)
    recovery_time = recovery_data.Date(1:end-1);
    
    % Note: Positive rate means water level is rising (recovery)
    % Negative rate means water level is still falling
end

%% Calculate recovery rates for PT-01a zones
zones_a = fieldnames(data_a);
fprintf('\nPT-01a recovery rates:\n');
for i = 1:length(zones_a)
    zone = zones_a{i};
    [data_a.(zone).recovery_rate_ms, data_a.(zone).recovery_time, data_a.(zone).recovery_data] = ...
        calc_recovery_rate(data_a.(zone).Date, data_a.(zone).Drawdownft, recovery_start_a, recovery_end_a, smooth_window);
    
    if ~isempty(data_a.(zone).recovery_rate_ms)
        max_recovery_rate = max(data_a.(zone).recovery_rate_ms);
        min_recovery_rate = min(data_a.(zone).recovery_rate_ms);
        avg_recovery_rate = mean(data_a.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s, Min=%.6f m/s\n', ...
            zone, data_a.(zone).Depthft, avg_recovery_rate, max_recovery_rate, min_recovery_rate);
    else
        fprintf('  %s (%.1f ft): NO DATA IN RECOVERY WINDOW\n', zone, data_a.(zone).Depthft);
    end
end

%% Calculate recovery rates for PT-01b zones (using plot window)
zones_b = fieldnames(data_b);
fprintf('\nPT-01b recovery rates (using plot window):\n');
for i = 1:length(zones_b)
    zone = zones_b{i};
    [data_b.(zone).recovery_rate_ms, data_b.(zone).recovery_time, data_b.(zone).recovery_data] = ...
        calc_recovery_rate(data_b.(zone).Date, data_b.(zone).Drawdownft, plot_start_b, plot_end_b, smooth_window);
    
    if ~isempty(data_b.(zone).recovery_rate_ms)
        max_recovery_rate = max(data_b.(zone).recovery_rate_ms);
        min_recovery_rate = min(data_b.(zone).recovery_rate_ms);
        avg_recovery_rate = mean(data_b.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s, Min=%.6f m/s\n', ...
            zone, data_b.(zone).Depthft, avg_recovery_rate, max_recovery_rate, min_recovery_rate);
    else
        fprintf('  %s (%.1f ft): NO DATA IN PLOT WINDOW\n', zone, data_b.(zone).Depthft);
    end
end

%% Calculate recovery rates for PT-01c zones
zones_c = fieldnames(data_c);
fprintf('\nPT-01c recovery rates:\n');
for i = 1:length(zones_c)
    zone = zones_c{i};
    fprintf('Processing zone: %s\n', zone);
    [data_c.(zone).recovery_rate_ms, data_c.(zone).recovery_time, data_c.(zone).recovery_data] = ...
        calc_recovery_rate(data_c.(zone).Date, data_c.(zone).Drawdownft, recovery_start_c, recovery_end_c, smooth_window);
    
    if ~isempty(data_c.(zone).recovery_rate_ms)
        max_recovery_rate = max(data_c.(zone).recovery_rate_ms);
        min_recovery_rate = min(data_c.(zone).recovery_rate_ms);
        avg_recovery_rate = mean(data_c.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s, Min=%.6f m/s\n', ...
            zone, data_c.(zone).Depthft, avg_recovery_rate, max_recovery_rate, min_recovery_rate);
    else
        fprintf('  %s (%.1f ft): NO DATA IN RECOVERY WINDOW\n', zone, data_c.(zone).Depthft);
    end
end

%% Get DAS strain rates for recovery periods
fprintf('\n=== CALCULATING DAS STRAIN RATES FOR RECOVERY PERIODS ===\n');

% Calculate depth arrays for DAS data and find channels in middle of pumping zones
chan_a = 1:size(data1Hz_a,2);
depthft_a_das = ((chan_a-C1_a-1)*MperChan_a)/.3048;
zone_min_ft_a = 450; zone_max_ft_a = 510;
zone_mid_a = (zone_min_ft_a + zone_max_ft_a)/2; % 480 ft
[~, channel_idx_a] = min(abs(depthft_a_das - zone_mid_a));

chan_b = 1:size(data1Hz_b,2);
depthft_b_das = ((chan_b-C1_b-1)*MperChan_b)/.3048;
zone_min_ft_b = 350; zone_max_ft_b = 400;
zone_mid_b = (zone_min_ft_b + zone_max_ft_b)/2; % 375 ft
[~, channel_idx_b] = min(abs(depthft_b_das - zone_mid_b));

chan_c = 1:size(data1Hz_c,2);
depthft_c_das = ((chan_c-C1_c-1)*MperChan_c)/.3048;
zone_min_ft_c = 260; zone_max_ft_c = 310;
zone_mid_c = (zone_min_ft_c + zone_max_ft_c)/2; % 285 ft
[~, channel_idx_c] = min(abs(depthft_c_das - zone_mid_c));

% Create time arrays and strain rates
Tdas_a = DASStart_a + seconds(0:size(data1Hz_a,1)-1);
Tdas_b = DASStart_b + seconds(0:size(data1Hz_b,1)-1) + seconds(120); % Shift PT-01b DAS data by 2 minutes
% Adjust PT-01c DAS data timing by +90 seconds (1 minute 30 seconds) to align with head data
Tdas_c = DASStart_c + seconds(0:size(data1Hz_c,1)-1) + seconds(90);

mdata_a = movmean(data1Hz_a, 10, 1);
mdata_b = movmean(data1Hz_b, 10, 1);
mdata_c = movmean(data1Hz_c, 10, 1);

strain_rate_a = mdata_a(:, channel_idx_a);
strain_rate_b = mdata_b(:, channel_idx_b);
strain_rate_c = mdata_c(:, channel_idx_c);

% Filter DAS data to recovery periods
recovery_mask_a = Tdas_a >= recovery_start_a & Tdas_a <= recovery_end_a;
recovery_mask_b = Tdas_b >= plot_start_b & Tdas_b <= plot_end_b;  % Use plot window for PT-01b
recovery_mask_c = Tdas_c >= recovery_start_c & Tdas_c <= recovery_end_c;

% Debug: Check mask results
fprintf('\n=== DEBUG: RECOVERY MASK RESULTS ===\n');
fprintf('PT-01a: Total DAS points: %d, Masked points: %d\n', length(Tdas_a), sum(recovery_mask_a));
fprintf('PT-01b: Total DAS points: %d, Masked points: %d\n', length(Tdas_b), sum(recovery_mask_b));
fprintf('PT-01c: Total DAS points: %d, Masked points: %d\n', length(Tdas_c), sum(recovery_mask_c));

% Check if any data points are found in recovery window
if sum(recovery_mask_a) == 0
    fprintf('WARNING: No PT-01a data found in recovery window!\n');
end
if sum(recovery_mask_b) == 0
    fprintf('WARNING: No PT-01b data found in plot window!\n');
    fprintf('PT-01b DAS data range: %s to %s\n', min(Tdas_b), max(Tdas_b));
    fprintf('PT-01b plot window: %s to %s\n', plot_start_b, plot_end_b);
end
if sum(recovery_mask_c) == 0
    fprintf('WARNING: No PT-01c data found in recovery window!\n');
end

Tdas_recovery_a = Tdas_a(recovery_mask_a);
Tdas_recovery_b = Tdas_b(recovery_mask_b);
Tdas_recovery_c = Tdas_c(recovery_mask_c);

strain_rate_recovery_a = strain_rate_a(recovery_mask_a);
strain_rate_recovery_b = strain_rate_b(recovery_mask_b);
strain_rate_recovery_c = strain_rate_c(recovery_mask_c);

% Display selected channels and depths
fprintf('Selected DAS channels for strain rate analysis:\n');
fprintf('  PT-01a: Channel %d at depth %.1f ft (target: %.1f ft)\n', ...
    channel_idx_a, depthft_a_das(channel_idx_a), zone_mid_a);
fprintf('  PT-01b: Channel %d at depth %.1f ft (target: %.1f ft)\n', ...
    channel_idx_b, depthft_b_das(channel_idx_b), zone_mid_b);
fprintf('  PT-01c: Channel %d at depth %.1f ft (target: %.1f ft)\n', ...
    channel_idx_c, depthft_c_das(channel_idx_c), zone_mid_c);

fprintf('DAS recovery data points: PT-01a=%d, PT-01b=%d, PT-01c=%d\n', ...
    length(Tdas_recovery_a), length(Tdas_recovery_b), length(Tdas_recovery_c));

% Debug: Check time ranges for each test
fprintf('\n=== DEBUG: TIME RANGES ===\n');
fprintf('PT-01a: DAS data range: %s to %s\n', min(Tdas_a), max(Tdas_a));
fprintf('PT-01a: Recovery window: %s to %s\n', recovery_start_a, recovery_end_a);
fprintf('PT-01a: Filtered data range: %s to %s\n', min(Tdas_recovery_a), max(Tdas_recovery_a));

fprintf('PT-01b: DAS data range: %s to %s\n', min(Tdas_b), max(Tdas_b));
fprintf('PT-01b: Recovery window: %s to %s (63 min)\n', recovery_start_b, recovery_end_b);
fprintf('PT-01b: Analysis plot window: %s to %s (4 min)\n', plot_start_b, plot_end_b);
fprintf('PT-01b: Filtered data range: %s to %s\n', min(Tdas_recovery_b), max(Tdas_recovery_b));

fprintf('PT-01c: DAS data range: %s to %s\n', min(Tdas_c), max(Tdas_c));
fprintf('PT-01c: Recovery window: %s to %s\n', recovery_start_c, recovery_end_c);
fprintf('PT-01c: Filtered data range: %s to %s\n', min(Tdas_recovery_c), max(Tdas_recovery_c));

%% Create recovery comparison plots
fprintf('\n=== CREATING RECOVERY COMPARISON PLOTS ===\n');

%% Plot 1: DAS displacement and channel comparison
figure(1)
set(gcf, 'Position', [100, 100, 1200, 800])

% PT-01a displacement and channel comparison
subplot(3,2,1)
hold on
% Plot selected channel
plot(Tdas_recovery_a, strain_rate_recovery_a, 'k-', 'LineWidth', 3, 'DisplayName', sprintf('Selected: Ch%d (%.1f ft)', channel_idx_a, depthft_a_das(channel_idx_a)))

% Plot 5 channels above and below
channels_to_plot_a = max(1, channel_idx_a-5):min(size(data1Hz_a,2), channel_idx_a+5);
colors_a = lines(length(channels_to_plot_a));
for i = 1:length(channels_to_plot_a)
    ch = channels_to_plot_a(i);
    if ch ~= channel_idx_a
        strain_ch = movmean(data1Hz_a(:, ch), 10, 1);
        strain_ch_recovery = strain_ch(recovery_mask_a);
        plot(Tdas_recovery_a, strain_ch_recovery, 'Color', colors_a(i,:), 'LineWidth', 1, ...
             'DisplayName', sprintf('Ch%d (%.1f ft)', ch, depthft_a_das(ch)));
    end
end
% Set x-axis limits to match recovery window
xlim([recovery_start_a, recovery_end_a])
ylabel('Strain Rate (nm/s)')
title('PT-01a: Selected Channel vs Nearby Channels')
legend('Location', 'best', 'FontSize', 8)
grid on
hold off

% PT-01a displacement (cumulative)
subplot(3,2,2)
hold on
% Calculate cumulative displacement for selected channel
displacement_a = cumsum(strain_rate_recovery_a) * 1; % 1 second intervals
plot(Tdas_recovery_a, displacement_a, 'k-', 'LineWidth', 2)
% Set x-axis limits to match recovery window
xlim([recovery_start_a, recovery_end_a])
ylabel('Cumulative Displacement (nm)')
title('PT-01a: Cumulative Displacement')
grid on
hold off

% PT-01b displacement and channel comparison
subplot(3,2,3)
hold on
% Plot selected channel
plot(Tdas_recovery_b, strain_rate_recovery_b, 'k-', 'LineWidth', 3, 'DisplayName', sprintf('Selected: Ch%d (%.1f ft)', channel_idx_b, depthft_b_das(channel_idx_b)))

% Plot 5 channels above and below
channels_to_plot_b = max(1, channel_idx_b-5):min(size(data1Hz_b,2), channel_idx_b+5);
colors_b = lines(length(channels_to_plot_b));
for i = 1:length(channels_to_plot_b)
    ch = channels_to_plot_b(i);
    if ch ~= channel_idx_b
        strain_ch = movmean(data1Hz_b(:, ch), 10, 1);
        strain_ch_recovery = strain_ch(recovery_mask_b);
        plot(Tdas_recovery_b, strain_ch_recovery, 'Color', colors_b(i,:), 'LineWidth', 1, ...
             'DisplayName', sprintf('Ch%d (%.1f ft)', ch, depthft_b_das(ch)));
    end
end
% Set x-axis limits to match shortened plot window
xlim([plot_start_b, plot_end_b])
ylabel('Strain Rate (nm/s)')
title('PT-01b: Selected Channel vs Nearby Channels')
legend('Location', 'best', 'FontSize', 8)
grid on
hold off

% PT-01b displacement (cumulative)
subplot(3,2,4)
hold on
% Calculate cumulative displacement for selected channel
displacement_b = cumsum(strain_rate_recovery_b) * 1; % 1 second intervals
plot(Tdas_recovery_b, displacement_b, 'k-', 'LineWidth', 2)
% Set x-axis limits to match shortened plot window
xlim([plot_start_b, plot_end_b])
ylabel('Cumulative Displacement (nm)')
title('PT-01b: Cumulative Displacement')
grid on
hold off

% PT-01c displacement and channel comparison
subplot(3,2,5)
hold on
% Plot selected channel
plot(Tdas_recovery_c, strain_rate_recovery_c, 'k-', 'LineWidth', 3, 'DisplayName', sprintf('Selected: Ch%d (%.1f ft)', channel_idx_c, depthft_c_das(channel_idx_c)))

% Plot 5 channels above and below
channels_to_plot_c = max(1, channel_idx_c-5):min(size(data1Hz_c,2), channel_idx_c+5);
colors_c = lines(length(channels_to_plot_c));
for i = 1:length(channels_to_plot_c)
    ch = channels_to_plot_c(i);
    if ch ~= channel_idx_c
        strain_ch = movmean(data1Hz_c(:, ch), 10, 1);
        strain_ch_recovery = strain_ch(recovery_mask_c);
        plot(Tdas_recovery_c, strain_ch_recovery, 'Color', colors_c(i,:), 'LineWidth', 1, ...
             'DisplayName', sprintf('Ch%d (%.1f ft)', ch, depthft_c_das(ch)));
    end
end
% Set x-axis limits to match recovery window
xlim([recovery_start_c, recovery_end_c])
ylabel('Strain Rate (nm/s)')
title('PT-01c: Selected Channel vs Nearby Channels')
xlabel('Time (UTC)')
legend('Location', 'best', 'FontSize', 8)
grid on
hold off

% PT-01c displacement (cumulative)
subplot(3,2,6)
hold on
% Calculate cumulative displacement for selected channel
displacement_c = cumsum(strain_rate_recovery_c) * 1; % 1 second intervals
plot(Tdas_recovery_c, displacement_c, 'k-', 'LineWidth', 2)
% Set x-axis limits to match recovery window
xlim([recovery_start_c, recovery_end_c])
ylabel('Cumulative Displacement (nm)')
title('PT-01c: Cumulative Displacement')
xlabel('Time (UTC)')
grid on
hold off

% Add summary text
sgtitle('DAS Channel Comparison and Displacement Analysis', 'FontSize', 14, 'FontWeight', 'bold')

% Plot 2: All recovery rates for each test
figure(2)
subplot(3,1,1)
hold on
colors_a = lines(length(zones_a));
for i = 1:length(zones_a)
    zone = zones_a{i};
    if ~isempty(data_a.(zone).recovery_rate_ms)
        plot(data_a.(zone).recovery_time, data_a.(zone).recovery_rate_ms, ...
             'Color', colors_a(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_a.(zone).Depthft));
    end
end
ylabel('Recovery Rate (m/s)')
title('PT-01a: All Zones Recovery Rates (20:44-20:49 UTC)')
xlim([recovery_start_a, recovery_end_a])
legend('Location', 'best')
grid on
hold off

subplot(3,1,2)
hold on
colors_b = lines(length(zones_b));
for i = 1:length(zones_b)
    zone = zones_b{i};
    if ~isempty(data_b.(zone).recovery_rate_ms)
        plot(data_b.(zone).recovery_time, data_b.(zone).recovery_rate_ms, ...
             'Color', colors_b(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_b.(zone).Depthft));
    end
end
ylabel('Recovery Rate (m/s)')
title('PT-01b: All Zones Recovery Rates (19:25-20:28 UTC)')
xlim([plot_start_b, plot_end_b])
legend('Location', 'best')
grid on
hold off

subplot(3,1,3)
hold on
colors_c = lines(length(zones_c));
for i = 1:length(zones_c)
    zone = zones_c{i};
    if ~isempty(data_c.(zone).recovery_rate_ms)
        plot(data_c.(zone).recovery_time, data_c.(zone).recovery_rate_ms, ...
             'Color', colors_c(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_c.(zone).Depthft));
    end
end
ylabel('Recovery Rate (m/s)')
title('PT-01c: All Zones Recovery Rates (19:14-19:18 UTC)')
xlim([recovery_start_c, recovery_end_c])
xlabel('Time (UTC)')
legend('Location', 'best')
grid on
hold off

%% Plot 3: Recovery rate vs strain rate comparison (z2-z5 for all tests)
figure(3)

% PT-01a comparison - use z2-z5 with strain rate
subplot(3,1,1)
hold on
% Plot all zones z2-z5
colors_a = lines(4); % 4 zones: z2, z3, z4, z5
zone_names_a = {'z2', 'z3', 'z4', 'z5'};
for i = 1:length(zone_names_a)
    zone = zone_names_a{i};
    if ~isempty(data_a.(zone).recovery_rate_ms)
        plot(data_a.(zone).recovery_time, data_a.(zone).recovery_rate_ms, ...
             'Color', colors_a(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_a.(zone).Depthft));
    end
end
% Add strain rate on secondary y-axis
yyaxis right
plot(Tdas_recovery_a, strain_rate_recovery_a, 'k-', 'LineWidth', 2, 'DisplayName', 'Strain Rate')
ylabel('Strain Rate (nm/s)')
yyaxis left
ylabel('Recovery Rate (m/s)')
title('PT-01a: Recovery Rates (z2-z5) vs Strain Rate')
xlim([recovery_start_a, recovery_end_a])
xlabel('Time (UTC)')
legend('Location', 'best')
grid on
hold off

% PT-01b comparison - use z2-z5 with strain rate
subplot(3,1,2)
hold on
% Plot all zones z2-z5
colors_b = lines(4); % 4 zones: z2, z3, z4, z5
zone_names_b = {'z2', 'z3', 'z4', 'z5'};
for i = 1:length(zone_names_b)
    zone = zone_names_b{i};
    if ~isempty(data_b.(zone).recovery_rate_ms)
        plot(data_b.(zone).recovery_time, data_b.(zone).recovery_rate_ms, ...
             'Color', colors_b(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_b.(zone).Depthft));
    end
end
% Add strain rate on secondary y-axis
yyaxis right
plot(Tdas_recovery_b, strain_rate_recovery_b, 'k-', 'LineWidth', 2, 'DisplayName', 'Strain Rate')
ylabel('Strain Rate (nm/s)')
yyaxis left
ylabel('Recovery Rate (m/s)')
title('PT-01b: Recovery Rates (z2-z5) vs Strain Rate')
xlim([plot_start_b, plot_end_b])
xlabel('Time (UTC)')
legend('Location', 'best')
grid on
hold off

% PT-01c comparison - use z2-z5 with strain rate
subplot(3,1,3)
hold on
% Plot all zones z2-z5
colors_c = lines(4); % 4 zones: z2, z3, z4, z5
zone_names_c = {'z2', 'z3', 'z4', 'z5'};
for i = 1:length(zone_names_c)
    zone = zone_names_c{i};
    if ~isempty(data_c.(zone).recovery_rate_ms)
        plot(data_c.(zone).recovery_time, data_c.(zone).recovery_rate_ms, ...
             'Color', colors_c(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_c.(zone).Depthft));
    end
end
% Add strain rate on secondary y-axis
yyaxis right
plot(Tdas_recovery_c, strain_rate_recovery_c, 'k-', 'LineWidth', 2, 'DisplayName', 'Strain Rate')
ylabel('Strain Rate (nm/s)')
yyaxis left
ylabel('Recovery Rate (m/s)')
title('PT-01c: Recovery Rates (z2-z5) vs Strain Rate')
xlim([recovery_start_c, recovery_end_c])
xlabel('Time (UTC)')
legend('Location', 'best')
grid on
hold off

%% Create Figure 2-style plots for all three datasets
fprintf('\n=== CREATING FIGURE 2-STYLE PLOTS ===\n');

% Create time arrays for DAS data
Tdas_a_full = DASStart_a + seconds(0:size(data1Hz_a,1)-1);
Tdas_b_full = DASStart_b + seconds(0:size(data1Hz_b,1)-1) + seconds(120); % Shift PT-01b DAS data by 2 minutes
Tdas_c_full = DASStart_c + seconds(0:size(data1Hz_c,1)-1) + seconds(90); % Adjust for PT-01c

% Calculate depth arrays for DAS data
chan_a = 1:size(data1Hz_a,2);
depthft_a_das_full = ((chan_a-C1_a-1)*MperChan_a)/.3048;
chan_b = 1:size(data1Hz_b,2);
depthft_b_das_full = ((chan_b-C1_b-1)*MperChan_b)/.3048;
chan_c = 1:size(data1Hz_c,2);
depthft_c_das_full = ((chan_c-C1_c-1)*MperChan_c)/.3048;

% Apply moving average to all DAS data
mdata_a_full = movmean(data1Hz_a, 10, 1);
mdata_b_full = movmean(data1Hz_b, 10, 1);
mdata_c_full = movmean(data1Hz_c, 10, 1);

% Define zones for each test
zone_min_ft_a = 450; zone_max_ft_a = 510;
zone_min_ft_b = 350; zone_max_ft_b = 400;
zone_min_ft_c = 260; zone_max_ft_c = 310;

% Find representative channels for each test
target_depth_ft_a = (zone_min_ft_a + zone_max_ft_a)/2; % 480 ft
[~, channel_idx_a_full] = min(abs(depthft_a_das_full - target_depth_ft_a));

target_depth_ft_b = (zone_min_ft_b + zone_max_ft_b)/2; % 375 ft
[~, channel_idx_b_full] = min(abs(depthft_b_das_full - target_depth_ft_b));

% Try a different channel for PT-01b - let's use one closer to the zone minimum
target_depth_ft_b_alt = zone_min_ft_b + 25; % 375 ft (350 + 25)
[~, channel_idx_b_full] = min(abs(depthft_b_das_full - target_depth_ft_b_alt));

% Debug: Show available channels in the pumping zone
fprintf('\n=== PT-01b Channel Options ===\n');
fprintf('Pumping zone: %.1f to %.1f ft\n', zone_min_ft_b, zone_max_ft_b);
fprintf('Current channel: %d at %.1f ft\n', channel_idx_b_full, depthft_b_das_full(channel_idx_b_full));

% Show a few channel options
channels_in_zone = find(depthft_b_das_full >= zone_min_ft_b & depthft_b_das_full <= zone_max_ft_b);
if length(channels_in_zone) > 0
    fprintf('Available channels in zone:\n');
    for i = 1:min(5, length(channels_in_zone))
        ch = channels_in_zone(i);
        fprintf('  Channel %d at %.1f ft\n', ch, depthft_b_das_full(ch));
    end
    if length(channels_in_zone) > 5
        fprintf('  ... and %d more channels\n', length(channels_in_zone) - 5);
    end
end

target_depth_ft_c = (zone_min_ft_c + zone_max_ft_c)/2; % 285 ft
[~, channel_idx_c_full] = min(abs(depthft_c_das_full - target_depth_ft_c));

% Get single channel displacement rates
single_disp_rate_a = mdata_a_full(:, channel_idx_a_full);
single_disp_rate_b = mdata_b_full(:, channel_idx_b_full);
single_disp_rate_c = mdata_c_full(:, channel_idx_c_full);

% Set color ranges for displacement rate plots - adjusted to match actual data ranges
disp_rate_range_a = [0.35 0.55];  % PT-01a range - adjusted based on bottom plot
disp_rate_range_b = [-1.0 -0.8];  % PT-01b range - match bottom plot axis range
disp_rate_range_c = [-0.2 0.1];   % PT-01c range - adjusted based on bottom plot

%% Figure 4: PT-01a Figure 2-style plot
figure(4)
subplot(2,1,1)
v = pcolor(Tdas_a_full, depthft_a_das_full, mdata_a_full');
set(v, 'EdgeColor', 'none')
set(gca, 'clim', disp_rate_range_a)
colormap('jet')
c7=colorbar; c7.Location="northoutside";
c7.Ruler.TickLabelFormat='%g nm/s';
grid on; set(gca,'layer','top');
ylabel('Depth (ft)')
axis ij
ylim([100 665])
yline(zone_min_ft_a, '--w', 'Zone min', LineWidth=1.5)
yline(zone_max_ft_a, '--w', 'Zone max', LineWidth=1.5)
xlim([recovery_start_a, recovery_end_a])
xlabel('Date Time UTC')
title(sprintf('PT-01a: Displacement Rate (Channel %d at %.1f ft)', channel_idx_a_full, depthft_a_das_full(channel_idx_a_full)))

subplot(2,1,2)
yyaxis left
% Plot all zones recovery rates
colors_a = lines(length(zones_a));
hold on
for i = 1:length(zones_a)
    zone = zones_a{i};
    if ~isempty(data_a.(zone).recovery_rate_ms)
        plot(data_a.(zone).recovery_time, data_a.(zone).recovery_rate_ms, ...
             'Color', colors_a(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_a.(zone).Depthft));
    end
end
xlim([recovery_start_a, recovery_end_a])
xlabel('Time (UTC)')
ylabel('Recovery Rate (m/s)')
ylim([-0.0001 0.0008])  % Tightened range to expose signal better

yyaxis right
plot(Tdas_a_full, single_disp_rate_a, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Displacement Rate')
ylabel('Displacement Rate (nm/s)')
grid on
legend('Location', 'northwest')

%% Figure 5: PT-01b Figure 2-style plot
figure(5)
subplot(2,1,1)

% Debug: Check data ranges before plotting
fprintf('PT-01b data range: [%.3f, %.3f] nm/s\n', min(mdata_b_full(:)), max(mdata_b_full(:)));
fprintf('PT-01b color range: [%.3f, %.3f] nm/s\n', disp_rate_range_b(1), disp_rate_range_b(2));

% Filter data to plot window to reduce memory usage
plot_mask_b = Tdas_b_full >= plot_start_b & Tdas_b_full <= plot_end_b;
if sum(plot_mask_b) > 0
    Tdas_b_plot = Tdas_b_full(plot_mask_b);
    mdata_b_plot = mdata_b_full(plot_mask_b, :);
    
    v = pcolor(Tdas_b_plot, depthft_b_das_full, mdata_b_plot');
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', disp_rate_range_b)
    colormap('jet')
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/s';
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    ylim([100 665])
    yline(zone_min_ft_b, '--w', 'Zone min', LineWidth=1.5)
    yline(zone_max_ft_b, '--w', 'Zone max', LineWidth=1.5)
    xlim([plot_start_b, plot_end_b])  % Use shortened time window
    xlabel('Date Time UTC')
    title(sprintf('PT-01b: Displacement Rate (Channel %d at %.1f ft)', channel_idx_b_full, depthft_b_das_full(channel_idx_b_full)))
else
    fprintf('WARNING: No PT-01b data found in plot window!\n');
    text(0.5, 0.5, 'No data in plot window', 'HorizontalAlignment', 'center', 'Units', 'normalized');
end

subplot(2,1,2)
yyaxis left
% Plot all zones recovery rates
colors_b = lines(length(zones_b));
hold on
for i = 1:length(zones_b)
    zone = zones_b{i};
    if ~isempty(data_b.(zone).recovery_rate_ms)
        plot(data_b.(zone).recovery_time, data_b.(zone).recovery_rate_ms, ...
             'Color', colors_b(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_b.(zone).Depthft));
    end
end
xlim([plot_start_b, plot_end_b])  % Use shortened time window
xlabel('Time (UTC)')
ylabel('Recovery Rate (m/s)')
ylim([-0.0001 0.0008])  % Tightened range to expose signal better

yyaxis right
plot(Tdas_b_full, single_disp_rate_b, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Displacement Rate')
ylabel('Displacement Rate (nm/s)')
grid on
legend('Location', 'northwest')

%% Figure 6: PT-01c Figure 2-style plot
figure(6)
subplot(2,1,1)
v = pcolor(Tdas_c_full, depthft_c_das_full, mdata_c_full');
set(v, 'EdgeColor', 'none')
set(gca, 'clim', disp_rate_range_c)
colormap('jet')
c7=colorbar; c7.Location="northoutside";
c7.Ruler.TickLabelFormat='%g nm/s';
grid on; set(gca,'layer','top');
ylabel('Depth (ft)')
axis ij
ylim([100 665])
yline(zone_min_ft_c, '--w', 'Zone min', LineWidth=1.5)
yline(zone_max_ft_c, '--w', 'Zone max', LineWidth=1.5)
xlim([recovery_start_c, recovery_end_c])
xlabel('Date Time UTC')
title(sprintf('PT-01c: Displacement Rate (Channel %d at %.1f ft)', channel_idx_c_full, depthft_c_das_full(channel_idx_c_full)))

subplot(2,1,2)
yyaxis left
% Plot all zones recovery rates
colors_c = lines(length(zones_c));
hold on
for i = 1:length(zones_c)
    zone = zones_c{i};
    if ~isempty(data_c.(zone).recovery_rate_ms)
        plot(data_c.(zone).recovery_time, data_c.(zone).recovery_rate_ms, ...
             'Color', colors_c(i,:), 'LineWidth', 1.5, 'DisplayName', ...
             sprintf('%s (%.1f ft)', zone, data_c.(zone).Depthft));
    end
end
xlim([recovery_start_c, recovery_end_c])
xlabel('Time (UTC)')
ylabel('Recovery Rate (m/s)')
ylim([-0.0001 0.0008])  % Tightened range to expose signal better

yyaxis right
plot(Tdas_c_full, single_disp_rate_c, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Displacement Rate')
ylabel('Displacement Rate (nm/s)')
grid on
legend('Location', 'northwest')

%% Raw Data Plots
fprintf('\n=== CREATING RAW DATA PLOTS ===\n');

%% Simple Waterfall Plots (Raw DAS Data)
fprintf('\n=== CREATING SIMPLE WATERFALL PLOTS ===\n');

% Figure 10: PT-01a Simple Waterfall Plot
figure(10)
imagesc(data1Hz_a')
clim([-2 2])
colormap('jet')
colorbar
title('PT-01a: Raw Data')
xlabel('Sample')
ylabel('Channel Number')

% Figure 11: PT-01b Simple Waterfall Plot
figure(11)
imagesc(data1Hz_b')
clim([-2 2])
colormap('jet')
colorbar
title('PT-01b: Raw Data')
xlabel('Sample')
ylabel('Channel Number')

% Figure 12: PT-01c Simple Waterfall Plot
figure(12)
imagesc(data1Hz_c')
clim([-2 2])
colormap('jet')
colorbar
title('PT-01c: Raw Data')
xlabel('Sample')
ylabel('Channel Number')

% Figure 7: PT-01a Raw Data
figure(7)
subplot(2,1,1)
% Plot raw head data for all zones
hold on
colors_a = lines(length(zones_a));
for i = 1:length(zones_a)
    zone = zones_a{i};
    plot(data_a.(zone).Date, data_a.(zone).Drawdownft, ...
         'Color', colors_a(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_a.(zone).Depthft));
end
% Highlight recovery period
xlim([recovery_start_a - minutes(5), recovery_end_a + minutes(5)])
ylabel('Drawdown (ft)')
title('PT-01a: Raw Head Data - All Zones')
legend('Location', 'best')
grid on
% Add recovery window shading
y_lims = ylim;
patch([recovery_start_a recovery_end_a recovery_end_a recovery_start_a], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Recovery Window')
hold off

subplot(2,1,2)
% Plot raw DAS data (single channel)
plot(Tdas_a_full, single_disp_rate_a, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Raw DAS Displacement Rate')
xlim([recovery_start_a - minutes(5), recovery_end_a + minutes(5)])
ylabel('Displacement Rate (nm/s)')
xlabel('Time (UTC)')
title(sprintf('PT-01a: Raw DAS Data - Channel %d at %.1f ft', channel_idx_a_full, depthft_a_das_full(channel_idx_a_full)))
legend('Location', 'best')
grid on
% Add recovery window shading
y_lims = ylim;
patch([recovery_start_a recovery_end_a recovery_end_a recovery_start_a], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Recovery Window')

% Figure 8: PT-01b Raw Data
figure(8)
subplot(2,1,1)
% Plot raw head data for all zones
hold on
colors_b = lines(length(zones_b));
for i = 1:length(zones_b)
    zone = zones_b{i};
    plot(data_b.(zone).Date, data_b.(zone).Drawdownft, ...
         'Color', colors_b(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_b.(zone).Depthft));
end
% Highlight recovery period
xlim([recovery_start_b - minutes(10), recovery_end_b + minutes(10)])
ylabel('Drawdown (ft)')
title('PT-01b: Raw Head Data - All Zones')
legend('Location', 'best')
grid on
% Add plot window shading (analysis window)
y_lims = ylim;
patch([plot_start_b plot_end_b plot_end_b plot_start_b], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Analysis Window')
hold off

subplot(2,1,2)
% Plot raw DAS data (single channel)
plot(Tdas_b_full, single_disp_rate_b, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Raw DAS Displacement Rate')
xlim([recovery_start_b - minutes(10), recovery_end_b + minutes(10)])
ylabel('Displacement Rate (nm/s)')
xlabel('Time (UTC)')
title(sprintf('PT-01b: Raw DAS Data - Channel %d at %.1f ft', channel_idx_b_full, depthft_b_das_full(channel_idx_b_full)))
legend('Location', 'best')
grid on
% Add plot window shading (analysis window)
y_lims = ylim;
patch([plot_start_b plot_end_b plot_end_b plot_start_b], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Analysis Window')

% Figure 9: PT-01c Raw Data
figure(9)
subplot(2,1,1)
% Plot raw head data for all zones
hold on
colors_c = lines(length(zones_c));
for i = 1:length(zones_c)
    zone = zones_c{i};
    plot(data_c.(zone).Date, data_c.(zone).Drawdownft, ...
         'Color', colors_c(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_c.(zone).Depthft));
end
% Highlight recovery period
xlim([recovery_start_c - minutes(5), recovery_end_c + minutes(5)])
ylabel('Drawdown (ft)')
title('PT-01c: Raw Head Data - All Zones')
legend('Location', 'best')
grid on
% Add recovery window shading
y_lims = ylim;
patch([recovery_start_c recovery_end_c recovery_end_c recovery_start_c], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Recovery Window')
hold off

subplot(2,1,2)
% Plot raw DAS data (single channel)
plot(Tdas_c_full, single_disp_rate_c, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Raw DAS Displacement Rate')
xlim([recovery_start_c - minutes(5), recovery_end_c + minutes(5)])
ylabel('Displacement Rate (nm/s)')
xlabel('Time (UTC)')
title(sprintf('PT-01c: Raw DAS Data - Channel %d at %.1f ft', channel_idx_c_full, depthft_c_das_full(channel_idx_c_full)))
legend('Location', 'best')
grid on
% Add recovery window shading
y_lims = ylim;
patch([recovery_start_c recovery_end_c recovery_end_c recovery_start_c], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Recovery Window')

%% Summary analysis
fprintf('\n=== RECOVERY ANALYSIS SUMMARY ===\n');

fprintf('\nPT-01a recovery summary (%.1f minutes):\n', minutes(recovery_end_a - recovery_start_a));
for i = 1:length(zones_a)
    zone = zones_a{i};
    if ~isempty(data_a.(zone).recovery_rate_ms)
        avg_rate = mean(data_a.(zone).recovery_rate_ms);
        max_rate = max(data_a.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s\n', ...
            zone, data_a.(zone).Depthft, avg_rate, max_rate);
    end
end

fprintf('\nPT-01b recovery summary (%.1f minutes, plot window %.1f minutes):\n', minutes(recovery_end_b - recovery_start_b), minutes(plot_end_b - plot_start_b));
for i = 1:length(zones_b)
    zone = zones_b{i};
    if ~isempty(data_b.(zone).recovery_rate_ms)
        avg_rate = mean(data_b.(zone).recovery_rate_ms);
        max_rate = max(data_b.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s\n', ...
            zone, data_b.(zone).Depthft, avg_rate, max_rate);
    end
end

fprintf('\nPT-01c recovery summary (%.1f minutes):\n', minutes(recovery_end_c - recovery_start_c));
for i = 1:length(zones_c)
    zone = zones_c{i};
    if ~isempty(data_c.(zone).recovery_rate_ms)
        avg_rate = mean(data_c.(zone).recovery_rate_ms);
        max_rate = max(data_c.(zone).recovery_rate_ms);
        fprintf('  %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s\n', ...
            zone, data_c.(zone).Depthft, avg_rate, max_rate);
    end
end

%% Key findings
fprintf('\n=== KEY FINDINGS ===\n');
fprintf('1. Recovery periods analyzed using original time windows from PM07_PT01(a,b,c)_Analysis.m\n');
fprintf('2. Analysis focuses on zones z2-z5 for all tests (z1 excluded)\n');
fprintf('3. Positive recovery rates indicate water level rising (recovery)\n');
fprintf('4. Negative recovery rates indicate continued drawdown\n');
fprintf('5. PT-01b has the longest original recovery window (63 minutes) but analysis uses shortened plot window (4 minutes)\n');
fprintf('6. All tests now use similar analysis windows: PT-01a (5 min), PT-01b (4 min), PT-01c (4 min)\n');

fprintf('\n=== RECOVERY ANALYSIS COMPLETE ===\n');
