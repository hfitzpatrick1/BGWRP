function apply_line_chart_bounds(config, test_label, chart_type)
%APPLY_LINE_CHART_BOUNDS Apply Y-axis bounds to line charts based on configuration
%
% This function applies configured Y-axis bounds to line charts (head data and DAS line data)
% in dual-axis plots. It works with yyaxis left/right plots.
%
% Input:
%   config     - Configuration structure containing manual_bounds
%   test_label - Dataset name (e.g., 'PT01a_Recovery_short')
%   chart_type - Type of chart: 'displacement_rate' or 'strain'
%
% Example:
%   apply_line_chart_bounds(config, 'PT01a_Recovery_short', 'displacement_rate');

% Map chart type to specific line chart bounds
head_bound_type = 'head_data';
if strcmp(chart_type, 'displacement_rate')
    das_bound_type = 'displacement_rate_line';
elseif strcmp(chart_type, 'strain')
    das_bound_type = 'strain_line';
else
    chart_logger('WARNING: Unknown chart type for line bounds: %s', chart_type);
    return;
end

try
    % Get head data bounds (yyaxis left)
    head_bounds = get_plot_bounds([], head_bound_type, config, test_label);
    
    % Get DAS line data bounds (yyaxis right)
    das_bounds = get_plot_bounds([], das_bound_type, config, test_label);
    
    % Apply head data bounds (yyaxis left)
    yyaxis left;
    ylim(head_bounds);
    chart_logger('    Applied head data Y-axis bounds: [%.3f, %.3f] ft', head_bounds(1), head_bounds(2));
    
    % Apply DAS line data bounds (yyaxis right)
    yyaxis right;
    ylim(das_bounds);
    chart_logger('    Applied %s line bounds: [%.3f, %.3f] nm/s', das_bound_type, das_bounds(1), das_bounds(2));
    
    % Apply depth bounds to waterfall (main plot above)
    % Note: This would be applied to the subplot(2,1,1) which should be active before this call
    
catch ME
    chart_logger('WARNING: Failed to apply line chart bounds for %s: %s', test_label, ME.message);
end

end
