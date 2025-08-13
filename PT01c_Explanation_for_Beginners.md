# Understanding the PT-01c DAS Analysis Script
## A Beginner's Guide

### What is this script doing?
This script analyzes data from a pump test using DAS (Distributed Acoustic Sensing) technology. Think of DAS like a very sensitive microphone that runs down a well, listening for tiny movements in the ground when water is pumped.

---

## Section 1: Setting Up the Basics

### What is a pump test?
- **Pump Test**: Scientists pump water from a well at different rates to see how the ground responds
- **Why?**: To understand how water flows through the ground and how the ground moves
- **PT-01c**: This is the name of this specific test (Pilot Test 01, Depth c)

### The Well Setup
```
Well depth: About 80 meters deep
Fiber length: 223 meters total
Surface stickup: 54.5 feet (16.6 meters) above ground
Effective length: 207 meters below ground
Channel spacing: 0.25 meters between each measurement point
```

**Think of it like this**: Imagine a very long, thin cable with thousands of tiny sensors spaced every 0.25 meters. This cable goes down the well and measures tiny movements.

---

## Section 2: Loading the Data

### What data are we loading?
1. **DAS Data** (`PM07_01c_1Hz.mat`): The raw measurements from the fiber
2. **Head Data** (`head_c_z5.mat`): Water level measurements from the well

### Key Parameters
- **C1 = 110**: The starting channel number (where we begin counting)
- **MperChan = 0.25**: Each channel represents 0.25 meters of depth

---

## Section 3: Time and Depth Calculations

### Time Setup
```matlab
DASStart = October 24, 2023 at 15:02:36 UTC
```
- **UTC**: Universal Time Coordinated (like Greenwich Mean Time)
- **Why important?**: All measurements need to be synchronized to the same time

### Depth Calculations
```matlab
depth = (channel_number - starting_channel - 1) × meters_per_channel
```

**Example**: 
- Channel 200: depth = (200 - 110 - 1) × 0.25 = 89 × 0.25 = 22.25 meters
- Channel 300: depth = (300 - 110 - 1) × 0.25 = 189 × 0.25 = 47.25 meters

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
intdata = cumtrapz(subdata1Hz,1);
```

**What is integration?**
- **Input**: Strain rate (how fast it's moving)
- **Output**: Strain (how much it has moved)


**Why start from sample 15085?**
- The beginning of the data is often noisy
- We skip the first 15,085 measurements to get cleaner data

### Detrending: Removing Drift
```matlab
dintdata = detrend(intdata,2);
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
- **Color Range**: -0.25 to 0.15 nm/s

**Bottom Plot (Time Series)**
```matlab
yyaxis left
plot(Thead, Drawdownft, 'b-')  % Blue line = water level
yyaxis right  
plot(Tdas, mdata(:,492), 'r-') % Red line = ground movement
```
- **Purpose**: Compare water level changes with ground movement
- **Channel 492**: One specific depth point we're monitoring
- **Dual Y-axis**: Left for water level, right for ground movement

### Figure 3: Strain Analysis
**Similar to Figure 2, but shows:**
- **Top**: Strain (total movement) over time and depth
- **Bottom**: Strain at channel 492 vs. water level
- **Units**: nm/m (nanometers per meter)

---

## Section 7: Key Time Windows

### Pump Test Schedule
```
15:10 UTC: Start 50 gpm pumping
16:10 UTC: Increase to 80 gpm
17:10 UTC: Increase to 110 gpm  
18:10 UTC: Increase to 140 gpm
19:10 UTC: Stop pumping (recovery)
```

### Analysis Window
```
19:14-19:18 UTC: 4-minute period during recovery
```
- **Why this window?**: Shows how the ground responds when pumping stops
- **What to look for**: Changes in strain rate and strain as water levels recover

---

## Section 8: What to Look For

### Good Data Signs
- **Smooth patterns**: Gradual changes rather than random spikes
- **Depth correlation**: Changes that make sense with depth
- **Time correlation**: Changes that relate to pumping activities

### Problem Signs
- **Vertical bands**: System-wide noise affecting all depths
- **Random spikes**: Individual channel problems
- **No correlation**: Data doesn't relate to pumping activities

---

## Section 9: Common Questions

### Why use channel 492?
- It's at a good depth for monitoring
- Shows clear responses to pumping
- Representative of the overall behavior

### Why filter the data?
- Raw data is often noisy
- Filtering removes random variations
- Makes real patterns easier to see

### What do the colors mean?
- **Blue**: Low strain rate (little movement)
- **Green/Yellow**: Medium strain rate
- **Red**: High strain rate (lots of movement)

---

## Section 10: Next Steps

### What this analysis tells us
1. **Ground response**: How the subsurface moves during pumping
2. **Hydraulic properties**: How water flows through the ground
3. **Well performance**: How the well responds to different pumping rates

### How to interpret results
- **Look for patterns**: Do changes relate to pumping rates?
- **Check depth trends**: Do deeper areas respond differently?
- **Compare with theory**: Do the results match expected behavior?

---

## Summary

This script takes raw DAS measurements and transforms them into meaningful visualizations that help scientists understand:
- How the ground moves during pump tests
- How water flows through the subsurface
- How the well performs under different conditions

The key is understanding that we're measuring tiny movements (nanometers) over time to understand large-scale groundwater behavior.
