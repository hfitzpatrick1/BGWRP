%% Run Cross Section: PM-07 to PT-01c
% This script creates and displays a cross section between PM-07 and PT-01c wells
% based on the well construction data provided.

clear; clc; close all;

% Add current directory to path
addpath(pwd);

fprintf('Creating cross section from PM-07 to PT-01c...\n');

% Run the cross section creation function
create_cross_section_PM07_PT01c();

fprintf('Cross section complete!\n');
fprintf('Figure saved as: Cross Section PM-07 to PT-01c\n');


