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
    
    %% Figure 1: Raw Data Waterfall (from simple script)
    fig1_num = 100 + i*3 - 2;
    fprintf('  Creating Figure %d: Raw Data Waterfall\n', fig1_num);
    figure(fig1_num);
    clf;
    imagesc(das_data.smoothed_data');  % Use smoothed data like simple script
    
    % Set color bounds - dynamic or fixed
    if isfield(config, 'dynamic_bounds') && config.dynamic_bounds
        % Dynamic bounds using percentiles to remove outliers
        raw_data = das_data.smoothed_data';
        lower_bound = prctile(raw_data(:), 5);
        upper_bound = prctile(raw_data(:), 95);
        clim([lower_bound upper_bound]);
        fprintf('    Dynamic raw data bounds: [%.3f, %.3f]\n', lower_bound, upper_bound);
    else
        % Fixed bounds from simple script
        clim([-2 2]);
        fprintf('    Fixed raw data bounds: [-2, 2]\n');
    end
    
    colormap('jet');
    colorbar;
    title(sprintf('Raw Data - Test %s', upper(test_label)));
    xlabel('Sample');
    ylabel('Channel Number');
    
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
    
    % Set displacement rate bounds - dynamic or fixed
    if isfield(config, 'dynamic_bounds') && config.dynamic_bounds
        % Dynamic bounds - focus on pumping zone during analysis window
        analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
        zone_mask = das_data.depth_ft >= das_data.pumping_zone.min_ft & das_data.depth_ft <= das_data.pumping_zone.max_ft;
        zone_data = das_data.smoothed_data(analysis_mask, zone_mask);
        lower_bound = prctile(zone_data(:), 10);
        upper_bound = prctile(zone_data(:), 90);
        set(gca, 'clim', [lower_bound upper_bound]);
        fprintf('    Dynamic displacement rate bounds: [%.3f, %.3f] nm/s\n', lower_bound, upper_bound);
    else
        % Fixed bounds from simple script
        set(gca, 'clim', [-0.25 0.15]);
        fprintf('    Fixed displacement rate bounds: [-0.25, 0.15] nm/s\n');
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
    
    % Set strain bounds - dynamic or fixed
    if isfield(config, 'dynamic_bounds') && config.dynamic_bounds
        % Dynamic bounds - symmetric around zero, focus on pumping zone
        zone_mask = das_data.depth_ft >= das_data.pumping_zone.min_ft & das_data.depth_ft <= das_data.pumping_zone.max_ft;
        zone_strain = dintdata(:, zone_mask)/10;
        max_abs = prctile(abs(zone_strain(:)), 95);
        % Keep symmetric bounds but ensure they make sense for strain (typically negative)
        if mean(zone_strain(:)) < 0
            strain_bounds = [-max_abs, max_abs*0.2];  % Allow some positive but emphasize negative
        else
            strain_bounds = [-max_abs, max_abs];  % Symmetric if data is mixed
        end
        set(gca, 'clim', strain_bounds);
        fprintf('    Dynamic strain bounds: [%.3f, %.3f] nm/m\n', strain_bounds(1), strain_bounds(2));
    else
        % Fixed bounds from simple script
        set(gca, 'clim', [-2 0]);
        fprintf('    Fixed strain bounds: [-2, 0] nm/m\n');
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