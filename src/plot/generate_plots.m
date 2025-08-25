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

fprintf('=== GENERATING ANALYSIS PLOTS (SIMPLIFIED) ===\n');

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
        fprintf('Created chart output directory: %s\n', save_dir);
    end
    plot_results.save_dir = save_dir;
    fprintf('Chart saving enabled to: %s\n', save_dir);
else
    fprintf('Chart saving disabled\n');
end

%% Get available test labels from results
test_labels = {};
if isfield(das_results, 'tests')
    test_labels = das_results.tests;
elseif ~isempty(fieldnames(das_results))
    test_labels = fieldnames(das_results);
    test_labels = test_labels(~strcmp(test_labels, 'tests') & ~strcmp(test_labels, 'timing'));
end

fprintf('Creating plots for tests: %s\n', strjoin(test_labels, ', '));

%% Pre-calculate unified bounds if using related bounds
unified_bounds = struct();
if isfield(config, 'use_related_bounds') && config.use_related_bounds && length(test_labels) > 1
    fprintf('Calculating unified bounds across %d related datasets...\n', length(test_labels));
    
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
        fprintf('✓ Unified bounds calculated\n');
    end
else
    fprintf('Using individual bounds for each dataset\n');
end

%% Create simplified plots for each test (based on PM07_PT01c_Simple.m)
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Creating plots for test %s ---\n', upper(test_label));
    
    % Skip if no DAS data
    if ~isfield(das_results, test_label) || isfield(das_results.(test_label), 'error')
        fprintf('  Skipping %s: No DAS data available\n', test_label);
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
        fprintf('    DEBUG: Found head data for %s with zones: %s\n', test_label, strjoin(fieldnames(head_data.zones), ', '));
    else
        fprintf('    DEBUG: No head data available for %s\n', test_label);
    end
    
    %% Figure 1: Raw Data Waterfall (standardized with time filtering)
    fig1_num = 100 + i*3 - 2;
    fprintf('  Creating Figure %d: Raw Data Waterfall\n', fig1_num);
    
    % DEBUG: Check data availability and dimensions
    fprintf('    DEBUG: das_data fields: %s\n', strjoin(fieldnames(das_data), ', '));
    if isfield(das_data, 'smoothed_data')
        fprintf('    DEBUG: smoothed_data size: [%d x %d]\n', size(das_data.smoothed_data, 1), size(das_data.smoothed_data, 2));
        fprintf('    DEBUG: smoothed_data range: [%.3f, %.3f]\n', min(das_data.smoothed_data(:)), max(das_data.smoothed_data(:)));
    else
        fprintf('    ERROR: smoothed_data field missing!\n');
    end
    
    if isfield(das_data, 'time_array')
        fprintf('    DEBUG: time_array size: %d elements\n', length(das_data.time_array));
        fprintf('    DEBUG: time_array range: %s to %s\n', das_data.time_array(1), das_data.time_array(end));
    else
        fprintf('    ERROR: time_array field missing!\n');
    end
    
    if isfield(das_data, 'depth_ft')
        fprintf('    DEBUG: depth_ft size: %d elements\n', length(das_data.depth_ft));
        fprintf('    DEBUG: depth_ft range: [%.1f, %.1f] ft\n', min(das_data.depth_ft), max(das_data.depth_ft));
    else
        fprintf('    ERROR: depth_ft field missing!\n');
    end
    
    figure(fig1_num);
    clf;
    
    % Check if required data exists before plotting
    if ~isfield(das_data, 'smoothed_data') || ~isfield(das_data, 'time_array') || ~isfield(das_data, 'depth_ft')
        fprintf('    ERROR: Missing required data fields for waterfall plot!\n');
        text(0.5, 0.5, 'Missing Data Fields', 'HorizontalAlignment', 'center');
        return;
    end
    
    % Apply configurable plotting method to test pixelation sources
    v = apply_plot_config(das_data.time_array, das_data.depth_ft, das_data.smoothed_data', config, 'waterfall');
    
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
        fprintf('    Unified raw data bounds: [%.6f, %.6f]\n', raw_bounds(1), raw_bounds(2));
    else
        % Calculate individual bounds for this dataset
        raw_bounds = get_plot_bounds(das_data, 'raw', config);
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
    ylim([100 700]);  % Consistent depth range
    xlim([analysis_start analysis_end]);  % Filter to analysis window
    xlabel('Date Time UTC');
    title(sprintf('Raw Data - Test %s', upper(test_label)));
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_raw_data.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        fprintf('  Saved: %s\n', filename);
    end
    
    %% Figure 2: Displacement Rate (from simple script Figure 2)
    fig2_num = 100 + i*3 - 1;
    fprintf('  Creating Figure %d: Displacement Rate\n', fig2_num);
    figure(fig2_num);
    clf;
    
    subplot(2,1,1);
    % Apply configurable plotting method to test pixelation sources
    v = apply_plot_config(das_data.time_array, das_data.depth_ft, das_data.smoothed_data', config, 'waterfall');
    
    % Set displacement rate bounds using new utility functions
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'displacement')
        % Use pre-calculated unified bounds
        disp_bounds = unified_bounds.displacement;
        set(gca, 'clim', disp_bounds);
        fprintf('    Unified displacement rate bounds: [%.6f, %.6f] nm/s\n', disp_bounds(1), disp_bounds(2));
    else
        % Calculate individual bounds for this dataset
        disp_bounds = get_plot_bounds(das_data, 'displacement', config);
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
    ylim([100 700]);
    xlim([analysis_start analysis_end]);
    xlabel('Date Time UTC');
    title(sprintf('DAS Displacement Rate - Test %s', upper(test_label)));
    
    subplot(2,1,2);
    if ~isempty(head_data)
        % Plot head data if available (like simple script)
        zone_names = fieldnames(head_data.zones);
        fprintf('    DEBUG DISPLACEMENT: Found %d zones: %s\n', length(zone_names), strjoin(zone_names, ', '));
        if ~isempty(zone_names)
            % Get zones to plot based on configuration
            zones_to_plot = get_zones_to_plot(test_label, zone_names, head_data, config);
            
            if ~isempty(zones_to_plot)
                % Get display mode
                display_mode = get_head_display_mode(test_label, config);
                
                if strcmp(display_mode, 'average')
                    % Average multiple zones into single line
                    averaged_data = average_zone_data(zones_to_plot, head_data);
                    if ~isempty(averaged_data)
                        yyaxis left;
                        plot(averaged_data.Date, averaged_data.Drawdownft, 'DisplayName', 'Head (avg)');
                        xlim([analysis_start analysis_end]);
                        xlabel('Date Time UTC');
                        ylabel('Head (ft)');
                        
                        yyaxis right;
                        plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx), 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                        ylabel('Displacement Rate (nm/s)');
                        fprintf('    Plotted averaged head data from %d zones\n', length(zones_to_plot));
                    end
                else
                    % Plot multiple zones or single zone
                    yyaxis left;
                    hold on;
                    % Define consistent colors for zones z2, z3, z4, z5 across all datasets
                    zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
                        {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
                    
                    for z_idx = 1:length(zones_to_plot)
                        zone_name = zones_to_plot{z_idx};
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
                    if length(zones_to_plot) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx), 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                    ylabel('Displacement Rate (nm/s)');
                    fprintf('    Plotted head data from zones: %s\n', strjoin(zones_to_plot, ', '));
                end
            else
                % No valid head data, just plot DAS
                plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx), 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                xlim([analysis_start analysis_end]);
                ylabel('Displacement Rate (nm/s)');
                xlabel('Date Time UTC');
            end
        else
            % No head data, just plot DAS
            plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx), 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
            xlim([analysis_start analysis_end]);
            ylabel('Displacement Rate (nm/s)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot DAS
        plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx), 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
        xlim([analysis_start analysis_end]);
        ylabel('Displacement Rate (nm/s)');
        xlabel('Date Time UTC');
    end
    title(sprintf('Representative Channel (%.0f ft)', das_data.pumping_zone.channel_depth_ft));
    grid on;
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_displacement_rate.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        fprintf('  Saved: %s\n', filename);
    end
    
    %% Figure 3: Strain (integrated data) - from simple script Figure 3
    fig3_num = 100 + i*3;
    fprintf('  Creating Figure %d: Strain\n', fig3_num);
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
        fprintf('    WARNING: Analysis window outside dataset - using dataset start for integration\n');
    else
        fprintf('    Integration starting at: %s (10 min before analysis)\n', integration_reference_time);
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
    
    subplot(2,1,1);
    % Apply configurable plotting method to test pixelation sources
    v = apply_plot_config(iTdas, das_data.depth_ft, dintdata'/10, config, 'waterfall');
    
    % Set strain bounds using actual plotted data (dintdata/10)
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'strain')
        % Use pre-calculated unified bounds
        strain_bounds = unified_bounds.strain;
        set(gca, 'clim', strain_bounds);
        fprintf('    Unified strain bounds: [%.6f, %.6f] nm/m\n', strain_bounds(1), strain_bounds(2));
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
            fprintf('    Individual strain bounds: [%.6f, %.6f] nm/m\n', strain_bounds(1), strain_bounds(2));
        else
            % Fixed bounds
            strain_bounds = [-2, 0];
            set(gca, 'clim', strain_bounds);
            fprintf('    Fixed strain bounds: [-2, 0] nm/m\n');
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
    ylim([100 700]);
    xlim([analysis_start analysis_end]);
    xlabel('Date Time UTC');
    title(sprintf('DAS Strain - Test %s', upper(test_label)));
    
    subplot(2,1,2);
    if ~isempty(head_data)
        % Plot head data if available
        zone_names = fieldnames(head_data.zones);
        if ~isempty(zone_names)
            % Get zones to plot based on configuration
            zones_to_plot = get_zones_to_plot(test_label, zone_names, head_data, config);
            
            if ~isempty(zones_to_plot)
                % Get display mode
                display_mode = get_head_display_mode(test_label, config);
                
                if strcmp(display_mode, 'average')
                    % Average multiple zones into single line
                    averaged_data = average_zone_data(zones_to_plot, head_data);
                    if ~isempty(averaged_data)
                        yyaxis left;
                        plot(averaged_data.Date, averaged_data.Drawdownft, 'DisplayName', 'Head (avg)');
                        xlim([analysis_start analysis_end]);
                        xlabel('Date Time UTC');
                        ylabel('Head (ft)');
                        
                        yyaxis right;
                        plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                        ylabel('Strain (nm/m)');
                        fprintf('    Plotted averaged head data from %d zones\n', length(zones_to_plot));
                    end
                else
                    % Plot multiple zones or single zone
                    yyaxis left;
                    hold on;
                    % Define consistent colors for zones z2, z3, z4, z5 across all datasets
                    zone_colors = containers.Map({'z2', 'z3', 'z4', 'z5'}, ...
                        {[0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250], [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});
                    
                    for z_idx = 1:length(zones_to_plot)
                        zone_name = zones_to_plot{z_idx};
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
                    if length(zones_to_plot) > 1
                        legend('show');
                    end
                    
                    yyaxis right;
                    plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                    ylabel('Strain (nm/m)');
                    fprintf('    Plotted head data from zones: %s\n', strjoin(zones_to_plot, ', '));
                end
            else
                % No valid head data, just plot strain
                plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10, 'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 1.2, 'DisplayName', 'DAS');
                xlim([analysis_start analysis_end]);
                ylabel('Strain (nm/m)');
                xlabel('Date Time UTC');
                fprintf('    No valid head data for plotting\n');
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
    title(sprintf('Representative Channel Strain (%.0f ft)', das_data.pumping_zone.channel_depth_ft));
    grid on;
    
    if plot_results.save_enabled
        filename = sprintf('test_%s_strain.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        fprintf('  Saved: %s\n', filename);
    end
    
    % Store figure handles
    if ~isfield(plot_results, 'figures')
        plot_results.figures = struct();
    end
    plot_results.figures.(test_label).raw_data = fig1_num;
    plot_results.figures.(test_label).displacement_rate = fig2_num;
    plot_results.figures.(test_label).strain = fig3_num;
end

%% Summary
fprintf('\n=== PLOT GENERATION COMPLETE ===\n');
fprintf('Figures created: %d\n', length(test_labels));

if plot_results.save_enabled && ~isempty(plot_results.figures_created)
    fprintf('Charts saved to: %s\n', plot_results.save_dir);
    for i = 1:length(plot_results.figures_created)
        fprintf('  - %s\n', plot_results.figures_created{i});
    end
else
    fprintf('Charts displayed but not saved (save_charts disabled)\n');
end

end