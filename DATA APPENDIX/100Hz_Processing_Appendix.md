# Digital Appendix: Data Processing for DAS and DTS Analyses

> **Thesis companion document** — describes the data processing pipelines, parameters, and reproducibility steps for the 100 Hz DAS recovery datasets and DTS temperature analyses presented in this work.

---

## 1. Overview

Three constant-rate pump tests (PT-01a, PT-01b, PT-01c) were monitored with a Silixa iDAS distributed acoustic sensing (DAS) system and a Silixa XT-DTS distributed temperature sensing (DTS) system, both installed on the same fiber optic cable cemented behind well casing at PM-07. DAS data were acquired at 100 Hz with 0.25 m channel spacing; DTS profiles were collected at approximately 11-minute intervals.

Recovery-phase DAS data were processed to extract strain rate, correlated with piezometric head rate, and used to estimate specific storage via the simplified poroelastic method (Becker et al., 2023). DTS temperature profiles were used to establish a long-term ambient geothermal gradient and to evaluate vertical hydraulic connectivity by comparing pre- and post-pumping temperatures.

All processing was performed in MATLAB using a custom toolkit (`BGWRP_Toolkit`). Source code is included in the `src/` directory of this appendix.

### 1.1 DAS Datasets

| Dataset | Directory Name | Test Date (UTC) | Well Depth Range |
|---------|---------------|------------------|------------------|
| PT-01a Recovery | `PT01a_Recovery_100` | 2023-11-07 | 450-510 ft (137-155 m) |
| PT-01b Recovery | `PT01b_Recovery_100` | 2023-10-31 | 350-400 ft (107-122 m) |
| PT-01c Recovery | `PT01c_Recovery_100` | 2023-10-24 | 260-310 ft (79-94 m) |

### 1.2 DTS Datasets

| Dataset | Description | Profiles |
|---------|-------------|----------|
| `Channel1_alldataupto070224.mat` | Compiled temperature profiles (Jun 2023 - Jul 2024) | 111 |
| `_raw_DTS/channel 1/Step-tests DTS/` | Raw XML profiles during pump tests | ~90 |
| `_raw_DTS/channel 1/LCR DTS/` | Ambient LCR survey profiles | ~20 |
| `_raw_DTS/channel 1/COLD TEST CH1/` | Cold test calibration profiles (Jul 2, 2024) | 4 |

---

## 2. DAS Data Preparation Pipeline

### 2.1 Raw TDMS to MAT Conversion

Raw Silixa iDAS TDMS files were converted to MATLAB `.mat` files using `Silixa_TDMSDataToPhysicalDispRate.m` (`src/prepare/`). This function:

- Reads TDMS binary data and applies ADC-to-physical scaling
- Outputs displacement rate in **nm/sample** (native iDAS units)
- Preserves the sampling frequency (`fs_f = 100 Hz`) and spatial metadata (`spatial_samp`, `spatial_res = 0.25 m/channel`)

### 2.2 Concatenation (No Decimation)

Sequential TDMS files recorded at 60-second intervals were concatenated at the native 100 Hz sampling rate into continuous datasets using `process_mat_data.m` with **`decimation_factor = 1`** (mode `prep_no_decim`). Concatenation at full sampling rate preserved temporal continuity without introducing edge effects between files. The output variable is `fulldata` (matrix dimensions: time samples x channels).

**Memory note:** Each 100 Hz dataset is approximately 1.4 GB in memory. Only one dataset should reside in the `_active/` directory at a time.

### 2.3 Depth Calibration

DAS data were spatially calibrated by identifying characteristic transitions in the raw displacement rate data. For PT-01a and PT-01b: top of casing at channel 513, water table at channel 622 (27.24 m / 89.43 ft), bottom at channel 1324. For PT-01c: top of casing at channel 109, water table at channel 218, bottom at channel 920. A scaling factor of 0.9997 was applied to align measured fiber length with the known depth of 202.69 m (665 ft), yielding an effective spatial resolution of 0.25 m per channel.

### 2.4 Directory Structure

Each processed DAS dataset is stored in `_processed_DAS/` with the following layout:

