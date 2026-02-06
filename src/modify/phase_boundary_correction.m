function corrected_data = phase_boundary_correction(data, timing_config, options)
%PHASE_BOUNDARY_CORRECTION Correct file boundary discontinuities in DAS data
%
% Two-stage approach: 1) Diagnostic detection, 2) Targeted correction
%
% Inputs:
%   data          - DAS data matrix [time x channels]
%   timing_config - Timing configuration structure
%   options       - Correction options structure
%
% Outputs:
%   corrected_data - Phase-corrected DAS data matrix

if nargin < 3
    options = struct();
end

% Default options
if ~isfield(options, 'method'), options.method = 'phase_align'; end
if ~isfield(options, 'diagnostic_threshold'), options.diagnostic_threshold = 0.01; end
if ~isfield(options, 'correction_window'), options.correction_window = 10; end
if ~isfield(options, 'test_channels'), options.test_channels = 450:470; end

console_log('=== PHASE BOUNDARY CORRECTION ===\n');
console_log('Method: %s\n', options.method);

%% STAGE 1: DIAGNOSTIC DETECTION
console_log('\n--- STAGE 1: BOUNDARY DETECTION ---\n');

% Calculate expected file boundaries
start_time = timing_config.start;
file_duration_minutes = 1;  % 1-minute files
sample_rate = 1;           % 1 Hz
samples_per_file = file_duration_minutes * 60 * sample_rate;

num_files = ceil(size(data, 1) / samples_per_file);
boundary_positions = (1:num_files-1) * samples_per_file;

console_log('Detecting boundaries in %d total samples\n', size(data, 1));
console_log('Expected %d boundaries at 60-sample intervals\n', length(boundary_positions));

% Detect significant discontinuities
boundary_info = [];
test_channels = options.test_channels;
test_channels = test_channels(test_channels <= size(data, 2)); % Ensure valid channels

console_log('Testing channels %d to %d for discontinuities\n', min(test_channels), max(test_channels));

for i = 1:length(boundary_positions)
    boundary_sample = boundary_positions(i);
    
    if boundary_sample > options.correction_window && boundary_sample <= size(data, 1) - options.correction_window
        % Extract data around boundary
        pre_window = (boundary_sample - options.correction_window + 1):boundary_sample;
        post_window = (boundary_sample + 1):(boundary_sample + options.correction_window);
        
        pre_data = data(pre_window, test_channels);
        post_data = data(post_window, test_channels);
        
        % Calculate phase discontinuity
        pre_mean = mean(pre_data, 1);
        post_mean = mean(post_data, 1);
        
        phase_jump = post_mean - pre_mean;
        max_jump = max(abs(phase_jump));
        mean_jump = mean(abs(phase_jump));
        
        % Store boundary information
        boundary_info(end+1, :) = [boundary_sample, max_jump, mean_jump, mean(phase_jump)];
        
        if max_jump > options.diagnostic_threshold
            boundary_time = start_time + seconds(boundary_sample - 1);
            console_log('  Boundary %d (sample %d, %s): max_jump=%.4f, mean_offset=%.4f\n', ...
                i, boundary_sample, boundary_time, max_jump, mean(phase_jump));
        end
    end
end

% Filter significant boundaries
if ~isempty(boundary_info)
    significant_mask = boundary_info(:, 2) > options.diagnostic_threshold;
    significant_boundaries = boundary_info(significant_mask, :);
    
    console_log('\nDetected %d/%d significant boundaries requiring correction\n', ...
        sum(significant_mask), size(boundary_info, 1));
else
    console_log('No boundaries detected - returning original data\n');
    corrected_data = data;
    return;
end

%% STAGE 2: TARGETED CORRECTION
console_log('\n--- STAGE 2: PHASE CORRECTION ---\n');

corrected_data = data; % Start with original data

