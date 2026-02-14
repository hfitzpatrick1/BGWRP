function plot_results = generate_plots(head_results, das_results, config)
%GENERATE_PLOTS Create analysis plots using simplified approach
%
% Creates essential plots based on PM07_PT01c_Simple.m approach
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data  
%   config       - Batch processor configuration
%
% Outputs:
%   plot_results - Structure containing plot metadata

% Initialize chart logging
init_chart_logging(config);
chart_logger('=== GENERATING ANALYSIS PLOTS (SIMPLIFIED) ===');

% Initialize results
plot_results = struct();
plot_results.figures_created = {};
plot_results.save_enabled = false;

% Configure chart saving
if isfield(config, 'save_charts') && config.save_charts
    plot_results.save_enabled = true;
    if isfield(config, 'chart_output_dir') && ~isempty(config.chart_output_dir)
        save_dir = config.chart_output_dir;
    else
        save_dir = fullfile(config.base_input, '_analysis_charts');
    end
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
        chart_logger('Created chart output directory: %s', save_dir);
    end
    plot_results.save_dir = save_dir;
    chart_logger('Chart saving enabled to: %s', save_dir);
else
    chart_logger('Chart saving disabled');
end

%% Get available test labels from results
test_labels = {};
if isfield(das_results, 'tests')
    test_labels = das_results.tests;
elseif ~isempty(fieldnames(das_results))
    test_labels = fieldnames(das_results);
    test_labels = test_labels(~strcmp(test_labels, 'tests') & ~strcmp(test_labels, 'timing'));
end

chart_logger('Creating plots for tests: %s', strjoin(test_labels, ', '));

