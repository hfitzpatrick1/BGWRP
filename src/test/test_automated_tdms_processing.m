function test_automated_tdms_processing()
    % TEST_AUTOMATED_TDMS_PROCESSING - Test the automated Python TDMS downsampler
    %
    % This script tests calling the automated (non-interactive) Python TDMS 
    % downsampler from MATLAB using command-line arguments. Maintains clean
    % separation between repositories.
    %
    % Author: AI Assistant
    % Date: 2025-09-14
    
    console_log('=== BGWRP - Automated Python TDMS Processing Test ===\n\n');
    
    %% Configuration - Absolute paths to maintain repository separation
    pythonScript = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\TDMS_Downsampler_Automated.py';
    inputFolder = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01c_Recovery_short\_das';
    outputFolder = 'C:\Coding\BGWRP\src\test_output_automated';
    decimationFactor = 10;  % Start with a safe factor
    
    console_log('Configuration:\n');
    console_log('  Python Script: %s\n', pythonScript);
    console_log('  Input Folder: %s\n', inputFolder);
    console_log('  Output Folder: %s\n', outputFolder);
    console_log('  Decimation Factor: %d\n', decimationFactor);
    
    %% Pre-flight checks
    console_log('\n--- Pre-flight Checks ---\n');
    
    % Check if automated Python script exists
    if ~exist(pythonScript, 'file')
        error('Automated Python script not found: %s', pythonScript);
    end
    console_log('✓ Automated Python script found\n');
    
    % Check input data
    if ~exist(inputFolder, 'dir')
        error('Input folder not found: %s', inputFolder);
    end
    
    tdmsFiles = dir(fullfile(inputFolder, '*.tdms'));
    if isempty(tdmsFiles)
        error('No TDMS files found in input folder');
    end
    console_log('✓ Found %d TDMS files ready for processing\n', length(tdmsFiles));
    
    % Clean/create output folder
    if exist(outputFolder, 'dir')
        rmdir(outputFolder, 's');  % Remove existing output
    end
    mkdir(outputFolder);
    console_log('✓ Clean output folder created\n');
    
    %% Test automated Python script execution
    console_log('\n--- Testing Automated Python Execution ---\n');
    
    % Construct the command with proper argument parsing
    cmd = sprintf(['python "%s" ' ...
                   '--input "%s" ' ...
                   '--decimation %d ' ...
                   '--output "%s"'], ...
                   pythonScript, inputFolder, decimationFactor, outputFolder);
    
    console_log('Executing command:\n  %s\n\n', cmd);
    
    % Execute the command
    tic;
    [status, cmdout] = system(cmd);
    executionTime = toc;
    
    console_log('--- Execution Results ---\n');
    console_log('Exit status: %d\n', status);
    console_log('Execution time: %.2f seconds\n', executionTime);
    console_log('\nCommand output:\n%s\n', cmdout);
    
    %% Validate results
    console_log('\n--- Result Validation ---\n');
    
    success = false;
    
    if status == 0
        console_log('✓ Python script executed successfully\n');
        
        % Check for expected output files
        expectedMatFile = fullfile(outputFolder, 'Output', 'Out.mat');
        expectedPropsFile = fullfile(outputFolder, 'Output', 'OutProperties.txt');
        
        if exist(expectedMatFile, 'file')
            console_log('✓ Output .mat file found: %s\n', expectedMatFile);
            
            try
                % Try to load the processed data
                loadedData = load(expectedMatFile);
                if isfield(loadedData, 'Data')
                    dataMatrix = loadedData.Data;
                    console_log('✓ Data matrix loaded successfully\n');
                    console_log('  Matrix dimensions: %d x %d\n', size(dataMatrix, 1), size(dataMatrix, 2));
                    console_log('  Data type: %s\n', class(dataMatrix));
                    console_log('  Memory usage: %.2f MB\n', ...
                            numel(dataMatrix) * 8 / (1024*1024)); % Assuming double precision
                    
                    % Basic data validation
                    if ~isempty(dataMatrix) && all(isfinite(dataMatrix(:)))
                        console_log('✓ Data matrix appears valid (finite values)\n');
                        success = true;
                    else
                        console_log('⚠ Data matrix contains invalid values\n');
                    end
                else
                    console_log('⚠ Expected "Data" field not found in .mat file\n');
                    console_log('  Available fields: %s\n', strjoin(fieldnames(loadedData), ', '));
                end
                
            catch ME
                console_log('✗ Error loading data: %s\n', ME.message);
            end
        else
            console_log('✗ Expected output file not found: %s\n', expectedMatFile);
        end
        
        % Check for properties file
        if exist(expectedPropsFile, 'file')
            console_log('✓ Properties file found: %s\n', expectedPropsFile);
            try
                props = fileread(expectedPropsFile);
                console_log('  Properties preview:\n');
                lines = split(props, '\n');
                for i = 1:min(5, length(lines))
                    if ~isempty(strtrim(lines{i}))
                        console_log('    %s\n', strtrim(lines{i}));
                    end
                end
                if length(lines) > 5
                    console_log('    ... (%d more lines)\n', length(lines) - 5);
                end
            catch
                console_log('  Could not read properties file\n');
            end
        else
            console_log('⚠ Properties file not found (optional)\n');
        end
        
    else
        console_log('✗ Python script failed with exit code: %d\n', status);
    end
    
    %% Performance comparison (if successful)
    if success
        console_log('\n--- Performance Analysis ---\n');
        
        % Calculate compression ratio
        originalFiles = length(tdmsFiles);
        originalSizeMB = sum([tdmsFiles.bytes]) / (1024*1024);
        processedSizeMB = numel(dataMatrix) * 8 / (1024*1024);
        
        compressionRatio = originalSizeMB / processedSizeMB;
        
        console_log('Original TDMS files: %d files, %.2f MB total\n', originalFiles, originalSizeMB);
        console_log('Processed data: %.2f MB\n', processedSizeMB);
        console_log('Compression ratio: %.1fx\n', compressionRatio);
        console_log('Decimation factor: %d\n', decimationFactor);
    end
    
    %% Summary and integration recommendations
    console_log('\n--- Integration Summary ---\n');
    
    if success
        console_log('🎉 SUCCESS: Automated Python-MATLAB integration working!\n\n');
        
        console_log('Next steps for production integration:\n');
        console_log('1. Create wrapper function for routine use\n');
        console_log('2. Add error handling and parameter validation\n');
        console_log('3. Integrate into main BGWRP processing pipeline\n');
        console_log('4. Consider batch processing for multiple datasets\n');
        
        console_log('\nRecommended usage pattern:\n');
        console_log('  inputDir = ''C:\\path\\to\\tdms\\files'';\n');
        console_log('  [success, data] = process_tdms_with_python(inputDir, ''DecimationFactor'', 10);\n');
        
    else
        console_log('❌ FAILURE: Integration needs troubleshooting\n\n');
        
        console_log('Troubleshooting steps:\n');
        console_log('1. Check Python environment and package installations\n');
        console_log('2. Verify TDMS files are valid and readable\n');
        console_log('3. Check file permissions for output directory\n');
        console_log('4. Review Python script error messages above\n');
    end
    
    console_log('\n=== Test Complete ===\n');
end

