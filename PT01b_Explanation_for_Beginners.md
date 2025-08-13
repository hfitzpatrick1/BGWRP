# Understanding the PT-01b DAS Analysis Script
## A Beginner's Guide

### What is this script doing?
This script analyzes data from a pump test using DAS (Distributed Acoustic Sensing) technology. Think of DAS like a very sensitive microphone that runs down a well, listening for tiny movements in the ground when water is pumped. This specific test (PT-01b) was conducted on October 31, 2023.

---

## Section 1: Setting Up the Basics

### What is a pump test?
- **Pump Test**: Scientists pump water from a well at different rates to see how the ground responds
- **Why?**: To understand how water flows through the ground and how the ground moves
- **PT-01b**: This is the name of this specific test (Pilot Test 01, Depth b)

### The Well Setup
```
Well Screen: 350-400 ft (this is where water is pumped from)
Starting Channel: 513 (where we begin counting measurements)
Channel spacing: 0.25 meters between each measurement point
```

**Think of it like this**: Imagine a very long, thin cable with thousands of tiny sensors spaced every 0.25 meters. This cable goes down the well and measures tiny movements, with special focus on the area between 350-400 feet deep.

---

## Section 2: Loading the Data

### What data are we loading?
1. **DAS Data** (`PM07_01b_1Hz.mat`): The raw measurements from the fiber
2. **Head Data** (`head_b_z5.mat`): Water level measurements from the well

### Key Parameters
- **C1 = 513**: The starting channel number (where we begin counting)
- **MperChan = 0.25**: Each channel represents 0.25 meters of depth

**Simple analogy**: If you have a ruler that's 100 cm long with marks every 0.25 cm, C1=513 means you start counting from the 513th mark, and each mark represents 0.25 cm.

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
DASStart = October 31, 2023 at 15:29:36 UTC
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
- **Color Range**: -1.0 to 0 nm/s
- **Reference Lines**: Show when different pump rates started
- **Zone Lines**: White dashed lines at 350 ft and 400 ft showing the pumping zone

**Bottom Plot (Time Series)**
```matlab
yyaxis left
plot(TheadLocal, Drawdownft, 'b-')  % Blue line = water level
yyaxis right  
plot(TdasLocal, avg_disp_rate, 'r-') % Red line = average ground movement
```
- **Purpose**: Compare water level changes with ground movement
- **Average Displacement Rate**: Uses the average across the entire pumping zone (350-400 ft)
- **Dual Y-axis**: Left for water level, right for ground movement
- **Time Zone**: Shows local time (America/Los_Angeles) for easier interpretation

### Figure 3: Strain Analysis
**Similar to Figure 2, but shows:**
- **Top**: Strain (total movement) over time and depth
- **Bottom**: Average strain across the pumping zone vs. water level
- **Units**: nm/m (nanometers per meter)
- **Color Range**: -2200 to -1880 nm/m

---

## Section 7: Key Time Windows

### Pump Test Schedule
```
15:30 UTC: Start 50 gpm pumping
16:30 UTC: Increase to 80 gpm
17:30 UTC: Increase to 110 gpm  
18:30 UTC: Increase to 140 gpm
19:30 UTC: Stop pumping (recovery)
```

### Analysis Window
```
19:25-20:28 UTC: 63-minute period during recovery
```
- **Why this window?**: Shows how the ground responds when pumping stops
- **What to look for**: Changes in strain rate and strain as water levels recover

---

## Section 8: Zone Averaging vs. Single Channel

### What is zone averaging?
```matlab
zone_min_ft = 350;  % lower bound of zone of interest
zone_max_ft = 400;  % upper bound of zone of interest
idxZone = depthft >= zone_min_ft & depthft <= zone_max_ft;
avg_disp_rate = mean(mdata(:, idxZone), 2, 'omitnan');
```

**Why use zone averaging?**
- **More representative**: Averages across the entire pumping zone
- **Less noisy**: Reduces individual channel noise
- **Better signal**: Shows the overall response of the pumping zone

**vs. Single Channel (like PT-01c)**
- **PT-01c**: Uses channel 492 specifically
- **PT-01b**: Uses average of all channels between 350-400 ft
- **Trade-off**: Zone average is less noisy but might miss local details

---

## Section 9: What to Look For

### Good Data Signs
- **Smooth patterns**: Gradual changes rather than random spikes
- **Depth correlation**: Changes that make sense with depth
- **Time correlation**: Changes that relate to pumping activities
- **Zone response**: Clear response in the 350-400 ft pumping zone

### Problem Signs
- **Vertical bands**: System-wide noise affecting all depths
- **Random spikes**: Individual channel problems
- **No correlation**: Data doesn't relate to pumping activities
- **No zone response**: No clear changes in the pumping zone

---

## Section 10: Common Questions

### Why focus on 350-400 ft?
- This is the well screen zone where water is pumped from
- The ground should respond most strongly in this area
- It's the most relevant depth for understanding the pump test

### Why use zone averaging instead of a single channel?
- **Less noisy**: Averages out individual channel problems
- **More representative**: Shows the overall zone response
- **Better for analysis**: More reliable for understanding the test

### What do the colors mean?
- **Blue**: Low strain rate (little movement)
- **Green/Yellow**: Medium strain rate
- **Red**: High strain rate (lots of movement)

### Why the different time window (19:25-20:28)?
- This period shows the recovery phase clearly
- Longer window (63 minutes) shows more of the recovery process
- Good balance between detail and overall trends

---

## Section 11: Key Differences from PT-01c

### Date and Time
- **PT-01b**: October 31, 2023
- **PT-01c**: October 24, 2023

### Pumping Zone
- **PT-01b**: 350-400 ft (zone averaging)
- **PT-01c**: Single channel at specific depth

### Analysis Method
- **PT-01b**: Zone-averaged displacement rate and strain
- **PT-01c**: Single channel displacement rate and strain

### Time Window
- **PT-01b**: 19:25-20:28 UTC (63 minutes)
- **PT-01c**: 19:14-19:18 UTC (4 minutes)

---

## Section 12: Next Steps

### What this analysis tells us
1. **Ground response**: How the subsurface moves during pumping
2. **Hydraulic properties**: How water flows through the ground
3. **Well performance**: How the well responds to different pumping rates
4. **Zone behavior**: How the pumping zone specifically responds

### How to interpret results
- **Look for patterns**: Do changes relate to pumping rates?
- **Check zone response**: Does the 350-400 ft zone show clear changes?
- **Compare with theory**: Do the results match expected behavior?
- **Compare with other tests**: How does this compare to PT-01a and PT-01c?

---

## Summary

This script takes raw DAS measurements and transforms them into meaningful visualizations that help scientists understand:
- How the ground moves during pump tests
- How water flows through the subsurface
- How the well performs under different conditions
- How the specific pumping zone (350-400 ft) responds

The key is understanding that we're measuring tiny movements (nanometers) over time to understand large-scale groundwater behavior, with special focus on the zone where water is actually being pumped from.
