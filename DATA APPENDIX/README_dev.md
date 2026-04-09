# DATA APPENDIX: BGWRP Thesis Digital Appendix

**Thesis:** Estimating Hydraulic Properties of a Coastal Aquifer Using Distributed Fiber Optic Sensing
**Author:** Hannah Fitzpatrick, M.S. Geology, California State University, Long Beach (December 2025)

---

## Contents

This appendix contains all data, source code, and processing scripts needed to reproduce the DAS poroelastic storage analysis (Thesis Figures 11-16, Table 4) and DTS temperature analysis (Thesis Figures 7-8). All scripts use relative paths derived from `mfilename('fullpath')` and require no manual path editing.

```
DATA APPENDIX/
|
|-- README_dev.md                     <- This file
|-- 100Hz_Processing_Appendix.md      <- Detailed processing pipeline documentation
|
|-- scripts/                          <- All analysis runner scripts
|   |-- run_PT01a_thesis_analysis.m   <-   PT-01a DAS entry point (Lynwood-Silverado, 137-155 m)
|   |-- run_PT01b_thesis_analysis.m   <-   PT-01b DAS entry point (Lynwood-Silverado, 107-122 m)
|   |-- run_PT01c_thesis_analysis.m   <-   PT-01c DAS entry point (Gage-Gardena, 79-94 m)
|   |-- run_roi_analysis_PT01a_100Hz.m  <- ROI regression + storage (PT-01a)
|   |-- run_roi_analysis_PT01b_100Hz.m  <- ROI regression + storage (PT-01b)
|   |-- run_roi_analysis_PT01c_100Hz.m  <- ROI regression + storage (PT-01c)
|   |-- geothermal_gradient_PM07.m    <-   Geothermal gradient analysis (Figure 7)
|   +-- DTS_W_LAS.m                   <-   DTS pre/post pump profiles + LAS export (Figure 8)
|
|-- src/                              <- BGWRP Toolkit source code
|   |-- config.m                      <-   Analysis parameters (smoothing, windows, bounds)
|   |-- BGWRP_Toolkit.m              <-   Main processing orchestrator
|   |-- analyze/                      <-   Core analysis functions
|   |   |-- analyze_das_data.m        <-     DAS data loading and smoothing
|   |   |-- analyze_head_data.m       <-     Piezometer head processing
|   |   |-- linear_regression_depth_range.m  <- Strain-rate vs head-rate regression
|   |   +-- calculate_specific_storage_becker.m  <- Poroelastic storage calculation
|   |-- filter/                       <-   Signal processing filters
|   |   |-- apply_filter.m            <-     Filter dispatcher
|   |   |-- common_mode_removal_filter.m
|   |   |-- spatial_median_filter.m
|   |   +-- resample_antialias_filter.m
|   |-- plot/                         <-   Visualization
|   |   |-- generate_plots.m          <-     Waterfall and time series plots
|   |   +-- get_plot_bounds.m
|   |-- prepare/                      <-   Data preparation
|   |   |-- Silixa_TDMSDataToPhysicalDispRate.m  <- TDMS-to-MAT conversion
|   |   |-- process_mat_data.m        <-     Concatenation and decimation
|   |   |-- process_head_data.m       <-     Head data combination
|   |   +-- TDMS_Adv_Read.m           <-     TDMS binary reader
|   +-- _utils/                       <-   Utility functions
|       |-- console_log.m
|       |-- discover_datasets.m
|       +-- load_batch_config.m
|
|-- data/                             <- Toolkit working directory (auto-created)
|   |-- _BATCH/
|   |   |-- _active/                  <-   Datasets staged for analysis (junction or copy)
|   |   +-- _log/                     <-   Console log output
|   +-- head/                         <-   Individual zone head files (head_a_z2.mat, etc.)
|
|-- _processed_DAS/                   <- Processed 100 Hz DAS recovery data
|   |-- PT01a_Recovery_100/           <-   PT-01a (Nov 7, 2023, ~400 MB)
|   |   |-- _das/Dataset_PT01a_Recovery_short_1Hz.mat
|   |   |-- _head/head_data.mat
|   |   +-- _das_timing/get_timing_PT01a_Recovery_short.m
|   |-- PT01b_Recovery_100/           <-   PT-01b (Oct 31, 2023, ~412 MB)
|   +-- PT01c_Recovery_100/           <-   PT-01c (Oct 24, 2023, ~290 MB)
|
|-- _processed_DTS/                   <- Processed DTS temperature data
|   |-- Channel1_alldataupto070224.mat  <- 111 compiled profiles (815 ch x 111 timestamps)
|   +-- Channel2_alldataupto070224.mat  <- Channel 2 compiled profiles
|
|-- _processed_head/                  <- Processed piezometer head data (MAT)
|   |-- head_a_z2.mat ... head_a_z5.mat, head_a_pw.mat  <- PT-01a zones + pumping well
|   |-- head_b_z2.mat ... head_b_z5.mat, head_b_pw.mat  <- PT-01b
|   +-- head_c_z2.mat ... head_c_z5.mat, head_c_pw.mat  <- PT-01c
|
|-- _raw_das/                         <- Raw TDMS files (Silixa iDAS, 100 Hz)
|   |-- PT01a_Recovery_short/_das/    <-   21 TDMS files (20:35-20:55 UTC, Nov 7 2023)
|   |-- PT01b_Recovery_short/_das/    <-   21 TDMS files (19:19-19:39 UTC, Oct 31 2023)
|   +-- PT01c_Recovery_short/_das/    <-   21 TDMS files (19:04-19:24 UTC, Oct 24 2023)
|
|-- _raw_DTS/                         <- Raw DTS XML temperature profiles
|   |-- channel 1/                    <-   Channel 1 (primary)
|   |   |-- *.xml                     <-     Individual profiles (ambient surveys)
|   |   |-- Step-tests DTS/           <-     Profiles during pump tests (by date)
|   |   |-- LCR DTS/                  <-     LCR survey profiles (by date)
|   |   +-- COLD TEST CH1/            <-     Cold test calibration (Jul 2, 2024)
|   +-- channel 2/                    <-   Channel 2 (redundant)
|
+-- _raw_head/                        <- Raw piezometer CSV files (VuSitu)
    |-- a/                            <-   PT-01a zones (Nov 7, 2023)
    |-- b/                            <-   PT-01b zones (Oct 31, 2023)
    +-- c/                            <-   PT-01c zones + pumping wells (Oct 24, 2023)
```

