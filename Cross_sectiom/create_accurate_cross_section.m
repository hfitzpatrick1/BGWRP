function create_accurate_cross_section()
%CREATE_ACCURATE_CROSS_SECTION Creates an accurate cross section with actual as-built data
%
% This function creates a detailed geological cross section showing
% the actual well construction details for PM-07 and PT-01c wells
% based on as-built construction data.

%% Well Construction Data (As-Built)
% PM-07 well data (from previous analysis)
PM07.top_casing = 0;        % ft
PM07.bottom_casing = 665;   % ft
PM07.top_screen = 645;      % ft
PM07.bottom_screen = 665;   % ft
PM07.casing_diameter = 2.5; % inches

% PT-01c well data (AS-BUILT from construction diagram)
PT01c.top_casing = 0;       % ft
PT01c.bottom_casing = 320;  % ft (total well depth)
PT01c.top_screen = 260;     % ft
PT01c.bottom_screen = 310;  % ft
PT01c.casing_diameter = 6;  % inches (6-inch PVC)
PT01c.screen_slot_size = 0.050; % inches
PT01c.sump_depth = 310;     % ft (sump starts at screen bottom)
PT01c.sump_bottom = 320;    % ft (sump extends to well bottom)

% PT-01c Construction Materials (from as-built)
PT01c.cement_bentonite_grout_top = 0;     % ft
PT01c.cement_bentonite_grout_bottom = 240; % ft
PT01c.bentonite_seal_top = 240;           % ft
PT01c.bentonite_seal_bottom = 250;        % ft
PT01c.filter_pack_top = 250;              % ft
PT01c.filter_pack_bottom = 320;           % ft

% Borehole reaming information
PT01c.borehole_22inch_top = 0;    % ft
PT01c.borehole_22inch_bottom = 20; % ft
PT01c.borehole_14_75inch_top = 20; % ft
PT01c.borehole_14_75inch_bottom = 320; % ft

%% Cross Section Parameters
well_distance = 177; % feet (PM-07 is 177 ft NW of PT-01c)

% Create figure
figure('Name', 'Accurate Cross Section: PM-07 to PT-01c (As-Built)', 'Position', [50, 50, 1600, 1000]);

%% Define Geological Layers (estimated based on typical groundwater geology)
geology_layers = {
    0, 50, 'Topsoil/Sand';           % Surface layer
    50, 150, 'Clay/Silt';            % Confining layer
    150, 300, 'Sand/Gravel';         % Aquifer
    300, 450, 'Clay';                % Confining layer
    450, 600, 'Sandstone';           % Deeper aquifer
    600, 665, 'Bedrock'              % Bedrock
};

%% Plot Geological Layers
plot_geological_layers(geology_layers, well_distance);

%% Plot Wells
% PM-07 (left side)
x_pm07 = 0;
x_pt01c = well_distance;

% Plot PM-07 well (simplified) - make it more visible
plot_enhanced_well(x_pm07, PM07, 'PM-07', 'left');

% Plot PT-01c well with detailed construction
plot_detailed_pt01c_well(x_pt01c, PT01c, 'PT-01c', 'right');

%% Add Cross Section Details
% Set axis properties
xlim([-50, well_distance + 50]);
ylim([0, 700]);
set(gca, 'YDir', 'reverse'); % Depth increases downward
xlabel('Distance (ft)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title('Accurate Cross Section: PM-07 to PT-01c Wells (As-Built Data)', 'FontSize', 16, 'FontWeight', 'bold');

% Add grid
grid on;
grid minor;
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);

% Add well labels
text(x_pm07, -50, 'PM-07', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);
text(x_pt01c, -50, 'PT-01c', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);

% Add depth markers
depth_markers = [100, 200, 300, 400, 500, 600];
for i = 1:length(depth_markers)
    yline(depth_markers(i), '--', 'Color', [0.6, 0.6, 0.6], 'Alpha', 0.7, 'LineWidth', 1);
    text(-35, depth_markers(i), sprintf('%d ft', depth_markers(i)), ...
         'HorizontalAlignment', 'right', 'Color', [0.4, 0.4, 0.4], 'FontSize', 10);
