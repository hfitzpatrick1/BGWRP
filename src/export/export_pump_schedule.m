function export_pump_schedule(pump_start_time, output_csv)
%EXPORT_PUMP_SCHEDULE Export pump schedule with elapsed time in seconds
%
% Usage:
%   export_pump_schedule(pump_start_time, output_csv)
%
% Creates CSV with: Time_sec, Rate_GPM, Event

% Define pump schedule (1 hour intervals)
pump_times_relative = [
    0;          % Start - 50 GPM
    3600;       % 1 hour - 80 GPM
    7200;       % 2 hours - 110 GPM
    10800;      % 3 hours - 150 GPM
    14400;      % 4 hours - OFF
];

pump_rates = [50; 80; 110; 150; 0];

event_names = {
    'Pump Start - 50 GPM';
    'Rate Change - 80 GPM';
    'Rate Change - 110 GPM';
    'Rate Change - 150 GPM';
    'Pump OFF - Recovery';
};

% Create table
schedule_table = table(pump_times_relative, pump_rates, event_names, ...
    'VariableNames', {'Time_sec', 'Rate_GPM', 'Event'});

% Write to CSV
writetable(schedule_table, output_csv);

fprintf('\n=== PUMP SCHEDULE ===\n');
fprintf('Exported to: %s\n\n', output_csv);
fprintf('Time (sec)  Time (hr:min)  Rate (GPM)  Event\n');
fprintf('-----------------------------------------------------------\n');
for i = 1:length(pump_times_relative)
    hours = floor(pump_times_relative(i) / 3600);
    mins = floor(mod(pump_times_relative(i), 3600) / 60);
    fprintf('%10d  %02d:%02d          %3d         %s\n', ...
        pump_times_relative(i), hours, mins, pump_rates(i), event_names{i});
end
fprintf('\nSchedule complete!\n');

end
