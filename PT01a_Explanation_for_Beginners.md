# Understanding the PT-01a DAS Analysis Script
## A Beginner's Guide

### What is this script doing?
This script analyzes data from a pump test using DAS (Distributed Acoustic Sensing) technology. Think of DAS like a very sensitive microphone that runs down a well, listening for tiny movements in the ground when water is pumped. This specific test (PT-01a) was conducted on November 7, 2023.

---

## Section 1: Setting Up the Basics

### What is a pump test?
- **Pump Test**: Scientists pump water from a well at different rates to see how the ground responds
- **Why?**: To understand how water flows through the ground and how the ground moves
- **PT-01a**: This is the name of this specific test (Pilot Test 01, Depth a)

### The Well Setup
```
Well Screen: 450-510 ft (this is where water is pumped from)
Starting Channel: 513 (where we begin counting measurements)
Channel spacing: 0.25 meters between each measurement point
```

**Think of it like this**: Imagine a very long, thin cable with thousands of tiny sensors spaced every 0.25 meters. This cable goes down the well and measures tiny movements, with special focus on the area between 450-510 feet deep.

---

## Section 2: Loading the Data

### What data are we loading?
1. **DAS Data** (`PM07_01a_1Hz.mat`): The raw measurements from the fiber
2. **Head Data** (`head_a_z5.mat`): Water level measurements from the well

### Key Parameters
- **C1 = 513**: The starting channel number (where we begin counting)
- **MperChan = 0.25**: Each channel represents 0.25 meters of depth



### Variable Naming
```matlab
data1Hz = decdata;  % Rename to match our script's variable naming
```
- **What this does**: The data file contains a variable called `decdata`, but we rename it to `data1Hz` to make the script easier to understand
- **Why?**: Different data files might use different variable names, so we standardize them

---

## Section 3: Time and Depth Calculations

### Time Setup
```matlab
DASStart = November 7, 2023 at 16:45:36 UTC
```
- **UTC**: Universal Time Coordinated (like Greenwich Mean Time)
- **Why important?**: All measurements need to be synchronized to the same time

### Depth Calculations
```matlab
depth = (channel_number - starting_channel - 1) × meters_per_channel
```

**Example**: 
- Channel 600: depth = (600 - 513 - 1) × 0.25 = 86 × 0.25 = 21.5 meters = 70.5 feet
- Channel 700: depth = (700 - 513 - 1) × 0.25 = 186 × 0.25 = 46.5 meters = 152.6 feet

---

## Section 4: Understanding the Data

### What is strain rate?
- **Strain Rate**: How fast the ground is moving at each point
- **Units**: nanometers per second (nm/s) - very tiny movements!
- **Think of it**: Like measuring how fast a rubber band is stretching

### Data Statistics
```matlab
meanampf = mean(data1Hz,1);  % Average strain rate over time
varampf = var(data1Hz,1);    % How much the strain rate varies
```

**Why calculate these?**
- **Mean**: Shows the typical movement at each depth
- **Variance**: Shows how "noisy" or variable the data is

---

## Section 5: Data Processing

### Integration: From Speed to Distance
```matlab
start_offset_min = 15;
integration_start = DASStart + minutes(start_offset_min);
start_idx = find(Tdas >= integration_start, 1);
subdata1Hz = data1Hz(start_idx:end,:);
intdata = cumtrapz(subdata1Hz,1);
```

