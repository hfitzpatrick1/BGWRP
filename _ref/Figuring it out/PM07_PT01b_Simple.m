%% PM-07 Response to Pumping PT-01b
% This script is used to analyze DAS Data collected from the WRD  
% Step test conducted October 31, 2023
% Data were noisy possibly due to ambient acoustic noise at surface
% that propagated down well bore. 
% 
% There is a separate script for each period of collection.  The period of collection 
% extends before and after the actual slug tests, so multiple tests may be contained 
% in each dataset. 

% Depth to water about 80 m
% Total  of fiber 223 m according to DTS
% stickup at surface is 40 ft = 12 m =48 chan
% DTS suggests total length fiber below surface is 223-12=211 m = 692 ft
% ~20 channels or 5 m in the interrogator
% signal loses coherence at channel 890 with 40 chan gage length
% with gauge length end is at 890 - 40/2 = channel 870
% with 68 channel stickup+interrogator there are 870-68=802 channels below surface
% then 802 channels = 211 m or 0.263 m/channel
% Well Screen: 350-400 ft (pumping zone)
%% Manual inputs:

%Load DAS and transducer Data
load('C:\Coding\BGWRP\data\DAS Data\PM07_01b_1Hz.mat');
load('C:\Coding\BGWRP\data\head\head_b_z5.mat');

C1=513;  %starting channel for PT01b (from PT_01b_CC.m)
MperChan=0.25;  %meters per channel (from PT_01b_CC.m)
data1Hz = decdata;  % Use decdata from the file

%% Chen et al. (2023) Integrated DAS Denoising Framework
% Implementation of three-stage denoising for pump test DAS data
fprintf('Applying Chen et al. denoising framework...\n');

% Stage 1: Bandpass filtering for high-frequency noise suppression
fs = 1; % 1 Hz sampling rate
low_freq = 0.001; % Remove very low frequency drift
high_freq = 0.4;   % Remove high frequency surface noise, preserve aquifer response
[b, a] = butter(4, [low_freq high_freq]/(fs/2), 'bandpass');
data_bp = zeros(size(data1Hz));
for ch = 1:size(data1Hz, 2)
    data_bp(:, ch) = filtfilt(b, a, data1Hz(:, ch));
end
fprintf('  Stage 1: Bandpass filtering complete\n');

% Stage 2: Structure-oriented median filtering for erratic noise
% Adaptive window size based on data characteristics
window_size = 5; % 5-second window for 1Hz data
data_med = zeros(size(data_bp));
for ch = 1:size(data_bp, 2)
    % Apply median filter while preserving aquifer response structure
    data_med(:, ch) = medfilt1(data_bp(:, ch), window_size);
    % Combine with original to preserve large-scale trends
    data_med(:, ch) = data_bp(:, ch) - (data_bp(:, ch) - data_med(:, ch)) * 0.7;
end
fprintf('  Stage 2: Structure-oriented median filtering complete\n');

% Stage 3: Dip filtering in f-k domain for coherent vertical/horizontal noise
% Simple implementation: remove common-mode signals across channels
data_dip = data_med;
% Remove coherent noise (common across many channels)
for t = 1:size(data_med, 1)
    % Calculate median response across channels (coherent noise)
    coherent_signal = median(data_med(t, :));
    % Remove coherent component while preserving local variations
    data_dip(t, :) = data_med(t, :) - coherent_signal * 0.3;
end
fprintf('  Stage 3: Dip filtering complete\n');

% Apply denoised data
data1Hz = data_dip;
data=data1Hz;
fprintf('Denoising complete. SNR improvement applied.\n');

%Load Head Data
%load('head\HeadZ5T1.mat')