end

% Add distance markers
x_markers = [0, 44, 89, 133, 177];
for i = 1:length(x_markers)
    xline(x_markers(i), ':', 'Color', [0.6, 0.6, 0.6], 'Alpha', 0.5);
    text(x_markers(i), -30, sprintf('%d ft', x_markers(i)), ...
         'HorizontalAlignment', 'center', 'Color', [0.4, 0.4, 0.4], 'FontSize', 9);
end

% Add detailed construction summary
summary_text = {
    'Well Construction Summary (As-Built):';
    '';
    'PM-07:';
    sprintf('  Casing: 0 - %d ft (%.1f" diameter)', PM07.bottom_casing, PM07.casing_diameter);
    sprintf('  Screen: %d - %d ft', PM07.top_screen, PM07.bottom_screen);
    '';
    'PT-01c (As-Built):';
    sprintf('  Total Depth: %d ft', PT01c.bottom_casing);
    sprintf('  6" PVC Casing: 0 - %d ft', PT01c.bottom_casing);
    sprintf('  Screen: %d - %d ft (0.050" slots)', PT01c.top_screen, PT01c.bottom_screen);
    sprintf('  Sump: %d - %d ft', PT01c.sump_depth, PT01c.sump_bottom);
    sprintf('  Cement-Bentonite Grout: 0 - %d ft', PT01c.cement_bentonite_grout_bottom);
    sprintf('  Bentonite Seal: %d - %d ft', PT01c.bentonite_seal_top, PT01c.bentonite_seal_bottom);
    sprintf('  Filter Pack: %d - %d ft', PT01c.filter_pack_top, PT01c.filter_pack_bottom);
    '';
    'Borehole Reaming:';
    sprintf('  22" diameter: 0 - %d ft', PT01c.borehole_22inch_bottom);
    sprintf('  14.75" diameter: %d - %d ft', PT01c.borehole_14_75inch_top, PT01c.borehole_14_75inch_bottom);
};

text(well_distance/2, 50, summary_text, 'FontSize', 9, ...
     'BackgroundColor', 'white', 'EdgeColor', 'black', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'center');

% Add legend
legend_items = {'PM-07 Casing', 'PM-07 Screen', 'PT-01c Casing', 'PT-01c Screen', ...
                'PT-01c Sump', 'Cement-Bentonite Grout', 'Bentonite Seal', 'Filter Pack', ...
                '22" Borehole', '14.75" Borehole'};
legend(legend_items, 'Location', 'northeast', 'FontSize', 9);

fprintf('Accurate cross section created successfully!\n');
fprintf('PM-07: Casing 0-%d ft, Screen %d-%d ft\n', PM07.bottom_casing, PM07.top_screen, PM07.bottom_screen);
fprintf('PT-01c: Total depth %d ft, Screen %d-%d ft, Sump %d-%d ft\n', ...
        PT01c.bottom_casing, PT01c.top_screen, PT01c.bottom_screen, PT01c.sump_depth, PT01c.sump_bottom);

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

