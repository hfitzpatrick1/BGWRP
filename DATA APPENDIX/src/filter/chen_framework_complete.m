function filtered_data = chen_framework_complete(data, config)
% CHEN_FRAMEWORK_COMPLETE - Full Chen et al. (2023) 3-stage DAS denoising
%
% Complete implementation of the Chen et al. integrated denoising framework
% optimized for DAS grid pattern removal
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - Denoised DAS data [time x channels]
%
% Configuration Parameters:
%   config.chen_enable_stage1          - Enable bandpass filtering (default: true)
%   config.chen_enable_stage2          - Enable SOMF filtering (default: true)  
%   config.chen_enable_stage3          - Enable F-K filtering (default: true)
%   config.chen_bandpass_low           - Low cutoff Hz (default: 0.001)
%   config.chen_bandpass_high          - High cutoff Hz (default: 0.4)
%   config.chen_bandpass_order         - Filter order (default: 6)
%   config.chen_somf_window            - SOMF window size (default: 17)
%   config.chen_somf_slope_smooth      - Slope smoothing radius (default: 20)
%   config.chen_fk_strength            - F-K filter strength (default: 0.02)
%   config.chen_fk_preserve_signal     - Signal preservation 0-1 (default: 0.8)

console_log('  Chen et al. (2023) 3-stage denoising framework:\n');

% Get configuration with defaults
enable_stage1 = get_param(config, 'chen_enable_stage1', true);
enable_stage2 = get_param(config, 'chen_enable_stage2', true);
enable_stage3 = get_param(config, 'chen_enable_stage3', true);

% Initialize with input data
current_data = data;

% Stage 1: Butterworth Bandpass Filter
if enable_stage1
    console_log('    Stage 1: Butterworth bandpass filtering...\n');
    current_data = chen_stage1_bandpass(current_data, config);
else
    console_log('    Stage 1: SKIPPED - Bandpass filtering disabled\n');
end

% Stage 2: Structure-Oriented Median Filter (SOMF)
if enable_stage2
    console_log('    Stage 2: Structure-oriented median filtering...\n');
    current_data = chen_stage2_somf(current_data, config);
else
    console_log('    Stage 2: SKIPPED - SOMF filtering disabled\n');
end

% Stage 3: F-K Domain Dip Filter
if enable_stage3
    console_log('    Stage 3: F-K domain dip filtering...\n');
    current_data = chen_stage3_fk(current_data, config);
else
    console_log('    Stage 3: SKIPPED - F-K filtering disabled\n');
end

filtered_data = current_data;

% Calculate and report SNR improvement
original_std = std(data(:));
filtered_std = std(filtered_data(:));
snr_improvement = 20 * log10(original_std / filtered_std);

console_log('  Chen framework complete. SNR improvement: %.1f dB\n', snr_improvement);

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