---

## Software Requirements

- **MATLAB R2023b** or later
- **Signal Processing Toolbox** (for `pwelch`, `spectrogram`, `filtfilt`, `butter`)
- Core functions used: `movmean`, `cumtrapz`, `datetime` (timezone support), `polyfit`, `interp1`
- **RAM:** >= 16 GB recommended (100 Hz datasets are ~290-412 MB on disk, ~1.4 GB in memory)

No Python installation is required.

---

## Quick Start: Reproducing the Analysis

### Setup (one-time)

The toolkit expects DAS datasets at `data/_BATCH/_active/<dataset_name>/`. Stage a dataset by either copying or creating a directory junction from `_processed_DAS/`:

**Option A -- Copy (portable, uses disk space):**
```
Copy _processed_DAS\PT01c_Recovery_100\  to  data\_BATCH\_active\PT01c_Recovery_100\
```

**Option B -- Junction (no duplication, Windows only):**
```cmd
mklink /J "data\_BATCH\_active\PT01c_Recovery_100" "_processed_DAS\PT01c_Recovery_100"
```

Process one dataset at a time to stay within memory limits.

### DAS Poroelastic Storage (Figures 11-16, Table 4)

In MATLAB, navigate to `scripts/` and run any of:
```matlab
run_PT01c_thesis_analysis    % PT-01c (Gage-Gardena, 79-94 m)
run_PT01b_thesis_analysis    % PT-01b (Lynwood-Silverado, 107-122 m)
run_PT01a_thesis_analysis    % PT-01a (Lynwood-Silverado, 137-155 m)
```

