function test_aquatroll_workflow()
%TEST_AQUATROLL_WORKFLOW Generate synthetic noisy pump test data and test cleaning
%
% This script creates synthetic Aquatroll-like data with realistic noise,
% then tests the cleaning workflow. Use this to understand the processing
% steps before applying to your real data.

fprintf('=== TESTING AQUATROLL WORKFLOW WITH SYNTHETIC DATA ===\n\n');

%% Generate Synthetic Pump Test Data
fprintf('Generating synthetic pump test data...\n');

% Time parameters
t_start = datetime(2024,1,15,10,0,0);
dt = seconds(1); % 1-second sampling
duration_hours = 6; % 6-hour pump test
num_points = duration_hours * 3600;
timestamps = t_start + seconds(0:dt:(num_points-1)*dt);

% Pump test parameters
static_pressure = 15.0; % psi (static water level)
pump_start_time = t_start + hours(1); % Start pumping after 1 hour
pump_end_time = t_start + hours(4); % Stop pumping after 4 hours
max_drawdown = 5.0; % ft maximum drawdown

% Convert ft to psi (1 psi = 2.31 ft for freshwater)
psi_to_ft = 2.31;
max_drawdown_psi = max_drawdown / psi_to_ft;

% Create idealized pump test response
pressure_ideal = static_pressure * ones(size(timestamps));

for i = 1:num_points
    t = timestamps(i);
    
    if t >= pump_start_time && t < pump_end_time
        % Pumping phase - logarithmic drawdown (Cooper-Jacob)
        t_since_start = hours(t - pump_start_time);
        if t_since_start > 0
            % Drawdown increases logarithmically
            drawdown_psi = max_drawdown_psi * log10(1 + t_since_start*10);
            pressure_ideal(i) = static_pressure - drawdown_psi;
        end
    elseif t >= pump_end_time
        % Recovery phase - logarithmic recovery (Theis recovery)
        t_since_stop = hours(t - pump_end_time);
        t_pumping = hours(pump_end_time - pump_start_time);
        
        % Horner time ratio for recovery
        if t_since_stop > 0
            horner_ratio = (t_pumping + t_since_stop) / t_since_stop;
            recovery_fraction = log10(horner_ratio) / log10(1 + t_pumping*10);
            remaining_drawdown = max_drawdown_psi * (1 - recovery_fraction);
            pressure_ideal(i) = static_pressure - remaining_drawdown;
        end
    end
end

%% Add Realistic Noise
fprintf('Adding realistic noise sources...\n');

% 1. White noise (electronic noise) - small amplitude, high frequency
white_noise = 0.005 * randn(size(pressure_ideal)); % 0.005 psi RMS

% 2. Barometric pressure drift (low frequency)
baro_freq = 1/(3*3600); % One cycle per 3 hours
baro_amplitude = 0.02; % 0.02 psi amplitude
baro_drift = baro_amplitude * sin(2*pi*baro_freq * (1:num_points) * dt);

% 3. Temperature drift (very low frequency)
temp_freq = 1/(24*3600); % Daily cycle
temp_amplitude = 0.01;
temp_drift = temp_amplitude * sin(2*pi*temp_freq * (1:num_points) * dt);

% 4. Random spikes (cable hits, electrical interference)
num_spikes = 15; % Number of spikes
spike_locations = randperm(num_points, num_spikes);
spike_amplitudes = 0.05 + 0.1*rand(num_spikes, 1); % 0.05-0.15 psi spikes
spikes = zeros(size(pressure_ideal));
for i = 1:num_spikes
    loc = spike_locations(i);
    spikes(loc) = spike_amplitudes(i) * (2*randi([0,1])-1); % Random sign
end

% 5. Short-duration high-frequency noise (pump vibration during pumping)
pump_noise = zeros(size(pressure_ideal));
pump_active = timestamps >= pump_start_time & timestamps < pump_end_time;
pump_noise(pump_active) = 0.002 * randn(sum(pump_active), 1);

% Combine all noise sources
pressure_noisy = pressure_ideal + white_noise + baro_drift' + temp_drift' + spikes' + pump_noise;

% Add a few NaN gaps (data dropouts)
dropout_locs = [1000:1005, 5000:5008, 15000]; % Some data gaps
pressure_noisy(dropout_locs) = NaN;

fprintf('✓ Synthetic data generated\n');
fprintf('  Duration: %.1f hours\n', duration_hours);
fprintf('  Sampling rate: 1 Hz\n');
fprintf('  Noise sources: white noise, barometric drift, temperature drift, spikes, pump vibration\n');
fprintf('  Data dropouts: %d points\n', length(dropout_locs));

%% Apply Cleaning Steps (mimicking process_aquatroll_pump_test.m)
fprintf('\nApplying cleaning workflow...\n');

% Step 1: Outlier detection
window_size = 50;
moving_median = movmedian(pressure_noisy, window_size, 'omitnan');
moving_mad = movmad(pressure_noisy, window_size, 'omitnan');
outlier_threshold = 3;
outliers = abs(pressure_noisy - moving_median) > outlier_threshold * moving_mad;

