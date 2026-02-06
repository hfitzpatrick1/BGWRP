function [success, outputPath, metadata] = call_python_tdms_downsampler(inputFolder, varargin)
    % CALL_PYTHON_TDMS_DOWNSAMPLER - Interface to Python TDMS Signal Downsampler
    %
    % This function provides a MATLAB interface to the Python TDMS Signal 
    % Downsampler located in the separate repository.
    %
    % Usage:
    %   [success, outputPath] = call_python_tdms_downsampler(inputFolder)
    %   [success, outputPath] = call_python_tdms_downsampler(inputFolder, 'Name', Value, ...)
    %
    % Inputs:
    %   inputFolder - Path to folder containing TDMS files
    %
    % Optional Name-Value Pairs:
    %   'DecimationFactor' - Decimation factor (default: 10)
    %   'ChannelRange' - [min, max] channel indices (default: all channels)
    %   'OutputFolder' - Custom output folder (default: creates temp folder)
    %   'PythonExe' - Path to Python executable (default: 'python')
    %   'Timeout' - Timeout in seconds (default: 300)
    %   'Verbose' - Display detailed output (default: true)
    %
    % Outputs:
    %   success - True if processing completed successfully
    %   outputPath - Path to the output .mat file
    %   metadata - Structure containing processing metadata
    %
    % Example:
    %   inputDir = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01c_Recovery_short\_das';
    %   [success, matFile] = call_python_tdms_downsampler(inputDir, 'DecimationFactor', 5);
    %   if success
    %       data = load(matFile);
    %       disp('Processing complete!');
    %   end
    %
    % Author: AI Assistant  
    % Date: 2025-09-14
    
    %% Input validation and default parameters
    p = inputParser;
    addRequired(p, 'inputFolder', @(x) ischar(x) && exist(x, 'dir'));
    addParameter(p, 'DecimationFactor', 10, @(x) isnumeric(x) && x > 0);
    addParameter(p, 'ChannelRange', [], @(x) isnumeric(x) && length(x) <= 2);
    addParameter(p, 'OutputFolder', '', @ischar);
    addParameter(p, 'PythonExe', 'python', @ischar);
    addParameter(p, 'Timeout', 300, @(x) isnumeric(x) && x > 0);
    addParameter(p, 'Verbose', true, @islogical);
    
    parse(p, inputFolder, varargin{:});
    
    % Extract parsed parameters
    decimationFactor = p.Results.DecimationFactor;
    channelRange = p.Results.ChannelRange;
    outputFolder = p.Results.OutputFolder;
    pythonExe = p.Results.PythonExe;
    timeout = p.Results.Timeout;
    verbose = p.Results.Verbose;
    
    %% Initialize outputs
    success = false;
    outputPath = '';
    metadata = struct();
    
    if verbose
        console_log('=== BGWRP Python TDMS Downsampler Interface ===\n');
    end
    
    %% Configuration
    pythonScript = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\TDMS_Downsampler_Automated.py';
    
    % Create output folder if not specified
    if isempty(outputFolder)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        outputFolder = fullfile(tempdir, sprintf('tdms_output_%s', timestamp));
    end
    
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
        if verbose
            console_log('Created output folder: %s\n', outputFolder);
        end
    end
    
    %% Pre-flight checks
    if verbose
        console_log('\n--- Pre-flight Checks ---\n');
    end
    
    % Check Python script
    if ~exist(pythonScript, 'file')
        error('Python TDMS script not found: %s', pythonScript);
    end
    if verbose
        console_log('✓ Python script found\n');
    end
    
    % Check input folder and TDMS files
    tdmsFiles = dir(fullfile(inputFolder, '*.tdms'));
    if isempty(tdmsFiles)
        error('No TDMS files found in input folder: %s', inputFolder);
    end
    if verbose
        console_log('✓ Found %d TDMS files\n', length(tdmsFiles));
    end
    
    % Test Python availability
    [pythonStatus, pythonOutput] = system(sprintf('%s --version', pythonExe));
    if pythonStatus ~= 0
        error('Python not available with command: %s\nOutput: %s', pythonExe, pythonOutput);
    end
    if verbose
        console_log('✓ Python available: %s', strtrim(pythonOutput));
    end
    
    %% Prepare Python execution
    if verbose
        console_log('\n--- Preparing Python Execution ---\n');
        console_log('Note: Current Python script requires interactive input.\n');
        console_log('      This function will attempt automated execution.\n');
    end
    
    % Store current directory and change to output folder
    originalDir = pwd;
    cd(outputFolder);
    
    try
        %% Method 1: Direct execution (will likely require user interaction)
        if verbose
            console_log('\nAttempting to execute Python script...\n');
            console_log('Script: %s\n', pythonScript);
            console_log('Working directory: %s\n', pwd);
        end
        
        % Construct command with proper arguments for automated script
        cmd = sprintf('"%s" "%s" --input "%s" --decimation %d --output "%s"', ...
                      pythonExe, pythonScript, inputFolder, decimationFactor, outputFolder);
        
        % Add channel range if specified
        if ~isempty(channelRange)
            cmd = sprintf('%s --channels %d %d', cmd, channelRange(1), channelRange(2));
        end
        
        if verbose
            console_log('Command: %s\n', cmd);
            console_log('\n--- Python Script Execution ---\n');
        end
        
        % Execute automated script (no user interaction required)
        [status, cmdout] = system(cmd);
        
        if verbose
            console_log('Exit status: %d\n', status);
            console_log('Output:\n%s\n', cmdout);
        end
        
        %% Check for output files
        % Look for typical output files from the Python script
        possibleOutputs = {
            'Output\Out.mat',
            'Out.mat',
            fullfile('Output', 'Out.mat')
        };
        
        foundOutput = false;
        for i = 1:length(possibleOutputs)
            if exist(possibleOutputs{i}, 'file')
                outputPath = fullfile(pwd, possibleOutputs{i});
                foundOutput = true;
                if verbose
                    console_log('✓ Found output file: %s\n', outputPath);
                end
                break;
            end
        end
        
        if foundOutput
            success = true;
            
            % Try to load metadata if available
            metadataFile = fullfile('Output', 'OutProperties.txt');
            if exist(metadataFile, 'file')
                try
                    metadata = parse_properties_file(metadataFile);
                    if verbose
                        console_log('✓ Loaded metadata from properties file\n');
                    end
                catch
                    if verbose
                        console_log('⚠ Could not parse metadata file\n');
                    end
                end
            end
            
            % Add processing information to metadata
            metadata.processing_timestamp = datestr(now);
            metadata.input_folder = inputFolder;
            metadata.output_folder = outputFolder;
            metadata.tdms_file_count = length(tdmsFiles);
            metadata.decimation_factor = decimationFactor;
            
        else
            if verbose
                console_log('⚠ No output files found\n');
            end
        end
        
    catch ME
        if verbose
            console_log('Error during execution: %s\n', ME.message);
        end
        success = false;
    end
    
    % Return to original directory
    cd(originalDir);
    
    %% Summary
    if verbose
        console_log('\n--- Execution Summary ---\n');
        console_log('Success: %s\n', matlab.lang.makeValidName(string(success)));
        if success
            console_log('Output file: %s\n', outputPath);
        end
        console_log('Processing completed.\n');
    end
end

function props = parse_properties_file(filename)
    % Parse the properties text file generated by the Python script
    props = struct();
    
    try
        fid = fopen(filename, 'r');
        if fid == -1
            return;
        end
        
        while ~feof(fid)
            line = fgetl(fid);
            if ischar(line) && contains(line, ':')
                parts = split(line, ':', 2);
                if length(parts) == 2
                    key = matlab.lang.makeValidName(strtrim(parts{1}));
                    value = strtrim(parts{2});
                    
                    % Try to convert to number if possible
                    numValue = str2double(value);
                    if ~isnan(numValue)
                        props.(key) = numValue;
                    else
                        props.(key) = value;
                    end
                end
            end
        end
        
        fclose(fid);
    catch
        % If parsing fails, return empty struct
        props = struct();
    end
end
