function chart_type = map_data_type_to_chart_type(data_type)
%MAP_DATA_TYPE_TO_CHART_TYPE Map analysis data types to config chart types
%
% Maps the data_type used in analysis ('raw', 'displacement', 'strain')
% to the chart_type used in manual bounds config ('raw_data', 'displacement_rate', 'strain')
%
% Input:
%   data_type - String: 'raw', 'displacement', or 'strain'
%
% Output:
%   chart_type - String: 'raw_data', 'displacement_rate', or 'strain'

switch lower(data_type)
    case 'raw'
        chart_type = 'raw_data';
    case 'displacement'
        chart_type = 'displacement_rate';
    case 'strain'
        chart_type = 'strain';
    otherwise
        chart_type = data_type;  % Fallback
end

end
