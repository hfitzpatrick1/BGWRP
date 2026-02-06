function export_pump_schedule_elapsed(csv_file, pump_start_time, output_csv)
%EXPORT_PUMP_SCHEDULE_ELAPSED Export pump schedule with correct elapsed times
%
% Usage:
%   export_pump_schedule_elapsed(csv_file, pump_start_time, output_csv)
%
% Calculates elapsed time from file start, not pump start

% Load just the first timestamp from the file
fid = fopen(csv_file, 'r');
line_count = 0;
while ~feof(fid)
    line = fgetl(fid);
    line_count = line_count + 1;
    if contains(line, 'Date Time') && contains(line, 'Depth')
        break;
    end
end
fclose(fid);

opts = detectImportOptions(csv_file);
opts.DataLines = [line_count+1, line_count+1];
opts.VariableNames = {'DateTime', 'Pressure_psi', 'Temperature_C', 'Depth_ft'};
first_row = readtable(csv_file, opts);

timestamps_local = datetime(first_row.DateTime, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
timestamps_local.TimeZone = 'America/Los_Angeles';
file_start = timestamps_local;
file_start.TimeZone = 'UTC';

% Calculate pump start in elapsed time from file start
pump_start_elapsed = seconds(pump_start_time - file_start);

% Define pump schedule relative to pump start
pump_times_elapsed = pump_start_elapsed + [0; 3600; 7200; 10800; 14400];
pump_rates = [50; 80; 110; 150; 0];

event_names = {
    'Pump Start - 50 GPM';
    'Rate Change - 80 GPM';
    'Rate Change - 110 GPM';
    'Rate Change - 150 GPM';
    'Pump OFF - Recovery';
};

% Create table
schedule_table = table(pump_times_elapsed, pump_rates, event_names, ...
    'VariableNames', {'Time_sec', 'Rate_GPM', 'Event'});

% Write to CSV
writetable(schedule_table, output_csv);

fprintf('\n=== PUMP SCHEDULE (Elapsed Time from File Start) ===\n');
fprintf('File starts at: %s UTC\n', datestr(file_start));
fprintf('Pump starts at: %s UTC (%.1f sec elapsed)\n\n', datestr(pump_start_time), pump_start_elapsed);
fprintf('Exported to: %s\n\n', output_csv);
fprintf('Time (sec)  Time (hr:min)  Rate (GPM)  Event\n');
fprintf('-----------------------------------------------------------\n');
for i = 1:length(pump_times_elapsed)
    hours = floor(pump_times_elapsed(i) / 3600);
    mins = floor(mod(pump_times_elapsed(i), 3600) / 60);
    fprintf('%10.1f  %02d:%02d          %3d         %s\n', ...
        pump_times_elapsed(i), hours, mins, pump_rates(i), event_names{i});
end
fprintf('\nSchedule saved!\n');

end
