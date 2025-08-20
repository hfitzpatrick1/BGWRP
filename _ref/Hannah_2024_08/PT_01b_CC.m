%% DAS Step Test & Recovery Analysis – PT-01b (Clean Signal Focus with Common Mode Removal)
% Clean visualization focused on exposing both step test pumping and recovery signal patterns
% Step test data from Oct 31, 2023
% Uses common mode removal techniques to enhance signal quality
% Well Screen: 350-400 ft

clear; clc; close all

%% 1. Load data
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

%% 2. Depth control (PT01b parameters)
C1 = 513; BOT = 1324; well_depth_ft = 665; water_table_depth_ft = 89;
dx_m = 0.25; dx_ft = dx_m*3.28084;

DAS_depth_ft = ((0:size(data,2)-1).*dx_m)*3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
scale        = well_depth_ft/raw_depth_ft(BOT);
final_depth_ft = raw_depth_ft*scale;

% Define pumping zone for analysis (PT01b well screening zone)
pump_zone_top = 350;    % ft - well screened zone
pump_zone_bot = 400;    % ft - well screened zone  
pump_zone_center = 375; % ft

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

%% 3. Time axis (PT01b timing)
Fs = 1;
T0 = datetime(2023,10,31,15,29,36,'TimeZone','UTC');  % PT01b file start
Tdas = T0 + seconds((0:size(data,1)-1));

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

%% 5. Integration and baseline (PT01b approach)
fprintf('\n--- Integration and Baseline ---\n');
intdata = cumtrapz(data_cleaned, 1);
idata_roi = intdata(:, roi);

% Use PT01b baseline approach: 120-s flat pre-pump pad
pump_on  = datetime(2023,10,31,15,30,0,'TimeZone','UTC');
idx_pre  = find(Tdas < pump_on);
pad_rows = 120;                                % 120 s @ 1 Hz
firstVec = idata_roi(idx_pre(end),:);
padBlock = repmat(firstVec, pad_rows, 1);
idata_roi = [padBlock ; idata_roi];            % prepend pad
baseline  = mean(padBlock,1,'omitnan');
dstrain   = idata_roi - baseline;
padTimes  = Tdas(1) - seconds(pad_rows:-1:1);  % row vector!
Tdas      = [padTimes  Tdas];                  % extend time axis

% Define recovery period for PT01b (pumps shut off at 19:30)
% PT01b pump schedule:
% 15:30 - 50 GPM, 16:30 - 80 GPM, 17:30 - 110 GPM, 18:30 - 148 GPM, 19:30 - 0 GPM (recovery)
recovery_start = datetime(2023,10,31,19,30,0,'TimeZone','UTC');  % Pumps shut off
recovery_end = datetime(2023,10,31,20,30,0,'TimeZone','UTC');

