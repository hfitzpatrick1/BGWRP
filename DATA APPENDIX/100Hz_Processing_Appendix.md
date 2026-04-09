# Digital Appendix: 100 Hz DAS Data Processing for PT-01a, PT-01b, and PT-01c

> **Thesis companion document** — describes the data processing pipeline, parameters, and reproducibility steps for all 100 Hz recovery datasets analyzed in this work.

---

## 1. Overview

Three constant-rate pump tests (PT-01a, PT-01b, PT-01c) were monitored with a Silixa iDAS distributed acoustic sensing (DAS) system installed in a fiber-optic cable cemented behind well casing. Raw data were acquired at 100 Hz with 0.25 m channel spacing. Recovery-phase data were processed to extract strain rate, correlated with piezometric head, and used to estimate specific storage via the simplified poroelastic method (Becker et al., 2023).

All processing was performed in MATLAB using a custom toolkit (`BGWRP_Toolkit`). Source code is available in the accompanying repository.

### Datasets

| Dataset | Directory Name | Test Date (UTC) | Well Depth Range |
|---------|---------------|------------------|------------------|
| PT-01a Recovery | `PT01a_Recovery_100` | 2023-11-07 | 450–510 ft (137–155 m) |
| PT-01b Recovery | `PT01b_Recovery_100` | 2023-10-31 | 350–400 ft (107–122 m) |
| PT-01c Recovery | `PT01c_Recovery_100` | 2023-10-24 | 260–310 ft (79–94 m) |

---

## 2. Data Preparation Pipeline

### 2.1 Raw TDMS to MAT Conversion

Raw Silixa iDAS TDMS files were converted to MATLAB `.mat` files using `Silixa_TDMSDataToPhysicalDispRate.m`. This function:

- Reads TDMS binary data and applies ADC-to-physical scaling
- Outputs displacement rate in **nm/sample** (native iDAS units)
- Preserves the sampling frequency (`fs_f = 100 Hz`) and spatial metadata (`spatial_samp`, `spatial_res = 0.25 m/channel`)

### 2.2 Concatenation (No Decimation)

Sequential TDMS files recorded at 60-second intervals were concatenated at the native 100 Hz sampling rate into continuous datasets using `process_mat_data.m` with **`decimation_factor = 1`** (mode `prep_no_decim`). Concatenation at full sampling rate preserved temporal continuity without introducing edge effects between files. The output variable is `fulldata` (matrix dimensions: time samples × channels).

**Memory note:** Each 100 Hz dataset is approximately 1.4 GB in memory. Only one dataset should reside in the `_active/` directory at a time.

### 2.3 Depth Calibration

DAS data were spatially calibrated by identifying characteristic transitions in the raw displacement rate data. For PT-01a and PT-01b: top of casing at channel 513, water table at channel 622 (27.24 m / 89.43 ft), bottom at channel 1324. For PT-01c: top of casing at channel 109, water table at channel 218, bottom at channel 920. A scaling factor of 0.9997 was applied to align measured fiber length with the known depth of 202.69 m (665 ft), yielding an effective spatial resolution of 0.25 m per channel.

### 2.4 Directory Structure

Each dataset was placed in `data/_BATCH/_active/` with the following layout:

```
data/_BATCH/_active/
  PT01a_Recovery_100/
    _das/
      Dataset_PT01a_Recovery_short_1Hz.mat    ← DAS data (fulldata variable)
    _head/
      head_data.mat                            ← Pressure transducer data
    _das_timing/
      get_timing_PT01a_Recovery_short.m        ← Timing configuration
```

Timing configuration files were auto-generated from TDMS filenames (UTC timestamps) and define the `start` and `end` datetimes for each dataset.

---

## 3. Signal Processing

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

The `run_correlation_analysis` mode in `BGWRP_Toolkit.m` sets global defaults of `matlab_movmean_window = 5000` (50 s), but the per-dataset `config.dataset_smoothing` entries override these to 30 s for the preprocessing pass. The toolkit resolves windows as **seconds × fs** to convert to samples.

### 3.3 DAS Time Shift

A forward time shift of **+38 seconds** was applied to the DAS time array before analysis-window masking (`das_time_shift_seconds = 38` in `BGWRP_Toolkit.m`). This compensates for the timing offset between the GPS-synchronized DAS clock and the pressure transducer data loggers. The shift is applied **before** the analysis window mask so that the cropped data are properly aligned.

