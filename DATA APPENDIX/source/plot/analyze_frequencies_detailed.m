function freq_analysis = analyze_frequencies_detailed(das_data, config)
%ANALYZE_FREQUENCIES_DETAILED Advanced frequency analysis with multiple methods
%
% Provides comprehensive frequency identification during specific time windows:
% 1. Windowed FFT (spectrogram)
% 2. Welch PSD estimation 
% 3. Statistical peak detection
% 4. Frequency evolution tracking
% 5. Signal-to-noise ratio analysis

console_log('    Performing detailed frequency analysis...\n');

% Get analysis data
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start = min(das_data.analysis_time);
    analysis_end = max(das_data.analysis_time);
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
    
    signal = das_data.smoothed_data(analysis_mask, round(size(das_data.smoothed_data,2)/2));
    time_array = das_data.time_array(analysis_mask);
    analysis_duration = seconds(analysis_end - analysis_start);
else
    signal = das_data.smoothed_data(:, round(size(das_data.smoothed_data,2)/2));
    time_array = (1:length(signal))';
    analysis_duration = length(signal);
end

% Get sampling rate safely
if isstruct(config)
    fs = get_config_param(config, 'sampling_rate', 1.0);
else
    fs = 1.0;  % Default for DAS data
end

N = length(signal);

% Initialize results
freq_analysis = struct();
freq_analysis.analysis_duration = analysis_duration;
freq_analysis.sampling_rate = fs;
freq_analysis.n_samples = N;

console_log('      Analysis window: %.1f minutes (%d samples at %.1f Hz)\n', ...
    analysis_duration/60, N, fs);

%% METHOD 1: BASIC FFT WITH STATISTICAL PEAK DETECTION
console_log('      Method 1: Statistical peak detection...\n');

% Clean signal
signal_clean = detrend(signal - mean(signal));
if N > 1
    signal_windowed = signal_clean .* hann(N);
else
    signal_windowed = signal_clean;
end

% Compute FFT
Y = fft(signal_windowed, N);
freq_vector = (0:N-1) * (fs/N);
nyquist_idx = floor(N/2) + 1;

magnitude = abs(Y(1:nyquist_idx));
phase = angle(Y(1:nyquist_idx));
freq_one_sided = freq_vector(1:nyquist_idx);

% Statistical noise floor estimation
magnitude_db = 20*log10(magnitude + eps);
noise_floor_db = median(magnitude_db);
noise_std_db = std(magnitude_db);

% Define significance thresholds
threshold_3sigma = noise_floor_db + 3*noise_std_db;  % 99.7% confidence
threshold_6sigma = noise_floor_db + 6*noise_std_db;  % Very high confidence

% Find significant peaks
[peaks_3sig, locs_3sig] = findpeaks(magnitude_db, 'MinPeakHeight', threshold_3sigma, ...
    'MinPeakDistance', max(1, round(length(magnitude_db)/100)));
[peaks_6sig, locs_6sig] = findpeaks(magnitude_db, 'MinPeakHeight', threshold_6sigma, ...
    'MinPeakDistance', max(1, round(length(magnitude_db)/100)));

freq_analysis.basic_fft.frequencies = freq_one_sided;
freq_analysis.basic_fft.magnitude = magnitude;
freq_analysis.basic_fft.magnitude_db = magnitude_db;
freq_analysis.basic_fft.noise_floor_db = noise_floor_db;
freq_analysis.basic_fft.noise_std_db = noise_std_db;

% Store significant peaks
if ~isempty(locs_3sig)
    freq_analysis.peaks_3sigma.frequencies = freq_one_sided(locs_3sig);
    freq_analysis.peaks_3sigma.magnitudes = magnitude(locs_3sig);
    freq_analysis.peaks_3sigma.snr_db = peaks_3sig - noise_floor_db;
    console_log('        Found %d peaks above 3-sigma threshold\n', length(locs_3sig));
    for i = 1:length(locs_3sig)
        console_log('          %.4f Hz (SNR: %.1f dB)\n', ...
            freq_analysis.peaks_3sigma.frequencies(i), ...
            freq_analysis.peaks_3sigma.snr_db(i));
    end
else
    freq_analysis.peaks_3sigma = struct('frequencies', [], 'magnitudes', [], 'snr_db', []);
end

if ~isempty(locs_6sig)
    freq_analysis.peaks_6sigma.frequencies = freq_one_sided(locs_6sig);
    freq_analysis.peaks_6sigma.magnitudes = magnitude(locs_6sig);
    freq_analysis.peaks_6sigma.snr_db = peaks_6sig - noise_floor_db;
    console_log('        Found %d peaks above 6-sigma threshold (high confidence)\n', length(locs_6sig));
end

%% METHOD 2: WELCH POWER SPECTRAL DENSITY
console_log('      Method 2: Welch PSD estimation...\n');

if N > 64
    window_length = min(256, floor(N/4));
    overlap = floor(window_length/2);
    nfft = max(256, 2^nextpow2(window_length));
    
    [psd, freq_welch] = pwelch(signal_clean, hamming(window_length), overlap, nfft, fs);
    psd_db = 10*log10(psd + eps);
    
    % Find peaks in PSD
    psd_noise_floor = median(psd_db);
    psd_threshold = psd_noise_floor + 6;  % 6 dB above noise floor
    
    [psd_peaks, psd_locs] = findpeaks(psd_db, 'MinPeakHeight', psd_threshold, ...
        'MinPeakDistance', max(1, round(length(psd_db)/50)));
    
    freq_analysis.welch_psd.frequencies = freq_welch;
    freq_analysis.welch_psd.psd = psd;
    freq_analysis.welch_psd.psd_db = psd_db;
    freq_analysis.welch_psd.noise_floor_db = psd_noise_floor;
    
    if ~isempty(psd_locs)
        freq_analysis.welch_psd.peak_frequencies = freq_welch(psd_locs);
        freq_analysis.welch_psd.peak_powers = psd(psd_locs);
        freq_analysis.welch_psd.peak_snr_db = psd_peaks - psd_noise_floor;
        console_log('        Welch method found %d significant peaks\n', length(psd_locs));
        for i = 1:length(psd_locs)
            console_log('          %.4f Hz (SNR: %.1f dB)\n', ...
                freq_analysis.welch_psd.peak_frequencies(i), ...
                freq_analysis.welch_psd.peak_snr_db(i));
        end
    end