%% Run correlation analysis if enabled
if isfield(config, 'correlation_analysis') && config.correlation_analysis
    chart_logger('Running strain rate vs head data correlation analysis...');
    try
        correlation_results = analyze_strain_head_correlation(das_results, head_results, das_results.timing, test_labels, config);
        plot_strain_head_correlation(correlation_results, config);
        chart_logger('✓ Correlation analysis completed');
        
        % Run linear regression analysis for each test
        chart_logger('Running linear regression: strain rate vs drawdown rate...');
        for j = 1:length(test_labels)
            test_label = test_labels{j};
            if isfield(das_results, test_label) && isfield(head_results, test_label)
                try
                    % Set up configuration for linear regression
                    lr_config.timing_correction_sec = 8;  % Optimized: 8 seconds backward shift (R=0.724, R^2=0.525)
                    lr_config.zone = 'z5';  % Default: Zone 5
                    lr_config.show_plots = true;
                    
                    % Add focused recovery window (same as ROI: 19:14-19:17)
                    lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                                                 datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];
                    
                    % Perform linear regression
                    lr_results = linear_regression_strain_drawdown(das_results, head_results, test_label, lr_config);
                    
                    % Store results in das_results for later use
                    das_results.(test_label).linear_regression = lr_results;
                    
                    chart_logger('✓ Linear regression for %s: R=%.3f, R^2=%.3f', test_label, lr_results.R, lr_results.R_squared);
                catch ME
                    chart_logger('✗ Linear regression failed for %s: %s', test_label, ME.message);
                    console_log('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Correlation analysis failed: %s', ME.message);
        console_log('Correlation analysis error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% Run linear regression analysis if enabled
if isfield(config, 'linear_regression') && config.linear_regression
    chart_logger('Running linear regression analysis...');
    try
        % Determine if we should run both strain rate and displacement rate regressions
        run_both = false;
        if isfield(config, 'lr_run_both_comparisons')
            run_both = config.lr_run_both_comparisons;
        end
        
        % Run linear regression for each test
        for j = 1:length(test_labels)
            test_label = test_labels{j};
            if isfield(das_results, test_label) && isfield(head_results, test_label)
                try
                    % Set up base configuration for linear regression
                    lr_config.timing_correction_sec = 8;  % Default: 8 seconds backward shift
                    if isfield(config, 'lr_timing_correction_sec')
                        lr_config.timing_correction_sec = config.lr_timing_correction_sec;
                    end
                    lr_config.zone = 'z5';  % Default: Zone 5
                    if isfield(config, 'lr_zone')
                        lr_config.zone = config.lr_zone;
                    end
                    % Add recovery window if specified
                    if isfield(config, 'lr_recovery_window')
                        lr_config.recovery_window = config.lr_recovery_window;
                    end
                    % Depth range analysis (optional)
                    if isfield(config, 'lr_depth_range_ft')
                        lr_config.depth_range_ft = config.lr_depth_range_ft;
                    end
                    if isfield(config, 'lr_depth_averaging_method')
                        lr_config.depth_averaging_method = config.lr_depth_averaging_method;
                    end
                    lr_config.show_plots = true;
                    
                    % Check if amplitude mode is requested
                    if isfield(config, 'lr_use_amplitude')
                        lr_config.use_amplitude = config.lr_use_amplitude;
                    end
                    
                    % Run strain rate regression (default)
                    lr_config.use_displacement_rate = false;
                    lr_results_strain = linear_regression_strain_drawdown(das_results, head_results, test_label, lr_config);
                    das_results.(test_label).linear_regression_strain = lr_results_strain;
                    chart_logger('✓ Strain rate regression for %s: R=%.3f, R^2=%.3f', test_label, lr_results_strain.R, lr_results_strain.R_squared);
                    
                    % Also run displacement rate regression if requested
                    if run_both
                        lr_config.use_displacement_rate = true;
                        lr_results_disp = linear_regression_strain_drawdown(das_results, head_results, test_label, lr_config);
                        das_results.(test_label).linear_regression_displacement = lr_results_disp;
                        chart_logger('✓ Displacement rate regression for %s: R=%.3f, R^2=%.3f', test_label, lr_results_disp.R, lr_results_disp.R_squared);
                        
                        % Print comparison
                        console_log('\n=== COMPARISON: Strain Rate vs Displacement Rate ===\n');
                        console_log('Test: %s\n', test_label);
                        console_log('Strain Rate Regression:       R=%.3f, R^2=%.3f, slope=%.2e (1/s)/(ft/s)\n', ...
                            lr_results_strain.R, lr_results_strain.R_squared, lr_results_strain.slope);
                        console_log('Displacement Rate Regression: R=%.3f, R^2=%.3f, slope=%.2e (nm/s)/(ft/s)\n', ...
                            lr_results_disp.R, lr_results_disp.R_squared, lr_results_disp.slope);
                        console_log('======================================================\n\n');
                    end
                    
                    % Store primary result (for backward compatibility)
                    das_results.(test_label).linear_regression = lr_results_strain;
                    
                catch ME
                    chart_logger('✗ Linear regression failed for %s: %s', test_label, ME.message);
                    console_log('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Linear regression analysis failed: %s', ME.message);
        console_log('Linear regression error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% Run amplitude-based storage calculation if enabled
if isfield(config, 'amplitude_storage') && config.amplitude_storage
    chart_logger('Running amplitude-based storage calculation...');
    try
        % Run amplitude storage for each test
        for j = 1:length(test_labels)
            test_label = test_labels{j};
            if isfield(das_results, test_label) && isfield(head_results, test_label)
                try
                    % Call the amplitude storage function
                    amplitude_results = calculate_amplitude_storage(das_results, head_results, test_label, config);
                    
                    % Store results
                    das_results.(test_label).amplitude_storage = amplitude_results;
                    
                    chart_logger('✓ Amplitude storage for %s: Ss = %.2e 1/m (depth = %.1f ft)', ...
                        test_label, amplitude_results.Ss, amplitude_results.depth_ft);
                    
                catch ME
                    chart_logger('✗ Amplitude storage failed for %s: %s', test_label, ME.message);
                    console_log('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Amplitude storage calculation failed: %s', ME.message);
        console_log('Amplitude storage error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% Run storage calculation from regression if enabled
if isfield(config, 'calculate_storage') && config.calculate_storage
    chart_logger('Running storage calculation from linear regression...');
    try
        % Import the storage calculation function
        calculate_storage_from_regression;
        chart_logger('✓ Storage calculation completed');
    catch ME
        chart_logger('✗ Storage calculation failed: %s', ME.message);
        console_log('Storage calculation error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% Run storage parameter analysis if enabled
if isfield(config, 'storage_analysis') && config.storage_analysis
    chart_logger('Running storage parameter analysis...');
    try
        storage_results = analyze_storage_parameters(das_results, head_results, das_results.timing, test_labels, config);
        plot_storage_analysis(storage_results, config);
        chart_logger('✓ Storage parameter analysis completed');
    catch ME
        chart_logger('✗ Storage parameter analysis failed: %s', ME.message);
        console_log('Storage analysis error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% Pre-calculate unified bounds if using related bounds
unified_bounds = struct();
if isfield(config, 'use_related_bounds') && config.use_related_bounds && length(test_labels) > 1
    chart_logger('Calculating unified bounds across %d related datasets...', length(test_labels));
    
    % Collect all DAS data for unified bounds calculation
    das_data_array = {};
    for j = 1:length(test_labels)
        test_label = test_labels{j};
        if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
            das_data_array{end+1} = das_results.(test_label);
        end
    end
    
    % Calculate unified bounds for each data type
    if ~isempty(das_data_array)
        unified_bounds.raw = get_plot_bounds(das_data_array, 'raw', config);
        unified_bounds.displacement = get_plot_bounds(das_data_array, 'displacement', config);
        unified_bounds.strain = get_plot_bounds(das_data_array, 'strain', config);
        chart_logger('✓ Unified bounds calculated');
    end
else
    chart_logger('Using individual bounds for each dataset');
end

%% Create simplified plots for each test (based on PM07_PT01c_Simple.m)
for i = 1:length(test_labels)
    test_label = test_labels{i};
    chart_logger('\n--- Creating plots for test %s ---', upper(test_label));
    
    % Skip if no DAS data
    if ~isfield(das_results, test_label) || isfield(das_results.(test_label), 'error')
        chart_logger('  Skipping %s: No DAS data available', test_label);
        continue;
    end
    
    das_data = das_results.(test_label);
    
    % Get analysis window for plotting
    analysis_start = das_data.analysis_time(1);
    analysis_end = das_data.analysis_time(end);
    
    % Get head data if available
    head_data = [];
    if isfield(head_results, test_label) && ~isfield(head_results.(test_label), 'error')
        head_data = head_results.(test_label);
        chart_logger('    DEBUG: Found head data for %s with zones: %s', test_label, strjoin(fieldnames(head_data.zones), ', '));
    else
        chart_logger('    DEBUG: No head data available for %s', test_label);
    end
    
    %% Figure 1: Raw Data Waterfall (standardized with time filtering)
    fig1_num = 100 + i*3 - 2;
    chart_logger('  Creating Figure %d: Raw Data Waterfall', fig1_num);
    
    % DEBUG: Check data availability and dimensions
    chart_logger('    DEBUG: das_data fields: %s', strjoin(fieldnames(das_data), ', '));
    if isfield(das_data, 'smoothed_data')
        chart_logger('    DEBUG: smoothed_data size: [%d x %d]', size(das_data.smoothed_data, 1), size(das_data.smoothed_data, 2));
        chart_logger('    DEBUG: smoothed_data range: [%.3f, %.3f]', min(das_data.smoothed_data(:)), max(das_data.smoothed_data(:)));
    else
        chart_logger('    ERROR: smoothed_data field missing!');
    end
    
    if isfield(das_data, 'time_array')
        chart_logger('    DEBUG: time_array size: %d elements', length(das_data.time_array));
        chart_logger('    DEBUG: time_array range: %s to %s', das_data.time_array(1), das_data.time_array(end));
    else
        chart_logger('    ERROR: time_array field missing!');
    end
    
    if isfield(das_data, 'depth_ft')
        chart_logger('    DEBUG: depth_ft size: %d elements', length(das_data.depth_ft));
        chart_logger('    DEBUG: depth_ft range: [%.1f, %.1f] ft', min(das_data.depth_ft), max(das_data.depth_ft));
    else
        chart_logger('    ERROR: depth_ft field missing!');
    end
    
    figure(fig1_num);
    set(fig1_num, 'Visible', 'on');
    clf;
    
    % Check if required data exists before plotting
    if ~isfield(das_data, 'smoothed_data') || ~isfield(das_data, 'time_array') || ~isfield(das_data, 'depth_ft')
        chart_logger('    ERROR: Missing required data fields for waterfall plot!');
        text(0.5, 0.5, 'Missing Data Fields', 'HorizontalAlignment', 'center');
        return;
    end
    
    % Filter data to analysis window BEFORE plotting
    % Apply waterfall time shift to align DAS waterfall with head data
    % Per-dataset waterfall time shift to align DAS waterfall with head data
    % PT-01c needs -10s, PT-01b may need different value
    if contains(test_name, 'PT01c', 'IgnoreCase', true)
        waterfall_shift_sec = -10;  % PT-01c: shift left 10 seconds
    else
        waterfall_shift_sec = -15;  % Default: shift left 15 seconds
    end
    % Grab extra data to compensate for the shift so the plot fills the full window
    analysis_mask_fig101 = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end - seconds(waterfall_shift_sec);
    filtered_time = das_data.time_array(analysis_mask_fig101) + seconds(waterfall_shift_sec);
    filtered_data = das_data.smoothed_data(analysis_mask_fig101, :);
    
    % Downsample for plotting if data is high-resolution (>2000 time points)
    % Keeps analysis at full resolution, only reduces plot rendering load
    plot_time = filtered_time;
    plot_data = filtered_data;
    if length(filtered_time) > 2000
        ds_factor = ceil(length(filtered_time) / 2000);
        plot_time = filtered_time(1:ds_factor:end);
        plot_data = filtered_data(1:ds_factor:end, :);
        chart_logger('    Downsampled for plotting: %d -> %d time points (factor %dx)', length(filtered_time), length(plot_time), ds_factor);
    end
    
    % Fix bad DAS channels (display only) - replace outliers with neighbor average
    plot_data = fix_bad_channels(plot_data);
    
    % Spatial smoothing to reduce horizontal banding (Figure 101)
    if contains(test_label, 'PT01b', 'IgnoreCase', true)
        % PT01b: blend shallow artifacts first, then spatial smooth
        shallow_mask_101 = das_data.depth_ft < 262;
        clean_band_101 = das_data.depth_ft >= 262 & das_data.depth_ft <= 330;
        bg_values_101 = mean(plot_data(:, clean_band_101), 2, 'omitnan');
        plot_data(:, shallow_mask_101) = repmat(bg_values_101, 1, sum(shallow_mask_101));
        plot_data = movmean(plot_data, 40, 2, 'omitnan');
        chart_logger('    Figure 101 PT01b: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask_101));
    elseif contains(test_label, 'PT01a', 'IgnoreCase', true)
        % PT01a: blend shallow artifacts first, then spatial smooth
        shallow_mask_101 = das_data.depth_ft < 262;
        clean_band_101 = das_data.depth_ft >= 262 & das_data.depth_ft <= 350;
        bg_values_101 = mean(plot_data(:, clean_band_101), 2, 'omitnan');
        plot_data(:, shallow_mask_101) = repmat(bg_values_101, 1, sum(shallow_mask_101));
        plot_data = movmean(plot_data, 40, 2, 'omitnan');
        chart_logger('    Figure 101 PT01a: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask_101));
    elseif contains(test_label, 'PT01c', 'IgnoreCase', true)
        % PT01c: blend shallow artifacts first, then spatial smooth
        shallow_mask_101 = das_data.depth_ft < 256;
        clean_band_101 = das_data.depth_ft >= 310 & das_data.depth_ft <= 380;
        bg_values_101 = mean(plot_data(:, clean_band_101), 2, 'omitnan');
        plot_data(:, shallow_mask_101) = repmat(bg_values_101, 1, sum(shallow_mask_101));
        plot_data = movmean(plot_data, 40, 2, 'omitnan');
        chart_logger('    Figure 101 PT01c: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask_101));
    end
    
    % Convert depth from feet to meters
    depth_m = das_data.depth_ft * 0.3048;
    
    % Apply configurable plotting method to test pixelation sources
    apply_plot_config(plot_time, depth_m, plot_data', config, 'waterfall');
    
    % Overlay head data if available
    if ~isempty(head_data) && isfield(head_data, 'zones')
        hold on;
        zone_names = fieldnames(head_data.zones);
        for z = 1:length(zone_names)
            zone_data = head_data.zones.(zone_names{z});
            if isfield(zone_data, 'Depthft') && isfield(zone_data, 'avg_recovery_rate') && ~isnan(zone_data.avg_recovery_rate)
                % Plot head data as colored markers
                depth_ft = zone_data.Depthft;
                recovery_rate = zone_data.avg_recovery_rate * 1000; % Convert to similar scale
                scatter(das_data.time_array(end-50), depth_ft, 100, recovery_rate, 'filled', 'MarkerEdgeColor', 'black');
                % Add label
                text(das_data.time_array(end-40), depth_ft, sprintf('%.1e', zone_data.avg_recovery_rate), ...
                     'FontSize', 8, 'Color', 'white', 'HorizontalAlignment', 'left');
            end
        end
        hold off;
    end
    
    % Set color bounds for Figure 101 waterfall plot
    % Check actual data range first
    actual_min = min(das_data.smoothed_data(:));
    actual_max = max(das_data.smoothed_data(:));
    chart_logger('    Figure 101: Actual data range: [%.3f, %.3f] nm/s', actual_min, actual_max);
    chart_logger('    Figure 101: Advisor''s range: [-0.25, 0.15] nm/s');
    
    % Colorbar bounds from config (per-dataset)
    raw_bounds = get_plot_bounds(das_data, 'raw', config, test_label);
    clim(raw_bounds);
    chart_logger('    Figure 101: Colorbar bounds: [%.2f, %.2f] nm/s', raw_bounds(1), raw_bounds(2));
    
    % Warn if data is outside bounds
    if actual_min < raw_bounds(1) || actual_max > raw_bounds(2)
        chart_logger('    ⚠ WARNING: Data extends beyond colorbar bounds!');
        chart_logger('      Data: [%.3f, %.3f], Bounds: [%.3f, %.3f]', actual_min, actual_max, raw_bounds(1), raw_bounds(2));
    end
    
    % Colormap is set by apply_plot_config, but ensure consistency for colorbar
    if isfield(config, 'colormap_name') && isfield(config, 'colormap_resolution')
        if config.colormap_resolution == 256
            colormap(config.colormap_name);
        else
            colormap(feval(config.colormap_name, config.colormap_resolution));
        end
    else
        colormap('jet'); % Fallback
    end
    c1 = colorbar;
    c1.Location = "northoutside";
    c1.Ruler.TickLabelFormat = '%g nm/s';
    grid on; 
    set(gca,'layer','top');
    ylabel('Depth (m)');
    axis ij;
    % Apply configurable depth axis bounds and convert to meters
    depth_bounds = get_plot_bounds([], 'depth_axis', config, test_label);
    depth_bounds_m = depth_bounds * 0.3048;
    ylim(depth_bounds_m);
    chart_logger('    Applied depth axis bounds: [%.0f, %.0f] m', depth_bounds_m(1), depth_bounds_m(2));
    
    % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
    
    xlabel('Date Time UTC');
    title(sprintf('Raw Data - Test %s', upper(test_label)));
    text(-0.12, 0.95, '(a)', 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_raw_data.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    
    %% Figure 2: Displacement Rate (from simple script Figure 2)
    fig2_num = 100 + i*3 - 1;
    chart_logger('  Creating Figure %d: Displacement Rate', fig2_num);
    figure(fig2_num);
    set(fig2_num, 'Visible', 'on');
    clf;
    
    subplot(3,1,1);
    % Apply configurable plotting method to test pixelation sources
    % For displacement rate, use the analysis window data only
    % Grab extra data to compensate for the shift so the plot fills the full window
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end - seconds(waterfall_shift_sec);
    analysis_smoothed_data = das_data.smoothed_data(analysis_mask, :);
    analysis_time_array = das_data.time_array(analysis_mask) + seconds(waterfall_shift_sec);
    % Downsample for plotting if high-resolution
    plot_time_102 = analysis_time_array;
    plot_data_102 = analysis_smoothed_data;
    if length(analysis_time_array) > 2000
        ds_factor = ceil(length(analysis_time_array) / 2000);
        plot_time_102 = analysis_time_array(1:ds_factor:end);
        plot_data_102 = analysis_smoothed_data(1:ds_factor:end, :);
        chart_logger('    Downsampled Fig 102 waterfall: %d -> %d points', length(analysis_time_array), length(plot_time_102));
    end
    
    % Fix bad DAS channels (display only)
    plot_data_102 = fix_bad_channels(plot_data_102);
    
    % Spatial smoothing to reduce horizontal banding (Figure 102)
    if contains(test_label, 'PT01b', 'IgnoreCase', true)
        % PT01b: blend shallow artifacts first, then spatial smooth
        shallow_mask = das_data.depth_ft < 262;
        clean_band = das_data.depth_ft >= 262 & das_data.depth_ft <= 330;
        bg_values = mean(plot_data_102(:, clean_band), 2, 'omitnan');
        plot_data_102(:, shallow_mask) = repmat(bg_values, 1, sum(shallow_mask));
        plot_data_102 = movmean(plot_data_102, 40, 2, 'omitnan');
        chart_logger('    Figure 102 PT01b: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask));
    elseif contains(test_label, 'PT01a', 'IgnoreCase', true)
        % PT01a: blend shallow artifacts first, then spatial smooth
        shallow_mask = das_data.depth_ft < 262;
        clean_band = das_data.depth_ft >= 262 & das_data.depth_ft <= 350;
        bg_values = mean(plot_data_102(:, clean_band), 2, 'omitnan');
        plot_data_102(:, shallow_mask) = repmat(bg_values, 1, sum(shallow_mask));
        plot_data_102 = movmean(plot_data_102, 40, 2, 'omitnan');
        chart_logger('    Figure 102 PT01a: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask));
    elseif contains(test_label, 'PT01c', 'IgnoreCase', true)
        % PT01c: blend shallow artifacts first, then spatial smooth
        shallow_mask = das_data.depth_ft < 256;
        clean_band = das_data.depth_ft >= 310 & das_data.depth_ft <= 380;
        bg_values = mean(plot_data_102(:, clean_band), 2, 'omitnan');
        plot_data_102(:, shallow_mask) = repmat(bg_values, 1, sum(shallow_mask));
        plot_data_102 = movmean(plot_data_102, 40, 2, 'omitnan');
        chart_logger('    Figure 102 PT01c: Blended %d shallow channels + 40-ch spatial smoothing', sum(shallow_mask));
    end
    
    % Convert depth from feet to meters
    depth_m = das_data.depth_ft * 0.3048;
    apply_plot_config(plot_time_102, depth_m, plot_data_102', config, 'waterfall');
    
    % Colorbar bounds from config (per-dataset, matches Figure 101)
    disp_bounds = get_plot_bounds(das_data, 'displacement', config, test_label);
    set(gca, 'clim', disp_bounds);
    chart_logger('    Figure 102 subplot 1: Colorbar bounds: [%.2f, %.2f] nm/s', disp_bounds(1), disp_bounds(2));
    
    % Colormap is set by apply_plot_config, but ensure consistency for colorbar
    if isfield(config, 'colormap_name') && isfield(config, 'colormap_resolution')
        if config.colormap_resolution == 256
            colormap(config.colormap_name);
        else
            colormap(feval(config.colormap_name, config.colormap_resolution));
        end
    else
        colormap('jet'); % Fallback
    end
    c7 = colorbar; 
    c7.Location = "northoutside";
    c7.Ruler.TickLabelFormat = '%g nm/s';
    grid on; 
    set(gca,'layer','top');
    ylabel('Depth (m)');
    axis ij;
    % Apply configurable depth axis bounds and convert to meters
    depth_bounds = get_plot_bounds([], 'depth_axis', config, test_label);
    depth_bounds_m = depth_bounds * 0.3048;
    ylim(depth_bounds_m);
    chart_logger('    Applied depth axis bounds: [%.0f, %.0f] m', depth_bounds_m(1), depth_bounds_m(2));
    
    % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
    
    % Add screened interval label (per-dataset)
    if contains(test_label, 'PT01c', 'IgnoreCase', true)
        screened_top_m = 260 * 0.3048;  % 79.25 m (PT01c)
        screened_bot_m = 310 * 0.3048;  % 94.49 m
    elseif contains(test_label, 'PT01b', 'IgnoreCase', true)
        screened_top_m = 350 * 0.3048;  % 106.68 m (PT01b)
        screened_bot_m = 400 * 0.3048;  % 121.92 m
    else
        screened_top_m = 450 * 0.3048;  % 137.16 m (PT01a/default)
        screened_bot_m = 510 * 0.3048;  % 155.45 m
    end
    hold on;
    yline(screened_top_m, '--k', 'LineWidth', 1.5);
    yline(screened_bot_m, '--k', 'LineWidth', 1.5);
    % Place label at the midpoint of the screened interval, near the right edge
    xl = xlim;
    text(xl(2), mean([screened_top_m, screened_bot_m]), ...
        sprintf('  Screened Interval\n  (%.0f–%.0f m)', screened_top_m, screened_bot_m), ...
        'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
    hold off;
    
    xlabel('Date Time UTC');
    title(sprintf('DAS Displacement Rate - Test %s', strrep(upper(test_label), '_', ' ')));
    text(-0.12, 0.95, '(a)', 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    
    % Pre-compute extended DAS displacement rate for subplots 2 & 3
    % Apply dataset-specific DAS time shift to align with head data
    das_plot_shift = -13;  % No shift for Figure 102 (shift only applied in regression figure)
    ext_mask = das_data.time_array >= analysis_start - seconds(abs(das_plot_shift) + 15) & das_data.time_array <= analysis_end + seconds(abs(das_plot_shift) + 15);
    plot_das_time_ext = das_data.time_array(ext_mask) + seconds(das_plot_shift);
    % For PT01b: pick the most responsive channel in the screened interval
    if contains(test_label, 'PT01b', 'IgnoreCase', true)
        screen_ch_mask = das_data.depth_ft >= 350 & das_data.depth_ft <= 400;
        screen_data = das_data.smoothed_data(ext_mask, screen_ch_mask);
        ch_variance = var(screen_data, 0, 1, 'omitnan');
        [~, best_ch_local] = max(ch_variance);
        screen_indices = find(screen_ch_mask);
        best_ch_idx = screen_indices(best_ch_local);
        plot_das_rate_ext = das_data.smoothed_data(ext_mask, best_ch_idx);
        chart_logger('    PT01b: Using most responsive channel at %.1f ft (idx %d, variance=%.2e)', das_data.depth_ft(best_ch_idx), best_ch_idx, ch_variance(best_ch_local));
    else
        plot_das_rate_ext = das_data.smoothed_data(ext_mask, das_data.pumping_zone.channel_idx);
    end
    
    subplot(3,1,2);
    if ~isempty(head_data)
        % Plot monitoring well data (z2, z3, z4, z5) - exclude pw for separate subplot
        zone_names = fieldnames(head_data.zones);
        chart_logger('    DEBUG DISPLACEMENT: Found %d zones: %s', length(zone_names), strjoin(zone_names, ', '));
        if ~isempty(zone_names)
            % Get zones to plot based on configuration, but exclude pw for this subplot
            zones_to_plot = get_zones_to_plot(test_label, zone_names, head_data, config);
            monitoring_zones = zones_to_plot(~strcmp(zones_to_plot, 'pw'));  % Exclude pw
            
            if ~isempty(monitoring_zones)
                % Get display mode
                display_mode = get_head_display_mode(test_label, config);
                
                if strcmp(display_mode, 'average')
                    % Average multiple zones into single line
                    averaged_data = average_zone_data(monitoring_zones, head_data);
                    if ~isempty(averaged_data)
                        yyaxis left;
                        % Convert head levels to drawdown rate for better comparison with displacement rate
                        [drawdown_rate_ftmin, rate_time] = calculate_drawdown_rate(averaged_data.Date, averaged_data.Drawdownft, 'ft_per_min');
                        % Convert from ft/min to m/s: 1 ft/min = 0.3048/60 m/s = 0.00508 m/s
                        drawdown_rate = drawdown_rate_ftmin * 0.00508;
                        plot(rate_time, drawdown_rate, 'DisplayName', 'Drawdown Rate (avg)');
                        if contains(test_label, 'PT01a', 'IgnoreCase', true)
                            xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
                        else
                            % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                        end
                        xlabel('Date Time UTC');
                        ylabel('Drawdown Rate (m/s)');
                        
                        yyaxis right;
                        plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
                        ylabel('Displacement Rate (nm/s)');
                        % Set fixed bounds for Figure 102 subplot 2
                        % ylim auto-scales for different data resolutions
                        legend('show', 'Location', 'best');
                        chart_logger('    Plotted averaged drawdown rate from %d monitoring zones', length(monitoring_zones));
                        chart_logger('    Figure 102 subplot 2: Fixed displacement rate y-axis bounds: [0.34, 0.37] nm/s');
                    end
                else
                    % Plot multiple monitoring zones (excluding pw)
                    yyaxis left;
                    hold on;
                    % Define consistent colors for zones z2, z3, z4, z5 across all datasets
                    zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5', 'pw'}, ...
                        {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880], [0.0000 1.0000 1.0000]});
                    
                    for z_idx = 1:length(monitoring_zones)
                        zone_name = monitoring_zones{z_idx};
                        zone_data = head_data.zones.(zone_name);
                        if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data) && ...
                           isfield(zone_data.recovery_data, 'Date') && length(zone_data.recovery_data.Date) > 1
                            % Use consistent color and solid line style
                            if zone_colors.isKey(zone_name)
                                zone_color = zone_colors(zone_name);
                            else
                                zone_color = [0 0 0];
                            end
                            % Convert head levels to drawdown rate for better comparison with displacement rate
                            [drawdown_rate_ftmin, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft_per_min');
                            % Convert from ft/min to m/s: 1 ft/min = 0.3048/60 m/s = 0.00508 m/s
                            drawdown_rate = drawdown_rate_ftmin * 0.00508;
                            plot(rate_time, drawdown_rate, ...
                                'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.0, ...
                                'DisplayName', sprintf('Drawdown Rate %s', zone_name));
                        end
                    end
                    hold off;
                    if strcmpi(test_label, 'PT01a_Recovery_short')
                        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
                    else
                        % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                    end
                    xlabel('Date Time UTC');
                    ylabel('Drawdown Rate (m/s)');
                    if length(monitoring_zones) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
                    ylabel('Displacement Rate (nm/s)');
                    % Set fixed bounds for Figure 102 subplot 2
                    % ylim auto-scales for different data resolutions
                    legend('show', 'Location', 'best');
                    chart_logger('    Plotted monitoring well drawdown rate data from zones: %s', strjoin(monitoring_zones, ', '));
                end
            else
                % No valid head data, just plot DAS
                plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
                if strcmpi(test_label, 'PT01a_Recovery_short')
                    xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
                else
                    % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                end
                ylabel('Displacement Rate (nm/s)');
                xlabel('Date Time UTC');
                % ylim auto-scales for different data resolutions
            end
        else
            % No head data, just plot DAS
            plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
            % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
            ylabel('Displacement Rate (nm/s)');
            xlabel('Date Time UTC');
            % ylim auto-scales for different data resolutions
        end
    else
        % No head data, just plot DAS
        plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
        % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
        ylabel('Displacement Rate (nm/s)');
        xlabel('Date Time UTC');
            % ylim auto-scales for different data resolutions
    end
    title('Drawdown Rate & Displacement Rate at PM-07');
    text(-0.12, 0.95, '(b)', 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    grid on;
    
    % Third subplot: Pumping Well (pw) data
    subplot(3,1,3);
    if ~isempty(head_data) && isfield(head_data.zones, 'pw')
        pw_data = head_data.zones.pw;
        if isfield(pw_data, 'recovery_data') && ~isempty(pw_data.recovery_data) && ...
           isfield(pw_data.recovery_data, 'Date') && length(pw_data.recovery_data.Date) > 1
            
            yyaxis left;
            % Convert head levels to drawdown rate for better comparison with displacement rate
            [drawdown_rate_ftmin, rate_time] = calculate_drawdown_rate(pw_data.recovery_data.Date, pw_data.recovery_data.Drawdownft, 'ft_per_min');
            % Convert from ft/min to m/s: 1 ft/min = 0.3048/60 m/s = 0.00508 m/s
            drawdown_rate = drawdown_rate_ftmin * 0.00508;
            % Flip sign for PT01b (recovery appears inverted)
            if contains(test_label, 'PT01b', 'IgnoreCase', true)
                drawdown_rate = -drawdown_rate;
            end
            % Determine well name for label
            if contains(test_label, 'PT01a', 'IgnoreCase', true)
                pw_label = 'PT-01a';
            elseif contains(test_label, 'PT01b', 'IgnoreCase', true)
                pw_label = 'PT-01b';
            elseif contains(test_label, 'PT01c', 'IgnoreCase', true)
                pw_label = 'PT-01c';
            else
                pw_label = 'PW';
            end
            plot(rate_time, drawdown_rate, 'Color', [0.0000 1.0000 1.0000], 'LineStyle', '-', 'LineWidth', 2.0, 'DisplayName', sprintf('Drawdown Rate %s', pw_label));
            if strcmpi(test_label, 'PT01a_Recovery_short')
                xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
            else
                % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
            end
            xlabel('Date Time UTC');
            ylabel('Drawdown Rate (m/s)');
            
            yyaxis right;
            plot(plot_das_time_ext, plot_das_rate_ext, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'Displacement Rate PM-07 z1');
            ylabel('Displacement Rate (nm/s)');
            
            % ylim auto-scales for subplot 3 to match data resolution
            
            legend('show', 'Location', 'best');
            title(sprintf('Drawdown Rate at %s & Displacement Rate at PM-07', pw_label));
            text(-0.12, 0.95, '(c)', 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
            grid on;
            chart_logger('    Plotted pumping well (pw) drawdown rate data');
        else
            text(0.5, 0.5, 'No valid pumping well recovery data', 'HorizontalAlignment', 'center');
            title('Pumping Well (pw) - No Data');
        end
    else
        text(0.5, 0.5, 'No pumping well data available', 'HorizontalAlignment', 'center');
        title('Pumping Well (pw) - No Data');
    end
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_displacement_rate.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    
    %% Figure 3: Strain (integrated data) - DISABLED for thesis
    % To re-enable, uncomment this block through the saveas call below.
    if false  % Disabled: strain waterfall + head overlay not needed for thesis
    fig3_num = 100 + i*3;
    chart_logger('  Creating Figure %d: Strain', fig3_num);
    figure(fig3_num);
    set(fig3_num, 'Visible', 'on');
    clf;
    
    % Calculate integrated data using absolute time-based integration
    % Use a small buffer (1 minute) before analysis window for baseline
    % This avoids loading the entire dataset into memory for large (100Hz) data
    integration_buffer = minutes(1);
    integration_reference_time = analysis_start - integration_buffer;
    
    % Find the integration start and end indices
    integration_start_idx = find(das_data.time_array >= integration_reference_time, 1);
    analysis_end_idx = find(das_data.time_array <= analysis_end, 1, 'last');
    
    if isempty(integration_start_idx)
        integration_start_idx = 1;
        chart_logger('    WARNING: Using dataset start for integration');
    end
    if isempty(analysis_end_idx) || das_data.time_array(end) < analysis_start
        error('Analysis window is outside dataset bounds');
    end
    
    chart_logger('    Integration window: indices %d to %d (%d samples)', integration_start_idx, analysis_end_idx, analysis_end_idx - integration_start_idx + 1);
    
    % Only extract the needed slice (saves memory for 100Hz data)
    subdata1Hz = das_data.smoothed_data(integration_start_idx:analysis_end_idx, :);
    iTdas = das_data.time_array(integration_start_idx:analysis_end_idx);
    
    intdata = cumtrapz(subdata1Hz, 1);
    clear subdata1Hz;  % Free memory immediately
    
    % Detrend integrated data (in-place to save memory)
    for nn = 1:size(intdata, 2)
        intdata(:, nn) = detrend(intdata(:, nn), 2);
    end
    
    subplot(3,1,1);
    % Filter to analysis window for plotting
    strain_mask_fig103 = iTdas >= analysis_start & iTdas <= analysis_end;
    filtered_time_strain = iTdas(strain_mask_fig103);
    filtered_strain_data = intdata(strain_mask_fig103, :);
    
    % Downsample for plotting if high-resolution
    plot_time_103 = filtered_time_strain;
    plot_strain_103 = filtered_strain_data;
    if length(filtered_time_strain) > 2000
        ds_factor = ceil(length(filtered_time_strain) / 2000);
        plot_time_103 = filtered_time_strain(1:ds_factor:end);
        plot_strain_103 = filtered_strain_data(1:ds_factor:end, :);
        chart_logger('    Downsampled Fig 103 waterfall: %d -> %d points', length(filtered_time_strain), length(plot_time_103));
    end
    
    % Apply configurable plotting method to test pixelation sources
    apply_plot_config(plot_time_103, das_data.depth_ft, plot_strain_103'/10, config, 'waterfall');
    
    % Set strain bounds using actual plotted data (intdata/10, already detrended)
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'strain')
        % Use pre-calculated unified bounds
        strain_bounds = unified_bounds.strain;
        set(gca, 'clim', strain_bounds);
        chart_logger('    Unified strain bounds: [%.6f, %.6f] nm/m', strain_bounds(1), strain_bounds(2));
    else
        % Calculate individual bounds from actual plotted strain data
        if isfield(config, 'dynamic_bounds') && config.dynamic_bounds
            % Focus on pumping zone for strain bounds
            zone_mask = das_data.depth_ft >= das_data.pumping_zone.min_ft & das_data.depth_ft <= das_data.pumping_zone.max_ft;
            strain_data = intdata(:, zone_mask) / 10;  % Same as plotted data
            
            % Get bounds mode from config
            if isfield(config, 'dynamic_bounds_mode')
                mode = config.dynamic_bounds_mode;
            else
                mode = 'percentile';
            end
            
            strain_bounds = calculate_dynamic_bounds(strain_data, mode, 'Percentiles', [2, 98]);
            
            % Ensure reasonable bounds (strain is usually negative)
            if strain_bounds(2) - strain_bounds(1) < 0.01  % Very small range
                strain_center = mean(strain_bounds);
                strain_bounds = [strain_center - 0.1, strain_center + 0.1];
            end
            
            set(gca, 'clim', strain_bounds);
            chart_logger('    Individual strain bounds: [%.6f, %.6f] nm/m', strain_bounds(1), strain_bounds(2));
        else
            % Use manual bounds configuration via get_plot_bounds
            strain_bounds = get_plot_bounds(das_data, 'strain', config, test_label);
            set(gca, 'clim', strain_bounds);
            chart_logger('    Manual strain bounds: [%.3f, %.3f] nm/m', strain_bounds(1), strain_bounds(2));
        end
    end
    
    % Colormap is set by apply_plot_config, but ensure consistency for colorbar
    if isfield(config, 'colormap_name') && isfield(config, 'colormap_resolution')
        if config.colormap_resolution == 256
            colormap(config.colormap_name);
        else
            colormap(feval(config.colormap_name, config.colormap_resolution));
        end
    else
        colormap('jet'); % Fallback
    end
    c7 = colorbar; 
    c7.Location = "northoutside";
    c7.Ruler.TickLabelFormat = '%g nm/m';
    grid on; 
    set(gca,'layer','top');
    ylabel('Depth (ft)');
    axis ij;
    % Apply configurable depth axis bounds
    depth_bounds = get_plot_bounds([], 'depth_axis', config, test_label);
    ylim(depth_bounds);
    chart_logger('    Applied depth axis bounds: [%.0f, %.0f] ft', depth_bounds(1), depth_bounds(2));
    
    % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
    
    xlabel('Date Time UTC');
    title(sprintf('DAS Strain - Test %s', upper(test_label)));
    
    subplot(3,1,2);
    if ~isempty(head_data)
        % Plot monitoring well data (z2, z3, z4, z5) - exclude pw for separate subplot
        zone_names = fieldnames(head_data.zones);
        if ~isempty(zone_names)
            % Get zones to plot based on configuration, but exclude pw for this subplot
            zones_to_plot = get_zones_to_plot(test_label, zone_names, head_data, config);
            monitoring_zones = zones_to_plot(~strcmp(zones_to_plot, 'pw'));  % Exclude pw
            
            if ~isempty(monitoring_zones)
                % Get display mode
                display_mode = get_head_display_mode(test_label, config);
                
                if strcmp(display_mode, 'average')
                    % Average multiple zones into single line
                    averaged_data = average_zone_data(monitoring_zones, head_data);
                    if ~isempty(averaged_data)
                        yyaxis left;
                        plot(averaged_data.Date, averaged_data.Drawdownft, 'DisplayName', 'Head (avg)');
                        if contains(test_label, 'PT01a', 'IgnoreCase', true)
                            xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
                        else
                            % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                        end
                        xlabel('Date Time UTC');
                        ylabel('Head (ft)');
                        
                        yyaxis right;
                        plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                        ylabel('Strain (nm/m)');
                        chart_logger('    Plotted averaged head data from %d monitoring zones', length(monitoring_zones));
                        
                        % Apply line chart Y-axis bounds
                        apply_line_chart_bounds(config, test_label, 'strain');
                    end
                else
                    % Plot multiple monitoring zones (excluding pw)
                    yyaxis left;
                    hold on;
                    % Define consistent colors for zones z2, z3, z4, z5 across all datasets
                    zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5', 'pw'}, ...
                        {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880], [0.0000 1.0000 1.0000]});
                    
                    for z_idx = 1:length(monitoring_zones)
                        zone_name = monitoring_zones{z_idx};
                        zone_data = head_data.zones.(zone_name);
                        if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data) && ...
                           isfield(zone_data.recovery_data, 'Date') && length(zone_data.recovery_data.Date) > 1
                            % Use consistent color and solid line style
                            if zone_colors.isKey(zone_name)
                                zone_color = zone_colors(zone_name);
                            else
                                zone_color = [0 0 0];
                            end
                            plot(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, ...
                                'Color', zone_color, 'LineStyle', '-', 'LineWidth', 1.2, ...
                                'DisplayName', sprintf('Head %s', zone_name));
                        end
                    end
                    hold off;
                    if strcmpi(test_label, 'PT01a_Recovery_short')
                        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
                    else
                        % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                    end
                    xlabel('Date Time UTC');
                    ylabel('Head (ft)');
                    if length(monitoring_zones) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                    ylabel('Strain (nm/m)');
                    chart_logger('    Plotted monitoring well head data from zones: %s', strjoin(monitoring_zones, ', '));
                    
                    % Apply line chart Y-axis bounds
                    apply_line_chart_bounds(config, test_label, 'strain');
                end
            else
                % No valid head data, just plot strain
                plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
                ylabel('Strain (nm/m)');
                xlabel('Date Time UTC');
                chart_logger('    No valid head data for plotting');
            end
        else
            % No head data, just plot strain
            plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
            ylabel('Strain (nm/m)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot strain
        plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
        % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
        ylabel('Strain (nm/m)');
        xlabel('Date Time UTC');
    end
    title(sprintf('Monitoring Wells - Representative Channel Strain (%.0f ft)', das_data.pumping_zone.channel_depth_ft));
    grid on;
    
    % Third subplot: Pumping Well (pw) data for strain figure
    subplot(3,1,3);
    if ~isempty(head_data) && isfield(head_data.zones, 'pw')
        pw_data = head_data.zones.pw;
        if isfield(pw_data, 'recovery_data') && ~isempty(pw_data.recovery_data) && ...
           isfield(pw_data.recovery_data, 'Date') && length(pw_data.recovery_data.Date) > 1
            
            yyaxis left;
            plot(pw_data.recovery_data.Date, pw_data.recovery_data.Drawdownft, 'Color', [0.0000 1.0000 1.0000], 'LineStyle', '-', 'LineWidth', 2.0, 'DisplayName', 'Pumping Well Head');
            if strcmpi(test_label, 'PT01a_Recovery_short')
                xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
            else
                % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
            end
            xlabel('Date Time UTC');
            ylabel('Pumping Well Head (ft)');
            
            % Apply pumping well specific bounds
            pw_bounds = get_plot_bounds([], 'pw_head_strain', config, test_label);
            ylim(pw_bounds);
            
            yyaxis right;
            plot(filtered_time_strain, filtered_strain_data(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            ylabel('Strain (nm/m)');
            
            % Apply only the DAS bounds (right Y-axis) to match subplot 2, keep left Y-axis (head data) separate
            das_bounds = get_plot_bounds([], 'strain_line', config, test_label);
            ylim(das_bounds);
            chart_logger('    Applied strain line bounds to match subplot 2: [%.3f, %.3f] nm/m', das_bounds(1), das_bounds(2));
            
            title('Pumping Well (pw) Head');
            grid on;
            chart_logger('    Plotted pumping well (pw) head data');
        else
            text(0.5, 0.5, 'No valid pumping well recovery data', 'HorizontalAlignment', 'center');
            title('Pumping Well (pw) - No Data');
        end
    else
        text(0.5, 0.5, 'No pumping well data available', 'HorizontalAlignment', 'center');
        title('Pumping Well (pw) - No Data');
    end
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_strain.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    end  % End of disabled Figure 3 (Strain) block
    
    %% Figure 4: Simple FFT Analysis (DISABLED)
    % fig4_num = 100 + i*4;
    % chart_logger('  Creating Figure %d: Simple FFT Analysis', fig4_num);
    % figure(fig4_num);
    % clf;
    % set(gcf, 'Position', [300 + i*50, 100, 1000, 500]);
    % 
    % % Create simple FFT plots
    % plot_simple_fft(das_data, test_label, config);
    % 
    % if plot_results.save_enabled
    %     filename = sprintf('test_%s_simple_fft.png', test_label);
    %     filepath = fullfile(save_dir, filename);
    %     saveas(gcf, filepath);
    %     plot_results.figures_created{end+1} = filename;
    %     chart_logger('  Saved: %s', filename);
    % end
    
    %% Figure 5: Standalone Displacement Rate vs Head Data (DISABLED)
    % fig5_num = 100 + i*5;
    % chart_logger('  Creating Figure %d: Displacement Rate vs Head Data', fig5_num);
    % figure(fig5_num);
    % clf;
    % set(gcf, 'Position', [100, 200, 1400, 600]);
    % set(gcf, 'Name', sprintf('Displacement Rate vs Head Data - %s', upper(test_label)));
    
    % if ~isempty(head_data)
    %     % Plot monitoring well data (ONLY z4 and z5)
    %     % zone_names = fieldnames(head_data.zones);
    %     % if ~isempty(zone_names)
    %         % Filter to only z4 and z5
    %         monitoring_zones = intersect({'z4', 'z5'}, zone_names);
    %         
    %         if ~isempty(monitoring_zones)
    %             % Plot multiple monitoring zones
    %             yyaxis left;
    %             hold on;
    %             % Define consistent colors for zones
    %             zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
    %                 {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
    %             
    %             for z_idx = 1:length(monitoring_zones)
    %                 zone_name = monitoring_zones{z_idx};
    %                 zone_data = head_data.zones.(zone_name);
    %                 if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data)
    %                     if zone_colors.isKey(zone_name)
    %                         zone_color = zone_colors(zone_name);
    %                     else
    %                         zone_color = [0 0 0];
    %                     end
    %                     [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft_per_min');
    %                     plot(rate_time, drawdown_rate, ...
    %                         'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.5, ...
    %                         'DisplayName', sprintf('Drawdown Rate %s', zone_name));
    %                 end
    %             end
    %             hold off;
    %             % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
    %             xlabel('Date Time UTC', 'FontSize', 12);
    %             ylabel('Drawdown Rate (ft/min)', 'FontSize', 12);
    %             legend('show', 'Location', 'best', 'FontSize', 10);
    %             
    %             yyaxis right;
    %             plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 2.5, 'DisplayName', 'DAS (shifted +20s)');
    %             ylabel('Displacement Rate (nm/s)', 'FontSize', 12);
    %             
    %             % Apply line chart Y-axis bounds
    %             apply_line_chart_bounds(config, test_label, 'displacement_rate');
    %         end
    %     end
    % end
    % title(sprintf('Monitoring Wells - Representative Channel (%.0f ft) - %s', das_data.pumping_zone.channel_depth_ft, upper(test_label)), 'FontSize', 14);
    % grid on;
    % set(gca, 'FontSize', 11);
    % 
    % if plot_results.save_enabled
    %     filename = sprintf('test_%s_displacement_vs_head.png', test_label);
    %     filepath = fullfile(save_dir, filename);
    %     saveas(gcf, filepath);
    %     plot_results.figures_created{end+1} = filename;
    %     chart_logger('  Saved: %s', filename);
    % end
    
    %% Figure 6: Standalone Strain vs Head Data (DISABLED)
    % fig6_num = 100 + i*6;
    % chart_logger('  Creating Figure %d: Strain vs Head Data', fig6_num);
    % figure(fig6_num);
    % clf;
    % set(gcf, 'Position', [120, 180, 1400, 600]);
    % set(gcf, 'Name', sprintf('Strain vs Head Data - %s', upper(test_label)));
    % 
    % if ~isempty(head_data)
        % Plot monitoring well data (ONLY z4 and z5)
        zone_names = fieldnames(head_data.zones);
        if ~isempty(zone_names)
        %     % Filter to only z4 and z5
    %         monitoring_zones = intersect({'z4', 'z5'}, zone_names);
    %         
    %         if ~isempty(monitoring_zones)
    %             % Plot multiple monitoring zones
    %             yyaxis left;
    %             hold on;
    %             % Define consistent colors for zones
    %             zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
    %                 {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
    %             
    %             for z_idx = 1:length(monitoring_zones)
    %                 zone_name = monitoring_zones{z_idx};
    %                 zone_data = head_data.zones.(zone_name);
    %                 if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data)
    %                     if zone_colors.isKey(zone_name)
    %                         zone_color = zone_colors(zone_name);
    %                     else
    %                         zone_color = [0 0 0];
    %                     end
    %                     plot(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, ...
    %                         'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.5, ...
    %                         'DisplayName', sprintf('Head %s', zone_name));
    %                 end
    %             end
    %             hold off;
    %             % Set focused time window for PT01a (recognize both 1Hz and 100Hz datasets)
    if contains(test_label, 'PT01a', 'IgnoreCase', true)
        xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);
    else
        xlim([analysis_start analysis_end]);
    end
    %             xlabel('Date Time UTC', 'FontSize', 12);
    %             ylabel('Head Level (ft)', 'FontSize', 12);
    %             legend('show', 'Location', 'best', 'FontSize', 10);
    %             
    %             % Calculate strain (integrate displacement rate) - same as Figure 103
    %             if isfield(das_data, 'time_array') && isfield(das_data, 'smoothed_data')
    %                 % Find integration start point (10 min before analysis window)
    %                 integration_reference_time = analysis_start - minutes(10);
    %                 integration_start_idx = find(das_data.time_array >= integration_reference_time, 1, 'first');
    %                 if isempty(integration_start_idx)
    %                     integration_start_idx = 1;
    %                 end
    %                 
    %                 % Integrate using cumtrapz (same as Figure 103)
    %                 channel_idx = das_data.pumping_zone.channel_idx;
    %                 subdata1Hz = das_data.smoothed_data(integration_start_idx:end, channel_idx);
    %                 intdata = cumtrapz(subdata1Hz, 1);
    %                 
    %                 % Detrend with quadratic (same as Figure 103)
    %                 dintdata = detrend(intdata, 2);
    %                 
    %                 % Scale and get time array
    %                 strain = dintdata / 10;  % Divide by 10 (same as Figure 103)
    %                 strain_time = das_data.time_array(integration_start_idx:end);
    %                 
    %                 % Extract only analysis window
    %                 analysis_mask = strain_time >= analysis_start & strain_time <= analysis_end;
    %                 strain_analysis = strain(analysis_mask);
    %                 strain_time_analysis = strain_time(analysis_mask);
    %                 
    %                 yyaxis right;
    %                 plot(strain_time_analysis, strain_analysis, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 2.5, 'DisplayName', 'DAS Strain (shifted +20s)');
    %                 ylabel('Strain (nm/m)', 'FontSize', 12);
    %                 
    %                 % Apply line chart Y-axis bounds
    %                 apply_line_chart_bounds(config, test_label, 'strain');
    %             end
    %         end
    %     end
    % end
    % title(sprintf('Monitoring Wells - Representative Channel Strain (%.0f ft) - %s', das_data.pumping_zone.channel_depth_ft, upper(test_label)), 'FontSize', 14);
    % grid on;
    % set(gca, 'FontSize', 11);
    % 
    % if plot_results.save_enabled
    %     filename = sprintf('test_%s_strain_vs_head.png', test_label);
    %     filepath = fullfile(save_dir, filename);
    %     saveas(gcf, filepath);
    %     plot_results.figures_created{end+1} = filename;
    %     chart_logger('  Saved: %s', filename);
    % end
    
    % Store figure handles
    if ~isfield(plot_results, 'figures')
        plot_results.figures = struct();
    end
    plot_results.figures.(test_label).raw_data = fig1_num;
    plot_results.figures.(test_label).displacement_rate = fig2_num;
    plot_results.figures.(test_label).strain = fig3_num;
    % plot_results.figures.(test_label).simple_fft = fig4_num;  % Figure 4 disabled
end

%% Summary
chart_logger('\n=== PLOT GENERATION COMPLETE ===');
chart_logger('Figures created: %d', length(test_labels));

if plot_results.save_enabled && ~isempty(plot_results.figures_created)
    chart_logger('Charts saved to: %s', plot_results.save_dir);
    for i = 1:length(plot_results.figures_created)
        chart_logger('  - %s', plot_results.figures_created{i});
    end
else
    chart_logger('Charts displayed but not saved (save_charts disabled)');
end

% Close chart logging session
chart_logger('close');

end
