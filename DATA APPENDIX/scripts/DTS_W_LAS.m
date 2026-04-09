% DTS DATA ANALYSIS – full script with detailed console logging
% (calibrates depth so CH-815 = 665 ft below casing)

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(script_dir);

%% 1. LOAD DATA -----------------------------------------------------------
fprintf('--- Loading DTS Dataset ---\n');
load(fullfile(parent_dir, '_processed_DTS', 'Channel1_alldataupto070224.mat'));
fprintf('DTS Data Loaded: [%d depths  x  %d timestamps]\n',length(distance),length(datetime));

%% 2. DEPTH CALIBRATION ---------------------------------------------------
distance_ft         = distance * 3.28084;            % metres → feet

top_casing_channel  = 80;                            % from cold-test
top_casing_distance = distance_ft(top_casing_channel);
actual_well_depth   = 665;                           % ft below casing
excess_cable        = 54.46;                         % ft
cable_in_instrument = top_casing_distance - excess_cable;

depth_bc_raw   = distance_ft - top_casing_distance;          % raw ft-bc
measured_well_depth = depth_bc_raw(815);                     % ≈613 ft
scale_factor   = actual_well_depth / measured_well_depth;    % ≈1.085
depth_bc_corr  = depth_bc_raw * scale_factor;                % CH-815 → 665

fprintf('\nDTS SYSTEM CALIBRATION (updated)\n');
fprintf('Top of casing  : CH-%d  (%.2f ft from start)\n',top_casing_channel,top_casing_distance);
fprintf('Cable in inst  : %.2f ft\n',cable_in_instrument);
fprintf('Excess cable   : %.2f ft\n',excess_cable);
fprintf('Measured well depth (raw) : %.2f ft\n',measured_well_depth);
fprintf('Target well depth        : %.2f ft\n',actual_well_depth);
fprintf('Scale factor applied     : %.4f\n',scale_factor);
fprintf('Depth-bc at CH-815 (after) : %.2f ft\n\n',depth_bc_corr(815));

% pick last 25 channels (≈ 3 m fibre) after calibration
deep_idx        = 815-24:815;
deep_temp       = mean(tempC(deep_idx,:),1);     % raw °C series
deep_stdev_raw  = std(deep_temp);                % before alignment

deep_temp_corr  = mean(tempC(deep_idx,:) ,1);    % same values; alignment didn’t move temps
fprintf('Std-dev of bottom 25 channels across all times = %.3f °C\n',deep_stdev_raw);

%% 3. QUICK DEPTH-SHIFT PLOT ---------------------------------------------
figure; hold on
plot(distance_ft,'b','DisplayName','Original abs-ft');
plot(depth_bc_corr+top_casing_distance,'r','DisplayName','Corrected abs-ft');
plot(top_casing_channel,top_casing_distance,'ko','MarkerFaceColor','k')
xlabel('Channel'); ylabel('Absolute Depth (ft)'); legend; grid on
title('Depth Correction')

%% 4. PRE- vs POST-PUMP PROFILES (depth below casing everywhere) ----------
test_dates = {'24-Oct-2023','31-Oct-2023','07-Nov-2023'};
test_names = {'PT-01c','PT-01a','PT-01b'};
cols       = {'m','r','b'};
xlims      = {[21.3 24.5],[21.2 24.5],[21.4 24.5]};

for n = 1:numel(test_dates)
    day_idx = datetime >= datenum(test_dates{n}) & datetime < datenum(test_dates{n})+1;
    if ~any(day_idx), continue, end
    
    pre_idx  = find(day_idx,3,'first');
    post_idx = find(day_idx,3,'last');
    
    pre_temp  = mean(tempC(:,pre_idx),2);
    post_temp = mean(tempC(:,post_idx),2);
    
    align_idx = depth_bc_corr>=600 & depth_bc_corr<=650;
    offset    = mean(pre_temp(align_idx)) - mean(post_temp(align_idx));
    post_aln  = post_temp + offset;
    
    figure;
    plot(pre_temp ,depth_bc_corr,'k','LineWidth',0.8,'DisplayName','Pre');
    hold on
    h=plot(post_aln,depth_bc_corr,cols{n},'LineWidth',0.8,'DisplayName','Post (aligned)');
    h.Color(4)=0.8;
    set(gca,'YDir','reverse'); ylim([0 700]); xlim(xlims{n});
    xlabel('Temperature (°C)'); ylabel('Depth below casing (ft)');
    title([test_names{n} ' – aligned profiles']);
    legend location best; grid on
