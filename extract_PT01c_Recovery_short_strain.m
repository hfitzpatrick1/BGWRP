function extract_PT01c_Recovery_short_strain()
%EXTRACT_PT01C_RECOVERY_SHORT_STRAIN Extract strain matrix for PT01c_Recovery_short
%
% This function should be run AFTER running BGWRP_Toolkit analysis
% It extracts the strain matrix data for the PT01c_Recovery_short dataset
% and saves it to a .mat file for your advisor

fprintf('=== EXTRACTING PT01c_Recovery_short STRAIN DATA ===\n');

% Check if das_results exists in workspace
if ~exist('das_results', 'var')
    error('das_results not found in workspace. Please run BGWRP_Toolkit analysis first.');
end

% Dataset name
dataset_name = 'PT01c_Recovery_short';

% Check if the dataset exists in results
if ~isfield(das_results, dataset_name)
    error('Dataset %s not found in das_results. Available datasets: %s', ...
        dataset_name, strjoin(fieldnames(das_results), ', '));
end

fprintf('Extracting strain data for: %s\n', dataset_name);

% Extract the strain data
strain_matrix = das_results.(dataset_name).smoothed_data;
time_array = das_results.(dataset_name).time_array;
depth_ft = das_results.(dataset_name).depth_ft;

% Get analysis window data (19:14-19:19 UTC)
analysis_strain = das_results.(dataset_name).analysis_strain_rate;
analysis_time = das_results.(dataset_name).analysis_time;

% Display information
fprintf('Full strain matrix size: %d time points x %d channels\n', size(strain_matrix,1), size(strain_matrix,2));
fprintf('Analysis window strain size: %d time points\n', length(analysis_strain));
fprintf('Time range: %s to %s\n', time_array(1), time_array(end));
fprintf('Analysis window: %s to %s\n', analysis_time(1), analysis_time(end));
fprintf('Depth range: %.1f to %.1f ft\n', min(depth_ft), max(depth_ft));

% Save full dataset
filename_full = 'PT01c_Recovery_short_strain_matrix_full.mat';
save(filename_full, 'strain_matrix', 'time_array', 'depth_ft');
fprintf('✓ Full strain matrix saved to: %s\n', filename_full);

% Save analysis window dataset
filename_analysis = 'PT01c_Recovery_short_strain_matrix_analysis_window.mat';
save(filename_analysis, 'analysis_strain', 'analysis_time', 'depth_ft');
fprintf('✓ Analysis window strain data saved to: %s\n', filename_analysis);

% Also save as CSV for easy viewing
csv_filename = 'PT01c_Recovery_short_strain_matrix.csv';
% Create header with time and depth info
header = ['Time_UTC', arrayfun(@(x) sprintf('Depth_%.1f_ft', x), depth_ft, 'UniformOutput', false)];
% Combine time and strain data
csv_data = [time_array, strain_matrix];
% Write CSV (note: datetime might need special handling)
writematrix(csv_data, csv_filename);
fprintf('✓ Strain matrix also saved as CSV: %s\n', csv_filename);

fprintf('\n=== EXTRACTION COMPLETE ===\n');
fprintf('Files created for your advisor:\n');
fprintf('  - %s (full dataset)\n', filename_full);
fprintf('  - %s (analysis window only)\n', filename_analysis);
fprintf('  - %s (CSV format)\n', csv_filename);

end


