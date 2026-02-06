function combined_filtering_approach()
% COMBINED FILTERING: Common Mode Removal + 5-Second Moving Mean
% This combines the working 5-second moving mean with common mode removal

fprintf('=== COMBINED FILTERING APPROACH ===\n');

%% Load data
data_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01c_Recovery_short\_das\Dataset_PT01c_Recovery_short_1Hz.mat';
fprintf('Loading data: %s\n', data_file);
load(data_file);

% Check what variables are in the file
fprintf('Variables in file: %s\n', strjoin(fieldnames(load(data_file)), ', '));

% Load timing configuration
addpath('C:\Coding\BGWRP\data\_BATCH\_active\PT01c_Recovery_short\_das_timing');
timing_config = get_timing_PT01c_Recovery_short();

% Create proper time array
dt = 1.0; % 1 second sampling
time_array = timing_config.start + seconds(0:dt:(size(decdata,1)-1)*dt);

% Calculate depth array
C1 = 110; % Use C1=110 instead of timing_config.C1
MperChan = 0.263;
channels = 1:size(decdata, 2);
depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;

fprintf('Loaded data: [%d x %d]\n', size(decdata,1), size(decdata,2));
fprintf('Time range: %s to %s\n', time_array(1), time_array(end));
fprintf('Depth range: %.1f to %.1f ft\n', min(depth_ft), max(depth_ft));
fprintf('Original data range: [%.3f, %.3f] nm/s\n', min(decdata(:)), max(decdata(:)));

%% Define analysis window
analysis_start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
analysis_end = datetime(2023,10,24,19,19,00,00,'TimeZone','UTC');
analysis_mask = time_array >= analysis_start & time_array <= analysis_end;

data_analysis = decdata(analysis_mask, :);
time_analysis = time_array(analysis_mask);
depth_mask = depth_ft >= 200 & depth_ft <= 665;
depth_analysis = depth_ft(depth_mask);
data_analysis = data_analysis(:, depth_mask);

fprintf('Analysis window: %s to %s (%d time points)\n', time_analysis(1), time_analysis(end), length(time_analysis));
fprintf('Depth range: %.1f to %.1f ft (%d channels)\n', min(depth_analysis), max(depth_analysis), length(depth_analysis));

%% APPROACH 1: Subtraction-based Common Mode + 5-sec Moving Mean
fprintf('\n--- APPROACH 1: Subtraction Common Mode + 5-sec Moving Mean ---\n');

% Use only the last 100 ft (565-665 ft) for common mode calculation
cm_depth_mask = depth_analysis >= 565 & depth_analysis <= 665;
cm_data = data_analysis(:, cm_depth_mask);
fprintf('Using depths %.1f-%.1f ft (%d channels) for common mode calculation\n', ...
    min(depth_analysis(cm_depth_mask)), max(depth_analysis(cm_depth_mask)), sum(cm_depth_mask));

% Calculate common mode signal (depth-averaged for each time step from last 100 ft only)
common_mode = mean(cm_data, 2);

% Remove common mode by subtraction
data_cm_subtracted = data_analysis - common_mode;

% Apply 5-second moving mean
data_approach1 = movmean(data_cm_subtracted, 5, 1, 'omitnan');

fprintf('After CM subtraction: [%.3f, %.3f] nm/s\n', min(data_cm_subtracted(:)), max(data_cm_subtracted(:)));
fprintf('After 5-sec moving mean: [%.3f, %.3f] nm/s\n', min(data_approach1(:)), max(data_approach1(:)));

%% APPROACH 2: Division-based Common Mode (with epsilon) + 5-sec Moving Mean
fprintf('\n--- APPROACH 2: Division Common Mode + 5-sec Moving Mean ---\n');

% Find a quiet period for reference
quiet_start = datetime(2023,10,24,19,15,30,00,'TimeZone','UTC');
quiet_end = datetime(2023,10,24,19,16,00,00,'TimeZone','UTC');
quiet_mask = time_analysis >= quiet_start & time_analysis <= quiet_end;

