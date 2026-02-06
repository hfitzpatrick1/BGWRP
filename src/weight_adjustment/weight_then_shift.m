% Complete workflow: Add weights THEN shift time for AQTESOLV

%% Step 1: Add weights to DENOISED file (using original time values)
input_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_DENOISED.csv';
weighted_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_WEIGHTED_TEMP.csv';

% Pump starts at 2670 in the DENOISED file
pump_start_in_file = 2670;

% Define weights - DOUBLED for all areas of interest!
weight_ranges = {
    % Before pump - very low weight
    0,                          pump_start_in_file,        0.1;
    
    % CRITICAL: First 10 minutes (0-600 sec) - QUADRUPLE WEIGHT for S!
    pump_start_in_file,         pump_start_in_file + 600,  4.0;  % DOUBLED from 2.0!
    
    % Early-mid time (600-3300 sec) - still important
    pump_start_in_file + 600,   pump_start_in_file + 3300, 0.5;
    
    % CIRCLE 1: End of 50 GPM plateau (~3300-4000 sec)
    pump_start_in_file + 3300,  pump_start_in_file + 4000, 2.0;  % DOUBLED!
    
    % Between circles
    pump_start_in_file + 4000,  pump_start_in_file + 5300, 0.2;
    
    % CIRCLE 2: 80 GPM plateau section (~5300-7000 sec)
    pump_start_in_file + 5300,  pump_start_in_file + 7000, 2.0;  % DOUBLED!
    
    % Between circles
    pump_start_in_file + 7000,  pump_start_in_file + 8500, 0.2;
    
    % CIRCLE 3: 110 GPM plateau section (~8500-10500 sec)
    pump_start_in_file + 8500,  pump_start_in_file + 10500, 2.0;  % DOUBLED!
    
    % Between circles
    pump_start_in_file + 10500, pump_start_in_file + 11500, 0.2;
    
    % CIRCLE 4: 150 GPM plateau section (~11500-13000 sec)
    pump_start_in_file + 11500, pump_start_in_file + 13000, 2.0;  % DOUBLED!
    
    % Between circles
    pump_start_in_file + 13000, pump_start_in_file + 13500, 0.2;
    
    % CIRCLE 5: Recovery section (~13500-14500 sec)
    pump_start_in_file + 13500, pump_start_in_file + 14500, 2.0;  % DOUBLED!
    
    % After circles
    pump_start_in_file + 14500, 99999,                      0.2
};

console_log('STEP 1: Adding weights to DENOISED file...\n');
add_weights_to_data(input_file, weighted_file, weight_ranges);

%% Step 2: Shift time so pump start = 0
console_log('\nSTEP 2: Shifting time to pump start = 0...\n');
shift_time_to_pump_start(weighted_file, ...
                         'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_FINAL_AQTESOLV.csv', ...
                         pump_start_in_file);

console_log('\n=== COMPLETE! ===\n');
console_log('✓ Final file: PM7_Zone2_FINAL_AQTESOLV.csv\n');
console_log('✓ Includes weights for your circled areas\n');
console_log('✓ Time starts at t=0 (pump ON)\n');
console_log('✓ Ready to import into AQTESOLV!\n');
