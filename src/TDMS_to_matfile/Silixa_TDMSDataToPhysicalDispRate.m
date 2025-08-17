%%%%%%%%%% Confidential - Internal Silixa Code Only %%%%%%%%%%

%%% Load and scale data, convert from radians/sample to nm/sample displacement rate, and save data as mat file %%%

%% Input Variables
clear
% File location, directory and filename
directory       =   'D:\PM_07 Step Test\MATLAB\PT01c_Recovery\';
filesearch      =   '*.tdms'; % String to search for files, can be filename or *.tdms to find all tdms in a folder
fileindex       =   []; % index of file within the list returned by the search string, if blank, [], load all files in a loop

% save data, toggle (1 = Yes, 0 = No), directory to save data
save_data       =   1;
save_directory  =  'D:\PM_07 Step Test\MATLAB\mat\';

%% Run Script
% Find files
files           =   dir([directory filesearch]);
lf              =   length(files);
if isempty(fileindex)
    f_ind           =   1:lf;
else
    f_ind           =   fileindex;
end

cnt             =   0;
for nn = f_ind
    clc
    cnt             =   cnt + 1;
    fprintf('Processing File %i of %i\n',cnt,length(f_ind));
    
    %% Read file header
    fprintf('Loading Header...')
    filename        =   files(nn).name;
    [~,fileinfo]    =   TDMS_Adv_Read([directory filename]);
    n_ch            =   fileinfo.n_ch; % number of channels in the file
    n_samp          =   fileinfo.ChannelLength; % number of sampels in the file
    fsind           =   strcmp(fileinfo.Properties(:,1),'SamplingFrequency[Hz]');
    fs_f            =   fileinfo.Properties{fsind,2}; % sampling frequency
    ssind           =   strcmp(fileinfo.Properties(:,1),'SpatialResolution[m]');
    spatial_samp    =   fileinfo.Properties{ssind,2}; % spatial sampling distance
    srind           =   strcmp(fileinfo.Properties(:,1),'GaugeLength');
    spatial_res     =   fileinfo.Properties{srind,2}; % Spatial resolution
    fprintf('Done\n')
    
    %% Entire file selected
    ch_ind2         =   1:n_ch;
    arg.ch_start    =   ch_ind2(1);
    arg.ch_stop     =   ch_ind2(end);
    samp_ind2       =   1:n_samp;
    arg.t_start     =   samp_ind2(1);
    arg.t_stop      =   samp_ind2(end);
    
    %% Load Data
    fprintf('Loading Data...')
    arg.loading     =   'data';
    data            =   TDMS_Adv_Read([directory filename],arg);
    adc_scalar      =   1/8192;
    data            =   data*adc_scalar;
    fprintf('Done\n')
    
    %% Convert to displacement rate in (nanometers/sample)
    fprintf('Converting to Physical Displacement Rate...')
    data                  =   116*data;
    data_units            =   'nm/sample';
    fprintf('Done\n')
    
    %% Save data if required
    if save_data
        fprintf('Saving MAT File...')
        save([save_directory filename(1:end-4) 'mat'],'data',...
           'fs_f','spatial_samp','spatial_res',...
            'data_units','-v7.3')
        fprintf('Done\n')
    end
end