if any(quiet_mask)
    ref_data = data_analysis(quiet_mask, :);
    % Use same depth range (565-665 ft) for division approach consistency
    ref_data_cm = ref_data(:, cm_depth_mask);
    ref_signal = mean(ref_data_cm, 2); % Average across depths (last 100 ft only)
    baseline_common_mode = mean(ref_signal); % Average across time
    
    fprintf('Reference window: %s to %s (%d points)\n', quiet_start, quiet_end, sum(quiet_mask));
    fprintf('Baseline common mode: %.6f nm/s\n', baseline_common_mode);
    
    % Apply division with epsilon to avoid extreme values
    epsilon = 0.1; % Larger epsilon to be more conservative
    data_cm_divided = data_analysis ./ (baseline_common_mode + epsilon);
    
    % Apply 5-second moving mean
    data_approach2 = movmean(data_cm_divided, 5, 1, 'omitnan');
    
    fprintf('After CM division: [%.3f, %.3f] nm/s\n', min(data_cm_divided(:)), max(data_cm_divided(:)));
    fprintf('After 5-sec moving mean: [%.3f, %.3f] nm/s\n', min(data_approach2(:)), max(data_approach2(:)));
else
    fprintf('Warning: No quiet period found, skipping division approach\n');
    data_approach2 = data_approach1; % Use subtraction approach as fallback
end

%% APPROACH 3: Just 5-second Moving Mean (baseline)
fprintf('\n--- APPROACH 3: 5-Second Moving Mean Only (Baseline) ---\n');
data_approach3 = movmean(data_analysis, 5, 1, 'omitnan');
fprintf('After 5-sec moving mean only: [%.3f, %.3f] nm/s\n', min(data_approach3(:)), max(data_approach3(:)));

%% Calculate strain for all approaches
fprintf('\n--- Calculating Strain from Strain Rate ---\n');
dt = 1.0; % 1 second sampling interval

% Original strain
strain_original_cumsum = cumsum(data_analysis * dt, 1);
strain_original = detrend(strain_original_cumsum, 1);

% Approach 1 strain
strain_approach1_cumsum = cumsum(data_approach1 * dt, 1);
strain_approach1 = detrend(strain_approach1_cumsum, 1);

% Approach 2 strain
strain_approach2_cumsum = cumsum(data_approach2 * dt, 1);
strain_approach2 = detrend(strain_approach2_cumsum, 1);

% Approach 3 strain
strain_approach3_cumsum = cumsum(data_approach3 * dt, 1);
strain_approach3 = detrend(strain_approach3_cumsum, 1);

fprintf('Original strain range: [%.3f, %.3f] nm/m\n', min(strain_original(:)), max(strain_original(:)));
fprintf('Approach 1 strain range: [%.3f, %.3f] nm/m\n', min(strain_approach1(:)), max(strain_approach1(:)));
fprintf('Approach 2 strain range: [%.3f, %.3f] nm/m\n', min(strain_approach2(:)), max(strain_approach2(:)));
fprintf('Approach 3 strain range: [%.3f, %.3f] nm/m\n', min(strain_approach3(:)), max(strain_approach3(:)));

%% Create individual comparison visualizations
fprintf('\n--- Creating Individual Comparison Visualizations ---\n');