### 3.4 Common Mode Noise Removal

Common mode noise (coherent signals affecting the entire cable equally) was removed by subtracting a reference signal from the bottom 30 m (100 ft) of fiber at 172–202 m (565–665 ft) depth, corresponding to the Pico Formation. This interval showed minimal displacement rate response during all three tests, confirming it reflects only instrument-wide noise. Common mode subtraction removed instrument drift and environmental noise, improving waterfall plot resolution and producing a cleaner strain rate signal for linear regression.

### 3.5 Spatial Smoothing (Display Only)

For waterfall display plots only, a 40-channel spatial moving average (~10 m) was applied across depth channels to reduce horizontal banding artifacts. This window matches the 10 m gauge length and does not degrade spatial resolution. No spatial smoothing was applied to the data used in the linear regression analysis.

---

## 4. Analysis Windows

Each dataset was analyzed over a focused time window during the early recovery period, selected to capture the strongest poroelastic response:

| Dataset | Analysis Window (UTC) | Duration |
|---------|-----------------------|----------|
| PT-01a | 2023-11-07 20:44:30 – 20:47:30 | 3 min |
| PT-01b | 2023-10-31 19:29:30 – 19:32:30 | 3 min |
| PT-01c | 2023-10-24 19:14:30 – 19:17:30 | 3 min |

Within each analysis window, a narrower **regression window** was selected around the peak strain-rate signal:

| Dataset | Regression Window (UTC) | Duration |
|---------|-----------------------|----------|
| PT-01a | 2023-11-07 20:45:15 – 20:46:30 | 75 s |
| PT-01b | 2023-10-31 19:30:10 – 19:31:25 | 75 s |
| PT-01c | 2023-10-24 19:15:15 – 19:16:30 | 75 s |

---

## 5. ROI Strain Rate Computation (Becker Method)

The region-of-interest (ROI) analysis follows the spatial differencing approach of Becker et al. (2023) to convert DAS displacement rate to strain rate.

### 5.1 Processing Steps

1. **Channel extraction:** All DAS channels within the screened-interval depth range were extracted (test-specific ROIs: PT-01c 58 channels, PT-01b 61 channels, PT-01a 73 channels).
2. **Strain rate computation:** At each channel within the ROI, strain rate was computed from the difference in displacement rate between two points separated by the gauge length $L$, divided by $L$:

$$\dot{\varepsilon}(z,t) = \frac{\dot{u}(z + L, t) - \dot{u}(z, t)}{L}$$

where $L = 10$ m is the gauge length and $\dot{u}$ is displacement rate (nm/s).

3. **Spatial averaging:** The resulting strain rates were spatially averaged across all channels in the ROI, reducing channel-to-channel noise while preserving the temporal shape of the signal.
4. **Regression smoothing:** A 20-second moving average (2000 samples) was applied to the strain rate time series prior to regression.

### 5.2 Head Data Processing

- **Bourdet derivative** (Bourdet et al., 1989) of the piezometric head was computed to obtain drawdown rate — a time-weighted central differencing approach that provides robust noise reduction compared to simple finite differencing.
- A **15-second moving average** was applied to the Bourdet derivative to stabilize the head rate estimate.
- For PT-01a, **temporal weighting** emphasized the peak recovery interval; PT-01b and PT-01c used **uniform weighting**.

### 5.3 Timing Correction (Head Shift)

A backward time shift was applied to the head data to align it with the DAS signal. This corrects for the combined effects of wellbore storage, transducer response time, and any residual GPS–logger clock offset.

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
| Zone β | 0.132 | 0.020 | 0.021 |
| Depth range (ft) | 450–510 | 350–400 | 260–310 |
| Depth range (m) | 137–155 | 107–122 | 79–94 |
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

where $\partial h / \partial t$ is drawdown rate (piezometer) and $\partial \varepsilon / \partial t$ is strain rate (DAS). Specific storage is then $S_s \approx S_\epsilon \cdot \gamma_w$.

Parameters:
- $\alpha$ = 1.0 (Biot-Willis coefficient for unconsolidated alluvium)
- $\gamma_w$ = 9810 N/m³ (specific weight of water)

