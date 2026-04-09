function plot_fft_analysis_clean(das_data, fft_results, test_label, analysis_start, analysis_end, ~)
%PLOT_FFT_ANALYSIS_CLEAN Create clean FFT analysis figure like reference
%
% Creates a simple 2-subplot figure with clean styling:
% 1. Left: Spectrogram showing time-frequency evolution
% 2. Right: FFT spectrum with clear noise identification
%
% Designed for reliability and professional appearance

console_log('      Creating clean FFT analysis figure...\n');

%% Setup figure
figure;
set(gcf, 'Position', [400, 100, 1200, 500]);

%% Left Plot: Spectrogram
subplot(1,2,1);

% Get analysis data
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start_time = min(das_data.analysis_time);
    analysis_end_time = max(das_data.analysis_time);
    analysis_mask = das_data.time_array >= analysis_start_time & das_data.time_array <= analysis_end_time;
    
    analysis_signal = das_data.smoothed_data(analysis_mask, fft_results.rep_channel);
    analysis_times = das_data.time_array(analysis_mask);
    
    % Convert to time from start in minutes
    time_start = analysis_times(1);
    time_minutes = minutes(analysis_times - time_start);
else
    analysis_signal = das_data.smoothed_data(:, fft_results.rep_channel);
    time_minutes = (0:length(analysis_signal)-1) / fft_results.fs / 60;
end

% Create spectrogram
window_size = min(64, floor(length(analysis_signal)/3));
overlap = round(window_size * 0.75);
nfft = 128;

[S, F, T] = spectrogram(detrend(analysis_signal), hamming(window_size), overlap, nfft, fft_results.fs);

% Convert to power and dB
S_power = abs(S).^2;
S_dB = 10*log10(S_power + eps);

% Plot spectrogram with clean styling
imagesc(T/60, F, S_dB);
axis xy;
colormap('jet');
cb1 = colorbar;
cb1.Label.String = 'Power (dB)';
cb1.Label.FontSize = 11;

% Set frequency limits to focus on relevant range
ylim([0 0.25]);

% Add clean labels
xlabel('Time (min)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('%s Spectrogram', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');

% Add clean frequency band annotations
hold on;
% Low frequency band (groundwater)
y_low = [0, 0.1, 0.1, 0];
x_span = [min(T/60), max(T/60), max(T/60), min(T/60)];
fill(x_span, y_low, 'green', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
text(max(T/60)*0.8, 0.05, 'Low Frequency Noise from equipment', ...
    'FontSize', 10, 'Color', 'black', 'FontWeight', 'bold', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Higher frequency band (equipment noise)
if max(F) > 0.1
    y_high = [0.1, min(0.25, max(F)), min(0.25, max(F)), 0.1];
    fill(x_span, y_high, 'red', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    text(max(T/60)*0.8, 0.18, 'Propeller Noise', ...
        'FontSize', 10, 'Color', 'black', 'FontWeight', 'bold', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black');
end
hold off;

%% Right Plot: FFT Spectrum
subplot(1,2,2);

% Get frequency data
freq_hz = fft_results.freq_vector;
magnitude = fft_results.magnitude;

% Plot clean spectrum
plot(freq_hz, magnitude, 'b-', 'LineWidth', 1.5);

% Add clean labels immediately
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitude', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('%s FFT', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');
grid on;

% Set clean axis limits
xlim([0 min(1000, max(freq_hz))]);
ylim([0 max(magnitude)*1.1]);

hold on;

% Find and mark dominant peaks
if length(freq_hz) > 10 && max(magnitude) > 0
    % Find peaks in low frequency range (< 0.1 Hz)
    low_freq_mask = freq_hz <= 0.1 & freq_hz > 0;
    if any(low_freq_mask)
        low_freqs = freq_hz(low_freq_mask);
        low_mags = magnitude(low_freq_mask);
        [~, peak_locs] = findpeaks(low_mags, 'MinPeakHeight', max(low_mags)*0.3, 'NPeaks', 3);
        
        if ~isempty(peak_locs)
            peak_freqs = low_freqs(peak_locs);
            peak_mags = low_mags(peak_locs);
            
            % Mark low frequency peaks
            plot(peak_freqs, peak_mags, 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'green', 'LineWidth', 2);
            
            % Label significant peaks
            for i = 1:length(peak_freqs)
                text(peak_freqs(i), peak_mags(i)*1.15, sprintf('%.3f Hz', peak_freqs(i)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'green', ...
                    'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'green');
            end
        end
    end
    
    % Find peaks in equipment noise range (> 0.1 Hz)
    noise_freq_mask = freq_hz > 0.1 & freq_hz <= 1.0;
    if any(noise_freq_mask)
        noise_freqs = freq_hz(noise_freq_mask);
        noise_mags = magnitude(noise_freq_mask);
        [~, noise_peak_locs] = findpeaks(noise_mags, 'MinPeakHeight', max(noise_mags)*0.5, 'NPeaks', 2);
        
        if ~isempty(noise_peak_locs)
            noise_peak_freqs = noise_freqs(noise_peak_locs);
            noise_peak_mags = noise_mags(noise_peak_locs);
            
            % Mark noise peaks
            plot(noise_peak_freqs, noise_peak_mags, 'rs', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'LineWidth', 2);
            
            % Add dotted lines like in reference
            for i = 1:length(noise_peak_freqs)
                plot([noise_peak_freqs(i) noise_peak_freqs(i)], [0 max(magnitude)*1.1], ...
                    'r--', 'LineWidth', 1.5);
                text(noise_peak_freqs(i), max(magnitude)*0.9, 'Propeller Noise', ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'red', ...
                    'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'red');
            end
        end
    end
end

% Add frequency band shading like reference
yl = ylim;
% Low frequency equipment noise band
fill([0 100 100 0], [yl(1) yl(1) yl(2) yl(2)], 'cyan', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
text(50, yl(2)*0.1, 'Low Frequency Noise from equipment', ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
    'FontWeight', 'bold', 'Rotation', 0);

hold off;

%% Overall formatting
sgtitle(sprintf('Groundwater DAS: Time-Frequency Analysis of %s Signal', upper(test_label)), ...
    'FontSize', 16, 'FontWeight', 'bold');

% Force rendering
drawnow;

console_log('        Clean FFT analysis figure created\n');

end







