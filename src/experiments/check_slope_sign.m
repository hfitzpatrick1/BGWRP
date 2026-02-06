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

console_log('\n=== SLOPE SIGN CHECK ===\n\n');

console_log('Expected during recovery:\n');
console_log('  ∂ε/∂t (strain rate): > 0 (expansion, positive)\n');
console_log('  ∂s/∂t (drawdown rate): < 0 (drawdown decreasing, negative)\n');
console_log('  slope = (∂ε/∂t) / (∂s/∂t) = positive / negative = NEGATIVE\n\n');

console_log('Your results:\n');
console_log('  Slope: %.4e (1/s) per (ft/s)\n', 4.32e-09);
console_log('  This is POSITIVE - which suggests:\n');
console_log('    Option 1: Drawdown rate sign is wrong (should be negative)\n');
console_log('    Option 2: We should use absolute value of slope\n');
console_log('    Option 3: We should use head rate instead of drawdown rate\n\n');

console_log('Becker equation:\n');
console_log('  S_ε = -α (∂ε/∂t) / [γ (∂h/∂t)]\n');
console_log('  Using drawdown: ∂h/∂t = -∂s/∂t\n');
console_log('  So: S_ε = -α (∂ε/∂t) / [γ (-∂s/∂t)] = +α (∂ε/∂t) / [γ (∂s/∂t)]\n');
console_log('  If slope = (∂ε/∂t) / (∂s/∂t) is negative, then:\n');
console_log('    S_ε = +α × (negative slope) / γ = negative (WRONG!)\n\n');

console_log('SOLUTION: Use absolute value of slope:\n');
slope_abs = abs(4.32e-09);
console_log('  |slope| = %.4e\n', slope_abs);
console_log('  This would give the same result if slope is negative\n\n');

console_log('OR: Check if drawdown_rate should be negated:\n');
console_log('  If drawdown_rate is actually head_rate, then:\n');
console_log('    slope = (∂ε/∂t) / (∂h/∂t) = positive / positive = positive ✓\n');
console_log('    And S_ε = -α × slope / γ (with negative sign!)\n');

