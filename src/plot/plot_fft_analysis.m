function plot_fft_analysis(das_data, fft_results, test_label, analysis_start, analysis_end, ~)
%PLOT_FFT_ANALYSIS Create comprehensive FFT analysis figure (Figure 4)
%
% Generates a 4-subplot figure showing frequency domain analysis:
% 1. Power Spectral Density (PSD) - Overall frequency content
% 2. Spatial Frequency Coherence - Channel-to-channel consistency  
% 3. Time-Frequency Evolution - Spectrogram showing frequency changes over time
% 4. Frequency Band Analysis - Power distribution across frequency bands
%
% Inputs:
%   das_data       - DAS analysis results structure
%   fft_results    - FFT analysis results from analyze_fft_spectrum
%   test_label     - Test identifier string
%   analysis_start - Analysis window start time
%   analysis_end   - Analysis window end time  
%   config         - Configuration structure

fprintf('      Creating FFT analysis figure...\n');

%% Subplot 1: Power Spectral Density (PSD)
subplot(2,2,1);

% Plot PSD with log scale for better visualization
semilogy(fft_results.freq_vector, fft_results.psd_values, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight dominant frequencies
if ~isempty(fft_results.dominant_freqs)
    for i = 1:length(fft_results.dominant_freqs)
        freq_val = fft_results.dominant_freqs(i);
        power_val = fft_results.dominant_powers(i);
        plot(freq_val, power_val, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
        text(freq_val, power_val*1.5, sprintf('%.3f Hz', freq_val), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'red');
    end
end

% Mark known grid pattern frequency ranges
grid_slow_mask = fft_results.freq_vector >= 0.15 & fft_results.freq_vector <= 0.33;
grid_fast_mask = fft_results.freq_vector >= 0.35 & fft_results.freq_vector <= 0.45;

if any(grid_slow_mask)
    y_limits = ylim;
    fill([0.15 0.33 0.33 0.15], [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
        'red', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    text(0.24, y_limits(2)*0.8, 'Slow Grid', 'HorizontalAlignment', 'center', ...
        'FontSize', 8, 'Color', 'red', 'FontWeight', 'bold');
end

if any(grid_fast_mask)
    y_limits = ylim;
    fill([0.35 0.45 0.45 0.35], [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
        'magenta', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    text(0.40, y_limits(2)*0.6, 'Fast Grid', 'HorizontalAlignment', 'center', ...
        'FontSize', 8, 'Color', 'magenta', 'FontWeight', 'bold');
end

hold off;
grid on;
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density');
title(sprintf('PSD - Channel %d (%.0f ft)', fft_results.rep_channel, ...
    das_data.depth_ft(fft_results.rep_channel)));
xlim([0 max(fft_results.freq_vector)]);

%% Subplot 2: Spatial Frequency Coherence
subplot(2,2,2);

% Plot coherence as heatmap
if isfield(fft_results, 'coherence_matrix')
    imagesc(fft_results.coherence_channels, fft_results.freq_vector, fft_results.coherence_matrix);
    colormap(gca, 'hot');
    c2 = colorbar;
    c2.Label.String = 'Coherence';
    axis xy;  % Correct orientation
    
    xlabel('Channel Number');
    ylabel('Frequency (Hz)');
    title('Spatial Frequency Coherence');
    
    % Add depth labels on right axis if available
    if isfield(das_data, 'depth_ft')
        % depth_subset = das_data.depth_ft(fft_results.coherence_channels); % Unused for now
        yyaxis right;
        ylabel('Depth (ft)');
        ylim([min(fft_results.freq_vector) max(fft_results.freq_vector)]);
        set(gca, 'YColor', 'k');
        yyaxis left;
    end
else
    text(0.5, 0.5, 'Coherence analysis not available', 'HorizontalAlignment', 'center');
    title('Spatial Frequency Coherence - No Data');
end

%% Subplot 3: Time-Frequency Evolution (Spectrogram)
subplot(2,2,3);

if isfield(fft_results, 'spectrogram')
    % Convert power to dB for better visualization
    S_dB = 10*log10(fft_results.spectrogram.power + eps);
    
    % Plot spectrogram
    imagesc(fft_results.spectrogram.time_absolute, fft_results.spectrogram.frequencies, S_dB);
    axis xy;  % Correct time orientation
    colormap(gca, 'jet');
    c3 = colorbar;
    c3.Label.String = 'Power (dB)';
    
    xlabel('Time');
    ylabel('Frequency (Hz)');
    title('Time-Frequency Evolution');
    
    % Set time limits to analysis window
    xlim([analysis_start analysis_end]);
    ylim([0 max(fft_results.freq_vector)]);
    
    % Add grid pattern frequency markers
    hold on;
    plot([analysis_start analysis_end], [0.24 0.24], 'r--', 'LineWidth', 2); % Slow grid center
    plot([analysis_start analysis_end], [0.40 0.40], 'm--', 'LineWidth', 2); % Fast grid center
    hold off;
else
    text(0.5, 0.5, 'Spectrogram not available', 'HorizontalAlignment', 'center');
    title('Time-Frequency Evolution - No Data');
end

%% Subplot 4: Frequency Band Power Analysis
subplot(2,2,4);

% Create bar chart of power in different frequency bands
band_names = {'Low Freq\n(<0.1 Hz)', 'Slow Grid\n(0.15-0.33 Hz)', 'Fast Grid\n(0.35-0.45 Hz)', 'Other'};
band_powers = [fft_results.power_bands.low_freq, ...
               fft_results.power_bands.grid_slow, ...
               fft_results.power_bands.grid_fast, ...
               fft_results.power_bands.total - fft_results.power_bands.low_freq - ...
               fft_results.power_bands.grid_slow - fft_results.power_bands.grid_fast];

% Normalize to percentages
band_percentages = 100 * band_powers / fft_results.power_bands.total;

% Create bar plot with color coding
bar_colors = [0.2 0.7 0.2;    % Green for low freq (geological)
              1.0 0.3 0.3;    % Red for slow grid (artifact)
              1.0 0.1 0.8;    % Magenta for fast grid (artifact) 
              0.5 0.5 0.5];   % Gray for other

bar_handle = bar(band_percentages, 'FaceColor', 'flat');
bar_handle.CData = bar_colors;

% Add percentage labels on bars
for i = 1:length(band_percentages)
    text(i, band_percentages(i) + max(band_percentages)*0.02, ...
        sprintf('%.1f%%', band_percentages(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

set(gca, 'XTickLabel', band_names);
ylabel('Power Distribution (%)');
title('Frequency Band Power Analysis');
grid on;
ylim([0 max(band_percentages)*1.2]);

% Add noise analysis text
if isfield(fft_results, 'noise_analysis')
    noise_text = '';
    if fft_results.noise_analysis.has_slow_grid
        noise_text = [noise_text sprintf('Slow Grid: %.1fx\n', fft_results.noise_analysis.grid_slow_ratio)];
    end
    if fft_results.noise_analysis.has_fast_grid
        noise_text = [noise_text sprintf('Fast Grid: %.1fx\n', fft_results.noise_analysis.grid_fast_ratio)];
    end
    if ~isempty(noise_text)
        text(0.02, 0.98, sprintf('Grid Artifacts:\n%s', noise_text), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', ...
            'FontSize', 9, 'BackgroundColor', 'yellow', 'EdgeColor', 'black');
    end
end

%% Overall figure formatting
sgtitle(sprintf('FFT Analysis - Test %s', upper(test_label)), 'FontSize', 14, 'FontWeight', 'bold');

% Add analysis summary as figure annotation
summary_text = sprintf('Analysis: %.0f samples, Representative Channel: %d (%.0f ft)', ...
    size(das_data.smoothed_data, 1), fft_results.rep_channel, ...
    das_data.depth_ft(fft_results.rep_channel));

if ~isempty(fft_results.dominant_freqs)
    summary_text = [summary_text sprintf('\nDominant Frequencies: ')];
    for i = 1:min(3, length(fft_results.dominant_freqs))  % Show max 3 frequencies
        summary_text = [summary_text sprintf('%.3f Hz ', fft_results.dominant_freqs(i))];
    end
    if length(fft_results.dominant_freqs) > 3
        summary_text = [summary_text '...'];
    end
end

annotation('textbox', [0.02 0.02 0.96 0.08], 'String', summary_text, ...
    'FitBoxToText', 'on', 'FontSize', 10, 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'HorizontalAlignment', 'left');

fprintf('        FFT analysis figure created\n');

end
