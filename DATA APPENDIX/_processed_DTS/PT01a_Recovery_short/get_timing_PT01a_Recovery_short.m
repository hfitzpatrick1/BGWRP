function timing_config = get_timing_PT01a_Recovery_short()
%GET_TIMING_PT01A_RECOVERY_SHORT Timing configuration for PT01a_Recovery_short
%
% Auto-generated timing configuration
% Generated: 24-Aug-2025 13:18:54
%
% Output:
%   timing_config - Timing configuration structure

% Dataset Information
timing_config.source = 'extracted_from_filename';
timing_config.num_files = 21;
timing_config.first_file = 'PM07StepPT01a_UTC_20231107_203410.122.tdms';

% Timing Information
timing_config.start = datetime(2023, 11, 7, 20, 34, 10.122, 'TimeZone', 'UTC');
timing_config.end = datetime(2023, 11, 7, 20, 54, 10.122, 'TimeZone', 'UTC');
timing_config.duration_minutes = 20.0;

% Dataset-Specific Parameters
% PT-01a specific parameters
timing_config.head_timing_adjustment = 0;   % seconds
timing_config.das_timing_adjustment = 0;    % seconds
timing_config.C1 = 513;
timing_config.pumping_zone_min_ft = 450;
timing_config.pumping_zone_max_ft = 510;

end