```
_processed_DAS/
  PT01a_Recovery_100/
    _das/
      Dataset_PT01a_Recovery_short_1Hz.mat    <- DAS data (fulldata variable)
    _head/
      head_data.mat                            <- Pressure transducer data
    _das_timing/
      get_timing_PT01a_Recovery_short.m        <- Timing configuration
```

Timing configuration files were auto-generated from TDMS filenames (UTC timestamps) and define the `start` and `end` datetimes for each dataset.

---

## 3. DAS Signal Processing

### 3.1 Unit Conversion

Raw DAS data stored as **nm/sample** were converted to **nm/s** by multiplying by the sampling frequency (100 Hz) when `apply_sampling_freq_correction = true` in the toolkit configuration.

### 3.2 Temporal Smoothing

A MATLAB `movmean` moving average filter was applied along the time axis (dimension 1) with `'shrink'` endpoint handling. The smoothing window was configured per-dataset via `config.dataset_smoothing`:

| Parameter | PT-01a | PT-01b | PT-01c |
|-----------|--------|--------|--------|
| Sampling rate | 100 Hz | 100 Hz | 100 Hz |
| Preprocessing window | 30 s (3000 samples) | 30 s (3000 samples) | 30 s (3000 samples) |
| Strain rate window | 30 s (3000 samples) | 30 s (3000 samples) | 30 s (3000 samples) |
| Regression window | 20 s (2000 samples) | 20 s (2000 samples) | 20 s (2000 samples) |

The `run_correlation_analysis` mode in `BGWRP_Toolkit.m` sets global defaults of `matlab_movmean_window = 5000` (50 s), but the per-dataset `config.dataset_smoothing` entries override these to 30 s for the preprocessing pass. The toolkit resolves windows as **seconds x fs** to convert to samples.

### 3.3 DAS Time Shift

A forward time shift of **+38 seconds** was applied to the DAS time array before analysis-window masking (`das_time_shift_seconds = 38` in `BGWRP_Toolkit.m`). This compensates for the timing offset between the GPS-synchronized DAS clock and the pressure transducer data loggers. The shift is applied **before** the analysis window mask so that the cropped data are properly aligned.

### 3.4 Common Mode Noise Removal

Common mode noise (coherent signals affecting the entire cable equally) was removed by subtracting a reference signal from the bottom 30 m (100 ft) of fiber at 172-202 m (565-665 ft) depth, corresponding to the Pico Formation. This interval showed minimal displacement rate response during all three tests, confirming it reflects only instrument-wide noise. Common mode subtraction removed instrument drift and environmental noise, improving waterfall plot resolution and producing a cleaner strain rate signal for linear regression.

### 3.5 Spatial Smoothing (Display Only)

For waterfall display plots only, a 40-channel spatial moving average (~10 m) was applied across depth channels to reduce horizontal banding artifacts. This window matches the 10 m gauge length and does not degrade spatial resolution. No spatial smoothing was applied to the data used in the linear regression analysis.

---

## 4. DAS Analysis Windows

Each dataset was analyzed over a focused time window during the early recovery period, selected to capture the strongest poroelastic response:

| Dataset | Analysis Window (UTC) | Duration |
|---------|-----------------------|----------|
| PT-01a | 2023-11-07 20:44:30 - 20:47:30 | 3 min |
| PT-01b | 2023-10-31 19:29:30 - 19:32:30 | 3 min |
| PT-01c | 2023-10-24 19:14:30 - 19:17:30 | 3 min |

Within each analysis window, a narrower **regression window** was selected around the peak strain-rate signal:

| Dataset | Regression Window (UTC) | Duration |
|---------|-----------------------|----------|
| PT-01a | 2023-11-07 20:45:15 - 20:46:30 | 75 s |
| PT-01b | 2023-10-31 19:30:10 - 19:31:25 | 75 s |
| PT-01c | 2023-10-24 19:15:15 - 19:16:30 | 75 s |

---

## 5. ROI Strain Rate Computation (Becker Method)

The region-of-interest (ROI) analysis follows the spatial differencing approach of Becker et al. (2023) to convert DAS displacement rate to strain rate.

### 5.1 Processing Steps

1. **Channel extraction:** All DAS channels within the screened-interval depth range were extracted (test-specific ROIs: PT-01c 58 channels, PT-01b 61 channels, PT-01a 73 channels).
2. **Strain rate computation:** At each channel within the ROI, strain rate was computed from the difference in displacement rate between two points separated by the gauge length L, divided by L:

