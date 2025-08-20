%% PM-07 Drawdown Rate Analysis (FINAL FIXED VERSION)
% This script analyzes drawdown rates across all three PT-01 depths
% and compares them with displacement rates from DAS data
% 
% FIXED: All depth variables are properly converted to scalars to prevent repetitive output

%% Load all head data for the three PT-01 depths
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load head data for all three depths
load(fullfile(data_dir, 'head', 'head_a_z5.mat'));  % PT-01a
Date_a = Date;
Drawdownft_a = Drawdownft;
Depthft_a_scalar = mean(Depthft, 'omitnan');  % Convert to scalar - use mean depth, ignore NaNs

load(fullfile(data_dir, 'head', 'head_b_z5.mat'));  % PT-01b
Date_b = Date;
Drawdownft_b = Drawdownft;
Depthft_b_scalar = mean(Depthft, 'omitnan');  % Convert to scalar - use mean depth, ignore NaNs

load(fullfile(data_dir, 'head', 'head_c_z5.mat'));  % PT-01c
Date_c = Date;
Drawdownft_c = Drawdownft;
Depthft_c_scalar = mean(Depthft, 'omitnan');  % Convert to scalar - use mean depth, ignore NaNs

% Convert all dates to UTC for consistency
Date_a.TimeZone = 'UTC';
Date_b.TimeZone = 'UTC';
Date_c.TimeZone = 'UTC';

fprintf('Loaded head data for all three PT-01 depths:\n');
fprintf('PT-01a: %s to %s, depth %.1f ft (avg of %d measurements)\n', min(Date_a), max(Date_a), Depthft_a_scalar, length(Date_a));
fprintf('PT-01b: %s to %s, depth %.1f ft (avg of %d measurements)\n', min(Date_b), max(Date_b), Depthft_b_scalar, length(Date_b));
fprintf('PT-01c: %s to %s, depth %.1f ft (avg of %d measurements)\n', min(Date_c), max(Date_c), Depthft_c_scalar, length(Date_c));

%% Load DAS data for displacement rate comparison
% Load DAS data for each test
load(fullfile(data_dir, 'DAS Data', 'PM07_01a_1Hz.mat'));
data1Hz_a = decdata;
DASStart_a = datetime(2023,11,7,16,45,36,00,'TimeZone','UTC');
C1_a = 513;
MperChan_a = 0.25;

load(fullfile(data_dir, 'DAS Data', 'PM07_01b_1Hz.mat'));
data1Hz_b = decdata;
DASStart_b = datetime(2023,10,31,15,29,36,00,'TimeZone','UTC');
C1_b = 513;
MperChan_b = 0.25;

load(fullfile(data_dir, 'DAS Data', 'PM07_01c_1Hz.mat'));
if exist('decdata', 'var')
    data1Hz_c = decdata;
else
    data1Hz_c = data1Hz;  % Variable might be named differently
end
DASStart_c = datetime(2023,10,24,15,02,36,00,'TimeZone','UTC');
C1_c = 110;
MperChan_c = 0.25;

%% Calculate depth arrays for DAS data
% PT-01a: 450-510 ft (pumping zone)
chan_a = 1:size(data1Hz_a,2);
depthm_a = (chan_a-C1_a-1)*MperChan_a;
depthft_a_das = depthm_a/.3048;
zone_min_ft_a = 450;
zone_max_ft_a = 510;
[~, channel_idx_a] = min(abs(depthft_a_das - (zone_min_ft_a + zone_max_ft_a)/2));

% PT-01b: 350-400 ft
chan_b = 1:size(data1Hz_b,2);
depthm_b = (chan_b-C1_b-1)*MperChan_b;
depthft_b_das = depthm_b/.3048;
zone_min_ft_b = 350;
zone_max_ft_b = 400;
[~, channel_idx_b] = min(abs(depthft_b_das - (zone_min_ft_b + zone_max_ft_b)/2));

% PT-01c: ~80 m depth
chan_c = 1:size(data1Hz_c,2);
depthm_c = (chan_c-C1_c-1)*MperChan_c;
depthft_c_das = depthm_c/.3048;
% For PT-01c, use channel 492 as in original analysis
channel_idx_c = 492;

%% Create time arrays for DAS data
Tdas_a = DASStart_a + seconds(0:size(data1Hz_a,1)-1);
Tdas_b = DASStart_b + seconds(0:size(data1Hz_b,1)-1);
Tdas_c = DASStart_c + seconds(0:size(data1Hz_c,1)-1);

%% Smooth drawdown data and calculate derivatives
% Apply moving average smoothing before taking derivative
smooth_window = 10;  % 10-point moving average

