function chart_type = map_data_type_to_chart_type(data_type)
%MAP_DATA_TYPE_TO_CHART_TYPE Map analysis data types to config chart types
%
% Maps the data_type used in analysis to the chart_type used in manual bounds config
%
% Input:
%   data_type - String: 'raw', 'displacement', 'strain', 'head_data', 
%               'displacement_rate_line', 'strain_line', 'depth_axis'
%
% Output:
%   chart_type - String: 'raw_data', 'displacement_rate', 'strain', 'head_data',
%                'displacement_rate_line', 'strain_line', 'depth_axis'

switch lower(data_type)
    case 'raw'
        chart_type = 'raw_data';
    case 'displacement'
        chart_type = 'displacement_rate';
    case 'strain'
        chart_type = 'strain';
    case 'head_data'
        chart_type = 'head_data';
    case 'head_data_strain'
        chart_type = 'head_data_strain';
    case 'displacement_rate_line'
        chart_type = 'displacement_rate_line';
    case 'strain_line'
        chart_type = 'strain_line';
    case 'depth_axis'
        chart_type = 'depth_axis';
    otherwise
        chart_type = data_type;  % Fallback
end

end
