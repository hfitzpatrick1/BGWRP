# Digital Appendix: Estimating Hydraulic Properties of a Coastal Aquifer Using Distributed Fiber Optic Sensing

**Author:** Hannah Fitzpatrick
**Degree:** M.S. in Geology, California State University, Long Beach (December 2025)
**Advisor:** Matthew W. Becker, Ph.D.
**Committee:** Jillian Pearse, Ph.D.; K. Benjamin Hagedorn, Ph.D.

---

## Overview

This repository contains the data, source code, and processing scripts used to produce the analyses and figures presented in the thesis. The study applied Distributed Temperature Sensing (DTS) and Distributed Acoustic Sensing (DAS) during three aquifer pump tests (PT-01c, PT-01b, PT-01a) at the Brackish Groundwater Reclamation Program (BGWRP) site in Torrance, California, to characterize vertical hydraulic connectivity and estimate aquifer storage properties using a simplified poroelasticity method.

For detailed developer documentation of the MATLAB toolkit, see [README_dev.md](README_dev.md).
For a detailed description of the 100 Hz DAS data processing pipeline, see [DATA APPENDIX/100Hz_Processing_Appendix.md](DATA%20APPENDIX/100Hz_Processing_Appendix.md).

---

## Software Requirements

- **MATLAB R2023b** or later
- **Signal Processing Toolbox** (for `pwelch`, `spectrogram`, `filtfilt`, `butter`)
- Core functions used: `movmean`, `cumtrapz`, `datetime` (timezone support), `polyfit`, `interp1`

No Python installation is required. All analyses are reproducible using MATLAB alone.

---

## Repository Structure

```
BGWRP/
├── README.md                          # This file (thesis digital appendix)
├── README_dev.md                      # Developer toolkit documentation
├── config.m                           # Root configuration
│
├── scripts/                           # Runner scripts for each pump test
│   ├── run_PT01a_thesis_analysis.m    #   PT-01a (Lynwood-Silverado, 137-155 m)
│   ├── run_PT01b_thesis_analysis.m    #   PT-01b (Lynwood-Silverado, 107-122 m)
│   ├── run_PT01c_thesis_analysis.m    #   PT-01c (Gage-Gardena, 79-94 m)
│   ├── run_roi_analysis_PT01a_100Hz.m #   ROI regression + storage (PT-01a)
│   ├── run_roi_analysis_PT01b.m       #   ROI regression + storage (PT-01b)
│   └── run_roi_analysis_PT01c.m       #   ROI regression + storage (PT-01c)
│
├── src/                               # Toolkit source code
│   ├── BGWRP_Toolkit.m               #   Main processing entry point
│   ├── config.m                       #   Analysis parameters
│   ├── prepare/                       #   Data preparation (TDMS conversion, etc.)
│   ├── analyze/                       #   Core analysis functions
│   │   ├── linear_regression_depth_range.m    # Strain-rate vs head-rate regression
│   │   └── calculate_storage_from_poroelasticity.m
│   ├── filter/                        #   Signal processing and filtering
│   ├── plot/                          #   Visualization functions
│   └── _utils/                        #   Utility functions
│
├── data/
│   ├── _BAK/
│   │   ├── _raw/                      # Raw TDMS files from Silixa iDAS v2
│   │   ├── BAK/
│   │   │   ├── PT01a_Recovery_100/    # Processed 100 Hz DAS (PT-01a recovery)
│   │   │   ├── PT01b_Recovery_100/    # Processed 100 Hz DAS (PT-01b recovery)
│   │   │   └── PT01c_Recovery_100/    # Processed 100 Hz DAS (PT-01c recovery)
│   │   └── _TEMP/                     # Processed 1 Hz DAS (decimated)
│   ├── _BATCH/
│   │   ├── _active/                   # Working directory (copy data here to run)
│   │   └── _configs/                  # Global timing configurations
│   ├── Transducer Data/               # VuSitu piezometer CSVs (by test)
│   ├── PTWells/                       # Pumping well CSV logs
│   └── DTS Data/                      # DTS temperature data and scripts
│       ├── DTS_W_LAS.m               #   DTS processing + LAS export
│       ├── geothermal_gradient_PM07.m #   Geothermal gradient (Bourdet derivative)
│       ├── GradientDTS (coldtest)_GOOD.m  # Cold test calibration
│       ├── PM07_AvgGeothermalGradient.las # Exported gradient LAS
│       ├── Channel1_alldataupto070224.mat # Source DTS data (111 profiles)
│       └── channel 1/                 # Raw XML temperature profiles
│           ├── COLD TEST CH1/         #   Cold test calibration profiles
│           ├── LCR DTS/               #   LCR survey profiles (by date)
│           └── Step-tests DTS/        #   Profiles during pump tests
│
├── DATA APPENDIX/
│   └── 100Hz_Processing_Appendix.md   # Detailed processing pipeline docs
│
└── docs/                              # Schematics and supplementary materials
```

