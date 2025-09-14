function test_python_tdms_integration()
    % TEST_PYTHON_TDMS_INTEGRATION - Test calling Python TDMS downsampler from MATLAB
    %
    % This script tests the integration between BGWRP MATLAB toolkit and the 
    % Python TDMS Signal Downsampler repository
    %
    % Author: AI Assistant
    % Date: 2025-09-14
    
    fprintf('=== BGWRP - Python TDMS Integration Test ===\n\n');
    
    %% Configuration
    % Absolute paths to avoid any path resolution issues
    pythonScript = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\TDMS_Signal_Downsampler.py';
    inputFolder = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01c_Recovery_short\_das';
    outputFolder = 'C:\Coding\BGWRP\src\test_output';
    
    fprintf('Python Script: %s\n', pythonScript);
    fprintf('Input Folder: %s\n', inputFolder);
    fprintf('Output Folder: %s\n', outputFolder);
    
    %% Pre-flight checks
    fprintf('\n--- Pre-flight Checks ---\n');
    
    % Check if Python script exists
    if ~exist(pythonScript, 'file')
        error('Python script not found: %s', pythonScript);
    else
        fprintf('✓ Python script found\n');
    end
    
    % Check if input folder exists and contains TDMS files
    if ~exist(inputFolder, 'dir')
        error('Input folder not found: %s', inputFolder);
    else
        fprintf('✓ Input folder found\n');
    end
    
    % Count TDMS files in input folder
    tdmsFiles = dir(fullfile(inputFolder, '*.tdms'));
    if isempty(tdmsFiles)
        error('No TDMS files found in input folder');
    else
        fprintf('✓ Found %d TDMS files in input folder\n', length(tdmsFiles));
    end
    
    % Create output folder if it doesn't exist
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
        fprintf('✓ Created output folder\n');
    else
        fprintf('✓ Output folder exists\n');
    end
    
    %% Method 1: Test Python environment detection
    fprintf('\n--- Python Environment Detection ---\n');
    
    try
        [status, pythonVersion] = system('python --version');
        if status == 0
            fprintf('✓ Python available: %s', pythonVersion);
        else
            fprintf('⚠ Python not in PATH, trying python3...\n');
            [status, pythonVersion] = system('python3 --version');
            if status == 0
                fprintf('✓ Python3 available: %s', pythonVersion);
            else
                warning('Python not found in system PATH');
            end
        end
    catch ME
        fprintf('Error checking Python: %s\n', ME.message);
    end
    
    %% Method 2: Test calling Python script with system command
    fprintf('\n--- Testing System Command Approach ---\n');
    
    % Change to output directory for the test
    originalDir = pwd;
    cd(outputFolder);
    
    try
        % Construct the command - Note: The original script expects interactive input
        % For now, we'll just test if we can execute the script and see its output
        pythonCmd = sprintf('python "%s"', pythonScript);
        
        fprintf('Executing command: %s\n', pythonCmd);
        fprintf('Note: This will likely prompt for user input since the original script is interactive\n');
        
        % For this test, we'll use a timeout and capture initial output
        [status, cmdout] = system(pythonCmd);
        
        fprintf('Command status: %d\n', status);
        fprintf('Command output:\n%s\n', cmdout);
        
        if status == 0
            fprintf('✓ Python script executed successfully\n');
        else
            fprintf('⚠ Python script returned non-zero status\n');
        end
        
    catch ME
        fprintf('Error executing Python script: %s\n', ME.message);
    end
    
    % Return to original directory
    cd(originalDir);
    
    %% Method 3: Test MATLAB's pyenv (if available)
    fprintf('\n--- Testing MATLAB Python Integration ---\n');
    
    try
        % Check if pyenv is available (MATLAB R2019b+)
        if exist('pyenv', 'builtin')
            pe = pyenv;
            fprintf('✓ MATLAB Python integration available\n');
            fprintf('  Python Version: %s\n', pe.Version);
            fprintf('  Python Executable: %s\n', pe.Executable);
            fprintf('  Python Status: %s\n', pe.Status);
        else
            fprintf('⚠ MATLAB Python integration (pyenv) not available\n');
            fprintf('  This is expected for MATLAB versions before R2019b\n');
        end
    catch ME
        fprintf('Error checking MATLAB Python integration: %s\n', ME.message);
    end
    
    %% Summary and Recommendations
    fprintf('\n--- Test Summary ---\n');
    fprintf('Input data: %d TDMS files ready for processing\n', length(tdmsFiles));
    fprintf('Output location: %s\n', outputFolder);
    
    fprintf('\n--- Next Steps ---\n');
    fprintf('1. Modify Python script to accept command-line arguments\n');
    fprintf('2. Create wrapper function for automated processing\n');
    fprintf('3. Test full pipeline with actual data processing\n');
    
    fprintf('\n--- File Information ---\n');
    fprintf('Sample TDMS files:\n');
    for i = 1:min(5, length(tdmsFiles))  % Show first 5 files
        fprintf('  %s\n', tdmsFiles(i).name);
    end
    if length(tdmsFiles) > 5
        fprintf('  ... and %d more files\n', length(tdmsFiles) - 5);
    end
    
    fprintf('\n=== Test Complete ===\n');
end

