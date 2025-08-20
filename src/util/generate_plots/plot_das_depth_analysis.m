function figure_handle = plot_das_depth_analysis(das_results, test_label, test_index, plot_config, config)
%PLOT_DAS_DEPTH_ANALYSIS Create DAS strain rate vs depth analysis plot (Figure Type 2)
%
% Inputs:
%   das_results - Results from analyze_das_data
%   test_label  - Test label string
%   test_index  - Index for figure numbering
%   plot_config - Plot configuration structure
%   config      - Batch processor configuration (for zone filtering)
%
% Outputs:
%   figure_handle - Handle to created figure, or [] if no data

figure_handle = [];

%% Figure Type 2: DAS Strain Rate with Depth Analysis
if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
    das_data = das_results.(test_label);
    
    figure_handle = figure(200 + test_index);
    set(gcf, 'Position', [150 + test_index*50, 150, 1200, 800]);
    
    subplot(2,1,1)
    % Plot strain rate vs depth (pcolor-style) - USE ANALYSIS WINDOW ONLY
    if isfield(das_data, 'smoothed_data') && isfield(das_data, 'depth_ft') && isfield(das_data, 'analysis_time')
        % Filter to analysis window only
        analysis_start = min(das_data.analysis_time);
        analysis_end = max(das_data.analysis_time);
        
        % Find the indices for analysis window in full data
        if isfield(das_data, 'time_array')
            analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
            time_filtered = das_data.time_array(analysis_mask);
            data_filtered = das_data.smoothed_data(analysis_mask, :);
        else
            % Fallback: use analysis data directly
            time_filtered = das_data.analysis_time;
            data_filtered = das_data.smoothed_data; % Assume already filtered
        end
        
        % Check for dataset-specific zone filtering
        dataset_name = '';
        if isfield(das_results.(test_label), 'dataset_name')
            dataset_name = das_results.(test_label).dataset_name;
        else
            % Try to infer dataset name from test_label or other sources
            if isfield(das_results.(test_label), 'data_file')
                data_file = das_results.(test_label).data_file;
                if contains(data_file, 'PT01c_Recovery')
                    dataset_name = 'PT01c_Recovery';
                elseif contains(data_file, 'PT01c_Full')
                    dataset_name = 'PT01c_Full';
                elseif contains(data_file, 'PT01a_Recovery')
                    dataset_name = 'PT01a_Recovery';
                elseif contains(data_file, 'PT01b_Recovery')
                    dataset_name = 'PT01b_Recovery';
                end
            end
        end
        
        % Keep all data for display - zone filtering is for analysis, not visualization
        plot_data_filtered = data_filtered;
        depth_ft_filtered = das_data.depth_ft;
        filtered_applied = false;
        
        % Zone filtering info for reference (but don't filter the display data)
        if ~isempty(dataset_name) && isfield(config, 'waterfall_zones') && isfield(config.waterfall_zones, dataset_name)
            zone_config = config.waterfall_zones.(dataset_name);
            fprintf('  📋 Zone config found for %s: %.0f-%.0f ft (for analysis reference)\n', dataset_name, zone_config.min_depth, zone_config.max_depth);
        end
        
        % Subsample for plotting performance
        subsample_factor = max(1, floor(length(time_filtered) / 1000)); % Limit to ~1000 points
        time_subset = time_filtered(1:subsample_factor:end);
        data_subset = plot_data_filtered(1:subsample_factor:end, :);
        
        [T, D] = meshgrid(datenum(time_subset), depth_ft_filtered);
        v = pcolor(T, D, data_subset');
        set(v, 'EdgeColor', 'none');
        colormap('jet');
        
        % Determine dataset-specific color range (from PM07_Recovery_Analysis.m)
        if contains(upper(dataset_name), 'PT01A') || contains(upper(test_label), 'A')
            color_range = [0.35 0.55];  % PT-01a range
            fprintf('  🎨 Using PT-01a color range: [%.2f %.2f]\n', color_range(1), color_range(2));
        elseif contains(upper(dataset_name), 'PT01B') || contains(upper(test_label), 'B')
            color_range = [-1.0 -0.8];  % PT-01b range
            fprintf('  🎨 Using PT-01b color range: [%.2f %.2f]\n', color_range(1), color_range(2));
        elseif contains(upper(dataset_name), 'PT01C') || contains(upper(test_label), 'C')
            color_range = [-0.2 0.1];   % PT-01c range
            fprintf('  🎨 Using PT-01c color range: [%.2f %.2f]\n', color_range(1), color_range(2));
        else
            % Fallback to percentile-based range for unknown datasets
            color_range = prctile(data_subset(:), [5, 95]);
            if diff(color_range) <= 0
                color_range = [-2 2];  % Default range
            end
            fprintf('  🎨 Using data-based color range: [%.2f %.2f]\n', color_range(1), color_range(2));
        end
        
        c = colorbar;
        c.Ruler.TickLabelFormat = '%g nm/s';
        clim(color_range);
        
        % Set explicit time limits to analysis window
        xlim([datenum(analysis_start), datenum(analysis_end)]);
        
        % Update title to show zone info if configured
        if ~isempty(dataset_name) && isfield(config, 'waterfall_zones') && isfield(config.waterfall_zones, dataset_name)
            title_suffix = sprintf(' (Analysis Zone: %.0f-%.0f ft)', zone_config.min_depth, zone_config.max_depth);
        else
            title_suffix = '';
        end
        title(sprintf('Test %s: DAS Strain Rate vs Depth (Analysis Window)%s', upper(test_label), title_suffix));
        xlabel('Time');
        ylabel('Depth (ft)');
        datetick('x', 'HH:MM', 'keepticks');
        
        % Always use configured display bounds to show full context
        if isfield(config, 'waterfall_display_bounds')
            display_min_depth = config.waterfall_display_bounds.min_depth;
            display_max_depth = config.waterfall_display_bounds.max_depth;
            fprintf('  📏 Using configured display bounds: %.0f-%.0f ft\n', display_min_depth, display_max_depth);
        else
            % Fallback to original analysis defaults
            display_min_depth = 100;
            display_max_depth = 665;
            fprintf('  📏 Using default display bounds: %.0f-%.0f ft\n', display_min_depth, display_max_depth);
        end
        ylim([display_min_depth display_max_depth]);
        
        % Mark pumping zone (only if visible in display depth range)
        if isfield(das_data, 'pumping_zone')
            % Use configured display bounds for visibility check
            zone_min = das_data.pumping_zone.min_ft;
            zone_max = das_data.pumping_zone.max_ft;
            
            % Only show markers if they're within the display depth range
            if zone_min <= display_max_depth && zone_max >= display_min_depth
                hold on;
                xlims = xlim;
                
                % Only plot zone lines that are within display range
                if zone_min >= display_min_depth && zone_min <= display_max_depth
                    plot(xlims, [zone_min, zone_min], 'r-', 'LineWidth', 3);
                end
                if zone_max >= display_min_depth && zone_max <= display_max_depth
                    plot(xlims, [zone_max, zone_max], 'r-', 'LineWidth', 3);
                end
                
                % Place text at zone mid-point if visible, otherwise at display edge
                text_depth = das_data.pumping_zone.mid_ft;
                if text_depth < display_min_depth
                    text_depth = display_min_depth + 0.1 * (display_max_depth - display_min_depth);
                elseif text_depth > display_max_depth
                    text_depth = display_max_depth - 0.1 * (display_max_depth - display_min_depth);
                end
                
                text(xlims(1) + 0.02*diff(xlims), text_depth, ...
                    sprintf('Pumping Zone\n%.0f-%.0f ft', zone_min, zone_max), ...
                    'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', 'white');
            end
        end
    end
    
    subplot(2,1,2)
    % Plot single channel strain rate time series
    if isfield(das_data, 'analysis_time') && isfield(das_data, 'analysis_strain_rate')
        plot(das_data.analysis_time, das_data.analysis_strain_rate, 'b-', 'LineWidth', 2);
        
        % Set explicit time limits to analysis window
        xlim([min(das_data.analysis_time), max(das_data.analysis_time)]);
        
        title(sprintf('Test %s: Representative Channel Strain Rate (Ch %d, %.1f ft)', ...
            upper(test_label), das_data.pumping_zone.channel_idx, das_data.pumping_zone.channel_depth_ft));
        xlabel('Time');
        ylabel('Strain Rate');
        grid on;
    end
    
    if plot_config.save_enabled
        das_depth_filename = sprintf('test_%s_das_depth_analysis.png', test_label);
        das_depth_filepath = fullfile(plot_config.save_dir, das_depth_filename);
        saveas(gcf, das_depth_filepath);
        fprintf('✓ Saved DAS depth analysis: %s\n', das_depth_filename);
        plot_config.figures_created{end+1} = das_depth_filename;
    end
end

end