---

## Data Description

### DAS Data (Distributed Acoustic Sensing)

Raw DAS data were acquired using a Silixa iDAS v2 interrogator at 100 Hz with 0.25 m channel spacing along a fiber optic cable installed behind the PVC casing at PM-07.

| Directory | Contents | Format |
|-----------|----------|--------|
| `data/_BAK/_raw/` | Raw iDAS recordings | TDMS |
| `data/_BAK/BAK/PT01a_Recovery_100/` | Processed 100 Hz recovery, PT-01a (Nov 7, 2023) | MAT + timing config |
| `data/_BAK/BAK/PT01b_Recovery_100/` | Processed 100 Hz recovery, PT-01b (Oct 31, 2023) | MAT + timing config |
| `data/_BAK/BAK/PT01c_Recovery_100/` | Processed 100 Hz recovery, PT-01c (Oct 24, 2023) | MAT + timing config |
| `data/_BAK/_TEMP/` | Decimated 1 Hz recovery datasets | MAT + timing config |

### Piezometer Data

| Directory | Contents | Format |
|-----------|----------|--------|
| `data/Transducer Data/` | VuSitu pressure transducer data from PM-07 zones | CSV |
| `data/PTWells/` | Pumping well (PT-01a/b/c) pressure logs | CSV |

### DTS Data (Distributed Temperature Sensing)

Temperature profiles were collected using a Silixa XT-DTS along the same fiber at PM-07. A total of 111 profiles spanning June 2023 to July 2024 are included.

| File/Directory | Contents |
|----------------|----------|
| `Channel1_alldataupto070224.mat` | All 111 temperature profiles (815 channels x 111 timestamps) |
| `channel 1/` | Raw XML temperature profiles organized by survey date |
| `channel 1/Step-tests DTS/` | DTS profiles collected during pump tests (Oct 24, Oct 31, Nov 7 2023) |
| `channel 1/COLD TEST CH1/` | Cold test calibration profiles (Jul 2, 2024) |

---

## Reproducing the Analysis

### DAS Poroelastic Storage Analysis (Thesis Figures 14-16, Table 4)

Each pump test analysis follows the same workflow:

1. Copy the processed 100 Hz dataset into the working directory:
   ```
   Copy data\_BAK\BAK\PT01c_Recovery_100\ to data\_BATCH\_active\PT01c_Recovery_100\
   ```

2. Open MATLAB and navigate to the `scripts/` directory:
   ```matlab
   cd('C:\Coding\BGWRP\scripts')
   ```

3. Run the thesis analysis script:
   ```matlab
   run_PT01c_thesis_analysis    % PT-01c (Gage-Gardena, 79-94 m)
   ```

