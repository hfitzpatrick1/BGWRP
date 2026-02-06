function diagnose_boundaries_enhanced(dataset_name, data_filepath, timing_config)
%DIAGNOSE_BOUNDARIES_ENHANCED Enhanced boundary analysis with focused insights
%
% Provides concise, actionable analysis of file boundary artifacts
%
% Inputs:
%   dataset_name  - Name of dataset being analyzed
%   data_filepath - Path to concatenated MAT file
%   timing_config - Timing configuration with file information

console_log('=== ENHANCED BOUNDARY DIAGNOSTIC: %s ===\n', dataset_name);

% Load data
load(data_filepath, 'decdata');
data = decdata;

% Focus on pumping zone for analysis
test_channels = 450:470;
test_channels = test_channels(test_channels <= size(data, 2));

console_log('Dataset: %d samples, %d channels | Analyzing channels %d-%d\n', ...
    size(data, 1), size(data, 2), min(test_channels), max(test_channels));

% Expected file boundaries (60-sample intervals)
samples_per_file = 60;
boundary_positions = samples_per_file:samples_per_file:(size(data, 1) - samples_per_file);

% Analyze representative channel for pattern detection
rep_channel = test_channels(11); % Middle channel
rep_data = data(:, rep_channel);

console_log('\n--- ARTIFACT CHARACTERIZATION ---\n');

% 1. Boundary Jump Analysis
jumps = [];
for i = 1:min(length(boundary_positions), 20) % Limit to first 20 boundaries
    pos = boundary_positions(i);
    if pos > 5 && pos <= size(data, 1) - 5
        pre_val = mean(rep_data(pos-4:pos));
        post_val = mean(rep_data(pos+1:pos+5));
        jump = post_val - pre_val;
        jumps(end+1) = jump;
    end
end

if ~isempty(jumps)
    console_log('Jump Pattern: mean=%.4f, std=%.4f, range=[%.4f, %.4f]\n', ...
        mean(jumps), std(jumps), min(jumps), max(jumps));
    
    % Check for systematic bias
    if abs(mean(jumps)) > 2*std(jumps)
        console_log('  → SYSTEMATIC BIAS detected (mean >> std)\n');
    else
        console_log('  → RANDOM JUMPS detected (mean ≈ std)\n');
    end
    
    % Check for drift
    jump_trend = polyfit(1:length(jumps), jumps, 1);
    if abs(jump_trend(1)) > 0.001
        console_log('  → DRIFT detected: %.6f per boundary\n', jump_trend(1));
    end
end

% 2. Amplitude Scale Analysis
console_log('\n--- AMPLITUDE SCALING ---\n');
segment_rms = [];
for i = 1:min(length(boundary_positions)+1, 21) % First 20 segments
    if i == 1
        seg_start = 1;
    else
        seg_start = boundary_positions(i-1) + 1;
    end
    
    if i <= length(boundary_positions)
        seg_end = boundary_positions(i);
    else
        seg_end = size(data, 1);
    end
    
    if seg_end - seg_start > 10 % Ensure sufficient data
        segment_data = rep_data(seg_start:seg_end);
        segment_rms(end+1) = rms(segment_data);
    end
end

if length(segment_rms) > 1
    rms_variation = std(segment_rms) / mean(segment_rms);
    console_log('RMS Variation: %.1f%% (std/mean)\n', rms_variation * 100);
    
    if rms_variation > 0.1
        console_log('  → AMPLITUDE SCALING issues detected\n');
    else
        console_log('  → Amplitude scaling OK\n');
    end
end