switch lower(options.method)
    case 'phase_align'
        console_log('Applying phase alignment correction...\n');
        
        for i = 1:size(significant_boundaries, 1)
            boundary_sample = significant_boundaries(i, 1);
            mean_offset = significant_boundaries(i, 4);
            
            % Apply correction to all channels after this boundary
            correction_start = boundary_sample + 1;
            correction_end = size(data, 1);
            
            % Find next boundary to limit correction scope
            next_boundaries = significant_boundaries(significant_boundaries(:, 1) > boundary_sample, 1);
            if ~isempty(next_boundaries)
                correction_end = min(correction_end, next_boundaries(1));
            end
            
            % Apply phase offset correction to all channels
            console_log('    Correcting samples %d to %d (offset: %.4f)\n', ...
                correction_start, correction_end, mean_offset);
            
            corrected_data(correction_start:correction_end, :) = ...
                corrected_data(correction_start:correction_end, :) - mean_offset;
        end
        
    case 'smooth_transition'
        console_log('Applying smooth transition correction...\n');
        
        for i = 1:size(significant_boundaries, 1)
            boundary_sample = significant_boundaries(i, 1);
            mean_offset = significant_boundaries(i, 4);
            
            % Create smooth transition across boundary
            transition_length = options.correction_window;
            transition_start = boundary_sample - transition_length/2 + 1;
            transition_end = boundary_sample + transition_length/2;
            
            if transition_start > 0 && transition_end <= size(data, 1)
                % Create smooth transition weights
                weights = linspace(0, 1, transition_length);
                
                for j = 1:transition_length
                    sample_idx = transition_start + j - 1;
                    correction_factor = weights(j) * mean_offset;
                    
                    corrected_data(sample_idx, :) = ...
                        corrected_data(sample_idx, :) - correction_factor;
                end
                
                console_log('    Smooth transition at boundary %d (samples %d-%d)\n', ...
                    boundary_sample, transition_start, transition_end);
            end
        end
        
    case 'local_detrend'
        console_log('Applying local detrending correction...\n');
        
        for i = 1:size(significant_boundaries, 1)
            boundary_sample = significant_boundaries(i, 1);
            
            % Define local region around boundary
            local_start = max(1, boundary_sample - options.correction_window*2);
            local_end = min(size(data, 1), boundary_sample + options.correction_window*2);
            
            % Apply local detrending across boundary
            local_data = corrected_data(local_start:local_end, :);
            
            for ch = 1:size(local_data, 2)
                corrected_data(local_start:local_end, ch) = detrend(local_data(:, ch), 'linear');
            end
            
            console_log('    Local detrend at boundary %d (samples %d-%d)\n', ...
                boundary_sample, local_start, local_end);
        end
        
    otherwise
        warning('Unknown correction method: %s', options.method);
        return;
end

%% VALIDATION
console_log('\n--- CORRECTION VALIDATION ---\n');

% Re-test boundaries after correction
post_correction_info = [];
for i = 1:size(significant_boundaries, 1)
    boundary_sample = significant_boundaries(i, 1);
    
    if boundary_sample > options.correction_window && boundary_sample <= size(corrected_data, 1) - options.correction_window
        pre_window = (boundary_sample - options.correction_window + 1):boundary_sample;
        post_window = (boundary_sample + 1):(boundary_sample + options.correction_window);
        
        pre_data = corrected_data(pre_window, test_channels);
        post_data = corrected_data(post_window, test_channels);
        
        pre_mean = mean(pre_data, 1);
        post_mean = mean(post_data, 1);
        
        phase_jump = post_mean - pre_mean;
        max_jump_after = max(abs(phase_jump));
        
        original_jump = significant_boundaries(i, 2);
        improvement = ((original_jump - max_jump_after) / original_jump) * 100;
        
        post_correction_info(end+1, :) = [boundary_sample, original_jump, max_jump_after, improvement];
        
        console_log('  Boundary %d: %.4f -> %.4f (%.1f%% improvement)\n', ...
            boundary_sample, original_jump, max_jump_after, improvement);
    end
end

if ~isempty(post_correction_info)
    avg_improvement = mean(post_correction_info(:, 4));
    console_log('\nOverall average improvement: %.1f%%\n', avg_improvement);
    
    remaining_significant = sum(post_correction_info(:, 3) > options.diagnostic_threshold);
    console_log('Remaining significant boundaries: %d/%d\n', ...
        remaining_significant, size(post_correction_info, 1));
    
    if avg_improvement > 50
        console_log('✓ CORRECTION SUCCESSFUL: Substantial improvement achieved\n');
    elseif avg_improvement > 20
        console_log('⚠ CORRECTION PARTIAL: Moderate improvement achieved\n');
    else
        console_log('✗ CORRECTION MINIMAL: Limited improvement - try different method\n');
    end
else
    console_log('⚠ Unable to validate correction\n');
end

console_log('\n=== PHASE CORRECTION COMPLETE ===\n');

end
