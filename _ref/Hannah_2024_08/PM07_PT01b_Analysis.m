%% PM-07 Response to Pumping PT-01b
% This script is used to analyze DAS Data collected from the WRD  
% Step test conducted October 31, 2023
% 
% There is a separate script for each period of collection. The period of collection 
% extends before and after the actual slug tests, so multiple tests may be contained 
% in each dataset. 

% Well Screen: 350-400 ft

%% Manual inputs:

%Load DAS and transducer Data
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(fileparts(script_dir));  % Go up two levels from _ref/Hannah_2024_08/ to BGWRP/
data_dir = fullfile(project_dir, 'data');

load(fullfile(data_dir, 'DAS Data', 'PM07_01b_1Hz.mat'));
load(fullfile(data_dir, 'head', 'head_b_z5.mat'));
C1=513;  %starting channel (from PT_01b_CC.m)
MperChan=0.25;  %meters per channel (from PT_01b_CC.m)
data1Hz=decdata;  % Rename to match our script's variable naming
data=data1Hz;

% Note time range of data from file labels
DASStart= datetime(2023,10,31,15,29,36,00,'TimeZone','UTC'); 
DASEnd=DASStart+seconds(size(data1Hz,1));
%%
NC=size(data1Hz,2);
samp=1:size(data1Hz,1);
chan=1:size(data1Hz,2);
depthm=(chan-C1-1)*MperChan;  % compute depth in meters
depthft=depthm/.3048; % compute depth in ft
sec=samp/1;  %for 1 Hz

%time of DAS files 
Tdas=DASStart+seconds(sec);
% Compute Mean strain rate through time
meanampf=mean(data1Hz,1);
% Compute Variance strain rate through time
varampf=var(data1Hz,1);
%integrate through time with dt = 1 sec
% Start integration from 15 minutes after start (to skip initial noise)
start_offset_min = 15;
integration_start = DASStart + minutes(start_offset_min);
start_idx = find(Tdas >= integration_start, 1);

% Debug print
fprintf('Integration start time: %s (index: %d)\n', Tdas(start_idx), start_idx);
fprintf('Data dimensions: [%d x %d]\n', size(data1Hz));

% Perform integration
subdata1Hz = data1Hz(start_idx:end,:);
intdata = cumtrapz(subdata1Hz,1);
iTdas = Tdas(start_idx:end);

%% Detrend integrated DAS data
dintdata = zeros(size(intdata));  % Pre-allocate
for nn = 1:size(intdata,2)
    dintdata(:,nn) = detrend(intdata(:,nn),2);
end
% Plot raw data as waterfall

