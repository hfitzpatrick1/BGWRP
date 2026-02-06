%% Check Workspace Variables
% Quick check of what's in das_results and head_results

console_log('=== CHECKING WORKSPACE ===\n\n');

if exist('das_results', 'var')
    console_log('✓ das_results exists\n');
    console_log('Fields in das_results:\n');
    fields = fieldnames(das_results);
    for i = 1:length(fields)
        console_log('  %d. %s\n', i, fields{i});
    end
    console_log('\n');
else
    console_log('✗ das_results does NOT exist\n\n');
end

if exist('head_results', 'var')
    console_log('✓ head_results exists\n');
    console_log('Fields in head_results:\n');
    fields = fieldnames(head_results);
    for i = 1:length(fields)
        console_log('  %d. %s\n', i, fields{i});
    end
    console_log('\n');
else
    console_log('✗ head_results does NOT exist\n\n');
end

console_log('=== DIAGNOSTIC COMPLETE ===\n');
console_log('\nIf you see different field names above, we need to update run_roi_analysis.m\n');
console_log('to use the correct test name.\n');
