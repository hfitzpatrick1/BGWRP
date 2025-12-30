#!/usr/bin/env python3
"""
Compare all PT01b LAS files side by side
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

def parse_las_file(filename):
    """Parse LAS file and return data as pandas DataFrame"""
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    data_start = None
    curve_names = []
    
    for i, line in enumerate(lines):
        if line.strip().startswith('~A'):
            curve_line = line.strip().replace('~A', '').strip()
            curve_names = curve_line.split()
            data_start = i + 1
            break
    
    if data_start is None:
        raise ValueError(f"Could not find data section in {filename}")
    
    data_lines = lines[data_start:]
    data_rows = []
    
    for line in data_lines:
        line = line.strip()
        if line and not line.startswith('#'):
            values = line.split()
            if len(values) == len(curve_names):
                try:
                    data_rows.append([float(v) for v in values])
                except ValueError:
                    continue
    
    df = pd.DataFrame(data_rows, columns=curve_names)
    return df, curve_names

# List of files to compare
files = [
    ('PT01b_Recovery_short_DAS_Mean.las', 'Mean (raw)'),
    ('PT01b_Recovery_short_DAS_Processed.las', 'Snapshot\n(19:30:29)'),
    ('PT01b_Recovery_short_DAS_Profile.las', 'Time->Depth\n(Ch 970)'),
    ('PT01b_Recovery_short_DAS_Mean_Response.las', 'Mean Abs\nResponse'),
    ('PT01b_Recovery_short_DAS_Shifted.las', 'Shifted to\nScreen')
]

# Create figure with subplots
fig, axes = plt.subplots(1, 5, figsize=(20, 10), sharey=True)

# Plot each file
for idx, (filename, label) in enumerate(files):
    try:
        df, curve_names = parse_las_file(filename)
        
        # Get depth and data columns
        depth_col = df.columns[0]
        data_col = df.columns[1]
        
        depth = df[depth_col].values
        data = df[data_col].values
        
        ax = axes[idx]
        ax.plot(data, depth, 'b-', linewidth=1)
        ax.set_xlabel(label, fontsize=10, fontweight='bold')
        ax.set_title(f'{data_col}\n({len(depth)} pts)', fontsize=8)
        ax.grid(True, alpha=0.3)
        ax.invert_yaxis()
        ax.set_ylim(665, 0)  # Set depth range to 0-665 ft
        
        # Scale x-axis based on zone of interest (200-500 ft)
        zone_mask = (depth >= 200) & (depth <= 500)
        if np.any(zone_mask):
            zone_data = data[zone_mask]
            x_min = np.min(zone_data)
            x_max = np.max(zone_data)
            x_range = x_max - x_min
            if x_range > 0:
                ax.set_xlim(x_min - 0.1*x_range, x_max + 0.1*x_range)
        
        # Add screen interval markers (350-400 ft)
        ax.axhline(y=350, color='r', linestyle='--', linewidth=1, alpha=0.5)
        ax.axhline(y=400, color='r', linestyle='--', linewidth=1, alpha=0.5)
        
        # Print stats
        print(f"\n{filename}:")
        print(f"  Depth range: {depth.min():.1f} to {depth.max():.1f} ft")
        print(f"  Data range: {data.min():.5f} to {data.max():.5f}")
        print(f"  Mean: {data.mean():.5f}")
        
        # Check screen interval
        screen_mask = (depth >= 350) & (depth <= 400)
        if np.any(screen_mask):
            screen_data = data[screen_mask]
            print(f"  Screen (350-400 ft): {screen_data.min():.5f} to {screen_data.max():.5f}")
        
    except Exception as e:
        ax = axes[idx]
        ax.text(0.5, 0.5, f'Error:\n{str(e)}', 
                ha='center', va='center', transform=ax.transAxes)
        ax.set_xlabel(label, fontsize=10, fontweight='bold')

# Set common y-axis label
axes[0].set_ylabel('Depth (ft)', fontsize=12, fontweight='bold')

# Add main title
fig.suptitle('PT01b LAS File Comparison - All 5 Versions\n(Red lines: Screen interval 350-400 ft)', 
             fontsize=14, fontweight='bold')

plt.tight_layout()
plt.subplots_adjust(top=0.92)
plt.show()

print("\n" + "="*80)
print("SUMMARY:")
print("1. Mean (raw): Raw uncalibrated mean - INCORRECT VALUES")
print("2. Snapshot (19:30:29): Spatial profile at peak recovery time (30s smoothed)")
print("3. Time->Depth (Ch 970): Time series from 374 ft channel mapped to depth")
print("4. Mean Abs Response: Mean absolute response during recovery window")
print("5. Shifted to Screen: Snapshot shifted so peak aligns with screen (107-122 m)")
print("="*80)

