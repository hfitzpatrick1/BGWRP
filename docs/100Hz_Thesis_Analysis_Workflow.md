# 100Hz DAS Thesis Analysis Workflow

> **Last updated:** 2026-02-06 (PT01a complete, PT01b scripts ready, PT01c pending)
> **Author:** Generated from PT01a_Recovery_100 analysis session

## Overview

This document describes the complete workflow for processing 100Hz DAS recovery data and producing thesis-ready figures and storage calculations. The workflow was developed and validated on PT01a_Recovery_100 (R² = 0.934).

**Datasets to process:**
| Dataset | Directory name | Status |
|---------|---------------|--------|
| PT-01a Recovery | `PT01a_Recovery_100` | Done (R² = 0.934) |
| PT-01b Recovery | `PT01b_Recovery_100` | Scripts ready, prep pending |
| PT-01c Recovery | `PT01c_Recovery_100` (TBD) | Pending |

---

## Quick Start (Copy-paste for new dataset)

```matlab
% PT-01a
cd('C:\Coding\BGWRP'); run('scripts\run_PT01a_thesis_analysis.m')

% PT-01b
cd('C:\Coding\BGWRP'); run('scripts\run_PT01b_thesis_analysis.m')
```

Each dataset has its own run script and ROI analysis script. See `scripts/` directory.

---

## Pipeline Architecture

```
run_PT01a_thesis_analysis.m          <- Top-level script (one per dataset)
  |
  +-- BGWRP_Toolkit.m               <- Configures mode, runs pipeline
  |     |
  |     +-- config.m                 <- Global config (analysis windows, smoothing, bounds)
  |     +-- analyze_head_data.m      <- Loads & processes head transducer data
  |     +-- analyze_das_data.m       <- Loads, smooths, time-shifts DAS data
  |     +-- generate_plots.m         <- Figures 101, 102, 103
  |
  +-- run_roi_analysis.m             <- ROI linear regression & storage calc
        |
        +-- linear_regression_depth_range.m  <- Spatial differencing, regression, 4-subplot figure
        +-- calculate_specific_storage_becker.m  <- Becker 2022 storage calculation
```

---

## Step 1: Data Directory Setup

Place 100Hz data in `data\_BATCH\_active\`:

```
data\_BATCH\_active\
  PT01a_Recovery_100\
    _das\
      Dataset_PT01a_Recovery_short_1Hz.mat    <- DAS data (decdata variable)
    _head\
      head_data.mat                            <- Head transducer data
    _das_timing\
      get_timing_PT01a_Recovery_short.m        <- Timing configuration