else
    console_log('        Signal too short for Welch analysis\n');
    freq_analysis.welch_psd = struct();
end

%% METHOD 3: WINDOWED SPECTROGRAM ANALYSIS
console_log('      Method 3: Time-frequency evolution...\n');

if N > 32
    spec_window = min(64, floor(N/3));
    spec_overlap = floor(spec_window * 0.75);
    spec_nfft = max(128, 2^nextpow2(spec_window));
    
    [S, F, T] = spectrogram(signal_clean, hamming(spec_window), spec_overlap, spec_nfft, fs);
    S_power = abs(S).^2;
    S_db = 10*log10(S_power + eps);
    
    % Find frequencies that are consistently present across time
    mean_power_across_time = mean(S_db, 2);  % Average power for each frequency
    persistent_threshold = max(mean_power_across_time) - 10;  % Within 10 dB of max
    
    persistent_freq_mask = mean_power_across_time > persistent_threshold;
    persistent_frequencies = F(persistent_freq_mask);
    
    freq_analysis.spectrogram.frequencies = F;
    freq_analysis.spectrogram.time = T;
    freq_analysis.spectrogram.power_db = S_db;
    freq_analysis.spectrogram.persistent_frequencies = persistent_frequencies;
    
    console_log('        Found %d persistent frequencies across time window\n', ...
        length(persistent_frequencies));
    if ~isempty(persistent_frequencies)
        for i = 1:length(persistent_frequencies)
            console_log('          %.4f Hz (persistent)\n', persistent_frequencies(i));
        end
    end
else
    console_log('        Signal too short for spectrogram analysis\n');
    freq_analysis.spectrogram = struct();
end

%% METHOD 4: FREQUENCY BAND ANALYSIS
console_log('      Method 4: Frequency band power analysis...\n');

% Define frequency bands based on physical expectations
bands = struct();
bands.very_low = [0, 0.005];        % < 0.005 Hz (> 200 seconds)
bands.low = [0.005, 0.02];          % 0.005-0.02 Hz (50-200 seconds)  
bands.moderate = [0.02, 0.1];       % 0.02-0.1 Hz (10-50 seconds)
bands.high = [0.1, 0.5];            % 0.1-0.5 Hz (2-10 seconds)
bands.very_high = [0.5, fs/2];      % > 0.5 Hz (< 2 seconds)

total_power = sum(magnitude.^2);
for band_name = fieldnames(bands)'
    band_range = bands.(band_name{1});
    band_mask = freq_one_sided >= band_range(1) & freq_one_sided <= band_range(2);
    
    if any(band_mask)
        band_power = sum(magnitude(band_mask).^2);
        band_percentage = 100 * band_power / total_power;
        freq_analysis.band_analysis.(band_name{1}).power = band_power;
        freq_analysis.band_analysis.(band_name{1}).percentage = band_percentage;
        freq_analysis.band_analysis.(band_name{1}).frequency_range = band_range;
        
        console_log('        %s (%.3f-%.3f Hz): %.1f%% of total power\n', ...
            band_name{1}, band_range(1), band_range(2), band_percentage);
    end
end

%% SUMMARY
console_log('      Summary of frequency identification:\n');
console_log('        Analysis duration: %.1f minutes\n', analysis_duration/60);
console_log('        Frequency resolution: %.4f Hz\n', fs/N);
console_log('        Noise floor: %.1f dB\n', noise_floor_db);

% Combine all detected frequencies
all_detected_freqs = [];
if isfield(freq_analysis, 'peaks_3sigma') && ~isempty(freq_analysis.peaks_3sigma.frequencies)
    all_detected_freqs = [all_detected_freqs; freq_analysis.peaks_3sigma.frequencies(:)];
end
if isfield(freq_analysis, 'welch_psd') && isfield(freq_analysis.welch_psd, 'peak_frequencies')
    all_detected_freqs = [all_detected_freqs; freq_analysis.welch_psd.peak_frequencies(:)];
end
if isfield(freq_analysis, 'spectrogram') && ~isempty(freq_analysis.spectrogram.persistent_frequencies)
    all_detected_freqs = [all_detected_freqs; freq_analysis.spectrogram.persistent_frequencies(:)];
end

% Remove duplicates and sort
if ~isempty(all_detected_freqs)
    unique_freqs = unique(round(all_detected_freqs, 4));
    freq_analysis.summary.detected_frequencies = unique_freqs;
    console_log('        Total unique frequencies detected: %d\n', length(unique_freqs));
    console_log('        Frequency list: ');
    for i = 1:length(unique_freqs)
        console_log('%.4f ', unique_freqs(i));
        if mod(i, 10) == 0  % Line break every 10 frequencies
            console_log('\n                        ');
        end
    end
    console_log('Hz\n');
else
    freq_analysis.summary.detected_frequencies = [];
    console_log('        No significant frequencies detected\n');
end

console_log('        Detailed frequency analysis complete\n');

end
