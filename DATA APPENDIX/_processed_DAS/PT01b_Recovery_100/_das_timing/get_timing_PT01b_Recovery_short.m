function timing_config = get_timing_PT01b_Recovery_short()
%GET_TIMING_PT01B_RECOVERY_SHORT Timing configuration for PT01b_Recovery_short
%
% Auto-generated timing configuration
% Generated: 10-Feb-2026 12:11:41
%
% Output:
%   timing_config - Timing configuration structure

% Dataset Information
timing_config.source = 'extracted_from_filename';
timing_config.num_files = 21;
timing_config.first_file = 'PM07StepPT01a_UTC_20231031_191947.754.tdms';

% Timing Information
timing_config.start = datetime(2023, 10, 31, 19, 19, 47.754, 'TimeZone', 'UTC');
timing_config.end = datetime(2023, 10, 31, 19, 39, 47.754, 'TimeZone', 'UTC');
timing_config.duration_minutes = 20.0;

% Dataset-Specific Parameters
% Auto-detected parameters for: PT01b_Recovery_short
timing_config.head_timing_adjustment = 0;   % seconds
timing_config.das_timing_adjustment = 0;    % seconds
timing_config.C1 = 200;  % Dynamic default
timing_config.pumping_zone_min_ft = 200;
timing_config.pumping_zone_max_ft = 400;

% Note: Adjust parameters in config.m if needed

end
