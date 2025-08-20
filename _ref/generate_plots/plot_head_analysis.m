function figure_handle = plot_head_analysis(head_results, test_label, test_index, plot_config, config)
%PLOT_HEAD_ANALYSIS Create detailed head data analysis plot (Figure Type 1)
%
% Inputs:
%   head_results - Results from analyze_head_data
%   test_label   - Test label string
%   test_index   - Index for figure numbering
%   plot_config  - Plot configuration structure
%   config       - Batch processor configuration (for analysis windows)
%
% Outputs:
%   figure_handle - Handle to created figure, or [] if no data

figure_handle = [];

%% Figure Type 1: Detailed Head Data Plot
if isfield(head_results, test_label) && isfield(head_results.(test_label), 'zones')
    figure_handle = figure(100 + test_index);
    set(gcf, 'Position', [100 + test_index*50, 100, 1000, 600]);
    
    subplot(2,1,1)
    % Plot raw head data for all zones
    hold on;
    zones = fieldnames(head_results.(test_label).zones);
    colors = lines(length(zones));
    
    for j = 1:length(zones)
        zone_name = zones{j};
        zone_data = head_results.(test_label).zones.(zone_name);
        
        if isfield(zone_data, 'Date') && isfield(zone_data, 'Drawdownft')
            plot(zone_data.Date, zone_data.Drawdownft, ...
                'Color', colors(j,:), 'LineWidth', 2, ...
                'DisplayName', sprintf('%s (%.1f ft)', zone_name, zone_data.Depthft));
        end
    end
    
    title(sprintf('Test %s: Raw Head Data', upper(test_label)));
    xlabel('Time');
    ylabel('Drawdown (ft)');
    legend('Location', 'best');
    grid on;
    
    subplot(2,1,2)
    % Plot recovery rates
    hold on;
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
    
    if plot_config.save_enabled
        head_filename = sprintf('test_%s_head_analysis.png', test_label);
        head_filepath = fullfile(plot_config.save_dir, head_filename);
        saveas(gcf, head_filepath);
        fprintf('✓ Saved head analysis: %s\n', head_filename);
        plot_config.figures_created{end+1} = head_filename;
    end
end

end
