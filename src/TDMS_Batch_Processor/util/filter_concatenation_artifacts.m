function filtered_data = filter_concatenation_artifacts(data, method)
%FILTER_CONCATENATION_ARTIFACTS Remove vertical striping artifacts from DAS data
%
% Post-processing filter to remove file concatenation discontinuities
% from already-loaded DAS data
%
% Inputs:
%   data   - DAS data matrix [time x channels]
%   method - Filter method ('detrend', 'overlap_smooth', 'none')
%
% Outputs:
%   filtered_data - Filtered DAS data matrix

if nargin < 2
    method = 'detrend';  % Default method
end

fprintf('    Applying concatenation artifact filter: %s\n', method);

switch lower(method)
    case 'detrend'
        % Remove linear trends that occur at file boundaries
        filtered_data = zeros(size(data));
        for ch = 1:size(data, 2)
            if mod(ch, 100) == 0
                fprintf('      Detrending channel %d of %d\n', ch, size(data, 2));
            end
            filtered_data(:, ch) = detrend(data(:, ch), 'linear');
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
        fprintf('      No filtering applied\n');
        
    otherwise
        warning('Unknown filter method: %s. Using no filtering.', method);
        filtered_data = data;
end

fprintf('    ✓ Filtering completed\n');

end
