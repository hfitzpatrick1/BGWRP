function analyze_noise_characteristics(dataset_name)
% ANALYZE_NOISE_CHARACTERISTICS - Comprehensive noise analysis for filtering design
% Identifies specific frequencies, patterns, and artifacts that need filtering
%
% Usage: analyze_noise_characteristics('PT01c_Recovery_short')

if nargin < 1
    dataset_name = 'PT01c_Recovery_short';
end

fprintf('=== NOISE CHARACTERISTICS ANALYSIS ===\n');
fprintf('Dataset: %s\n', dataset_name);
fprintf('Purpose: Identify optimal filtering strategies\n\n');

% Load the concatenated data (post-decimation)
data_path = 'C:\Coding\BGWRP\data\_BATCH';
concat_file = fullfile(data_path, '_concatenated', dataset_name, sprintf('Dataset_%s_1Hz.mat', dataset_name));

if ~exist(concat_file, 'file')
    error('Concatenated file not found: %s', concat_file);
end

fprintf('Loading data: %s\n', concat_file);
load(concat_file);
fprintf('Data size: [%d x %d]\n', size(data,1), size(data,2));

% Get basic parameters
fs = 1; % Hz (post-decimation)
n_samples = size(data, 1);
n_channels = size(data, 2);
time_minutes = n_samples / fs / 60;

fprintf('Sampling rate: %.1f Hz\n', fs);
fprintf('Duration: %.1f minutes\n', time_minutes);
fprintf('Nyquist frequency: %.2f Hz\n\n', fs/2);

%% 1. TEMPORAL FREQUENCY ANALYSIS
fprintf('=== 1. TEMPORAL FREQUENCY ANALYSIS ===\n');

% Select representative channels for analysis
channel_subset = [100, 250, 500, 750, 900]; % Spread across fiber
channel_subset = channel_subset(channel_subset <= n_channels);

figure('Position', [100 100 1400 800]);

% Analyze each channel
dominant_freqs = [];
noise_powers = [];

for i = 1:length(channel_subset)
    ch = channel_subset(i);
    signal = data(:, ch);
    
    % Remove DC component and trend
    signal_detrended = detrend(signal);
    
    % Compute power spectral density
    [psd, freqs] = pwelch(signal_detrended, [], [], [], fs);
    
    % Plot PSD
    subplot(2, 3, i);
    semilogy(freqs, psd);
    title(sprintf('Channel %d PSD', ch));
    xlabel('Frequency (Hz)');
    ylabel('Power');
    grid on;
    
    % Find dominant frequencies (above median + 2*std)
    psd_threshold = median(psd) + 2*std(psd);
    [peaks, peak_locs] = findpeaks(psd, 'MinPeakHeight', psd_threshold);
    dominant_freqs = [dominant_freqs; freqs(peak_locs)];
    
    % Calculate total noise power
    total_power = sum(psd);
    noise_powers = [noise_powers; total_power];
    
    fprintf('Channel %d: %.1f%% relative noise, %d dominant peaks\n', ...
        ch, 100*std(signal_detrended)/mean(abs(signal_detrended)), length(peaks));
end

% Overall frequency analysis
subplot(2, 3, 6);
all_freqs = unique(round(dominant_freqs, 3));
hist(dominant_freqs, 20);
title('Dominant Frequency Distribution');
xlabel('Frequency (Hz)');
ylabel('Count');
grid on;

sgtitle(sprintf('%s - Temporal Frequency Analysis', dataset_name));

fprintf('\nDominant frequencies found: ');
fprintf('%.3f ', all_freqs);
fprintf('Hz\n');

%% 2. SPATIAL COHERENCE ANALYSIS
fprintf('\n=== 2. SPATIAL COHERENCE ANALYSIS ===\n');

% Analyze spatial correlation patterns
figure('Position', [200 200 1200 600]);

% Select time subset for spatial analysis (middle section)
time_subset = round(n_samples/4):round(3*n_samples/4);
spatial_data = data(time_subset, :);

% Calculate cross-correlation between adjacent channels
max_lag = 50; % channels
spatial_corr = zeros(n_channels-1, 1);

for ch = 1:n_channels-1
    if ch <= n_channels-1
        [xcorr_vals, lags] = xcorr(spatial_data(:,ch), spatial_data(:,ch+1), max_lag, 'coeff');
        [~, max_idx] = max(abs(xcorr_vals));
        spatial_corr(ch) = xcorr_vals(max_idx);
    end
end

subplot(1,2,1);
plot(spatial_corr);
title('Adjacent Channel Correlation');
xlabel('Channel Number');
ylabel('Correlation Coefficient');
grid on;

% Identify coherent noise regions
coherence_threshold = 0.7;
coherent_regions = find(spatial_corr > coherence_threshold);

fprintf('High spatial coherence (>%.1f): %d channel pairs\n', coherence_threshold, length(coherent_regions));
fprintf('Coherent regions: ');
if ~isempty(coherent_regions)
    fprintf('%d-%d ', [coherent_regions'; coherent_regions'+1]);
end
fprintf('\n');

% Channel-to-channel variability
subplot(1,2,2);
channel_std = std(spatial_data, 0, 1);
plot(channel_std);
title('Channel Standard Deviation');
xlabel('Channel Number');
ylabel('Standard Deviation');
grid on;

sgtitle(sprintf('%s - Spatial Coherence Analysis', dataset_name));

