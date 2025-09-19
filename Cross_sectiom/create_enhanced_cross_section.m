function create_enhanced_cross_section()
%CREATE_ENHANCED_CROSS_SECTION Creates an enhanced cross section with geological layers
%
% This function creates a more detailed geological cross section showing
% the well construction details and estimated geological layers between
% PM-07 and PT-01c wells.

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
well_distance = 100; % feet (placeholder - update with actual distance)

% Create figure
figure('Name', 'Enhanced Cross Section: PM-07 to PT-01c', 'Position', [50, 50, 1400, 900]);

%% Define Geological Layers (estimated based on typical groundwater geology)
% These are estimated layers - adjust based on actual geological data
geology_layers = [
    0, 50, 'Topsoil/Sand';           % Surface layer
    50, 150, 'Clay/Silt';            % Confining layer
    150, 300, 'Sand/Gravel';         % Aquifer
    300, 450, 'Clay';                % Confining layer
    450, 600, 'Sandstone';           % Deeper aquifer
    600, 665, 'Bedrock'              % Bedrock
];

%% Plot Geological Layers
plot_geological_layers(geology_layers, well_distance);

%% Plot Wells
% PM-07 (left side)
x_pm07 = 0;
x_pt01c = well_distance;

% Plot PM-07 well
plot_enhanced_well(x_pm07, PM07, 'PM-07', 'left');

% Plot PT-01c well
plot_enhanced_well(x_pt01c, PT01c, 'PT-01c', 'right');

%% Add Cross Section Details
% Set axis properties
xlim([-30, well_distance + 30]);
ylim([0, 700]);
set(gca, 'YDir', 'reverse'); % Depth increases downward
xlabel('Distance (ft)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title('Enhanced Cross Section: PM-07 to PT-01c Wells', 'FontSize', 16, 'FontWeight', 'bold');

% Add grid
grid on;
grid minor;
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);

% Add well labels
text(x_pm07, -40, 'PM-07', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);
text(x_pt01c, -40, 'PT-01c', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);

% Add depth markers
depth_markers = [100, 200, 300, 400, 500, 600];
for i = 1:length(depth_markers)
    yline(depth_markers(i), '--', 'Color', [0.6, 0.6, 0.6], 'Alpha', 0.7, 'LineWidth', 1);
    text(-25, depth_markers(i), sprintf('%d ft', depth_markers(i)), ...
         'HorizontalAlignment', 'right', 'Color', [0.4, 0.4, 0.4], 'FontSize', 10);
end

% Add distance markers
x_markers = [0, 25, 50, 75, 100];
for i = 1:length(x_markers)
    xline(x_markers(i), ':', 'Color', [0.6, 0.6, 0.6], 'Alpha', 0.5);
    text(x_markers(i), -20, sprintf('%d ft', x_markers(i)), ...
         'HorizontalAlignment', 'center', 'Color', [0.4, 0.4, 0.4], 'FontSize', 9);
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
    '';
    'Note: Geological layers are estimated';
    'Update with actual geological data';
};

text(well_distance/2, 50, summary_text, 'FontSize', 10, ...
     'BackgroundColor', 'white', 'EdgeColor', 'black', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'center');

% Add legend
legend_items = {'Casing', 'Screen', 'Geological Layers'};
legend(legend_items, 'Location', 'northeast', 'FontSize', 11);

fprintf('Enhanced cross section created successfully!\n');
fprintf('PM-07: Casing 0-%d ft, Screen %d-%d ft\n', PM07.bottom_casing, PM07.top_screen, PM07.bottom_screen);
fprintf('PT-01c: Casing 0-%d ft, Screen %d-%d ft\n', PT01c.bottom_casing, PT01c.top_screen, PT01c.bottom_screen);

end

function plot_geological_layers(layers, well_distance)
%PLOT_GEOLOGICAL_LAYERS Plots geological layers between wells

% Define colors for different geological units
colors = [
    0.8, 0.6, 0.4;  % Topsoil/Sand - tan
    0.6, 0.5, 0.4;  % Clay/Silt - brown
    0.9, 0.8, 0.6;  % Sand/Gravel - light tan
    0.5, 0.4, 0.3;  % Clay - dark brown
    0.7, 0.7, 0.6;  % Sandstone - gray-tan
    0.4, 0.4, 0.4   % Bedrock - dark gray
];

for i = 1:size(layers, 1)
    top_depth = layers(i, 1);
    bottom_depth = layers(i, 2);
    layer_name = layers(i, 3);
    
    % Create layer polygon
    x_coords = [0, well_distance, well_distance, 0, 0];
    y_coords = [top_depth, top_depth, bottom_depth, bottom_depth, top_depth];
    
    % Fill the layer
    fill(x_coords, y_coords, colors(i, :), 'EdgeColor', 'black', ...
         'LineWidth', 0.5, 'FaceAlpha', 0.7);
    
    % Add layer label
    text(well_distance/2, (top_depth + bottom_depth)/2, layer_name, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
end

end

function plot_enhanced_well(x_position, well_data, well_name, side)
%PLOT_ENHANCED_WELL Plots a single well with enhanced visualization

% Well width for visualization
well_width = 4;

% Plot casing (solid line with gradient effect)
casing_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
casing_y = [well_data.top_casing, well_data.top_casing, ...
            well_data.bottom_casing, well_data.bottom_casing, ...
            well_data.top_casing];

fill(casing_x, casing_y, [0.7, 0.7, 0.7], 'EdgeColor', 'black', 'LineWidth', 2);

% Plot screen (dashed line with blue fill)
screen_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
screen_y = [well_data.top_screen, well_data.top_screen, ...
            well_data.bottom_screen, well_data.bottom_screen, ...
            well_data.top_screen];

fill(screen_x, screen_y, [0.3, 0.6, 1.0], 'EdgeColor', 'blue', 'LineWidth', 2.5, ...
     'LineStyle', '--', 'FaceAlpha', 0.6);

% Add well center line
plot([x_position, x_position], [well_data.top_casing, well_data.bottom_casing], ...
     'k-', 'LineWidth', 2);

% Add depth labels with better formatting
if strcmp(side, 'left')
    text(x_position - well_width/2 - 8, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    text(x_position - well_width/2 - 8, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    if well_data.top_screen ~= well_data.bottom_screen
        text(x_position - well_width/2 - 8, well_data.top_screen, ...
             sprintf('%d ft', well_data.top_screen), ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
             'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    end
else
    text(x_position + well_width/2 + 8, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    text(x_position + well_width/2 + 8, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    if well_data.top_screen ~= well_data.bottom_screen
        text(x_position + well_width/2 + 8, well_data.top_screen, ...
             sprintf('%d ft', well_data.top_screen), ...
             'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
             'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    end
end

end


