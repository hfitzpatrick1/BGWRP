function filtered_data = filter_concatenation_artifacts(data, method)
%FILTER_CONCATENATION_ARTIFACTS Remove vertical striping artifacts from DAS data
%
% Post-processing filter to remove file concatenation discontinuities
% from already-loaded DAS data
%
% Inputs:
%   data   - DAS data matrix [time x channels]
%   method - Filter method ('none', 'detrend', 'highpass', 'median', 'overlap_smooth', 
%            'phase_align', 'smooth_transition', 'local_detrend')
%
% Outputs:
%   filtered_data - Filtered DAS data matrix

if nargin < 2
    method = 'detrend';  % Default method
end

console_log('    Applying concatenation artifact filter: %s\n', method);

switch lower(method)
    case 'detrend'
        % Remove linear trends that occur at file boundaries
        filtered_data = zeros(size(data));
        for ch = 1:size(data, 2)
            if mod(ch, 100) == 0
                console_log('      Detrending channel %d of %d\n', ch, size(data, 2));
            end
            filtered_data(:, ch) = detrend(data(:, ch), 'linear');
        end
        
    case 'highpass'
        % High-pass filter to remove low-frequency concatenation artifacts
        filtered_data = zeros(size(data));
        cutoff_freq = 0.01;  % 0.01 Hz cutoff frequency
        sample_rate = 1;     % 1 Hz sampling rate
        
        for ch = 1:size(data, 2)
            if mod(ch, 100) == 0
                console_log('      High-pass filtering channel %d of %d\n', ch, size(data, 2));
            end
            try
                filtered_data(:, ch) = highpass(data(:, ch), cutoff_freq, sample_rate);
            catch
                % Fallback if highpass function not available
                console_log('      Warning: highpass function not available, using detrend\n');
                filtered_data(:, ch) = detrend(data(:, ch), 'linear');
            end
        end
        
    case 'median'
        % Median filter to remove impulsive artifacts
        filtered_data = zeros(size(data));
        filter_length = 5;  % 5-sample median filter
        
        for ch = 1:size(data, 2)
            if mod(ch, 100) == 0
                console_log('      Median filtering channel %d of %d\n', ch, size(data, 2));
            end
            filtered_data(:, ch) = medfilt1(data(:, ch), filter_length);
        end
        
    case 'overlap_smooth'
        % Simulate overlap smoothing for file boundaries
        % Assumes ~60 samples per minute at 1Hz (file boundaries every 60 samples)
        filtered_data = data;
        file_interval = 60;  % 1 minute at 1Hz sampling
        overlap_samples = 5;  % Smooth over 5 samples at boundaries
        
        for boundary = file_interval:file_interval:size(data,1)-overlap_samples
            if boundary + overlap_samples <= size(data,1)
                % Apply Hanning window smoothing at estimated file boundaries
                window = hann(2*overlap_samples);
                fade_out = window(1:overlap_samples);
                fade_in = window(overlap_samples+1:end);
                
                % Smooth the transition
                transition_start = boundary - overlap_samples + 1;
                transition_end = boundary + overlap_samples;
                
                if transition_start > 0 && transition_end <= size(data,1)
                    pre_data = filtered_data(transition_start:boundary, :);
                    post_data = filtered_data(boundary+1:transition_end, :);
                    
                    % Apply windowing
                    filtered_data(transition_start:boundary, :) = ...
                        pre_data .* fade_out;
                    filtered_data(boundary+1:transition_end, :) = ...
                        post_data .* fade_in;
                end
            end
        end
        
    case 'none'
        % No filtering - pass through original data
        filtered_data = data;
        console_log('      No filtering applied\n');
        
    otherwise
        warning('Unknown filter method: %s. Using no filtering.', method);
        filtered_data = data;
end

console_log('    ✓ Filtering completed\n');

end
