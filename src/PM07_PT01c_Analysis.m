%% PM-07 Reponse to Pumping PT-01c
% This script is used to analyze DAS Data collected from the WRD  
% Step test conducted October 24, 2024
% Data were noisy possibily due to ambinent acoustic noise at surface
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
%% Manual inputs:

%Load DAS and transducer Data
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

load(fullfile(data_dir, 'DAS Data', 'PM07_Step1c_1Hz.mat'));
load(fullfile(data_dir, 'head', 'headz1.mat'));
C1=110;  %starting channel (corrected from reference PT_01c_CC.m)
MperChan=0.25;  %meters per channel (corrected from reference PT_01c_CC.m)
data=data1Hz;

%Load Head Data
%load('head\HeadZ5T1.mat')

% Note time range of data from file labels
DASStart= datetime(2023,10,24,15,02,36,00,'TimeZone','UTC'); 
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
subdata1Hz=data1Hz(15085:end,:);
intdata=cumtrapz( subdata1Hz,1 );
iTdas=Tdas(15085:end);
%% Detrend integrated DAS data
for nn = 1:size(intdata,2)
    dintdata(:,nn)=detrend(intdata(:,nn),2);
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

Start50= datetime(2023,10,24,15,10,00,00,'TimeZone','UTC'); 
Start80= Start50+hours(1);
Start110= Start80+hours(1);
Start140= Start110+hours(1);
StartRec= Start140+hours(1);

%remove common mode
%cmdata=data1Hz-mean(data1Hz(:,200:800),2);
mdata=movmean(data1Hz,10,1);
Thead=headz1.Date;
hm=headz1.Depthft*.3048;
hft=headz1.Depthft;
Thead.TimeZone='America/Los_Angeles';

StartPlot=StartRec+minutes(4);
EndPlot=StartRec+minutes(8);

figure(2)
subplot(2,1,1)
 v = pcolor(Tdas,depthft, mdata');
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [-0.25 0.15]);
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/s'; %c7.Limits=[0,15000];
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    %xlim([TestStart TestEnd]);
    ylim([100 700])
    xline([Start50 Start80  Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    %xl.Line = 'center';
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    %title('5 sec Moving Mean Displacement Rate Test 1c')
 subplot(2,1,2)
   yyaxis left
    plot(Thead,hft)
    xlim([StartPlot EndPlot])
    xlabel('Date Time Local')
    ylabel('Head (ft)')
   yyaxis right
    plot(Tdas,mdata(:,492))
    ylabel('Displacement Rate (nm/s)')
    
    
    %% Plot Strain
figure(3)
subplot(2,1,1)
 v = pcolor(iTdas,depthft, intdata'/10);
    set(v, 'EdgeColor', 'none')
    set(gca, 'clim', [-2 0]);
    colormap('jet');
    c7=colorbar; c7.Location="northoutside";
    c7.Ruler.TickLabelFormat='%g nm/m'; %c7.Limits=[0,15000];
    grid on; set(gca,'layer','top');
    ylabel('Depth (ft)')
    axis ij
    %xlim([TestStart TestEnd]);
    ylim([100 700])
    xline([Start50 Start80  Start110 Start140 StartRec],'--w',{'50 gpm','80 gpm','110 gpm','140 gpm','Recovery'},LineWidth=2)
    %xl.Line = 'center';
    xlim([StartPlot EndPlot])
    xlabel('Date Time UTC')
    %title('5 sec Moving Mean Displacement Rate Test 1c')
 subplot(2,1,2)
   yyaxis left
    plot(Thead,hft)
    xlim([StartPlot EndPlot])
    xlabel('Date Time Local')
    ylabel('Head (ft)')
   yyaxis right
    plot(iTdas,intdata(:,492)/10)
    ylabel('Strain (nm/m)')