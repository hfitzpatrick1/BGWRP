#!/usr/bin/env python3
"""
Simple Cross Section: PM-07 to PT-01c Wells (As-Built Data)
Simplified version that definitely works
"""

import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
from matplotlib.patches import Rectangle
import matplotlib.patches as mpatches

def create_simple_cross_section():
    """Create simple but accurate cross section"""
    
    # Well Construction Data (As-Built)
    PM07 = {
        'position': 0,
        'total_depth': 810,
        'wells': {
            'PM-07-01': {'screen_top': 645, 'screen_bottom': 665, 'casing_bottom': 665},
            'PM-07-02': {'screen_top': 485, 'screen_bottom': 505, 'casing_bottom': 505},
            'PM-07-03': {'screen_top': 420, 'screen_bottom': 440, 'casing_bottom': 440},
            'PM-07-04': {'screen_top': 360, 'screen_bottom': 380, 'casing_bottom': 380},
            'PM-07-05': {'screen_top': 290, 'screen_bottom': 310, 'casing_bottom': 310}
        }
    }
    
    PT01c = {
        'position': 25,
        'bottom_casing': 320,
        'top_screen': 260,
        'bottom_screen': 310,
        'sump_depth': 310,
        'sump_bottom': 320
    }
    
    # Create figure
    fig, ax = plt.subplots(figsize=(16, 10))
    
    # Set axis properties
    ax.set_xlim(-7, 30)
    ax.set_ylim(0, 700)
    ax.invert_yaxis()
    ax.set_ylabel('Depth (ft)', fontsize=12)
    ax.set_xticks([])  # Remove x-axis ticks and labels
    ax.set_title('Cross Section: PM-07 to PT-01c', 
                 fontsize=16, fontweight='bold')
    
    # Add grid
    ax.grid(True, alpha=0.3)
    
    # Plot geological layers (actual geology from site)
    geology_layers = [
        (0, 125, 'Bellflower Aquiclude', '#CD5C5C'),  # Red
        (125, 375, 'Gage/Gardena Aquifer', '#FFD700'),  # Yellow
        (375, 650, 'Lynwood/Silverado Aquifer', '#4169E1'),  # Blue (extended to include brackish water)
        (650, 700, 'Lower San Pedro Formation', '#228B22')  # Green
    ]
    
    for top, bottom, name, color in geology_layers:
        rect = Rectangle((-7, top), 37, bottom - top, 
                        facecolor=color, alpha=0.6, edgecolor='black', linewidth=0.5)
        ax.add_patch(rect)
        ax.text(11.5, (top + bottom) / 2, name, 
                ha='center', va='center', fontsize=10, fontweight='bold')
    
    # Plot PM-07 wells (5 wells)
    plot_pm07_wells_simple(ax, PM07)
    
    # Plot PT-01c well
    plot_pt01c_well_simple(ax, PT01c)
    
    # Add depth markers (50 ft intervals) - lines only, no text labels
    for depth in [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650]:
        ax.axhline(y=depth, color='gray', linestyle='--', alpha=0.7)
    
    # Add well labels
    ax.text(PM07['position'], -40, 'PM-07 (5 Wells)', ha='center', va='center', 
            fontweight='bold', fontsize=14)
    ax.text(PT01c['position'], -40, 'PT-01c', ha='center', va='center', 
            fontweight='bold', fontsize=14)
    
    # Add distance annotation between wells at 150-200 ft depth
    mid_point = (PM07['position'] + PT01c['position']) / 2
    annotation_depth = 175  # Position at 175 ft depth
    
    # Add horizontal line between wells at 175 ft depth
    ax.plot([PM07['position'], PT01c['position']], [annotation_depth, annotation_depth], 'k-', linewidth=2)
    
    # Add "177 ft" annotation at 175 ft depth
    ax.annotate('177 ft', xy=(mid_point, annotation_depth), ha='center', va='center',
                fontsize=14, fontweight='bold', color='black',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='white', edgecolor='black', linewidth=2))
    
    # Summary block removed as requested
    
    # Create legend
    legend_elements = [
        mpatches.Patch(color='#C0C0C0', label='PM-07 Casing (2.5" PVC)'),
        mpatches.Patch(color='#4169E1', label='PM-07 Screen (0.020" slots)'),
        mpatches.Patch(color='#808080', label='PT-01c Casing (6" PVC)'),
        mpatches.Patch(color='#0000FF', label='PT-01c Screen (0.050" slots)'),
        mpatches.Patch(color='#000000', label='PT-01c Sump'),
        mpatches.Patch(color='red', label='Fiber Optic Cable')
    ]
    
    ax.legend(handles=legend_elements, loc='lower right', fontsize=9)
    
    plt.tight_layout()
    
    # Save the plot
    output_file = 'cross_section_PM07_PT01c_simple.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Cross section saved as: {output_file}")
    print("Note: To use in MATLAB, you can import this PNG file or use the Python script directly.")
    
    plt.close()
    
    print("Simple cross section created successfully!")
    print("PM-07: 5 wells with screens at different depths (290-665 ft)")
    print("PT-01c: Total depth 320 ft, Screen 260-310 ft, Sump 310-320 ft")

