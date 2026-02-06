function console_log(action, varargin)
%CONSOLE_LOG Simple console logging that actually works
% Usage:
%   console_log('init', filepath) - Initialize logging
%   console_log(message, args...) - Log message (like fprintf)
%   console_log('close') - Close log file

persistent log_fid log_path

if nargin < 1
    return;
end

% Handle init
if ischar(action) && strcmp(action, 'init')
    if nargin < 2
        error('console_log init requires filepath');
    end
    
    % Close existing log if open
    if ~isempty(log_fid) && log_fid ~= -1
        fclose(log_fid);
    end
    
    log_path = varargin{1};
    log_fid = fopen(log_path, 'w');
    if log_fid == -1
        warning('Could not create console log: %s', log_path);
        return;
    end
    
    fprintf('Console logging to: %s\n', log_path);
    fprintf(log_fid, '=== CONSOLE LOG STARTED: %s ===\n\n', datestr(now));
    return;
end

% Handle close
if ischar(action) && strcmp(action, 'close')
    if ~isempty(log_fid) && log_fid ~= -1
        fprintf(log_fid, '\n=== CONSOLE LOG ENDED: %s ===\n', datestr(now));
        fclose(log_fid);
        fprintf('Console log saved to: %s\n', log_path);
        log_fid = [];
        log_path = '';
    end
    return;
end

% Handle regular logging (message + optional args)
if nargin > 1
    msg = sprintf(action, varargin{:});
else
    msg = action;
end

% Write to console
fprintf('%s', msg);

% Write to file if open
if ~isempty(log_fid) && log_fid ~= -1
    fprintf(log_fid, '%s', msg);
end

end
