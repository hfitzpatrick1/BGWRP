function test_python_tdms_integration()
    % TEST_PYTHON_TDMS_INTEGRATION - Test calling Python TDMS downsampler from MATLAB
    %
    % This script tests the integration between BGWRP MATLAB toolkit and the 
    % Python TDMS Signal Downsampler repository
    %
    % Author: AI Assistant
    % Date: 2025-09-14
    
    console_log('=== BGWRP - Python TDMS Integration Test ===\n\n');
    
    %% Configuration
    % Absolute paths to avoid any path resolution issues
    pythonScript = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\TDMS_Signal_Downsampler.py';
    inputFolder = 'C:\Coding\BGWRP\data\_BATCH\_raw\PT01c_Recovery_short\_das';
    outputFolder = 'C:\Coding\BGWRP\src\test_output';
    
    console_log('Python Script: %s\n', pythonScript);
    console_log('Input Folder: %s\n', inputFolder);
    console_log('Output Folder: %s\n', outputFolder);
    
    %% Pre-flight checks
    console_log('\n--- Pre-flight Checks ---\n');
    
    % Check if Python script exists
    if ~exist(pythonScript, 'file')
        error('Python script not found: %s', pythonScript);
    else
        console_log('✓ Python script found\n');
    end
    
    % Check if input folder exists and contains TDMS files
    if ~exist(inputFolder, 'dir')
        error('Input folder not found: %s', inputFolder);
    else
        console_log('✓ Input folder found\n');
    end
    
    % Count TDMS files in input folder
    tdmsFiles = dir(fullfile(inputFolder, '*.tdms'));
    if isempty(tdmsFiles)
        error('No TDMS files found in input folder');
    else
        console_log('✓ Found %d TDMS files in input folder\n', length(tdmsFiles));
    end
    
    % Create output folder if it doesn't exist
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
        console_log('✓ Created output folder\n');
    else
        console_log('✓ Output folder exists\n');
    end
    
    %% Method 1: Test Python environment detection
    console_log('\n--- Python Environment Detection ---\n');
    
    try
        [status, pythonVersion] = system('python --version');
        if status == 0
            console_log('✓ Python available: %s', pythonVersion);
        else
            console_log('⚠ Python not in PATH, trying python3...\n');
            [status, pythonVersion] = system('python3 --version');
            if status == 0
                console_log('✓ Python3 available: %s', pythonVersion);
            else
                warning('Python not found in system PATH');
            end
        end
    catch ME
        console_log('Error checking Python: %s\n', ME.message);
    end
    
    %% Method 2: Test calling Python script with system command
    console_log('\n--- Testing System Command Approach ---\n');
    
    % Change to output directory for the test
    originalDir = pwd;
    cd(outputFolder);
    
    try
        % Construct the command - Note: The original script expects interactive input
        % For now, we'll just test if we can execute the script and see its output
        pythonCmd = sprintf('python "%s"', pythonScript);
        
        console_log('Executing command: %s\n', pythonCmd);
        console_log('Note: This will likely prompt for user input since the original script is interactive\n');
        
        % For this test, we'll use a timeout and capture initial output
        [status, cmdout] = system(pythonCmd);
        
        console_log('Command status: %d\n', status);
        console_log('Command output:\n%s\n', cmdout);
        
        if status == 0
            console_log('✓ Python script executed successfully\n');
        else
            console_log('⚠ Python script returned non-zero status\n');
        end
        
    catch ME
        console_log('Error executing Python script: %s\n', ME.message);
    end
    
    % Return to original directory
    cd(originalDir);
    
    %% Method 3: Test MATLAB's pyenv (if available)
    console_log('\n--- Testing MATLAB Python Integration ---\n');
    
    try
        % Check if pyenv is available (MATLAB R2019b+)
        if exist('pyenv', 'builtin')
            pe = pyenv;
            console_log('✓ MATLAB Python integration available\n');
            console_log('  Python Version: %s\n', pe.Version);
            console_log('  Python Executable: %s\n', pe.Executable);
            console_log('  Python Status: %s\n', pe.Status);
        else
            console_log('⚠ MATLAB Python integration (pyenv) not available\n');
            console_log('  This is expected for MATLAB versions before R2019b\n');
        end
    catch ME
        console_log('Error checking MATLAB Python integration: %s\n', ME.message);
    end
    
    %% Summary and Recommendations
    console_log('\n--- Test Summary ---\n');
    console_log('Input data: %d TDMS files ready for processing\n', length(tdmsFiles));
    console_log('Output location: %s\n', outputFolder);
    
    console_log('\n--- Next Steps ---\n');
    console_log('1. Modify Python script to accept command-line arguments\n');
    console_log('2. Create wrapper function for automated processing\n');
    console_log('3. Test full pipeline with actual data processing\n');
    
    console_log('\n--- File Information ---\n');
    console_log('Sample TDMS files:\n');
    for i = 1:min(5, length(tdmsFiles))  % Show first 5 files
        console_log('  %s\n', tdmsFiles(i).name);
    end
    if length(tdmsFiles) > 5
        console_log('  ... and %d more files\n', length(tdmsFiles) - 5);
    end
    
    console_log('\n=== Test Complete ===\n');
end