%% 3. PATTERN PERIODICITY ANALYSIS
fprintf('\n=== 3. PATTERN PERIODICITY ANALYSIS ===\n');

figure('Position', [300 300 1200 600]);

% Look for regular temporal patterns
middle_channels = round(n_channels/4):round(3*n_channels/4);
avg_signal = mean(data(:, middle_channels), 2);

% Autocorrelation to find repeating patterns
max_lag_time = min(300, round(n_samples/4)); % Up to 5 minutes at 1Hz
[autocorr_vals, lags] = xcorr(avg_signal, max_lag_time, 'coeff');

subplot(1,2,1);
plot(lags/fs/60, autocorr_vals); % Convert to minutes
title('Temporal Autocorrelation');
xlabel('Lag (minutes)');
ylabel('Correlation');
grid on;

% Find periodic peaks
[peaks, peak_locs] = findpeaks(autocorr_vals(lags>0), 'MinPeakHeight', 0.1);
if ~isempty(peaks)
    peak_periods = lags(lags>0);
    peak_periods = peak_periods(peak_locs) / fs / 60; % Convert to minutes
    fprintf('Periodic patterns found at: ');
    fprintf('%.1f ', peak_periods);
    fprintf('minutes\n');
end

% Look for spatial patterns
spatial_autocorr = zeros(1, min(100, round(n_channels/4)));
for lag = 1:length(spatial_autocorr)
    if lag <= n_channels-lag
        corr_vals = corrcoef(mean(spatial_data, 1), ...
                           [mean(spatial_data(:, 1+lag:end), 1), ...
                            mean(spatial_data(:, 1:lag), 1)]);
        spatial_autocorr(lag) = corr_vals(1,2);
    end
end

subplot(1,2,2);
plot(spatial_autocorr);
title('Spatial Autocorrelation');
xlabel('Channel Lag');
ylabel('Correlation');
grid on;

sgtitle(sprintf('%s - Pattern Periodicity Analysis', dataset_name));

%% 4. FILTERING RECOMMENDATIONS
fprintf('\n=== 4. FILTERING RECOMMENDATIONS ===\n');

% Temporal filtering recommendations
low_freq_cutoff = min(all_freqs) * 0.8;
high_freq_cutoff = max(all_freqs) * 1.2;

fprintf('TEMPORAL FILTERING:\n');
fprintf('• Bandstop filters needed at: ');
fprintf('%.3f ', all_freqs);
fprintf('Hz\n');

if low_freq_cutoff > 0.001
    fprintf('• High-pass filter: >%.4f Hz (remove drift)\n', low_freq_cutoff);
end

if high_freq_cutoff < fs/2
    fprintf('• Low-pass filter: <%.3f Hz (remove high-freq noise)\n', high_freq_cutoff);
end

% Spatial filtering recommendations
fprintf('\nSPATIAL FILTERING:\n');
if length(coherent_regions) > n_channels/10
    fprintf('• High spatial coherence detected - spatial median filter recommended\n');
    fprintf('• Suggested filter window: %d channels\n', min(21, round(n_channels/20)));
else
    fprintf('• Low spatial coherence - spatial filtering may not be effective\n');
end

% Adaptive filtering recommendations
max_noise_channel = find(channel_std == max(channel_std), 1);
fprintf('\nADAPTIVE FILTERING:\n');
fprintf('• Noisiest channel: %d (std = %.3f)\n', max_noise_channel, max(channel_std));
fprintf('• Noise variation across channels: %.1f%%\n', 100*std(channel_std)/mean(channel_std));

if std(channel_std)/mean(channel_std) > 0.2
    fprintf('• Channel-specific filtering recommended\n');
else
    fprintf('• Uniform filtering across all channels acceptable\n');
end

%% 5. SIGNAL-TO-NOISE ASSESSMENT
fprintf('\n=== 5. SIGNAL-TO-NOISE ASSESSMENT ===\n');

% Estimate signal vs noise components
signal_energy = var(mean(spatial_data, 2)); % Common mode signal
noise_energy = mean(var(spatial_data, [], 2)); % Channel-specific variance

snr_estimate = 10*log10(signal_energy / noise_energy);
fprintf('Estimated SNR: %.1f dB\n', snr_estimate);

if snr_estimate > 10
    fprintf('• Good SNR - gentle filtering recommended\n');
elseif snr_estimate > 0
    fprintf('• Moderate SNR - targeted filtering needed\n');
else
    fprintf('• Poor SNR - aggressive filtering may be necessary\n');
end

%% 6. SUGGESTED CONFIG UPDATES
fprintf('\n=== 6. SUGGESTED CONFIG.M UPDATES ===\n');
fprintf('Based on this analysis, consider these config changes:\n\n');

fprintf('%% Filtering Configuration (based on noise analysis)\n');
if ~isempty(all_freqs)
    fprintf('config.bandstop_frequencies = [');
    fprintf('%.3f ', all_freqs);
    fprintf(']; %% Hz - remove dominant noise peaks\n');
end

if length(coherent_regions) > n_channels/10
    fprintf('config.spatial_median_channels = %d; %% Spatial filtering window\n', min(21, round(n_channels/20)));
    fprintf('config.smoothing_method = ''spatial_median''; %% Use spatial filtering\n');
end

if snr_estimate < 5
    fprintf('config.chen_denoising = true; %% Enable advanced denoising\n');
end

fprintf('\nAnalysis complete. Review plots and recommendations above.\n');

end
