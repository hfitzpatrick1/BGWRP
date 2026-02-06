% Add refined weights based on AQTESOLV fitting behavior
% Weights applied to TIME-SHIFTED data (t=0 at pump start)

%% Input/output files
input_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_FOR_AQTESOLV.csv';
output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_WEIGHTED_REFINED.csv';

%% Define weight ranges (times relative to pump start = 0)
% High weight for circled areas in AQTESOLV plot

weight_ranges = {
    % CIRCLE 1: Early time response (critical for S!)
    0,      1000,   1.0;
    
    % Transition period - low weight
    1000,   3000,   0.3;
    
    % CIRCLE 2: Middle of 50 GPM plateau
    3000,   6000,   1.0;
    
    % Transition to 80 GPM - low weight
    6000,   7000,   0.3;
    
    % CIRCLE 3: Middle of 80 GPM plateau
    7000,   9000,   1.0;
    
    % Transition to 110 GPM - low weight
    9000,   9500,   0.3;
    
    % CIRCLE 4: Middle of 110 GPM plateau
    9500,   11500,  1.0;
    
    % Transition to 150 GPM - low weight
    11500,  12500,  0.3;
    
    % CIRCLE 5: Middle of 150 GPM plateau
    12500,  14000,  1.0;
    
    % Transition to recovery - low weight
    14000,  14600,  0.3;
    
    % Recovery period - medium weight
    14600,  99999,  0.7
};

%% Apply weights
add_weights_to_data(input_file, output_file, weight_ranges);

console_log('\n=== REFINED WEIGHTS SUMMARY ===\n');
console_log('HIGH weight (1.0) - Your circled areas:\n');
console_log('  • 0-1000 sec: Early time response\n');
console_log('  • 3000-6000 sec: 50 GPM plateau\n');
console_log('  • 7000-9000 sec: 80 GPM plateau\n');
console_log('  • 9500-11500 sec: 110 GPM plateau\n');
console_log('  • 12500-14000 sec: 150 GPM plateau\n');
console_log('\nLow weight (0.3): Transitions\n');
console_log('Medium weight (0.7): Recovery\n');
