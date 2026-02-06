% Find which points give 1.3 nm/s amplitude

if ~exist('das_results', 'var')
    console_log('ERROR: das_results not in workspace\n');
    return
end

test_name = 'PT01c_Recovery_short';
if ~isfield(das_results, test_name)
    test_names = fieldnames(das_results);
    test_names = test_names(~strcmp(test_names, 'tests') & ~strcmp(test_names, 'timing'));
    if ~isempty(test_names)
        test_name = test_names{1};
    end
end

% Get displacement rate data
if isfield(das_results.(test_name), 'smoothed_data')
    disp_data = das_results.(test_name).smoothed_data;  % [time x channels]
    time_data = das_results.(test_name).time_array;
    depth_ft = das_results.(test_name).depth_ft;
    
    % Find channels around 285 ft (from plot title)
    target_depth = 285;
    depth_tolerance = 5;  % Check channels within ±5 ft of 285
    channels_near_target = find(abs(depth_ft - target_depth) <= depth_tolerance);
    
    console_log('Channels near %.0f ft (within ±%.0f ft):\n', target_depth, depth_tolerance);
    for i = 1:length(channels_near_target)
        ch = channels_near_target(i);
        console_log('  Channel %d: %.2f ft (%.2f ft from target)\n', ch, depth_ft(ch), abs(depth_ft(ch) - target_depth));
    end
    console_log('\nData size: [%d time x %d channels]\n\n', size(disp_data, 1), size(disp_data, 2));
    
    % Use closest channel for initial check
    [~, ch_idx] = min(abs(depth_ft - target_depth));
    console_log('Using closest channel: %d at %.2f ft\n\n', ch_idx, depth_ft(ch_idx));
    
    % Get displacement rate at this channel
    disp_at_ch = disp_data(:, ch_idx);  % nm/s
    
    % Find time window: 19:14:45 to 19:15:25 (from user)
    % Match timezone of time_data
    if isempty(time_data)
        console_log('No time data\n');
        return
    end
    % Create time window matching time_data format
    if isdatetime(time_data(1)) && ~isempty(time_data(1).TimeZone)
        time_start = datetime(2023, 10, 24, 19, 14, 45, 'TimeZone', time_data(1).TimeZone);
        time_end = datetime(2023, 10, 24, 19, 15, 25, 'TimeZone', time_data(1).TimeZone);
    else
        time_start = datetime(2023, 10, 24, 19, 14, 45);
        time_end = datetime(2023, 10, 24, 19, 15, 25);
    end
    time_mask = time_data >= time_start & time_data <= time_end;
    
    if sum(time_mask) > 0
        disp_window = disp_at_ch(time_mask);
        time_window = time_data(time_mask);
        
        console_log('Time window: %s to %s\n', datestr(min(time_window)), datestr(max(time_window)));
        console_log('Displacement range: [%.4f, %.4f] nm/s\n', min(disp_window), max(disp_window));
        console_log('Amplitude (max - min): %.4f nm/s\n\n', max(disp_window) - min(disp_window));
        
        % Check the specific time window first
        console_log('=== CHECKING SPECIFIC TIME WINDOW ===\n');
        console_log('Window: 19:14:45 to 19:15:25\n');
        amp = max(disp_window) - min(disp_window);
        console_log('Amplitude: %.4f nm/s (target: 1.3 nm/s)\n', amp);
        if abs(amp - 1.3) < 0.1
            console_log('  *** CLOSE TO 1.3 nm/s! ***\n');
        end
        
        % Check different time windows around this range
        console_log('\n=== CHECKING DIFFERENT TIME WINDOWS ===\n');
        center_time = time_start + (time_end - time_start)/2;
        windows = {seconds(20), seconds(30), seconds(40), minutes(1)};
        for i = 1:length(windows)
            win = windows{i};
            win_start = center_time - win;
            win_end = center_time + win;
            mask = time_data >= win_start & time_data <= win_end;
            if sum(mask) > 0
                amp = max(disp_at_ch(mask)) - min(disp_at_ch(mask));
                console_log('Window ±%s: amplitude = %.4f nm/s\n', char(win), amp);
                if abs(amp - 1.3) < 0.1
                    console_log('  *** CLOSE TO 1.3 nm/s! ***\n');
                end
            end
        end
        
        % Check all channels near 285 ft first (using the specific time window)
        console_log('\n=== CHECKING ALL CHANNELS NEAR 285 FT (19:14:45 to 19:15:25) ===\n');
        best_amp = 0;
        best_ch = 0;
        for ch = channels_near_target'
            disp_ch = disp_data(time_mask, ch);
            if ~all(isnan(disp_ch(:))) && ~isempty(disp_ch)
                amp = max(disp_ch) - min(disp_ch);
                console_log('Channel %d at %.2f ft: amplitude = %.4f nm/s', ch, depth_ft(ch), amp);
                if abs(amp - 1.3) < 0.1
                    console_log('  *** CLOSE TO 1.3 nm/s! ***');
                end
                console_log('\n');
                if abs(amp - 1.3) < abs(best_amp - 1.3)
                    best_amp = amp;
                    best_ch = ch;
                end
            end
        end
        if best_ch > 0
            console_log('\n*** BEST MATCH: Channel %d at %.2f ft, amplitude = %.4f nm/s ***\n', best_ch, depth_ft(best_ch), best_amp);
        end
        
        % Also check other depths
        console_log('\n=== CHECKING OTHER DEPTHS (19:14:45 to 19:15:25) ===\n');
        depths_to_check = [270, 275, 280, 290, 295, 300];
        for d = depths_to_check
            [~, ch] = min(abs(depth_ft - d));
            disp_ch = disp_data(time_mask, ch);
            if ~all(isnan(disp_ch(:))) && ~isempty(disp_ch)
                amp = max(disp_ch) - min(disp_ch);
                console_log('Depth %.0f ft (ch %d at %.2f ft): amplitude = %.4f nm/s\n', d, ch, depth_ft(ch), amp);
                if abs(amp - 1.3) < 0.1
                    console_log('  *** CLOSE TO 1.3 nm/s! ***\n');
                end
            end
        end
        
    else
        console_log('No data in time window around 19:15\n');
    end
    
else
    console_log('No smoothed_data found\n');
end