**What is integration?**
- **Input**: Strain rate (how fast it's moving)
- **Output**: Strain (how much it has moved)
- **Analogy**: If speed is how fast you're driving, integration gives you how far you've traveled

**Why start from 15 minutes after the beginning?**
- The beginning of the data is often noisy
- We skip the first 15 minutes to get cleaner data for integration

### Detrending: Removing Drift
```matlab
dintdata = zeros(size(intdata));  % Pre-allocate
for nn = 1:size(intdata,2)
    dintdata(:,nn) = detrend(intdata(:,nn),2);
end
```

**What is detrending?**
- **Problem**: The data might have a gradual upward or downward trend (drift)
- **Solution**: Remove this trend to see the real changes
- **Analogy**: If you're measuring temperature but your thermometer is slowly drifting, detrending removes the drift to show real temperature changes

---

## Section 6: Creating Visualizations

### Figure 1: Raw Data Overview
```matlab
imagesc(data1Hz')
```
- **Purpose**: Shows all the raw data at once
- **What you see**: A heatmap where colors represent strain rate values
- **X-axis**: Time
- **Y-axis**: Depth (channels)
- **Colors**: Blue = low strain rate, Red = high strain rate

### Figure 2: Displacement Rate Analysis
**Top Plot (Waterfall)**
```matlab
pcolor(Tdas,depthft, mdata')
```
- **Purpose**: Shows filtered displacement rate over time and depth
- **Filtering**: `movmean(data1Hz,10,1)` smooths out noise
- **Color Range**: 0.25 to 0.55 nm/s (fixed range)
- **Reference Lines**: Show when different pump rates started
- **Zone Lines**: White dashed lines at 450 ft and 510 ft showing the pumping zone

**Bottom Plot (Time Series)**
```matlab
yyaxis left
plot(TheadLocal, Drawdownft, 'b-')  % Blue line = water level
yyaxis right  
plot(TdasLocal, single_disp_rate, 'r-') % Red line = single channel ground movement
```
- **Purpose**: Compare water level changes with ground movement
- **Single Channel Displacement Rate**: Uses one specific channel in the pumping zone (450-510 ft)
- **Dual Y-axis**: Left for water level, right for ground movement
- **Time Zone**: Shows local time (America/Los_Angeles) for easier interpretation

### Figure 3: Strain Analysis
**Similar to Figure 2, but shows:**
- **Top**: Strain (total movement) over time and depth
- **Bottom**: Single channel strain vs. water level
- **Units**: nm/m (nanometers per meter)
- **Color Range**: -295 to -275 nm/m (fixed range)

---

## Section 7: Key Time Windows

### Pump Test Schedule
```
17:00 UTC: Start 50 gpm pumping
18:00 UTC: Increase to 80 gpm
19:00 UTC: Increase to 110 gpm  
20:00 UTC: Increase to 140 gpm
21:00 UTC: Stop pumping (recovery)
```

### Analysis Window
```
20:44-20:49 UTC: 5-minute period during recovery
```
- **Why this window?**: Shows how the ground responds when pumping stops
- **What to look for**: Changes in strain rate and strain as water levels recover
- **Short window**: Focuses on a specific moment during recovery

---

## Section 8: Single Channel vs. Zone Averaging

### What is single channel analysis?
```matlab
zone_min_ft = 450;  % lower bound of zone of interest
zone_max_ft = 510;  % upper bound of zone of interest
target_depth_ft = (zone_min_ft + zone_max_ft)/2;  % center of zone of interest
[~, channel_idx] = min(abs(depthft - target_depth_ft));
single_disp_rate = mdata(:, channel_idx);
```

**Why use single channel?**
- **More detailed**: Shows the response at one specific point
- **Less averaging**: Preserves local variations and details
- **Cleaner signal**: No averaging-related smoothing

**vs. Zone Averaging (like PT-01b)**
- **PT-01b**: Uses average of all channels between 350-400 ft
- **PT-01a**: Uses one specific channel at the center of 450-510 ft zone
- **Trade-off**: Single channel shows more detail but might be noisier

---

## Section 9: What to Look For

### Good Data Signs
- **Smooth patterns**: Gradual changes rather than random spikes
- **Depth correlation**: Changes that make sense with depth
- **Time correlation**: Changes that relate to pumping activities
- **Channel response**: Clear response at the selected channel

### Problem Signs
- **Vertical bands**: System-wide noise affecting all depths
- **Random spikes**: Individual channel problems
- **No correlation**: Data doesn't relate to pumping activities
- **No channel response**: No clear changes at the selected channel

---

## Section 10: Common Questions

### Why focus on 450-510 ft?
- This is the well screen zone where water is pumped from
- The ground should respond most strongly in this area
- It's the most relevant depth for understanding the pump test

### Why use single channel instead of zone averaging?
- **More detailed**: Shows the response at one specific point
- **Less averaging**: Preserves local variations and details
- **Cleaner signal**: No averaging-related smoothing

### What do the colors mean?
- **Blue**: Low strain rate (little movement)
- **Green/Yellow**: Medium strain rate
- **Red**: High strain rate (lots of movement)

### Why the short time window (20:44-20:49)?
- This period shows a specific moment during recovery
- Short window (5 minutes) shows detailed changes
- Focuses on a particular response pattern

### Why fixed color ranges?
- **Displacement Rate**: 0.25 to 0.55 nm/s
- **Strain**: -295 to -275 nm/m
- **Benefits**: Consistent scaling across different plots and time windows

---

## Section 11: Key Differences from Other Tests

### Date and Time
- **PT-01a**: November 7, 2023
- **PT-01b**: October 31, 2023
- **PT-01c**: October 24, 2023

### Pumping Zone
- **PT-01a**: 450-510 ft (single channel)
- **PT-01b**: 350-400 ft (zone averaging)
- **PT-01c**: Single channel at specific depth

### Analysis Method
- **PT-01a**: Single channel displacement rate and strain
- **PT-01b**: Zone-averaged displacement rate and strain
- **PT-01c**: Single channel displacement rate and strain

### Time Window
- **PT-01a**: 20:44-20:49 UTC (5 minutes)
- **PT-01b**: 19:25-20:28 UTC (63 minutes)
- **PT-01c**: 19:14-19:18 UTC (4 minutes)

---

## Section 12: Data Quality and Filtering

### Simple Filtering Approach
```matlab
mdata = movmean(data1Hz, 10, 1);
```
- **What this does**: Applies a 10-sample moving average filter
- **Why simple?**: Previous attempts with complex filtering were too aggressive
- **Benefits**: Reduces noise while preserving the signal

### Dynamic Drawdown Limits
```matlab
if isempty(window_drawdown)
    drawdown_ylim = [min(Drawdownft) max(Drawdownft)];
else
    drawdown_ylim = [min(window_drawdown) max(window_drawdown)];
end
```
- **What this does**: Automatically adjusts the y-axis limits for the drawdown plot
- **Why?**: Ensures the water level data is always visible
- **Fallback**: If no data in the window, uses the full range

---

## Section 13: Next Steps

### What this analysis tells us
1. **Ground response**: How the subsurface moves during pumping
2. **Hydraulic properties**: How water flows through the ground
3. **Well performance**: How the well responds to different pumping rates
4. **Local behavior**: How one specific point in the pumping zone responds

### How to interpret results
- **Look for patterns**: Do changes relate to pumping rates?
- **Check channel response**: Does the selected channel show clear changes?
- **Compare with theory**: Do the results match expected behavior?
- **Compare with other tests**: How does this compare to PT-01b and PT-01c?

---

## Summary

This script takes raw DAS measurements and transforms them into meaningful visualizations that help scientists understand:
- How the ground moves during pump tests
- How water flows through the subsurface
- How the well performs under different conditions
- How a specific point in the pumping zone (450-510 ft) responds

The key is understanding that we're measuring tiny movements (nanometers) over time to understand large-scale groundwater behavior, with focus on a single representative point in the zone where water is actually being pumped from.
