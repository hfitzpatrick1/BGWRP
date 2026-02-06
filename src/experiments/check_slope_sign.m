%CHECK_SLOPE_SIGN Verify slope sign convention
%
% During recovery:
% - Head increases: ∂h/∂t > 0
% - Drawdown decreases: ∂s/∂t < 0  (since s = h_initial - h)
% - Strain increases (expansion): ∂ε/∂t > 0
%
% So: slope = (∂ε/∂t) / (∂s/∂t) = positive / negative = NEGATIVE
%
% But if we got a positive slope, something is wrong with the sign convention

fprintf('\n=== SLOPE SIGN CHECK ===\n\n');

fprintf('Expected during recovery:\n');
fprintf('  ∂ε/∂t (strain rate): > 0 (expansion, positive)\n');
fprintf('  ∂s/∂t (drawdown rate): < 0 (drawdown decreasing, negative)\n');
fprintf('  slope = (∂ε/∂t) / (∂s/∂t) = positive / negative = NEGATIVE\n\n');

fprintf('Your results:\n');
fprintf('  Slope: %.4e (1/s) per (ft/s)\n', 4.32e-09);
fprintf('  This is POSITIVE - which suggests:\n');
fprintf('    Option 1: Drawdown rate sign is wrong (should be negative)\n');
fprintf('    Option 2: We should use absolute value of slope\n');
fprintf('    Option 3: We should use head rate instead of drawdown rate\n\n');

fprintf('Becker equation:\n');
fprintf('  S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)]\n');
fprintf('  Using drawdown: ∂h/∂t = -∂s/∂t\n');
fprintf('  So: S_ε = -α (∂ε/∂t) / [γ (-∂s/∂t)] = +α (∂ε/∂t) / [γ (∂s/∂t)]\n');
fprintf('  If slope = (∂ε/∂t) / (∂s/∂t) is negative, then:\n');
fprintf('    S_ε = +α × (negative slope) / γ = negative (WRONG!)\n\n');

fprintf('SOLUTION: Use absolute value of slope:\n');
slope_abs = abs(4.32e-09);
fprintf('  |slope| = %.4e\n', slope_abs);
fprintf('  This would give the same result if slope is negative\n\n');

fprintf('OR: Check if drawdown_rate should be negated:\n');
fprintf('  If drawdown_rate is actually head_rate, then:\n');
fprintf('    slope = (∂ε/∂t) / (∂h/∂t) = positive / positive = positive ✓\n');
fprintf('    And S_ε = -α × slope / γ (with negative sign!)\n');