### 6.3 Results Summary

| Metric | PT-01c (Zone 5) | PT-01b (Zone 4) | PT-01a (Zone 2) |
|--------|-----------------|-----------------|-----------------|
| Aquifer | Gage-Gardena | Lynwood-Silverado | Lynwood-Silverado |
| Depth (m) | 79–94 | 107–122 | 137–155 |
| Channels | 58 | 61 | 73 |
| β | 0.021 | 0.020 | 0.132 |
| Head shift (s) | +14 | +12 | +13 |
| Slope (1/m) | 3.19 × 10⁻⁸ | 2.16 × 10⁻⁸ | 2.43 × 10⁻⁸ |
| R | 0.970 | 0.988 | 0.986 |
| R² | 0.941 | 0.976 | 0.972 |
| RMSE (1/s) | 1.45 × 10⁻¹² | 3.67 × 10⁻¹³ | 7.63 × 10⁻¹³ |
| S_ε (1/Pa) | 1.07 × 10⁻¹¹ | 7.24 × 10⁻¹² | 8.14 × 10⁻¹² |
| S_s (1/m) | 1.05 × 10⁻⁷ | 7.10 × 10⁻⁸ | 7.98 × 10⁻⁸ |

All three tests yielded strong linear correlations (R² = 0.941–0.976). The two Lynwood-Silverado tests (PT-01a and PT-01b) produced consistent specific storage values (7.98 × 10⁻⁸ and 7.10 × 10⁻⁸ 1/m), while the shallower Gage-Gardena interval (PT-01c) exhibits higher storage (1.05 × 10⁻⁷ 1/m), consistent with lower compaction at shallower depths.

### 6.4 Comparison with Traditional Pressure-Based Analysis

| Test | DAS S_s (1/m) | AQTESOLV S_s (1/m) | Ratio |
|------|---------------|---------------------|-------|
| PT-01c (Zone 5) | 1.05 × 10⁻⁷ | 2.55 × 10⁻⁵ | 243× |
| PT-01b (Zone 4) | 7.10 × 10⁻⁸ | 1.80 × 10⁻⁵ | 254× |
| PT-01a (Zone 2) | 7.98 × 10⁻⁸ | 2.76 × 10⁻⁵ | 346× |

The Hantush-Jacob estimates are systematically 243–346× higher than DAS values. This discrepancy reflects the fundamental difference between the two methods: the DAS poroelastic approach isolates elastic skeletal compressibility, while the pressure-based approach yields a composite storativity that lumps skeletal compressibility, fluid compressibility, leakage, and other hydraulic contributions.

---

## 7. Figures Produced

For each dataset, the following figures were generated:

| Figure | Content |
|--------|---------|
| 101 | Raw DAS displacement rate waterfall (full analysis window) |
| 102 | Displacement rate waterfall with monitoring well drawdown rate overlay (3 subplots) |
| 103 | Integrated strain with head data overlay (3 subplots) |
| 104 | Depth profile of mean displacement rate over regression window |
| Regression | 4-subplot figure: scatter + time series + residuals + spatial difference |

### Waterfall Plot Rendering

Waterfall plots use `pcolor` with `'interp'` shading and `jet` colormap (256 levels). The time axis is downsampled to 2000 points for rendering performance. Depth is displayed in meters (converted from feet via × 0.3048).

---

## 8. Reproducibility

### 8.1 Running the Analysis

Each dataset has a dedicated driver script in `scripts/`:

```matlab
% PT-01a
cd('C:\Coding\BGWRP'); run('scripts\run_PT01a_thesis_analysis.m')

% PT-01b
cd('C:\Coding\BGWRP'); run('scripts\run_PT01b_thesis_analysis.m')

% PT-01c
cd('C:\Coding\BGWRP'); run('scripts\run_PT01c_thesis_analysis.m')
```

Each script executes two steps:
1. **`BGWRP_Toolkit`** in `run_correlation_analysis` mode — loads data, applies smoothing and time shift, generates Figures 101–103.
2. **`run_roi_analysis_PT01x.m`** — performs spatial differencing, regression, storage calculation, generates Figure 104 and regression figure.

### 8.2 Pipeline Call Graph