figure(1)
imagesc(data1Hz')
clim([-2 2])
colormap('jet')
colorbar
title('Raw Data')
xlabel('Sample')
ylabel('Channel Number')
% Plot Displacement Rate

% Load head data and handle time zones
Thead = Date;
Thead.TimeZone = 'UTC';  % Start in UTC
TheadLocal = Thead;
TheadLocal.TimeZone = 'America/Los_Angeles';  % Convert to local time for bottom plot
hm = Depthft*.3048;
hft = Depthft;

% Set time window for plotting (requested window)
StartPlot = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
EndPlot   = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');

% For reference points on plot
Start50 = datetime(2023,10,31,15,30,00,00,'TimeZone','UTC');
Start80 = Start50+hours(1);
Start110 = Start80+hours(1);
Start140 = Start110+hours(1);
StartRec = Start140+hours(1);

%remove common mode
%cmdata=data1Hz-mean(data1Hz(:,200:800),2);
mdata=movmean(data1Hz,10,1);

% Debug prints
fprintf('Head data time range: %s to %s\n', min(Thead), max(Thead));
fprintf('DAS data time range: %s to %s\n', min(Tdas), max(Tdas));
fprintf('StartPlot: %s\n', StartPlot);
fprintf('EndPlot: %s\n', EndPlot);
fprintf('Max drawdown: %.3f ft\n', max(Drawdownft));

% Find drawdown values in our plot window
window_mask = Thead >= StartPlot & Thead <= EndPlot;
window_drawdown = Drawdownft(window_mask);
fprintf('Drawdown in plot window: min=%.3f ft, max=%.3f ft\n', min(window_drawdown), max(window_drawdown));

% Choose a representative channel in the pumping zone (350-400 ft)
zone_min_ft = 350;  % lower bound of zone of interest
zone_max_ft = 400;  % upper bound of zone of interest
target_depth_ft = (zone_min_ft + zone_max_ft)/2;  % center of zone of interest
[~, channel_idx] = min(abs(depthft - target_depth_ft));
depth_at_channel = depthft(channel_idx);
fprintf('Selected channel %d at depth %.1f ft (target %.1f ft, zone %.1f-%.1f ft)\n', channel_idx, depth_at_channel, target_depth_ft, zone_min_ft, zone_max_ft);
fprintf('mdata range: [%.3f, %.3f] nm/s\n', min(mdata(:)), max(mdata(:)));
fprintf('mdata(:,%d) range: [%.3f, %.3f] nm/s\n', channel_idx, min(mdata(:,channel_idx)), max(mdata(:,channel_idx)));

% Zone masks and averages for plotting
idxZone = depthft >= zone_min_ft & depthft <= zone_max_ft;
avg_disp_rate = mean(mdata(:, idxZone), 2, 'omitnan');
avg_strain = mean(intdata(:, idxZone), 2, 'omitnan')/10;  % nm/m

figure(2)
subplot(2,1,1)
v = pcolor(Tdas,depthft, mdata');
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [-1.0 0]);
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/s';
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    ylim([100 665])
    xline([Start50 Start80 Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    yline(zone_min_ft, '--w', 'Zone min', LineWidth=1.5)
    yline(zone_max_ft, '--w', 'Zone max', LineWidth=1.5)
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    title('Displacement Rate (350-400 ft zone)')
subplot(2,1,2)
   yyaxis left
    plot(TheadLocal, Drawdownft, 'b-', 'LineWidth', 1.5)
    StartPlotLocal = StartPlot;
    StartPlotLocal.TimeZone = 'America/Los_Angeles';
    EndPlotLocal = EndPlot;
    EndPlotLocal.TimeZone = 'America/Los_Angeles';
    xlim([StartPlotLocal EndPlotLocal])
    xlabel('Date Time Local')
    ylabel('Drawdown (ft)')
    ylim([-0.07 0.05])  % Adjusted for actual drawdown range (-0.068 to -0.024 ft)
   yyaxis right
    TdasLocal = Tdas;
    TdasLocal.TimeZone = 'America/Los_Angeles';
    plot(TdasLocal, avg_disp_rate, 'r-', 'LineWidth', 1.5)
    ylabel('Displacement Rate (nm/s)')
    grid on
    legend('Drawdown', 'Displacement Rate', 'Location', 'northwest')
    
%% Plot Strain
figure(3)
subplot(2,1,1)
v = pcolor(iTdas,depthft, intdata'/10);
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [-2200 -1880]);  % Adjusted to match strain data range
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/m';
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    ylim([100 665])
    xline([Start50 Start80 Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    yline(zone_min_ft, '--w', 'Zone min', LineWidth=1.5)
    yline(zone_max_ft, '--w', 'Zone max', LineWidth=1.5)
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    title('Strain (350-400 ft zone)')
subplot(2,1,2)
   yyaxis left
    plot(TheadLocal, Drawdownft, 'b-', 'LineWidth', 1.5)
    StartPlotLocal = StartPlot;
    StartPlotLocal.TimeZone = 'America/Los_Angeles';
    EndPlotLocal = EndPlot;
    EndPlotLocal.TimeZone = 'America/Los_Angeles';
    xlim([StartPlotLocal EndPlotLocal])
    xlabel('Date Time Local')
    ylabel('Drawdown (ft)')
    ylim([-0.07 0.05])  % Adjusted for actual drawdown range (-0.068 to -0.024 ft)
   yyaxis right
    iTdasLocal = iTdas;
    iTdasLocal.TimeZone = 'America/Los_Angeles';
    plot(iTdasLocal, avg_strain, 'r-', 'LineWidth', 1.5)
    ylabel('Strain (nm/m)')
    grid on
    legend('Drawdown', 'Strain', 'Location', 'northwest')