% Pumping period definition (for additional pumping analysis)
% PT01b step test pumping period
pumping_start = datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % First step begins
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
title('Aquifer Recovery Signal – PT-01b Step Test (Pumps Off 19:30)', 'FontSize', 14)
xlabel('Time (UTC)', 'FontSize', 12)
ylabel('Depth (ft)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid off
box on

%% 6b. Focused well screen analysis (350-400 ft)  
fprintf('\n--- Focused Well Screen Analysis ---\n');

% Extract pumping zone data plus 20 ft buffer above and below
pump_zone_buffer_top = pump_zone_top - 20;  % 330 ft
pump_zone_buffer_bot = pump_zone_bot + 20;  % 420 ft
pump_zone_mask = depth_roi >= pump_zone_buffer_top & depth_roi <= pump_zone_buffer_bot;
pump_zone_depths = depth_roi(pump_zone_mask);
pump_zone_data = dstrain_recovery(:, pump_zone_mask);

% Enhanced color scaling for pumping zone
pump_zone_lims = prctile(pump_zone_data(:), [5 95]);  % Tighter percentiles for more contrast

fprintf('Well screen depths: %.1f - %.1f ft (%d channels)\n', ...
    min(pump_zone_depths), max(pump_zone_depths), sum(pump_zone_mask));
fprintf('Well screen signal range: [%.1f, %.1f] nε\n', ...
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
        
        % Filter to pumping zone plus buffer (330-420 ft) for focused plot
        pump_zone_las_mask = las_depth >= 330 & las_depth <= 420;
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
    % 20 feet above pumping zone (330 ft)
    yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone')
    
    % 20 feet below pumping zone (420 ft)
    yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
    
    % Pumping zone boundaries (well screen)
    yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Top (350 ft)')
    yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Bot (400 ft)')
    
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
    yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Pump Zone')
    yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Pump Zone')
    yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Top (350 ft)')
    yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Bot (400 ft)')
    hold off
end

% Clean time axis and formatting
datetick('x','HH:MM','keeplimits')
title('Recovery Signal (330-420 ft)', 'FontSize', 12)
xlabel('Time (UTC)', 'FontSize', 12)

% Improve figure appearance
set(gca, 'FontSize', 11)
grid on
box on

% Add depth grid lines for better resolution
yticks(330:10:420)
set(gca, 'YMinorTick', 'on')

% Add overall title for the figure
if ~isempty(gr_data)
    sgtitle('PT-01b Recovery Signal with Gamma Ray Log (330-420 ft)', 'FontSize', 14)
else
    title('PT-01b Recovery Signal (330-420 ft)', 'FontSize', 14)
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
    xlim([45, 130])  % Set GR scale to 45-130 GAPI
    xlabel('GR (GAPI)', 'FontSize', 10)
    ylabel('Depth (ft)', 'FontSize', 10)
    title('Gamma Ray', 'FontSize', 11)
    grid on
    
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
    sgtitle('PT-01b Full Recovery Signal with Gamma Ray Log', 'FontSize', 14)
    
    fprintf('Added gamma ray overlay to recovery plots\n');
end

%% 6e. PUMPING ANALYSIS - Active Step Test Period
fprintf('\n--- STEP TEST PUMPING ANALYSIS ---\n');

% Filter to pumping period
pumping_mask = Tdas >= pumping_start & Tdas <= pumping_end;
Tdas_pumping = Tdas(pumping_mask);
dstrain_pumping = dstrain(pumping_mask,:);

fprintf('Step test period: %s to %s\n', datestr(pumping_start), datestr(pumping_end));
fprintf('Step test duration: %.1f hours\n', hours(pumping_end - pumping_start));
fprintf('Step test data size: [%d x %d]\n', size(dstrain_pumping));

% Check if we have pumping data
if isempty(dstrain_pumping)
    fprintf('⚠ Warning: No data found for estimated pumping period\n');
    fprintf('   Data time range: %s to %s\n', datestr(min(Tdas)), datestr(max(Tdas)));
    fprintf('   You may need to adjust pumping_start time\n');
else
    % Use optimal color limits for pumping signal
    pump_lims = prctile(dstrain_pumping(:),[1 99]);  % 1st and 99th percentiles for maximum contrast
    
    %% 6f. Full step test heatmap
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
        sgtitle('Full Step Test Signal with Gamma Ray Log – PT-01b', 'FontSize', 14)
        
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
        title('Aquifer Step Test Signal – PT-01b', 'FontSize', 14)
    end
    
    % Clean time axis
    datetick('x','HH:MM','keeplimits')
    xlabel('Time (UTC)', 'FontSize', 12)
    
    % Improve figure appearance
    set(gca, 'FontSize', 11)
    grid off
    box on
    
    %% 6g. Focused well screen step test analysis
    % Extract well screen data for focused analysis
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
        yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Well Screen')
        yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Well Screen')
        yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Top (450 ft)')
        yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Bot (510 ft)')
        hold off
        
        % Remove y-axis labels from heatmap since GR subplot has them
        set(gca, 'YTickLabel', [])
        
        % Add overall title for the figure
        sgtitle('Step Test Well Screen Signal with Gamma Ray Log (330-420 ft) – PT-01b', 'FontSize', 14)
        
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
        title('Step Test Signal (330-420 ft) – PT-01b', 'FontSize', 14)
        
        % Add zone markers
        hold on
        yline(pump_zone_buffer_top, 'r--', 'LineWidth', 2, 'Label', '20 ft Above Well Screen')
        yline(pump_zone_buffer_bot, 'r--', 'LineWidth', 2, 'Label', '20 ft Below Well Screen')
        yline(pump_zone_top, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Top (450 ft)')
        yline(pump_zone_bot, 'k-', 'LineWidth', 3, 'Label', 'Well Screen Bot (510 ft)')
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
    yticks(330:10:420)
    set(gca, 'YMinorTick', 'on')
    
    %% 6h. Step test progression analysis (Early vs Late pumping)
    % Define step test periods for comparison
    step_duration = pumping_end - pumping_start;
    early_step_end = pumping_start + step_duration/3;  % First third of step test
    late_step_start = pumping_end - step_duration/3;   % Last third of step test
    
    t_early_pumping = Tdas >= pumping_start & Tdas < early_step_end;
    t_late_pumping = Tdas >= late_step_start & Tdas <= pumping_end;
    
    if sum(t_early_pumping) > 0 && sum(t_late_pumping) > 0
        early_pumping_avg = mean(dstrain(t_early_pumping,:), 1, 'omitnan');
        late_pumping_avg = mean(dstrain(t_late_pumping,:), 1, 'omitnan');
        step_progression = late_pumping_avg - early_pumping_avg;
        
        % Step test progression comparison plot
        figure(9); clf
        subplot(1,2,1)
        plot(early_pumping_avg, depth_roi, 'g-', 'LineWidth', 2); hold on;
        plot(late_pumping_avg, depth_roi, 'm-', 'LineWidth', 2);
        set(gca,'YDir','reverse'), grid on
        xlabel('Average Δ-Strain (nε)', 'FontSize', 12)
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Early vs Late Step Test', 'FontSize', 13)
        legend('Early Steps (1st third)', 'Late Steps (last third)', 'Location', 'best')
        ylim([90 well_depth_ft])
        
        subplot(1,2,2)
        plot(step_progression, depth_roi, 'k-', 'LineWidth', 2)
        set(gca,'YDir','reverse'), grid on
        xlabel('Step Test Progression (nε)', 'FontSize', 12)
        ylabel('Depth (ft)', 'FontSize', 12)
        title('Step Test Signal Development', 'FontSize', 13)
        ylim([90 well_depth_ft])
        
        % Add zero reference line
        hold on
        xline(0, 'k--', 'LineWidth', 1)
        hold off
        
        sgtitle('Step Test Analysis – PT-01b', 'FontSize', 14)
        
        % Define zone masks for step test analysis
        above_pump = final_depth_ft >= 90 & final_depth_ft < pump_zone_top;
        pump_zone = final_depth_ft >= pump_zone_top & final_depth_ft <= pump_zone_bot;
        below_pump = final_depth_ft > pump_zone_bot & final_depth_ft <= well_depth_ft;
        
        above_pump_roi = above_pump(roi);
        pump_zone_roi = pump_zone(roi);
        below_pump_roi = below_pump(roi);
        
        % Zone-based step test analysis
        above_pump_pumping = mean(step_progression(above_pump_roi), 'omitnan');
        pump_zone_pumping = mean(step_progression(pump_zone_roi), 'omitnan');
        below_pump_pumping = mean(step_progression(below_pump_roi), 'omitnan');
        
        fprintf('\n--- Step Test Progression Analysis ---\n');
        fprintf('Early step test period: %s to %s\n', datestr(pumping_start), datestr(early_step_end));
        fprintf('Late step test period: %s to %s\n', datestr(late_step_start), datestr(pumping_end));
        
        fprintf('\nStep test signal development (late - early):\n');
        fprintf('  Above well screen: %.1f nε\n', above_pump_pumping);
        fprintf('  Well screen zone: %.1f nε\n', pump_zone_pumping);
        fprintf('  Below well screen: %.1f nε\n', below_pump_pumping);
        
        fprintf('\nStep test signal characteristics:\n');
        fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_pumping(:)) - min(dstrain_pumping(:)));
        fprintf('  Step test extent: %.1f hours\n', hours(pumping_end - pumping_start));
        
        % Check step test patterns
        if abs(pump_zone_pumping) > abs(above_pump_pumping) && abs(pump_zone_pumping) > abs(below_pump_pumping)
            fprintf('  ✓ Maximum step test response in well screen zone (as expected)\n');
        else
            fprintf('  ⚠ Step test pattern differs from expected well screen response\n');
        end
        
        fprintf('\nPT-01b Step Test Schedule:\n');
        fprintf('  15:30 - 50 GPM (%.1f hr)\n', hours(datetime(2023,10,31,16,30,0,'TimeZone','UTC') - pumping_start));
        fprintf('  16:30 - 80 GPM (%.1f hr)\n', hours(datetime(2023,10,31,17,30,0,'TimeZone','UTC') - datetime(2023,10,31,16,30,0,'TimeZone','UTC')));
        fprintf('  17:30 - 110 GPM (%.1f hr)\n', hours(datetime(2023,10,31,18,30,0,'TimeZone','UTC') - datetime(2023,10,31,17,30,0,'TimeZone','UTC')));
        fprintf('  18:30 - 148 GPM (%.1f hr)\n', hours(pumping_end - datetime(2023,10,31,18,30,0,'TimeZone','UTC')));
        fprintf('  19:30 - 0 GPM (recovery begins)\n');
        
    else
        fprintf('⚠ Warning: Insufficient data for step test progression analysis\n');
    end
end

%% 7. Recovery period comparison analysis (adapted for PT01a)
fprintf('\n--- Recovery Period Analysis ---\n');

% Define recovery periods for PT01a step test
t_early_recovery = Tdas >= datetime(2023,10,31,19,30,0,'TimeZone','UTC') & ...
                   Tdas <  datetime(2023,10,31,19,45,0,'TimeZone','UTC');
t_late_recovery = Tdas >= datetime(2023,10,31,20,15,0,'TimeZone','UTC') & ...
                  Tdas <  datetime(2023,10,31,20,30,0,'TimeZone','UTC');

early_recovery_avg = mean(dstrain(t_early_recovery,:), 1, 'omitnan');
late_recovery_avg = mean(dstrain(t_late_recovery,:), 1, 'omitnan');
recovery_difference = late_recovery_avg - early_recovery_avg;

fprintf('Early recovery period: 19:30-19:45 (%.1f minutes)\n', 15);
fprintf('Late recovery period: 20:15-20:30 (%.1f minutes)\n', 15);
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
legend('Early Recovery (19:30-19:45)', 'Late Recovery (20:15-20:30)', 'Location', 'best')
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

sgtitle('Recovery Analysis – PT-01b (with CM Removal)', 'FontSize', 14)

%% 9. Zone-based analysis (background calculations)
% Calculate zone statistics without heavy visualization (well screen 350-400 ft)
above_pump = final_depth_ft >= 90 & final_depth_ft < pump_zone_top;
pump_zone = final_depth_ft >= pump_zone_top & final_depth_ft <= pump_zone_bot;
below_pump = final_depth_ft > pump_zone_bot & final_depth_ft <= well_depth_ft;

above_pump_roi = above_pump(roi);
pump_zone_roi = pump_zone(roi);
below_pump_roi = below_pump(roi);

above_pump_recovery = mean(recovery_difference(above_pump_roi), 'omitnan');
pump_zone_recovery = mean(recovery_difference(pump_zone_roi), 'omitnan');
below_pump_recovery = mean(recovery_difference(below_pump_roi), 'omitnan');

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
xlim([datetime(2023,10,31,15,30,0,'TimeZone','UTC') ...
      datetime(2023,10,31,20,30,0,'TimeZone','UTC')])
title('Strain-Rate (CM Removed) – PT-01b Step-Test', 'FontSize', 14)

%% 11. Summary statistics
fprintf('\n--- ANALYSIS SUMMARY ---\n');

% Step Test Analysis Summary (if data available)
if exist('dstrain_pumping', 'var') && ~isempty(dstrain_pumping)
    fprintf('\n=== STEP TEST ANALYSIS SUMMARY ===\n');
    fprintf('Step test duration: %.1f hours (%s to %s)\n', ...
        hours(pumping_end - pumping_start), datestr(pumping_start), datestr(pumping_end));
    
    if exist('step_progression', 'var')
        fprintf('\nStep test signal development:\n');
        fprintf('  Signal range: [%.1f, %.1f] nε\n', min(step_progression), max(step_progression));
        fprintf('  Average development: %.1f ± %.1f nε\n', mean(step_progression,'omitnan'), std(step_progression,'omitnan'));
        
        fprintf('\nZone-based step test response:\n');
        fprintf('  Above well screen: %.1f nε\n', above_pump_pumping);
        fprintf('  Well screen zone: %.1f nε\n', pump_zone_pumping);
        fprintf('  Below well screen: %.1f nε\n', below_pump_pumping);
        
        fprintf('\nStep test signal quality:\n');
        fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_pumping(:)) - min(dstrain_pumping(:)));
        fprintf('  Data completeness: %.1f%% (%d/%d time points)\n', ...
            100*sum(pumping_mask)/length(Tdas), sum(pumping_mask), length(Tdas));
        
        fprintf('\nStep test schedule:\n');
        fprintf('  15:30 - 50 GPM (%.1f hr)\n', hours(datetime(2023,10,31,16,30,0,'TimeZone','UTC') - pumping_start));
        fprintf('  16:30 - 80 GPM (%.1f hr)\n', hours(datetime(2023,10,31,17,30,0,'TimeZone','UTC') - datetime(2023,10,31,16,30,0,'TimeZone','UTC')));
        fprintf('  17:30 - 110 GPM (%.1f hr)\n', hours(datetime(2023,10,31,18,30,0,'TimeZone','UTC') - datetime(2023,10,31,17,30,0,'TimeZone','UTC')));
        fprintf('  18:30 - 148 GPM (%.1f hr)\n', hours(pumping_end - datetime(2023,10,31,18,30,0,'TimeZone','UTC')));
        fprintf('  19:30 - 0 GPM (recovery begins)\n');
    end
