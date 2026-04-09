function plot_storage_analysis(storage_results, config)
%PLOT_STORAGE_ANALYSIS Create plots for storage parameter analysis
%
% Inputs:
%   storage_results - Results from analyze_storage_parameters
%   config         - Configuration structure

console_log('\n=== PLOTTING STORAGE ANALYSIS ===\n');
console_log('Storage results fields: %s\n', strjoin(fieldnames(storage_results), ', '));

test_labels = storage_results.tests;
console_log('Test labels: %s\n', strjoin(test_labels, ', '));

for i = 1:length(test_labels)
    test_label = test_labels{i};
    
    % Check for z4 and z5 results
    z4_key = sprintf('%s_z4', test_label);
    z5_key = sprintf('%s_z5', test_label);
    
    has_z4 = isfield(storage_results, z4_key);
    has_z5 = isfield(storage_results, z5_key);
    
    console_log('  Checking for %s: has_z4=%d, has_z5=%d\n', test_label, has_z4, has_z5);
    
    if ~has_z4 && ~has_z5
        console_log('  No z4 or z5 results found for %s, skipping plot\n', test_label);
        continue;
    end
    
    % Create figure with 2x2 subplots
    figure('Name', sprintf('Storage Parameter Analysis - %s', upper(test_label)), ...
           'Position', [50, 50, 1400, 900]);
    
    % Subplot 1: Cross-plot for z4
    if has_z4
        subplot(2,2,1);
        data_z4 = storage_results.(z4_key);
        
        % Scatter plot
        scatter(data_z4.window_head, data_z4.window_das, 40, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
        hold on;
        
        % Linear fit line
        x_fit = linspace(min(data_z4.window_head), max(data_z4.window_head), 100);
        y_fit = data_z4.slope * x_fit + data_z4.intercept;
        plot(x_fit, y_fit, 'r-', 'LineWidth', 2.5);
        
        xlabel('Drawdown Rate z4 (ft/min)', 'FontSize', 12);
        ylabel('DAS Strain Rate (nm/s)', 'FontSize', 12);
        title(sprintf('z4: Slope = %.3f, R² = %.3f', data_z4.slope, data_z4.r_squared), 'FontSize', 13);
        grid on;
        legend('Data Points', 'Linear Fit', 'Location', 'best');
        hold off;
    end
    
    % Subplot 2: Cross-plot for z5
    if has_z5
        subplot(2,2,2);
        data_z5 = storage_results.(z5_key);
        
        % Scatter plot
        scatter(data_z5.window_head, data_z5.window_das, 40, 'g', 'filled', 'MarkerFaceAlpha', 0.6);
        hold on;
        
        % Linear fit line
        x_fit = linspace(min(data_z5.window_head), max(data_z5.window_head), 100);
        y_fit = data_z5.slope * x_fit + data_z5.intercept;
        plot(x_fit, y_fit, 'r-', 'LineWidth', 2.5);
        
        xlabel('Drawdown Rate z5 (ft/min)', 'FontSize', 12);
        ylabel('DAS Strain Rate (nm/s)', 'FontSize', 12);
        title(sprintf('z5: Slope = %.3f, R² = %.3f', data_z5.slope, data_z5.r_squared), 'FontSize', 13);
        grid on;
        legend('Data Points', 'Linear Fit', 'Location', 'best');
        hold off;
    end
    
    % Subplot 3: Time series showing correlation window
    subplot(2,2,3);
    if has_z4 && has_z5
        % Plot both zones
        yyaxis left;
        plot(data_z4.time, data_z4.head_drawdown_rate, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.5, 'DisplayName', 'Drawdown Rate z4');
        hold on;
        plot(data_z5.time, data_z5.head_drawdown_rate, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.5, 'DisplayName', 'Drawdown Rate z5');
        
        % Highlight correlation windows
        plot(data_z4.window_time, data_z4.window_head, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 3, 'DisplayName', 'z4 window');
        plot(data_z5.window_time, data_z5.window_head, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 3, 'DisplayName', 'z5 window');
        ylabel('Drawdown Rate (ft/min)', 'FontSize', 12);
        
        yyaxis right;
        plot(data_z4.time, data_z4.das_strain_rate, 'k-', 'LineWidth', 1.5, 'DisplayName', 'DAS Strain Rate');
        plot(data_z4.window_time, data_z4.window_das, 'k-', 'LineWidth', 3, 'DisplayName', 'DAS window');
        ylabel('DAS Strain Rate (nm/s)', 'FontSize', 12);
        hold off;
    elseif has_z4
        yyaxis left;
        plot(data_z4.time, data_z4.head_drawdown_rate, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.5, 'DisplayName', 'Drawdown Rate z4');
        hold on;
        plot(data_z4.window_time, data_z4.window_head, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 3, 'DisplayName', 'z4 window');
        ylabel('Drawdown Rate (ft/min)', 'FontSize', 12);
        
        yyaxis right;
        plot(data_z4.time, data_z4.das_strain_rate, 'k-', 'LineWidth', 1.5, 'DisplayName', 'DAS Strain Rate');
        plot(data_z4.window_time, data_z4.window_das, 'k-', 'LineWidth', 3, 'DisplayName', 'DAS window');
        ylabel('DAS Strain Rate (nm/s)', 'FontSize', 12);
        hold off;
    else
        yyaxis left;
        plot(data_z5.time, data_z5.head_drawdown_rate, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.5, 'DisplayName', 'Drawdown Rate z5');
        hold on;
        plot(data_z5.window_time, data_z5.window_head, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 3, 'DisplayName', 'z5 window');
        ylabel('Drawdown Rate (ft/min)', 'FontSize', 12);
        
        yyaxis right;
        plot(data_z5.time, data_z5.das_strain_rate, 'k-', 'LineWidth', 1.5, 'DisplayName', 'DAS Strain Rate');
        plot(data_z5.window_time, data_z5.window_das, 'k-', 'LineWidth', 3, 'DisplayName', 'DAS window');
        ylabel('DAS Strain Rate (nm/s)', 'FontSize', 12);
        hold off;
    end
    
    xlabel('Date Time UTC', 'FontSize', 12);
    title('Correlation Window Selection', 'FontSize', 13);
    legend('Location', 'best', 'FontSize', 10);
    grid on;
    
    % Subplot 4: Storage parameter summary
    subplot(2,2,4);
    axis off;
    
    y_pos = 0.9;
    text(0.1, y_pos, sprintf('Storage Parameter Results - %s', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');
    y_pos = y_pos - 0.1;
    
    if has_z4
        text(0.1, y_pos, 'Zone z4:', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.4940 0.1840 0.5560]);
        y_pos = y_pos - 0.07;
        text(0.15, y_pos, sprintf('S_s: %.2e 1/m, S: %.2e (b=%.0fm)', data_z4.Ss_estimate, data_z4.S_storativity, data_z4.aquifer_thickness_m), 'FontSize', 10);
        y_pos = y_pos - 0.05;
        text(0.15, y_pos, sprintf('R²: %.4f, Slope: %.3f', data_z4.r_squared, data_z4.slope), 'FontSize', 10);
        if ~isnan(data_z4.T_traditional_ft2_day)
            y_pos = y_pos - 0.05;
            text(0.15, y_pos, sprintf('T: %.0f ft²/day, K: %.1f ft/day', data_z4.T_traditional_ft2_day, data_z4.K_traditional_ft_day), 'FontSize', 10);
        end
        y_pos = y_pos - 0.08;
    end
    
    if has_z5
        text(0.1, y_pos, 'Zone z5:', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.4660 0.6740 0.1880]);
        y_pos = y_pos - 0.07;
        text(0.15, y_pos, sprintf('S_s: %.2e 1/m, S: %.2e (b=%.0fm)', data_z5.Ss_estimate, data_z5.S_storativity, data_z5.aquifer_thickness_m), 'FontSize', 10);
        y_pos = y_pos - 0.05;
        text(0.15, y_pos, sprintf('R²: %.4f, Slope: %.3f', data_z5.r_squared, data_z5.slope), 'FontSize', 10);
        if ~isnan(data_z5.T_traditional_ft2_day)
            y_pos = y_pos - 0.05;
            text(0.15, y_pos, sprintf('T: %.0f ft²/day, K: %.1f ft/day', data_z5.T_traditional_ft2_day, data_z5.K_traditional_ft_day), 'FontSize', 10);
        end
        y_pos = y_pos - 0.08;
    end
    
    % Add comparison with traditional if available
    if has_z4 && ~isnan(data_z4.S_traditional)
        text(0.1, y_pos, 'Comparison with Traditional:', 'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.06;
        text(0.15, y_pos, sprintf('Traditional S: %.2e', data_z4.S_traditional), 'FontSize', 10);
        y_pos = y_pos - 0.05;
        text(0.15, y_pos, sprintf('DAS S (z4): %.2e (%.1f%% of trad.)', data_z4.S_storativity, 100*data_z4.S_storativity/data_z4.S_traditional), 'FontSize', 10);
        y_pos = y_pos - 0.05;
        text(0.15, y_pos, sprintf('DAS S (z5): %.2e (%.1f%% of trad.)', data_z5.S_storativity, 100*data_z5.S_storativity/data_z5.S_traditional), 'FontSize', 10);
        y_pos = y_pos - 0.07;
    end
    
    text(0.1, y_pos, 'Method:', 'FontSize', 11, 'FontWeight', 'bold');
    y_pos = y_pos - 0.05;
    text(0.15, y_pos, sprintf('Biot-Willis (α): %.1f', data_z4.alpha_biot), 'FontSize', 9);
    y_pos = y_pos - 0.04;
    text(0.15, y_pos, 'α * S_s * ∂h/∂t ≈ ∂ε/∂t', 'FontSize', 9, 'FontStyle', 'italic');
    
    % Save if enabled
    if isfield(config, 'save_charts') && config.save_charts
        save_dir = fullfile(config.base_input, '_analysis_charts');
        if ~exist(save_dir, 'dir')
            mkdir(save_dir);
        end
        filename = fullfile(save_dir, sprintf('storage_analysis_%s.png', test_label));
        saveas(gcf, filename);
        console_log('Saved storage analysis plot: %s\n', filename);
    end
end

end

