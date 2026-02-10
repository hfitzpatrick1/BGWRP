function data_out = fix_bad_channels(data_in)
%FIX_BAD_CHANNELS Remove per-channel baseline offsets for clean plotting
%
% Subtracts the temporal median from each depth channel to eliminate
% horizontal banding caused by channel-to-channel baseline differences.
% Preserves all temporal dynamics and relative spatial patterns.
%
% Display only - does NOT modify analysis data.
%
% Input:  data_in  - [time x depth] matrix
% Output: data_out - baseline-corrected [time x depth] matrix

% Subtract temporal median from each channel (more robust than mean)
ch_median = median(data_in, 1, 'omitnan');
data_out = data_in - ch_median;

% Optional: add back the overall median so colorbar bounds stay similar
overall_median = median(ch_median);
data_out = data_out + overall_median;

end