for i = 1:length(layers)
    top_depth = layers{i, 1};
    bottom_depth = layers{i, 2};
    layer_name = layers{i, 3};
    
    % Create layer polygon
    x_coords = [0, well_distance, well_distance, 0, 0];
    y_coords = [top_depth, top_depth, bottom_depth, bottom_depth, top_depth];
    
    % Fill the layer
    fill(x_coords, y_coords, colors(i, :), 'EdgeColor', 'black', ...
         'LineWidth', 0.5, 'FaceAlpha', 0.6);
    
    % Add layer label
    text(well_distance/2, (top_depth + bottom_depth)/2, layer_name, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
end

end

function plot_enhanced_well(x_position, well_data, well_name, side)
%PLOT_ENHANCED_WELL Plots PM-07 well with enhanced visualization

% Well width for visualization - make it larger and more visible
well_width = 6;

% Plot casing (solid line with gradient effect)
casing_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
casing_y = [well_data.top_casing, well_data.top_casing, ...
            well_data.bottom_casing, well_data.bottom_casing, ...
            well_data.top_casing];

fill(casing_x, casing_y, [0.8, 0.8, 0.8], 'EdgeColor', 'black', 'LineWidth', 3);

% Plot screen (dashed line with blue fill)
screen_x = [x_position - well_width/2, x_position + well_width/2, ...
            x_position + well_width/2, x_position - well_width/2, ...
            x_position - well_width/2];
screen_y = [well_data.top_screen, well_data.top_screen, ...
            well_data.bottom_screen, well_data.bottom_screen, ...
            well_data.top_screen];

fill(screen_x, screen_y, [0.3, 0.6, 1.0], 'EdgeColor', 'blue', 'LineWidth', 3, ...
     'LineStyle', '--', 'FaceAlpha', 0.7);

% Add well center line - make it very visible
plot([x_position, x_position], [well_data.top_casing, well_data.bottom_casing], ...
     'k-', 'LineWidth', 4);

% Add depth labels
if strcmp(side, 'left')
    text(x_position - well_width/2 - 12, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
         'FontSize', 11, 'FontWeight', 'bold');
    text(x_position - well_width/2 - 12, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
         'FontSize', 11, 'FontWeight', 'bold');
    if well_data.top_screen ~= well_data.bottom_screen
        text(x_position - well_width/2 - 12, well_data.top_screen, ...
             sprintf('%d ft', well_data.top_screen), ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
             'FontSize', 11, 'FontWeight', 'bold', 'Color', 'blue');
    end
end

end

function plot_detailed_pt01c_well(x_position, well_data, well_name, side)
%PLOT_DETAILED_PT01C_WELL Plots PT-01c well with detailed as-built construction

% Well width for visualization
well_width = 8;

% Plot 22-inch borehole (0-20 ft)
borehole_22_x = [x_position - well_width, x_position + well_width, ...
                 x_position + well_width, x_position - well_width, ...
                 x_position - well_width];
borehole_22_y = [well_data.borehole_22inch_top, well_data.borehole_22inch_top, ...
                 well_data.borehole_22inch_bottom, well_data.borehole_22inch_bottom, ...
                 well_data.borehole_22inch_top];

fill(borehole_22_x, borehole_22_y, [0.9, 0.9, 0.9], 'EdgeColor', 'black', 'LineWidth', 1, 'FaceAlpha', 0.3);

% Plot 14.75-inch borehole (20-320 ft)
borehole_14_75_x = [x_position - well_width*0.7, x_position + well_width*0.7, ...
                    x_position + well_width*0.7, x_position - well_width*0.7, ...
                    x_position - well_width*0.7];
borehole_14_75_y = [well_data.borehole_14_75inch_top, well_data.borehole_14_75inch_top, ...
                    well_data.borehole_14_75inch_bottom, well_data.borehole_14_75inch_bottom, ...
                    well_data.borehole_14_75inch_top];

fill(borehole_14_75_x, borehole_14_75_y, [0.9, 0.9, 0.9], 'EdgeColor', 'black', 'LineWidth', 1, 'FaceAlpha', 0.3);

% Plot cement-bentonite grout (0-240 ft)
grout_x = [x_position - well_width*0.6, x_position + well_width*0.6, ...
           x_position + well_width*0.6, x_position - well_width*0.6, ...
           x_position - well_width*0.6];
grout_y = [well_data.cement_bentonite_grout_top, well_data.cement_bentonite_grout_top, ...
           well_data.cement_bentonite_grout_bottom, well_data.cement_bentonite_grout_bottom, ...
           well_data.cement_bentonite_grout_top];

fill(grout_x, grout_y, [0.8, 0.8, 0.6], 'EdgeColor', 'black', 'LineWidth', 1, 'FaceAlpha', 0.8);

% Plot bentonite seal (240-250 ft)
seal_x = [x_position - well_width*0.6, x_position + well_width*0.6, ...
          x_position + well_width*0.6, x_position - well_width*0.6, ...
          x_position - well_width*0.6];
seal_y = [well_data.bentonite_seal_top, well_data.bentonite_seal_top, ...
          well_data.bentonite_seal_bottom, well_data.bentonite_seal_bottom, ...
          well_data.bentonite_seal_top];

fill(seal_x, seal_y, [0.6, 0.4, 0.2], 'EdgeColor', 'black', 'LineWidth', 1, 'FaceAlpha', 0.9);

% Plot filter pack (250-320 ft)
filter_x = [x_position - well_width*0.6, x_position + well_width*0.6, ...
            x_position + well_width*0.6, x_position - well_width*0.6, ...
            x_position - well_width*0.6];
filter_y = [well_data.filter_pack_top, well_data.filter_pack_top, ...
            well_data.filter_pack_bottom, well_data.filter_pack_bottom, ...
            well_data.filter_pack_top];

fill(filter_x, filter_y, [0.9, 0.8, 0.5], 'EdgeColor', 'black', 'LineWidth', 1, 'FaceAlpha', 0.7);

% Plot casing (6-inch PVC)
casing_x = [x_position - well_width/4, x_position + well_width/4, ...
            x_position + well_width/4, x_position - well_width/4, ...
            x_position - well_width/4];
casing_y = [well_data.top_casing, well_data.top_casing, ...
            well_data.bottom_casing, well_data.bottom_casing, ...
            well_data.top_casing];

fill(casing_x, casing_y, [0.8, 0.8, 0.8], 'EdgeColor', 'black', 'LineWidth', 2);

% Plot screen (0.050-inch slots)
screen_x = [x_position - well_width/4, x_position + well_width/4, ...
            x_position + well_width/4, x_position - well_width/4, ...
            x_position - well_width/4];
screen_y = [well_data.top_screen, well_data.top_screen, ...
            well_data.bottom_screen, well_data.bottom_screen, ...
            well_data.top_screen];

fill(screen_x, screen_y, [0.3, 0.6, 1.0], 'EdgeColor', 'blue', 'LineWidth', 2.5, ...
     'LineStyle', '--', 'FaceAlpha', 0.6);

% Plot sump
sump_x = [x_position - well_width/4, x_position + well_width/4, ...
          x_position + well_width/4, x_position - well_width/4, ...
          x_position - well_width/4];
sump_y = [well_data.sump_depth, well_data.sump_depth, ...
          well_data.sump_bottom, well_data.sump_bottom, ...
          well_data.sump_depth];

fill(sump_x, sump_y, [0.2, 0.2, 0.2], 'EdgeColor', 'black', 'LineWidth', 2);

% Add well center line
plot([x_position, x_position], [well_data.top_casing, well_data.bottom_casing], ...
     'k-', 'LineWidth', 2);

% Add borehole diameter labels
text(x_position + well_width/2 + 5, 10, '22"', 'HorizontalAlignment', 'left', ...
     'VerticalAlignment', 'middle', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'red');
text(x_position + well_width*0.7/2 + 5, 170, '14.75"', 'HorizontalAlignment', 'left', ...
     'VerticalAlignment', 'middle', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'red');

% Add depth labels
if strcmp(side, 'right')
    text(x_position + well_width/2 + 15, well_data.top_casing, '0 ft', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    text(x_position + well_width/2 + 15, well_data.bottom_casing, ...
         sprintf('%d ft', well_data.bottom_casing), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold');
    text(x_position + well_width/2 + 15, well_data.top_screen, ...
         sprintf('%d ft', well_data.top_screen), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    text(x_position + well_width/2 + 15, well_data.bottom_screen, ...
         sprintf('%d ft', well_data.bottom_screen), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    text(x_position + well_width/2 + 15, well_data.sump_depth, ...
         sprintf('%d ft', well_data.sump_depth), ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
end

end
