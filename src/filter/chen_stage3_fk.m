function filtered_data = chen_stage3_fk(data, config)
% CHEN_STAGE3_FK - F-K domain dip filter (Chen et al. Stage 3)
%
% Removes horizontal and vertical morphological noise (grid patterns)
% using frequency-wavenumber domain filtering as described in Chen et al. (2023)
%
% This is the KEY filter for removing grid pattern artifacts!
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - F-K filtered data [time x channels]
%
% Configuration Parameters:
%   config.chen_fk_strength           - Filter strength 0-1 (default: 0.02)
%   config.chen_fk_target_horizontal  - Target horizontal noise (default: true)
%   config.chen_fk_target_vertical    - Target vertical noise (default: true)
%   config.chen_fk_preserve_signal    - Signal preservation 0-1 (default: 0.8)
%   config.chen_fk_taper_width        - Taper width for smooth filtering (default: 0.1)

% Get configuration parameters
filter_strength = get_param(config, 'chen_fk_strength', 0.02);
target_horizontal = get_param(config, 'chen_fk_target_horizontal', true);
target_vertical = get_param(config, 'chen_fk_target_vertical', true);
preserve_signal = get_param(config, 'chen_fk_preserve_signal', 0.8);
taper_width = get_param(config, 'chen_fk_taper_width', 0.1);

fprintf('      F-K dip filter: strength=%.3f, H=%d, V=%d\n', ...
    filter_strength, target_horizontal, target_vertical);

[num_time, num_channels] = size(data);

% Ensure data size is suitable for FFT (pad if necessary)
fft_time = 2^nextpow2(num_time);
fft_channels = 2^nextpow2(num_channels);

% Pad data for efficient FFT
padded_data = zeros(fft_time, fft_channels);
padded_data(1:num_time, 1:num_channels) = data;

% Step 1: Forward 2D FFT to frequency-wavenumber domain
fk_data = fft2(padded_data);

% Step 2: Create frequency and wavenumber axes
freq_axis = (0:fft_time-1) / fft_time - 0.5; % Normalized frequency
knum_axis = (0:fft_channels-1) / fft_channels - 0.5; % Normalized wavenumber

% Step 3: Design dip filter mask
filter_mask = ones(size(fk_data));

% Create coordinate matrices
[K, F] = meshgrid(knum_axis, freq_axis);

% Target horizontal noise (around zero wavenumber)
if target_horizontal
    horizontal_mask = create_triangular_notch(K, filter_strength, taper_width);
    filter_mask = filter_mask .* horizontal_mask;
    fprintf('        Applied horizontal noise filter\n');
end

% Target vertical noise (around zero frequency) - transpose and filter
if target_vertical
    % Transpose the F-K data to make vertical noise horizontal
    fk_data_t = fft2(padded_data');
    [K_t, F_t] = meshgrid(freq_axis, knum_axis); % Swapped for transpose
    
    vertical_mask = create_triangular_notch(K_t, filter_strength, taper_width);
    fk_data_t = fk_data_t .* vertical_mask;
    
    % Transform back and transpose
    filtered_transpose = real(ifft2(fk_data_t));
    padded_data = filtered_transpose';
    
    % Re-compute F-K for final filtering
    fk_data = fft2(padded_data);
    fprintf('        Applied vertical noise filter\n');
end

% Step 4: Apply filter mask
filtered_fk = fk_data .* filter_mask;

% Step 5: Inverse FFT back to time-space domain
filtered_padded = real(ifft2(filtered_fk));

% Step 6: Extract original data size and blend with original
filtered_result = filtered_padded(1:num_time, 1:num_channels);

% Preserve signal energy while removing coherent noise
filtered_data = data * preserve_signal + filtered_result * (1 - preserve_signal);

fprintf('        F-K filtering complete\n');

end

function mask = create_triangular_notch(K, strength, taper_width)
    % Create triangular notch filter centered at zero wavenumber
    % strength: 0 = no filtering, 1 = complete removal
    % taper_width: width of the transition region
    
    % Distance from zero wavenumber
    k_dist = abs(K);
    
    % Create triangular mask
    mask = ones(size(K));
    
    % Define filter region
    filter_width = strength * 0.5; % Half-width of the notch
    
    % Apply triangular taper
    in_filter = k_dist <= filter_width;
    in_taper = (k_dist > filter_width) & (k_dist <= filter_width + taper_width);
    
    % Zero out the center
    mask(in_filter) = 0;
    
    % Smooth taper
    mask(in_taper) = (k_dist(in_taper) - filter_width) / taper_width;
end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
