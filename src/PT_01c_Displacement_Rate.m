%% PT-01c Displacement Rate Analysis – Final Pumping & Recovery
% Analysis of displacement rate (strain rate) without integration
% Focus: 19:00-20:39 UTC (final 15 min pumping + full recovery)
% Target zone: 260-310 ft (well screen where clear signals expected)
% Based on PT_01c_CC.m but analyzing raw displacement rate instead of strain

clear; clc; close all
fprintf('=== PT-01c Displacement Rate Analysis Started ===\n');
fprintf('Script: PT_01c_Displacement_Rate.m\n');
fprintf('Dataset: PM07_01c_1Hz.mat (1Hz sampling rate)\n');
fprintf('Analysis Period: 19:00-20:39 UTC (Final pumping + Recovery)\n');
fprintf('Target Zone: 260-310 ft (Well Screen)\n');
fprintf('Signal: Displacement Rate (no integration)\n\n');

% Force figures to be visible
set(0, 'DefaultFigureVisible', 'on');
set(0, 'DefaultFigureWindowStyle', 'normal');

%% 1. Load data (same as PT_01c_CC.m)
fprintf('Loading PT01c data files...\n');

% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);  % Go up one level from src/ to project root
data_dir = fullfile(project_dir, 'data');

% Load data files from the data directory
pt01c_file = fullfile(data_dir, 'PM07_01c_1Hz.mat');
channel_file = fullfile(data_dir, 'Channel1_alldataupto070224.mat');

fprintf('Script location: %s\n', script_dir);
fprintf('Looking for data in: %s\n', data_dir);

if exist(pt01c_file, 'file') && exist(channel_file, 'file')
    load(pt01c_file)                 % → decdata
    fprintf('✓ Loaded PM07_01c_1Hz.mat: [%d x %d]\n', size(decdata));
    data = decdata;
    
    ld = load(channel_file);   % → distance
    fprintf('✓ Loaded Channel1_alldataupto070224.mat: %d depth points\n', length(ld.distance));
    DTS_depth_ft = ld.distance*3.28084;
else
    error('❌ Data files not found in %s\nMake sure PM07_01c_1Hz.mat and Channel1_alldataupto070224.mat are in the data folder.', data_dir);
end

%% 2. Simple filtering for 1Hz data
fprintf('\n--- Basic Filtering for 1Hz Data ---\n');
fprintf('Applying basic filtering to clean up signals...\n');

% Simple low-pass filtering for 1Hz data
fs = 1;
cutoff_freq = 0.3; % Conservative cutoff
[b, a] = butter(3, cutoff_freq/(fs/2), 'low');  % Low order filter

% Apply light filtering
for ch = 1:size(data, 2)
    data(:, ch) = filtfilt(b, a, data(:, ch));
end

fprintf('Applied basic low-pass filtering\n');

%% 3. Depth control (same parameters as PT_01c_CC.m)
fprintf('\n--- Depth Control Setup ---\n');
C1 = 110; BOT = 920; well_depth_ft = 665; water_table_depth_ft = 89;
dx_m = 0.25; dx_ft = dx_m*3.28084;
fprintf('✓ Depth control: C1=%d, BOT=%d, well_depth=%d ft\n', C1, BOT, well_depth_ft);

DAS_depth_ft = ((0:size(data,2)-1).*dx_m)*3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
scale        = well_depth_ft/raw_depth_ft(BOT);
final_depth_ft = raw_depth_ft*scale;

% Define target zone for analysis (well screening zone where signals expected)
target_zone_top = 260;    % ft - well screened zone
target_zone_bot = 310;    % ft - well screened zone  
target_zone_center = 285; % ft

%% 4. Depth Calibration Correction (same as PT_01c_CC.m)
depth_offset = 5;      % ft - correction to align with gamma ray features
depth_stretch = 1.0;   % multiplier to stretch/compress depth scale

% Apply depth calibration
final_depth_ft_corrected = (final_depth_ft + depth_offset) * depth_stretch;

