%% Run Accurate Cross Section: PM-07 to PT-01c (As-Built Data)
% This script creates and displays an accurate cross section between PM-07 and PT-01c wells
% using the actual as-built construction data for PT-01c.

clear; clc; close all;

% Add current directory to path
addpath(pwd);

fprintf('Creating accurate cross section from PM-07 to PT-01c using as-built data...\n');

% Run the accurate cross section creation function
create_accurate_cross_section();

fprintf('Accurate cross section complete!\n');
fprintf('Figure shows actual PT-01c construction details:\n');
fprintf('  - 6-inch PVC casing with 0.050-inch slot screen\n');
fprintf('  - Cement-bentonite grout, bentonite seal, filter pack\n');
fprintf('  - Detailed borehole reaming information\n');
fprintf('  - Sump construction details\n');


