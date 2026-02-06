# PT01a 100 Hz Data Analysis with Anti-Aliasing

## Overview
This analysis processes PT01a 100 Hz data using the **same anti-aliasing filter** that was used to create the clean 1 Hz data. This gives you 1 Hz smoothness with 100 Hz time resolution!

## What's New
- **Filter:** Resample anti-aliasing filter (Kaiser window FIR lowpass, cutoff 0.5 Hz)
- **Dataset:** PT01a_Recovery_100 (100 Hz sampling)
- **Same filter as your successful 1 Hz analysis** that achieved R² = 0.936

## How to Run

### Option 1: Quick Start (Recommended)
```matlab
cd('C:\Coding\BGWRP\scripts')
run_PT01a_100Hz_antialias
```

This single script runs the complete analysis:
1. Loads PT01a_Recovery_100 data
2. Applies anti-aliasing filter (same as 1 Hz decimation)
3. Runs correlation analysis
4. Runs ROI linear regression
5. Generates all figures
6. Compares with your 1 Hz results

### Option 2: Step-by-Step
```matlab
% Step 1: Add paths
cd('C:\Coding\BGWRP')
addpath(genpath('src'))

% Step 2: Run correlation analysis with anti-aliasing
mode = 'run_correlation_analysis_lowpass_PT01a';
BGWRP_Toolkit;

% Step 3: Run ROI analysis
run_roi_analysis_PT01a_100Hz;
```

## Configuration Details

### New Configuration Mode
**Mode:** `run_correlation_analysis_lowpass_PT01a`

**Settings:**
- Filter: `resample_antialias` (same as decimation)
- Cutoff: 0.5 Hz (Nyquist for 1 Hz)
- Decimation factor: 100 (simulates 100x decimation)
- Time shift: +38 seconds (from 1 Hz optimization)
- Recovery window: Nov 7, 2023, 20:45:15 to 20:46:30 UTC
- Dynamic colorbar bounds: Enabled

**Location:** `C:\Coding\BGWRP\src\BGWRP_Toolkit.m` (line ~841)

### Files Created
1. **Main script:** `scripts/run_PT01a_100Hz_antialias.m`
2. **ROI script:** `scripts/run_roi_analysis_PT01a_100Hz.m`
3. **Config mode:** Added to `src/BGWRP_Toolkit.m`

## Expected Results

### What Should Happen
- Cleaner waterfall plots (similar to 1 Hz quality)
- Better time resolution (100 Hz vs 1 Hz)
- Comparable or better R² value
- All 4 figures generated

### If R² is Lower
The 100 Hz data may need different timing than 1 Hz data. Try adjusting:

```matlab
% In BGWRP_Toolkit.m, line ~841 in the lowpass_PT01a mode
config.das_time_shift_seconds = XX;  % Try values around 38
```

Sweep ±5 seconds around 38 to find optimal timing.

## Comparison with 1 Hz Analysis

| Parameter | 1 Hz Data | 100 Hz + Anti-Aliasing |
|-----------|-----------|------------------------|
| **Dataset** | PT01a_Recovery_short | PT01a_Recovery_100 |
| **Sampling** | Pre-decimated to 1 Hz | 100 Hz with filter |
| **Filter** | Decimation anti-aliasing | Same filter applied |
| **Time Shift** | +38 seconds | +38 seconds (start) |
| **Smoothing** | 50s moving average | Minimal (100 samples) |
| **R²** | 0.936 | *To be determined* |

## Troubleshooting

### Dataset Not Found
**Error:** "No PT01a dataset found in das_results"

**Solution:** Make sure PT01a_Recovery_100 folder exists in:
```
C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_100\
```

And contains:
- A .mat file with the DAS data
- `get_timing_PT01a_Recovery_short.m` (timing config)

### Filter Takes Too Long
The anti-aliasing filter processes each channel individually. For ~2000 channels:
- Expected time: 2-5 minutes
- Progress printed every 100 channels

### NaN Values in Results
The filter checks for NaN/Inf and skips problematic channels. Check console output for warnings.

## Next Steps

After running this analysis:

1. **Compare R² values**
   - 1 Hz: 0.936
   - 100 Hz: Check `roi_results.R_squared`

2. **If 100 Hz R² is similar or better:** Success! You've validated the method at higher time resolution.

3. **If 100 Hz R² is lower:** Try time shift optimization:
   ```matlab
   % Test values from 33 to 43 seconds
   for shift = 33:43
       config.das_time_shift_seconds = shift;
       % Re-run analysis
   end
   ```

4. **Update your thesis documentation** with both 1 Hz and 100 Hz results to show robustness.

## Technical Details

### Why This Filter?
The 1 Hz data was created using MATLAB's `resample()` function, which applies a Kaiser window FIR anti-aliasing filter before decimation. This is why 1 Hz data looks cleaner than 100 Hz data with simple moving averages.

By applying the same filter to 100 Hz data **without decimating**, you get:
- Same smoothness as 1 Hz data
- Full 100 Hz time resolution preserved
- Cleaner baseline (less high-frequency noise)

### Filter Implementation
See: `src/filter/resample_antialias_filter.m`

- Filter order: 500 (or data-dependent)
- Cutoff: 0.5 Hz (normalized: 0.005 of 100 Hz Nyquist)
- Method: `fir1` + `filtfilt` (zero-phase)
- Same approach as MATLAB's `resample()` function

## Questions?
If you encounter issues, check:
1. Data file exists: `PT01a_Recovery_100/*.mat`
2. All scripts in `scripts/` folder
3. Console output for filter progress
4. Colorbar bounds are reasonable (dynamic bounds enabled)

Good luck with your analysis!
