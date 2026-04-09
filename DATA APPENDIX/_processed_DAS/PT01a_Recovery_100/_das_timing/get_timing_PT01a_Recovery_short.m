function timing_config = get_timing_PT01a_Recovery_short()
%GET_TIMING_PT01A_RECOVERY_SHORT Timing configuration for PT01a_Recovery_short
%
% Auto-generated timing configuration
% Generated: 04-Feb-2026 16:27:44
%
% Output:
%   timing_config - Timing configuration structure

% Dataset Information
timing_config.source = 'extracted_from_filename';
timing_config.num_files = 21;
timing_config.first_file = 'PM07StepPT01b_UTC_20231107_203510.122.tdms';

% Timing Information
timing_config.start = datetime(2023, 11, 7, 20, 35, 10.122, 'TimeZone', 'UTC');
timing_config.end = datetime(2023, 11, 7, 20, 55, 10.122, 'TimeZone', 'UTC');
timing_config.duration_minutes = 20.0;

% Dataset-Specific Parameters
% Auto-detected parameters for: PT01a_Recovery_short
timing_config.head_timing_adjustment = 0;   % seconds
timing_config.das_timing_adjustment = 0;    % seconds
timing_config.C1 = 200;  % Dynamic default
timing_config.pumping_zone_min_ft = 200;
timing_config.pumping_zone_max_ft = 400;

% Note: Adjust parameters in config.m if needed

end