end

% Recovery Analysis Summary
fprintf('\n=== RECOVERY ANALYSIS SUMMARY ===\n');

fprintf('\nOverall recovery statistics:\n');
fprintf('Recovery range: [%.1f, %.1f] nε\n', min(recovery_difference), max(recovery_difference));
fprintf('Average recovery change: %.1f ± %.1f nε\n', mean(recovery_difference,'omitnan'), std(recovery_difference,'omitnan'));

fprintf('\nZone-based recovery averages:\n');
fprintf('  Above well screen (90-350 ft): %.1f nε\n', above_pump_recovery);
fprintf('  Well screen zone (350-400 ft): %.1f nε\n', pump_zone_recovery);
fprintf('  Below well screen (400-665 ft): %.1f nε\n', below_pump_recovery);

fprintf('\nRecovery signal characteristics:\n');
fprintf('  Signal dynamic range: %.1f nε\n', max(dstrain_recovery(:)) - min(dstrain_recovery(:)));
fprintf('  Temporal extent: %.1f minutes\n', minutes(recovery_end - recovery_start));

% Check if we're seeing expected patterns
if pump_zone_recovery > above_pump_recovery && pump_zone_recovery > below_pump_recovery
    fprintf('  ✓ Maximum recovery in well screen zone (as expected)\n');