4. The script will:
   - Load the 100 Hz DAS data and piezometer head data
   - Apply temporal smoothing (30-second movmean) and compute strain rate
   - Apply common mode noise removal using Pico Formation reference channels
   - Generate DAS waterfall and time series plots (Figures 101-104)
   - Call `run_roi_analysis_PT01c.m`, which performs the linear regression of strain rate vs head rate over the ROI depth range and calculates specific storage

Repeat with `run_PT01b_thesis_analysis` and `run_PT01a_thesis_analysis` for the other two tests.

### DTS Temperature Analysis (Thesis Figures 7-8)

1. Open MATLAB and navigate to `data/DTS Data/`:
   ```matlab
   cd('C:\Coding\BGWRP\data\DTS Data')
   ```

2. Run the DTS processing script:
   ```matlab
   DTS_W_LAS    % Produces pre/post pump temperature profiles and LAS exports
   ```

3. Run the geothermal gradient script:
   ```matlab
   geothermal_gradient_PM07    % Produces average temperature profile and Bourdet derivative
   ```

---

## Script-to-Figure Mapping

| Thesis Figure | Script | Description |
|---------------|--------|-------------|
| Figure 7 | `data/DTS Data/geothermal_gradient_PM07.m` | Average ambient temperature profile and Bourdet-derived geothermal gradient |
| Figure 8 | `data/DTS Data/DTS_W_LAS.m` | Pre- and post-pumping temperature profiles for each test |
| Figures 11-13 | `scripts/run_PT01c/b/a_thesis_analysis.m` | DAS displacement rate waterfalls and time series |
| Figure 14 | `scripts/run_PT01c_thesis_analysis.m` + `run_roi_analysis_PT01c.m` | PT-01c poroelastic storage analysis (4-subplot regression) |
| Figure 15 | `scripts/run_PT01b_thesis_analysis.m` + `run_roi_analysis_PT01b.m` | PT-01b poroelastic storage analysis |
| Figure 16 | `scripts/run_PT01a_thesis_analysis.m` + `run_roi_analysis_PT01a_100Hz.m` | PT-01a poroelastic storage analysis |
| Figure 17 | `data/storage_comparison_barplot.py` | Specific storage comparison (AQTESOLV vs DAS) |
| Table 4 | `scripts/run_roi_analysis_PT01*.m` | Regression and storage results (compiled from all three tests) |

---

## Key Configuration Files

| File | Purpose |
|------|---------|
| `config.m` (root) | Global paths and base settings |
| `src/config.m` | Analysis parameters: smoothing windows, depth bounds, waterfall limits |
| `data/_BAK/BAK/PT01*/_das_timing/get_timing_*.m` | Per-test timing: start/end times, number of files, calibration |

---

## Processing Parameters (as described in thesis Chapter 3)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| DAS sampling rate | 100 Hz | Resolves rapid poroelastic transient during recovery |
| Temporal smoothing | 30 s movmean (3,000 samples) | Suppresses instrument noise; < half the 75 s recovery window |
| Regression smoothing | 20 s movmean (2,000 samples) | Bridges 100 Hz DAS and 0.2 Hz piezometer rates |
| Spatial smoothing | 40 channels (~10 m) | Matches gauge length; display plots only |
| Recovery window | 75 seconds post shut-off | Period of strongest strain-rate/head-rate correlation |
| Bourdet smoothing (DTS) | L = 6.1 m (20 ft) | Matches PM-07 screened interval length |
| Depth correction factor | 1.0849 | Ratio of known well depth to fiber-measured optical length |
| Biot-Willis coefficient | alpha = 1.0 | Appropriate for unconsolidated alluvium (Wang, 2000) |

---

## Citation

If you use this code or data, please cite:

> Fitzpatrick, H. (2025). *Estimating Hydraulic Properties of a Coastal Aquifer Using Distributed Fiber Optic Sensing* [Master's thesis, California State University, Long Beach].

---

## Contact

Hannah Fitzpatrick
Department of Geological Sciences
California State University, Long Beach
