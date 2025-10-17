function plot_strain_head_correlation(correlation_results, config)
    %PLOT_STRAIN_HEAD_CORRELATION Create overlay plot of strain rate vs head data
    %
    % Inputs:
    %   correlation_results - Results from analyze_strain_head_correlation
    %   config             - Configuration structure
    
    test_labels = correlation_results.tests;
    
    for i = 1:length(test_labels)
        test_label = test_labels{i};
        
        if ~isfield(correlation_results, test_label)
            continue;
        end
        
        data = correlation_results.(test_label);
        
        % Create figure
        figure('Name', sprintf('Strain Rate vs Head Data Correlation - %s', upper(test_label)), ...
               'Position', [100, 100, 1200, 800]);
        
        % Subplot 1: Time series overlay
        subplot(2,2,1);
        yyaxis left;
        plot(data.time, data.strain_rate, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Strain Rate');
        ylabel('Strain Rate (nm/s)');
        ylim([min(data.strain_rate)*1.1, max(data.strain_rate)*1.1]);
        
        yyaxis right;
        plot(data.time, data.head_rate, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Head Drawdown Rate');
        ylabel('Head Drawdown Rate (ft/min)');
        ylim([min(data.head_rate)*1.1, max(data.head_rate)*1.1]);
        
        xlabel('Time');
        title('Strain Rate vs Head Data Overlay');
        legend('Location', 'best');
        grid on;
        
        % Mark signal onsets
        hold on;
        xline(data.strain_onset_time, 'b--', 'LineWidth', 2, 'DisplayName', 'Strain Onset');
        xline(data.head_onset_time, 'r--', 'LineWidth', 2, 'DisplayName', 'Head Onset');
        hold off;
        
        % Subplot 2: Scatter plot with correlation
        subplot(2,2,2);
        scatter(data.strain_rate, data.head_rate, 20, 'b', 'filled', 'Alpha', 0.6);
        xlabel('Strain Rate (nm/s)');
        ylabel('Head Drawdown Rate (ft/min)');
        title(sprintf('Correlation: r = %.3f', data.correlation_coefficient));
        grid on;
        
        % Add trend line
        hold on;
        p = polyfit(data.strain_rate, data.head_rate, 1);
        x_trend = linspace(min(data.strain_rate), max(data.strain_rate), 100);
        y_trend = polyval(p, x_trend);
        plot(x_trend, y_trend, 'r-', 'LineWidth', 2, 'DisplayName', 'Linear Fit');
        legend('Data Points', 'Linear Fit', 'Location', 'best');
        hold off;
        
        % Subplot 3: Signal onset analysis
        subplot(2,2,3);
        plot(data.time, data.strain_rate, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Strain Rate');
        hold on;
        plot(data.time, data.head_rate, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Head Rate');
        xline(data.strain_onset_time, 'b--', 'LineWidth', 2, 'DisplayName', 'Strain Onset');
        xline(data.head_onset_time, 'r--', 'LineWidth', 2, 'DisplayName', 'Head Onset');
        xlabel('Time');
        ylabel('Rate');
        title('Signal Onset Detection');
        legend('Location', 'best');
        grid on;
        hold off;
        
        % Subplot 4: Correlation statistics
        subplot(2,2,4);
        text(0.1, 0.8, sprintf('Correlation Coefficient: %.3f', data.correlation_coefficient), 'FontSize', 12);
        text(0.1, 0.6, sprintf('Strain Onset: %s', data.strain_onset_time), 'FontSize', 12);
        text(0.1, 0.4, sprintf('Head Onset: %s', data.head_onset_time), 'FontSize', 12);
        text(0.1, 0.2, sprintf('Onset Delay: %.2f seconds', seconds(data.onset_delay)), 'FontSize', 12);
        axis off;
        title('Correlation Statistics');
        
        % Save if enabled
        if isfield(config, 'save_charts') && config.save_charts
            save_dir = fullfile(config.base_input, '_analysis_charts');
            if ~exist(save_dir, 'dir')
                mkdir(save_dir);
            end
            filename = fullfile(save_dir, sprintf('strain_head_correlation_%s.png', test_label));
            saveas(gcf, filename);
            fprintf('Saved correlation plot: %s\n', filename);
        end
    end
    end