```
run_PT01x_thesis_analysis.m
  ├── BGWRP_Toolkit.m  (mode = 'run_correlation_analysis')
  │     ├── config.m                      ← analysis windows, smoothing, bounds
  │     ├── analyze_head_data.m           ← load & process piezometer data
  │     ├── analyze_das_data.m            ← load, smooth, time-shift DAS data
  │     │     └── apply_filter.m          ← dispatches movmean smoothing
  │     └── generate_plots.m              ← Figures 101, 102, 103
  │
  └── run_roi_analysis_PT01x.m
        ├── linear_regression_depth_range.m   ← spatial differencing + regression
        │     └── calculate_specific_storage_becker.m  ← S_s from slope
        └── Depth profile plot (Figure 104)
```

### 8.3 Key Source Files

| File | Purpose |
|------|---------|
| `src/BGWRP_Toolkit.m` | Main entry point; mode switch configures pipeline |
| `config.m` | All analysis windows, smoothing parameters, plot bounds |
| `src/prepare/Silixa_TDMSDataToPhysicalDispRate.m` | TDMS → MAT conversion with physical scaling |
| `src/prepare/process_mat_data.m` | Concatenation and optional decimation |
| `src/analyze/analyze_das_data.m` | DAS loading, unit correction, smoothing, time shift |
| `src/analyze/analyze_head_data.m` | Head data loading and recovery rate calculation |
| `src/analyze/linear_regression_depth_range.m` | ROI spatial differencing and regression |
| `src/analyze/calculate_specific_storage_becker.m` | Poroelastic storage from regression slope |
| `src/filter/apply_filter.m` | Filter dispatcher (movmean, spatial median, etc.) |
| `src/plot/generate_plots.m` | Figure generation (101, 102, 103) |
| `scripts/run_PT01a_thesis_analysis.m` | PT-01a driver script |
| `scripts/run_PT01b_thesis_analysis.m` | PT-01b driver script |
| `scripts/run_PT01c_thesis_analysis.m` | PT-01c driver script |
| `scripts/run_roi_analysis_PT01a_100Hz.m` | PT-01a ROI analysis |
| `scripts/run_roi_analysis_PT01b.m` | PT-01b ROI analysis |
| `scripts/run_roi_analysis_PT01c.m` | PT-01c ROI analysis |

### 8.4 Configuration Keys

The toolkit uses **directory names** as dataset identifiers. Configuration lookups use `upper()` normalization. For each 100 Hz dataset, three configuration entries are required in `config.m`:

1. **Analysis window** — `config.analysis_windows.<DirectoryName>.start/.end`
2. **Dataset smoothing** — `config.dataset_smoothing.<UPPERCASE_NAME>.fs`, `.preprocessing_window_sec`, `.strain_rate_window_sec`, `.regression_window_sec`
3. **Manual plot bounds** — `config.manual_bounds.<DirectoryName>.*` (optional, for fixed colorbars)

---

## 9. Software Environment

- **MATLAB** R2023b or later (requires `movmean`, `cumtrapz`, `datetime` with timezone support)
- **Silixa TDMS reader** bundled in `src/prepare/`
- **Operating system:** Windows 10/11 (paths use backslash convention)
- **RAM requirement:** ≥ 16 GB recommended for 100 Hz datasets (~1.4 GB per matrix)

---

## References

Becker, M. W., Coleman, T. I., & Ciervo, C. C. (2020). Distributed Acoustic Sensing as a Distributed Hydraulic Sensor in Fractured Bedrock. *Water Resources Research*, 56, e2020WR028140. https://doi.org/10.1029/2020WR028140

Becker, M. W., Harris, B., & Pevzner, R. (2023). Characterization of aquifer poroelastic response to impulse and oscillatory well pressure using distributed acoustic sensing. *Geophysical Research Letters*, 50(1), e2022GL100904. https://doi.org/10.1029/2022GL100904

Bourdet, D., Ayoub, J. A., & Pirard, Y. M. (1989). Use of pressure derivative in well-test interpretation. *SPE Formation Evaluation*, 4(2), 293–302. https://doi.org/10.2118/12777-PA

Wang, H. F. (2000). *Theory of Linear Poroelasticity with Applications to Geomechanics and Hydrogeology* (Vol. 2). Princeton University Press.
