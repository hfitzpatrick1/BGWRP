function create_cross_section_PM07_PT01c()
%CREATE_CROSS_SECTION_PM07_PT01C Creates a cross section from PM-07 to PT-01c
%
% This function creates a geological cross section showing the well
% construction details for PM-07 and PT-01c wells based on the provided
% well construction data.
%
% Well Construction Data:
% PM-07: Top of casing: 0 ft, Bottom of Casing: 665 ft, 
%        Top of Screen: 645 ft, Bottom of Screen: 665 ft, Casing diameter: 2.5 inches
% PT-01c: Top of casing: 0 ft, Bottom of Casing: 310 ft,
%         Top of Screen: 260 ft, Bottom of Screen: 310 ft, Casing diameter: 6 inches

%% Well Construction Data
% PM-07 well data
PM07.top_casing = 0;        % ft
PM07.bottom_casing = 665;   % ft
PM07.top_screen = 645;      % ft
PM07.bottom_screen = 665;   % ft
PM07.casing_diameter = 2.5; % inches

% PT-01c well data
PT01c.top_casing = 0;       % ft
PT01c.bottom_casing = 310;  % ft
PT01c.top_screen = 260;     % ft
PT01c.bottom_screen = 310;  % ft
PT01c.casing_diameter = 6;  % inches

%% Cross Section Parameters
% Distance between wells (estimated - you may need to adjust based on actual coordinates)
well_distance = 100; % feet (placeholder - update with actual distance)

% Create figure
figure('Name', 'Cross Section: PM-07 to PT-01c', 'Position', [100, 100, 1200, 800]);

%% Plot Wells
% PM-07 (left side)
x_pm07 = 0;
x_pt01c = well_distance;

% Plot PM-07 well
plot_well(x_pm07, PM07, 'PM-07', 'left');

% Plot PT-01c well
plot_well(x_pt01c, PT01c, 'PT-01c', 'right');

%% Add Cross Section Details
% Set axis properties
xlim([-20, well_distance + 20]);
ylim([0, 700]);
set(gca, 'YDir', 'reverse'); % Depth increases downward
xlabel('Distance (ft)');
ylabel('Depth (ft)');
title('Cross Section: PM-07 to PT-01c Wells', 'FontSize', 14, 'FontWeight', 'bold');

% Add grid
grid on;
grid minor;

% Add legend
legend('Casing', 'Screen', 'Location', 'northeast');

% Add annotations
text(x_pm07, -30, 'PM-07', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(x_pt01c, -30, 'PT-01c', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Add depth markers
depth_markers = [100, 200, 300, 400, 500, 600];
for i = 1:length(depth_markers)
    yline(depth_markers(i), '--', 'Color', [0.7, 0.7, 0.7], 'Alpha', 0.5);
    text(-15, depth_markers(i), sprintf('%d ft', depth_markers(i)), ...
         'HorizontalAlignment', 'right', 'Color', [0.5, 0.5, 0.5]);
end

% Add well construction summary
summary_text = {
    'Well Construction Summary:';
    '';
    'PM-07:';
    sprintf('  Casing: 0 - %d ft (%.1f" diameter)', PM07.bottom_casing, PM07.casing_diameter);
    sprintf('  Screen: %d - %d ft', PM07.top_screen, PM07.bottom_screen);
    '';
    'PT-01c:';
    sprintf('  Casing: 0 - %d ft (%.1f" diameter)', PT01c.bottom_casing, PT01c.casing_diameter);
    sprintf('  Screen: %d - %d ft', PT01c.top_screen, PT01c.bottom_screen);
};

text(well_distance/2, 50, summary_text, 'FontSize', 10, ...
     'BackgroundColor', 'white', 'EdgeColor', 'black', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'center');

fprintf('Cross section created successfully!\n');
fprintf('PM-07: Casing 0-%d ft, Screen %d-%d ft\n', PM07.bottom_casing, PM07.top_screen, PM07.bottom_screen);
fprintf('PT-01c: Casing 0-%d ft, Screen %d-%d ft\n', PT01c.bottom_casing, PT01c.top_screen, PT01c.bottom_screen);

end

function plot_well(x_position, well_data, well_name, side)
%PLOT_WELL Plots a single well on the cross section
%
% Inputs:
%   x_position - X coordinate for the well
%   well_data - Structure containing well construction data
%   well_name - Name of the well
%   side - 'left' or 'right' for text positioning

% Well width for visualization
well_width = 3;

% Plot casing (solid line)
casing_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
casing_y = [well_data.top_casing, well_data.top_casing, ...
            well_data.bottom_casing, well_data.bottom_casing, ...
            well_data.top_casing];

fill(casing_x, casing_y, [0.8, 0.8, 0.8], 'EdgeColor', 'black', 'LineWidth', 1.5);

% Plot screen (dashed line)
screen_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
screen_y = [well_data.top_screen, well_data.top_screen, ...
            well_data.bottom_screen, well_data.bottom_screen, ...
            well_data.top_screen];

fill(screen_x, screen_y, [0.6, 0.8, 1.0], 'EdgeColor', 'blue', 'LineWidth', 2, ...
     'LineStyle', '--', 'FaceAlpha', 0.3);

% Add well center line
plot([x_position, x_position], [well_data.top_casing, well_data.bottom_casing], ...
     'k-', 'LineWidth', 1);

% Add depth labels
if strcmp(side, 'left')
    text(x_position - well_width/2 - 5, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    text(x_position - well_width/2 - 5, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    if well_data.top_screen ~= well_data.bottom_screen
        text(x_position - well_width/2 - 5, well_data.top_screen, ...
             sprintf('%d ft', well_data.top_screen), ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    end
else
    text(x_position + well_width/2 + 5, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    text(x_position + well_width/2 + 5, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    if well_data.top_screen ~= well_data.bottom_screen
        text(x_position + well_width/2 + 5, well_data.top_screen, ...
             sprintf('%d ft', well_data.top_screen), ...
             'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    end
end

end


