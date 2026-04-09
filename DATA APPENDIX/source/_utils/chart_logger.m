function chart_logger(message, varargin)
%CHART_LOGGER Write chart-related log messages to file and console
%
% Usage:
%   chart_logger(message)                    - Simple message
%   chart_logger(message, arg1, arg2, ...)   - Formatted message (like fprintf)
%   chart_logger('init', config)             - Initialize logging session
%   chart_logger('close')                    - Close logging session
%
% Examples:
%   chart_logger('init', config);
%   chart_logger('Manual bounds applied: [%.3f, %.3f]', min_val, max_val);
%   chart_logger('Processing dataset: %s', dataset_name);
%   chart_logger('close');

persistent log_file_handle log_directory log_filename session_active

% Handle special commands
if strcmp(message, 'init')
    if nargin < 2
        error('chart_logger init requires config structure');
    end
    config = varargin{1};
    
    % Create log directory
    if isfield(config, 'base_input')
        log_directory = fullfile(config.base_input, '_log');
    else
        log_directory = fullfile(pwd, '_log');
    end
    
    if ~exist(log_directory, 'dir')
        mkdir(log_directory);
    end
    
    % Create timestamped log file
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    log_filename = sprintf('chart_log_%s.txt', timestamp);
    log_filepath = fullfile(log_directory, log_filename);
    
    % Open log file
    log_file_handle = fopen(log_filepath, 'w');
    if log_file_handle == -1
        warning('Could not create chart log file: %s', log_filepath);
        session_active = false;
        return;
    end
    
    session_active = true;
    
    % Write session header directly to chart log file
    % NOTE: Do NOT call console_log(fid, ...) - console_log expects a format
    % string as first arg, not a file handle. Use fprintf directly.
    fprintf(log_file_handle, '=== CHART LOGGING SESSION ===\n');
    fprintf(log_file_handle, 'Started: %s\n', datestr(now));
    fprintf(log_file_handle, 'Log file: %s\n', log_filename);
    fprintf(log_file_handle, 'Base directory: %s\n', config.base_input);
    fprintf(log_file_handle, '=====================================\n\n');
    
    % Also display to console
    console_log('📊 Chart logging initialized: %s\n', log_filepath);
    return;
    
elseif strcmp(message, 'close')
    if ~isempty(session_active) && session_active && ~isempty(log_file_handle) && log_file_handle ~= -1
        % Write session footer directly to chart log file
        fprintf(log_file_handle, '\n=====================================\n');
        fprintf(log_file_handle, 'Session ended: %s\n', datestr(now));
        fprintf(log_file_handle, '=== END CHART LOGGING SESSION ===\n');
        
        fclose(log_file_handle);
        console_log('Chart log saved: %s\n', fullfile(log_directory, log_filename));
        
        % Reset persistent variables
        log_file_handle = [];
        session_active = false;
    end
    return;
end

% Format message if additional arguments provided
if nargin > 1
    formatted_message = sprintf(message, varargin{:});
else
    formatted_message = message;
end

% Add timestamp prefix
timestamp = datestr(now, 'HH:MM:SS.FFF');
timestamped_message = sprintf('[%s] %s', timestamp, formatted_message);

% Write to console (always)
console_log('%s\n', timestamped_message);

% Write to log file (if session active and initialized)
if ~isempty(session_active) && session_active && ~isempty(log_file_handle) && log_file_handle ~= -1
    fprintf(log_file_handle, '%s\n', timestamped_message);
    % Flush to ensure immediate write
    if exist('OCTAVE_VERSION', 'builtin')
        fflush(log_file_handle);
    else
        % MATLAB doesn't have fflush, but we can force flush
        fwrite(log_file_handle, '');
    end
end

end