Each script:
1. Adds `src/` to the MATLAB path (locates `config.m` and all toolkit functions)
2. Runs `BGWRP_Toolkit` in `run_correlation_analysis` mode (loads DAS + head data, applies smoothing, generates Figures 101-103)
3. Runs `run_roi_analysis_PT01x_100Hz` (spatial differencing, regression, storage calculation, generates Figure 104 and the 4-subplot regression figure)

### DTS Temperature Analysis (Figures 7-8)

From `scripts/`:
```matlab
geothermal_gradient_PM07     % Geothermal gradient (Figure 7)
DTS_W_LAS                    % Pre/post pump profiles + LAS export (Figure 8)
```

Both scripts load `Channel1_alldataupto070224.mat` from `_processed_DTS/` using relative paths.

---

## Script-to-Figure Mapping

| Thesis Figure | Script | Description |
|---------------|--------|-------------|
| Figure 7 | `scripts/geothermal_gradient_PM07.m` | Average ambient temperature profile and Bourdet-derived geothermal gradient |
| Figure 8 | `scripts/DTS_W_LAS.m` | Pre- and post-pumping temperature profiles for each test |
| Figures 11-13 | `scripts/run_PT01c/b/a_thesis_analysis.m` | DAS displacement rate waterfalls and time series |
| Figure 14 | `scripts/run_PT01c_thesis_analysis.m` + `run_roi_analysis_PT01c_100Hz.m` | PT-01c poroelastic regression (4-subplot) |
| Figure 15 | `scripts/run_PT01b_thesis_analysis.m` + `run_roi_analysis_PT01b_100Hz.m` | PT-01b poroelastic regression |
| Figure 16 | `scripts/run_PT01a_thesis_analysis.m` + `run_roi_analysis_PT01a_100Hz.m` | PT-01a poroelastic regression |
| Table 4 | `scripts/run_roi_analysis_PT01*_100Hz.m` | Regression and storage results (compiled from all three tests) |

---

## Processing Parameters (Thesis Chapter 3)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| DAS sampling rate | 100 Hz | Resolves rapid poroelastic transient during recovery |
| Temporal smoothing | 30 s movmean (3000 samples) | Suppresses instrument noise; < half the 75 s recovery window |
| Regression smoothing | 20 s movmean (2000 samples) | Bridges 100 Hz DAS and 0.2 Hz piezometer rates |
| Spatial smoothing | 40 channels (~10 m) | Matches gauge length; display plots only |
| Recovery window | 75 seconds post shut-off | Period of strongest strain-rate/head-rate correlation |
| DAS time shift | +38 seconds | GPS-to-logger clock offset correction |
| Bourdet smoothing (DTS) | L = 6.1 m (20 ft) | Matches PM-07 screened interval length |
| Depth correction factor | 1.0849 | Ratio of known well depth to fiber-measured optical length |
| Biot-Willis coefficient | alpha = 1.0 | Appropriate for unconsolidated alluvium (Wang, 2000) |

---

## Data Provenance

| Data Type | Instrument | Format | Location in Appendix |
|-----------|-----------|--------|---------------------|
| DAS (raw) | Silixa iDAS v2, 100 Hz, 0.25 m spacing | TDMS | `_raw_das/` |
| DAS (processed) | Concatenated at 100 Hz, no decimation | MAT | `_processed_DAS/` |
| DTS (raw) | Silixa XT-DTS, ~11 min intervals | XML | `_raw_DTS/` |
| DTS (compiled) | 111 profiles, Jun 2023 - Jul 2024 | MAT | `_processed_DTS/` |
| Piezometer (raw) | In-Situ VuSitu SDT, PM-07 zones 1-5 | CSV | `_raw_head/` |
| Piezometer (processed) | Per-zone MAT files | MAT | `_processed_head/` |
| Pumping well | In-Situ VuSitu, PT-01a/b/c | CSV | `_raw_head/c/PTWells/` |

---

## Detailed Processing Documentation

See [100Hz_Processing_Appendix.md](100Hz_Processing_Appendix.md) for the complete signal processing pipeline, analysis parameters, and results tables.

---

## Citation

> Fitzpatrick, H. (2025). *Estimating Hydraulic Properties of a Coastal Aquifer Using Distributed Fiber Optic Sensing* [Master's thesis, California State University, Long Beach].
