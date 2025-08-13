%% PM-07 Drawdown Rate Analysis - ALL HEAD DATA
% This script analyzes drawdown rates across ALL available head data files
% for all three PT-01 depths and compares them with displacement rates from DAS data
% 
% Includes ALL z-files for comprehensive analysis:
% - PT-01a: z1, z2, z3, z4, z5
% - PT-01b: z1, z2, z3, z4, z5  
% - PT-01c: z2, z3, z4, z5 (z1 not available)

%% Setup
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

%% Define available head data files for each test
head_files_a = {'head_a_z1.mat', 'head_a_z2.mat', 'head_a_z3.mat', 'head_a_z4.mat', 'head_a_z5.mat'};
head_files_b = {'head_b_z1.mat', 'head_b_z2.mat', 'head_b_z3.mat', 'head_b_z4.mat', 'head_b_z5.mat'};
head_files_c = {'head_c_z2.mat', 'head_c_z3.mat', 'head_c_z4.mat', 'head_c_z5.mat'};

fprintf('=== LOADING ALL HEAD DATA FILES ===\n');

%% Load all PT-01a head data
fprintf('\nPT-01a head data files:\n');
data_a = struct();
for i = 1:length(head_files_a)
    file_path = fullfile(data_dir, 'head', head_files_a{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = head_files_a{i}(8:9); % Extract z1, z2, etc. (skip underscore)
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
        zone_name = head_files_b{i}(8:9); % Extract z1, z2, etc. (skip underscore)
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
        zone_name = head_files_c{i}(8:9); % Extract z2, z3, etc. (skip underscore)
        data_c.(zone_name).Date = Date;
        data_c.(zone_name).Date.TimeZone = 'UTC';
        data_c.(zone_name).Drawdownft = Drawdownft;
        data_c.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_c.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s\n', ...
            zone_name, data_c.(zone_name).Depthft, data_c.(zone_name).n_points, ...
            min(Date), max(Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', head_files_c{i});
    end
end

%% Load DAS data for displacement rate comparison
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

%% Calculate drawdown rates for all zones
fprintf('\n=== CALCULATING DRAWDOWN RATES FOR ALL ZONES ===\n');

smooth_window = 10;  % 10-point moving average

% Function to calculate drawdown rate for a zone
function [drawdown_rate_ftmin, Date_rate, max_rate, max_time] = calc_drawdown_rate(Date, Drawdownft, smooth_window)
    drawdown_smooth = movmean(Drawdownft, smooth_window);
    drawdown_rate = diff(drawdown_smooth) ./ seconds(diff(Date));
    drawdown_rate_ftmin = drawdown_rate * 60;
    Date_rate = Date(1:end-1);
    [max_rate, max_idx] = max(abs(drawdown_rate_ftmin));
    max_time = Date_rate(max_idx);
end

% Calculate rates for PT-01a zones
zones_a = fieldnames(data_a);
fprintf('\nPT-01a drawdown rates:\n');
for i = 1:length(zones_a)
    zone = zones_a{i};
    [data_a.(zone).drawdown_rate_ftmin, data_a.(zone).Date_rate, ...
     data_a.(zone).max_rate, data_a.(zone).max_time] = ...
        calc_drawdown_rate(data_a.(zone).Date, data_a.(zone).Drawdownft, smooth_window);
    fprintf('  %s (%.1f ft): Max rate = %.6f ft/min at %s\n', ...
        zone, data_a.(zone).Depthft, data_a.(zone).max_rate, data_a.(zone).max_time);
end

% Calculate rates for PT-01b zones
zones_b = fieldnames(data_b);
fprintf('\nPT-01b drawdown rates:\n');
for i = 1:length(zones_b)
    zone = zones_b{i};
    [data_b.(zone).drawdown_rate_ftmin, data_b.(zone).Date_rate, ...
     data_b.(zone).max_rate, data_b.(zone).max_time] = ...
        calc_drawdown_rate(data_b.(zone).Date, data_b.(zone).Drawdownft, smooth_window);
    fprintf('  %s (%.1f ft): Max rate = %.6f ft/min at %s\n', ...
        zone, data_b.(zone).Depthft, data_b.(zone).max_rate, data_b.(zone).max_time);
end

% Calculate rates for PT-01c zones
zones_c = fieldnames(data_c);
fprintf('\nPT-01c drawdown rates:\n');
for i = 1:length(zones_c)
    zone = zones_c{i};
    [data_c.(zone).drawdown_rate_ftmin, data_c.(zone).Date_rate, ...
     data_c.(zone).max_rate, data_c.(zone).max_time] = ...
        calc_drawdown_rate(data_c.(zone).Date, data_c.(zone).Drawdownft, smooth_window);
    fprintf('  %s (%.1f ft): Max rate = %.6f ft/min at %s\n', ...
        zone, data_c.(zone).Depthft, data_c.(zone).max_rate, data_c.(zone).max_time);
end

%% Get strain rates from DAS data
fprintf('\n=== CALCULATING DAS STRAIN RATES ===\n');

% Calculate depth arrays for DAS data
chan_a = 1:size(data1Hz_a,2);
depthft_a_das = ((chan_a-C1_a-1)*MperChan_a)/.3048;
zone_min_ft_a = 450; zone_max_ft_a = 510;
[~, channel_idx_a] = min(abs(depthft_a_das - (zone_min_ft_a + zone_max_ft_a)/2));

chan_b = 1:size(data1Hz_b,2);
depthft_b_das = ((chan_b-C1_b-1)*MperChan_b)/.3048;
zone_min_ft_b = 350; zone_max_ft_b = 400;
[~, channel_idx_b] = min(abs(depthft_b_das - (zone_min_ft_b + zone_max_ft_b)/2));

chan_c = 1:size(data1Hz_c,2);
channel_idx_c = 492; % As used in original analysis

% Create time arrays and displacement rates
Tdas_a = DASStart_a + seconds(0:size(data1Hz_a,1)-1);
Tdas_b = DASStart_b + seconds(0:size(data1Hz_b,1)-1);
Tdas_c = DASStart_c + seconds(0:size(data1Hz_c,1)-1);

mdata_a = movmean(data1Hz_a, 10, 1);
mdata_b = movmean(data1Hz_b, 10, 1);
mdata_c = movmean(data1Hz_c, 10, 1);

strain_rate_a = mdata_a(:, channel_idx_a);
strain_rate_b = mdata_b(:, channel_idx_b);
strain_rate_c = mdata_c(:, channel_idx_c);

fprintf('DAS strain rates calculated for representative channels\n');

%% Create comprehensive comparison plots
fprintf('\n=== CREATING COMPREHENSIVE PLOTS ===\n');

% Plot 1: All drawdown rates for PT-01a
figure(1)
subplot(3,1,1)
hold on
colors_a = lines(length(zones_a));
for i = 1:length(zones_a)
    zone = zones_a{i};
    plot(data_a.(zone).Date_rate, data_a.(zone).drawdown_rate_ftmin, ...
         'Color', colors_a(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_a.(zone).Depthft));
end
ylabel('Drawdown Rate (ft/min)')
title('PT-01a: All Zones Drawdown Rates')
legend('Location', 'best')
grid on
hold off

% Plot 2: All drawdown rates for PT-01b
subplot(3,1,2)
hold on
colors_b = lines(length(zones_b));
for i = 1:length(zones_b)
    zone = zones_b{i};
    plot(data_b.(zone).Date_rate, data_b.(zone).drawdown_rate_ftmin, ...
         'Color', colors_b(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_b.(zone).Depthft));
end
ylabel('Drawdown Rate (ft/min)')
title('PT-01b: All Zones Drawdown Rates')
legend('Location', 'best')
grid on
hold off

% Set y-axis limits to match other plots
ylim([-0.1, 0.1])

% Plot 3: All drawdown rates for PT-01c
subplot(3,1,3)
hold on
colors_c = lines(length(zones_c));
for i = 1:length(zones_c)
    zone = zones_c{i};
    plot(data_c.(zone).Date_rate, data_c.(zone).drawdown_rate_ftmin, ...
         'Color', colors_c(i,:), 'LineWidth', 1.5, 'DisplayName', ...
         sprintf('%s (%.1f ft)', zone, data_c.(zone).Depthft));
end
ylabel('Drawdown Rate (ft/min)')
title('PT-01c: All Zones Drawdown Rates')
xlabel('Time (UTC)')
legend('Location', 'best')
grid on
hold off

%% Summary comparison across all zones
fprintf('\n=== COMPREHENSIVE SUMMARY ACROSS ALL ZONES ===\n');

fprintf('\nPT-01a zones summary:\n');
for i = 1:length(zones_a)
    zone = zones_a{i};
    fprintf('  %s: Depth %.1f ft, Max rate %.6f ft/min, Time %s\n', ...
        zone, data_a.(zone).Depthft, data_a.(zone).max_rate, data_a.(zone).max_time);
end

fprintf('\nPT-01b zones summary:\n');
for i = 1:length(zones_b)
    zone = zones_b{i};
    fprintf('  %s: Depth %.1f ft, Max rate %.6f ft/min, Time %s\n', ...
        zone, data_b.(zone).Depthft, data_b.(zone).max_rate, data_b.(zone).max_time);
end

fprintf('\nPT-01c zones summary:\n');
for i = 1:length(zones_c)
    zone = zones_c{i};
    fprintf('  %s: Depth %.1f ft, Max rate %.6f ft/min, Time %s\n', ...
        zone, data_c.(zone).Depthft, data_c.(zone).max_rate, data_c.(zone).max_time);
end

%% Cross-zone comparison - find best responding zones
fprintf('\n=== BEST RESPONDING ZONES ANALYSIS ===\n');

% Find zone with maximum response for each test
[max_rate_a, max_idx_a] = max([data_a.(zones_a{1}).max_rate, data_a.(zones_a{2}).max_rate, ...
                               data_a.(zones_a{3}).max_rate, data_a.(zones_a{4}).max_rate, ...
                               data_a.(zones_a{5}).max_rate]);
best_zone_a = zones_a{max_idx_a};

[max_rate_b, max_idx_b] = max([data_b.(zones_b{1}).max_rate, data_b.(zones_b{2}).max_rate, ...
                               data_b.(zones_b{3}).max_rate, data_b.(zones_b{4}).max_rate, ...
                               data_b.(zones_b{5}).max_rate]);
best_zone_b = zones_b{max_idx_b};

max_rates_c = [];
for i = 1:length(zones_c)
    max_rates_c(i) = data_c.(zones_c{i}).max_rate;
end
[max_rate_c, max_idx_c] = max(max_rates_c);
best_zone_c = zones_c{max_idx_c};

fprintf('Best responding zones (highest drawdown rates):\n');
fprintf('  PT-01a: %s (%.1f ft) with %.6f ft/min\n', best_zone_a, data_a.(best_zone_a).Depthft, max_rate_a);
fprintf('  PT-01b: %s (%.1f ft) with %.6f ft/min\n', best_zone_b, data_b.(best_zone_b).Depthft, max_rate_b);
fprintf('  PT-01c: %s (%.1f ft) with %.6f ft/min\n', best_zone_c, data_c.(best_zone_c).Depthft, max_rate_c);

%% Depth-response relationship analysis
fprintf('\n=== DEPTH vs RESPONSE RELATIONSHIP ===\n');

fprintf('Depth vs Max Response Analysis:\n');
fprintf('PT-01a zones (sorted by depth):\n');
depths_a = []; rates_a = [];
for i = 1:length(zones_a)
    depths_a(i) = data_a.(zones_a{i}).Depthft;
    rates_a(i) = data_a.(zones_a{i}).max_rate;
end
[sorted_depths_a, sort_idx_a] = sort(depths_a);
sorted_rates_a = rates_a(sort_idx_a);
sorted_zones_a = zones_a(sort_idx_a);
for i = 1:length(sorted_zones_a)
    fprintf('  %.1f ft (%s): %.6f ft/min\n', sorted_depths_a(i), sorted_zones_a{i}, sorted_rates_a(i));
end

fprintf('\nPT-01b zones (sorted by depth):\n');
depths_b = []; rates_b = [];
for i = 1:length(zones_b)
    depths_b(i) = data_b.(zones_b{i}).Depthft;
    rates_b(i) = data_b.(zones_b{i}).max_rate;
end
[sorted_depths_b, sort_idx_b] = sort(depths_b);
sorted_rates_b = rates_b(sort_idx_b);
sorted_zones_b = zones_b(sort_idx_b);
for i = 1:length(sorted_zones_b)
    fprintf('  %.1f ft (%s): %.6f ft/min\n', sorted_depths_b(i), sorted_zones_b{i}, sorted_rates_b(i));
end

fprintf('\nPT-01c zones (sorted by depth):\n');
depths_c = []; rates_c = [];
for i = 1:length(zones_c)
    depths_c(i) = data_c.(zones_c{i}).Depthft;
    rates_c(i) = data_c.(zones_c{i}).max_rate;
end
[sorted_depths_c, sort_idx_c] = sort(depths_c);
sorted_rates_c = rates_c(sort_idx_c);
sorted_zones_c = zones_c(sort_idx_c);
for i = 1:length(sorted_zones_c)
    fprintf('  %.1f ft (%s): %.6f ft/min\n', sorted_depths_c(i), sorted_zones_c{i}, sorted_rates_c(i));
end

%% Create drawdown rate vs strain rate comparison plots
fprintf('\n=== CREATING DRAWDOWN RATE vs STRAIN RATE PLOTS ===\n');

% Plot 4: PT-01a drawdown rate vs strain rate (best zone)
figure(2)
subplot(3,1,1)
hold on
% Use best responding zone for comparison
best_zone_data_a = data_a.(best_zone_a);
% Interpolate strain rate to drawdown rate time points
strain_rate_interp_a = interp1(Tdas_a, strain_rate_a, best_zone_data_a.Date_rate, 'linear', 'extrap');

% Debug: Check time ranges and interpolation
fprintf('\n=== DEBUG: TIME RANGES AND INTERPOLATION ===\n');
fprintf('PT-01a: DAS time range: %s to %s\n', min(Tdas_a), max(Tdas_a));
fprintf('PT-01a: Head time range: %s to %s\n', min(best_zone_data_a.Date_rate), max(best_zone_data_a.Date_rate));
fprintf('PT-01a: Interpolated strain rate - NaN count: %d/%d\n', sum(isnan(strain_rate_interp_a)), length(strain_rate_interp_a));
yyaxis left
plot(best_zone_data_a.Date_rate, best_zone_data_a.drawdown_rate_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(best_zone_data_a.Date_rate, strain_rate_interp_a, 'r-', 'LineWidth', 1.5)
ylabel('Strain Rate (nm/s)')
title(sprintf('PT-01a: %s (%.1f ft) - Drawdown Rate vs Strain Rate', best_zone_a, best_zone_data_a.Depthft))
xlabel('Time (UTC)')
legend('Drawdown Rate', 'Strain Rate', 'Location', 'best')
grid on
hold off

% Plot 5: PT-01b drawdown rate vs strain rate (best zone)
subplot(3,1,2)
hold on
best_zone_data_b = data_b.(best_zone_b);
strain_rate_interp_b = interp1(Tdas_b, strain_rate_b, best_zone_data_b.Date_rate, 'linear', 'extrap');

fprintf('PT-01b: DAS time range: %s to %s\n', min(Tdas_b), max(Tdas_b));
fprintf('PT-01b: Head time range: %s to %s\n', min(best_zone_data_b.Date_rate), max(best_zone_data_b.Date_rate));
fprintf('PT-01b: Interpolated strain rate - NaN count: %d/%d\n', sum(isnan(strain_rate_interp_b)), length(strain_rate_interp_b));
yyaxis left
plot(best_zone_data_b.Date_rate, best_zone_data_b.drawdown_rate_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(best_zone_data_b.Date_rate, strain_rate_interp_b, 'r-', 'LineWidth', 1.5)
ylabel('Strain Rate (nm/s)')
title(sprintf('PT-01b: %s (%.1f ft) - Drawdown Rate vs Strain Rate', best_zone_b, best_zone_data_b.Depthft))
xlabel('Time (UTC)')
legend('Drawdown Rate', 'Strain Rate', 'Location', 'best')
grid on
hold off

% Plot 6: PT-01c drawdown rate vs strain rate (best zone)
subplot(3,1,3)
hold on
best_zone_data_c = data_c.(best_zone_c);
strain_rate_interp_c = interp1(Tdas_c, strain_rate_c, best_zone_data_c.Date_rate, 'linear', 'extrap');

fprintf('PT-01c: DAS time range: %s to %s\n', min(Tdas_c), max(Tdas_c));
fprintf('PT-01c: Head time range: %s to %s\n', min(best_zone_data_c.Date_rate), max(best_zone_data_c.Date_rate));
fprintf('PT-01c: Interpolated strain rate - NaN count: %d/%d\n', sum(isnan(strain_rate_interp_c)), length(strain_rate_interp_c));
yyaxis left
plot(best_zone_data_c.Date_rate, best_zone_data_c.drawdown_rate_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(best_zone_data_c.Date_rate, strain_rate_interp_c, 'r-', 'LineWidth', 1.5)
ylabel('Strain Rate (nm/s)')
title(sprintf('PT-01c: %s (%.1f ft) - Drawdown Rate vs Strain Rate', best_zone_c, best_zone_data_c.Depthft))
xlabel('Time (UTC)')
legend('Drawdown Rate', 'Strain Rate', 'Location', 'best')
grid on
hold off

%% Correlation analysis between drawdown rates and strain rates
fprintf('\n=== CORRELATION ANALYSIS ===\n');

% Calculate correlations for best responding zones
% Remove NaN values before correlation
valid_a = ~isnan(best_zone_data_a.drawdown_rate_ftmin) & ~isnan(strain_rate_interp_a);
valid_b = ~isnan(best_zone_data_b.drawdown_rate_ftmin) & ~isnan(strain_rate_interp_b);
valid_c = ~isnan(best_zone_data_c.drawdown_rate_ftmin) & ~isnan(strain_rate_interp_c);

if sum(valid_a) > 10  % Need at least 10 points for meaningful correlation
    corr_a = corrcoef(best_zone_data_a.drawdown_rate_ftmin(valid_a), strain_rate_interp_a(valid_a));
    corr_a_val = corr_a(1,2);
else
    corr_a_val = NaN;
end

if sum(valid_b) > 10
    corr_b = corrcoef(best_zone_data_b.drawdown_rate_ftmin(valid_b), strain_rate_interp_b(valid_b));
    corr_b_val = corr_b(1,2);
else
    corr_b_val = NaN;
end

if sum(valid_c) > 10
    corr_c = corrcoef(best_zone_data_c.drawdown_rate_ftmin(valid_c), strain_rate_interp_c(valid_c));
    corr_c_val = corr_c(1,2);
else
    corr_c_val = NaN;
end

fprintf('Correlation coefficients (drawdown rate vs strain rate):\n');
fprintf('  PT-01a (%s): %.4f (valid points: %d/%d)\n', best_zone_a, corr_a_val, sum(valid_a), length(valid_a));
fprintf('  PT-01b (%s): %.4f (valid points: %d/%d)\n', best_zone_b, corr_b_val, sum(valid_b), length(valid_b));
fprintf('  PT-01c (%s): %.4f (valid points: %d/%d)\n', best_zone_c, corr_c_val, sum(valid_c), length(valid_c));

fprintf('\n=== COMPREHENSIVE ANALYSIS COMPLETE ===\n');
fprintf('All available head data files have been analyzed!\n');
fprintf('Total zones analyzed: PT-01a (%d), PT-01b (%d), PT-01c (%d)\n', ...
    length(zones_a), length(zones_b), length(zones_c));