% PT-01a drawdown rate
drawdown_smooth_a = movmean(Drawdownft_a, smooth_window);
drawdown_rate_a = diff(drawdown_smooth_a) ./ seconds(diff(Date_a));  % ft/s
drawdown_rate_a_ftmin = drawdown_rate_a * 60;  % ft/min for easier interpretation
Date_rate_a = Date_a(1:end-1);  % Time points for rate (one less than original)

% PT-01b drawdown rate
drawdown_smooth_b = movmean(Drawdownft_b, smooth_window);
drawdown_rate_b = diff(drawdown_smooth_b) ./ seconds(diff(Date_b));
drawdown_rate_b_ftmin = drawdown_rate_b * 60;
Date_rate_b = Date_b(1:end-1);

% PT-01c drawdown rate
drawdown_smooth_c = movmean(Drawdownft_c, smooth_window);
drawdown_rate_c = diff(drawdown_smooth_c) ./ seconds(diff(Date_c));
drawdown_rate_c_ftmin = drawdown_rate_c * 60;
Date_rate_c = Date_c(1:end-1);

%% Get displacement rates from DAS data
% Apply same smoothing as in original analyses
mdata_a = movmean(data1Hz_a, 10, 1);
mdata_b = movmean(data1Hz_b, 10, 1);
mdata_c = movmean(data1Hz_c, 10, 1);

% Get displacement rates for representative channels
disp_rate_a = mdata_a(:, channel_idx_a);  % nm/s
disp_rate_b = mdata_b(:, channel_idx_b);  % nm/s
disp_rate_c = mdata_c(:, channel_idx_c);  % nm/s

fprintf('\nDisplacement rate ranges:\n');
fprintf('PT-01a: [%.3f, %.3f] nm/s\n', min(disp_rate_a), max(disp_rate_a));
fprintf('PT-01b: [%.3f, %.3f] nm/s\n', min(disp_rate_b), max(disp_rate_b));
fprintf('PT-01c: [%.3f, %.3f] nm/s\n', min(disp_rate_c), max(disp_rate_c));

fprintf('\nDrawdown rate ranges:\n');
fprintf('PT-01a: [%.6f, %.6f] ft/min\n', min(drawdown_rate_a_ftmin), max(drawdown_rate_a_ftmin));
fprintf('PT-01b: [%.6f, %.6f] ft/min\n', min(drawdown_rate_b_ftmin), max(drawdown_rate_b_ftmin));
fprintf('PT-01c: [%.6f, %.6f] ft/min\n', min(drawdown_rate_c_ftmin), max(drawdown_rate_c_ftmin));

