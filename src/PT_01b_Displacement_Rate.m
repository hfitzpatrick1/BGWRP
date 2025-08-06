%% PT-01b Displacement Rate Analysis – Final Pumping & Recovery
% Analysis of displacement rate (strain rate) without integration
% Focus: Final 15 min pumping + recovery period
% Target zone: 350-400 ft (well screen where clear signals expected)
% Based on PT_01b_CC.m but analyzing raw displacement rate instead of strain

clear; clc; close all
fprintf('=== PT-01b Displacement Rate Analysis Started ===\n');
fprintf('Script: PT_01b_Displacement_Rate.m\n');
fprintf('Test Date: Oct 31, 2023\n');
fprintf('Target Zone: 350-400 ft (Well Screen)\n');
fprintf('Signal: Displacement Rate (no integration)\n\n');

% Force figures to be visible
set(0, 'DefaultFigureVisible', 'on');
set(0, 'DefaultFigureWindowStyle', 'normal');

%% 1. Load data (same as PT_01b_CC.m)
fprintf('Loading PT01b data files...\n');

% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);  % Go up one level from src/ to project root
data_dir = fullfile(project_dir, 'data');

% Load data files from the data directory
pt01b_file = fullfile(data_dir, 'PM07_01b_1Hz.mat');
channel_file = fullfile(data_dir, 'Channel1_alldataupto070224.mat');

fprintf('Script location: %s\n', script_dir);
fprintf('Looking for data in: %s\n', data_dir);

if exist(pt01b_file, 'file') && exist(channel_file, 'file')
    load(pt01b_file)                 % → decdata
    fprintf('✓ Loaded PM07_01b_1Hz.mat: [%d x %d]\n', size(decdata));
    data = decdata;
    
    ld = load(channel_file);   % → distance
    fprintf('✓ Loaded Channel1_alldataupto070224.mat: %d depth points\n', length(ld.distance));
    DTS_depth_ft = ld.distance*3.28084;
else
    error('❌ Data files not found in %s\nMake sure PM07_01b_1Hz.mat and Channel1_alldataupto070224.mat are in the data folder.', data_dir);
end

%% 2. Depth control (PT-01b specific parameters)
fprintf('\n--- Depth Control Setup ---\n');
C1 = 513; BOT = 1324; well_depth_ft = 665; water_table_depth_ft = 89;
dx_m = 0.25; dx_ft = dx_m*3.28084;
fprintf('✓ PT-01b Depth control: C1=%d, BOT=%d, well_depth=%d ft\n', C1, BOT, well_depth_ft);

DAS_depth_ft = ((0:size(data,2)-1).*dx_m)*3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
scale        = well_depth_ft/raw_depth_ft(BOT);
final_depth_ft = raw_depth_ft*scale;

% Define target zone for analysis (PT-01b well screening zone)
target_zone_top = 350;    % ft - well screened zone
target_zone_bot = 400;    % ft - well screened zone  
target_zone_center = 375; % ft

%% 3. Depth Calibration Correction (same as PT_01b_CC.m)
depth_offset = 5;      % ft - correction to align with gamma ray features
depth_stretch = 1.0;   % multiplier to stretch/compress depth scale

% Apply depth calibration
final_depth_ft_corrected = (final_depth_ft + depth_offset) * depth_stretch;

