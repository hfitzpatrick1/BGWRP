%% Check Actual Gauge Length from TDMS Files
%
% This script reads the TDMS metadata to find what gauge length
% the DAS system was actually configured for
%
% Run this from the BGWRP directory

% Find a TDMS file to check
tdms_dir = 'DATA\PT01c_Recovery_short\TDMS_PT01c_Recovery';

% Get first TDMS file
files = dir(fullfile(tdms_dir, '*.tdms'));
if isempty(files)
    error('No TDMS files found in %s', tdms_dir);
end

test_file = fullfile(tdms_dir, files(1).name);
fprintf('Checking TDMS file: %s\n\n', files(1).name);

% Read metadata only
[~, fileinfo] = TDMS_Adv_Read(test_file);

% Display relevant properties
fprintf('=== DAS SYSTEM CONFIGURATION ===\n');

% Gauge Length
try
    idx = strcmp(fileinfo.Properties(:,1), 'GaugeLength');
    if any(idx)
        gauge_length = fileinfo.Properties{idx,2};
        fprintf('Gauge Length: %.2f m\n', gauge_length);
    else
        fprintf('GaugeLength property not found!\n');
    end
catch
    fprintf('Error reading GaugeLength\n');
end

% Spatial Resolution
try
    idx = strcmp(fileinfo.Properties(:,1), 'SpatialResolution[m]');
    if any(idx)
        spatial_res = fileinfo.Properties{idx,2};
        fprintf('Spatial Resolution: %.4f m (%.2f cm)\n', spatial_res, spatial_res*100);
    end
catch
    fprintf('Error reading SpatialResolution\n');
end

% Sampling Frequency
try
    idx = strcmp(fileinfo.Properties(:,1), 'SamplingFrequency[Hz]');
    if any(idx)
        fs = fileinfo.Properties{idx,2};
        fprintf('Sampling Frequency: %.2f Hz\n', fs);
    end
catch
    fprintf('Error reading SamplingFrequency\n');
end

% Display ALL properties to see what's available
fprintf('\n=== ALL TDMS PROPERTIES ===\n');
for i = 1:size(fileinfo.Properties, 1)
    fprintf('%-40s: ', fileinfo.Properties{i,1});
    val = fileinfo.Properties{i,2};
    if isnumeric(val)
        fprintf('%.6g\n', val);
    else
        fprintf('%s\n', val);
    end
end

fprintf('\n=== ACTION REQUIRED ===\n');
fprintf('Check the Gauge Length value above.\n');
fprintf('If it is NOT 10 m, this explains your order of magnitude problem!\n');

