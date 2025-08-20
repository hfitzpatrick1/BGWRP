%% PM-07 Response to Pumping PT-01a
% This script is used to analyze DAS Data collected from the WRD  
% Step test conducted November 7, 2023
% 
% There is a separate script for each period of collection. The period of collection 
% extends before and after the actual slug tests, so multiple tests may be contained 
% in each dataset. 

% Well Screen: 450-510 ft (pumping zone)

%% Manual inputs:

%Load DAS and transducer Data
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

load(fullfile(data_dir, 'DAS Data', 'PM07_01a_1Hz.mat'));
load(fullfile(data_dir, 'head', 'head_a_z5.mat'));
C1=513;  %starting channel (from PT_01a_CC.m)
MperChan=0.25;  %meters per channel (from PT_01a_CC.m)
data1Hz=decdata;  % Rename to match our script's variable naming
data=data1Hz;

% Note time range of data from file labels
DASStart= datetime(2023,11,7,16,45,36,00,'TimeZone','UTC'); 
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
StartPlot = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');  % Requested start
EndPlot = datetime(2023,11,7,20,49,00,00,'TimeZone','UTC');    % Requested end

% For reference points on plot (based on PT-01a timing)
Start50 = datetime(2023,11,7,17,0,00,00,'TimeZone','UTC');   % Estimated pump start
Start80 = Start50+hours(1);
Start110 = Start80+hours(1);
Start140 = Start110+hours(1);
StartRec = Start140+hours(1);

% Simple approach - just basic moving average on raw data
mdata = movmean(data1Hz, 10, 1);

fprintf('Applied simple moving average filter (window = 10)\n');

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

% Check if we have drawdown data in the window
if isempty(window_drawdown)
    fprintf('Warning: No drawdown data found in plot window. Checking full range...\n');
    fprintf('Full drawdown range: [%.3f, %.3f] ft\n', min(Drawdownft), max(Drawdownft));
    fprintf('Full head time range: %s to %s\n', min(Thead), max(Thead));
    % Use full range for ylim if no data in window
    drawdown_ylim = [min(Drawdownft) max(Drawdownft)];
else
    drawdown_ylim = [min(window_drawdown) max(window_drawdown)];
end

% Choose a representative channel in the pumping zone (450-510 ft)
zone_min_ft = 450;  % lower bound of zone of interest
zone_max_ft = 510;  % upper bound of zone of interest
target_depth_ft = (zone_min_ft + zone_max_ft)/2;  % center of zone of interest
[~, channel_idx] = min(abs(depthft - target_depth_ft));
depth_at_channel = depthft(channel_idx);
fprintf('Selected channel %d at depth %.1f ft (target %.1f ft, zone %.1f-%.1f ft)\n', channel_idx, depth_at_channel, target_depth_ft, zone_min_ft, zone_max_ft);
fprintf('mdata range: [%.3f, %.3f] nm/s\n', min(mdata(:)), max(mdata(:)));
fprintf('mdata(:,%d) range: [%.3f, %.3f] nm/s\n', channel_idx, min(mdata(:,channel_idx)), max(mdata(:,channel_idx)));

% Use single representative channel instead of zone average
% Get displacement rate and strain for the selected channel
single_disp_rate = mdata(:, channel_idx);
single_strain = intdata(:, channel_idx)/10;  % nm/m

% Set fixed color bar ranges as originally requested
disp_rate_range = [0.25 0.55];  % Fixed range for Figure 2
strain_range = [-295 -275];   % Fixed range for Figure 3

fprintf('Single channel displacement rate range: [%.3f, %.3f] nm/s\n', min(single_disp_rate), max(single_disp_rate));
fprintf('Single channel strain range: [%.3f, %.3f] nm/m\n', min(single_strain), max(single_strain));
fprintf('Using fixed color range for displacement rate: [%.1f, %.1f] nm/s\n', disp_rate_range(1), disp_rate_range(2));
fprintf('Using fixed color range for strain: [%.0f, %.0f] nm/m\n', strain_range(1), strain_range(2));

figure(2)
subplot(2,1,1)
v = pcolor(Tdas,depthft, mdata');
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', disp_rate_range);  % Use actual data range
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
         title(sprintf('Displacement Rate (Channel %d at %.1f ft)', channel_idx, depth_at_channel))
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
    ylim(drawdown_ylim)  % Use calculated drawdown range
   yyaxis right
    TdasLocal = Tdas;
    TdasLocal.TimeZone = 'America/Los_Angeles';
         plot(TdasLocal, single_disp_rate, 'r-', 'LineWidth', 1.5)
    ylabel('Displacement Rate (nm/s)')
    grid on
    legend('Drawdown', 'Displacement Rate', 'Location', 'northwest')
    
%% Plot Strain
figure(3)
subplot(2,1,1)
v = pcolor(iTdas,depthft, intdata'/10);
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', strain_range);  % Use fixed strain range
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
         title(sprintf('Strain (Channel %d at %.1f ft)', channel_idx, depth_at_channel))
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
    ylim(drawdown_ylim)  % Use calculated drawdown range
   yyaxis right
    iTdasLocal = iTdas;
    iTdasLocal.TimeZone = 'America/Los_Angeles';
         plot(iTdasLocal, single_strain, 'r-', 'LineWidth', 1.5)
    ylabel('Strain (nm/m)')
    grid on
    legend('Drawdown', 'Strain', 'Location', 'northwest')
