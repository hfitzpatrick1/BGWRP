# Analysis Runner Scripts

This directory contains the main analysis scripts for running complete workflows.

## Main Scripts

### `run_PT01a_thesis_analysis.m` ⭐
**Purpose:** Complete PT-01a Recovery analysis for thesis
- Runs correlation analysis with optimized 1 Hz DAS data
- Performs linear regression with depth-range analysis
- Generates all required figures with optimal settings
- **Current settings:** R² = 0.936, 50-second smoothing, +38 second time shift

**Usage:**
```matlab
cd('C:\Coding\BGWRP\scripts')
run_PT01a_thesis_analysis
```

**Output:**
- Figure 101: DAS Displacement Rate (waterfall)
- Figure 102: Displacement Rate with monitoring wells (3 subplots)
- Figure 103: Strain with head data
- Figure: 4-subplot regression analysis (R² = 0.936)

### `run_roi_analysis.m`
**Purpose:** Region of Interest (ROI) linear regression analysis
- Analyzes specific depth ranges (e.g., 450-510 ft for PT-01a)
- Performs temporal weighting for better correlation
- Calculates storage parameters using Becker method

**Configuration:**
- Zone: z2 (PT-01a pumping zone)
- Depth range: 450-510 ft (137-155 m)
- Regression window: 20:45:15 to 20:46:30 UTC
- Timing correction: 14 seconds

**Usage:**
```matlab
% Must run after correlation analysis
mode = 'run_correlation_analysis'; 
cd('C:\Coding\BGWRP\src')
BGWRP_Toolkit

% Then run ROI analysis
cd('C:\Coding\BGWRP\scripts')
run_roi_analysis
```

## Other Runner Scripts

All other `run_*.m` scripts in this directory are various analysis workflows:
- `run_PT01a_thesis_analysis_zone2.m` - Zone 2 specific analysis
- `run_full_analysis_corrected.m` - Complete analysis with corrections
- `run_linear_regression_*.m` - Various regression configurations

## Directory Purpose

This directory separates **high-level analysis workflows** (scripts that you actually run) from:
- Source code implementation (`src/`)
- Experimental/test scripts (`src/experiments/`)
- Processing pipelines (`src/processing/`)
- Utility functions (`src/_utils/`)

## Quick Reference

**For thesis work:** Use `run_PT01a_thesis_analysis.m`
**For custom analysis:** Create new runner script or modify existing ones
**For development:** See `src/` directory for implementation details
