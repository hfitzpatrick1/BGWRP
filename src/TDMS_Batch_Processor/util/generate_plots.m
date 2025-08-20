function plot_results = generate_plots(~, das_results, config)
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
    
    % Create waterfall plot (based on simple script Figure 2)
    fig_num = 100 + i;
    figure(fig_num); 
    clf;
    
    % Get analysis window for plotting
    analysis_start = das_data.analysis_time(1);
    analysis_end = das_data.analysis_time(end);
    
    % Plot waterfall
    subplot(2,1,1);
    v = pcolor(das_data.time_array, das_data.depth_ft, das_data.smoothed_data');
    set(v, 'EdgeColor', 'none');
    set(gca, 'clim', [-0.25 0.15]);
    colormap('jet');
    c7 = colorbar; 
    c7.Location = "northoutside";
    c7.Ruler.TickLabelFormat = '%g nm/s';
    grid on; 
    set(gca,'layer','top');
    ylabel('Depth (ft)');
    axis ij;
    ylim([100 700]);  % From simple script
    xlim([analysis_start analysis_end]);
    xlabel('Date Time UTC');
    title(sprintf('DAS Waterfall - Test %s', upper(test_label)));
    
    % Plot strain rate at representative channel
    subplot(2,1,2);
    plot(das_data.time_array, das_data.smoothed_data(:, das_data.pumping_zone.channel_idx));
    xlim([analysis_start analysis_end]);
    ylabel('Displacement Rate (nm/s)');
    xlabel('Date Time UTC');
    title(sprintf('Representative Channel (%.0f ft)', das_data.pumping_zone.channel_depth_ft));
    grid on;
    
    % Save if enabled
    if plot_results.save_enabled
        filename = sprintf('test_%s_das_analysis.png', test_label);
        filepath = fullfile(save_dir, filename);
        saveas(gcf, filepath);
        plot_results.figures_created{end+1} = filename;
        fprintf('  Saved: %s\n', filename);
    end
    
    % Store figure handle
    if ~isfield(plot_results, 'figures')
        plot_results.figures = struct();
    end
    plot_results.figures.(test_label).das_waterfall = fig_num;
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