function plot_fft_analysis_improved(das_data, fft_results, test_label, analysis_start, analysis_end, ~)
%PLOT_FFT_ANALYSIS_IMPROVED Create groundwater DAS FFT figure: Time → Frequency
%
% Creates a focused 2-subplot figure showing DAS recovery analysis:
% 1. Recovery Spectrogram - Time-frequency evolution during pump recovery
% 2. Frequency Spectrum - FFT showing groundwater vs noise frequency separation
%
% Contextual for groundwater monitoring:
% - Low frequencies (< 0.1 Hz): Groundwater recovery signals
% - High frequencies (> 0.1 Hz): Equipment noise and artifacts

fprintf('      Creating groundwater DAS FFT analysis figure...\n');

%% Left Plot: Recovery Spectrogram
subplot(1,2,1);

% Get analysis window data
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start_time = min(das_data.analysis_time);
    analysis_end_time = max(das_data.analysis_time);
    analysis_mask = das_data.time_array >= analysis_start_time & das_data.time_array <= analysis_end_time;
    
    analysis_signal = das_data.smoothed_data(analysis_mask, fft_results.rep_channel);
    analysis_times = das_data.time_array(analysis_mask);
    
    % Convert datetime to minutes from start for cleaner display
    time_minutes = minutes(analysis_times - analysis_times(1));
else
    analysis_signal = das_data.smoothed_data(1:fft_results.N, fft_results.rep_channel);
    time_minutes = (0:length(analysis_signal)-1) / fft_results.fs / 60;
end

% Create spectrogram for recovery analysis
window_size = min(64, floor(length(analysis_signal)/4));
overlap = round(window_size * 0.75);
nfft = max(128, 2^nextpow2(window_size));

[S, F, T] = spectrogram(detrend(analysis_signal), hamming(window_size), overlap, nfft, fft_results.fs);

% Convert to dB and plot
S_dB = 10*log10(abs(S).^2 + eps);

% Plot spectrogram
imagesc(T/60, F, S_dB);  % Convert time to minutes
axis xy;
colormap(gca, 'jet');
c1 = colorbar;
c1.Label.String = 'Power (dB)';
c1.Label.FontSize = 10;

% Limit frequency range to focus on groundwater signals
ylim([0 min(0.25, fft_results.fs/2)]);
xlabel('Time (minutes)', 'FontSize', 12);
ylabel('Frequency (Hz)', 'FontSize', 12);
title('PT01b Recovery Spectrogram', 'FontSize', 14, 'FontWeight', 'bold');

