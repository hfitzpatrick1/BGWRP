% Shift PT01b_Recovery_short_DAS_Mean.las down by 50 feet
clear; clc;

%% Read the original LAS file (CALIBRATED VERSION)
input_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Processed.las';
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_DAS_Profile_Final.las';

fprintf('Reading: %s\n', input_file);

% Read the file line by line
fid_in = fopen(input_file, 'r');
lines = {};
while ~feof(fid_in)
    lines{end+1} = fgetl(fid_in);
end
fclose(fid_in);

%% Parse the data section
data_start_idx = 0;
for i = 1:length(lines)
    if startsWith(strtrim(lines{i}), '~A')
        data_start_idx = i + 1;
        break;
    end
end

% Extract depth and DAS data
depth_data = [];
das_data = [];
for i = data_start_idx:length(lines)
    if isempty(strtrim(lines{i}))
        continue;
    end
    vals = str2num(lines{i});
    if ~isempty(vals) && length(vals) == 2
        depth_data(end+1) = vals(1);
        das_data(end+1) = vals(2);
    end
end

fprintf('Original depth range: %.2f to %.2f ft\n', min(depth_data), max(depth_data));

%% Shift depth down by 120 feet (115 + 5 more)
shift_ft = 120;
depth_shifted = depth_data + shift_ft;

fprintf('Shifted depth range: %.2f to %.2f ft\n', min(depth_shifted), max(depth_shifted));
fprintf('Shift amount: %.1f feet DOWN\n', shift_ft);

%% Write new LAS file
fid = fopen(output_file, 'w');

% Header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', min(depth_shifted));
fprintf(fid, 'STOP.FT %.2f:\n', max(depth_shifted));
fprintf(fid, 'STEP.FT %.3f:\n', abs(depth_shifted(2) - depth_shifted(1)));
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth (shifted down 120 ft to align with screen 350-400 ft)\n');
fprintf(fid, 'DAS_RATE.NM_S : DAS Displacement Rate at 19:30:29 (1s smoothed, shifted)\n');
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_SNAP\n');

% Write data
for i = 1:length(depth_shifted)
    fprintf(fid, '%8.2f %12.5f\n', depth_shifted(i), das_data(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('Output file: %s\n', output_file);

% Check screen interval
screen_min = 350;
screen_max = 400;
screen_mask = (depth_shifted >= screen_min) & (depth_shifted <= screen_max);
fprintf('\n=== SCREEN INTERVAL (350-400 ft) ===\n');
fprintf('Points in screen: %d\n', sum(screen_mask));
if any(screen_mask)
    fprintf('DAS in screen range: %.5f to %.5f\n', min(das_data(screen_mask)), max(das_data(screen_mask)));
end

