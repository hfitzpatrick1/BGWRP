# Appendix B: MATLAB Files and Data Processing Code

The MATLAB processing code and processed data files are available as supplemental files to this PDF in the ProQuest Dissertations and Theses database.

## DAS Processing Toolkit

The DAS data processing and analysis code is contained in the `src/` directory. `BGWRP_Toolkit.m` is the main entry point for the processing pipeline. It is configured through `config.m`, which contains all analysis windows, smoothing parameters, and plot bounds for each pump test dataset. The toolkit processes raw 100 Hz Silixa iDAS displacement rate data (TDMS format) through concatenation, unit conversion (nm/sample to nm/s), temporal smoothing (30-second moving average, 3,000 samples), common mode noise removal using a Pico Formation reference interval (172--202 m depth), and a timing shifts on head rate data. Per-dataset smoothing parameters are defined in `config.m` under `dataset_smoothing` using uppercase keys (e.g., `PT01A_RECOVERY_100`).

Three driver scripts in `scripts/` reproduce the complete thesis analysis for each pump test:

- `run_PT01a_thesis_analysis.m` -- PT-01a (Lynwood-Silverado Aquifer, 137--155 m depth, November 7, 2023)
- `run_PT01b_thesis_analysis.m` -- PT-01b (Lynwood-Silverado Aquifer, 107--122 m depth, October 31, 2023)
- `run_PT01c_thesis_analysis.m` -- PT-01c (Gage-Gardena Aquifer, 79--94 m depth, October 24, 2023)

Each script sets `mode = 'run_correlation_analysis'` and runs `BGWRP_Toolkit`, which loads the DAS and head data, applies temporal smoothing and head rate timing shifts, and generates displacement rate waterfall plots (Figures 101--103). The script then calls a dataset-specific ROI analysis script (`run_roi_analysis_PT01a_100Hz.m`, `run_roi_analysis_PT01b.m`, or `run_roi_analysis_PT01c.m`), which extracts displacement rates across the screened-interval depth range, computes strain rate using spatial differencing over a 10 m gauge length (Becker et al., 2023), performs linear regression of strain rate against Bourdet-derived head rate over a 75-second recovery window using 15 evenly spaced time points, and calculates specific storage using the simplified poroelasticity equation with a Biot-Willis coefficient of 1.0 and specific weight of water of 9,810 N/m³. Test-specific timing corrections (+13 s for PT-01a, +12 s for PT-01b, +14 s for PT-01c) align the piezometer data with the GPS-synchronized DAS record. The ROI analysis generates a 4-subplot regression figure and a depth profile plot (Figure 104). Comments within each script describe the dataset-specific parameters.

Key analysis functions in `src/analyze/` include `analyze_das_data.m` (DAS loading, smoothing, and time shift), `analyze_head_data.m` (piezometer data processing), `linear_regression_depth_range.m` (ROI spatial differencing and regression), and `calculate_specific_storage_becker.m` (storage calculation from regression slope). Filter functions in `src/filter/` include `apply_filter.m`, which dispatches the MATLAB `movmean` smoothing used in this study. Plot generation is handled by `generate_plots.m` in `src/plot/`.

## DTS Processing Scripts

Two standalone scripts in `scripts/` reproduce the DTS analyses:

- `geothermal_gradient_PM07.m` computes the long-term average ambient temperature profile and Bourdet-derived geothermal gradient from 111 DTS profiles collected over 13 months (June 2023--July 2024), producing Figure 7 and exporting a LAS file for WellCAD visualization.
- `DTS_W_LAS.m` generates pre-pumping and post-pumping temperature profiles for each test date, computes temperature differences to identify thermal anomalies, and exports the results to LAS format, producing Figure 8.

Both scripts load the compiled DTS dataset (`Channel1_alldataupto070224.mat`) from the `_processed_DTS/` directory. The DTS depth calibration uses a top-of-casing reference at channel 80 (identified from a cold test on July 2, 2024) and a scale factor mapping the fiber length to the known well depth of 202.69 m (665 ft).

## Processed Data

Processed DAS datasets are stored in `_processed_DAS/`, with one subdirectory per test containing the concatenated 100 Hz displacement rate matrix (`_das/`), pressure transducer data (`_head/`), and timing configuration (`_das_timing/`). Each 100 Hz dataset is approximately 1.4 GB in memory; only one should be staged to the toolkit's working directory at a time. Compiled DTS temperature data are stored in `_processed_DTS/`.

## Raw Data Conversion Tools

Two third-party MATLAB toolboxes were used to convert raw instrument files into the `.mat` files consumed by the analysis scripts. Both are bundled in `src/`.

The Silixa TDMS reader (`src/prepare/Silixa_TDMSDataToPhysicalDispRate.m`) converts raw iDAS TDMS files into MATLAB `.mat` files containing displacement rate data in physical units (nm/sample) with sampling frequency and spatial metadata preserved.

The CTEMPs MATLAB DTS Toolbox (`src/ctemps_matlab_guis_07-2018/`; Kobs and Hausner, 2015) was used to read raw Silixa XT-DTS temperature profiles from individual XML files into compiled `.mat` matrices. The primary script used was `Process_Silixa.m`, which reads the XML output from the XT-DTS interrogator and consolidates all temperature profiles for a given channel into a single matrix file. Supporting functions include `calDTS.m` (calibration), `processDTS.m` (batch processing), `probe2tref.m` and `tref2DTS.m` (reference temperature handling). Sample `.ddf` data files are included with the toolbox for verification.

## Software Requirements

The code requires MATLAB R2023b or later with the Signal Processing Toolbox. All code was developed and tested on Windows 10/11. A minimum of 16 GB RAM is recommended for processing the 100 Hz DAS datasets.

## References

Kobs, S., and Hausner, M., 2015, CTEMPs MATLAB DTS Toolbox User Guide: Center for Transformative Environmental Monitoring Programs (ctemps.org), Corvallis, Oregon.

Becker, M. W., Harris, B., and Pevzner, R., 2023, Characterization of aquifer poroelastic response to impulse and oscillatory well pressure using distributed acoustic sensing: Geophysical Research Letters, v. 50, no. 1, e2022GL100904, doi:10.1029/2022GL100904.
