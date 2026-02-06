function console_logger(action, varargin)
%CONSOLE_LOGGER Reliable console output logging using file handles
%
% Usage:
%   console_logger('init', log_filepath) - Initialize logging
%   console_logger('log', message, args...) - Log formatted message
%   console_logger('close') - Close logging session
%
% Example:
%   console_logger('init', 'C:\path\to\log.txt');
%   console_logger('log', 'Processing %s with value %.2f', name, value);
%   console_logger('close');

persistent log_fid log_path

switch action
    case 'init'
        if nargin < 2
            error('console_logger init requires log filepath');
        end
        log_path = varargin{1};
        
        % Close any existing log
        if ~isempty(log_fid) && log_fid ~= -1
            fclose(log_fid);
        end
        
        % Open new log file
        log_fid = fopen(log_path, 'w');
        if log_fid == -1
            warning('Could not create console log file: %s', log_path);
            return;
        end
        
        fprintf('Console logging to: %s\n', log_path);
        fprintf(log_fid, 'Console log started: %s\n\n', datestr(now));
        
    case 'log'
        if nargin < 2
            return;
        end
        
        % Format message
        if nargin > 2
            message = sprintf(varargin{1}, varargin{2:end});
        else
            message = varargin{1};
        end
        
        % Write to console
        fprintf('%s', message);
        
        % Write to file if open
        if ~isempty(log_fid) && log_fid ~= -1
            fprintf(log_fid, '%s', message);
        end
        
    case 'close'
        if ~isempty(log_fid) && log_fid ~= -1
            fprintf(log_fid, '\nConsole log ended: %s\n', datestr(now));
            fclose(log_fid);
            fprintf('Console log saved to: %s\n', log_path);
            log_fid = [];
            log_path = '';
        end
        
    otherwise
        error('Unknown action: %s', action);
end

end
