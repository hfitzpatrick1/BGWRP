function figure_handle = plot_das_waterfall(das_results, test_label, test_index, plot_config)
%PLOT_DAS_WATERFALL Create DAS waterfall plot (Figure Type 3)
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
        
        % Waterfall plot with filtered data
        imagesc(waterfall_data');
        clim([-2 2]); % Standard range from original
        colormap('jet');
        colorbar;
        title(sprintf('Test %s: DAS Waterfall (Analysis Window)', upper(test_label)));
        xlabel('Time Sample (Analysis Window)');
        ylabel('Channel Number');
        
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