% Figure 1: Original Data
figure('Position', [100, 100, 1500, 800]);
subplot(3,1,1);
imagesc(time_analysis, depth_analysis, data_analysis');
colormap(parula);
colorbar;
title('Original Strain Rate (nm/s)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([-0.15, 0.1]);

subplot(3,1,2);
imagesc(time_analysis, depth_analysis, strain_original');
colormap(parula);
colorbar;
title('Original Strain (nm/m)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([min(strain_original(:)), max(strain_original(:))]);

subplot(3,1,3);
% Find representative channel (middle of depth range)
rep_channel = round(length(depth_analysis)/2);
yyaxis left;
plot(time_analysis, data_analysis(:, rep_channel), 'b-', 'LineWidth', 1.5);
ylabel('Strain Rate (nm/s)');
yyaxis right;
plot(time_analysis, strain_original(:, rep_channel), 'r-', 'LineWidth', 1.5);
ylabel('Strain (nm/m)');
title(sprintf('Line Plots at %.1f ft depth', depth_analysis(rep_channel)));
xlabel('Time');
grid on;

% Figure 2: CM Subtraction + 5-sec Moving Mean
figure('Position', [200, 150, 1500, 800]);
subplot(3,1,1);
imagesc(time_analysis, depth_analysis, data_approach1');
colormap(parula);
colorbar;
title('CM Subtraction + 5-sec Moving Mean - Strain Rate (nm/s)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([-0.07, 0.07]);

subplot(3,1,2);
imagesc(time_analysis, depth_analysis, strain_approach1');
colormap(parula);
colorbar;
title('CM Subtraction + 5-sec Moving Mean - Strain (nm/m)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([-0.5, 0.5]);

subplot(3,1,3);
yyaxis left;
plot(time_analysis, data_approach1(:, rep_channel), 'b-', 'LineWidth', 1.5);
ylabel('Strain Rate (nm/s)');
yyaxis right;
plot(time_analysis, strain_approach1(:, rep_channel), 'r-', 'LineWidth', 1.5);
ylabel('Strain (nm/m)');
title(sprintf('Line Plots at %.1f ft depth', depth_analysis(rep_channel)));
xlabel('Time');
grid on;

% Figure 3: CM Division + 5-sec Moving Mean
figure('Position', [300, 200, 1500, 800]);
subplot(3,1,1);
imagesc(time_analysis, depth_analysis, data_approach2');
colormap(parula);
colorbar;
title('CM Division + 5-sec Moving Mean - Strain Rate (nm/s)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([-6, 0]);

subplot(3,1,2);
imagesc(time_analysis, depth_analysis, strain_approach2');
colormap(parula);
colorbar;
title('CM Division + 5-sec Moving Mean - Strain (nm/m)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([min(strain_approach2(:)), max(strain_approach2(:))]);

subplot(3,1,3);
yyaxis left;
plot(time_analysis, data_approach2(:, rep_channel), 'b-', 'LineWidth', 1.5);
ylabel('Strain Rate (nm/s)');
yyaxis right;
plot(time_analysis, strain_approach2(:, rep_channel), 'r-', 'LineWidth', 1.5);
ylabel('Strain (nm/m)');
title(sprintf('Line Plots at %.1f ft depth', depth_analysis(rep_channel)));
xlabel('Time');
grid on;

% Figure 4: 5-sec Moving Mean Only
figure('Position', [400, 250, 1500, 800]);
subplot(3,1,1);
imagesc(time_analysis, depth_analysis, data_approach3');
colormap(parula);
colorbar;
title('5-sec Moving Mean Only - Strain Rate (nm/s)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([-0.15, 0.1]);

subplot(3,1,2);
imagesc(time_analysis, depth_analysis, strain_approach3');
colormap(parula);
colorbar;
title('5-sec Moving Mean Only - Strain (nm/m)');
xlabel('Time'); ylabel('Depth (ft)');
caxis([min(strain_approach3(:)), max(strain_approach3(:))]);

subplot(3,1,3);
yyaxis left;
plot(time_analysis, data_approach3(:, rep_channel), 'b-', 'LineWidth', 1.5);
ylabel('Strain Rate (nm/s)');
yyaxis right;
plot(time_analysis, strain_approach3(:, rep_channel), 'r-', 'LineWidth', 1.5);
ylabel('Strain (nm/m)');
title(sprintf('Line Plots at %.1f ft depth', depth_analysis(rep_channel)));
xlabel('Time');
grid on;

%% Save results
fprintf('\n--- Saving Results ---\n');
save('PT01c_Recovery_COMBINED_filtering.mat', ...
     'data_analysis', 'data_approach1', 'data_approach2', 'data_approach3', ...
     'strain_original', 'strain_approach1', 'strain_approach2', 'strain_approach3', ...
     'time_analysis', 'depth_analysis', 'common_mode', 'baseline_common_mode');

fprintf('✓ Results saved to: PT01c_Recovery_COMBINED_filtering.mat\n');

fprintf('\n=== COMBINED FILTERING COMPLETE ===\n');
fprintf('Three approaches compared:\n');
fprintf('1. CM Subtraction + 5-sec Moving Mean\n');
fprintf('2. CM Division + 5-sec Moving Mean\n');
fprintf('3. 5-sec Moving Mean Only (baseline)\n');
fprintf('Compare the results to see which combination works best!\n');

end
