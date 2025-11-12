#!/usr/bin/env python3
"""
Preview LAS file data as it would appear in WellCAD
Shows depth on Y-axis and each curve on X-axis in separate subplots
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

def parse_las_file(filename):
    """Parse LAS file and return data as pandas DataFrame"""
    
    # Read the file
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    # Find the data section
    data_start = None
    curve_names = []
    
    for i, line in enumerate(lines):
        if line.strip().startswith('~A'):
            # Extract curve names from the ~A line
            curve_line = line.strip().replace('~A', '').strip()
            curve_names = curve_line.split()
            data_start = i + 1
            break
    
    if data_start is None:
        raise ValueError("Could not find data section in LAS file")
    
    # Read the data
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
                    continue  # Skip lines with non-numeric data
    
    # Create DataFrame
    df = pd.DataFrame(data_rows, columns=curve_names)
    return df

def preview_las_curves(filename, depth_min=0, depth_max=665):
    """Create WellCAD-style preview of LAS curves"""
    
    # Parse the LAS file
    df = parse_las_file(filename)
    
    # Get depth column (should be first column)
    depth_col = df.columns[0]
    depth = df[depth_col].values
    
    # Filter data to specified depth range
    depth_mask = (depth >= depth_min) & (depth <= depth_max)
    df_filtered = df[depth_mask].copy()
    depth_filtered = df_filtered[depth_col].values
    
    # Get curve columns (all except depth)
    curve_cols = [col for col in df_filtered.columns if col != depth_col]
    
    # Create subplots - one for each curve
    n_curves = len(curve_cols)
    fig, axes = plt.subplots(1, n_curves, figsize=(4*n_curves, 12), sharey=True)
    
    # Handle single curve case
    if n_curves == 1:
        axes = [axes]
    
    # Plot each curve
    for i, curve_name in enumerate(curve_cols):
        ax = axes[i]
        curve_data = df_filtered[curve_name].values
        
        # Plot curve with depth on Y-axis (inverted to match well log convention)
        ax.plot(curve_data, depth_filtered, 'b-', linewidth=1)
        ax.set_xlabel(curve_name)
        ax.set_title(f'{curve_name}')
        ax.grid(True, alpha=0.3)
        
        # Set Y-axis to show depth increasing downward (well log convention)
        ax.invert_yaxis()
        ax.set_ylim(depth_max, depth_min)  # Set explicit Y limits
        
        # Auto-scale X-axis based on data in the event zone (175-340 ft) for better visibility
        event_mask = (depth_filtered >= 175) & (depth_filtered <= 340)
        if np.any(event_mask):
            event_data = curve_data[event_mask]
            if len(event_data) > 0:
                # Use event zone data to set X-axis scale
                x_min_event = np.min(event_data)
                x_max_event = np.max(event_data)
                x_range_event = x_max_event - x_min_event
                
                # Add some padding around event zone range
                padding = 0.2 * x_range_event if x_range_event > 0 else 0.1 * abs(x_max_event)
                ax.set_xlim(x_min_event - padding, x_max_event + padding)
            else:
                # Fallback to full data range with padding
                x_min, x_max = np.min(curve_data), np.max(curve_data)
                x_range = x_max - x_min
                ax.set_xlim(x_min - 0.1*x_range, x_max + 0.1*x_range)
        else:
            # Fallback to full data range with padding
            x_min, x_max = np.min(curve_data), np.max(curve_data)
            x_range = x_max - x_min
            ax.set_xlim(x_min - 0.1*x_range, x_max + 0.1*x_range)
    
    # Set Y-label only on leftmost plot
    axes[0].set_ylabel(f'{depth_col}')
    
    # Add main title with depth range info
    fig.suptitle(f'LAS File Preview: {filename}\nDepth Range: {depth_min}-{depth_max} ft (X-axis scaled for event zone 175-340 ft)', 
                 fontsize=14, fontweight='bold')
    
    # Adjust layout
    plt.tight_layout()
    plt.subplots_adjust(top=0.92)
    
    # Show plot
    plt.show()
    
    # Print summary statistics
    print(f"\n=== LAS FILE SUMMARY ===")
    print(f"File: {filename}")
    print(f"Depth range: {depth.min():.2f} to {depth.max():.2f} ft")
    print(f"Number of data points: {len(depth)}")
    print(f"Curves: {', '.join(curve_cols)}")
    
    print(f"\n=== CURVE STATISTICS ===")
    for curve in curve_cols:
        data = df[curve].values
        print(f"{curve:12s}: min={data.min():8.5f}, max={data.max():8.5f}, mean={data.mean():8.5f}")

if __name__ == "__main__":
    import sys
    
    # Default to the LAS file if no argument provided
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        filename = "PT01c_Recovery_short_DAS_Variance.las"
    
    try:
        preview_las_curves(filename)
    except Exception as e:
        print(f"Error: {e}")
        print(f"Usage: python {sys.argv[0]} [las_file]")
