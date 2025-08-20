%% PM-07 PT-01b — Zone-averaged strain rate (350–400 ft)
% This stand-alone script plots the average displacement (strain) rate
% across the pumping zone and overlays it with drawdown.

% Locate project directories (works regardless of current folder)
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load DAS and head data
load(fullfile(data_dir, 'DAS Data', 'PM07_01b_1Hz.mat'));  % provides decdata
load(fullfile(data_dir, 'head', 'head_b_z5.mat'));         % provides Date, Depthft, Drawdownft

% DAS geometry (from PT_01b_CC.m)
C1 = 513;          % starting channel index
MperChan = 0.25;   % meters per channel

% Prepare DAS arrays
data1Hz = decdata;                            % [time x channel]
samp = 1:size(data1Hz,1);
chan = 1:size(data1Hz,2);
depthm = (chan - C1 - 1) * MperChan;          % depth relative to fiber zero [m]
depthft = depthm / 0.3048;                    % convert to feet

% Time vector (1 Hz)
DASStart = datetime(2023,10,31,15,29,36,00, 'TimeZone','UTC');
Tdas = DASStart + seconds(samp);              % UTC

% Smooth a bit to reduce noise, consistent with the analysis script
mdata = movmean(data1Hz, 10, 1);              % nm/s (displacement rate)

% Head data in UTC
Thead = Date;                 % from loaded head file
Thead.TimeZone = 'UTC';

% Plot window requested
StartPlot = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
EndPlot   = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');

% Pumping zone
zone_min_ft = 350;
zone_max_ft = 400;
zone_mask = depthft >= zone_min_ft & depthft <= zone_max_ft;

% Average displacement rate across zone (time series)
avg_disp_rate = mean(mdata(:, zone_mask), 2, 'omitnan');

% DAS time remains in UTC

% Figure: Drawdown (left) vs zone-averaged displacement rate (right)
figure('Name','PT-01b Zone-Averaged Displacement Rate');
yyaxis left
plot(Thead, Drawdownft, 'b-', 'LineWidth', 1.5);
xlim([StartPlot EndPlot]);
ylabel('Drawdown (ft)');
xlabel('Date Time UTC');
grid on; hold on;

yyaxis right
plot(Tdas, avg_disp_rate, 'r-', 'LineWidth', 1.5);
ylabel('Displacement Rate (nm/s)');

legend('Drawdown','Avg Displacement Rate (350–400 ft)','Location','northwest');
title('PT-01b: Zone-averaged Displacement Rate (350–400 ft) — Full Test Window');
grid on;


