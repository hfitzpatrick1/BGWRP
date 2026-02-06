# Aquatroll 700 Pump Test Data Processing Guide

## Quick Start

You have noisy Aquatroll 700 data from an observation well. Here's where to start:

### Step 1: Prepare Your Data

1. **Export your Aquatroll data as CSV** from the Win-Situ software
2. Make sure it includes at minimum:
   - Date/Time column
   - Pressure column (psi or kPa)
   - (Optional) Temperature column
   - (Optional) Water level/depth column

3. **Place the CSV file** in a known location, for example:
   ```
   C:\Coding\BGWRP\data\aquatroll\
   ```

### Step 2: Run the Processing Script

1. **Open the processing script**:
   ```matlab
   edit process_aquatroll_pump_test.m
   ```

2. **Update three key sections** (marked with "USER INPUT REQUIRED"):

   **Section A** (Line ~23): Point to your data file
   ```matlab
   data_file = 'C:\Coding\BGWRP\data\aquatroll\YOUR_ACTUAL_FILE.csv';
   ```

   **Section B** (Lines ~63-66): Match your column names
   ```matlab
   time_col = 'Date_Time';        % Your actual time column name
   pressure_col = 'Pressure_psi'; % Your actual pressure column name
   temp_col = 'Temperature_C';    % Your actual temperature column name
   ```

   **Section C** (Line ~194): Set if you have barometric data
   ```matlab
   has_baro_data = false; % Change to true if you have it
   ```

3. **Run the script**:
   ```matlab
   process_aquatroll_pump_test()
   ```

### Step 3: Review the Results

The script will generate:

1. **Two figure windows**:
   - Raw data with outlier detection
   - Cleaned data with noise removal

2. **Quality metrics** printed to console:
   - RMS noise level
   - Signal-to-noise ratio
   - Data completeness

3. **Output files** in `data/aquatroll/processed/`:
   - `aquatroll_cleaned.csv` - Cleaned data for import to other tools
   - `aquatroll_cleaned.mat` - MATLAB format for further analysis

## What the Script Does

### Noise Removal Steps:

1. **Outlier Detection**: Uses moving median absolute deviation (MAD) to identify spikes
2. **Physical Validation**: Removes impossible values
3. **Gap Filling**: Interpolates small gaps (< 5 points)
4. **Smoothing**: Applies moving average + Savitzky-Golay filter
5. **Barometric Correction**: (Optional) Removes atmospheric pressure effects

### Common Aquatroll Noise Sources:

- **Electronic spikes**: Sudden jumps in pressure readings
- **Cable noise**: Electromagnetic interference from nearby equipment
- **Temperature effects**: Sensor drift with temperature changes
- **Atmospheric pressure**: Changes in barometric pressure
- **Pump vibration**: Mechanical vibrations transmitted through water column

## Tuning the Filters

If the default filtering is too aggressive or not enough:

### Outlier Detection (Line ~124)
```matlab
outlier_threshold = 3; % Increase to keep more data, decrease to remove more
```

### Smoothing Window (Line ~173)
```matlab
smooth_window = 5; % Increase for more smoothing, decrease for less
```

### Savitzky-Golay Filter (Lines ~179-183)
```matlab
savgol_order = 2;        % Polynomial order (1-5 typical)
savgol_framelen = 11;    # Window size (must be odd)
```

## Pump Test Analysis Integration

Once your data is cleaned, you can integrate it with your existing workflow:

```matlab
% Load cleaned data
load('data/aquatroll/processed/aquatroll_cleaned.mat');

% Now you can use 'drawdown_ft' and 'timestamps' for pump test analysis
% This matches the format of your existing head data processing

% Example: Create a structure matching your PT01a/b/c format
head_data = struct();
head_data.Date = timestamps;
head_data.Drawdownft = drawdown_ft;
head_data.Depthft = YOUR_SENSOR_DEPTH; % ft below ground surface

% Save in your standard format
save('data/head/head_obs_well.mat', 'head_data');
```

## Troubleshooting

### "Data file not found"
- Check the path in line ~23
- Use forward slashes `/` or escaped backslashes `\\`

### "Missing required columns"
- Run the script once to see your actual column names
- Update lines ~63-66 to match exactly (case-sensitive!)

### "Too much data removed"
- Increase `outlier_threshold` (line ~124)
- Reduce smoothing window (line ~173)

### "Still too noisy"
- Decrease `outlier_threshold`
- Increase smoothing window
- Check for barometric effects - you may need correction

## Advanced: Barometric Correction

If you have a separate barometer dataset:

1. Load barometric data
2. Interpolate to match Aquatroll timestamps
3. Apply correction:
   ```matlab
   % Typical correction
   reference_baro = 14.7; % psi (sea level)
   baro_effect = baro_pressure - reference_baro;
   pressure_corrected = pressure_raw - baro_effect;
   ```

Barometric efficiency typically 0.2-0.8 for confined aquifers.

## Questions to Answer

Before running, gather this info:

1. **What's your static water level?** (for drawdown calculation)
2. **What's your sensor depth?** (ft below ground surface)
3. **Do you have barometric data?** (for pressure correction)
4. **What's your aquifer type?** (confined, unconfined, leaky)
5. **When did pumping start/stop?** (to validate drawdown timing)

## Next Steps After Cleaning

1. **Plot drawdown vs time** - Verify pump test phases visible
2. **Check for interference** - Other wells pumping nearby?
3. **Calculate derivative** - dh/dt for aquifer analysis
4. **Match with DAS data** - Correlate with your existing fiber optic measurements
5. **Estimate hydraulic parameters** - Use Cooper-Jacob, Theis, etc.

---

Need help? Check your existing scripts:
- `src/prepare/process_head_data.m` - Similar workflow for piezometer data
- `combined_filtering_approach.m` - Advanced filtering examples
