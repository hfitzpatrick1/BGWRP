% Example: Add weights to Zone 2 pump test data
% Customize the weight ranges below for your specific needs

%% Input/output files
input_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_PERFECTLY_FLAT.csv';
output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_WEIGHTED.csv';

%% Define weight ranges
% Format: {start_time, end_time, weight}
% Note: pump_start_elapsed = 31500 seconds

pump_start = 31500;

weight_ranges = {
    % Baseline period - low weight (not used for analysis)
    0,                    pump_start,           0.1;
    
    % First 2 min after pump on - wellbore effects
    pump_start,           pump_start + 120,     0.3;
    
    % 50 GPM plateau - good data
    pump_start + 120,     pump_start + 3480,    1.0;
    
    % Transitions between rates - medium weight
    pump_start + 3480,    pump_start + 3720,    0.5;
    
    % 80 GPM plateau - good data
    pump_start + 3720,    pump_start + 7080,    1.0;
    
    % Transition
    pump_start + 7080,    pump_start + 7320,    0.5;
    
    % 110 GPM plateau - good data
    pump_start + 7320,    pump_start + 10680,   1.0;
    
    % Transition
    pump_start + 10680,   pump_start + 10920,   0.5;
    
    % 150 GPM plateau - good data
    pump_start + 10920,   pump_start + 14280,   1.0;
    
    % Transition to recovery
    pump_start + 14280,   pump_start + 14520,   0.5;
    
    % Recovery period - good data
    pump_start + 14520,   pump_start + 20000,   1.0
};

%% Apply weights
add_weights_to_data(input_file, output_file, weight_ranges);

%% Alternative: Weight only specific plateau
% If you want to weight ONLY ONE section highly, uncomment below:

% % Example: Only use the 110 GPM plateau
% weight_ranges = {
%     0,                    pump_start + 7320,    0.1;   % Everything before
%     pump_start + 7320,    pump_start + 10680,   1.0;   % 110 GPM plateau ONLY
%     pump_start + 10680,   999999,               0.1    % Everything after
% };
