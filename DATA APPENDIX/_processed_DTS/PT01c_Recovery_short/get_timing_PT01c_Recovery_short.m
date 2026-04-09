function timing_config = get_timing_PT01c_Recovery_short()
%GET_TIMING_PT01C_RECOVERY_SHORT Timing configuration for PT01c_Recovery_short
%
% Auto-generated timing configuration
% Generated: 24-Aug-2025 12:26:18
%
% Output:
%   timing_config - Timing configuration structure

% Dataset Information
timing_config.source = 'extracted_from_filename';
timing_config.num_files = 21;
timing_config.first_file = 'PM07StepPT01c_UTC_20231024_190436.338.tdms';

% Timing Information
timing_config.start = datetime(2023, 10, 24, 19, 4, 36.338, 'TimeZone', 'UTC');
timing_config.end = datetime(2023, 10, 24, 19, 24, 36.338, 'TimeZone', 'UTC');
timing_config.duration_minutes = 20.0;

% Dataset-Specific Parameters
% PT-01c specific parameters
timing_config.head_timing_adjustment = 10;  % seconds
timing_config.das_timing_adjustment = 90;   % seconds
timing_config.C1 = 110;
timing_config.pumping_zone_min_ft = 260;
timing_config.pumping_zone_max_ft = 310;

end
