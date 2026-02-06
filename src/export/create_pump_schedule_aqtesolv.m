% Create pump schedule for AQTESOLV (time starts at pump ON = 0)

output_file = 'E:/Transducer Data 10_24_2023/Cleaned/PT01a/Pump_Schedule_AQTESOLV.csv';

%% Pump schedule (time relative to pump start)
% Time = 0 at pump ON
time_sec = [
    0;      % Pump starts at 50 GPM
    3600;   % 1 hour: increase to 80 GPM
    7200;   % 2 hours: increase to 110 GPM
    10800;  % 3 hours: increase to 150 GPM
    14400   % 4 hours: pump OFF (recovery)
];

pump_rate_gpm = [
    50;
    80;
    110;
    150;
    0   % Pump off = 0 GPM
];

%% Create table
schedule_table = table(time_sec, pump_rate_gpm, ...
    'VariableNames', {'Time_sec', 'Pump_Rate_GPM'});

%% Export
writetable(schedule_table, output_file);

fprintf('=== PUMP SCHEDULE FOR AQTESOLV ===\n');
fprintf('Exported to: %s\n\n', output_file);
disp(schedule_table);

fprintf('\n✓ Time starts at t=0 (pump ON)\n');
fprintf('✓ Use this file in AQTESOLV for pump schedule\n');