pressure_cleaned = pressure_noisy;
pressure_cleaned(outliers) = NaN;
fprintf('✓ Removed %d outliers\n', sum(outliers));

% Step 2: Interpolate small gaps
max_gap = 5;
pressure_cleaned = fillmissing(pressure_cleaned, 'linear', 'MaxGap', max_gap);
fprintf('✓ Interpolated small gaps\n');

% Step 3: Moving average smoothing
smooth_window = 5;
pressure_smoothed = movmean(pressure_cleaned, smooth_window, 'omitnan');
fprintf('✓ Applied %d-point moving average\n', smooth_window);

% Step 4: Savitzky-Golay filter
savgol_order = 2;
savgol_framelen = 11;
pressure_final = sgolayfilt(pressure_smoothed, savgol_order, savgol_framelen);
fprintf('✓ Applied Savitzky-Golay filter\n');

%% Calculate Drawdown
baseline_points = 3000; % First 50 minutes (before pumping starts)
static_pressure_calc = mean(pressure_final(1:baseline_points), 'omitnan');

water_level_ideal = pressure_ideal * psi_to_ft;
water_level_noisy = pressure_noisy * psi_to_ft;
water_level_cleaned = pressure_final * psi_to_ft;

static_level = static_pressure_calc * psi_to_ft;

drawdown_ideal = static_level - water_level_ideal;
drawdown_noisy = static_level - water_level_noisy;
drawdown_cleaned = static_level - water_level_cleaned;

%% Visualize Results
fprintf('\nCreating visualizations...\n');

figure('Name', 'Synthetic Aquatroll Test - Full Workflow', 'Position', [100, 100, 1400, 900]);

