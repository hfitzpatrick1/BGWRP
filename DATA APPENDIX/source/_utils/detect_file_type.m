function file_type = detect_file_type(filepath)
%DETECT_FILE_TYPE Determine if a .mat file contains head data or DAS data
%
% Input:
%   filepath - Path to .mat file
%
% Output:
%   file_type - 'head_data', 'das_data', or 'unknown'
%
% Detection logic:
% - Head data files contain: Date, Drawdownft, Depthft fields
% - DAS data files contain: large time_array, smoothed_data matrices
% - Uses field names and data dimensions to classify

try
    % Get file info without loading large arrays
    file_info = whos('-file', filepath);
    field_names = {file_info.name};
    
    % Check for head data signature
    has_date = any(strcmpi(field_names, 'Date'));
    has_drawdown = any(strcmpi(field_names, 'Drawdownft'));
    has_depth = any(strcmpi(field_names, 'Depthft'));
    
    if has_date && has_drawdown && has_depth
        file_type = 'head_data';
        return;
    end
    
    % Check for DAS data signature
    has_time_array = any(strcmpi(field_names, 'time_array'));
    has_smoothed_data = any(strcmpi(field_names, 'smoothed_data'));
    has_das_data = any(strcmpi(field_names, 'das_data'));
    
    % Look for large matrices that indicate DAS data
    large_matrices = false;
    for i = 1:length(file_info)
        if length(file_info(i).size) == 2
            total_elements = prod(file_info(i).size);
            if total_elements > 100000  % Large matrix threshold
                large_matrices = true;
                break;
            end
        end
    end
    
    if (has_time_array || has_smoothed_data || has_das_data) && large_matrices
        file_type = 'das_data';
        return;
    end
    
    % If we can't determine from field names, try loading a small sample
    try
        data = load(filepath);
        field_names_loaded = fieldnames(data);
        
        % More detailed checks with loaded data
        if any(strcmpi(field_names_loaded, 'Date')) && any(strcmpi(field_names_loaded, 'Drawdownft'))
            % Verify it's time series data with reasonable length for head data
            if isfield(data, 'Date') && length(data.Date) > 10 && length(data.Date) < 50000
                file_type = 'head_data';
                return;
            end
        end
        
        % Check for DAS-like data structures
        for fn = field_names_loaded'
            field_data = data.(fn{1});
            if isnumeric(field_data) && length(size(field_data)) == 2
                [rows, cols] = size(field_data);
                if rows > 1000 && cols > 100  % Typical DAS data dimensions
                    file_type = 'das_data';
                    return;
                end
            end
        end
        
    catch
        % If loading fails, fall back to unknown
    end
    
    file_type = 'unknown';
    
catch ME
    console_log('Warning: Could not analyze file %s: %s\n', filepath, ME.message);
    file_type = 'unknown';
end

end
