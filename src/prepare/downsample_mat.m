function [downsampled_data, success] = downsample_mat(input_data, decimation_factor, source_sampling_rate)
%DOWNSAMPLE_MAT Downsample data with validation and warnings
%
% Pure downsampling function with comprehensive validation.
% Handles the MATLAB decimate() bug with single precision data.
%
% Inputs:
%   input_data           - Input data matrix [time x channels]
%   decimation_factor    - Decimation factor (1 = no decimation)
%   source_sampling_rate - Source sampling rate in Hz (default: 100)
%
% Outputs:
%   downsampled_data - Decimated data matrix
%   success         - true if successful, false otherwise

if nargin < 3
    source_sampling_rate = 100; % Default based on TDMS analysis
end

fprintf('=== DOWNSAMPLING DATA ===\n');
fprintf('Input size: [%d x %d]\n', size(input_data, 1), size(input_data, 2));
fprintf('Decimation factor: %d\n', decimation_factor);

success = false;
downsampled_data = [];

try
    % Validate decimation factor
    validate_decimation_factor(decimation_factor, source_sampling_rate);
    
    % Handle no decimation case
    if decimation_factor == 1
        fprintf('No decimation - preserving full resolution\n');
        downsampled_data = input_data;
        success = true;
        return;
    end
    
    % Validate input data
    if isempty(input_data) || ~isnumeric(input_data)
        error('Invalid input data');
    end
    
    % Check for problematic data
    nan_count = sum(isnan(input_data(:)));
    if nan_count > 0
        warning('Input data contains %d NaN values (%.1f%%). These will propagate through decimation.', ...
                nan_count, (nan_count/numel(input_data))*100);
    end
    
    % Initialize output array
    output_length = ceil(size(input_data, 1) / decimation_factor);
    downsampled_data = zeros(output_length, size(input_data, 2));
    
    fprintf('Decimating %d channels...\n', size(input_data, 2));
    
    % Decimate each channel
    for n = 1:size(input_data, 2)
        if mod(n, 500) == 0 || n == size(input_data, 2)  % Show every 500th + last
            fprintf('  Channel %d of %d\n', n, size(input_data, 2));
        end
        
        % Fix for MATLAB decimate() bug with single precision data
        % Convert to double if using problematic decimation factors
        channel_data = input_data(:, n);
        if isa(channel_data, 'single') && (decimation_factor == 10 || decimation_factor == 6)
            channel_data = double(channel_data);
        end
        
        try
            % Use MATLAB's decimate() function (matches paper method)
            % Paper: "we down-sampled the 1,000 Hz sampling rate to 100 Hz using 
            % the Matlab 'decimate' command which applies a lowpass Chebyshev Type I 
            % infinite impulse response (IIR) anti-aliasing filter of order 8"
            % 
            % We're going from 100 Hz to 1 Hz, so use decimate() like the paper
            % decimate() applies anti-aliasing filter (reduces amplitude) then downsamples
            % The filter naturally reduces amplitude - this is expected behavior
            % No additional division needed - decimate() handles the decimation correctly
            
            decimated = decimate(channel_data, decimation_factor);
            
            % Ensure output length matches (decimate may differ slightly)
            if length(decimated) > output_length
                downsampled_data(:, n) = decimated(1:output_length);
            elseif length(decimated) < output_length
                % Pad with last value if needed
                downsampled_data(:, n) = [decimated; repmat(decimated(end), output_length - length(decimated), 1)];
            else
                downsampled_data(:, n) = decimated;
            end
            
        catch ME
            % Fallback: try direct downsampling if decimate() fails
            warning('decimate() failed for channel %d, using simple downsample: %s', n, ME.message);
            try
                downsampled_data(:, n) = downsample(channel_data, decimation_factor);
            catch ME2
                warning('Decimation failed for channel %d: %s. Filling with NaN.', n, ME2.message);
                downsampled_data(:, n) = NaN(output_length, 1);
            end
        end
    end
    
    % Final validation
    final_nan_count = sum(isnan(downsampled_data(:)));
    if final_nan_count > 0
        warning('Output contains %d NaN values (%.1f%%). Check input data quality.', ...
                final_nan_count, (final_nan_count/numel(downsampled_data))*100);
    end
    
    success = true;
    fprintf('✓ Downsampling complete: [%d x %d]\n', size(downsampled_data, 1), size(downsampled_data, 2));
    
catch ME
    fprintf('✗ Error during downsampling: %s\n', ME.message);
    success = false;
    downsampled_data = [];
end

end

function validate_decimation_factor(decimation_factor, source_sampling_rate)
%VALIDATE_DECIMATION_FACTOR Check if decimation factor is appropriate

% Calculate target sampling rate and Nyquist
target_sampling_rate = source_sampling_rate / decimation_factor;
target_nyquist = target_sampling_rate / 2;
source_nyquist = source_sampling_rate / 2;

fprintf('\n=== DECIMATION VALIDATION ===\n');
fprintf('Source: %.1f Hz (Nyquist: %.1f Hz)\n', source_sampling_rate, source_nyquist);
fprintf('Target: %.1f Hz (Nyquist: %.1f Hz)\n', target_sampling_rate, target_nyquist);

% Validation checks
if decimation_factor < 1
    error('Decimation factor must be >= 1');
elseif decimation_factor == 1
    fprintf('✓ No decimation - preserving full resolution\n');
elseif decimation_factor <= 5
    fprintf('✓ Light decimation - preserving signal dynamics\n');
elseif decimation_factor <= 20
    fprintf('⚠ Medium decimation - adequate for slower phenomena\n');
elseif decimation_factor <= 50
    fprintf('⚠ Heavy decimation - only slow phenomena preserved\n');
elseif decimation_factor <= 100
    fprintf('⚠ Very heavy decimation - only very slow phenomena\n');
else
    fprintf('⚠ Extreme decimation - most signal content lost\n');
    warning('Decimation factor %d may be too aggressive', decimation_factor);
end

% Check for known problematic values
if decimation_factor == 10
    fprintf('ℹ Note: Factor 10 requires double precision (MATLAB bug workaround)\n');
end

if mod(decimation_factor, 2) ~= 0 && decimation_factor > 1
    fprintf('ℹ Note: Odd factors may cause phase distortion\n');
end

fprintf('===============================\n\n');

end
