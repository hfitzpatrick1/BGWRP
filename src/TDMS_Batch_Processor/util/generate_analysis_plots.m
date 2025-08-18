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

%% Individual detailed plots for each test (4 figure types per test)
for i = 1:length(test_labels)
    test_label = test_labels{i};
    
    %% Figure Type 1: Detailed Head Data Plot
    if isfield(head_results, test_label) && isfield(head_results.(test_label), 'zones')
        figure(100 + i); % Start at 101, 102, etc.
        set(gcf, 'Position', [100 + i*50, 100, 1000, 600]);
        
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
        
        if plot_results.save_enabled
            head_filename = sprintf('test_%s_head_analysis.png', test_label);
            head_filepath = fullfile(plot_results.save_dir, head_filename);
            saveas(gcf, head_filepath);
            fprintf('✓ Saved head analysis: %s\n', head_filename);
            plot_results.figures_created{end+1} = head_filename;
        end
    end
    
    %% Figure Type 2: DAS Strain Rate with Depth Analysis
    if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
        das_data = das_results.(test_label);
        
        figure(200 + i); % Start at 201, 202, etc.
        set(gcf, 'Position', [150 + i*50, 150, 1200, 800]);
        
        subplot(2,1,1)
        % Plot strain rate vs depth (pcolor-style)
        if isfield(das_data, 'smoothed_data') && isfield(das_data, 'depth_ft') && isfield(das_data, 'time_array')
            % Create depth vs time plot
            time_subset = das_data.time_array(1:10:end); % Subsample for plotting
            data_subset = das_data.smoothed_data(1:10:end, :);
            
            [T, D] = meshgrid(datenum(time_subset), das_data.depth_ft);
            v = pcolor(T, D, data_subset');
            set(v, 'EdgeColor', 'none');
            colormap('jet');
            colorbar;
            
            % Set reasonable color limits
            data_range = prctile(data_subset(:), [5, 95]);
            if diff(data_range) > 0
                clim(data_range);
            end
            
            title(sprintf('Test %s: DAS Strain Rate vs Depth', upper(test_label)));
            xlabel('Time');
            ylabel('Depth (ft)');
            datetick('x', 'HH:MM', 'keepticks');
            
            % Mark pumping zone
            if isfield(das_data, 'pumping_zone')
                hold on;
                xlims = xlim;
                plot(xlims, [das_data.pumping_zone.min_ft, das_data.pumping_zone.min_ft], 'r-', 'LineWidth', 3);
                plot(xlims, [das_data.pumping_zone.max_ft, das_data.pumping_zone.max_ft], 'r-', 'LineWidth', 3);
                text(xlims(1) + 0.02*diff(xlims), das_data.pumping_zone.mid_ft, ...
                    sprintf('Pumping Zone\n%.0f-%.0f ft', das_data.pumping_zone.min_ft, das_data.pumping_zone.max_ft), ...
                    'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', 'white');
            end
        end
        
        subplot(2,1,2)
        % Plot single channel strain rate time series
        if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
            plot(das_data.analysis_time, das_data.analysis_strain_rate, 'b-', 'LineWidth', 2);
            title(sprintf('Test %s: Representative Channel Strain Rate (Ch %d, %.1f ft)', ...
                upper(test_label), das_data.pumping_zone.channel_idx, das_data.pumping_zone.channel_depth_ft));
            xlabel('Time');
            ylabel('Strain Rate');
            grid on;
        end
        
        if plot_results.save_enabled
            das_depth_filename = sprintf('test_%s_das_depth_analysis.png', test_label);
            das_depth_filepath = fullfile(plot_results.save_dir, das_depth_filename);
            saveas(gcf, das_depth_filepath);
            fprintf('✓ Saved DAS depth analysis: %s\n', das_depth_filename);
            plot_results.figures_created{end+1} = das_depth_filename;
        end
    end
    
    %% Figure Type 3: DAS Waterfall Plot (Simple)
    if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
        das_data = das_results.(test_label);
        if isfield(das_data, 'smoothed_data')
            figure(300 + i); % Start at 301, 302, etc.
            set(gcf, 'Position', [200 + i*50, 200, 800, 600]);
            
            % Simple waterfall plot
            imagesc(das_data.smoothed_data');
            clim([-2 2]); % Standard range from original
            colormap('jet');
            colorbar;
            title(sprintf('Test %s: DAS Raw Data Waterfall', upper(test_label)));
            xlabel('Time Sample');
            ylabel('Channel Number');
            
            if plot_results.save_enabled
                waterfall_filename = sprintf('test_%s_das_waterfall.png', test_label);
                waterfall_filepath = fullfile(plot_results.save_dir, waterfall_filename);
                saveas(gcf, waterfall_filepath);
                fprintf('✓ Saved DAS waterfall: %s\n', waterfall_filename);
                plot_results.figures_created{end+1} = waterfall_filename;
            end
        end
    end
    
    %% Figure Type 4: Combined Head + DAS Comparison
    if (isfield(head_results, test_label) && isfield(head_results.(test_label), 'zones')) && ...
       (isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error'))
        
        figure(400 + i); % Start at 401, 402, etc.
        set(gcf, 'Position', [250 + i*50, 250, 1200, 800]);
        
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
        
        if plot_results.save_enabled
            combined_filename = sprintf('test_%s_combined_analysis.png', test_label);
            combined_filepath = fullfile(plot_results.save_dir, combined_filename);
            saveas(gcf, combined_filepath);
            fprintf('✓ Saved combined analysis: %s\n', combined_filename);
            plot_results.figures_created{end+1} = combined_filename;
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