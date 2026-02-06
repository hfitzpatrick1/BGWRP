% Add custom weights to Zone 2 data based on specific time ranges

%% Input/output files
input_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_DENOISED.csv';
output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/PM7_Zone2_WEIGHTED.csv';

%% Define weight ranges based on behavior
% High weight for sections with good response behavior
% Lower weight for other sections

weight_ranges = {
    % Before first target section - low weight
    0,      4800,   0.3;
    
    % TARGET 1: 4,800 - 6,400 seconds - HIGH WEIGHT
    4800,   6400,   1.0;
    
    % Between sections - medium weight
    6400,   8000,   0.5;
    
    % TARGET 2: 8,000 - 10,000 seconds - HIGH WEIGHT
    8000,   10000,  1.0;
    
    % Between sections - medium weight
    10000,  12000,  0.5;
    
    % TARGET 3: 12,000 - 13,600 seconds - HIGH WEIGHT
    12000,  13600,  1.0;
    
    % Between sections - medium weight
    13600,  15200,  0.5;
    
    % TARGET 4: 15,200 - 16,800 seconds - HIGH WEIGHT
    15200,  16800,  1.0;
    
    % After last target section - low weight
    16800,  99999,  0.3
};

%% Apply weights
add_weights_to_data(input_file, output_file, weight_ranges);

fprintf('\n=== SUMMARY ===\n');
fprintf('High weight (1.0) sections:\n');
fprintf('  • 4,800 - 6,400 sec\n');
fprintf('  • 8,000 - 10,000 sec\n');
fprintf('  • 12,000 - 13,600 sec\n');
fprintf('  • 15,200 - 16,800 sec\n');
fprintf('\nMedium weight (0.5): Transitions\n');
fprintf('Low weight (0.3): Other sections\n');