```

**Only one dataset should be in `_active\` at a time** to avoid memory issues with 100Hz data.

---

## Step 2: Configuration (config.m)

Three things must be set in `config.m` (project root) for each 100Hz dataset:

### 2a. Analysis Window
```matlab
% Line ~66 - defines the time range for Figures 101-103
config.analysis_windows.PT01a_Recovery_100.start = datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC');
config.analysis_windows.PT01a_Recovery_100.end   = datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC');
```

### 2b. Dataset Smoothing
```matlab
% Line ~355 - UPPERCASE key required
config.dataset_smoothing.PT01A_RECOVERY_100.fs = 100;                       % Sampling rate
config.dataset_smoothing.PT01A_RECOVERY_100.preprocessing_window_sec = 50;  % movmean window (seconds)
config.dataset_smoothing.PT01A_RECOVERY_100.strain_rate_window_sec = 50;
config.dataset_smoothing.PT01A_RECOVERY_100.regression_window_sec = 40;
```

> **Key rule:** Config keys must be UPPERCASE (`PT01A_RECOVERY_100`). Directory names are mixed case (`PT01a_Recovery_100`). The code normalizes with `upper()` before lookup.

### 2c. Manual Plot Bounds (optional)
If you want fixed colorbar/axis bounds, add entries under `config.manual_bounds`.

---

## Step 3: Processing Mode (BGWRP_Toolkit.m)

The run script sets `mode = 'run_correlation_analysis'` which configures:

| Parameter | Value | Notes |
|-----------|-------|-------|
| `smoothing_method` | `matlab_movmean` | Moving average filter |
| `matlab_movmean_window` | `5000` | 5000 samples = 50 seconds at 100Hz |
| `strain_rate_smoothing_window` | `5000` | Same 50-second window |
| `das_time_shift_seconds` | `38` | Shifts DAS forward to align with head data |

These are set globally in `BGWRP_Toolkit.m` but overridden per-dataset by `config.dataset_smoothing`.

---

## Step 4: DAS Processing (analyze_das_data.m)

What happens to the raw 100Hz data:

1. **Load** `.mat` file containing `decdata` (125,979 × 1,407 for PT01a)
2. **Unit correction**: Data stored as nm/sample → nm/s (multiply by fs if needed)
3. **Temporal smoothing**: `movmean(data, 5000, 1, 'shrink')` — 50-second window along time
4. **Time array**: Built from data start time at actual fs (100Hz): `data_start + seconds((0:n-1)/100)`
5. **Time shift**: Applied BEFORE analysis window masking (+38 seconds for PT01a)
6. **Analysis mask**: Applied to shifted time array to select the configured window
7. **No spatial smoothing** (opt-in via `config.enable_spatial_smooth`, currently off)
8. **No channel demeaning** (was tried, reverted — collapses signal)

---

## Step 5: Plot Generation (generate_plots.m)

### Figure 101 — Raw Data Waterfall
- Full analysis window, all channels
- Colorbar: `[0.35, 0.50]` nm/s (fixed for PT01a — adjust per dataset)
- Depth axis in meters, converted from feet
- Downsampled to 2000 time points for rendering

### Figure 102 — Displacement Rate with Monitoring Wells
- **Subplot 1**: Waterfall (same as 101 but with depth bounds and screened interval label)
  - Screened interval: 450-510 ft (137-155 m) shown as dashed black lines
  - Colorbar: `[0.35, 0.50]` nm/s
- **Subplot 2**: Monitoring well drawdown rate (left axis) + DAS displacement rate (right axis)
  - DAS shifted left by **16 seconds** for visual alignment (`-seconds(16)`)
  - Extended 15 seconds past analysis end to fill plot
- **Subplot 3**: Pumping well drawdown rate + DAS displacement rate (same shifts)
- X-axis: hardcoded to `[20:44:30, 20:47:30]` UTC for PT01a — **must update per dataset**

### Figure 103 — Strain with Head Data
- Strain = `cumtrapz(smoothed_data)` then `detrend(..., 2)` then `/10`
- Integration starts 1 minute before analysis window for baseline
- Memory-optimized: only loads analysis window + buffer

### Dataset-specific hardcoded values in generate_plots.m
Search for these and update when switching datasets:
```matlab
% Hardcoded PT01a time windows (appears ~15 times):
xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);

% Colorbar bounds (Figures 101, 102):
raw_bounds = [0.35, 0.50];
disp_bounds = [0.35, 0.50];

% Screened interval (Figure 102 subplot 1):
screened_top_m = 450 * 0.3048;
screened_bot_m = 510 * 0.3048;

