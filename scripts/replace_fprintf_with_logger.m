% Script to replace all fprintf calls with console_log in a file

target_file = 'C:\Coding\BGWRP\scripts\run_PT01a_thesis_analysis.m';

% Read the file
fid = fopen(target_file, 'r');
content = fread(fid, '*char')';
fclose(fid);

% Replace fprintf with console_log
% This regex finds fprintf( and replaces with console_log(
content = regexprep(content, 'fprintf\(', 'console_log(');

% Write back to file
fid = fopen(target_file, 'w');
fprintf(fid, '%s', content);
fclose(fid);

fprintf('Replaced all fprintf calls with console_log in: %s\n', target_file);
