function corrected_data = amplitude_normalization_correction(data, timing_config, options)
%AMPLITUDE_NORMALIZATION_CORRECTION Normalize amplitude variations between file segments
%
% Addresses the 66.5% RMS variation detected by enhanced diagnostic
% Uses multiplicative scaling rather than additive offsets
%
% Inputs:
%   data          - DAS data matrix [time x channels]
%   timing_config - Timing configuration structure
%   options       - Correction options structure
%
% Outputs:
%   corrected_data - Amplitude-normalized DAS data matrix

if nargin < 3
    options = struct();
end

% Default options
if ~isfield(options, 'method'), options.method = 'rms_normalize'; end
if ~isfield(options, 'reference_method'), options.reference_method = 'median'; end
if ~isfield(options, 'test_channels'), options.test_channels = 450:470; end
if ~isfield(options, 'smoothing'), options.smoothing = false; end

console_log('=== AMPLITUDE NORMALIZATION CORRECTION ===\n');
console_log('Method: %s\n', options.method);

% Calculate file segment boundaries
samples_per_file = 60;  % 1-minute files at 1Hz
num_segments = floor(size(data, 1) / samples_per_file);
segment_boundaries = (0:num_segments) * samples_per_file;
segment_boundaries(end) = size(data, 1); % Ensure last boundary covers all data

console_log('Processing %d file segments\n', num_segments);

% Focus on test channels for amplitude calculation
test_channels = options.test_channels;
test_channels = test_channels(test_channels <= size(data, 2));

%% Stage 1: Analyze segment amplitudes
console_log('\n--- STAGE 1: AMPLITUDE ANALYSIS ---\n');

segment_stats = [];
for i = 1:num_segments
    seg_start = segment_boundaries(i) + 1;
    seg_end = segment_boundaries(i + 1);
    
    if seg_end - seg_start > 10 % Ensure sufficient data
        segment_data = data(seg_start:seg_end, test_channels);
        
        % Calculate amplitude metrics
        seg_rms = sqrt(mean(segment_data(:).^2));
        seg_std = std(segment_data(:));
        seg_mean_abs = mean(abs(segment_data(:)));
        seg_max = max(abs(segment_data(:)));
        
        segment_stats(i, :) = [seg_start, seg_end, seg_rms, seg_std, seg_mean_abs, seg_max];
        
        if i <= 10 || mod(i, 20) == 0  % Show first 10 and every 20th
            console_log('  Segment %d: RMS=%.4f, STD=%.4f, MaxAbs=%.4f\n', ...
                i, seg_rms, seg_std, seg_max);
        end
    end
end

if isempty(segment_stats)
    console_log('No valid segments found - returning original data\n');
    corrected_data = data;
    return;
end

% Calculate reference amplitude
switch lower(options.reference_method)
    case 'median'
        reference_rms = median(segment_stats(:, 3));
        console_log('Reference amplitude (median RMS): %.6f\n', reference_rms);
    case 'mean'
        reference_rms = mean(segment_stats(:, 3));
        console_log('Reference amplitude (mean RMS): %.6f\n', reference_rms);
    case 'first'
        reference_rms = segment_stats(1, 3);
        console_log('Reference amplitude (first segment RMS): %.6f\n', reference_rms);
    otherwise
        reference_rms = median(segment_stats(:, 3));
        console_log('Reference amplitude (default median RMS): %.6f\n', reference_rms);
end

%% Stage 2: Apply amplitude normalization
console_log('\n--- STAGE 2: AMPLITUDE NORMALIZATION ---\n');

corrected_data = data; % Start with original data