% Add frequency band annotations
hold on;
% Groundwater recovery signal band
fill([0 max(T/60) max(T/60) 0], [0 0 0.1 0.1], 'green', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
text(max(T/60)*0.7, 0.05, 'Groundwater Recovery', 'FontSize', 10, 'Color', 'green', ...
    'FontWeight', 'bold', 'BackgroundColor', 'white');

% Equipment noise band  
if max(F) > 0.1
    fill([0 max(T/60) max(T/60) 0], [0.1 0.1 min(0.25, max(F)) min(0.25, max(F))], ...
        'red', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    text(max(T/60)*0.7, 0.15, 'Equipment Noise', 'FontSize', 10, 'Color', 'red', ...
        'FontWeight', 'bold', 'BackgroundColor', 'white');
end
hold off;

%% Right Plot: PT01b Recovery FFT Spectrum
subplot(1,2,2);
cla; % Clear current axes to ensure clean state

% Plot magnitude spectrum with groundwater context
freq_hz = fft_results.freq_vector;
magnitude = fft_results.magnitude;

% Use linear scale for better groundwater signal visualization
plot(freq_hz, magnitude, 'b-', 'LineWidth', 2);

% Set basic labels immediately after initial plot
xlabel('Frequency (Hz)', 'FontSize', 12);
ylabel('Magnitude', 'FontSize', 12);
title('PT01b Recovery FFT', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

hold on;

% Shade frequency bands for groundwater monitoring context
yl = ylim;
xl = xlim;

% Groundwater recovery signal band (0 - 0.1 Hz)
groundwater_mask = freq_hz <= 0.1;
if any(groundwater_mask)
    fill([0 0.1 0.1 0], [yl(1) yl(1) yl(2) yl(2)], 'green', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    text(0.05, yl(2)*0.9, 'Groundwater Recovery', 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'Color', 'green', 'FontWeight', 'bold', 'BackgroundColor', 'white');
end

% Equipment/Grid noise band (0.1 - 0.25 Hz, limited to plot area)
plot_max_freq = min(0.25, max(freq_hz));
noise_band_max = plot_max_freq;
if noise_band_max > 0.1
    fill([0.1 noise_band_max noise_band_max 0.1], [yl(1) yl(1) yl(2) yl(2)], ...
        'red', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    % Position text within visible plot area
    text_x_pos = min(0.175, (0.1 + noise_band_max)/2);  % Ensure text is within [0.1, 0.25] range
    text(text_x_pos, yl(2)*0.8, 'Equipment Noise', 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold', 'BackgroundColor', 'white');
end

% Highlight groundwater frequency components - find peaks directly from plotted data
% Find peaks in the low frequency range (0-0.1 Hz) for better accuracy
low_freq_mask = freq_hz <= 0.1 & freq_hz > 0;  % Exclude DC component
if any(low_freq_mask)
    low_freq_range = freq_hz(low_freq_mask);
    low_mag_range = magnitude(low_freq_mask);
    
    % Find the top 2 peaks in groundwater frequency range
    [peak_mags, peak_locs] = findpeaks(low_mag_range, 'SortStr', 'descend', 'NPeaks', 2);
    
    if ~isempty(peak_mags)
        for i = 1:length(peak_mags)
            freq_val = low_freq_range(peak_locs(i));
            mag_val = peak_mags(i);
            
            % Mark groundwater peaks in green  
            plot(freq_val, mag_val, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'green', 'LineWidth', 2);
            text(freq_val, mag_val*1.2, sprintf('%.3f Hz', freq_val), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'green', ...
                'BackgroundColor', 'white', 'FontWeight', 'bold', 'EdgeColor', 'green');
        end
    end
end

% Also mark any detected dominant frequencies in groundwater range (fallback)
if ~isempty(fft_results.dominant_frequencies)
    groundwater_freqs = fft_results.dominant_frequencies(fft_results.dominant_frequencies <= 0.1);
    groundwater_mags = fft_results.dominant_magnitudes(fft_results.dominant_frequencies <= 0.1);
    
    for i = 1:length(groundwater_freqs)
        freq_val = groundwater_freqs(i);
        mag_val = groundwater_mags(i);
        
        % Mark with smaller markers (backup peaks)
        plot(freq_val, mag_val, 'g^', 'MarkerSize', 8, 'MarkerFaceColor', 'lightgreen', 'LineWidth', 1);
    end
    
    % Mark noise frequencies
    noise_freqs = fft_results.dominant_frequencies(fft_results.dominant_frequencies > 0.1);
    noise_mags = fft_results.dominant_magnitudes(fft_results.dominant_frequencies > 0.1);
    
    for i = 1:min(3, length(noise_freqs))  % Show only top 3 noise peaks
        freq_val = noise_freqs(i);
        mag_val = noise_mags(i);
        
        % Mark noise peaks in red
        plot(freq_val, mag_val, 'rs', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'LineWidth', 1);
    end
end

hold off;

% Set axis limits first
xlim([0 min(0.25, max(freq_hz))]);  % Focus on low frequencies

% Add recovery analysis summary
recovery_power = sum(fft_results.psd(freq_hz <= 0.1));
total_power = sum(fft_results.psd);
recovery_percentage = 100 * recovery_power / total_power;

text(0.98, 0.88, sprintf('Recovery Signal: %.1f%%\nNoise: %.1f%%\nFilter Cutoff: ~%.2f Hz', ...
    recovery_percentage, 100-recovery_percentage, 0.2), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'FontSize', 10, 'EdgeColor', 'black');

% Labels were set earlier - just ensure final formatting
drawnow; % Force immediate rendering


%% Overall figure formatting
sgtitle('Groundwater DAS: Time-Frequency Analysis of Recovery Signal', ...
    'FontSize', 16, 'FontWeight', 'bold');

% Add subtitle with context
annotation('textbox', [0.2 0.02 0.6 0.05], ...
    'String', 'Left: Spectrogram shows recovery evolution | Right: FFT separates groundwater signals from noise', ...
    'HorizontalAlignment', 'center', 'FontSize', 11, ...
    'EdgeColor', 'none', 'BackgroundColor', 'none');

fprintf('        Fundamental FFT analysis figure created\n');

end