% 3. Frequency Content Analysis
console_log('\n--- FREQUENCY ANALYSIS ---\n');
% Compare pre/post boundary frequency content
if length(boundary_positions) >= 2
    % Get data from 2 adjacent segments
    pos1 = boundary_positions(10); % Middle boundary
    pre_segment = rep_data(pos1-30:pos1);
    post_segment = rep_data(pos1+1:pos1+31);
    
    % Simple frequency comparison
    pre_diff = diff(pre_segment);
    post_diff = diff(post_segment);
    
    pre_hf_energy = sum(pre_diff.^2);
    post_hf_energy = sum(post_diff.^2);
    
    hf_ratio = post_hf_energy / pre_hf_energy;
    console_log('High-freq energy ratio (post/pre): %.2f\n', hf_ratio);
    
    if hf_ratio > 1.5 || hf_ratio < 0.67
        console_log('  → FREQUENCY CONTENT changes at boundaries\n');
    end
end

% 4. Spatial Coherence
console_log('\n--- SPATIAL COHERENCE ---\n');
if length(test_channels) > 5
    % Check if all channels show similar pattern
    pos = boundary_positions(10);
    if pos > 10 && pos <= size(data, 1) - 10
        all_jumps = [];
        for ch = test_channels(1:5:end) % Sample every 5th channel
            pre_val = mean(data(pos-4:pos, ch));
            post_val = mean(data(pos+1:pos+5, ch));
            all_jumps(end+1) = post_val - pre_val;
        end
        
        jump_coherence = std(all_jumps) / abs(mean(all_jumps));
        console_log('Channel coherence: %.2f (std/mean)\n', jump_coherence);
        
        if jump_coherence < 0.5
            console_log('  → COHERENT across channels (global artifact)\n');
        else
            console_log('  → INCOHERENT across channels (channel-specific)\n');
        end
    end
end

% 5. Correction Recommendation
console_log('\n--- RECOMMENDATION ---\n');
if exist('jumps', 'var') && ~isempty(jumps)
    if abs(mean(jumps)) > 3*std(jumps)
        console_log('→ Try DC OFFSET correction (systematic bias)\n');
    elseif exist('rms_variation', 'var') && rms_variation > 0.15
        console_log('→ Try AMPLITUDE SCALING correction\n');
    elseif exist('hf_ratio', 'var') && (hf_ratio > 2 || hf_ratio < 0.5)
        console_log('→ Try FREQUENCY DOMAIN correction\n');
    elseif std(jumps) > abs(mean(jumps))
        console_log('→ Artifacts may be RANDOM - filtering may not help\n');
    else
        console_log('→ Try INTERPOLATION across boundaries\n');
    end
else
    console_log('→ Insufficient data for recommendation\n');
end

% Create focused diagnostic plot
figure('Name', sprintf('Boundary Diagnostic - %s', dataset_name));

subplot(2,2,1);
plot(rep_data);
hold on;
for i = 1:min(10, length(boundary_positions))
    xline(boundary_positions(i), 'r-', 'Alpha', 0.7);
end
title('Signal with Boundaries');
xlabel('Sample'); ylabel('Amplitude');
xlim([1, min(1200, length(rep_data))]);

subplot(2,2,2);
if exist('jumps', 'var') && ~isempty(jumps)
    plot(jumps, 'o-');
    title('Jump Magnitude vs Boundary');
    xlabel('Boundary #'); ylabel('Jump Size');
    yline(0, 'k--', 'Alpha', 0.5);
end

subplot(2,2,3);
if exist('segment_rms', 'var') && length(segment_rms) > 1
    plot(segment_rms, 's-');
    title('RMS per Segment');
    xlabel('Segment #'); ylabel('RMS');
end

subplot(2,2,4);
% Show detail around one boundary
if length(boundary_positions) >= 10
    pos = boundary_positions(10);
    detail_range = max(1, pos-30):min(size(data,1), pos+30);
    plot(detail_range, rep_data(detail_range), 'b-', 'LineWidth', 1.5);
    hold on;
    xline(pos, 'r-', 'LineWidth', 2);
    title('Boundary Detail');
    xlabel('Sample'); ylabel('Amplitude');
end

console_log('\n=== DIAGNOSTIC COMPLETE ===\n');

end
