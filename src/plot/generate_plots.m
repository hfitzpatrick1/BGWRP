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
                    
                    % Perform linear regression
                    lr_results = linear_regression_strain_drawdown(das_results, head_results, test_label, lr_config);
                    
                    % Store results in das_results for later use
                    das_results.(test_label).linear_regression = lr_results;
                    
                    chart_logger('✓ Linear regression for %s: R=%.3f, R^2=%.3f', test_label, lr_results.R, lr_results.R_squared);
                catch ME
                    chart_logger('✗ Linear regression failed for %s: %s', test_label, ME.message);
                    fprintf('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Correlation analysis failed: %s', ME.message);
        fprintf('Correlation analysis error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
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
                    % Depth range analysis (optional)
                    if isfield(config, 'lr_depth_range_ft')
                        lr_config.depth_range_ft = config.lr_depth_range_ft;
                    end
                    if isfield(config, 'lr_depth_averaging_method')
                        lr_config.depth_averaging_method = config.lr_depth_averaging_method;
                    end
                    lr_config.show_plots = true;
                    
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
                        fprintf('\n=== COMPARISON: Strain Rate vs Displacement Rate ===\n');
                        fprintf('Test: %s\n', test_label);
                        fprintf('Strain Rate Regression:       R=%.3f, R^2=%.3f, slope=%.2e (1/s)/(ft/s)\n', ...
                            lr_results_strain.R, lr_results_strain.R_squared, lr_results_strain.slope);
                        fprintf('Displacement Rate Regression: R=%.3f, R^2=%.3f, slope=%.2e (nm/s)/(ft/s)\n', ...
                            lr_results_disp.R, lr_results_disp.R_squared, lr_results_disp.slope);
                        fprintf('======================================================\n\n');
                    end
                    
                    % Store primary result (for backward compatibility)
                    das_results.(test_label).linear_regression = lr_results_strain;
                    
                catch ME
                    chart_logger('✗ Linear regression failed for %s: %s', test_label, ME.message);
                    fprintf('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Linear regression analysis failed: %s', ME.message);
        fprintf('Linear regression error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
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
                    fprintf('  Error at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
            end
        end
        
    catch ME
        chart_logger('✗ Amplitude storage calculation failed: %s', ME.message);
        fprintf('Amplitude storage error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
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
        fprintf('Storage analysis error details: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
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
    clf;
    
    % Check if required data exists before plotting
    if ~isfield(das_data, 'smoothed_data') || ~isfield(das_data, 'time_array') || ~isfield(das_data, 'depth_ft')
        chart_logger('    ERROR: Missing required data fields for waterfall plot!');
        text(0.5, 0.5, 'Missing Data Fields', 'HorizontalAlignment', 'center');
        return;
    end
    
    % Apply configurable plotting method to test pixelation sources
    apply_plot_config(das_data.time_array, das_data.depth_ft, das_data.smoothed_data', config, 'waterfall');
    
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
    
    % Set color bounds using new utility functions
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'raw')
        % Use pre-calculated unified bounds
        raw_bounds = unified_bounds.raw;
        clim(raw_bounds);
        chart_logger('    Unified raw data bounds: [%.6f, %.6f]', raw_bounds(1), raw_bounds(2));
    else
        % Calculate individual bounds for this dataset
        raw_bounds = get_plot_bounds(das_data, 'raw', config, test_label);
        clim(raw_bounds);
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
    ylabel('Depth (ft)');
    axis ij;
    % Apply configurable depth axis bounds
    depth_bounds = get_plot_bounds([], 'depth_axis', config, test_label);
    ylim(depth_bounds);
    chart_logger('    Applied depth axis bounds: [%.0f, %.0f] ft', depth_bounds(1), depth_bounds(2));
    xlim([analysis_start analysis_end]);  % Filter to analysis window
    xlabel('Date Time UTC');
    title(sprintf('Raw Data - Test %s', upper(test_label)));
    
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
    clf;
    
    subplot(3,1,1);
    % Apply configurable plotting method to test pixelation sources
    % For displacement rate, use the analysis window data only
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
    analysis_smoothed_data = das_data.smoothed_data(analysis_mask, :);
    analysis_time_array = das_data.time_array(analysis_mask);
    apply_plot_config(analysis_time_array, das_data.depth_ft, analysis_smoothed_data', config, 'waterfall');
    
    % Set displacement rate bounds using new utility functions
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'displacement')
        % Use pre-calculated unified bounds
        disp_bounds = unified_bounds.displacement;
        set(gca, 'clim', disp_bounds);
        chart_logger('    Unified displacement rate bounds: [%.6f, %.6f] nm/s', disp_bounds(1), disp_bounds(2));
    else
        % Calculate individual bounds for this dataset
        disp_bounds = get_plot_bounds(das_data, 'displacement', config, test_label);
        set(gca, 'clim', disp_bounds);
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
    c7.Ruler.TickLabelFormat = '%g nm/s';
    grid on; 
    set(gca,'layer','top');
    ylabel('Depth (ft)');
    axis ij;
    % Apply configurable depth axis bounds
    depth_bounds = get_plot_bounds([], 'depth_axis', config, test_label);
    ylim(depth_bounds);
    chart_logger('    Applied depth axis bounds: [%.0f, %.0f] ft', depth_bounds(1), depth_bounds(2));
    xlim([analysis_start analysis_end]);
    xlabel('Date Time UTC');
    title(sprintf('DAS Displacement Rate - Test %s', upper(test_label)));
    
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
                        [drawdown_rate, rate_time] = calculate_drawdown_rate(averaged_data.Date, averaged_data.Drawdownft, 'ft_per_min');
                        plot(rate_time, drawdown_rate, 'DisplayName', 'Drawdown Rate (avg)');
                        xlim([analysis_start analysis_end]);
                        xlabel('Date Time UTC');
                        ylabel('Drawdown Rate (ft/min)');
                        
                        yyaxis right;
                        plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                        ylabel('Displacement Rate (nm/s)');
                        chart_logger('    Plotted averaged drawdown rate from %d monitoring zones', length(monitoring_zones));
                        
                        % Apply line chart Y-axis bounds
                        apply_line_chart_bounds(config, test_label, 'displacement_rate');
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
                            [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft_per_min');
                            plot(rate_time, drawdown_rate, ...
                                'Color', zone_color, 'LineStyle', '-', 'LineWidth', 1.2, ...
                                'DisplayName', sprintf('Drawdown Rate %s', zone_name));
                        end
                    end
                    hold off;
                    xlim([analysis_start analysis_end]);
                    xlabel('Date Time UTC');
                    ylabel('Drawdown Rate (ft/min)');
                    if length(monitoring_zones) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                    ylabel('Displacement Rate (nm/s)');
                    chart_logger('    Plotted monitoring well drawdown rate data from zones: %s', strjoin(monitoring_zones, ', '));
                    
                    % Apply line chart Y-axis bounds
                    apply_line_chart_bounds(config, test_label, 'displacement_rate');
                end
            else
                % No valid head data, just plot DAS
                plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                xlim([analysis_start analysis_end]);
                ylabel('Displacement Rate (nm/s)');
                xlabel('Date Time UTC');
            end
        else
            % No head data, just plot DAS
            plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            xlim([analysis_start analysis_end]);
            ylabel('Displacement Rate (nm/s)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot DAS
        plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
        xlim([analysis_start analysis_end]);
        ylabel('Displacement Rate (nm/s)');
        xlabel('Date Time UTC');
    end
    title(sprintf('Monitoring Wells - Representative Channel (%.0f ft)', das_data.pumping_zone.channel_depth_ft));
    grid on;
    
    % Third subplot: Pumping Well (pw) data
    subplot(3,1,3);
    if ~isempty(head_data) && isfield(head_data.zones, 'pw')
        pw_data = head_data.zones.pw;
        if isfield(pw_data, 'recovery_data') && ~isempty(pw_data.recovery_data) && ...
           isfield(pw_data.recovery_data, 'Date') && length(pw_data.recovery_data.Date) > 1
            
            yyaxis left;
            % Convert head levels to drawdown rate for better comparison with displacement rate
            [drawdown_rate, rate_time] = calculate_drawdown_rate(pw_data.recovery_data.Date, pw_data.recovery_data.Drawdownft, 'ft_per_min');
            plot(rate_time, drawdown_rate, 'Color', [0.0000 1.0000 1.0000], 'LineStyle', '-', 'LineWidth', 0.8, 'DisplayName', 'Pumping Well Drawdown Rate');
            xlim([analysis_start analysis_end]);
            xlabel('Date Time UTC');
            ylabel('Pumping Well Drawdown Rate (ft/min)');
            
            yyaxis right;
            plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            ylabel('Displacement Rate (nm/s)');
            
            % Apply only the DAS bounds (right Y-axis) to match subplot 2, keep left Y-axis (drawdown rate) separate
            das_bounds = get_plot_bounds([], 'displacement_rate_line', config, test_label);
            ylim(das_bounds);
            chart_logger('    Applied displacement rate line bounds to match subplot 2: [%.3f, %.3f] nm/s', das_bounds(1), das_bounds(2));
            
            title('Pumping Well (pw) Drawdown');
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
    
    %% Figure 3: Strain (integrated data) - from simple script Figure 3
    fig3_num = 100 + i*3;
    chart_logger('  Creating Figure %d: Strain', fig3_num);
    figure(fig3_num);
    clf;
    
    % Calculate integrated data using absolute time-based integration
    % Start integration 10 minutes before analysis window for consistent baseline
    integration_reference_time = analysis_start - minutes(10);
    
    % Find the integration start index in the actual data
    integration_start_idx = find(das_data.time_array >= integration_reference_time, 1);
    
    if isempty(integration_start_idx)
        % Analysis window is outside dataset bounds - use beginning of dataset
        integration_start_idx = 1;
        chart_logger('    WARNING: Analysis window outside dataset - using dataset start for integration');
    else
        chart_logger('    Integration starting at: %s (10 min before analysis)', integration_reference_time);
    end
    
    % Check if analysis window is actually available in the dataset
    analysis_end_idx = find(das_data.time_array <= analysis_end, 1, 'last');
    if isempty(analysis_end_idx) || das_data.time_array(end) < analysis_start
        error('Analysis window (%s to %s) is completely outside dataset bounds (%s to %s)', ...
            analysis_start, analysis_end, das_data.time_array(1), das_data.time_array(end));
    end
    
    subdata1Hz = das_data.smoothed_data(integration_start_idx:end, :);
    intdata = cumtrapz(subdata1Hz, 1);
    iTdas = das_data.time_array(integration_start_idx:end);
    
    % Detrend integrated data
    dintdata = zeros(size(intdata));
    for nn = 1:size(intdata, 2)
        dintdata(:, nn) = detrend(intdata(:, nn), 2);
    end
    
    subplot(3,1,1);
    % Apply configurable plotting method to test pixelation sources
    apply_plot_config(iTdas, das_data.depth_ft, dintdata'/10, config, 'waterfall');
    
    % Set strain bounds using actual plotted data (dintdata/10)
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
            strain_data = dintdata(:, zone_mask) / 10;  % Same as plotted data
            
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
    xlim([analysis_start analysis_end]);
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
                        xlim([analysis_start analysis_end]);
                        xlabel('Date Time UTC');
                        ylabel('Head (ft)');
                        
                        yyaxis right;
                        plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
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
                    xlim([analysis_start analysis_end]);
                    xlabel('Date Time UTC');
                    ylabel('Head (ft)');
                    if length(monitoring_zones) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                    ylabel('Strain (nm/m)');
                    chart_logger('    Plotted monitoring well head data from zones: %s', strjoin(monitoring_zones, ', '));
                    
                    % Apply line chart Y-axis bounds
                    apply_line_chart_bounds(config, test_label, 'strain');
                end
            else
                % No valid head data, just plot strain
                plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                xlim([analysis_start analysis_end]);
                ylabel('Strain (nm/m)');
                xlabel('Date Time UTC');
                chart_logger('    No valid head data for plotting');
            end
        else
            % No head data, just plot strain
            plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            xlim([analysis_start analysis_end]);
            ylabel('Strain (nm/m)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot strain
        plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
        xlim([analysis_start analysis_end]);
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
            plot(pw_data.recovery_data.Date, pw_data.recovery_data.Drawdownft, 'Color', [0.0000 1.0000 1.0000], 'LineStyle', '-', 'LineWidth', 0.8, 'DisplayName', 'Pumping Well Head');
            xlim([analysis_start analysis_end]);
            xlabel('Date Time UTC');
            ylabel('Pumping Well Head (ft)');
            
            % Apply pumping well specific bounds
            pw_bounds = get_plot_bounds([], 'pw_head_strain', config, test_label);
            ylim(pw_bounds);
            
            yyaxis right;
            plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
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
    
    %% Figure 4: Simple FFT Analysis
    fig4_num = 100 + i*4;
    chart_logger('  Creating Figure %d: Simple FFT Analysis', fig4_num);
    figure(fig4_num);
    clf;
    set(gcf, 'Position', [300 + i*50, 100, 1000, 500]);
    
    % Create simple FFT plots
    plot_simple_fft(das_data, test_label, config);
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_simple_fft.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    
    %% Figure 5: Standalone Displacement Rate vs Head Data (from Figure 102 subplot 2)
    fig5_num = 100 + i*5;
    chart_logger('  Creating Figure %d: Displacement Rate vs Head Data', fig5_num);
    figure(fig5_num);
    clf;
    set(gcf, 'Position', [100, 200, 1400, 600]);
    set(gcf, 'Name', sprintf('Displacement Rate vs Head Data - %s', upper(test_label)));
    
    if ~isempty(head_data)
        % Plot monitoring well data (ONLY z4 and z5)
        zone_names = fieldnames(head_data.zones);
        if ~isempty(zone_names)
            % Filter to only z4 and z5
            monitoring_zones = intersect({'z4', 'z5'}, zone_names);
            
            if ~isempty(monitoring_zones)
                % Plot multiple monitoring zones
                yyaxis left;
                hold on;
                % Define consistent colors for zones
                zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
                    {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
                
                for z_idx = 1:length(monitoring_zones)
                    zone_name = monitoring_zones{z_idx};
                    zone_data = head_data.zones.(zone_name);
                    if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data)
                        if zone_colors.isKey(zone_name)
                            zone_color = zone_colors(zone_name);
                        else
                            zone_color = [0 0 0];
                        end
                        [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft_per_min');
                        plot(rate_time, drawdown_rate, ...
                            'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.5, ...
                            'DisplayName', sprintf('Drawdown Rate %s', zone_name));
                    end
                end
                hold off;
                xlim([analysis_start analysis_end]);
                xlabel('Date Time UTC', 'FontSize', 12);
                ylabel('Drawdown Rate (ft/min)', 'FontSize', 12);
                legend('show', 'Location', 'best', 'FontSize', 10);
                
                yyaxis right;
                plot(das_data.analysis_time, das_data.analysis_strain_rate, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 2.5, 'DisplayName', 'DAS (shifted +20s)');
                ylabel('Displacement Rate (nm/s)', 'FontSize', 12);
                
                % Apply line chart Y-axis bounds
                apply_line_chart_bounds(config, test_label, 'displacement_rate');
            end
        end
    end
    title(sprintf('Monitoring Wells - Representative Channel (%.0f ft) - %s', das_data.pumping_zone.channel_depth_ft, upper(test_label)), 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 11);
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_displacement_vs_head.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    
    %% Figure 6: Standalone Strain vs Head Data (from Figure 103 subplot 2)
    fig6_num = 100 + i*6;
    chart_logger('  Creating Figure %d: Strain vs Head Data', fig6_num);
    figure(fig6_num);
    clf;
    set(gcf, 'Position', [120, 180, 1400, 600]);
    set(gcf, 'Name', sprintf('Strain vs Head Data - %s', upper(test_label)));
    
    if ~isempty(head_data)
        % Plot monitoring well data (ONLY z4 and z5)
        zone_names = fieldnames(head_data.zones);
        if ~isempty(zone_names)
            % Filter to only z4 and z5
            monitoring_zones = intersect({'z4', 'z5'}, zone_names);
            
            if ~isempty(monitoring_zones)
                % Plot multiple monitoring zones
                yyaxis left;
                hold on;
                % Define consistent colors for zones
                zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
                    {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
                
                for z_idx = 1:length(monitoring_zones)
                    zone_name = monitoring_zones{z_idx};
                    zone_data = head_data.zones.(zone_name);
                    if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data)
                        if zone_colors.isKey(zone_name)
                            zone_color = zone_colors(zone_name);
                        else
                            zone_color = [0 0 0];
                        end
                        plot(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, ...
                            'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.5, ...
                            'DisplayName', sprintf('Head %s', zone_name));
                    end
                end
                hold off;
                xlim([analysis_start analysis_end]);
                xlabel('Date Time UTC', 'FontSize', 12);
                ylabel('Head Level (ft)', 'FontSize', 12);
                legend('show', 'Location', 'best', 'FontSize', 10);
                
                % Calculate strain (integrate displacement rate) - same as Figure 103
                if isfield(das_data, 'time_array') && isfield(das_data, 'smoothed_data')
                    % Find integration start point (10 min before analysis window)
                    integration_reference_time = analysis_start - minutes(10);
                    integration_start_idx = find(das_data.time_array >= integration_reference_time, 1, 'first');
                    if isempty(integration_start_idx)
                        integration_start_idx = 1;
                    end
                    
                    % Integrate using cumtrapz (same as Figure 103)
                    channel_idx = das_data.pumping_zone.channel_idx;
                    subdata1Hz = das_data.smoothed_data(integration_start_idx:end, channel_idx);
                    intdata = cumtrapz(subdata1Hz, 1);
                    
                    % Detrend with quadratic (same as Figure 103)
                    dintdata = detrend(intdata, 2);
                    
                    % Scale and get time array
                    strain = dintdata / 10;  % Divide by 10 (same as Figure 103)
                    strain_time = das_data.time_array(integration_start_idx:end);
                    
                    % Extract only analysis window
                    analysis_mask = strain_time >= analysis_start & strain_time <= analysis_end;
                    strain_analysis = strain(analysis_mask);
                    strain_time_analysis = strain_time(analysis_mask);
                    
                    yyaxis right;
                    plot(strain_time_analysis, strain_analysis, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 2.5, 'DisplayName', 'DAS Strain (shifted +20s)');
                    ylabel('Strain (nm/m)', 'FontSize', 12);
                    
                    % Apply line chart Y-axis bounds
                    apply_line_chart_bounds(config, test_label, 'strain');
                end
            end
        end
    end
    title(sprintf('Monitoring Wells - Representative Channel Strain (%.0f ft) - %s', das_data.pumping_zone.channel_depth_ft, upper(test_label)), 'FontSize', 14);
    grid on;
    set(gca, 'FontSize', 11);
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_strain_vs_head.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        chart_logger('  Saved: %s', filename);
    end
    
    % Store figure handles
    if ~isfield(plot_results, 'figures')
        plot_results.figures = struct();
    end
    plot_results.figures.(test_label).raw_data = fig1_num;
    plot_results.figures.(test_label).displacement_rate = fig2_num;
    plot_results.figures.(test_label).strain = fig3_num;
    plot_results.figures.(test_label).simple_fft = fig4_num;
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
