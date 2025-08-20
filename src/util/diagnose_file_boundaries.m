function diagnose_file_boundaries(dataset_name, data_filepath, timing_config)
%DIAGNOSE_FILE_BOUNDARIES Analyze file boundary discontinuities in DAS data
%
% Identifies and characterizes sharp transitions at file concatenation points
%
% Inputs:
%   dataset_name  - Name of dataset being analyzed
%   data_filepath - Path to concatenated MAT file
%   timing_config - Timing configuration with file information

fprintf('=== FILE BOUNDARY DISCONTINUITY DIAGNOSTIC ===\n');
fprintf('Dataset: %s\n', dataset_name);

% Load data
fprintf('Loading data from: %s\n', data_filepath);
load(data_filepath, 'decdata');
data = decdata;

% Get timing information
start_time = timing_config.start;
file_duration_minutes = 1;  % Assume 1-minute files
sample_rate = 1;  % 1 Hz
samples_per_file = file_duration_minutes * 60 * sample_rate;

fprintf('Expected samples per file: %d\n', samples_per_file);
fprintf('Total samples: %d\n', size(data, 1));
fprintf('Total channels: %d\n', size(data, 2));

% Calculate expected file boundary positions
num_files = ceil(size(data, 1) / samples_per_file);
boundary_positions = (1:num_files-1) * samples_per_file;

fprintf('Expected file boundaries at samples: %s\n', mat2str(boundary_positions));

% Focus on pumping zone channels (around depth 280-290 ft)
test_channels = [450:470];  % Representative subset
fprintf('Analyzing channels: %d to %d\n', min(test_channels), max(test_channels));

% Analyze discontinuities at each boundary
fprintf('\n--- BOUNDARY DISCONTINUITY ANALYSIS ---\n');

discontinuities = [];
for i = 1:length(boundary_positions)
    boundary_sample = boundary_positions(i);
    
    if boundary_sample > 10 && boundary_sample < size(data, 1) - 10
        % Extract data around boundary (±10 samples)
        pre_boundary = data(boundary_sample-9:boundary_sample, test_channels);
        post_boundary = data(boundary_sample+1:boundary_sample+10, test_channels);
        
        % Calculate mean values before and after boundary
        pre_mean = mean(pre_boundary, 1);
        post_mean = mean(post_boundary, 1);
        
        % Calculate discontinuity magnitude
        discontinuity = abs(post_mean - pre_mean);
        max_discontinuity = max(discontinuity);
        mean_discontinuity = mean(discontinuity);
        
        discontinuities(i, :) = [boundary_sample, max_discontinuity, mean_discontinuity];
        
        % Calculate boundary time
        boundary_time = start_time + seconds(boundary_sample - 1);
        
        fprintf('Boundary %d (sample %d, time %s):\n', i, boundary_sample, boundary_time);
        fprintf('  Max discontinuity: %.6f\n', max_discontinuity);
        fprintf('  Mean discontinuity: %.6f\n', mean_discontinuity);
        fprintf('  Affected channels: %d/%d (>0.001 threshold)\n', ...
            sum(discontinuity > 0.001), length(discontinuity));
    end
end

% Overall statistics
if ~isempty(discontinuities)
    fprintf('\n--- SUMMARY STATISTICS ---\n');
    fprintf('Total boundaries analyzed: %d\n', size(discontinuities, 1));
    fprintf('Average max discontinuity: %.6f\n', mean(discontinuities(:, 2)));
    fprintf('Average mean discontinuity: %.6f\n', mean(discontinuities(:, 3)));
    fprintf('Largest discontinuity: %.6f (at sample %d)\n', ...
        max(discontinuities(:, 2)), discontinuities(discontinuities(:, 2) == max(discontinuities(:, 2)), 1));
    
    % Determine if this explains the vertical striping
    significant_boundaries = sum(discontinuities(:, 2) > 0.01);
    fprintf('Significant boundaries (>0.01 threshold): %d/%d\n', ...
        significant_boundaries, size(discontinuities, 1));
    
    if significant_boundaries >= 3
        fprintf('\n✓ DIAGNOSIS: File boundary discontinuities likely cause of vertical striping\n');
        fprintf('  Recommendation: Implement boundary-specific phase alignment correction\n');
    else
        fprintf('\n⚠ DIAGNOSIS: File boundaries show minor discontinuities\n');
        fprintf('  Recommendation: Investigate other causes (calibration drift, temperature)\n');
    end
else
    fprintf('\n⚠ No boundary discontinuities detected - check file timing assumptions\n');
end

% Create diagnostic plot
figure;
subplot(2,1,1);
plot(data(:, test_channels(1)));
hold on;
for i = 1:length(boundary_positions)
    xline(boundary_positions(i), 'r--', sprintf('File %d', i+1));
end
title(sprintf('Channel %d - File Boundaries', test_channels(1)));
xlabel('Sample');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
if ~isempty(discontinuities)
    bar(discontinuities(:, 1), discontinuities(:, 2));
    title('Discontinuity Magnitude at File Boundaries');
    xlabel('Sample Position');
    ylabel('Max Discontinuity');
    grid on;
end

sgtitle(sprintf('File Boundary Diagnostic - %s', dataset_name));

fprintf('\n=== DIAGNOSTIC COMPLETE ===\n');

end
