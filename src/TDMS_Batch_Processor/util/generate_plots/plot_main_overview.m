function main_figure_handle = plot_main_overview(head_results, das_results, test_labels, plot_config)
%PLOT_MAIN_OVERVIEW Create main analysis overview figure (Figure 1)
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data
%   test_labels  - Cell array of test labels
%   plot_config  - Plot configuration structure
%
% Outputs:
%   main_figure_handle - Handle to created figure

%% Main analysis figure
if ~isempty(test_labels)
    main_figure_handle = figure(1);
    set(gcf, 'Position', [100, 100, 1200, 800]);
    
    subplot_idx = 1;
    for i = 1:length(test_labels)
        test_label = test_labels{i};
        fprintf('--- Generating main overview for test %s ---\n', upper(test_label));
        
        % Plot DAS data if available
        if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
            fprintf('  Plotting DAS data for test %s\n', test_label);
            
            subplot(length(test_labels), 2, subplot_idx);
            
            % Plot strain rate for representative channel
            das_data = das_results.(test_label);
            if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
                plot(das_data.analysis_time, das_data.analysis_strain_rate, 'b-', 'LineWidth', 2);
                
                % Set explicit time limits to analysis window
                xlim([min(das_data.analysis_time), max(das_data.analysis_time)]);
                
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
    if plot_config.save_enabled
        main_filename = 'recovery_analysis_overview.png';
        main_filepath = fullfile(plot_config.save_dir, main_filename);
        saveas(gcf, main_filepath);
        fprintf('✓ Saved main analysis figure: %s\n', main_filename);
        plot_config.figures_created{end+1} = main_filename;
    end
else
    main_figure_handle = [];
end

end
