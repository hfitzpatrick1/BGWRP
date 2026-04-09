% GEOTHERMAL GRADIENT PROFILE FOR PM-07 (BGWRP)
% Averages all 111 DTS temperature profiles from Channel1_alldataupto070224.mat
% and computes the thermal gradient vs depth below casing using the Bourdet
% derivative method (Bourdet et al., 1989).
%
% Outputs:
%   - 3-panel figure: (a) all profiles + mean, (b) mean + linear fit,
%     (c) Bourdet derivative gradient
%   - LAS file: PM07_AvgGeothermalGradient.las (depth in metres)

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));

%% 1. LOAD DATA -----------------------------------------------------------
fprintf('--- Loading DTS Dataset ---\n');
load(fullfile(script_dir, 'Channel1_alldataupto070224.mat'));

[n_channels, n_profiles] = size(tempC);
fprintf('Loaded %d temperature profiles, %d depth channels\n', n_profiles, n_channels);

%% 2. DEPTH CALIBRATION (mirrors DTS_W_LAS.m) ----------------------------
M_TO_FT = 3.28084;
distance_ft = distance(:) * M_TO_FT;

TOP_CASING_CH   = 80;
WELL_DEPTH_FT   = 665.0;
EXCESS_CABLE_FT = 54.46;

top_casing_ft    = distance_ft(TOP_CASING_CH);
depth_bc_raw     = distance_ft - top_casing_ft;
measured_well_ft = depth_bc_raw(end);
scale_factor     = WELL_DEPTH_FT / measured_well_ft;
depth_bc         = depth_bc_raw * scale_factor;

fprintf('Top of casing   : CH-%d  (%.2f ft from start)\n', TOP_CASING_CH, top_casing_ft);
fprintf('Scale factor    : %.4f\n', scale_factor);
fprintf('Depth at CH-%d : %.2f ft (target %.0f)\n', n_channels, depth_bc(end), WELL_DEPTH_FT);

%% 3. SUBSURFACE MASK (casing to bottom) ----------------------------------
subsurface = (depth_bc >= 0) & (depth_bc <= WELL_DEPTH_FT);
depth_sub  = depth_bc(subsurface);
tempC_sub  = tempC(subsurface, :);

%% 4. MEAN TEMPERATURE PROFILE -------------------------------------------
mean_temp   = nanmean(tempC_sub, 2);
std_temp    = nanstd(tempC_sub, 0, 2);
median_temp = nanmedian(tempC_sub, 2);

%% 5. GEOTHERMAL GRADIENT VIA BOURDET DERIVATIVE -------------------------
%  Bourdet et al. (1989) weighted central-difference derivative.
%  For each point i, find the nearest points j (above) and k (below)
%  whose depth separation from i is >= L.
%
%  L controls smoothing: larger L = smoother curve.

BOURDET_L_FT = 20.0;

n_sub = length(depth_sub);
gradient_per_ft = nan(n_sub, 1);

for i = 1:n_sub
    j = [];
    for jj = i-1:-1:1
        if depth_sub(i) - depth_sub(jj) >= BOURDET_L_FT
            j = jj;
            break;
        end
    end
    
    k = [];
    for kk = i+1:n_sub
        if depth_sub(kk) - depth_sub(i) >= BOURDET_L_FT
            k = kk;
            break;
        end
    end
    
    if isempty(j) || isempty(k)
        continue;
    end
    
    dz_L = depth_sub(i) - depth_sub(j);
    dz_R = depth_sub(k) - depth_sub(i);
    gradient_per_ft(i) = ((mean_temp(i) - mean_temp(j)) / dz_L * dz_R + ...
                          (mean_temp(k) - mean_temp(i)) / dz_R * dz_L) / (dz_L + dz_R);
end

gradient_per_100ft = gradient_per_ft * 100;
gradient_per_100m  = gradient_per_ft * M_TO_FT * 100;

valid = ~isnan(gradient_per_100ft);
depth_gradient      = depth_sub(valid);
gradient_per_100ft  = gradient_per_100ft(valid);
gradient_per_100m_v = gradient_per_100m(valid);

%% 6. LINEAR FIT (bulk gradient, excluding shallow zone) ------------------
fit_mask = depth_sub >= 100;
coeffs   = polyfit(depth_sub(fit_mask), mean_temp(fit_mask), 1);
bulk_gradient_per_100ft = coeffs(1) * 100;

fprintf('\nBulk geothermal gradient (100-665 ft): %.3f deg C/100 ft\n', bulk_gradient_per_100ft);
fprintf('                                     = %.3f deg C/km\n', coeffs(1) * 1000 / M_TO_FT);

%% 7. DATE RANGE ----------------------------------------------------------
date_first = datestr(datetime(1), 'mmm yyyy');
date_last  = datestr(datetime(end), 'mmm yyyy');
fprintf('Profile date range: %s to %s\n', date_first, date_last);