$$\dot{\varepsilon}(z,t) = \frac{\dot{u}(z + L, t) - \dot{u}(z, t)}{L}$$

where L = 10 m is the gauge length and u-dot is displacement rate (nm/s).

3. **Spatial averaging:** The resulting strain rates were spatially averaged across all channels in the ROI, reducing channel-to-channel noise while preserving the temporal shape of the signal.
4. **Regression smoothing:** A 20-second moving average (2000 samples) was applied to the strain rate time series prior to regression.

### 5.2 Head Data Processing

- **Bourdet derivative** (Bourdet et al., 1989) of the piezometric head was computed to obtain drawdown rate, a time-weighted central differencing approach that provides robust noise reduction compared to simple finite differencing.
- A **15-second moving average** was applied to the Bourdet derivative to stabilize the head rate estimate.
- For PT-01a, **temporal weighting** emphasized the peak recovery interval; PT-01b and PT-01c used **uniform weighting**.

### 5.3 Timing Correction (Head Shift)

A backward time shift was applied to the head data to align it with the DAS signal. This corrects for the combined effects of wellbore storage, transducer response time, and any residual GPS-logger clock offset.

| Dataset | Head Timing Correction | Direction |
|---------|----------------------|-----------|
| PT-01a | +13 s | Head shifted right (forward) |
| PT-01b | +12 s | Head shifted right (forward) |
| PT-01c | +14 s | Head shifted right (forward) |

### 5.4 Dataset-Specific Parameters

| Parameter | PT-01a | PT-01b | PT-01c |
|-----------|--------|--------|--------|
| Aquifer | Lynwood-Silverado | Lynwood-Silverado | Gage-Gardena |
| Head zone | z2 | z4 | z5 |
| Depth range (ft) | 450-510 | 350-400 | 260-310 |
| Depth range (m) | 137-155 | 107-122 | 79-94 |
| Channels in ROI | 73 | 61 | 58 |
| Head shift (s) | +13 | +12 | +14 |
| Calibration C1 | 513 | 513 | 513 |
| Channel spacing (m) | 0.25 | 0.25 | 0.25 |

---

## 6. Linear Regression and Storage Calculation

### 6.1 Linear Regression

Linear regression was performed between strain rate and head rate during the 75-second recovery window. All regressions used **N = 15 evenly spaced time points** within the window. For PT-01a, temporal weighting emphasized the peak recovery interval; PT-01b and PT-01c used uniform weighting.

### 6.2 Specific Storage (Becker et al., 2023)

Poroelastic storage was calculated from the simplified poroelasticity equation (Wang, 2000; Becker et al., 2023):

$$S_\epsilon = \frac{\alpha}{\gamma_w} \cdot \frac{\partial h / \partial t}{\partial \varepsilon / \partial t}$$

where dh/dt is drawdown rate (piezometer) and d-epsilon/dt is strain rate (DAS). Specific storage is then S_s = S_epsilon * gamma_w.

Parameters:
- alpha = 1.0 (Biot-Willis coefficient for unconsolidated alluvium)
- gamma_w = 9810 N/m^3 (specific weight of water)

### 6.3 Results Summary

| Metric | PT-01c (Zone 5) | PT-01b (Zone 4) | PT-01a (Zone 2) |
|--------|-----------------|-----------------|-----------------|
| Aquifer | Gage-Gardena | Lynwood-Silverado | Lynwood-Silverado |
| Depth (m) | 79-94 | 107-122 | 137-155 |
| Channels | 58 | 61 | 73 |
| Head shift (s) | +14 | +12 | +13 |
| Slope (1/m) | 3.19 x 10^-8 | 2.16 x 10^-8 | 2.43 x 10^-8 |
| R | 0.970 | 0.988 | 0.986 |
| R^2 | 0.941 | 0.976 | 0.972 |
| RMSE (1/s) | 1.45 x 10^-12 | 3.67 x 10^-13 | 7.63 x 10^-13 |
| S_epsilon (1/Pa) | 1.07 x 10^-11 | 7.24 x 10^-12 | 8.14 x 10^-12 |
| S_s (1/m) | 1.05 x 10^-7 | 7.10 x 10^-8 | 7.98 x 10^-8 |