fprintf('Original DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft), max(final_depth_ft));
fprintf('Corrected DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft_corrected), max(final_depth_ft_corrected));
fprintf('Target analysis zone: %.1f-%.1f ft (well screen)\n', target_zone_top, target_zone_bot);

% Use corrected depths for all analysis
final_depth_ft = final_depth_ft_corrected;

%% 5. Time axis setup
T0 = datetime(2023,10,24,15,17,36,'TimeZone','UTC');  % PT01c file start
Tdas = T0 + seconds((0:size(data,1)-1));  % Now at 1Hz after decimation

%% 6. Enhanced Common Mode Removal (NO INTEGRATION)
fprintf('\n--- Enhanced Common Mode Removal (No Integration) ---\n');
fprintf('Processing displacement rate data (strain rate)...\n');

% Focus on clean middle section (avoid surface noise and cable termination)
roi_top = 200;      % ft - avoid surface/shallow noise
roi_bottom = 580;   % ft - avoid cable termination effects
roi = final_depth_ft>=roi_top & final_depth_ft<=roi_bottom;
data_well = data(:, roi);
depth_roi = final_depth_ft(roi);

fprintf('Analysis ROI: %.0f - %.0f ft (excludes surface noise and termination effects)\n', roi_top, roi_bottom);

% Step 1: Remove temporal mean from each channel
data_temp_cleaned = zeros(size(data));
for ch = 1:size(data, 2)
    channel_data = data(:, ch);
    temporal_mean = mean(channel_data, 'omitnan');
    data_temp_cleaned(:, ch) = channel_data - temporal_mean;
end

% Step 2: Aggressive Common Mode Removal
fprintf('Applying aggressive common mode removal...\n');

% Method: Use running spatial median to remove horizontal stripes
data_cleaned = data_temp_cleaned;

% Apply spatial common mode removal with local references
reference_channels = final_depth_ft>=300 & final_depth_ft<=500;  % Use stable deep zone as reference

for t = 1:size(data_cleaned, 1)
    % Calculate spatial common mode from reference zone
    ref_slice = data_cleaned(t, reference_channels);
    spatial_cm = median(ref_slice, 'omitnan');
    
    % Remove common mode from all channels
    data_cleaned(t, :) = data_cleaned(t, :) - spatial_cm;
end

% Additional step: Remove any remaining temporal trends in each channel
for ch = 1:size(data_cleaned, 2)
    % Detrend each channel (remove linear trends)
    if sum(~isnan(data_cleaned(:, ch))) > 10  % Only if enough data points
        data_cleaned(:, ch) = detrend(data_cleaned(:, ch), 'linear');
    end
end

fprintf('Applied temporal mean removal to %d channels\n', size(data, 2));
fprintf('Applied spatial common mode removal (median subtraction)\n');
fprintf('Working with displacement rate (nε/s) - NO integration applied\n');

% Extract displacement rate data for ROI
displacement_rate_roi = data_cleaned(:, roi);

%% 7. Define Analysis Time Windows
fprintf('\n--- Time Window Definition ---\n');

% Define analysis periods based on actual data availability
final_pumping_start = datetime(2023,10,24,19,0,0,'TimeZone','UTC');   % 15 min before shutoff
pump_shutoff = datetime(2023,10,24,19,15,0,'TimeZone','UTC');         % Pumps shut off

% Determine actual data end time
data_end_time = max(Tdas);
recovery_end = min(datetime(2023,10,24,20,39,0,'TimeZone','UTC'), data_end_time); % Use actual data end

fprintf('Data available until: %s\n', datestr(data_end_time));
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

%% 8. Target Zone Analysis (260-310 ft)
fprintf('\n--- Target Zone Analysis (260-310 ft) ---\n');

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

%% 9. Create Visualizations

% 9a. Full analysis period heatmap (19:00-20:39)
fprintf('\n--- Creating Visualizations ---\n');

% Use cleaned data without additional smoothing to avoid artifacts
% Calculate color limits for optimal contrast
analysis_lims = prctile(displacement_rate_analysis(:),[10 90]);  % Use 10-90 percentiles to clip extreme noise

figure(1); clf
pcolor(datenum(Tdas_analysis), depth_roi, displacement_rate_analysis'), shading interp
colormap jet; caxis(analysis_lims)
c = colorbar; 
ylabel(c, 'Displacement Rate (nε/s)', 'FontSize', 12)
set(gca,'YDir','reverse')
ylim([roi_top roi_bottom])  % Focus on clean middle section: 200-580 ft
xlim([datenum(final_pumping_start), datenum(recovery_end)])

% Add time markers
hold on
xline(datenum(pump_shutoff), 'w--', 'LineWidth', 3, 'Label', 'Pumps Shut Off (19:15)')
hold off

% Clean time axis
datetick('x','HH:MM','keeplimits')
title('PT-01c Displacement Rate: Final Pumping & Recovery (19:00-20:39)', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid off
box on

set(gcf, 'Visible', 'on');
figure(1);
fprintf('✅ Figure 1: Full analysis period heatmap\n');

% 9b. Extended target zone heatmap (250-320 ft)
% Extract extended zone data for better context
extended_zone_top = 250;
extended_zone_bot = 320;
extended_zone_mask = depth_roi >= extended_zone_top & depth_roi <= extended_zone_bot;
extended_zone_depths = depth_roi(extended_zone_mask);
extended_zone_data = displacement_rate_analysis(:, extended_zone_mask);

% Use cleaned data without smoothing artifacts
extended_zone_lims = prctile(extended_zone_data(:), [10 90]);  % Clip extreme noise

figure(2); clf
pcolor(datenum(Tdas_analysis), extended_zone_depths, extended_zone_data'), shading interp
colormap jet; caxis(extended_zone_lims)
c = colorbar; 
ylabel(c, 'Displacement Rate (nε/s)', 'FontSize', 12)
set(gca,'YDir','reverse')
ylim([extended_zone_top, extended_zone_bot])  % Full extended range
xlim([datenum(final_pumping_start), datenum(recovery_end)])

% Add zone and time markers
hold on
xline(datenum(pump_shutoff), 'w--', 'LineWidth', 3, 'Label', 'Pumps Shut Off (19:15)')
yline(target_zone_top, 'k-', 'LineWidth', 2, 'Label', 'Well Screen Top (260 ft)')
yline(target_zone_bot, 'k-', 'LineWidth', 2, 'Label', 'Well Screen Bot (310 ft)')
hold off

% Clean time axis and formatting
datetick('x','HH:MM','keeplimits')
title('PT-01c Extended Target Zone Displacement Rate (250-320 ft)', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

set(gca, 'FontSize', 11)
grid on
box on

set(gcf, 'Visible', 'on');
figure(2);
fprintf('✅ Figure 2: Extended target zone heatmap (250-320 ft)\n');

% 9c. Displacement rate traces at key depths
target_depths = [270, 285, 300];  % Within well screen zone
idx = arrayfun(@(d) find(abs(depth_roi-d)==min(abs(depth_roi-d)),1), target_depths);

clr = {'r','b','g'};
figure(3); clf, hold on
for k = 1:3
    trace = movmean(displacement_rate_analysis(:,idx(k)),30);  % 30-s moving average (30 points at 1Hz)
    plot(Tdas_analysis, trace, 'Color', clr{k}, 'LineWidth', 2)
end

% Add pump shutoff marker
xline(pump_shutoff, 'k--', 'LineWidth', 2, 'Label', 'Pumps Shut Off')

hold off, grid on
legend({'270 ft','285 ft','300 ft', 'Pump Shutoff'},'Location','best')
xlabel('Time (UTC)'), ylabel('Displacement Rate (nε/s)')
xlim([final_pumping_start, recovery_end])
title('Displacement Rate Traces in Well Screen Zone', 'FontSize', 14)

set(gcf, 'Visible', 'on');
figure(3);
fprintf('✅ Figure 3: Displacement rate traces\n');

%% 10. Analysis Summary
fprintf('\n--- DISPLACEMENT RATE ANALYSIS SUMMARY ---\n');

% Calculate statistics for different periods
final_pump_avg = mean(displacement_rate_final_pump(:), 'omitnan');
final_pump_std = std(displacement_rate_final_pump(:), 'omitnan');

recovery_avg = mean(displacement_rate_recovery(:), 'omitnan');
recovery_std = std(displacement_rate_recovery(:), 'omitnan');

target_zone_final_pump_avg = mean(target_zone_data_final_pump(:), 'omitnan');
target_zone_recovery_avg = mean(target_zone_data_recovery(:), 'omitnan');

fprintf('\n=== SIGNAL CHARACTERISTICS ===\n');
fprintf('Analysis period: %s to %s (%.1f minutes total)\n', ...
    datestr(final_pumping_start), datestr(recovery_end), ...
    minutes(recovery_end - final_pumping_start));

fprintf('\nFinal pumping period (19:00-19:15):\n');
fprintf('  Average displacement rate: %.3f ± %.3f nε/s\n', final_pump_avg, final_pump_std);
fprintf('  Target zone (260-310 ft): %.3f nε/s\n', target_zone_final_pump_avg);
fprintf('  Signal range: [%.3f, %.3f] nε/s\n', ...
    min(displacement_rate_final_pump(:)), max(displacement_rate_final_pump(:)));

fprintf('\nRecovery period (19:15-20:39):\n');
fprintf('  Average displacement rate: %.3f ± %.3f nε/s\n', recovery_avg, recovery_std);
fprintf('  Target zone (260-310 ft): %.3f nε/s\n', target_zone_recovery_avg);
fprintf('  Signal range: [%.3f, %.3f] nε/s\n', ...
    min(displacement_rate_recovery(:)), max(displacement_rate_recovery(:)));

fprintf('\nTarget zone analysis (260-310 ft well screen):\n');
fprintf('  Number of channels: %d\n', sum(target_zone_mask));
fprintf('  Depth range: %.1f - %.1f ft\n', min(target_zone_depths), max(target_zone_depths));
fprintf('  Signal change (pump→recovery): %.3f nε/s\n', ...
    target_zone_recovery_avg - target_zone_final_pump_avg);

% Signal quality assessment
signal_dynamic_range = max(displacement_rate_analysis(:)) - min(displacement_rate_analysis(:));
fprintf('\nSignal quality:\n');
fprintf('  Dynamic range: %.3f nε/s\n', signal_dynamic_range);
fprintf('  Data completeness: %.1f%% (%d/%d time points)\n', ...
    100*sum(analysis_mask)/length(Tdas), sum(analysis_mask), length(Tdas));

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Generated visualizations:\n');
fprintf('  - Figure 1: Full analysis period (19:00-20:39)\n');
fprintf('  - Figure 2: Target zone focused (260-310 ft)\n');
fprintf('  - Figure 3: Displacement rate traces at key depths\n');
fprintf('\nDisplacement rate analysis focused on well screen zone signals.\n');
fprintf('No integration applied - analyzing raw strain rate measurements.\n');