%% Plot 1: Drawdown rates comparison
figure(1)
subplot(3,1,1)
plot(Date_rate_a, drawdown_rate_a_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
title('PT-01a Drawdown Rate')
grid on
xlim([min(Date_rate_a) max(Date_rate_a)])

subplot(3,1,2)
plot(Date_rate_b, drawdown_rate_b_ftmin, 'r-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
title('PT-01b Drawdown Rate')
grid on
xlim([min(Date_rate_b) max(Date_rate_b)])

subplot(3,1,3)
plot(Date_rate_c, drawdown_rate_c_ftmin, 'g-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
title('PT-01c Drawdown Rate')
xlabel('Time (UTC)')
grid on
xlim([min(Date_rate_c) max(Date_rate_c)])

%% Plot 2: Drawdown rate vs Displacement rate comparison
% Find common time windows for each test
% PT-01a: Focus on the promising signal around 12:46:30 (20:46:30 UTC)
start_plot_a = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
end_plot_a = datetime(2023,11,7,20,49,00,00,'TimeZone','UTC');

% PT-01b: Use the original plot window
start_plot_b = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
end_plot_b = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');

% PT-01c: Use the original plot window
start_plot_c = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
end_plot_c = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

figure(2)
% PT-01a comparison
subplot(3,2,1)
yyaxis left
plot(Date_rate_a, drawdown_rate_a_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(Tdas_a, disp_rate_a, 'r-', 'LineWidth', 1.5)
ylabel('Displacement Rate (nm/s)')
title('PT-01a: Drawdown Rate vs Displacement Rate')
grid on
xlim([start_plot_a end_plot_a])
legend('Drawdown Rate', 'Displacement Rate', 'Location', 'best')

% PT-01b comparison
subplot(3,2,3)
yyaxis left
plot(Date_rate_b, drawdown_rate_b_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(Tdas_b, disp_rate_b, 'r-', 'LineWidth', 1.5)
ylabel('Displacement Rate (nm/s)')
title('PT-01b: Drawdown Rate vs Displacement Rate')
grid on
xlim([start_plot_b end_plot_b])
legend('Drawdown Rate', 'Displacement Rate', 'Location', 'best')

% PT-01c comparison
subplot(3,2,5)
yyaxis left
plot(Date_rate_c, drawdown_rate_c_ftmin, 'b-', 'LineWidth', 1.5)
ylabel('Drawdown Rate (ft/min)')
yyaxis right
plot(Tdas_c, disp_rate_c, 'r-', 'LineWidth', 1.5)
ylabel('Displacement Rate (nm/s)')
title('PT-01c: Drawdown Rate vs Displacement Rate')
xlabel('Time (UTC)')
grid on
xlim([start_plot_c end_plot_c])
legend('Drawdown Rate', 'Displacement Rate', 'Location', 'best')

%% Plot 3: Cross-correlation analysis
% Find overlapping time periods and calculate correlations
subplot(3,2,2)
% PT-01a correlation
mask_a = Date_rate_a >= start_plot_a & Date_rate_a <= end_plot_a;
mask_das_a = Tdas_a >= start_plot_a & Tdas_a <= end_plot_a;
if sum(mask_a) > 10 && sum(mask_das_a) > 10
    drawdown_window_a = drawdown_rate_a_ftmin(mask_a);
    disp_window_a = disp_rate_a(mask_das_a);
    % Interpolate to same time points for correlation
    time_a = Date_rate_a(mask_a);
    disp_interp_a = interp1(Tdas_a(mask_das_a), disp_window_a, time_a, 'linear', 'extrap');
    corr_a = corrcoef(drawdown_window_a, disp_interp_a);
    scatter(drawdown_window_a, disp_interp_a, 'b.')
    title(sprintf('PT-01a Correlation: r=%.3f', corr_a(1,2)))
    xlabel('Drawdown Rate (ft/min)')
    ylabel('Displacement Rate (nm/s)')
    grid on
end

subplot(3,2,4)
% PT-01b correlation
mask_b = Date_rate_b >= start_plot_b & Date_rate_b <= end_plot_b;
mask_das_b = Tdas_b >= start_plot_b & Tdas_b <= end_plot_b;
if sum(mask_b) > 10 && sum(mask_das_b) > 10
    drawdown_window_b = drawdown_rate_b_ftmin(mask_b);
    disp_window_b = disp_rate_b(mask_das_b);
    time_b = Date_rate_b(mask_b);
    disp_interp_b = interp1(Tdas_b(mask_das_b), disp_window_b, time_b, 'linear', 'extrap');
    corr_b = corrcoef(drawdown_window_b, disp_interp_b);
    scatter(drawdown_window_b, disp_interp_b, 'r.')
    title(sprintf('PT-01b Correlation: r=%.3f', corr_b(1,2)))
    xlabel('Drawdown Rate (ft/min)')
    ylabel('Displacement Rate (nm/s)')
    grid on
end

subplot(3,2,6)
% PT-01c correlation
mask_c = Date_rate_c >= start_plot_c & Date_rate_c <= end_plot_c;
mask_das_c = Tdas_c >= start_plot_c & Tdas_c <= end_plot_c;
if sum(mask_c) > 10 && sum(mask_das_c) > 10
    drawdown_window_c = drawdown_rate_c_ftmin(mask_c);
    disp_window_c = disp_rate_c(mask_das_c);
    time_c = Date_rate_c(mask_c);
    disp_interp_c = interp1(Tdas_c(mask_das_c), disp_window_c, time_c, 'linear', 'extrap');
    corr_c = corrcoef(drawdown_window_c, disp_interp_c);
    scatter(drawdown_window_c, disp_interp_c, 'g.')
    title(sprintf('PT-01c Correlation: r=%.3f', corr_c(1,2)))
    xlabel('Drawdown Rate (ft/min)')
    ylabel('Displacement Rate (nm/s)')
    grid on
end

%% Summary statistics (FIXED - all variables are now scalars)
fprintf('\n=== SUMMARY STATISTICS ===\n');

% Calculate maximum values and their indices (ensure scalars)
[max_dd_a, idx_dd_a] = max(abs(drawdown_rate_a_ftmin));
[max_disp_a, ~] = max(abs(disp_rate_a));
[max_dd_b, idx_dd_b] = max(abs(drawdown_rate_b_ftmin));
[max_disp_b, ~] = max(abs(disp_rate_b));
[max_dd_c, idx_dd_c] = max(abs(drawdown_rate_c_ftmin));
[max_disp_c, ~] = max(abs(disp_rate_c));

% Ensure all values are scalars by taking first element if needed
max_dd_a = max_dd_a(1);
max_disp_a = max_disp_a(1);
max_dd_b = max_dd_b(1);
max_disp_b = max_disp_b(1);
max_dd_c = max_dd_c(1);
max_disp_c = max_disp_c(1);
idx_dd_a = idx_dd_a(1);
idx_dd_b = idx_dd_b(1);
idx_dd_c = idx_dd_c(1);

% Print summary - now using scalar depth values
fprintf('PT-01a (%.1f ft): Max drawdown rate = %.6f ft/min, Max displacement rate = %.3f nm/s\n', ...
    Depthft_a_scalar, max_dd_a, max_disp_a);
fprintf('PT-01b (%.1f ft): Max drawdown rate = %.6f ft/min, Max displacement rate = %.3f nm/s\n', ...
    Depthft_b_scalar, max_dd_b, max_disp_b);
fprintf('PT-01c (%.1f ft): Max drawdown rate = %.6f ft/min, Max displacement rate = %.3f nm/s\n', ...
    Depthft_c_scalar, max_dd_c, max_disp_c);

% Print timing information
fprintf('\nTiming of maximum responses:\n');
fprintf('PT-01a max drawdown rate at: %s\n', Date_rate_a(idx_dd_a));
fprintf('PT-01b max drawdown rate at: %s\n', Date_rate_b(idx_dd_b));
fprintf('PT-01c max drawdown rate at: %s\n', Date_rate_c(idx_dd_c));

%% Look for specific signals mentioned by advisor - uniform analysis for all depths
fprintf('\n=== LOOKING FOR SPECIFIC SIGNALS (UNIFORM ANALYSIS) ===\n');

% PT-01a: Check the specific signal mentioned by advisor (12:46:30 local time)
target_time_local_a = datetime(2023,11,7,12,46,30,00,'TimeZone','America/Los_Angeles');
target_time_utc_a = target_time_local_a;
target_time_utc_a.TimeZone = 'UTC';

fprintf('PT-01a (%.1f ft) - Signal at 12:46:30:\n', Depthft_a_scalar);
fprintf('  Target time (UTC): %s\n', target_time_utc_a);

[~, idx_closest_a] = min(abs(Date_rate_a - target_time_utc_a));
closest_time_a = Date_rate_a(idx_closest_a);
time_diff_a = abs(closest_time_a - target_time_utc_a);

fprintf('  Closest time in data: %s (diff: %s)\n', closest_time_a, time_diff_a);
if time_diff_a < minutes(5)
    fprintf('  Drawdown rate at this time: %.6f ft/min\n', drawdown_rate_a_ftmin(idx_closest_a));
    fprintf('  This time is within our analysis window!\n');
else
    fprintf('  Note: This time is outside our main analysis window\n');
end

% PT-01b: Check for signals during main pumping period
fprintf('\nPT-01b (%.1f ft) - Peak response analysis:\n', Depthft_b_scalar);
[~, peak_idx_b] = max(abs(drawdown_rate_b_ftmin));
peak_time_b = Date_rate_b(peak_idx_b);
fprintf('  Peak drawdown rate time: %s\n', peak_time_b);
fprintf('  Peak drawdown rate value: %.6f ft/min\n', drawdown_rate_b_ftmin(peak_idx_b));

% PT-01c: Check for signals during main pumping period
fprintf('\nPT-01c (%.1f ft) - Peak response analysis:\n', Depthft_c_scalar);
[~, peak_idx_c] = max(abs(drawdown_rate_c_ftmin));
peak_time_c = Date_rate_c(peak_idx_c);
fprintf('  Peak drawdown rate time: %s\n', peak_time_c);
fprintf('  Peak drawdown rate value: %.6f ft/min\n', drawdown_rate_c_ftmin(peak_idx_c));

%% Additional analysis: Compare response times
fprintf('\n=== RESPONSE TIME ANALYSIS ===\n');
fprintf('Comparing how quickly each depth responds to pumping:\n');

% Find the first significant drawdown rate (above 10% of max)
threshold_a = 0.1 * max_dd_a;
threshold_b = 0.1 * max_dd_b;
threshold_c = 0.1 * max_dd_c;

% Find first time above threshold
first_response_a = find(abs(drawdown_rate_a_ftmin) > threshold_a, 1);
first_response_b = find(abs(drawdown_rate_b_ftmin) > threshold_b, 1);
first_response_c = find(abs(drawdown_rate_c_ftmin) > threshold_c, 1);

if ~isempty(first_response_a)
    fprintf('PT-01a first significant response: %s\n', Date_rate_a(first_response_a));
end
if ~isempty(first_response_b)
    fprintf('PT-01b first significant response: %s\n', Date_rate_b(first_response_b));
end
if ~isempty(first_response_c)
    fprintf('PT-01c first significant response: %s\n', Date_rate_c(first_response_c));
end

fprintf('\n=== ANALYSIS COMPLETE - NO MORE REPETITIVE OUTPUT! ===\n');
