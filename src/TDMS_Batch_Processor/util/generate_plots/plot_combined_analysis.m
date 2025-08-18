function figure_handle = plot_combined_analysis(head_results, das_results, test_label, test_index, plot_config)
%PLOT_COMBINED_ANALYSIS Create combined head+DAS comparison plot (Figure Type 4)
%
% Inputs:
%   head_results - Results from analyze_head_data
%   das_results  - Results from analyze_das_data
%   test_label   - Test label string
%   test_index   - Index for figure numbering
%   plot_config  - Plot configuration structure
%
% Outputs:
%   figure_handle - Handle to created figure, or [] if no data

figure_handle = [];

%% Figure Type 4: Combined Head + DAS Comparison
if (isfield(head_results, test_label) && isfield(head_results.(test_label), 'zones')) && ...
   (isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error'))
    
    figure_handle = figure(400 + test_index);
    set(gcf, 'Position', [250 + test_index*50, 250, 1200, 800]);
    
    subplot(3,1,1)
    % Head recovery rates
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
    ylabel('Recovery Rate (mm/s)');
    legend('Location', 'best');
    grid on;
    
    subplot(3,1,2)
    % DAS strain rate
    das_data = das_results.(test_label);
    if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
        plot(das_data.analysis_time, das_data.analysis_strain_rate, 'b-', 'LineWidth', 2);
        
        % Set explicit time limits to analysis window
        xlim([min(das_data.analysis_time), max(das_data.analysis_time)]);
        
        title(sprintf('DAS Strain Rate (Ch %d, %.1f ft)', ...
            das_data.pumping_zone.channel_idx, das_data.pumping_zone.channel_depth_ft));
        ylabel('Strain Rate');
        grid on;
    end
    
    subplot(3,1,3)
    % Combined comparison plot (normalized)
    hold on;
    
    % Get head data for normalization and plotting
    zones = fieldnames(head_results.(test_label).zones);
    head_colors = lines(length(zones));
    
    % Initialize variables to prevent undefined errors
    head_normalized_first = [];
    zone_data_first = [];
    
    % Plot normalized head recovery rates
    for j = 1:length(zones)
        zone_name = zones{j};
        zone_data = head_results.(test_label).zones.(zone_name);
        
        if isfield(zone_data, 'recovery_time') && isfield(zone_data, 'recovery_rate_ms')
            if ~isempty(zone_data.recovery_time) && ~isempty(zone_data.recovery_rate_ms)
                % Normalize head data to 0-1 range
                head_data = zone_data.recovery_rate_ms * 1000; % Convert to mm/s
                head_normalized = (head_data - min(head_data)) / (max(head_data) - min(head_data));
                if any(isnan(head_normalized)) || (max(head_data) - min(head_data)) == 0
                    head_normalized = zeros(size(head_data)); % Handle case where all values are the same
                end
                
                % Store first zone's data for correlation analysis
                if j == 1
                    head_normalized_first = head_normalized;
                    zone_data_first = zone_data;
                end
                
                plot(zone_data.recovery_time, head_normalized, '--', ...
                    'Color', head_colors(j,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('Head %s (norm)', zone_name));
            end
        end
    end
    
    % Plot normalized DAS strain rate
    das_data = das_results.(test_label);
    das_normalized = [];
    if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
        % Normalize DAS data to 0-1 range
        das_strain = das_data.analysis_strain_rate;
        if max(das_strain) - min(das_strain) > 0
            das_normalized = (das_strain - min(das_strain)) / (max(das_strain) - min(das_strain));
        else
            das_normalized = zeros(size(das_strain)); % Handle case where all values are the same
        end
        
        plot(das_data.analysis_time, das_normalized, 'b-', 'LineWidth', 2, ...
            'DisplayName', sprintf('DAS Ch%d (norm)', das_data.pumping_zone.channel_idx));
    end
    
    % Calculate and display cross-correlation if both datasets exist
    if ~isempty(head_normalized_first) && ~isempty(das_normalized) && ~isempty(zone_data_first)
        if isfield(zone_data_first, 'recovery_time') && ~isempty(zone_data_first.recovery_time)
            % Interpolate to common time grid for correlation
            common_time = das_data.analysis_time;
            if length(zone_data_first.recovery_time) > 1 && length(common_time) > 1
                try
                    head_interp = interp1(zone_data_first.recovery_time, head_normalized_first, common_time, 'linear', 'extrap');
                    
                    % Calculate correlation coefficient
                    valid_idx = ~isnan(head_interp) & ~isnan(das_normalized) & isfinite(head_interp) & isfinite(das_normalized);
                    if sum(valid_idx) > 10 % Need enough points for meaningful correlation
                        corr_coef = corrcoef(head_interp(valid_idx), das_normalized(valid_idx));
                        if size(corr_coef, 1) >= 2 && size(corr_coef, 2) >= 2
                            correlation = corr_coef(1,2);
                            
                            % Add correlation text
                            text(0.02, 0.95, sprintf('Correlation: %.3f', correlation), ...
                                'Units', 'normalized', 'VerticalAlignment', 'top', ...
                                'BackgroundColor', 'white', 'FontWeight', 'bold');
                        end
                    end
                catch ME
                    fprintf('Warning: Correlation calculation failed: %s\n', ME.message);
                end
            end
        end
    end
    
    title(sprintf('Test %s: Normalized Combined Analysis', upper(test_label)));
    xlabel('Time');
    ylabel('Normalized Response (0-1)');
    legend('Location', 'best');
    grid on;
    
    if plot_config.save_enabled
        combined_filename = sprintf('test_%s_combined_analysis.png', test_label);
        combined_filepath = fullfile(plot_config.save_dir, combined_filename);
        saveas(gcf, combined_filepath);
        fprintf('✓ Saved combined analysis: %s\n', combined_filename);
        plot_config.figures_created{end+1} = combined_filename;
    end
end

end
