%% DAS Pumping & Recovery Analysis – PT-01a (Clean Signal Focus)
% Clean visualization focused on exposing both pumping and recovery signal patterns
% Pumping well: 95 ft away, screened at 450-510 ft depth

clear; clc; close all

%% 1. Load data
fprintf('Loading PT01a data files...\n');

% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);  % Go up one level from src/ to project root
data_dir = fullfile(project_dir, 'data');

% Load data files from the data directory
pt01a_file = fullfile(data_dir, 'PM07_01a_1Hz.mat');
channel_file = fullfile(data_dir, 'Channel1_alldataupto070224.mat');

fprintf('Script location: %s\n', script_dir);
fprintf('Looking for data in: %s\n', data_dir);

if exist(pt01a_file, 'file') && exist(channel_file, 'file')
    load(pt01a_file)                 % → decdata
    fprintf('✓ Loaded PM07_01a_1Hz.mat: [%d x %d]\n', size(decdata));
    data = decdata;
    
    ld = load(channel_file);   % → distance
    fprintf('✓ Loaded Channel1_alldataupto070224.mat: %d depth points\n', length(ld.distance));
    DTS_depth_ft = ld.distance*3.28084;
else
    error('❌ Data files not found in %s\nMake sure PM07_01a_1Hz.mat and Channel1_alldataupto070224.mat are in the data folder.', data_dir);
end

%% 2. Depth control
C1 = 513; BOT = 1324; well_depth_ft = 665; water_table_depth_ft = 89;
dx_m = 0.25; dx_ft = dx_m*3.28084;

DAS_depth_ft = ((0:size(data,2)-1).*dx_m)*3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
scale        = well_depth_ft/raw_depth_ft(BOT);
final_depth_ft = raw_depth_ft*scale;

% Define pumping zone for analysis (but not for annotation)
pump_zone_top = 450;    % ft
pump_zone_bot = 510;    % ft
pump_zone_center = 480; % ft

%% 2b. Depth Calibration Correction
% TO ALIGN WITH GAMMA RAY LOG:
% 1. Look at prominent gamma ray features (spikes/dips) in the plots
% 2. Note their depths in the gamma ray log
% 3. Find corresponding features in the DAS heatmap
% 4. Adjust parameters below to align them:

depth_offset = 5;      % ft - try +5 ft correction to align gamma peaks with horizontal features
depth_stretch = 1.0;   % multiplier to stretch/compress depth scale

% Apply depth calibration
final_depth_ft_corrected = (final_depth_ft + depth_offset) * depth_stretch;

