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
    
    % Use pcolor with time arrays like other plots (consistent approach)
    v = pcolor(das_data.time_array, das_data.depth_ft, das_data.smoothed_data');
    set(v, 'EdgeColor', 'none');
    
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
    
    colormap('jet');
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
    v = pcolor(das_data.time_array, das_data.depth_ft, das_data.smoothed_data');
    set(v, 'EdgeColor', 'none');
    
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
    
    colormap('jet');
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
        if ~isempty(zone_names)
            zone_data = head_data.zones.(zone_names{1}); % Use first zone
            yyaxis left;
            plot(zone_data.Date, zone_data.Drawdownft);
            xlim([analysis_start analysis_end]);
            xlabel('Date Time UTC');
            ylabel('Head (ft)');
            
            yyaxis right;
            plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx));
            ylabel('Displacement Rate (nm/s)');
        else
            % No head data, just plot DAS
            plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx));
            xlim([analysis_start analysis_end]);
            ylabel('Displacement Rate (nm/s)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot DAS
        plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx));
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
    v = pcolor(iTdas, das_data.depth_ft, dintdata'/10);  % Divide by 10 like simple script
    set(v, 'EdgeColor', 'none');
    
    % Set strain bounds using new utility functions
    if ~isempty(unified_bounds) && isfield(unified_bounds, 'strain')
        % Use pre-calculated unified bounds
        strain_bounds = unified_bounds.strain;
        set(gca, 'clim', strain_bounds);
        fprintf('    Unified strain bounds: [%.6f, %.6f] nm/m\n', strain_bounds(1), strain_bounds(2));
    else
        % Calculate individual bounds for this dataset  
        strain_bounds = get_plot_bounds(das_data, 'strain', config);
        set(gca, 'clim', strain_bounds);
    end
    
    colormap('jet');
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
            zone_data = head_data.zones.(zone_names{1}); % Use first zone
            yyaxis left;
            plot(zone_data.Date, zone_data.Drawdownft);
            xlim([analysis_start analysis_end]);
            xlabel('Date Time UTC');
            ylabel('Head (ft)');
            
            yyaxis right;
            plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10);
            ylabel('Strain (nm/m)');
        else
            % No head data, just plot strain
            plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10);
            xlim([analysis_start analysis_end]);
            ylabel('Strain (nm/m)');
            xlabel('Date Time UTC');
        end
    else
        % No head data, just plot strain
        plot(iTdas, dintdata(:, das_data.pumping_zone.channel_idx)/10);
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