function plot_frequency_analysis_detailed(freq_analysis, test_label)
%PLOT_FREQUENCY_ANALYSIS_DETAILED Create comprehensive frequency analysis plots
%
% Shows multiple methods for frequency identification:
% 1. FFT with statistical thresholds
% 2. Welch PSD estimation
% 3. Spectrogram (time-frequency evolution)
% 4. Frequency band power distribution

fprintf('      Creating detailed frequency analysis plots...\n');

figure;
set(gcf, 'Position', [100, 100, 1400, 900]);

%% Subplot 1: FFT with Statistical Peak Detection
subplot(2,3,1);

if isfield(freq_analysis, 'basic_fft')
    fft_data = freq_analysis.basic_fft;
    
    % Plot magnitude spectrum
    plot(fft_data.frequencies, fft_data.magnitude_db, 'b-', 'LineWidth', 1);
    hold on;
    
    % Add noise floor lines
    yline(fft_data.noise_floor_db, 'k--', 'LineWidth', 1, 'DisplayName', 'Noise Floor');
    yline(fft_data.noise_floor_db + 3*fft_data.noise_std_db, 'r--', 'LineWidth', 1, 'DisplayName', '3σ Threshold');
    yline(fft_data.noise_floor_db + 6*fft_data.noise_std_db, 'm--', 'LineWidth', 1, 'DisplayName', '6σ Threshold');
    
    % Mark significant peaks
    if isfield(freq_analysis, 'peaks_3sigma') && ~isempty(freq_analysis.peaks_3sigma.frequencies)
        peak_mags_db = 20*log10(freq_analysis.peaks_3sigma.magnitudes + eps);
        plot(freq_analysis.peaks_3sigma.frequencies, peak_mags_db, 'ro', ...
            'MarkerSize', 8, 'MarkerFaceColor', 'red', 'DisplayName', '3σ Peaks');
        
        % Label peaks
        for i = 1:length(freq_analysis.peaks_3sigma.frequencies)
            text(freq_analysis.peaks_3sigma.frequencies(i), peak_mags_db(i) + 2, ...
                sprintf('%.3f Hz', freq_analysis.peaks_3sigma.frequencies(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'red', 'FontWeight', 'bold');
        end
    end
    
    if isfield(freq_analysis, 'peaks_6sigma') && ~isempty(freq_analysis.peaks_6sigma.frequencies)
        peak_mags_db = 20*log10(freq_analysis.peaks_6sigma.magnitudes + eps);
        plot(freq_analysis.peaks_6sigma.frequencies, peak_mags_db, 'ms', ...
            'MarkerSize', 10, 'MarkerFaceColor', 'magenta', 'DisplayName', '6σ Peaks');
    end
    
    hold off;
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title('FFT with Statistical Peak Detection');
    legend('Location', 'best');
    xlim([0 min(0.5, max(fft_data.frequencies))]);
end

%% Subplot 2: Welch PSD Estimation
subplot(2,3,2);

if isfield(freq_analysis, 'welch_psd') && isfield(freq_analysis.welch_psd, 'frequencies')
    welch_data = freq_analysis.welch_psd;
    
    % Plot PSD
    plot(welch_data.frequencies, welch_data.psd_db, 'g-', 'LineWidth', 1.5);
    hold on;
    
    % Add noise floor
    yline(welch_data.noise_floor_db, 'k--', 'LineWidth', 1, 'DisplayName', 'Noise Floor');
    yline(welch_data.noise_floor_db + 6, 'r--', 'LineWidth', 1, 'DisplayName', '6 dB Threshold');
    
    % Mark peaks
    if isfield(welch_data, 'peak_frequencies') && ~isempty(welch_data.peak_frequencies)
        peak_powers_db = 10*log10(welch_data.peak_powers + eps);
        plot(welch_data.peak_frequencies, peak_powers_db, 'go', ...
            'MarkerSize', 8, 'MarkerFaceColor', 'green', 'DisplayName', 'PSD Peaks');
        
        % Label peaks
        for i = 1:length(welch_data.peak_frequencies)
            text(welch_data.peak_frequencies(i), peak_powers_db(i) + 2, ...
                sprintf('%.3f Hz', welch_data.peak_frequencies(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'green', 'FontWeight', 'bold');
        end
    end
    
    hold off;
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Power Spectral Density (dB/Hz)');
    title('Welch PSD Estimation');
    legend('Location', 'best');
    xlim([0 min(0.5, max(welch_data.frequencies))]);
else
    text(0.5, 0.5, 'Signal too short for Welch analysis', 'HorizontalAlignment', 'center');
    title('Welch PSD - No Data');
end

%% Subplot 3: Spectrogram (Time-Frequency Evolution)
subplot(2,3,3);

if isfield(freq_analysis, 'spectrogram') && isfield(freq_analysis.spectrogram, 'power_db')
    spec_data = freq_analysis.spectrogram;
    
    imagesc(spec_data.time, spec_data.frequencies, spec_data.power_db);
    axis xy;
    colormap('jet');
    cb = colorbar;
    cb.Label.String = 'Power (dB)';
    
    % Limit frequency range for better visualization
    ylim([0 min(0.5, max(spec_data.frequencies))]);
    
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title('Time-Frequency Evolution');
    
    % Mark persistent frequencies
    if ~isempty(spec_data.persistent_frequencies)
        hold on;
        for i = 1:length(spec_data.persistent_frequencies)
            yline(spec_data.persistent_frequencies(i), 'w--', 'LineWidth', 2);
            text(max(spec_data.time)*0.02, spec_data.persistent_frequencies(i), ...
                sprintf('%.3f Hz', spec_data.persistent_frequencies(i)), ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 8);
        end
        hold off;
    end
else
    text(0.5, 0.5, 'Signal too short for spectrogram analysis', 'HorizontalAlignment', 'center');
    title('Spectrogram - No Data');
end

%% Subplot 4: Frequency Band Power Distribution
subplot(2,3,4);

if isfield(freq_analysis, 'band_analysis')
    band_data = freq_analysis.band_analysis;
    band_names = fieldnames(band_data);
    
    percentages = [];
    labels = {};
    colors = [0.2 0.4 0.8; 0.4 0.6 1.0; 0.6 0.8 0.4; 1.0 0.6 0.2; 1.0 0.2 0.2];
    
    for i = 1:length(band_names)
        percentages(i) = band_data.(band_names{i}).percentage;
        freq_range = band_data.(band_names{i}).frequency_range;
        labels{i} = sprintf('%s\n(%.3f-%.3f Hz)', strrep(band_names{i}, '_', ' '), freq_range(1), freq_range(2));
    end
    
    % Create pie chart
    pie(percentages, labels);
    colormap(colors(1:length(band_names), :));
    title('Power Distribution by Frequency Band');
else
    text(0.5, 0.5, 'No band analysis data', 'HorizontalAlignment', 'center');
    title('Band Analysis - No Data');
end

%% Subplot 5: Combined Peak Summary
subplot(2,3,5);

all_freqs = [];
all_methods = {};
all_snrs = [];

% Collect all detected frequencies
if isfield(freq_analysis, 'peaks_3sigma') && ~isempty(freq_analysis.peaks_3sigma.frequencies)
    all_freqs = [all_freqs; freq_analysis.peaks_3sigma.frequencies(:)];
    all_methods = [all_methods; repmat({'FFT 3σ'}, length(freq_analysis.peaks_3sigma.frequencies), 1)];
    all_snrs = [all_snrs; freq_analysis.peaks_3sigma.snr_db(:)];
end

if isfield(freq_analysis, 'welch_psd') && isfield(freq_analysis.welch_psd, 'peak_frequencies')
    all_freqs = [all_freqs; freq_analysis.welch_psd.peak_frequencies(:)];
    all_methods = [all_methods; repmat({'Welch PSD'}, length(freq_analysis.welch_psd.peak_frequencies), 1)];
    all_snrs = [all_snrs; freq_analysis.welch_psd.peak_snr_db(:)];
end

if isfield(freq_analysis, 'spectrogram') && ~isempty(freq_analysis.spectrogram.persistent_frequencies)
    all_freqs = [all_freqs; freq_analysis.spectrogram.persistent_frequencies(:)];
    all_methods = [all_methods; repmat({'Persistent'}, length(freq_analysis.spectrogram.persistent_frequencies), 1)];
    all_snrs = [all_snrs; ones(length(freq_analysis.spectrogram.persistent_frequencies), 1) * 10];  % Arbitrary SNR for persistent
end

if ~isempty(all_freqs)
    % Create scatter plot of detected frequencies
    method_colors = containers.Map({'FFT 3σ', 'Welch PSD', 'Persistent'}, ...
                                  {[1 0 0], [0 1 0], [0 0 1]});
    
    hold on;
    for i = 1:length(all_freqs)
        if method_colors.isKey(all_methods{i})
            color = method_colors(all_methods{i});
        else
            color = [0 0 0];
        end
        scatter(all_freqs(i), all_snrs(i), 100, color, 'filled', 'DisplayName', all_methods{i});
        text(all_freqs(i), all_snrs(i) + 1, sprintf('%.3f Hz', all_freqs(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
    hold off;
    
    xlabel('Frequency (Hz)');
    ylabel('Signal-to-Noise Ratio (dB)');
    title('All Detected Frequencies');
    grid on;
    legend('Location', 'best');
    xlim([0 max(all_freqs)*1.1]);
else
    text(0.5, 0.5, 'No frequencies detected', 'HorizontalAlignment', 'center');
    title('No Detected Frequencies');
end


%% Overall title
sgtitle(sprintf('Detailed Frequency Analysis - %s', upper(test_label)), ...
    'FontSize', 16, 'FontWeight', 'bold');

fprintf('        Detailed frequency analysis plots created\n');

end