All three tests yielded strong linear correlations (R^2 = 0.941-0.976). The two Lynwood-Silverado tests (PT-01a and PT-01b) produced consistent specific storage values (7.98 x 10^-8 and 7.10 x 10^-8 1/m), while the shallower Gage-Gardena interval (PT-01c) exhibits higher storage (1.05 x 10^-7 1/m), consistent with lower compaction at shallower depths.

### 6.4 Comparison with Traditional Pressure-Based Analysis

| Test | DAS S_s (1/m) | AQTESOLV S_s (1/m) | Ratio |
|------|---------------|---------------------|-------|
| PT-01c (Zone 5) | 1.05 x 10^-7 | 2.55 x 10^-5 | 243x |
| PT-01b (Zone 4) | 7.10 x 10^-8 | 1.80 x 10^-5 | 254x |
| PT-01a (Zone 2) | 7.98 x 10^-8 | 2.76 x 10^-5 | 346x |

The Hantush-Jacob estimates are systematically 243-346x higher than DAS values. This discrepancy reflects the fundamental difference between the two methods: the DAS poroelastic approach isolates elastic skeletal compressibility, while the pressure-based approach yields a composite storativity that lumps skeletal compressibility, fluid compressibility, leakage, and other hydraulic contributions.

---

## 7. DTS Temperature Processing

### 7.1 Instrument and Data Acquisition

Temperature profiles were collected using a Silixa XT-DTS along the same fiber optic cable at PM-07. Each profile records temperature at 815 channels (0.25 m spacing) from the instrument to the bottom of the well. A total of 111 profiles spanning June 2023 to July 2024 are compiled in `Channel1_alldataupto070224.mat` (variables: `tempC` [815 x 111], `distance` [815 x 1] in metres, `datetime` [1 x 111]).

### 7.2 Depth Calibration

DTS depth calibration mirrors the DAS approach. The top-of-casing was identified at channel 80 from the cold test, and a correction factor was applied to map channel 815 to the known well depth of 665 ft (202.69 m):

| Parameter | Value |
|-----------|-------|
| Top of casing channel | 80 |
| Known well depth | 665 ft (202.69 m) |
| Excess cable above casing | 54.46 ft |
| Scale factor | ~1.085 |

Raw fibre distance was converted to depth below casing in feet, then scaled so that the bottom channel maps to 665 ft.

### 7.3 DTS_W_LAS.m: Pre/Post Pump Temperature Profiles (Thesis Figure 8)

`scripts/DTS_W_LAS.m` generates pre- and post-pumping temperature profiles for each test date:

1. **Profile selection:** For each pump test date (Oct 24, Oct 31, Nov 7 2023), the script identifies DTS profiles collected before, during, and after pumping using UTC timestamps.
2. **Depth masking:** Only subsurface channels (depth >= 0 ft, <= 665 ft) are retained.
3. **Profile differencing:** Post-pump minus pre-pump temperature differences are computed to identify thermal anomalies. All three tests showed differences < 0.06 C, consistent with no vertical fluid movement.
4. **LAS export:** Temperature profiles are exported to LAS 2.0 format for visualization in WellCAD, with depth in feet below casing and temperature in degrees Celsius.

### 7.4 geothermal_gradient_PM07.m: Ambient Temperature Profile (Thesis Figure 7)

`scripts/geothermal_gradient_PM07.m` computes the long-term average geothermal gradient:

1. **Mean profile:** All 111 DTS temperature profiles are averaged to produce a mean and standard deviation profile, suppressing transient perturbations from individual pump tests or seasonal effects.
2. **Bourdet derivative:** The geothermal gradient is computed using the Bourdet derivative method (Bourdet et al., 1989) with a smoothing distance of L = 6.1 m (20 ft), matching the PM-07 screened interval length. This weighted central-difference approach provides a smoother gradient estimate than simple finite differencing.
3. **Linear fit:** A bulk gradient is computed by linear regression of temperature vs depth below 100 ft, excluding the shallow zone where surface temperature influence dominates.
4. **Outputs:** A three-panel figure (all profiles + mean, mean + linear fit, Bourdet derivative) and a LAS file (`PM07_AvgGeothermalGradient.las`) containing depth, mean temperature, and gradient.