switch lower(options.method)
    case 'rms_normalize'
        console_log('Applying RMS normalization...\n');
        
        for i = 1:size(segment_stats, 1)
            seg_start = segment_stats(i, 1);
            seg_end = segment_stats(i, 2);
            seg_rms = segment_stats(i, 3);
            
            if seg_rms > 1e-12  % Avoid division by zero
                % Calculate scaling factor
                scale_factor = reference_rms / seg_rms;
                
                % Apply to all channels in this segment
                corrected_data(seg_start:seg_end, :) = ...
                    corrected_data(seg_start:seg_end, :) * scale_factor;
                
                if i <= 5 || mod(i, 25) == 0
                    console_log('    Segment %d: scale_factor=%.4f (RMS: %.4f -> %.4f)\n', ...
                        i, scale_factor, seg_rms, seg_rms * scale_factor);
                end
            end
        end
        
    case 'adaptive_normalize'
        console_log('Applying adaptive normalization with smoothing...\n');
        
        % Calculate smooth scaling factors
        raw_factors = reference_rms ./ segment_stats(:, 3);
        
        if options.smoothing && length(raw_factors) > 5
            % Apply smoothing to scaling factors
            smooth_factors = movmean(raw_factors, 5);
            console_log('    Applied 5-point smoothing to scaling factors\n');
        else
            smooth_factors = raw_factors;
        end
        
        for i = 1:size(segment_stats, 1)
            seg_start = segment_stats(i, 1);
            seg_end = segment_stats(i, 2);
            scale_factor = smooth_factors(i);
            
            if abs(scale_factor) > 1e-12 && scale_factor < 10  % Reasonable bounds
                corrected_data(seg_start:seg_end, :) = ...
                    corrected_data(seg_start:seg_end, :) * scale_factor;
                
                if i <= 5 || mod(i, 25) == 0
                    console_log('    Segment %d: smooth_scale=%.4f\n', i, scale_factor);
                end
            end
        end
        
    case 'percentile_normalize'
        console_log('Applying percentile-based normalization...\n');
        
        % Use 90th percentile instead of RMS for robustness
        reference_p90 = median(prctile(abs(data(segment_stats(:,1):segment_stats(:,2), test_channels)), 90, 'all'));
        
        for i = 1:size(segment_stats, 1)
            seg_start = segment_stats(i, 1);
            seg_end = segment_stats(i, 2);
            
            segment_data = data(seg_start:seg_end, test_channels);
            seg_p90 = prctile(abs(segment_data(:)), 90);
            
            if seg_p90 > 1e-12
                scale_factor = reference_p90 / seg_p90;
                
                corrected_data(seg_start:seg_end, :) = ...
                    corrected_data(seg_start:seg_end, :) * scale_factor;
                
                if i <= 5 || mod(i, 25) == 0
                    console_log('    Segment %d: P90_scale=%.4f\n', i, scale_factor);
                end
            end
        end
        
    otherwise
        warning('Unknown normalization method: %s', options.method);
        return;
end

%% Stage 3: Validation
console_log('\n--- NORMALIZATION VALIDATION ---\n');

% Recalculate segment RMS after correction
post_correction_stats = [];
for i = 1:size(segment_stats, 1)
    seg_start = segment_stats(i, 1);
    seg_end = segment_stats(i, 2);
    
    corrected_segment = corrected_data(seg_start:seg_end, test_channels);
    post_rms = sqrt(mean(corrected_segment(:).^2));
    
    original_rms = segment_stats(i, 3);
    improvement = abs(post_rms - reference_rms) / reference_rms * 100;
    
    post_correction_stats(i, :) = [original_rms, post_rms, improvement];
end

% Calculate overall improvement
original_rms_variation = std(segment_stats(:, 3)) / mean(segment_stats(:, 3)) * 100;
corrected_rms_variation = std(post_correction_stats(:, 2)) / mean(post_correction_stats(:, 2)) * 100;

reduction_percentage = ((original_rms_variation - corrected_rms_variation) / original_rms_variation) * 100;

console_log('RMS Variation: %.1f%% -> %.1f%% (%.1f%% reduction)\n', ...
    original_rms_variation, corrected_rms_variation, reduction_percentage);

% Success criteria
if reduction_percentage > 70
    console_log('✓ NORMALIZATION EXCELLENT: Substantial amplitude variation reduction\n');
elseif reduction_percentage > 40
    console_log('✓ NORMALIZATION GOOD: Significant amplitude variation reduction\n');
elseif reduction_percentage > 15
    console_log('⚠ NORMALIZATION PARTIAL: Moderate amplitude variation reduction\n');
else
    console_log('✗ NORMALIZATION MINIMAL: Limited improvement achieved\n');
end

console_log('\n=== AMPLITUDE NORMALIZATION COMPLETE ===\n');

end
