function success = process_head_data(input_directory, output_file)
%PROCESS_HEAD_DATA Combine multiple zone head data files into single file
%
% Similar to process_mat_data but for head data - combines multiple zone
% files (head_*_z1.mat, head_*_z2.mat, etc.) into a single unified file
%
% Inputs:
%   input_directory - Directory containing head_*.mat files
%   output_file     - Output path for combined head data file
%
% Outputs:
%   success - True if processing completed successfully
%
% Combined file structure:
%   Date: [Nx1] shared timestamp array
%   zones.z1.Drawdownft: [Nx1] water level data for zone 1
%   zones.z1.Depthft: scalar depth for zone 1
%   zones.z2.Drawdownft: [Nx1] water level data for zone 2
%   zones.z2.Depthft: scalar depth for zone 2
%   etc.

success = false;

try
    console_log('Processing head data: %s\n', input_directory);
    
    % Check if this is a PT01c, PT01b, or PT01a dataset and use global head data directory
    if contains(input_directory, 'PT01a')
        console_log('🔄 Detected PT01a dataset - using global head data directory\n');
        cfg_tmp = config();
        global_head_dir = fullfile(fileparts(cfg_tmp.base_input), 'head');
        
        % Find ONLY head_a_*.mat files in global directory for PT01a
        mat_files = dir(fullfile(global_head_dir, 'head_a_*.mat'));
        
        if isempty(mat_files)
            console_log('⚠ No head_a_*.mat files found in %s\n', global_head_dir);
            % Fallback to input directory
            mat_files = dir(fullfile(input_directory, '*.mat'));
        else
            console_log('✓ Found %d head_a_*.mat files in global directory\n', length(mat_files));
            % Update input_directory to point to global directory for file loading
            input_directory = global_head_dir;
        end
    elseif contains(input_directory, 'PT01c')
        console_log('🔄 Detected PT01c dataset - using global head data directory\n');
        cfg_tmp = config();
        global_head_dir = fullfile(fileparts(cfg_tmp.base_input), 'head');
        
        % Find ONLY head_c_*.mat files in global directory for PT01c
        mat_files = dir(fullfile(global_head_dir, 'head_c_*.mat'));
        
        if isempty(mat_files)
            console_log('⚠ No head_c_*.mat files found in %s\n', global_head_dir);
            % Fallback to input directory
            mat_files = dir(fullfile(input_directory, '*.mat'));
        else
            console_log('✓ Found %d head_c_*.mat files in global directory\n', length(mat_files));
            % Update input_directory to point to global directory for file loading
            input_directory = global_head_dir;
        end
    elseif contains(input_directory, 'PT01b')
        console_log('🔄 Detected PT01b dataset - using global head data directory\n');
        cfg_tmp = config();
        global_head_dir = fullfile(fileparts(cfg_tmp.base_input), 'head');
        
        % Find ONLY head_b_*.mat files in global directory for PT01b
        mat_files = dir(fullfile(global_head_dir, 'head_b_*.mat'));
        
        if isempty(mat_files)
            console_log('⚠ No head_b_*.mat files found in %s\n', global_head_dir);
            % Fallback to input directory
            mat_files = dir(fullfile(input_directory, '*.mat'));
        else
            console_log('✓ Found %d head_b_*.mat files in global directory\n', length(mat_files));
            % Update input_directory to point to global directory for file loading
            input_directory = global_head_dir;
        end
    else
        % For other datasets, find all .mat files in input directory (original behavior)
        mat_files = dir(fullfile(input_directory, '*.mat'));
    end
    
    if isempty(mat_files)
        console_log('⚠ No .mat files found in %s\n', input_directory);
        return;
    end
    
    % Check if we have a combined head_data.mat file
    combined_file = fullfile(input_directory, 'head_data.mat');
    if exist(combined_file, 'file')
        console_log('Found combined head_data.mat file - using existing combined data\n');
        try
            % Load the existing combined data
            combined_data = load(combined_file);
            
            % Verify it has the expected structure
            if isfield(combined_data, 'zones') && isfield(combined_data, 'Date')
                console_log('✓ Combined head data loaded successfully\n');
                console_log('  Zones: %s\n', strjoin(fieldnames(combined_data.zones), ', '));
                console_log('  Data points: %d\n', length(combined_data.Date));
                
                % Save to output location if different
                if ~strcmp(combined_file, output_file)
                    save(output_file, '-struct', 'combined_data');
                    console_log('✓ Copied combined head data to: %s\n', output_file);
                end
                
                success = true;
                return;
            else
                console_log('⚠ Combined head_data.mat missing required fields (zones, Date)\n');
                % Continue with individual file processing
            end
        catch ME
            console_log('⚠ Failed to load combined head_data.mat: %s\n', ME.message);
            % Continue with individual file processing
        end
    end
    
    console_log('Found %d head data files\n', length(mat_files));
    
    % Initialize combined data structure
    combined_data = struct();
    combined_data.zones = struct();
    shared_date = [];
    
    % Process each head data file
    for i = 1:length(mat_files)
        filename = mat_files(i).name;
        filepath = fullfile(input_directory, filename);
        
        console_log('  Processing: %s\n', filename);
        
        try
            % Load head data file
            loaded_data = load(filepath);
            
            % Handle different file structures
            if isfield(loaded_data, 'recovery_data') && isfield(loaded_data, 'depth_ft')
                % This is a pw file with recovery_data structure
                head_data = struct();
                head_data.Date = loaded_data.recovery_data.Date;
                head_data.Drawdownft = loaded_data.recovery_data.Drawdownft;
                head_data.Depthft = loaded_data.depth_ft; % Scalar depth value
                console_log('    ✓ Loaded pw file with recovery_data structure\n');
            elseif isfield(loaded_data, 'Date') && isfield(loaded_data, 'Drawdownft') && isfield(loaded_data, 'Depthft')
                % This is a standard zone file
                head_data = loaded_data;
            else
                console_log('    ⚠ Missing required fields (Date, Drawdownft, Depthft) in %s\n', filename);
                continue;
            end
            
            % Extract zone name from filename - support both zone (z2, z3, etc.) and pumping well (pw)
            % Handle head_a_z2.mat, head_b_z2.mat, head_c_z2.mat and head_c_pw.mat patterns
            zone_match = regexp(filename, 'head_[abc]_(z\d+|pw)\.mat', 'tokens');
            if isempty(zone_match)
                console_log('    ⚠ Could not extract zone name from %s\n', filename);
                continue;
            end
            zone_name = zone_match{1}{1};
            
            % Clean timestamp array - remove NaT values
            valid_mask = ~isnat(head_data.Date);
            if sum(valid_mask) == 0
                console_log('    ✗ Zone %s has no valid timestamps - skipping\n', zone_name);
                continue;
            end
            
            if sum(valid_mask) < length(head_data.Date)
                console_log('    ⚠ Zone %s has %d invalid timestamps, cleaning...\n', zone_name, sum(~valid_mask));
                head_data.Date = head_data.Date(valid_mask);
                head_data.Drawdownft = head_data.Drawdownft(valid_mask);
                % Only filter Depthft if it's an array, not a scalar
                if length(head_data.Depthft) > 1
                    head_data.Depthft = head_data.Depthft(valid_mask);
                end
            end
            
            % Validate/establish shared timestamp array
            if isempty(shared_date)
                shared_date = head_data.Date;
                console_log('    ✓ Established shared timestamp array from %s (%d points)\n', zone_name, length(shared_date));
                
                % Clean shared timestamp array too
                shared_valid_mask = ~isnat(shared_date);
                if sum(shared_valid_mask) < length(shared_date)
                    console_log('    → Cleaning %d invalid timestamps from reference\n', sum(~shared_valid_mask));
                    shared_date = shared_date(shared_valid_mask);
                end
            else
                % Handle timestamp mismatches by finding overlapping period
                if length(head_data.Date) ~= length(shared_date)
                    console_log('    ⚠ Zone %s has different number of timestamps (%d vs %d) - aligning...\n', ...
                        zone_name, length(head_data.Date), length(shared_date));
                    
                    % DEBUG: Show actual time ranges
                    console_log('      Reference: %s to %s\n', shared_date(1), shared_date(end));
                    console_log('      Zone %s:   %s to %s\n', zone_name, head_data.Date(1), head_data.Date(end));
                    
                    % Find overlapping time window
                    shared_start = max(shared_date(1), head_data.Date(1));
                    shared_end = min(shared_date(end), head_data.Date(end));
                    
                    console_log('      Overlap window: %s to %s\n', shared_start, shared_end);
                    
                    if shared_end <= shared_start
                        console_log('    ✗ Zone %s has no overlapping time period - skipping\n', zone_name);
                        continue;
                    end
                    
                    % Trim reference timestamps to overlap window
                    ref_mask = shared_date >= shared_start & shared_date <= shared_end;
                    zone_mask = head_data.Date >= shared_start & head_data.Date <= shared_end;
                    
                    if sum(ref_mask) < 10 || sum(zone_mask) < 10
                        console_log('    ✗ Zone %s overlap too small (%d points) - skipping\n', zone_name, min(sum(ref_mask), sum(zone_mask)));
                        continue;
                    end
                    
                    % Align zone data to reference timestamps using nearest neighbor
                    zone_aligned_data = interp1(head_data.Date(zone_mask), head_data.Drawdownft(zone_mask), ...
                        shared_date(ref_mask), 'linear', 'extrap');
                    
                    % Update shared_date to overlap window on first mismatch
                    if length(shared_date) ~= sum(ref_mask)
                        console_log('    → Trimming reference timebase to overlap window (%d points)\n', sum(ref_mask));
                        shared_date = shared_date(ref_mask);
                    end
                    
                    % Use aligned data
                    head_data.Drawdownft = zone_aligned_data;
                    
                    console_log('    ✓ Zone %s aligned to reference timebase (%d points)\n', zone_name, length(shared_date));
                else
                    % Same length - check if timestamps are close enough (within 1 second)
                    time_diff = abs(seconds(head_data.Date - shared_date));
                    max_diff = max(time_diff);
                    if max_diff > 1
                        console_log('    ⚠ Zone %s timestamps differ by up to %.1f seconds - aligning...\n', zone_name, max_diff);
                        
                        % Align data to reference timestamps
                        aligned_data = interp1(head_data.Date, head_data.Drawdownft, shared_date, 'linear', 'extrap');
                        head_data.Drawdownft = aligned_data;
                        
                        console_log('    ✓ Zone %s realigned to reference timestamps\n', zone_name);
                    end
                end
            end
            
            % Store zone data
            combined_data.zones.(zone_name).Drawdownft = head_data.Drawdownft;
            combined_data.zones.(zone_name).Depthft = mean(head_data.Depthft, 'omitnan');
            
            % Store metadata
            combined_data.zones.(zone_name).source_file = filename;
            combined_data.zones.(zone_name).num_points = length(head_data.Drawdownft);
            
            console_log('    ✓ Zone %s: %.1f ft depth, %d data points\n', ...
                zone_name, combined_data.zones.(zone_name).Depthft, combined_data.zones.(zone_name).num_points);
            
        catch ME
            console_log('    ✗ Error processing %s: %s\n', filename, ME.message);
            continue;
        end
    end
    
    % Validate we have data
    zone_names = fieldnames(combined_data.zones);
    if isempty(zone_names)
        console_log('✗ No valid zones processed\n');
        return;
    end
    
    if isempty(shared_date)
        console_log('✗ No shared timestamp array established\n');
        return;
    end
    
    % Store shared timestamp array
    combined_data.Date = shared_date;
    
    % Add metadata
    combined_data.processing_info.timestamp = datetime('now');
    combined_data.processing_info.source_directory = input_directory;
    combined_data.processing_info.zones_processed = zone_names;
    combined_data.processing_info.num_zones = length(zone_names);
    combined_data.processing_info.time_range.start = shared_date(1);
    combined_data.processing_info.time_range.end = shared_date(end);
    combined_data.processing_info.time_range.duration_hours = hours(shared_date(end) - shared_date(1));
    combined_data.processing_info.using_global_head_data = contains(input_directory, 'data\head');
    
    % Create output directory if needed
    output_dir = fileparts(output_file);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Save combined file
    console_log('Saving combined head data: %s\n', output_file);
    save(output_file, '-struct', 'combined_data');
    
    % Summary
    console_log('✓ Head data processing completed\n');
    console_log('  Combined zones: %s\n', strjoin(zone_names, ', '));
    console_log('  Timestamp range: %s to %s (%.1f hours)\n', ...
        shared_date(1), shared_date(end), combined_data.processing_info.time_range.duration_hours);
    console_log('  Output file: %s\n', output_file);
    
    success = true;
    
catch ME
    console_log('✗ Head data processing failed: %s\n', ME.message);
    if length(ME.stack) > 0
        console_log('   Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    success = false;
end

end