### 7.5 DTS Processing Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Top of casing channel | CH-80 | Identified from cold test |
| Well depth | 665 ft (202.69 m) | Known from well completion |
| Scale factor | ~1.085 | Aligns fiber length to known depth |
| Bourdet smoothing distance | L = 6.1 m (20 ft) | Matches PM-07 screened interval length |
| Temperature resolution | < 0.06 C | Sufficient to detect vertical flow |
| Number of profiles | 111 | June 2023 - July 2024 |

---

## 8. Figures Produced

### 8.1 DAS Figures (per test)

| Figure | Content |
|--------|---------|
| 101 | Raw DAS displacement rate waterfall (full analysis window) |
| 102 | Displacement rate waterfall with monitoring well drawdown rate overlay (3 subplots) |
| 103 | Integrated strain with head data overlay (3 subplots) |
| 104 | Depth profile of mean displacement rate over regression window |
| Regression | 4-subplot figure: scatter + time series + residuals + spatial difference |

### 8.2 DTS Figures

| Thesis Figure | Script | Content |
|---------------|--------|---------|
| Figure 7 | `scripts/geothermal_gradient_PM07.m` | 3-panel: all profiles + mean, mean + linear fit, Bourdet derivative |
| Figure 8 | `scripts/DTS_W_LAS.m` | Pre/post pump temperature profiles for each test date |

### Waterfall Plot Rendering

Waterfall plots use `pcolor` with `'interp'` shading and `jet` colormap (256 levels). The time axis is downsampled to 2000 points for rendering performance. Depth is displayed in meters (converted from feet via x 0.3048).

---

## 9. Reproducibility

### 9.1 Running the DAS Analysis

**Setup:** The toolkit expects data at `data/_BATCH/_active/<dataset_name>/`. Stage a dataset by copying or creating a directory junction from `_processed_DAS/`:

```cmd
mklink /J "data\_BATCH\_active\PT01c_Recovery_100" "_processed_DAS\PT01c_Recovery_100"
```

Process one dataset at a time to stay within memory limits (~1.4 GB per dataset in memory).

**Running:** In MATLAB, navigate to `scripts/` and run:

```matlab
% PT-01c (Gage-Gardena, 79-94 m)
run_PT01c_thesis_analysis

% PT-01b (Lynwood-Silverado, 107-122 m)
run_PT01b_thesis_analysis

% PT-01a (Lynwood-Silverado, 137-155 m)
run_PT01a_thesis_analysis
```

Each script adds `src/` to the MATLAB path (which contains `config.m` and all toolkit functions), then executes two steps:
1. **`BGWRP_Toolkit`** in `run_correlation_analysis` mode: loads data from `_active/`, applies smoothing and time shift, generates Figures 101-103.
2. **`run_roi_analysis_PT01x_100Hz.m`**: performs spatial differencing, regression, storage calculation, generates Figure 104 and the 4-subplot regression figure.

### 9.2 Running the DTS Analysis

From `scripts/`:
```matlab
geothermal_gradient_PM07   % Produces average temperature + Bourdet gradient (Figure 7)
DTS_W_LAS                  % Produces pre/post pump profiles + LAS exports (Figure 8)
```

Both scripts load `Channel1_alldataupto070224.mat` from `_processed_DTS/` using relative paths. Output files (LAS and PNG) are written to the appendix root.

### 9.3 Pipeline Call Graph

