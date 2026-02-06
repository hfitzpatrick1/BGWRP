%% Check Workspace Variables
% Quick check of what's in das_results and head_results

fprintf('=== CHECKING WORKSPACE ===\n\n');

if exist('das_results', 'var')
    fprintf('✓ das_results exists\n');
    fprintf('Fields in das_results:\n');
    fields = fieldnames(das_results);
    for i = 1:length(fields)
        fprintf('  %d. %s\n', i, fields{i});
    end
    fprintf('\n');
else
    fprintf('✗ das_results does NOT exist\n\n');
end

if exist('head_results', 'var')
    fprintf('✓ head_results exists\n');
    fprintf('Fields in head_results:\n');
    fields = fieldnames(head_results);
    for i = 1:length(fields)
        fprintf('  %d. %s\n', i, fields{i});
    end
    fprintf('\n');
else
    fprintf('✗ head_results does NOT exist\n\n');
end

fprintf('=== DIAGNOSTIC COMPLETE ===\n');
fprintf('\nIf you see different field names above, we need to update run_roi_analysis.m\n');
fprintf('to use the correct test name.\n');