else
    fprintf('  ⚠ Recovery pattern differs from expected well screen response\n');
end

fprintf('\nCommon Mode Removal Effects:\n');
fprintf('  Applied temporal mean removal to %d channels\n', size(data, 2));
fprintf('  Original signal range: [%.2f, %.2f] nε/s\n', min(data(:)), max(data(:)));
fprintf('  Cleaned signal range: [%.2f, %.2f] nε/s\n', min(data_cleaned(:)), max(data_cleaned(:)));

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Generated visualizations:\n');
fprintf('  - Figure 1: Full recovery heatmap (90-665 ft)\n');
fprintf('  - Figure 2: Recovery comparison profiles\n');
fprintf('  - Figure 4: Well screen focused analysis (330-420 ft)\n');
fprintf('  - Figure 5: Strain-rate traces during step test\n');
if exist('gr_data_full', 'var') && ~isempty(gr_data_full)
    fprintf('  - Figure 6: Full recovery with gamma ray overlay\n');
end
if exist('dstrain_pumping', 'var') && ~isempty(dstrain_pumping)
    fprintf('  - Figure 7: Full step test heatmap\n');
    fprintf('  - Figure 8: Well screen step test analysis (330-420 ft)\n');
    if exist('step_progression', 'var')
        fprintf('  - Figure 9: Step test progression analysis\n');
    end
end
fprintf('Analysis focused on both step test response and recovery patterns.\n'); 