%% 8. LAS EXPORT (depth in metres, gradient in deg C/100 m) ---------------
depth_sub_m      = depth_sub / M_TO_FT;
depth_gradient_m = depth_gradient / M_TO_FT;

STEP_M    = 0.1;
z_uniform = (ceil(depth_sub_m(1) / STEP_M) * STEP_M : STEP_M : ...
             floor(depth_sub_m(end) / STEP_M) * STEP_M)';

avg_temp_u = interp1(depth_sub_m, mean_temp, z_uniform, 'linear');
grad_u     = interp1(depth_gradient_m, gradient_per_100m_v, z_uniform, 'linear');

las_path = fullfile(script_dir, 'PM07_AvgGeothermalGradient.las');
fid = fopen(las_path, 'w');
if fid == -1, error('Cannot create %s', las_path); end

fprintf(fid, '~Version Information\nVERS. 2.0:\nWRAP. NO:\n\n');
fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.M %.2f:\nSTOP.M %.2f:\nSTEP.M %.2f:\nNULL. -999.25:\n\n', ...
        z_uniform(1), z_uniform(end), STEP_M);
fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.M          : Depth below casing\n');
fprintf(fid, 'AVGTEMP.DEGC    : Mean temperature (avg of %d DTS profiles)\n', n_profiles);
fprintf(fid, 'GRADIENT.DEGC   : Geothermal gradient (deg C / 100 m)\n\n');
fprintf(fid, '~A  DEPT  AVGTEMP  GRADIENT\n');
for j = 1:length(z_uniform)
    fprintf(fid, '%8.2f %12.5f %12.5f\n', z_uniform(j), avg_temp_u(j), grad_u(j));
end
fclose(fid);
fprintf('LAS written -> %s\n', las_path);

%% 9. PLOT ----------------------------------------------------------------
fig = figure('Position', [50 50 1600 900]);

% Panel A: all individual profiles + mean
ax1 = subplot(1, 3, 1);
hold on;
for i = 1:n_profiles
    plot(tempC_sub(:, i), depth_sub, 'Color', [0.8 0.8 0.8 0.5], 'LineWidth', 0.3);
end
fill([mean_temp - std_temp; flipud(mean_temp + std_temp)], ...
     [depth_sub; flipud(depth_sub)], ...
     [0.27 0.51 0.71], 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'DisplayName', '\pm1 \sigma');
plot(mean_temp, depth_sub, 'Color', [0.27 0.51 0.71], 'LineWidth', 1.8, 'DisplayName', 'Mean');
plot(median_temp, depth_sub, '--', 'Color', [1.0 0.55 0.0], 'LineWidth', 1.2, 'DisplayName', 'Median');
set(gca, 'YDir', 'reverse');
xlabel('Temperature (\circC)', 'FontSize', 12);
ylabel('Depth below casing (ft)', 'FontSize', 12);
title('(a) Temperature profiles', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 9);
grid on; set(gca, 'GridAlpha', 0.3);

% Panel B: mean profile + linear fit
ax2 = subplot(1, 3, 2);
hold on;
plot(mean_temp, depth_sub, 'Color', [0.27 0.51 0.71], 'LineWidth', 1.8, 'DisplayName', 'Mean profile');
fit_line = polyval(coeffs, depth_sub);
plot(fit_line, depth_sub, 'r--', 'LineWidth', 1.2, ...
    'DisplayName', sprintf('Linear fit (%.2f \\circC/100 ft)', bulk_gradient_per_100ft));
set(gca, 'YDir', 'reverse');
xlabel('Temperature (\circC)', 'FontSize', 12);
title('(b) Mean profile + gradient fit', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 9);
grid on; set(gca, 'GridAlpha', 0.3);

% Panel C: Bourdet derivative gradient
ax3 = subplot(1, 3, 3);
hold on;
plot(gradient_per_100ft, depth_gradient, 'Color', [0.0 0.39 0.0], 'LineWidth', 1.2);
xline(bulk_gradient_per_100ft, 'r--', 'LineWidth', 1, ...
    'DisplayName', sprintf('Bulk: %.2f \\circC/100 ft', bulk_gradient_per_100ft));
set(gca, 'YDir', 'reverse');
xlabel('Gradient (\circC / 100 ft)', 'FontSize', 12);
title(sprintf('(c) Bourdet derivative (L=%.0f ft)', BOURDET_L_FT), 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 9);
grid on; set(gca, 'GridAlpha', 0.3);

linkaxes([ax1 ax2 ax3], 'y');

sgtitle(sprintf('PM-07 Geothermal Gradient Profile — DTS Mean of %d profiles\n(%s – %s)', ...
    n_profiles, date_first, date_last), 'FontSize', 14, 'FontWeight', 'bold');

out_path = fullfile(script_dir, 'PM07_geothermal_gradient.png');
exportgraphics(fig, out_path, 'Resolution', 200);
fprintf('\nFigure saved -> %s\n', out_path);
