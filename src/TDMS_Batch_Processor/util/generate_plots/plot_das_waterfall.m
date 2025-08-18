function figure_handle = plot_das_waterfall(das_results, test_label, test_index, plot_config, config)
%PLOT_DAS_WATERFALL Create DAS waterfall plot (Figure Type 3)
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

%% Figure Type 3: DAS Waterfall Plot (Analysis Window Only)
if isfield(das_results, test_label) && ~isfield(das_results.(test_label), 'error')
    das_data = das_results.(test_label);
    if isfield(das_data, 'smoothed_data') && isfield(das_data, 'analysis_time')
        figure_handle = figure(300 + test_index);
        set(gcf, 'Position', [200 + test_index*50, 200, 800, 600]);
        
        % Filter to analysis window only
        analysis_start = min(das_data.analysis_time);
        analysis_end = max(das_data.analysis_time);
        
        if isfield(das_data, 'time_array')
            % Filter full data to analysis window
            analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
            waterfall_data = das_data.smoothed_data(analysis_mask, :);
        else
            % Use pre-filtered data (shouldn't happen but safe fallback)
            waterfall_data = das_data.smoothed_data;
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
        
        % Apply zone filtering if configured
        plot_data = waterfall_data;
        depth_channels = 1:size(waterfall_data, 2);
        ylabel_text = 'Channel Number';
        
        if ~isempty(dataset_name) && isfield(config, 'waterfall_zones') && isfield(config.waterfall_zones, dataset_name)
            zone_config = config.waterfall_zones.(dataset_name);
            fprintf('  🎯 Applying zone filter for %s: %.0f-%.0f ft\n', dataset_name, zone_config.min_depth, zone_config.max_depth);
            
            % Convert depth range to channel indices (if depth info available)
            if isfield(das_results.(test_label), 'depth_ft')
                depth_ft = das_results.(test_label).depth_ft;
                channel_mask = depth_ft >= zone_config.min_depth & depth_ft <= zone_config.max_depth;
                if any(channel_mask)
                    plot_data = waterfall_data(:, channel_mask);
                    depth_channels = find(channel_mask);
                    ylabel_text = sprintf('Channel Number (%.0f-%.0f ft)', zone_config.min_depth, zone_config.max_depth);
                    fprintf('  📊 Filtered to %d channels (ch %d-%d)\n', sum(channel_mask), min(depth_channels), max(depth_channels));
                else
                    fprintf('  ⚠ No channels found in specified depth range\n');
                end
            else
                fprintf('  ⚠ No depth information available for zone filtering\n');
            end
        end
        
        % Waterfall plot with (potentially filtered) data
        imagesc(plot_data');
        clim([-2 2]); % Standard range from original
        colormap('jet');
        colorbar;
        
        % Update title and labels
        if ~isempty(dataset_name) && isfield(config, 'waterfall_zones') && isfield(config.waterfall_zones, dataset_name)
            title_suffix = ' (Zone Filtered)';
        else
            title_suffix = '';
        end
        title(sprintf('Test %s: DAS Waterfall (Analysis Window)%s', upper(test_label), title_suffix));
        xlabel('Time Sample (Analysis Window)');
        ylabel(ylabel_text);
        
        if plot_config.save_enabled
            waterfall_filename = sprintf('test_%s_das_waterfall.png', test_label);
            waterfall_filepath = fullfile(plot_config.save_dir, waterfall_filename);
            saveas(gcf, waterfall_filepath);
            fprintf('✓ Saved DAS waterfall: %s\n', waterfall_filename);
            plot_config.figures_created{end+1} = waterfall_filename;
        end
    end
end

end