% Plot 1: Ideal vs Noisy vs Cleaned Pressure
subplot(4,1,1);
plot(timestamps, pressure_ideal, 'g-', 'LineWidth', 2, 'DisplayName', 'Ideal (no noise)');
hold on;
plot(timestamps, pressure_noisy, 'b-', 'LineWidth', 0.5, 'DisplayName', 'Noisy');
plot(timestamps, pressure_final, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
xline(pump_start_time, 'k--', 'Pump ON', 'LineWidth', 1.5);
xline(pump_end_time, 'k--', 'Pump OFF', 'LineWidth', 1.5);
ylabel('Pressure (psi)');
title('Synthetic Pump Test Data - Cleaning Workflow Test');
legend('Location', 'best');
grid on;
ylim([static_pressure - max_drawdown_psi - 0.2, static_pressure + 0.1]);

% Plot 2: Noise components
subplot(4,1,2);
plot(timestamps, white_noise, 'DisplayName', 'White Noise');
hold on;
plot(timestamps, baro_drift, 'DisplayName', 'Barometric Drift');
plot(timestamps, spikes, 'DisplayName', 'Spikes');
if any(outliers)
    plot(timestamps(outliers), zeros(sum(outliers),1), 'ro', 'MarkerSize', 4, 'DisplayName', 'Detected Outliers');
end
ylabel('Noise (psi)');
title('Noise Components (what we are trying to remove)');
legend('Location', 'best');
grid on;

% Plot 3: Drawdown comparison
subplot(4,1,3);
plot(timestamps, drawdown_ideal, 'g-', 'LineWidth', 2, 'DisplayName', 'Ideal');
hold on;
plot(timestamps, drawdown_noisy, 'b-', 'LineWidth', 0.5, 'DisplayName', 'Noisy');
plot(timestamps, drawdown_cleaned, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
xline(pump_start_time, 'k--', 'LineWidth', 1.5);
xline(pump_end_time, 'k--', 'LineWidth', 1.5);
ylabel('Drawdown (ft)');
title('Drawdown Time Series');
legend('Location', 'best');
grid on;

% Plot 4: Cleaning effectiveness (residuals)
subplot(4,1,4);
residual_noisy = pressure_noisy - pressure_ideal;
residual_cleaned = pressure_final - pressure_ideal;
plot(timestamps, residual_noisy, 'b-', 'LineWidth', 0.5, 'DisplayName', ...
    sprintf('Before (RMS=%.4f psi)', rms(residual_noisy, 'omitnan')));
hold on;
plot(timestamps, residual_cleaned, 'r-', 'LineWidth', 1, 'DisplayName', ...
    sprintf('After (RMS=%.4f psi)', rms(residual_cleaned, 'omitnan')));
ylabel('Error (psi)');
xlabel('Time');
title('Residuals vs Ideal Data (measure of cleaning effectiveness)');
legend('Location', 'best');
grid on;

%% Quality Metrics
fprintf('\n=== QUALITY METRICS ===\n');
noise_before = rms(residual_noisy, 'omitnan');
noise_after = rms(residual_cleaned, 'omitnan');
noise_reduction = (1 - noise_after/noise_before) * 100;

fprintf('RMS Noise:\n');
fprintf('  Before cleaning: %.4f psi (%.3f ft)\n', noise_before, noise_before * psi_to_ft);
fprintf('  After cleaning:  %.4f psi (%.3f ft)\n', noise_after, noise_after * psi_to_ft);
fprintf('  Noise reduction: %.1f%%\n', noise_reduction);

signal_std = std(pressure_ideal);
snr_before = 20 * log10(signal_std / noise_before);
snr_after = 20 * log10(signal_std / noise_after);

fprintf('\nSignal-to-Noise Ratio:\n');
fprintf('  Before cleaning: %.1f dB\n', snr_before);
fprintf('  After cleaning:  %.1f dB\n', snr_after);
fprintf('  Improvement:     %.1f dB\n', snr_after - snr_before);

fprintf('\nOutlier Detection:\n');
fprintf('  Spikes injected: %d\n', num_spikes);
fprintf('  Outliers detected: %d\n', sum(outliers));
fprintf('  Detection rate: %.1f%%\n', 100 * sum(outliers) / num_spikes);

%% Zoom plots for detailed inspection
figure('Name', 'Detailed Views', 'Position', [200, 200, 1400, 700]);

% Zoom on pump start
subplot(2,2,1);
zoom_start = pump_start_time - minutes(5);
zoom_end = pump_start_time + minutes(15);
zoom_mask = timestamps >= zoom_start & timestamps <= zoom_end;
plot(timestamps(zoom_mask), pressure_ideal(zoom_mask), 'g-', 'LineWidth', 2);
hold on;
plot(timestamps(zoom_mask), pressure_noisy(zoom_mask), 'b-', 'LineWidth', 0.5);
plot(timestamps(zoom_mask), pressure_final(zoom_mask), 'r-', 'LineWidth', 1.5);
xline(pump_start_time, 'k--', 'Pump ON');
ylabel('Pressure (psi)');
title('Detailed View: Pump Start');
legend('Ideal', 'Noisy', 'Cleaned', 'Location', 'best');
grid on;

% Zoom on steady pumping
subplot(2,2,2);
zoom_start = pump_start_time + hours(1);
zoom_end = pump_start_time + hours(1.5);
zoom_mask = timestamps >= zoom_start & timestamps <= zoom_end;
plot(timestamps(zoom_mask), pressure_ideal(zoom_mask), 'g-', 'LineWidth', 2);
hold on;
plot(timestamps(zoom_mask), pressure_noisy(zoom_mask), 'b-', 'LineWidth', 0.5);
plot(timestamps(zoom_mask), pressure_final(zoom_mask), 'r-', 'LineWidth', 1.5);
ylabel('Pressure (psi)');
title('Detailed View: Steady Pumping');
legend('Ideal', 'Noisy', 'Cleaned', 'Location', 'best');
grid on;

% Zoom on pump stop / recovery start
subplot(2,2,3);
zoom_start = pump_end_time - minutes(5);
zoom_end = pump_end_time + minutes(15);
zoom_mask = timestamps >= zoom_start & timestamps <= zoom_end;
plot(timestamps(zoom_mask), pressure_ideal(zoom_mask), 'g-', 'LineWidth', 2);
hold on;
plot(timestamps(zoom_mask), pressure_noisy(zoom_mask), 'b-', 'LineWidth', 0.5);
plot(timestamps(zoom_mask), pressure_final(zoom_mask), 'r-', 'LineWidth', 1.5);
xline(pump_end_time, 'k--', 'Pump OFF');
ylabel('Pressure (psi)');
xlabel('Time');
title('Detailed View: Recovery Start');
legend('Ideal', 'Noisy', 'Cleaned', 'Location', 'best');
grid on;

% Zoom on late recovery
subplot(2,2,4);
zoom_start = pump_end_time + hours(1);
zoom_end = pump_end_time + hours(1.5);
zoom_mask = timestamps >= zoom_start & timestamps <= zoom_end;
plot(timestamps(zoom_mask), pressure_ideal(zoom_mask), 'g-', 'LineWidth', 2);
hold on;
plot(timestamps(zoom_mask), pressure_noisy(zoom_mask), 'b-', 'LineWidth', 0.5);
plot(timestamps(zoom_mask), pressure_final(zoom_mask), 'r-', 'LineWidth', 1.5);
ylabel('Pressure (psi)');
xlabel('Time');
title('Detailed View: Late Recovery');
legend('Ideal', 'Noisy', 'Cleaned', 'Location', 'best');
grid on;

%% Summary
fprintf('\n=== TEST COMPLETE ===\n');
fprintf('✓ Synthetic data with realistic noise generated\n');
fprintf('✓ Cleaning workflow applied successfully\n');
fprintf('✓ %.1f%% noise reduction achieved\n', noise_reduction);
fprintf('✓ Visualizations created\n\n');
fprintf('📋 INTERPRETATION:\n');
fprintf('   - Green lines show "ground truth" (ideal pump test response)\n');
fprintf('   - Blue lines show noisy data (similar to raw Aquatroll data)\n');
fprintf('   - Red lines show cleaned data (after filtering)\n\n');
fprintf('💡 TIP: If this test looks good, you can now apply the same\n');
fprintf('   workflow to your real Aquatroll data using:\n');
fprintf('   >> process_aquatroll_pump_test()\n\n');

end
