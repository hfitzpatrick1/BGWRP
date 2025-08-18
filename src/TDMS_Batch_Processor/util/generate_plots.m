function plot_results = generate_plots(head_results, das_results, config)
%GENERATE_PLOTS Create analysis plots using modular helper functions
%
% This function uses individual plot helper functions for better maintainability.
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data  
%   config       - Batch processor configuration
%
% Outputs:
%   plot_results - Structure containing plot metadata

fprintf('=== GENERATING ANALYSIS PLOTS (MODULAR) ===\n');

% Add plot helper functions to path
plot_helper_dir = fullfile(fileparts(mfilename('fullpath')), 'generate_plots');
addpath(plot_helper_dir);

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
        save_dir = fullfile(config.base_input, 'analysis_charts');
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
if isfield(head_results, 'tests')
    test_labels = head_results.tests;
elseif ~isempty(fieldnames(head_results))
    test_labels = fieldnames(head_results);
    test_labels = test_labels(~strcmp(test_labels, 'tests') & ~strcmp(test_labels, 'timing'));
end

%% Create main overview plot
fprintf('\n--- Creating main overview plot ---\n');
main_figure = plot_main_overview(head_results, das_results, test_labels, plot_results, config);

%% Create individual detailed plots for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Generating detailed plots for test %s ---\n', upper(test_label));
    
    % Plot Type 1: Detailed Head Data Plot
    head_figure = plot_head_analysis(head_results, test_label, i, plot_results, config);
    
    % Plot Type 2: DAS Strain Rate with Depth Analysis
    das_depth_figure = plot_das_depth_analysis(das_results, test_label, i, plot_results, config);
    
    % Plot Type 3: DAS Waterfall Plot
    waterfall_figure = plot_das_waterfall(das_results, test_label, i, plot_results, config);
    
    % Plot Type 4: Combined Head + DAS Comparison
    combined_figure = plot_combined_analysis(head_results, das_results, test_label, i, plot_results, config);
    
    % Store figure handles (optional)
    if ~isfield(plot_results, 'figures')
        plot_results.figures = struct();
    end
    plot_results.figures.(test_label).head = head_figure;
    plot_results.figures.(test_label).das_depth = das_depth_figure;
    plot_results.figures.(test_label).waterfall = waterfall_figure;
    plot_results.figures.(test_label).combined = combined_figure;
end

%% Summary
fprintf('\n=== PLOT GENERATION COMPLETE ===\n');
fprintf('Figures created: %d\n', length(plot_results.figures_created));

if plot_results.save_enabled && ~isempty(plot_results.figures_created)
    fprintf('Charts saved to: %s\n', plot_results.save_dir);
    for i = 1:length(plot_results.figures_created)
        fprintf('  - %s\n', plot_results.figures_created{i});
    end
else
    fprintf('Charts displayed but not saved (save_charts disabled)\n');
end

% Clean up path
rmpath(plot_helper_dir);

end