% DAS visual time shift for subplots 2 & 3:
plot_das_time_ext = das_data.time_array(ext_mask) - seconds(16);
```

---

## Step 6: ROI Analysis (run_roi_analysis.m)

### Parameters to set per dataset:

```matlab
lr_config.zone = 'z2';                    % Which monitoring zone for head data
lr_config.depth_range_ft = [450, 510];    % Screened interval / pumping zone
lr_config.timing_correction_sec = 14;     % Head data backward shift (seconds)
lr_config.visual_strain_shift_sec = -5;   % Visual alignment shift for regression plots
lr_config.recovery_window = [datetime('2023-11-07 20:45:15', 'TimeZone', 'UTC'), ...
                            datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC')];
```

### What the ROI analysis does:
1. Extracts displacement rates for all channels in depth range
2. Applies 5-second pre-smoothing
3. Computes **centered spatial difference** across 10m gauge length: `ε̇ = [u̇(z+L/2) - u̇(z-L/2)] / L`
4. Takes **maximum envelope** across all valid depth pairs
5. Applies 40-sample moving average
6. Computes **Bourdet derivative** of head data
7. Runs **weighted least squares regression** with temporal weighting
8. Generates 4-subplot regression figure
9. Calculates **specific storage** via Becker 2022 method

### Storage calculation parameters:
```matlab
storage_config.alpha = 0.90;          % Biot-Willis coefficient
storage_config.gamma_unit = 'SI';     % SI units
storage_config.poisson_ratio = 0.30;  % Typical for sand/sandstone
```

---

## Step 7: Results (PT01a)

| Metric | Value |
|--------|-------|
| R² | 0.9344 |
| Correlation (R) | 0.9667 |
| Slope | 1.4116e-08 (1/s)/(ft/s) |
| RMSE | 2.0438e-13 1/s |
| S_s (specific storage) | 4.1682e-08 1/m |
| S_ε (strain-constrained) | 4.2489e-12 1/Pa |

---

## Checklist: Adding a New 100Hz Dataset

- [ ] Place data files in `data\_BATCH\_active\<DatasetName>\` with `_das\`, `_head\`, `_das_timing\` subdirs
- [ ] Add `config.analysis_windows.<DatasetName>.start/.end` in `config.m`
- [ ] Add `config.dataset_smoothing.<UPPERCASE_NAME>` in `config.m` with `fs=100`
- [ ] Copy `run_PT01a_thesis_analysis.m` → `run_PT01b_thesis_analysis.m`
- [ ] Copy `run_roi_analysis.m` → update or parameterize for new dataset
- [ ] Update **analysis window datetimes** in the run script and `config.m`
- [ ] Update **regression window** (`lr_config.recovery_window`) — identify the peak signal region
- [ ] Update **depth range** (`lr_config.depth_range_ft`) for the new well's screened interval
- [ ] Update **zone** (`lr_config.zone`) for the appropriate monitoring zone
- [ ] Update **colorbar bounds** in `generate_plots.m` (or make them auto-scale)
- [ ] Update **screened interval** label depths in `generate_plots.m`
- [ ] Update **hardcoded xlim datetimes** in `generate_plots.m` (search for `datetime('2023-11-07`)
- [ ] Update **DAS visual time shift** (`-seconds(16)`) if needed for new dataset
- [ ] Tune `timing_correction_sec` and `visual_strain_shift_sec` after initial run
- [ ] Run and verify all figures

---

## Known Issues & Workarounds

### Memory (100Hz data is ~1.4GB per matrix)
- Only one dataset in `_active\` at a time
- Waterfall plots downsampled to 2000 time points
- Strain integration only loads analysis window + 1min buffer
- `clear` used aggressively after large intermediate arrays

### MATLAB Crashes
- If MATLAB crashes, restart and rerun. The script overwrites logs each time.
- If Cursor's MATLAB terminal profile disappears: Ctrl+Shift+P → "Terminal: Select Default Profile" → pick PowerShell, then run `matlab -batch "..."` manually

### Implicit Expansion Gotcha
- Some arrays end up as row vs column vectors. If you get "14.8GB array" errors from simple operations like `&`, force column vectors with `(:)`.

### Head Data Ends Early
- `analyze_head_data.m` loads recovery data with a 15-second buffer past the analysis window end
- If head data still appears truncated, increase the buffer in `calc_recovery_rate`

---

## Files Modified in This Session

| File | Changes |
|------|---------|
| `config.m` | Added `PT01a_Recovery_100` analysis window and dataset_smoothing |
| `src/analyze/analyze_das_data.m` | Fixed time shift order (shift BEFORE mask), correct fs for time array |
| `src/analyze/analyze_head_data.m` | Extended recovery data by 15s buffer for plotting |
| `src/plot/generate_plots.m` | Fixed colorbar bounds, screened interval label, DAS visual shift, extended data for subplots |
| `src/analyze/linear_regression_depth_range.m` | Fixed sign conventions, added visual strain shift, column vector fixes |
| `scripts/run_roi_analysis.m` | Auto-detect dataset name, configurable visual strain shift |
| `scripts/run_PT01a_thesis_analysis.m` | Updated mode and comments |
| `src/BGWRP_Toolkit.m` | Set movmean window to 5000 for 100Hz |
