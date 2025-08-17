function timing_config = PM07_Auto_Timing(data_dir, config)
%PM07_Auto_Timing - Automatically detect DAS data timing from file metadata
%
% This function attempts to automatically detect the actual start times
% of DAS data files, which is critical when working with data subsets.
%
% Usage: 
%   timing_config = PM07_Auto_Timing(data_dir, config);
%
% Inputs:
%   data_dir - Path to the data directory
%   config   - Configuration structure from PM07_Recovery_Config()
%
% Outputs:
%   timing_config - Updated timing configuration with detected start times

fprintf('=== ATTEMPTING AUTOMATIC TIMING DETECTION ===\n');

% Initialize output structure with default values
timing_config = config;

%% Check for timing metadata in MAT files
tests = {'a', 'b', 'c'};
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};

for i = 1:length(tests)
    test = tests{i};
    test_name = test_names{i};
    
    fprintf('\n%s timing detection:\n', test_name);
    
    % Get the DAS file path
    das_file_path = fullfile(data_dir, config.das_files.(test));
    
    if exist(das_file_path, 'file')
        % Load the MAT file to check for timing variables
        file_vars = who('-file', das_file_path);
        fprintf('  Variables in %s: %s\n', config.das_files.(test), strjoin(file_vars, ', '));
        
        % Look for common timing variable names
        timing_vars = intersect(file_vars, {'StartTime', 'start_time', 'DASStart', 'timestamp', 'time_start'});
        
        if ~isempty(timing_vars)
            % Found potential timing variable
            load(das_file_path, timing_vars{1});
            eval(['detected_time = ' timing_vars{1} ';']);
            
            if isa(detected_time, 'datetime')
                timing_config.das_timing.(test).start = detected_time;
                timing_config.das_timing.(test).source = 'auto_detected';
                fprintf('  ✓ Auto-detected start time: %s\n', detected_time);
            elseif ischar(detected_time) || isstring(detected_time)
                % Try to parse as datetime
                try
                    detected_time = datetime(detected_time, 'TimeZone', 'UTC');
                    timing_config.das_timing.(test).start = detected_time;
                    timing_config.das_timing.(test).source = 'auto_detected_parsed';
                    fprintf('  ✓ Auto-detected and parsed start time: %s\n', detected_time);
                catch
                    fprintf('  ⚠ Found timing variable but could not parse: %s\n', detected_time);
                end
            else
                fprintf('  ⚠ Found timing variable but unrecognized format\n');
            end
        else
            fprintf('  ⚠ No timing metadata found in MAT file\n');
            fprintf('  Using default start time: %s\n', config.das_timing.(test).start);
            timing_config.das_timing.(test).source = 'default_hardcoded';
        end
    else
        fprintf('  ⚠ DAS file not found: %s\n', das_file_path);
        timing_config.das_timing.(test).source = 'file_not_found';
    end
end

%% Alternative: Try to infer timing from original TDMS file naming pattern
fprintf('\n=== CHECKING FOR TDMS SOURCE PATTERN ===\n');

% Look for patterns like "UTC_YYYYMMDD_HHMMSS" in the data directory structure
for i = 1:length(tests)
    test = tests{i};
    test_name = test_names{i};
    
    if strcmp(timing_config.das_timing.(test).source, 'default_hardcoded') || ...
       strcmp(timing_config.das_timing.(test).source, 'file_not_found')
        
        fprintf('%s: Searching for TDMS timing patterns...\n', test_name);
        
        % This is where you could add logic to scan TDMS directories
        % for files with UTC timestamps in the names
        % For now, just indicate this capability exists
        fprintf('  (TDMS pattern detection could be implemented here)\n');
    end
end

fprintf('\n=== TIMING DETECTION COMPLETE ===\n');
fprintf('Remember to verify detected times against your expected data windows!\n');

end