fprintf('Original DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft), max(final_depth_ft));
fprintf('Corrected DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft_corrected), max(final_depth_ft_corrected));
fprintf('Target analysis zone: %.1f-%.1f ft (well screen)\n', target_zone_top, target_zone_bot);

% Use corrected depths for all analysis
final_depth_ft = final_depth_ft_corrected;

%% 4. Time axis setup (PT-01b timing)
Fs = 1;
T0 = datetime(2023,10,31,15,29,36,'TimeZone','UTC');  % PT01b file start
Tdas = T0 + seconds((0:size(data,1)-1));

%% 5. Common Mode Removal (same as PT_01b_CC.m but NO INTEGRATION)
fprintf('\n--- Common Mode Removal (No Integration) ---\n');
fprintf('Processing displacement rate data (strain rate)...\n');

% Focus on the well casing region (PT-01b uses 90-665 ft range)
roi = final_depth_ft>=90 & final_depth_ft<=well_depth_ft;
data_well = data(:, roi);
depth_roi = final_depth_ft(roi);

% For each depth channel, remove its temporal mean
data_cleaned = zeros(size(data));
for ch = 1:size(data, 2)
    channel_data = data(:, ch);
    
    % Remove temporal mean from this channel
    temporal_mean = mean(channel_data, 'omitnan');
    data_cleaned(:, ch) = channel_data - temporal_mean;
end

fprintf('Applied per-channel temporal mean removal to %d channels\n', size(data, 2));
fprintf('Working with displacement rate (nε/s) - NO integration applied\n');

% Extract displacement rate data for ROI
displacement_rate_roi = data_cleaned(:, roi);

%% 6. Define Analysis Time Windows
fprintf('\n--- Time Window Definition ---\n');

% PT-01b pump schedule:
% 15:30 - 50 GPM, 16:30 - 80 GPM, 17:30 - 110 GPM, 18:30 - 148 GPM, 19:30 - 0 GPM (recovery)

% Define analysis periods - need to determine end time from data availability
pump_shutoff = datetime(2023,10,31,19,30,0,'TimeZone','UTC');         % Pumps shut off
final_pumping_start = datetime(2023,10,31,19,15,0,'TimeZone','UTC');  % 15 min before shutoff

% Determine recovery end time based on data availability
data_end_time = max(Tdas);
fprintf('Data available until: %s\n', datestr(data_end_time));

% Set recovery end to either 1 hour after shutoff or end of data, whichever is earlier
recovery_end_target = pump_shutoff + hours(1);  % 1 hour recovery
recovery_end = min(recovery_end_target, data_end_time);

fprintf('Final pumping period: %s to %s (%.1f minutes)\n', ...
    datestr(final_pumping_start), datestr(pump_shutoff), ...
    minutes(pump_shutoff - final_pumping_start));
fprintf('Recovery period: %s to %s (%.1f minutes)\n', ...
    datestr(pump_shutoff), datestr(recovery_end), ...
    minutes(recovery_end - pump_shutoff));

% Create time masks
final_pumping_mask = Tdas >= final_pumping_start & Tdas < pump_shutoff;
recovery_mask = Tdas >= pump_shutoff & Tdas <= recovery_end;
analysis_mask = Tdas >= final_pumping_start & Tdas <= recovery_end;

% Extract data for analysis periods
Tdas_analysis = Tdas(analysis_mask);
displacement_rate_analysis = displacement_rate_roi(analysis_mask,:);

Tdas_final_pump = Tdas(final_pumping_mask);
displacement_rate_final_pump = displacement_rate_roi(final_pumping_mask,:);

Tdas_recovery = Tdas(recovery_mask);
displacement_rate_recovery = displacement_rate_roi(recovery_mask,:);

fprintf('Final pumping data: [%d x %d] points\n', size(displacement_rate_final_pump));
fprintf('Recovery data: [%d x %d] points\n', size(displacement_rate_recovery));
fprintf('Total analysis data: [%d x %d] points\n', size(displacement_rate_analysis));

%% 7. Target Zone Analysis (350-400 ft)
fprintf('\n--- Target Zone Analysis (350-400 ft) ---\n');

% Extract target zone data
target_zone_mask = depth_roi >= target_zone_top & depth_roi <= target_zone_bot;
target_zone_depths = depth_roi(target_zone_mask);
target_zone_data_analysis = displacement_rate_analysis(:, target_zone_mask);
target_zone_data_final_pump = displacement_rate_final_pump(:, target_zone_mask);
target_zone_data_recovery = displacement_rate_recovery(:, target_zone_mask);

fprintf('Target zone depths: %.1f - %.1f ft (%d channels)\n', ...
    min(target_zone_depths), max(target_zone_depths), sum(target_zone_mask));
fprintf('Target zone signal range: [%.3f, %.3f] nε/s\n', ...
    min(target_zone_data_analysis(:)), max(target_zone_data_analysis(:)));

%% 8. Create Visualizations

% 8a. Full analysis period heatmap
fprintf('\n--- Creating Visualizations ---\n');

% Calculate color limits for optimal contrast
analysis_lims = prctile(displacement_rate_analysis(:),[2 98]);  % 2nd and 98th percentiles

figure(1); clf
pcolor(datenum(Tdas_analysis), depth_roi, displacement_rate_analysis'), shading interp
colormap jet; caxis(analysis_lims)
c = colorbar; 
ylabel(c, 'Displacement Rate (nε/s)', 'FontSize', 12)
set(gca,'YDir','reverse')
ylim([90 well_depth_ft])  % PT-01b uses 90-665 ft range
xlim([datenum(final_pumping_start), datenum(recovery_end)])

% Add time markers
hold on
xline(datenum(pump_shutoff), 'w--', 'LineWidth', 3, 'Label', 'Pumps Shut Off (19:30)')
hold off

% Clean time axis
datetick('x','HH:MM','keeplimits')
title('PT-01b Displacement Rate: Final Pumping & Recovery', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid off
box on

set(gcf, 'Visible', 'on');
figure(1);
fprintf('✅ Figure 1: Full analysis period heatmap\n');

% 8b. Target zone focused heatmap (350-400 ft with buffer)
target_zone_buffer_top = target_zone_top - 20;  % 330 ft
target_zone_buffer_bot = target_zone_bot + 20;  % 420 ft
target_zone_lims = prctile(target_zone_data_analysis(:), [5 95]);  % Tighter percentiles for contrast

figure(2); clf
pcolor(datenum(Tdas_analysis), target_zone_depths, target_zone_data_analysis'), shading interp
colormap jet; caxis(target_zone_lims)
c = colorbar; 
ylabel(c, 'Displacement Rate (nε/s)', 'FontSize', 12)
set(gca,'YDir','reverse')
ylim([target_zone_buffer_top, target_zone_buffer_bot])
xlim([datenum(final_pumping_start), datenum(recovery_end)])

% Add zone and time markers
hold on
xline(datenum(pump_shutoff), 'w--', 'LineWidth', 3, 'Label', 'Pumps Shut Off (19:30)')
yline(target_zone_top, 'k-', 'LineWidth', 2, 'Label', 'Well Screen Top (350 ft)')
yline(target_zone_bot, 'k-', 'LineWidth', 2, 'Label', 'Well Screen Bot (400 ft)')
yline(target_zone_buffer_top, 'r--', 'LineWidth', 1, 'Label', '20 ft Buffer')
yline(target_zone_buffer_bot, 'r--', 'LineWidth', 1, 'Label', '20 ft Buffer')
hold off

% Clean time axis and formatting
datetick('x','HH:MM','keeplimits')
title('PT-01b Target Zone Displacement Rate (350-400 ft)', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

set(gca, 'FontSize', 11)
grid on
box on

% Add depth grid lines for better resolution
yticks(330:10:420)
set(gca, 'YMinorTick', 'on')

set(gcf, 'Visible', 'on');
figure(2);
fprintf('✅ Figure 2: Target zone focused heatmap\n');

% 8c. Displacement rate traces at key depths
target_depths = [360, 375, 390];  % Within well screen zone
idx = arrayfun(@(d) find(abs(depth_roi-d)==min(abs(depth_roi-d)),1), target_depths);

clr = {'r','b','g'};
figure(3); clf, hold on
for k = 1:3
    trace = movmean(displacement_rate_analysis(:,idx(k)),30);  % 30-s moving average
    plot(Tdas_analysis, trace, 'Color', clr{k}, 'LineWidth', 2)
end

% Add pump shutoff marker
xline(pump_shutoff, 'k--', 'LineWidth', 2, 'Label', 'Pumps Shut Off')

hold off, grid on
legend({'360 ft','375 ft','390 ft', 'Pump Shutoff'},'Location','best')
xlabel('Time (UTC)'), ylabel('Displacement Rate (nε/s)')
xlim([final_pumping_start, recovery_end])
title('Displacement Rate Traces in Well Screen Zone (350-400 ft)', 'FontSize', 14)

set(gcf, 'Visible', 'on');
figure(3);
fprintf('✅ Figure 3: Displacement rate traces\n');

%% 9. Analysis Summary
fprintf('\n--- DISPLACEMENT RATE ANALYSIS SUMMARY ---\n');

% Calculate statistics for different periods
if ~isempty(displacement_rate_final_pump)
    final_pump_avg = mean(displacement_rate_final_pump(:), 'omitnan');
    final_pump_std = std(displacement_rate_final_pump(:), 'omitnan');
    target_zone_final_pump_avg = mean(target_zone_data_final_pump(:), 'omitnan');
else
    final_pump_avg = NaN;
    final_pump_std = NaN;
    target_zone_final_pump_avg = NaN;
end

if ~isempty(displacement_rate_recovery)
    recovery_avg = mean(displacement_rate_recovery(:), 'omitnan');
    recovery_std = std(displacement_rate_recovery(:), 'omitnan');
    target_zone_recovery_avg = mean(target_zone_data_recovery(:), 'omitnan');
else
    recovery_avg = NaN;
    recovery_std = NaN;
    target_zone_recovery_avg = NaN;
end

fprintf('\n=== SIGNAL CHARACTERISTICS ===\n');
fprintf('Analysis period: %s to %s (%.1f minutes total)\n', ...
    datestr(final_pumping_start), datestr(recovery_end), ...
    minutes(recovery_end - final_pumping_start));

if ~isnan(final_pump_avg)
    fprintf('\nFinal pumping period (19:15-19:30):\n');
    fprintf('  Average displacement rate: %.3f ± %.3f nε/s\n', final_pump_avg, final_pump_std);
    fprintf('  Target zone (350-400 ft): %.3f nε/s\n', target_zone_final_pump_avg);
    fprintf('  Signal range: [%.3f, %.3f] nε/s\n', ...
        min(displacement_rate_final_pump(:)), max(displacement_rate_final_pump(:)));
else
    fprintf('\nFinal pumping period: No data available\n');
end

if ~isnan(recovery_avg)
    fprintf('\nRecovery period (%s to %s):\n', datestr(pump_shutoff), datestr(recovery_end));
    fprintf('  Average displacement rate: %.3f ± %.3f nε/s\n', recovery_avg, recovery_std);
    fprintf('  Target zone (350-400 ft): %.3f nε/s\n', target_zone_recovery_avg);
    fprintf('  Signal range: [%.3f, %.3f] nε/s\n', ...
        min(displacement_rate_recovery(:)), max(displacement_rate_recovery(:)));
else
    fprintf('\nRecovery period: No data available\n');
end

fprintf('\nTarget zone analysis (350-400 ft well screen):\n');
fprintf('  Number of channels: %d\n', sum(target_zone_mask));
fprintf('  Depth range: %.1f - %.1f ft\n', min(target_zone_depths), max(target_zone_depths));

if ~isnan(target_zone_final_pump_avg) && ~isnan(target_zone_recovery_avg)
    fprintf('  Signal change (pump→recovery): %.3f nε/s\n', ...
        target_zone_recovery_avg - target_zone_final_pump_avg);
end

% Signal quality assessment
signal_dynamic_range = max(displacement_rate_analysis(:)) - min(displacement_rate_analysis(:));
fprintf('\nSignal quality:\n');
fprintf('  Dynamic range: %.3f nε/s\n', signal_dynamic_range);
fprintf('  Data completeness: %.1f%% (%d/%d time points)\n', ...
    100*sum(analysis_mask)/length(Tdas), sum(analysis_mask), length(Tdas));

fprintf('\nPT-01b Pump Schedule:\n');
fprintf('  15:30 - 50 GPM (1.0 hr)\n');
fprintf('  16:30 - 80 GPM (1.0 hr)\n');
fprintf('  17:30 - 110 GPM (1.0 hr)\n');
fprintf('  18:30 - 148 GPM (1.0 hr)\n');
fprintf('  19:30 - 0 GPM (recovery begins)\n');

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Generated visualizations:\n');
fprintf('  - Figure 1: Full analysis period heatmap\n');
fprintf('  - Figure 2: Target zone focused (350-400 ft)\n');
fprintf('  - Figure 3: Displacement rate traces at key depths\n');
fprintf('\nDisplacement rate analysis focused on well screen zone signals.\n');
fprintf('No integration applied - analyzing raw strain rate measurements.\n');