%%%%%%%%%% Confidential - Internal Silixa Code Only %%%%%%%%%%

%%% Load and scale data, convert from radians/sample to nm/sample displacement rate, and save data as mat file %%%
%%% Enhanced version with detailed error reporting

%% Input Variables
% NOTE: Variables should be set by calling script before running this
% Default values provided for standalone operation

if ~exist('directory', 'var')
    directory       =   'D:\PM_07 Step Test\MATLAB\PT01c_Recovery\';
end
if ~exist('filesearch', 'var')
    filesearch      =   '*.tdms'; % String to search for files, can be filename or *.tdms to find all tdms in a folder
end
if ~exist('fileindex', 'var')
    fileindex       =   []; % index of file within the list returned by the search string, if blank, [], load all files in a loop
end
if ~exist('save_data', 'var')
    save_data       =   1; % save data, toggle (1 = Yes, 0 = No)
end
if ~exist('save_directory', 'var')
    save_directory  =  'D:\PM_07 Step Test\MATLAB\mat\';
end

%% Enhanced Error Handling and Validation
fprintf('=== SILIXA TDMS TO PHYSICAL DISPLACEMENT RATE ===\n');
fprintf('Using directory: %s\n', directory);
fprintf('Saving to: %s\n', save_directory);

% Verify directories exist
fprintf('Checking directories...\n');
if ~exist(directory, 'dir')
    error('Source directory does not exist: %s', directory);
end
fprintf('✓ Source directory exists: %s\n', directory);

if ~exist(save_directory, 'dir')
    mkdir(save_directory);
    fprintf('✓ Created output directory: %s\n', save_directory);
else
    fprintf('✓ Output directory exists: %s\n', save_directory);
end

%% Run Script
% Find files
files           =   dir([directory filesearch]);
lf              =   length(files);
fprintf('Found %d TDMS files to process\n', lf);

if lf == 0
    error('No TDMS files found in directory: %s', directory);
end

if isempty(fileindex)
    f_ind           =   1:lf;
else
    f_ind           =   fileindex;
end

cnt             =   0;
successful_files = 0;
failed_files    = 0;

for nn = f_ind
    clc
    cnt             =   cnt + 1;
    filename        =   files(nn).name;
    fprintf('Processing File %i of %i: %s\n',cnt,length(f_ind), filename);
    
    try
        %% Read file header
        fprintf('Loading Header...')
        full_path = [directory filename];
        
        if ~exist(full_path, 'file')
            error('File does not exist: %s', full_path);
        end
        
        [~,fileinfo]    =   TDMS_Adv_Read(full_path);
        n_ch            =   fileinfo.n_ch; % number of channels in the file
        n_samp          =   fileinfo.ChannelLength; % number of sampels in the file
        fsind           =   strcmp(fileinfo.Properties(:,1),'SamplingFrequency[Hz]');
        fs_f            =   fileinfo.Properties{fsind,2}; % sampling frequency
        ssind           =   strcmp(fileinfo.Properties(:,1),'SpatialResolution[m]');
        spatial_samp    =   fileinfo.Properties{ssind,2}; % spatial sampling distance
        srind           =   strcmp(fileinfo.Properties(:,1),'GaugeLength');
        spatial_res     =   fileinfo.Properties{srind,2}; % Spatial resolution
        fprintf('Done (Ch:%d, Samp:%d)\n', n_ch, n_samp)
        
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
        data            =   TDMS_Adv_Read(full_path,arg);
        adc_scalar      =   1/8192;
        data            =   data*adc_scalar;
        fprintf('Done (Size:[%dx%d])\n', size(data,1), size(data,2))
        
        %% Convert to displacement rate in (nanometers/sample)
        fprintf('Converting to Physical Displacement Rate...')
        data                  =   116*data;
        data_units            =   'nm/sample';
        fprintf('Done\n')
        
        %% Save data if required
        if save_data
            fprintf('Saving MAT File...')
            
            % Extract test name from input directory path
            [~, input_dir_name, ~] = fileparts(directory(1:end-1)); % Remove trailing slash and get folder name
            test_subdir = [input_dir_name '_mat\'];
            
            % Create subdirectory if it doesn't exist
            full_save_dir = [save_directory test_subdir];
            if ~exist(full_save_dir, 'dir')
                mkdir(full_save_dir);
                fprintf('Created subdirectory: %s\n', full_save_dir);
            end
            
            output_filename = [full_save_dir filename(1:end-4) 'mat'];
            save(output_filename,'data',...
               'fs_f','spatial_samp','spatial_res',...
                'data_units','-v7.3')
            
            % Verify file was created
            if exist(output_filename, 'file')
                fprintf('Done\n')
                successful_files = successful_files + 1;
            else
                error('File was not created: %s', output_filename);
            end
        else
            successful_files = successful_files + 1;
        end
        
    catch ME
        failed_files = failed_files + 1;
        fprintf('\n✗ ERROR processing %s: %s\n', filename, ME.message);
        if length(ME.stack) > 0
            fprintf('   Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        % Continue with next file instead of stopping
        fprintf('   Continuing with next file...\n');
    end
end

fprintf('\n=== PROCESSING SUMMARY ===\n');
fprintf('Total files: %d\n', cnt);
fprintf('Successful: %d\n', successful_files);
fprintf('Failed: %d\n', failed_files);
fprintf('Output directory: %s\n', save_directory);
