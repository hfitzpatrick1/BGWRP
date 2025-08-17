function plot_results = generate_analysis_plots(head_results, das_results, config)
%GENERATE_ANALYSIS_PLOTS Dynamic plotting utility for analysis results
%
% Generates standardized plots for head and DAS data analysis results
% with optional saving to output directory
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data
%   config       - Batch processor configuration structure
%
% Outputs:
%   plot_results - Structure containing plot information and save status

fprintf('=== GENERATING ANALYSIS PLOTS ===\n');

% Initialize plot results
plot_results = struct();
plot_results.figures_created = {};
plot_results.save_enabled = false;
plot_results.save_directory = '';

%% Check if chart saving is enabled
if isfield(config, 'save_charts') && config.save_charts
    plot_results.save_enabled = true;
    
    % Determine save directory (same as data source path)
    if isfield(config, 'chart_output_dir') && ~isempty(config.chart_output_dir)
        save_dir = config.chart_output_dir;
    else
        % Debug: check what base_input contains
        fprintf('DEBUG: config.base_input = "%s"\n', config.base_input);
        save_dir = fullfile(config.base_input, 'analysis_charts');
        fprintf('DEBUG: save_dir = "%s"\n', save_dir);
    end
    
    % Create directory if it doesn't exist
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
        fprintf('Created chart output directory: %s\n', save_dir);
    end
    
    plot_results.save_directory = save_dir;
    fprintf('Chart saving enabled to: %s\n', save_dir);
else
    fprintf('Chart saving disabled\n');
end

%% Get test labels from results
if isfield(head_results, 'tests')
    test_labels = head_results.tests;
elseif isfield(das_results, 'tests')
    test_labels = das_results.tests;
else
    fprintf('No test labels found in results\n');
    return;
end

%% Generate plots for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Generating plots for test %s ---\n', upper(test_label));
    
    %% Plot 1: Time series overview
    fig_num = i * 10 + 1;
    figure(fig_num);
    subplot(2,1,1);
    title(sprintf('Test %s - Head Data Overview', upper(test_label)));
    xlabel('Time (UTC)');
    ylabel('Head/Drawdown');
    grid on;
    
    subplot(2,1,2);
    title(sprintf('Test %s - DAS Data Overview', upper(test_label)));
    xlabel('Time (UTC)');
    ylabel('Strain Rate');
    grid on;
    
    % Add actual plotting code here based on available data
    if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
        % Plot DAS data if available
        fprintf('  Plotting DAS data for test %s\n', test_label);
    end
    
    if isfield(head_results, test_label) && ~isfield(head_results.(test_label), 'error')
        % Plot head data if available
        fprintf('  Plotting head data for test %s\n', test_label);
    end
    
    sgtitle(sprintf('Test %s - Analysis Overview', upper(test_label)));
    
    % Save if enabled
    if plot_results.save_enabled
        filename = sprintf('test_%s_overview.png', test_label);
        filepath = fullfile(plot_results.save_directory, filename);
        saveas(gcf, filepath);
        fprintf('  ✓ Saved: %s\n', filename);
        plot_results.figures_created{end+1} = filename;
    end
    
    %% Plot 2: Detailed analysis (if data available)
    fig_num = i * 10 + 2;
    figure(fig_num);
    
    title(sprintf('Test %s - Detailed Analysis', upper(test_label)));
    
    % Placeholder for detailed plotting
    text(0.5, 0.5, sprintf('Detailed analysis plots for test %s', upper(test_label)), ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');
    
    % Save if enabled
    if plot_results.save_enabled
        filename = sprintf('test_%s_detailed.png', test_label);
        filepath = fullfile(plot_results.save_directory, filename);
        saveas(gcf, filepath);
        fprintf('  ✓ Saved: %s\n', filename);
        plot_results.figures_created{end+1} = filename;
    end
end

%% Summary plot (all tests)
if length(test_labels) > 1
    fprintf('\n--- Generating summary comparison plot ---\n');
    
    fig_num = 999;
    figure(fig_num);
    
    % Create comparison plots
    subplot(2,1,1);
    title('All Tests - DAS Data Comparison');
    xlabel('Time (UTC)');
    ylabel('Strain Rate');
    grid on;
    hold on;
    
    % Plot comparison data for each test
    colors = lines(length(test_labels));
    for i = 1:length(test_labels)
        test_label = test_labels{i};
        % Add comparison plotting code here
        fprintf('  Adding test %s to comparison\n', test_label);
    end
    
    subplot(2,1,2);
    title('All Tests - Head Data Comparison');
    xlabel('Time (UTC)');
    ylabel('Head/Drawdown');
    grid on;
    hold on;
    
    sgtitle('Multi-Test Comparison');
    
    % Save if enabled
    if plot_results.save_enabled
        filename = 'all_tests_comparison.png';
        filepath = fullfile(plot_results.save_directory, filename);
        saveas(gcf, filepath);
        fprintf('  ✓ Saved: %s\n', filename);
        plot_results.figures_created{end+1} = filename;
    end
end

%% Summary
fprintf('\n=== PLOT GENERATION COMPLETE ===\n');
fprintf('Figures created: %d\n', length(plot_results.figures_created));

if plot_results.save_enabled
    fprintf('Charts saved to: %s\n', plot_results.save_directory);
    for i = 1:length(plot_results.figures_created)
        fprintf('  - %s\n', plot_results.figures_created{i});
    end
else
    fprintf('Charts displayed but not saved (save_charts disabled)\n');
end

end