fprintf('\n--- Depth Calibration ---\n');
fprintf('Original DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft), max(final_depth_ft));
fprintf('Corrected DAS depth range: %.1f to %.1f ft\n', min(final_depth_ft_corrected), max(final_depth_ft_corrected));
fprintf('Depth offset: %.1f ft, Depth stretch: %.3f\n', depth_offset, depth_stretch);
fprintf('Depth correction: %.1f ft shift applied\n', depth_offset);
fprintf('ALIGNMENT CHECK: Gamma ray peaks should align with horizontal features in DAS heatmap\n');
fprintf('If misaligned, adjust depth_offset: increase (+) or decrease (-) by 1-3 ft increments\n');

% Use corrected depths for all analysis
final_depth_ft = final_depth_ft_corrected;

%% 3. Time axis
Fs = 1;
Tdas = datetime(2023,11,7,16,45,36,'TimeZone','UTC') + seconds((0:size(data,1)-1));

%% 4. Temporal common mode removal
fprintf('\n--- Per Channel Average Subtraction ---\n');
fprintf('Original strain rate data size: [%d x %d]\n', size(data));

% Focus on the well casing region
roi = final_depth_ft>=90 & final_depth_ft<=well_depth_ft;
data_well = data(:, roi);
depth_roi = final_depth_ft(roi);

% For each depth channel, remove its temporal mean
for ch = 1:size(data, 2)
    channel_data = data(:, ch);
    
    % Remove temporal mean from this channel
    temporal_mean = mean(channel_data, 'omitnan');
    data_cleaned(:, ch) = channel_data - temporal_mean;
end

fprintf('Applied per-channel temporal mean removal to %d channels\n', size(data, 2));
fprintf('This removes systematic biases in each depth channel\n');

%% 5. Integration and baseline
fprintf('\n--- Integration and Baseline ---\n');
intdata = cumtrapz(data_cleaned, 1);
idata_roi = intdata(:, roi);

% Recovery period definition
recovery_start = datetime(2023,11,7,20,45,0,'TimeZone','UTC');
recovery_end = datetime(2023,11,7,22,21,0,'TimeZone','UTC');

% Baseline: last 5 minutes before recovery (your original approach)
t_baseline = Tdas >= datetime(2023,11,7,20,40,0,'TimeZone','UTC') & ...
             Tdas <  datetime(2023,11,7,20,45,0,'TimeZone','UTC');

baseline = mean(idata_roi(t_baseline,:),1,'omitnan');
dstrain = idata_roi - baseline;

% Pumping period definition (for additional pumping analysis)
% Estimate based on typical pump test duration
pumping_start = datetime(2023,11,7,17,0,0,'TimeZone','UTC');  % Estimate: 3.75 hours of pumping
pumping_end = recovery_start;  % Pumping ends when recovery begins

% Filter to recovery period
recovery_mask = Tdas >= recovery_start & Tdas <= recovery_end;
Tdas_recovery = Tdas(recovery_mask);
dstrain_recovery = dstrain(recovery_mask,:);

fprintf('Recovery period: %s to %s\n', datestr(recovery_start), datestr(recovery_end));
fprintf('Recovery data size: [%d x %d]\n', size(dstrain_recovery));

%% 6. Clean recovery heatmap - focus on signal
% Use optimal color limits for best signal exposure
lims = prctile(dstrain_recovery(:),[1 99]);  % 1st and 99th percentiles for maximum contrast

figure(1); clf
pcolor(datenum(Tdas_recovery), depth_roi, dstrain_recovery'), shading interp
colormap jet; caxis(lims)
c = colorbar; 
ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
set(gca,'YDir','reverse')
ylim([90 well_depth_ft])
xlim([datenum(recovery_start), datenum(recovery_end)])

% Clean time axis
datetick('x','HH:MM','keeplimits')
title('Aquifer Recovery Signal – PT-01a', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid off
box on

%% 6b. Focused pumping zone analysis (430-530 ft extended view)
fprintf('\n--- Focused Pumping Zone Analysis (Extended View) ---\n');

% Extract pumping zone data with extended bounds for figure 4
pump_zone_buffer_top = pump_zone_top - 20;  % 430 ft
pump_zone_buffer_bot = pump_zone_bot + 20;  % 530 ft
pump_zone_mask = depth_roi >= pump_zone_buffer_top & depth_roi <= pump_zone_buffer_bot;
pump_zone_depths = depth_roi(pump_zone_mask);
pump_zone_data = dstrain_recovery(:, pump_zone_mask);

% Enhanced color scaling for pumping zone
pump_zone_lims = prctile(pump_zone_data(:), [5 95]);  % Tighter percentiles for more contrast

fprintf('Extended view depths: %.1f - %.1f ft (%d channels)\n', ...
    min(pump_zone_depths), max(pump_zone_depths), sum(pump_zone_mask));
fprintf('Extended view signal range: [%.1f, %.1f] nε\n', ...
    min(pump_zone_data(:)), max(pump_zone_data(:)));

%% 6c. Load and process LAS file for Gamma Ray overlay
fprintf('\n--- Loading LAS Gamma Ray Data ---\n');

% Prompt for LAS file or use default name
las_file = 'C:\Users\Hannah Fitz\OneDrive - csulb\RBGRP\WellCAD\LAS\31086_ELOG.las';
if ~exist(las_file, 'file')
    fprintf('LAS file not found. Please ensure %s is in the current directory.\n', las_file);
    fprintf('Continuing without gamma ray overlay...\n');
    gr_data = [];
    gr_depth = [];
    gr_data_full = [];
    gr_depth_full = [];
else
    try
        % Read LAS file
        fid = fopen(las_file, 'r');
        if fid == -1
            error('Could not open LAS file');
        end
        
        % Read header to find data section
        line = fgetl(fid);
        data_started = false;
        while ischar(line) && ~data_started
            if contains(line, '~A') || contains(line, '~ASCII')
                data_started = true;
                break;
            end
            line = fgetl(fid);
        end
        
        if ~data_started
            error('Could not find data section in LAS file');
        end
        
        % Read data section
        data_lines = {};
        line = fgetl(fid);
        while ischar(line)
            if ~isempty(line) && ~startsWith(line, '~')
                data_lines{end+1} = line;
            end
            line = fgetl(fid);
        end
        fclose(fid);
        
        % Parse data - assuming format: DEPT RSN RLN SP GR RSNCorr RLNCorr RLL3 XCAL
        % GR is column 5 based on the header you provided
        data_matrix = [];
        for i = 1:length(data_lines)
            values = str2num(data_lines{i});
            if length(values) >= 5  % Make sure we have enough columns
                data_matrix = [data_matrix; values];
            end
        end
        
        if isempty(data_matrix)
            error('Could not parse data from LAS file');
        end
        
        % Extract depth and GR columns
        las_depth = data_matrix(:, 1);  % DEPT column
        las_gr = data_matrix(:, 5);     % GR column
        
        % Filter to pumping zone plus buffer (430-530 ft) for focused plot
        pump_zone_las_mask = las_depth >= 430 & las_depth <= 530;
        gr_depth = las_depth(pump_zone_las_mask);
        gr_data = las_gr(pump_zone_las_mask);
        
        % Remove null values (-999.25) for pumping zone
        valid_gr = gr_data ~= -999.25 & ~isnan(gr_data);
        gr_depth = gr_depth(valid_gr);
        gr_data = gr_data(valid_gr);
        
        % Filter to full well depth range (90-665 ft) for full plot
        full_well_las_mask = las_depth >= 90 & las_depth <= 665;
        gr_depth_full = las_depth(full_well_las_mask);
        gr_data_full = las_gr(full_well_las_mask);
        
        % Remove null values (-999.25) for full range
        valid_gr_full = gr_data_full ~= -999.25 & ~isnan(gr_data_full);
        gr_depth_full = gr_depth_full(valid_gr_full);
        gr_data_full = gr_data_full(valid_gr_full);
        
        fprintf('Loaded gamma ray data from %s\n', las_file);
        fprintf('Pumping zone GR: %d points (%.1f - %.1f ft)\n', length(gr_data), min(gr_depth), max(gr_depth));
        fprintf('Full well GR: %d points (%.1f - %.1f ft)\n', length(gr_data_full), min(gr_depth_full), max(gr_depth_full));
        fprintf('GR value range: %.1f - %.1f GAPI\n', min([gr_data; gr_data_full]), max([gr_data; gr_data_full]));
        
    catch ME
        fprintf('Error reading LAS file: %s\n', ME.message);
        fprintf('Continuing without gamma ray overlay...\n');
        gr_data = [];
        gr_depth = [];
        gr_data_full = [];
        gr_depth_full = [];
    end
end

% Create focused pumping zone heatmap with gamma ray overlay
figure(4); clf

if ~isempty(gr_data)
    % Create subplot with gamma ray on the left
    subplot(1,10,1:2)  % GR subplot takes 2/10 of width
    
    % Plot gamma ray log
    plot(gr_data, gr_depth, 'k-', 'LineWidth', 2)
    set(gca, 'YDir', 'reverse')
    ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
    xlim([45, 100])  % Set GR scale to 45-100 GAPI
    xlabel('GR (GAPI)', 'FontSize', 10)
    ylabel('Depth (ft)', 'FontSize', 10)
    title('Gamma Ray', 'FontSize', 11)
    grid on
    
    % Clean gamma ray log without value labels
    
    % Main heatmap subplot
    subplot(1,10,3:10)  % Heatmap takes 8/10 of width
    pcolor(datenum(Tdas_recovery), pump_zone_depths, pump_zone_data'), shading interp
    colormap(gca, jet); caxis(pump_zone_lims)
    c = colorbar; 
    ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
    set(gca,'YDir','reverse')
    ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
    xlim([datenum(recovery_start), datenum(recovery_end)])
    
    % Add well and pumping zone markers
    hold on
    % Extended view boundary (300 ft)
    yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone (430 ft)')
    
    % 20 feet below pumping zone (420 ft)
    yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
    
    % Pumping zone boundaries
    yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Top (450 ft)')
    yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Bot (510 ft)')
    
    % Well boundaries (if within visible range)
    if water_table_depth_ft >= pump_zone_buffer_top && water_table_depth_ft <= pump_zone_buffer_bot
        yline(water_table_depth_ft, 'w--', 'LineWidth', 2, 'Label', 'Water Table (90 ft)')
    end
    
    if well_depth_ft >= pump_zone_buffer_top && well_depth_ft <= pump_zone_buffer_bot
        yline(well_depth_ft, 'w--', 'LineWidth', 2, 'Label', 'Well Bottom (665 ft)')
    end
    hold off
    
    % Remove y-axis labels from heatmap since GR subplot has them
    set(gca, 'YTickLabel', [])
    
else
    % No gamma ray data - just create regular heatmap
    pcolor(datenum(Tdas_recovery), pump_zone_depths, pump_zone_data'), shading interp
    colormap jet; caxis(pump_zone_lims)
    c = colorbar; 
    ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
    set(gca,'YDir','reverse')
    ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
    xlim([datenum(recovery_start), datenum(recovery_end)])
    ylabel('Depth (ft)', 'FontSize', 12)
    
    % Add markers even without gamma ray
    hold on
    yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone (430 ft)')
    yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
    yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Top (450 ft)')
    yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Bot (510 ft)')
    hold off
end

% Clean time axis and formatting
datetick('x','HH:MM','keeplimits')
title('Recovery Signal (430-530 ft)', 'FontSize', 12)
xlabel('Time (UTC)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid on
box on

% Add depth grid lines for better resolution
yticks(430:20:530)
set(gca, 'YMinorTick', 'on')

% Add overall title for the figure
if ~isempty(gr_data)
    sgtitle('Pumping Zone Recovery Signal with Gamma Ray Log (430-530 ft)', 'FontSize', 14)
else
    title('Pumping Zone Recovery Signal (430-530 ft)', 'FontSize', 14)
end

%% 6d. Full recovery heatmap with GR overlay
if ~isempty(gr_data_full)
    figure(6); clf
    
    % Create subplot with gamma ray on the left
    subplot(1,10,1:2)  % GR subplot takes 2/10 of width
    
    % Plot gamma ray log for full range
    plot(gr_data_full, gr_depth_full, 'k-', 'LineWidth', 2)
    set(gca, 'YDir', 'reverse')
    ylim([90 well_depth_ft])
    xlim([45, 130])  % Set GR scale to 45-100 GAPI
    xlabel('GR (GAPI)', 'FontSize', 10)
    ylabel('Depth (ft)', 'FontSize', 10)
    title('Gamma Ray', 'FontSize', 11)
    grid on
    
    % Clean gamma ray log without value labels
    
    % Main heatmap subplot
    subplot(1,10,3:10)  % Heatmap takes 8/10 of width
    pcolor(datenum(Tdas_recovery), depth_roi, dstrain_recovery'), shading interp
    colormap(gca, jet); caxis(lims)
    c = colorbar; 
    ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
    set(gca,'YDir','reverse')
    ylim([90 well_depth_ft])
    xlim([datenum(recovery_start), datenum(recovery_end)])
    
    % Remove y-axis labels from heatmap since GR subplot has them
    set(gca, 'YTickLabel', [])
    
    % Clean time axis
    datetick('x','HH:MM','keeplimits')
    title('Full Recovery Signal', 'FontSize', 12)
    xlabel('Time (UTC)', 'FontSize', 12)
    
    % Improve figure appearance
    set(gca, 'FontSize', 11)
    grid off
    box on
    
    % Add overall title for the figure
    sgtitle('Full Recovery Signal with Gamma Ray Log', 'FontSize', 14)
    
    fprintf('Added gamma ray overlay to recovery plots\n');
end

% Figure 5 removed as requested

%% 6e. PUMPING ANALYSIS - Active Pumping Period
fprintf('\n--- PUMPING PERIOD ANALYSIS ---\n');

% Filter to pumping period
pumping_mask = Tdas >= pumping_start & Tdas <= pumping_end;
Tdas_pumping = Tdas(pumping_mask);
dstrain_pumping = dstrain(pumping_mask,:);

fprintf('Pumping period: %s to %s\n', datestr(pumping_start), datestr(pumping_end));
fprintf('Pumping duration: %.1f hours\n', hours(pumping_end - pumping_start));
fprintf('Pumping data size: [%d x %d]\n', size(dstrain_pumping));

% Check if we have pumping data
if isempty(dstrain_pumping)
    fprintf('⚠ Warning: No data found for estimated pumping period\n');
    fprintf('   Data time range: %s to %s\n', datestr(min(Tdas)), datestr(max(Tdas)));
    fprintf('   You may need to adjust pumping_start time\n');
else
    % Use optimal color limits for pumping signal
    pump_lims = prctile(dstrain_pumping(:),[1 99]);  % 1st and 99th percentiles for maximum contrast
    
    %% 6f. Full pumping heatmap
    figure(7); clf
    
    if ~isempty(gr_data_full)
        % Create subplot with gamma ray on the left
        subplot(1,10,1:2)  % GR subplot takes 2/10 of width
        
        % Plot gamma ray log for full range
        plot(gr_data_full, gr_depth_full, 'k-', 'LineWidth', 2)
        set(gca, 'YDir', 'reverse')
        ylim([90 well_depth_ft])
        xlim([45, 130])  % Set GR scale
        xlabel('GR (GAPI)', 'FontSize', 10)
        ylabel('Depth (ft)', 'FontSize', 10)
        title('Gamma Ray', 'FontSize', 11)
        grid on
        
        % Main heatmap subplot
        subplot(1,10,3:10)  % Heatmap takes 8/10 of width
        pcolor(datenum(Tdas_pumping), depth_roi, dstrain_pumping'), shading interp
        colormap(gca, jet); caxis(pump_lims)
        c = colorbar; 
        ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
        set(gca,'YDir','reverse')
        ylim([90 well_depth_ft])
        xlim([datenum(pumping_start), datenum(pumping_end)])
        
        % Remove y-axis labels from heatmap since GR subplot has them
        set(gca, 'YTickLabel', [])
        
        % Add overall title for the figure
        sgtitle('Full Pumping Signal with Gamma Ray Log', 'FontSize', 14)
        
    else
        % No gamma ray data - just create regular heatmap
        pcolor(datenum(Tdas_pumping), depth_roi, dstrain_pumping'), shading interp
        colormap jet; caxis(pump_lims)
        c = colorbar; 
        ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
        set(gca,'YDir','reverse')
        ylim([90 well_depth_ft])
        xlim([datenum(pumping_start), datenum(pumping_end)])
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Aquifer Pumping Signal – PT-01a', 'FontSize', 14)
    end
    
    % Clean time axis
    datetick('x','HH:MM','keeplimits')
    xlabel('Time (UTC)', 'FontSize', 12)
    
    % Improve figure appearance
    set(gca, 'FontSize', 11)
    grid off
    box on
    
    %% 6g. Focused pumping zone analysis
    % Extract pumping zone data for focused analysis
    pump_zone_data_pumping = dstrain_pumping(:, pump_zone_mask);
    pump_zone_lims_pumping = prctile(pump_zone_data_pumping(:), [5 95]);  % Tighter percentiles for contrast
    
    figure(8); clf
    
    if ~isempty(gr_data)
        % Create subplot with gamma ray on the left
        subplot(1,10,1:2)  % GR subplot takes 2/10 of width
        
        % Plot gamma ray log
        plot(gr_data, gr_depth, 'k-', 'LineWidth', 2)
        set(gca, 'YDir', 'reverse')
        ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
        xlim([45, 100])  % Set GR scale to 45-100 GAPI
        xlabel('GR (GAPI)', 'FontSize', 10)
        ylabel('Depth (ft)', 'FontSize', 10)
        title('Gamma Ray', 'FontSize', 11)
        grid on
        
        % Main heatmap subplot
        subplot(1,10,3:10)  % Heatmap takes 8/10 of width
        pcolor(datenum(Tdas_pumping), pump_zone_depths, pump_zone_data_pumping'), shading interp
        colormap(gca, jet); caxis(pump_zone_lims_pumping)
        c = colorbar; 
        ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
        set(gca,'YDir','reverse')
        ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
        xlim([datenum(pumping_start), datenum(pumping_end)])
        
        % Add zone markers
        hold on
        yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone (430 ft)')
        yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
        yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Top (450 ft)')
        yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Bot (510 ft)')
        hold off
        
        % Remove y-axis labels from heatmap since GR subplot has them
        set(gca, 'YTickLabel', [])
        
        % Add overall title for the figure
        sgtitle('Pumping Zone Signal with Gamma Ray Log (430-530 ft)', 'FontSize', 14)
        
    else
        % No gamma ray data - just create regular heatmap
        pcolor(datenum(Tdas_pumping), pump_zone_depths, pump_zone_data_pumping'), shading interp
        colormap jet; caxis(pump_zone_lims_pumping)
        c = colorbar; 
        ylabel(c, 'Δ-Strain (nε)', 'FontSize', 12)
        set(gca,'YDir','reverse')
        ylim([pump_zone_buffer_top, pump_zone_buffer_bot])
        xlim([datenum(pumping_start), datenum(pumping_end)])
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Pumping Signal (430-530 ft)', 'FontSize', 14)
        
        % Add zone markers
        hold on
        yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone (430 ft)')
        yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
        yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Top (450 ft)')
        yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Pump Zone Bot (510 ft)')
        hold off
    end
    
    % Clean time axis and formatting
    datetick('x','HH:MM','keeplimits')
    xlabel('Time (UTC)', 'FontSize', 12)
    
    % Improve figure appearance
    set(gca, 'FontSize', 11)
    grid on
    box on
    
    % Add depth grid lines for better resolution
    yticks(430:20:530)
    set(gca, 'YMinorTick', 'on')
    
    %% 6h. Pumping progression analysis (Early vs Late pumping)
    % Define pumping periods for comparison
    pump_duration = pumping_end - pumping_start;
    early_pump_end = pumping_start + pump_duration/3;  % First third of pumping
    late_pump_start = pumping_end - pump_duration/3;   % Last third of pumping
    
    t_early_pumping = Tdas >= pumping_start & Tdas < early_pump_end;
    t_late_pumping = Tdas >= late_pump_start & Tdas <= pumping_end;
    
    if sum(t_early_pumping) > 0 && sum(t_late_pumping) > 0
        early_pumping_avg = mean(dstrain(t_early_pumping,:), 1, 'omitnan');
        late_pumping_avg = mean(dstrain(t_late_pumping,:), 1, 'omitnan');
        pumping_progression = late_pumping_avg - early_pumping_avg;
        
        % Pumping progression comparison plot
        figure(9); clf
        subplot(1,2,1)
        plot(early_pumping_avg, depth_roi, 'g-', 'LineWidth', 2); hold on;
        plot(late_pumping_avg, depth_roi, 'm-', 'LineWidth', 2);
        set(gca,'YDir','reverse'), grid on
        xlabel('Average Δ-Strain (nε)', 'FontSize', 12)
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Early vs Late Pumping', 'FontSize', 13)
        legend('Early Pumping (1st third)', 'Late Pumping (last third)', 'Location', 'best')
        ylim([90 well_depth_ft])
        
        subplot(1,2,2)
        plot(pumping_progression, depth_roi, 'k-', 'LineWidth', 2)
        set(gca,'YDir','reverse'), grid on
        xlabel('Pumping Progression (nε)', 'FontSize', 12)
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Pumping Signal Development', 'FontSize', 13)
        ylim([90 well_depth_ft])
        
        % Add zero reference line
        hold on
        xline(0, 'k--', 'LineWidth', 1)
        hold off
        
        sgtitle('Pumping Analysis – PT-01a', 'FontSize', 14)
        
        % Define zone masks for pumping analysis
        above_pump = final_depth_ft >= 90 & final_depth_ft < pump_zone_top;
        pump_zone = final_depth_ft >= pump_zone_top & final_depth_ft <= pump_zone_bot;
        below_pump = final_depth_ft > pump_zone_bot & final_depth_ft <= well_depth_ft;
        
        above_pump_roi = above_pump(roi);
        pump_zone_roi = pump_zone(roi);
        below_pump_roi = below_pump(roi);
        
        % Zone-based pumping analysis
        above_pump_pumping = mean(pumping_progression(above_pump_roi), 'omitnan');
        pump_zone_pumping = mean(pumping_progression(pump_zone_roi), 'omitnan');
        below_pump_pumping = mean(pumping_progression(below_pump_roi), 'omitnan');
        
        fprintf('\n--- Pumping Progression Analysis ---\n');
        fprintf('Early pumping period: %s to %s\n', datestr(pumping_start), datestr(early_pump_end));
        fprintf('Late pumping period: %s to %s\n', datestr(late_pump_start), datestr(pumping_end));
        
        fprintf('\nPumping signal development (late - early):\n');
        fprintf('  Above pumping zone: %.1f nε\n', above_pump_pumping);
        fprintf('  Pumping zone: %.1f nε\n', pump_zone_pumping);
        fprintf('  Below pumping zone: %.1f nε\n', below_pump_pumping);
        
        fprintf('\nPumping signal characteristics:\n');
        fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_pumping(:)) - min(dstrain_pumping(:)));
        fprintf('  Pumping extent: %.1f hours\n', hours(pumping_end - pumping_start));
        
        % Check pumping patterns
        if abs(pump_zone_pumping) > abs(above_pump_pumping) && abs(pump_zone_pumping) > abs(below_pump_pumping)
            fprintf('  ✓ Maximum pumping response in pumping zone (as expected)\n');
        else
            fprintf('  ⚠ Pumping pattern differs from expected pumping zone response\n');
        end
    else
        fprintf('⚠ Warning: Insufficient data for pumping progression analysis\n');
    end
end

%% 7. Recovery period comparison analysis
fprintf('\n--- Recovery Period Analysis ---\n');

% Define recovery periods
t_early_recovery = Tdas >= datetime(2023,11,7,20,45,0,'TimeZone','UTC') & ...
                   Tdas <  datetime(2023,11,7,21,0,0,'TimeZone','UTC');
t_late_recovery = Tdas >= datetime(2023,11,7,22,0,0,'TimeZone','UTC') & ...
                  Tdas <  datetime(2023,11,7,22,15,0,'TimeZone','UTC');

early_recovery_avg = mean(dstrain(t_early_recovery,:), 1, 'omitnan');
late_recovery_avg = mean(dstrain(t_late_recovery,:), 1, 'omitnan');
recovery_difference = late_recovery_avg - early_recovery_avg;

fprintf('Early recovery period: 20:45-21:00 (%.1f minutes)\n', 15);
fprintf('Late recovery period: 22:00-22:15 (%.1f minutes)\n', 15);
fprintf('Recovery difference calculated for %d depth points\n', length(recovery_difference));

%% 8. Clean depth profile comparison
figure(2); clf
subplot(1,2,1)
plot(early_recovery_avg, depth_roi, 'r-', 'LineWidth', 2); hold on;
plot(late_recovery_avg, depth_roi, 'b-', 'LineWidth', 2);
set(gca,'YDir','reverse'), grid on
xlabel('Average Δ-Strain (nε)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)
title('Early vs Late Recovery', 'FontSize', 13)
legend('Early Recovery (20:45-21:00)', 'Late Recovery (22:00-22:15)', 'Location', 'best')
ylim([90 well_depth_ft])

subplot(1,2,2)
plot(recovery_difference, depth_roi, 'k-', 'LineWidth', 2)
set(gca,'YDir','reverse'), grid on
xlabel('Recovery Change (nε)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)
title('Recovery Deviation Profile', 'FontSize', 13)
ylim([90 well_depth_ft])

% Add zero reference line
hold on
xline(0, 'k--', 'LineWidth', 1)
hold off

sgtitle('Recovery Analysis – PT-01a', 'FontSize', 14)

%% 9. Zone-based analysis (background calculations)
% Calculate zone statistics without heavy visualization
above_pump = final_depth_ft >= 90 & final_depth_ft < pump_zone_top;
pump_zone = final_depth_ft >= pump_zone_top & final_depth_ft <= pump_zone_bot;
below_pump = final_depth_ft > pump_zone_bot & final_depth_ft <= well_depth_ft;

above_pump_roi = above_pump(roi);
pump_zone_roi = pump_zone(roi);
below_pump_roi = below_pump(roi);

above_pump_recovery = mean(recovery_difference(above_pump_roi), 'omitnan');
pump_zone_recovery = mean(recovery_difference(pump_zone_roi), 'omitnan');
below_pump_recovery = mean(recovery_difference(below_pump_roi), 'omitnan');

% Figure 3 removed as requested
%% 10. Step test specific analysis - strain-rate traces
fprintf('\n--- Step Test Strain-Rate Analysis ---\n');

% Extract strain-rate data for key depths during step test
target_depths = [250 400 550];
idx = arrayfun(@(d) find(abs(depth_roi-d)==min(abs(depth_roi-d)),1), target_depths);

% Use time axis that matches the data after padding
rate_roi = data_cleaned(:,roi);  % Use cleaned data instead of raw
tt = Tdas(end-size(rate_roi,1)+1 : end).';  % column vector, same length as each trace

clr = {'r','b','g'};
figure(5); clf, hold on
for k = 1:3
    trace = movmean(rate_roi(:,idx(k)),50);  % 50-s moving average
    plot(tt, trace, 'Color', clr{k}, 'LineWidth', 2)
end
hold off, grid on
legend({'250 ft','400 ft','550 ft'},'Location','best')
xlabel('Time (UTC)'), ylabel('Strain-rate (nε s⁻¹)')
xlim([datetime(2023,11,07,16,45,0,'TimeZone','UTC') ...
      datetime(2023,11,07,22,21,0,'TimeZone','UTC')])
title('Strain-Rate (CM Removed) – PT-01c Step-Test', 'FontSize', 14)

% Force figure to be visible and on top
set(gcf, 'Visible', 'on');
figure(5);  % Bring to front
fprintf('✅ Figure 5 created: Strain-rate traces\n');

%% 11. Summary statistics
fprintf('\n--- ANALYSIS SUMMARY ---\n');

% Pumping Analysis Summary (if data available)
if exist('dstrain_pumping', 'var') && ~isempty(dstrain_pumping)
    fprintf('\n=== PUMPING ANALYSIS SUMMARY ===\n');
    fprintf('Pumping duration: %.1f hours (%s to %s)\n', ...
        hours(pumping_end - pumping_start), datestr(pumping_start), datestr(pumping_end));
    
    if exist('pumping_progression', 'var')
        fprintf('\nPumping signal development:\n');
        fprintf('  Signal range: [%.1f, %.1f] nε\n', min(pumping_progression), max(pumping_progression));
        fprintf('  Average development: %.1f ± %.1f nε\n', mean(pumping_progression,'omitnan'), std(pumping_progression,'omitnan'));
        
        fprintf('\nZone-based pumping response:\n');
        fprintf('  Above pumping zone: %.1f nε\n', above_pump_pumping);
        fprintf('  Pumping zone: %.1f nε\n', pump_zone_pumping);
        fprintf('  Below pumping zone: %.1f nε\n', below_pump_pumping);
        
        fprintf('\nPumping signal quality:\n');
        fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_pumping(:)) - min(dstrain_pumping(:)));
        fprintf('  Data completeness: %.1f%% (%d/%d time points)\n', ...
            100*sum(pumping_mask)/length(Tdas), sum(pumping_mask), length(Tdas));
    end
end

% Recovery Analysis Summary
fprintf('\n=== RECOVERY ANALYSIS SUMMARY ===\n');

fprintf('\nOverall recovery statistics:\n');
fprintf('Recovery range: [%.1f, %.1f] nε\n', min(recovery_difference), max(recovery_difference));
fprintf('Average recovery change: %.1f ± %.1f nε\n', mean(recovery_difference,'omitnan'), std(recovery_difference,'omitnan'));

fprintf('\nZone-based recovery averages:\n');
fprintf('  Above pumping zone (90-450 ft): %.1f nε\n', above_pump_recovery);
fprintf('  Pumping zone (450-510 ft): %.1f nε\n', pump_zone_recovery);
fprintf('  Below pumping zone (510-665 ft): %.1f nε\n', below_pump_recovery);

fprintf('\nRecovery signal characteristics:\n');
fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_recovery(:)) - min(dstrain_recovery(:)));
fprintf('  Temporal extent: %.1f minutes\n', minutes(recovery_end - recovery_start));

% Check if we're seeing expected patterns
if pump_zone_recovery > above_pump_recovery && pump_zone_recovery > below_pump_recovery
    fprintf('  ✓ Maximum recovery in pumping zone (as expected)\n');
else
    fprintf('  ⚠ Recovery pattern differs from expected pumping zone response\n');
end

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Generated visualizations:\n');
fprintf('  - Figure 1: Full recovery heatmap\n');
fprintf('  - Figure 2: Recovery progression profiles\n');
fprintf('  - Figure 4: Focused recovery zone (430-530 ft)\n');
fprintf('  - Figure 5: Strain-rate traces during pumping test\n');
if exist('gr_data_full', 'var') && ~isempty(gr_data_full)
    fprintf('  - Figure 6: Full recovery with gamma ray overlay\n');
end
if exist('dstrain_pumping', 'var') && ~isempty(dstrain_pumping)
    fprintf('  - Figure 7: Full pumping heatmap\n');
    fprintf('  - Figure 8: Focused pumping zone (430-530 ft)\n');
    if exist('pumping_progression', 'var')
        fprintf('  - Figure 9: Pumping progression analysis\n');
    end
end
fprintf('Analysis focused on both pumping response and recovery patterns.\n'); 