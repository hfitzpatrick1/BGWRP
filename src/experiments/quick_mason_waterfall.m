function quick_mason_waterfall()
    % QUICK_MASON_WATERFALL - Quick visualization of Mason's TDMS output
    %
    % Loads Mason's Out.mat file and displays it as a waterfall plot using
    % the same visualization parameters as the BGWRP toolkit
    %
    % Author: AI Assistant
    % Date: 2025-09-14
    
    console_log('=== Quick Mason TDMS Waterfall Visualization ===\n\n');
    
    %% Configuration - Hardcoded values from BGWRP config
    mason_file = 'C:\Coding\TDMS-Signal-Downsampler\TDMS Signal Downsampler\Output\Out.mat';
    
    % From your BGWRP config
    channel_min = 200;  % channels (corresponds to ~200 ft depth)
    channel_max = 665;  % channels (corresponds to ~665 ft depth)
    decimation_factor = 10;  % what you used in Mason's script
    
    % Calibration from PT01c config
    C1 = 140;           % First channel depth
    MperChan = 0.263;   % Meters per channel
    
    % Plot bounds from BGWRP manual bounds
    raw_bounds = [-2.000, 2.000];  % Based on Mason's data range we saw
    
    console_log('Loading Mason''s processed data...\n');
    console_log('File: %s\n', mason_file);
    
    %% Load Mason's data
    if ~exist(mason_file, 'file')
        error('Mason''s output file not found: %s', mason_file);
    end
    
    loaded = load(mason_file);
    
    % Check what variables are available
    vars = fieldnames(loaded);
    console_log('Available variables: %s\n', strjoin(vars, ', '));
    
    % Get the data (Mason's script saves as 'Data')
    if isfield(loaded, 'Data')
        data = loaded.Data;
        console_log('Loaded Data variable: [%d x %d]\n', size(data, 1), size(data, 2));
    else
        error('Data variable not found in Mason''s file');
    end
    
    %% Determine data orientation and extract relevant channels
    [nrows, ncols] = size(data);
    
    if nrows > ncols
        % Assume [time x channels] format like BGWRP
        time_samples = nrows;
        total_channels = ncols;
        console_log('Detected format: [time x channels] = [%d x %d]\n', time_samples, total_channels);
        
        % Extract channel range
        if total_channels >= channel_max
            channel_data = data(:, channel_min:channel_max);
            channels_used = channel_min:channel_max;
        else
            warning('Total channels (%d) less than max requested (%d), using all available', total_channels, channel_max);
            channel_data = data;
            channels_used = 1:total_channels;
        end
        
    else
        % Assume [channels x time] format - transpose needed
        time_samples = ncols;
        total_channels = nrows;
        console_log('Detected format: [channels x time] = [%d x %d], transposing...\n', total_channels, time_samples);
        
        data = data';  % Transpose to [time x channels]
        
        % Extract channel range
        if total_channels >= channel_max
            channel_data = data(:, channel_min:channel_max);
            channels_used = channel_min:channel_max;
        else
            warning('Total channels (%d) less than max requested (%d), using all available', total_channels, channel_max);
            channel_data = data;
            channels_used = 1:total_channels;
        end
    end
    
    console_log('Using data subset: [%d x %d] (time x channels)\n', size(channel_data, 1), size(channel_data, 2));
    console_log('Data range: [%.3f, %.3f]\n', min(channel_data(:)), max(channel_data(:)));
    
    %% Create depth axis (convert channels to depth in feet)
    depth_m = (channels_used - C1) * MperChan;  % Depth in meters
    depth_ft = depth_m * 3.28084;               % Convert to feet
    
    console_log('Depth range: [%.1f, %.1f] ft\n', min(depth_ft), max(depth_ft));
    
    %% Create time axis (assume 1 Hz sampling after decimation)
    sampling_rate = 1;  % Hz after decimation
    time_seconds = (0:size(channel_data, 1)-1) / sampling_rate;
    time_minutes = time_seconds / 60;
    
    console_log('Time range: [%.1f, %.1f] minutes\n', min(time_minutes), max(time_minutes));
    
    %% Create waterfall plot
    figure('Name', 'Mason TDMS Output - Waterfall', 'Position', [100, 100, 1200, 800]);
    
    % Use pcolor for smooth visualization (same as BGWRP)
    pcolor(time_minutes, depth_ft, channel_data');
    shading interp;  % Smooth shading
    
    % Apply colormap and bounds
    colormap jet;
    if ~isempty(raw_bounds)
        caxis(raw_bounds);
    end
    
    % Labels and formatting
    xlabel('Time (minutes)', 'FontSize', 12);
    ylabel('Depth (ft)', 'FontSize', 12);
    title(sprintf('Mason TDMS Processing Output\\nChannels %d-%d, Decimation Factor %d', ...
          channel_min, channel_max, decimation_factor), 'FontSize', 14);
    
    % Add colorbar
    cb = colorbar;
    cb.Label.String = 'Strain Rate (nm/s)';
    cb.Label.FontSize = 12;
    
    % Set axis directions (depth increases downward)
    set(gca, 'YDir', 'reverse');
    
    % Grid for readability
    grid on;
    set(gca, 'GridAlpha', 0.3);
    
    % Add text annotation with processing info
    annotation('textbox', [0.02, 0.02, 0.3, 0.15], ...
               'String', sprintf('Processing Info:\\nDecimation: %dx\\nChannels: %d-%d\\nSampling: %.1f Hz', ...
                               decimation_factor, channel_min, channel_max, sampling_rate), ...
               'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    console_log('\n✓ Waterfall plot generated successfully!\n');
    console_log('Figure window should be displayed.\n');
    
end
