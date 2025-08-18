function figure_handle = plot_das_depth_analysis(das_results, test_label, test_index, plot_config)
%PLOT_DAS_DEPTH_ANALYSIS Create DAS strain rate vs depth analysis plot (Figure Type 2)
%
% Inputs:
%   das_results - Results from analyze_das_data
%   test_label  - Test label string
%   test_index  - Index for figure numbering
%   plot_config - Plot configuration structure
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
        
        % Subsample for plotting performance
        subsample_factor = max(1, floor(length(time_filtered) / 1000)); % Limit to ~1000 points
        time_subset = time_filtered(1:subsample_factor:end);
        data_subset = data_filtered(1:subsample_factor:end, :);
        
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
        
        % Set explicit time limits to analysis window
        xlim([datenum(analysis_start), datenum(analysis_end)]);
        
        title(sprintf('Test %s: DAS Strain Rate vs Depth (Analysis Window)', upper(test_label)));
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