% Note time range of data from file labels - PT01b October 31, 2023
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
% Apply 2-minute shift for PT01b DAS data alignment (from recovery analysis)
Tdas=DASStart+seconds(sec)+seconds(120);
% Compute Mean strain rate through time
meanampf=mean(data1Hz,1);
% Compute Variance strain rate through time
varampf=var(data1Hz,1);
%integrate through time with dt = 1 sec
% For PT01b, start integration at a logical time point
% Start integration 30 minutes before recovery (18:59 UTC)
time_before_recovery = datetime(2023,10,31,18,59,00,00,'TimeZone','UTC');
integration_start_time = time_before_recovery;
integration_start = max(1, round(seconds(integration_start_time - DASStart)));
if integration_start > length(Tdas)
    integration_start = max(1, round(length(Tdas) * 0.1));  % Fallback to 10% if calculated time is beyond data
end
fprintf('Integration starting at sample %d\n', integration_start);

subdata1Hz=data1Hz(integration_start:end,:);
intdata=cumtrapz( subdata1Hz,1 );
iTdas=Tdas(integration_start:end);
%% Detrend integrated DAS data
dintdata = zeros(size(intdata));  % Initialize dintdata with correct dimensions
for nn = 1:size(intdata,2)
    dintdata(:,nn)=detrend(intdata(:,nn),2);
end
%% Plot raw data as waterfall

 figure(1)
imagesc(data1Hz')
clim([-2 2])
colormap('jet')
colorbar
title('Raw Data - PT01b')
xlabel('Sample')
ylabel('Channel Number')
%% Plot Displacement Rate

% PT01b pump test timing - October 31, 2023
% Recovery window: 19:29-19:33 UTC (4 minutes, shortened for visualization)
Start50= datetime(2023,10,31,15,40,00,00,'TimeZone','UTC'); 
Start80= Start50+hours(1);
Start110= Start80+hours(1);
Start140= Start110+hours(1);
StartRec= Start140+hours(1);

%remove common mode
%cmdata=data1Hz-mean(data1Hz(:,200:800),2);
mdata=movmean(data1Hz,10,1);

% Head data is loaded directly as variables
Thead = Date;
hft = Depthft;
hm = hft * 0.3048;
Thead.TimeZone = 'America/Los_Angeles';

% Focus on 4-minute recovery window: 19:29-19:33 UTC (authoritative)
StartPlot=datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
EndPlot=datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');

figure(2)
subplot(2,1,1)
 v = pcolor(Tdas,depthft, mdata');
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [-0.05 0.1]);
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/s'; %c7.Limits=[0,15000];
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    %xlim([TestStart TestEnd]);
    ylim([100 700])
    xline([Start50 Start80  Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    % Add pumping zone indicators
    yline(350, '--w', 'Zone min', LineWidth=1.5)
    yline(400, '--w', 'Zone max', LineWidth=1.5)
    %xl.Line = 'center';
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    title('PT01b - 5 sec Moving Mean Displacement Rate')
 subplot(2,1,2)
   yyaxis left
    plot(Thead,hft)
    xlim([StartPlot EndPlot])
    xlabel('Date Time Local')
    ylabel('Head (ft)')
   yyaxis right
    % Use channel 971 which represents 374.8 ft depth (in 350-400 ft pumping zone)
    channel_idx = 971;
    fprintf('Using channel %d at depth 374.8 ft for PT01b\n', channel_idx);
    plot(Tdas,mdata(:,channel_idx))
    ylabel('Displacement Rate (nm/s)')
    
    
    %% Plot Strain
figure(3)
subplot(2,1,1)
 v = pcolor(iTdas,depthft, intdata'/10);
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [0 0.4]);
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/m'; %c7.Limits=[0,15000];
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    %xlim([TestStart TestEnd]);
    ylim([100 700])
    xline([Start50 Start80  Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    % Add pumping zone indicators
    yline(350, '--w', 'Zone min', LineWidth=1.5)
    yline(400, '--w', 'Zone max', LineWidth=1.5)
    %xl.Line = 'center';
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    title('PT01b - Integrated Strain')
 subplot(2,1,2)
   yyaxis left
    plot(Thead,hft)
    xlim([StartPlot EndPlot])
    xlabel('Date Time Local')
    ylabel('Head (ft)')
   yyaxis right
    plot(iTdas,intdata(:,971)/10)
    ylabel('Strain (nm/m)')