```
DAS Analysis:
  scripts/run_PT01x_thesis_analysis.m
    +-- addpath(genpath('src/'))             <- puts config.m and all toolkit code on path
    +-- src/BGWRP_Toolkit.m  (mode = 'run_correlation_analysis')
    |     +-- src/config.m                   <- analysis windows, smoothing, bounds
    |     +-- src/analyze/analyze_head_data.m  <- load & process piezometer data
    |     +-- src/analyze/analyze_das_data.m   <- load, smooth, time-shift DAS data
    |     |     +-- src/filter/apply_filter.m  <- dispatches movmean smoothing
    |     +-- src/plot/generate_plots.m        <- Figures 101, 102, 103
    |
    +-- scripts/run_roi_analysis_PT01x_100Hz.m
          +-- src/analyze/linear_regression_depth_range.m  <- spatial differencing + regression
          |     +-- src/analyze/calculate_specific_storage_becker.m  <- S_s from slope
          +-- Depth profile plot (Figure 104)

DTS Analysis:
  scripts/DTS_W_LAS.m
    +-- _processed_DTS/Channel1_alldataupto070224.mat  <- 111 compiled profiles
    +-- Depth calibration (cold test parameters)
    +-- Pre/post pump differencing
    +-- LAS export

  scripts/geothermal_gradient_PM07.m
    +-- _processed_DTS/Channel1_alldataupto070224.mat  <- same source data
    +-- Mean profile computation
    +-- Bourdet derivative (L = 20 ft)
    +-- Linear fit (below 100 ft)
    +-- LAS + PNG export
```

### 9.4 Key Source Files

| File | Purpose |
|------|---------|
| `src/config.m` | All analysis windows, smoothing parameters, plot bounds |
| `src/BGWRP_Toolkit.m` | Main entry point; mode switch configures pipeline |
| `src/prepare/Silixa_TDMSDataToPhysicalDispRate.m` | TDMS to MAT conversion with physical scaling |
| `src/prepare/process_mat_data.m` | Concatenation and optional decimation |
| `src/analyze/analyze_das_data.m` | DAS loading, unit correction, smoothing, time shift |
| `src/analyze/analyze_head_data.m` | Head data loading and recovery rate calculation |
| `src/analyze/linear_regression_depth_range.m` | ROI spatial differencing and regression |
| `src/analyze/calculate_specific_storage_becker.m` | Poroelastic storage from regression slope |
| `src/filter/apply_filter.m` | Filter dispatcher (movmean, spatial median, etc.) |
| `src/plot/generate_plots.m` | Figure generation (101, 102, 103) |
| `scripts/DTS_W_LAS.m` | DTS pre/post pump profiles and LAS export |
| `scripts/geothermal_gradient_PM07.m` | Geothermal gradient (Bourdet derivative) and LAS export |

### 9.5 Configuration Keys

The toolkit uses **directory names** as dataset identifiers. Configuration lookups use `upper()` normalization. For each 100 Hz dataset, three configuration entries are required in `src/config.m`:

1. **Analysis window** -- `config.analysis_windows.<DirectoryName>.start/.end`
2. **Dataset smoothing** -- `config.dataset_smoothing.<UPPERCASE_NAME>.fs`, `.preprocessing_window_sec`, `.strain_rate_window_sec`, `.regression_window_sec`
3. **Manual plot bounds** -- `config.manual_bounds.<DirectoryName>.*` (optional, for fixed colorbars)

---

## 10. Software Environment

- **MATLAB** R2023b or later (requires `movmean`, `cumtrapz`, `datetime` with timezone support, `polyfit`, `interp1`)
- **Signal Processing Toolbox** (for `pwelch`, `spectrogram`, `filtfilt`, `butter`)
- **Silixa TDMS reader** bundled in `src/prepare/`
- **Operating system:** Windows 10/11 (paths use backslash convention)
- **RAM requirement:** >= 16 GB recommended for 100 Hz datasets (~1.4 GB per matrix)

---

## References

Becker, M. W., Coleman, T. I., & Ciervo, C. C. (2020). Distributed Acoustic Sensing as a Distributed Hydraulic Sensor in Fractured Bedrock. *Water Resources Research*, 56, e2020WR028140. https://doi.org/10.1029/2020WR028140

Becker, M. W., Harris, B., & Pevzner, R. (2023). Characterization of aquifer poroelastic response to impulse and oscillatory well pressure using distributed acoustic sensing. *Geophysical Research Letters*, 50(1), e2022GL100904. https://doi.org/10.1029/2022GL100904

Bourdet, D., Ayoub, J. A., & Pirard, Y. M. (1989). Use of pressure derivative in well-test interpretation. *SPE Formation Evaluation*, 4(2), 293-302. https://doi.org/10.2118/12777-PA

Wang, H. F. (2000). *Theory of Linear Poroelasticity with Applications to Geomechanics and Hydrogeology* (Vol. 2). Princeton University Press.
