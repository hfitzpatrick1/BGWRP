function plot_results = generate_analysis_plots(head_results, das_results, config)
%GENERATE_ANALYSIS_PLOTS Create analysis plots from head and DAS results
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data  
%   config       - Batch processor configuration
%
% Outputs:
%   plot_results - Structure containing plot metadata

fprintf('=== GENERATING ANALYSIS PLOTS ===\n');

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

%% Main analysis figure
if ~isempty(test_labels)
    figure(1);
    set(gcf, 'Position', [100, 100, 1200, 800]);
    
    subplot_idx = 1;
    for i = 1:length(test_labels)
        test_label = test_labels{i};
        fprintf('\n--- Generating plots for test %s ---\n', upper(test_label));
        
        % Plot DAS data if available
        if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
            fprintf('  Plotting DAS data for test %s\n', test_label);
            
            subplot(length(test_labels), 2, subplot_idx);
            
            % Plot strain rate for representative channel
            das_data = das_results.(test_label);
            if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
                plot(das_data.analysis_time, das_data.analysis_strain_rate, 'b-', 'LineWidth', 2);
                title(sprintf('Test %s: DAS Strain Rate (Ch %d, %.1f ft)', ...
                    upper(test_label), das_data.pumping_zone.channel_idx, das_data.pumping_zone.channel_depth_ft));
                xlabel('Time');
                ylabel('Strain Rate');
                grid on;
                
                % Add pumping zone info
                if isfield(das_data, 'pumping_zone')
                    zone_text = sprintf('Pumping Zone: %.0f-%.0f ft', ...
                        das_data.pumping_zone.min_ft, das_data.pumping_zone.max_ft);
                    text(0.02, 0.98, zone_text, 'Units', 'normalized', ...
                        'VerticalAlignment', 'top', 'BackgroundColor', 'white');
                end
            end
            subplot_idx = subplot_idx + 1;
        end
        
        % Plot head data if available
        if isfield(head_results, test_label) && isfield(head_results.(test_label), 'zones')
            fprintf('  Plotting head data for test %s\n', test_label);
            
            subplot(length(test_labels), 2, subplot_idx);
            hold on;
            
            zones = fieldnames(head_results.(test_label).zones);
            colors = lines(length(zones));
            
            for j = 1:length(zones)
                zone_name = zones{j};
                zone_data = head_results.(test_label).zones.(zone_name);
                
                if isfield(zone_data, 'recovery_time') && isfield(zone_data, 'recovery_rate_ms')
                    if ~isempty(zone_data.recovery_time) && ~isempty(zone_data.recovery_rate_ms)
                        plot(zone_data.recovery_time, zone_data.recovery_rate_ms * 1000, ...
                            'Color', colors(j,:), 'LineWidth', 2, ...
                            'DisplayName', sprintf('%s (%.1f ft)', zone_name, zone_data.Depthft));
                    end
                end
            end
            
            title(sprintf('Test %s: Head Recovery Rates', upper(test_label)));
            xlabel('Time');
            ylabel('Recovery Rate (mm/s)');
            legend('Location', 'best');
            grid on;
            
            subplot_idx = subplot_idx + 1;
        end
    end
    
    % Save main figure if enabled
    if plot_results.save_enabled
        main_filename = 'recovery_analysis_overview.png';
        main_filepath = fullfile(plot_results.save_dir, main_filename);
        saveas(gcf, main_filepath);
        fprintf('✓ Saved main analysis figure: %s\n', main_filename);
        plot_results.figures_created{end+1} = main_filename;
    end
end

%% Individual detailed plots for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    
    % Create detailed DAS waterfall plot
    if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
        das_data = das_results.(test_label);
        if isfield(das_data, 'smoothed_data') && isfield(das_data, 'depth_ft')
            figure(10 + i);
            set(gcf, 'Position', [200 + i*50, 200, 800, 600]);
            
            % Create waterfall plot of DAS data
            imagesc(das_data.smoothed_data');
            colormap('jet');
            colorbar;
            title(sprintf('Test %s: DAS Data Waterfall', upper(test_label)));
            xlabel('Time Sample');
            ylabel('Channel');
            
            % Mark pumping zone
            if isfield(das_data, 'pumping_zone')
                hold on;
                zone_channels = find(das_data.depth_ft >= das_data.pumping_zone.min_ft & ...
                                   das_data.depth_ft <= das_data.pumping_zone.max_ft);
                if ~isempty(zone_channels)
                    plot([1, size(das_data.smoothed_data, 1)], [min(zone_channels), min(zone_channels)], 'r-', 'LineWidth', 2);
                    plot([1, size(das_data.smoothed_data, 1)], [max(zone_channels), max(zone_channels)], 'r-', 'LineWidth', 2);
                end
            end
            
            if plot_results.save_enabled
                waterfall_filename = sprintf('test_%s_das_waterfall.png', test_label);
                waterfall_filepath = fullfile(plot_results.save_dir, waterfall_filename);
                saveas(gcf, waterfall_filepath);
                fprintf('✓ Saved DAS waterfall: %s\n', waterfall_filename);
                plot_results.figures_created{end+1} = waterfall_filename;
            end
        end
    end
end

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

end