end

%% --- START  LAS EXPORT (Pre, Post, Diff)  -------------------------------
%
%  • Uses depth_bc_corr   (depth below casing, calibrated to 665 ft)
%  • Resamples to 0.25 ft   so WellCAD never re-bins the data
%  • Outputs:  PRETEMP   POSTTEMP   DIFFTEMP  (post – pre)
%  • One LAS per event:   PT-01a_Temps.las,  etc.
%
% ========================================================================

output_dir = [parent_dir filesep];
step_ft    = 0.25;                      % uniform vertical resolution

for i = 1:numel(test_dates)
    %% --- select columns for this day -----------------------------------
    day0      = datenum(test_dates{i});
    day_idx   = find(datetime >= day0 & datetime < day0+1);
    pre_idx   = day_idx(1:3);                 % first 3
    post_idx  = day_idx(end-2:end);           % last 3

    pre_temp  = mean(tempC(:,pre_idx), 2);
    post_temp = mean(tempC(:,post_idx),2);

    %% --- align on 600–650 ft-bc ----------------------------------------
    align     = depth_bc_corr>=600 & depth_bc_corr<=650;
    offset    = mean(pre_temp(align)) - mean(post_temp(align));
    post_aln  = post_temp + offset;

    %% --- clip to fibre (≤665 ft) ---------------------------------------
    good      = depth_bc_corr <= 665;
    d_bc      = depth_bc_corr(good);
    pre_temp  = pre_temp(good);
    post_aln  = post_aln(good);

    %% --- resample to constant 0.25 ft step -----------------------------
    z_uniform = (ceil(min(d_bc)/step_ft)*step_ft : step_ft : ...
                 floor(max(d_bc)/step_ft)*step_ft)';

    pre_u  = interp1(d_bc, pre_temp , z_uniform,'linear');
    post_u = interp1(d_bc, post_aln , z_uniform,'linear');
    diff_u = post_u - pre_u;                            % ΔT curve

    %% --- write LAS -----------------------------------------------------
    fname = sprintf('%s%s_Temps.las',output_dir,test_names{i});
    fid   = fopen(fname,'w');  if fid==-1, error('Cannot create %s',fname); end

    fprintf(fid,'~Version Information\nVERS. 2.0:\nWRAP. NO:\n\n');
    fprintf(fid,'~Well Information\n');
    fprintf(fid,'STRT.FT %.2f:\nSTOP.FT %.2f:\nSTEP.FT %.2f:\nNULL. -999.25:\n\n',...
            min(z_uniform), max(z_uniform), step_ft);

    fprintf(fid,'~Curve Information\n');
    fprintf(fid,'DEPT.FT     : Depth below casing\n');
    fprintf(fid,'PRETEMP.C   : Pre-pump Temperature\n');
    fprintf(fid,'POSTTEMP.C  : Post-pump Temperature (aligned)\n');
    fprintf(fid,'DIFFTEMP.C  : Post minus Pre Temperature\n\n');

    fprintf(fid,'~A  DEPT  PRETEMP  POSTTEMP  DIFFTEMP\n');
    for j = 1:numel(z_uniform)
        fprintf(fid,'%8.2f %12.5f %12.5f %12.5f\n',...
                z_uniform(j), pre_u(j), post_u(j), diff_u(j));
    end
    fclose(fid);
    fprintf('✅  LAS written →  %s\n',fname);
end

