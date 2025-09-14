function test_automated_tdms_processing()
    % TEST_AUTOMATED_TDMS_PROCESSING - Test the automated Python TDMS downsampler
    %
    % This script tests calling the automated (non-interactive) Python TDMS 
    % downsampler from MATLAB using command-line arguments. Maintains clean
    % separation between repositories.
    %
    % Author: AI Assistant
    % Date: 2025-09-14
    
    fprintf('=== BGWRP - Automated Python TDMS Processing Test ===\n\n');
    
    %% Configuration - Absolute paths to maintain repository separation
    pythonScript = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\TDMS_Downsampler_Automated.py';
    inputFolder = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01c_Recovery_short\_das';
    outputFolder = 'C:\Coding\BGWRP\src\test_output_automated';
    decimationFactor = 10;  % Start with a safe factor
    
    fprintf('Configuration:\n');
    fprintf('  Python Script: %s\n', pythonScript);
    fprintf('  Input Folder: %s\n', inputFolder);
    fprintf('  Output Folder: %s\n', outputFolder);
    fprintf('  Decimation Factor: %d\n', decimationFactor);
    
    %% Pre-flight checks
    fprintf('\n--- Pre-flight Checks ---\n');
    
    % Check if automated Python script exists
    if ~exist(pythonScript, 'file')
        error('Automated Python script not found: %s', pythonScript);
    end
    fprintf('✓ Automated Python script found\n');
    
    % Check input data
    if ~exist(inputFolder, 'dir')
        error('Input folder not found: %s', inputFolder);
    end
    
    tdmsFiles = dir(fullfile(inputFolder, '*.tdms'));
    if isempty(tdmsFiles)
        error('No TDMS files found in input folder');
    end
    fprintf('✓ Found %d TDMS files ready for processing\n', length(tdmsFiles));
    
    % Clean/create output folder
    if exist(outputFolder, 'dir')
        rmdir(outputFolder, 's');  % Remove existing output
    end
    mkdir(outputFolder);
    fprintf('✓ Clean output folder created\n');
    
    %% Test automated Python script execution
    fprintf('\n--- Testing Automated Python Execution ---\n');
    
    % Construct the command with proper argument parsing
    cmd = sprintf(['python "%s" ' ...
                   '--input "%s" ' ...
                   '--decimation %d ' ...
                   '--output "%s"'], ...
                   pythonScript, inputFolder, decimationFactor, outputFolder);
    
    fprintf('Executing command:\n  %s\n\n', cmd);
    
    % Execute the command
    tic;
    [status, cmdout] = system(cmd);
    executionTime = toc;
    
    fprintf('--- Execution Results ---\n');
    fprintf('Exit status: %d\n', status);
    fprintf('Execution time: %.2f seconds\n', executionTime);
    fprintf('\nCommand output:\n%s\n', cmdout);
    
    %% Validate results
    fprintf('\n--- Result Validation ---\n');
    
    success = false;
    
    if status == 0
        fprintf('✓ Python script executed successfully\n');
        
        % Check for expected output files
        expectedMatFile = fullfile(outputFolder, 'Output', 'Out.mat');
        expectedPropsFile = fullfile(outputFolder, 'Output', 'OutProperties.txt');
        
        if exist(expectedMatFile, 'file')
            fprintf('✓ Output .mat file found: %s\n', expectedMatFile);
            
            try
                % Try to load the processed data
                loadedData = load(expectedMatFile);
                if isfield(loadedData, 'Data')
                    dataMatrix = loadedData.Data;
                    fprintf('✓ Data matrix loaded successfully\n');
                    fprintf('  Matrix dimensions: %d x %d\n', size(dataMatrix, 1), size(dataMatrix, 2));
                    fprintf('  Data type: %s\n', class(dataMatrix));
                    fprintf('  Memory usage: %.2f MB\n', ...
                            numel(dataMatrix) * 8 / (1024*1024)); % Assuming double precision
                    
                    % Basic data validation
                    if ~isempty(dataMatrix) && all(isfinite(dataMatrix(:)))
                        fprintf('✓ Data matrix appears valid (finite values)\n');
                        success = true;
                    else
                        fprintf('⚠ Data matrix contains invalid values\n');
                    end
                else
                    fprintf('⚠ Expected "Data" field not found in .mat file\n');
                    fprintf('  Available fields: %s\n', strjoin(fieldnames(loadedData), ', '));
                end
                
            catch ME
                fprintf('✗ Error loading data: %s\n', ME.message);
            end
        else
            fprintf('✗ Expected output file not found: %s\n', expectedMatFile);
        end
        
        % Check for properties file
        if exist(expectedPropsFile, 'file')
            fprintf('✓ Properties file found: %s\n', expectedPropsFile);
            try
                props = fileread(expectedPropsFile);
                fprintf('  Properties preview:\n');
                lines = split(props, '\n');
                for i = 1:min(5, length(lines))
                    if ~isempty(strtrim(lines{i}))
                        fprintf('    %s\n', strtrim(lines{i}));
                    end
                end
                if length(lines) > 5
                    fprintf('    ... (%d more lines)\n', length(lines) - 5);
                end
            catch
                fprintf('  Could not read properties file\n');
            end
        else
            fprintf('⚠ Properties file not found (optional)\n');
        end
        
    else
        fprintf('✗ Python script failed with exit code: %d\n', status);
    end
    
    %% Performance comparison (if successful)
    if success
        fprintf('\n--- Performance Analysis ---\n');
        
        % Calculate compression ratio
        originalFiles = length(tdmsFiles);
        originalSizeMB = sum([tdmsFiles.bytes]) / (1024*1024);
        processedSizeMB = numel(dataMatrix) * 8 / (1024*1024);
        
        compressionRatio = originalSizeMB / processedSizeMB;
        
        fprintf('Original TDMS files: %d files, %.2f MB total\n', originalFiles, originalSizeMB);
        fprintf('Processed data: %.2f MB\n', processedSizeMB);
        fprintf('Compression ratio: %.1fx\n', compressionRatio);
        fprintf('Decimation factor: %d\n', decimationFactor);
    end
    
    %% Summary and integration recommendations
    fprintf('\n--- Integration Summary ---\n');
    
    if success
        fprintf('🎉 SUCCESS: Automated Python-MATLAB integration working!\n\n');
        
        fprintf('Next steps for production integration:\n');
        fprintf('1. Create wrapper function for routine use\n');
        fprintf('2. Add error handling and parameter validation\n');
        fprintf('3. Integrate into main BGWRP processing pipeline\n');
        fprintf('4. Consider batch processing for multiple datasets\n');
        
        fprintf('\nRecommended usage pattern:\n');
        fprintf('  inputDir = ''C:\\path\\to\\tdms\\files'';\n');
        fprintf('  [success, data] = process_tdms_with_python(inputDir, ''DecimationFactor'', 10);\n');
        
    else
        fprintf('❌ FAILURE: Integration needs troubleshooting\n\n');
        
        fprintf('Troubleshooting steps:\n');
        fprintf('1. Check Python environment and package installations\n');
        fprintf('2. Verify TDMS files are valid and readable\n');
        fprintf('3. Check file permissions for output directory\n');
        fprintf('4. Review Python script error messages above\n');
    end
    
    fprintf('\n=== Test Complete ===\n');
end