def plot_pm07_wells_simple(ax, well_data):
    """Plot PM-07 wells (5 wells)"""
    
    x_pos = well_data['position']
    well_width = 3
    well_spacing = 2
    
    # Arrange wells with PM-07-01 in center
    # Left: PM-07-05, PM-07-03 | Center: PM-07-01 | Right: PM-07-02, PM-07-04
    well_names = ['PM-07-05', 'PM-07-03', 'PM-07-01', 'PM-07-02', 'PM-07-04']
    
    for i, well_name in enumerate(well_names):
        well_x = x_pos + (i - 2) * well_spacing
        well_info = well_data['wells'][well_name]
        
        # Plot casing
        casing_rect = Rectangle((well_x - well_width/2, 0), 
                               well_width, well_info['casing_bottom'],
                               facecolor='#C0C0C0', edgecolor='black', linewidth=1.5)
        ax.add_patch(casing_rect)
        
        # Plot screen
        screen_rect = Rectangle((well_x - well_width/2, well_info['screen_top']), 
                               well_width, well_info['screen_bottom'] - well_info['screen_top'],
                               facecolor='#4169E1', edgecolor='blue', linewidth=1.5, alpha=0.7)
        ax.add_patch(screen_rect)
        
        # Add fiber optic cable (red line) for PM-07-01 only
        if well_name == 'PM-07-01':
            ax.plot([well_x, well_x], [0, well_info['casing_bottom']], 'r-', linewidth=3, label='Fiber Optic Cable' if well_name == 'PM-07-01' else "")
        
        # Add well label (simplified to just the number, no leading zeros)
        well_number = well_name.split('-')[-1]  # Extract the number (01, 02, etc.)
        well_number = str(int(well_number))  # Remove leading zeros (01 -> 1, 02 -> 2, etc.)
        ax.text(well_x, -20, well_number, ha='center', va='center', 
                fontsize=9, fontweight='bold')
        
        # Depth indicator removed as requested
        
        # Screen depth labels removed for cleaner appearance

def plot_pt01c_well_simple(ax, well_data):
    """Plot PT-01c well"""
    
    x_pos = well_data['position']
    well_width = 6
    
    # Plot casing
    casing_rect = Rectangle((x_pos - well_width/2, 0), 
                           well_width, well_data['bottom_casing'],
                           facecolor='#808080', edgecolor='black', linewidth=2)
    ax.add_patch(casing_rect)
    
    # Plot screen
    screen_rect = Rectangle((x_pos - well_width/2, well_data['top_screen']), 
                           well_width, well_data['bottom_screen'] - well_data['top_screen'],
                           facecolor='#0000FF', edgecolor='blue', linewidth=2, alpha=0.7)
    ax.add_patch(screen_rect)
    
    # Plot sump
    sump_rect = Rectangle((x_pos - well_width/2, well_data['sump_depth']), 
                         well_width, well_data['sump_bottom'] - well_data['sump_depth'],
                         facecolor='#000000', edgecolor='black', linewidth=2)
    ax.add_patch(sump_rect)
    
    # Center line removed as requested
    
    # Screen depth labels removed for cleaner appearance
    
    # Add pumping arrow - from screen up through casing
    screen_mid = (well_data['top_screen'] + well_data['bottom_screen']) / 2
    ax.annotate('', xy=(x_pos, 0), xytext=(x_pos, screen_mid),
                arrowprops=dict(arrowstyle='->', lw=5, color='black'))
    
    # Add horizontal arrow going toward the screen
    ax.annotate('', xy=(x_pos - well_width/2, screen_mid), xytext=(x_pos - well_width/2 - 8, screen_mid),
                arrowprops=dict(arrowstyle='->', lw=4, color='black'))
    
    # "Pumping" label removed as requested

if __name__ == "__main__":
    create_simple_cross_section()
