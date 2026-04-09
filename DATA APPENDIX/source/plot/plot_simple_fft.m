function plot_simple_fft(das_data, test_label, config)
%PLOT_SIMPLE_FFT Create simple 2-subplot FFT figure
%
% Creates a clean 2-subplot figure:
% 1. Time domain signal
% 2. Frequency domain (FFT)

console_log('      Creating simple FFT analysis...\n');

% Get analysis data
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start = min(das_data.analysis_time);
    analysis_end = max(das_data.analysis_time);
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
    
    signal = das_data.smoothed_data(analysis_mask, round(size(das_data.smoothed_data,2)/2));
    time_array = das_data.time_array(analysis_mask);
    
    % Use actual datetime for x-axis
    use_datetime = true;
else
    signal = das_data.smoothed_data(:, round(size(das_data.smoothed_data,2)/2));
    time_minutes = (0:length(signal)-1) / 60;  % Assuming 1 Hz sampling
    use_datetime = false;
end

% Get sampling rate
if isstruct(config)
    fs = get_config_param(config, 'sampling_rate', 1.0);
else
    fs = 1.0;  % Default
end

%% Subplot 1: Time Domain
subplot(1,2,1);

if use_datetime
    plot(time_array, signal, 'b-', 'LineWidth', 1.5);
    xlabel('Time (UTC)', 'FontSize', 12, 'FontWeight', 'bold');
    % Format x-axis to show time nicely
    xtickformat('HH:mm:ss');
    xtickangle(45);
else
    plot(time_minutes, signal, 'b-', 'LineWidth', 1.5);
    xlabel('Time (minutes)', 'FontSize', 12, 'FontWeight', 'bold');
end

grid on;
ylabel('Amplitude', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('%s - Time Domain', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');

% Add some basic statistics
signal_std = std(signal);
signal_mean = mean(signal);
text(0.02, 0.98, sprintf('Mean: %.3f\nStd: %.3f', signal_mean, signal_std), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);


%% Subplot 2: Frequency Domain
subplot(1,2,2);

% Prepare signal for FFT
signal_clean = detrend(signal - mean(signal));
N = length(signal_clean);

if N > 1
    % Apply window to reduce spectral leakage
    windowed_signal = signal_clean .* hann(N);
    
    % Compute FFT
    Y = fft(windowed_signal, N);
    freq_vector = (0:N-1) * (fs/N);
    
    % One-sided spectrum
    nyquist_idx = floor(N/2) + 1;
    magnitude = abs(Y(1:nyquist_idx));
    freq_one_sided = freq_vector(1:nyquist_idx);
    
    % Plot frequency spectrum
    plot(freq_one_sided, magnitude, 'r-', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Magnitude', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('%s - Frequency Domain', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');
    
    % Focus on interesting frequency range
    xlim([0 min(0.5, max(freq_one_sided))]);
    
    % Find and mark dominant peak
    [max_mag, max_idx] = max(magnitude(2:end));  % Skip DC component
    max_freq = freq_one_sided(max_idx + 1);  % +1 because we skipped DC
    
    hold on;
    plot(max_freq, max_mag, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'green', 'LineWidth', 2);
    text(max_freq, max_mag*1.1, sprintf('%.3f Hz', max_freq), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'green', ...
        'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'green');
    hold off;
    
    % Add frequency bands
    yl = ylim;
    hold on;
    % Groundwater band (< 0.1 Hz)
    fill([0 0.1 0.1 0], [yl(1) yl(1) yl(2) yl(2)], 'green', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    text(0.05, yl(2)*0.9, 'Groundwater', 'HorizontalAlignment', 'center', ...
        'FontSize', 9, 'Color', 'green', 'FontWeight', 'bold');
    
    % Equipment noise band (> 0.1 Hz)
    if max(freq_one_sided) > 0.1
        fill([0.1 min(0.5, max(freq_one_sided)) min(0.5, max(freq_one_sided)) 0.1], ...
            [yl(1) yl(1) yl(2) yl(2)], 'red', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        text(0.3, yl(2)*0.9, 'Equipment', 'HorizontalAlignment', 'center', ...
            'FontSize', 9, 'Color', 'red', 'FontWeight', 'bold');
    end
    hold off;
    
else
    text(0.5, 0.5, 'Insufficient data for FFT', 'HorizontalAlignment', 'center');
    title('FFT - No Data');
end

%% Overall formatting
sgtitle(sprintf('Simple FFT Analysis - %s', upper(test_label)), ...
    'FontSize', 16, 'FontWeight', 'bold');

console_log('        Simple FFT analysis complete\n');

end
