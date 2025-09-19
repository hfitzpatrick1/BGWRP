#!/usr/bin/env python3
"""
Create Cross Section: PM-07 to PT-01c Wells (As-Built Data)
Python implementation with accurate well construction visualization
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
from matplotlib.patches import Rectangle, FancyBboxPatch
import matplotlib.patches as mpatches

def create_cross_section_python():
    """Create accurate cross section with as-built well construction data"""
    
    # Well Construction Data (As-Built)
    # PM-07 well data (AS-BUILT from construction diagram)
    PM07 = {
        'position': 0,           # ft (left side)
        'total_depth': 810,      # ft (total borehole depth)
        'casing_diameter': 2.5,  # inches (2.5-inch PVC)
        'screen_slot_size': 0.020, # inches
        
        # Five wells with different screen intervals
        'wells': {
            'PM-07-01': {'screen_top': 645, 'screen_bottom': 665, 'casing_bottom': 665},
            'PM-07-02': {'screen_top': 485, 'screen_bottom': 505, 'casing_bottom': 505},
            'PM-07-03': {'screen_top': 420, 'screen_bottom': 440, 'casing_bottom': 440},
            'PM-07-04': {'screen_top': 360, 'screen_bottom': 380, 'casing_bottom': 380},
            'PM-07-05': {'screen_top': 290, 'screen_bottom': 310, 'casing_bottom': 310}
        },
        
        # Borehole reaming information
        'borehole_22inch_top': 0,     # ft
        'borehole_22inch_bottom': 20, # ft
        'borehole_17inch_top': 20,    # ft
        'borehole_17inch_bottom': 390, # ft
        'borehole_14_75inch_top': 390, # ft
        'borehole_14_75inch_bottom': 515, # ft
        'borehole_10_625inch_top': 515, # ft
        'borehole_10_625inch_bottom': 805, # ft
        
        # Construction materials (estimated depths based on typical construction)
        'cement_bentonite_grout_top': 0,     # ft
        'cement_bentonite_grout_bottom': 280, # ft (varies by well)
        'bentonite_seal_thickness': 10,      # ft (typical thickness)
        'filter_pack_thickness': 20,         # ft (typical thickness)
    }
    
    # PT-01c well data (AS-BUILT from construction diagram)
    PT01c = {
        'top_casing': 0,       # ft
        'bottom_casing': 320,  # ft (total well depth)
        'top_screen': 260,     # ft
        'bottom_screen': 310,  # ft
        'casing_diameter': 6,  # inches (6-inch PVC)
        'screen_slot_size': 0.050, # inches
        'sump_depth': 310,     # ft (sump starts at screen bottom)
        'sump_bottom': 320,    # ft (sump extends to well bottom)
        'position': 177,       # ft (PM-07 is 177 ft NW of PT-01c)
        
        # Construction Materials (from as-built)
        'cement_bentonite_grout_top': 0,     # ft
        'cement_bentonite_grout_bottom': 240, # ft
        'bentonite_seal_top': 240,           # ft
        'bentonite_seal_bottom': 250,        # ft
        'filter_pack_top': 250,              # ft
        'filter_pack_bottom': 320,           # ft
        
        # Borehole reaming information
        'borehole_22inch_top': 0,    # ft
        'borehole_22inch_bottom': 20, # ft
        'borehole_14_75inch_top': 20, # ft
        'borehole_14_75inch_bottom': 320, # ft
    }
    
    # Create figure
    fig, ax = plt.subplots(figsize=(16, 10))
    
    # Set axis properties
    ax.set_xlim(-50, 227)  # 177 + 50 for padding
    ax.set_ylim(0, 700)
    ax.invert_yaxis()  # Depth increases downward
    ax.set_xlabel('Distance (ft)', fontsize=12)
    ax.set_ylabel('Depth (ft)', fontsize=12)
    ax.set_title('Accurate Cross Section: PM-07 to PT-01c Wells (As-Built Data)', 
                 fontsize=16, fontweight='bold')
    
    # Add grid
    ax.grid(True, alpha=0.3)
    ax.set_axisbelow(True)
    
    # Define geological layers
    geology_layers = [
        (0, 50, 'Topsoil/Sand', '#D2B48C'),
        (50, 150, 'Clay/Silt', '#8B7355'),
        (150, 300, 'Sand/Gravel', '#F5DEB3'),
        (300, 450, 'Clay', '#654321'),
        (450, 600, 'Sandstone', '#A9A9A9'),
        (600, 665, 'Bedrock', '#2F4F4F')
    ]
    
    # Plot geological layers
    for top, bottom, name, color in geology_layers:
        rect = Rectangle((-50, top), 277, bottom - top, 
                        facecolor=color, alpha=0.6, edgecolor='black', linewidth=0.5)
        ax.add_patch(rect)
        
        # Add layer label
        ax.text(88.5, (top + bottom) / 2, name, 
                ha='center', va='center', fontsize=10, fontweight='bold')
    
    # Plot PM-07 wells (5 zones)
    plot_pm07_wells(ax, PM07)
    
    # Plot PT-01c well
    plot_pt01c_well(ax, PT01c)
    
    # Add depth markers
    depth_markers = [100, 200, 300, 400, 500, 600]
    for depth in depth_markers:
        ax.axhline(y=depth, color='gray', linestyle='--', alpha=0.7, linewidth=1)
        ax.text(-45, depth, f'{depth} ft', ha='right', va='center', 
                color='gray', fontsize=10)
    
    # Add distance markers
    x_markers = [0, 44, 89, 133, 177]
    for x in x_markers:
        ax.axvline(x=x, color='gray', linestyle=':', alpha=0.5)
        ax.text(x, -30, f'{x} ft', ha='center', va='center', 
                color='gray', fontsize=9)
    
    # Add well labels
    ax.text(PM07['position'], -40, 'PM-07', ha='center', va='center', 
            fontweight='bold', fontsize=14)
    ax.text(PT01c['position'], -40, 'PT-01c', ha='center', va='center', 
            fontweight='bold', fontsize=14)
    
    # Add construction summary
    summary_text = (
        'Well Construction Summary (As-Built):\n\n'
        'PM-07 (5 Wells):\n'
        f'  Total Depth: {PM07["total_depth"]} ft\n'
        f'  2.5" PVC Casing with 0.020" slot screens\n'
        f'  PM-07-01: Screen {PM07["wells"]["PM-07-01"]["screen_top"]}-{PM07["wells"]["PM-07-01"]["screen_bottom"]} ft\n'
        f'  PM-07-02: Screen {PM07["wells"]["PM-07-02"]["screen_top"]}-{PM07["wells"]["PM-07-02"]["screen_bottom"]} ft\n'
        f'  PM-07-03: Screen {PM07["wells"]["PM-07-03"]["screen_top"]}-{PM07["wells"]["PM-07-03"]["screen_bottom"]} ft\n'
        f'  PM-07-04: Screen {PM07["wells"]["PM-07-04"]["screen_top"]}-{PM07["wells"]["PM-07-04"]["screen_bottom"]} ft\n'
        f'  PM-07-05: Screen {PM07["wells"]["PM-07-05"]["screen_top"]}-{PM07["wells"]["PM-07-05"]["screen_bottom"]} ft\n\n'
        'PT-01c (As-Built):\n'
        f'  Total Depth: {PT01c["bottom_casing"]} ft\n'
        f'  6" PVC Casing: 0 - {PT01c["bottom_casing"]} ft\n'
        f'  Screen: {PT01c["top_screen"]} - {PT01c["bottom_screen"]} ft (0.050" slots)\n'
        f'  Sump: {PT01c["sump_depth"]} - {PT01c["sump_bottom"]} ft\n'
        f'  Cement-Bentonite Grout: 0 - {PT01c["cement_bentonite_grout_bottom"]} ft\n'
        f'  Bentonite Seal: {PT01c["bentonite_seal_top"]} - {PT01c["bentonite_seal_bottom"]} ft\n'
        f'  Filter Pack: {PT01c["filter_pack_top"]} - {PT01c["filter_pack_bottom"]} ft\n\n'
        'PM-07 Borehole Reaming:\n'
        f'  22" diameter: 0 - {PM07["borehole_22inch_bottom"]} ft\n'
        f'  17" diameter: {PM07["borehole_17inch_top"]} - {PM07["borehole_17inch_bottom"]} ft\n'
        f'  14.75" diameter: {PM07["borehole_14_75inch_top"]} - {PM07["borehole_14_75inch_bottom"]} ft\n'
        f'  10.625" diameter: {PM07["borehole_10_625inch_top"]} - {PM07["borehole_10_625inch_bottom"]} ft\n\n'
        'PT-01c Borehole Reaming:\n'
        f'  22" diameter: 0 - {PT01c["borehole_22inch_bottom"]} ft\n'
        f'  14.75" diameter: {PT01c["borehole_14_75inch_top"]} - {PT01c["borehole_14_75inch_bottom"]} ft'
    )
    
    ax.text(88.5, 50, summary_text, ha='center', va='top', fontsize=9,
            bbox=dict(boxstyle='round,pad=0.5', facecolor='white', edgecolor='black'))
    
    # Create legend
    legend_elements = [
        mpatches.Patch(color='#C0C0C0', label='PM-07 Casing (2.5" PVC)'),
        mpatches.Patch(color='#4169E1', label='PM-07 Screen (0.020" slots)'),
        mpatches.Patch(color='#2F2F2F', label='PT-01c Casing (6" PVC)'),
        mpatches.Patch(color='#0000FF', label='PT-01c Screen (0.050" slots)'),
        mpatches.Patch(color='#000000', label='PT-01c Sump'),
        mpatches.Patch(color='#F0E68C', label='Cement-Bentonite Grout'),
        mpatches.Patch(color='#D2691E', label='Bentonite Seal'),
        mpatches.Patch(color='#DEB887', label='Filter Pack'),
        mpatches.Patch(color='#D3D3D3', label='22" Borehole'),
        mpatches.Patch(color='#A9A9A9', label='14.75" Borehole'),
        mpatches.Patch(color='#B0B0B0', label='17" Borehole'),
        mpatches.Patch(color='#808080', label='10.625" Borehole')
    ]
    
    ax.legend(handles=legend_elements, loc='upper right', fontsize=9)
    
    plt.tight_layout()
    
    # Save the plot instead of showing it to avoid freezing
    output_file = 'cross_section_PM07_PT01c.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Cross section saved as: {output_file}")
    
    # Also save as PDF for better quality
    output_file_pdf = 'cross_section_PM07_PT01c.pdf'
    plt.savefig(output_file_pdf, bbox_inches='tight')
    print(f"Cross section also saved as: {output_file_pdf}")
    
    plt.close()  # Close the figure to free memory
    
    print("Accurate cross section created successfully!")
    print(f"PM-07: 5 wells with screens at different depths (290-665 ft), Total depth {PM07['total_depth']} ft")
    print(f"PT-01c: Total depth {PT01c['bottom_casing']} ft, Screen {PT01c['top_screen']}-{PT01c['bottom_screen']} ft, Sump {PT01c['sump_depth']}-{PT01c['sump_bottom']} ft")

def plot_pm07_wells(ax, well_data):
    """Plot PM-07 wells with realistic construction (5 wells)"""
    
    x_pos = well_data['position']
    well_width = 3  # Width for individual wells
    well_spacing = 4  # Spacing between wells
    
    # Plot borehole reaming (background)
    plot_pm07_borehole(ax, well_data)
    
    # Plot each of the 5 wells
    well_names = ['PM-07-01', 'PM-07-02', 'PM-07-03', 'PM-07-04', 'PM-07-05']
    
    for i, well_name in enumerate(well_names):
        well_x = x_pos + (i - 2) * well_spacing  # Center wells around x_pos
        well_info = well_data['wells'][well_name]
        
        # Plot casing (2.5" diameter)
        casing_rect = Rectangle((well_x - well_width/2, 0), 
                               well_width, well_info['casing_bottom'],
                               facecolor='#C0C0C0', edgecolor='black', linewidth=1.5)
        ax.add_patch(casing_rect)
        
        # Plot screen
        screen_rect = Rectangle((well_x - well_width/2, well_info['screen_top']), 
                               well_width, well_info['screen_bottom'] - well_info['screen_top'],
                               facecolor='#4169E1', edgecolor='blue', linewidth=1.5, 
                               alpha=0.7)
        ax.add_patch(screen_rect)
        
        # Add center line
        ax.plot([well_x, well_x], [0, well_info['casing_bottom']], 
                'k-', linewidth=2)
        
        # Add well label at top
        ax.text(well_x, -20, well_name, ha='center', va='center', 
                fontsize=9, fontweight='bold')
        
        # Add screen depth labels
        ax.text(well_x - well_width/2 - 8, well_info['screen_top'], 
                f'{well_info["screen_top"]} ft', 
                ha='right', va='center', fontsize=8, fontweight='bold', color='blue')
        ax.text(well_x - well_width/2 - 8, well_info['screen_bottom'], 
                f'{well_info["screen_bottom"]} ft', 
                ha='right', va='center', fontsize=8, fontweight='bold', color='blue')

def plot_pm07_borehole(ax, well_data):
    """Plot PM-07 borehole reaming (background)"""
    
    x_pos = well_data['position']
    borehole_width = 20  # Total width of borehole area
    
    # Plot 22-inch borehole (0-20 ft)
    borehole_22_rect = Rectangle((x_pos - borehole_width/2, well_data['borehole_22inch_top']), 
                                borehole_width, well_data['borehole_22inch_bottom'] - well_data['borehole_22inch_top'],
                                facecolor='#D3D3D3', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_22_rect)
    
    # Plot 17-inch borehole (20-390 ft)
    borehole_17_rect = Rectangle((x_pos - borehole_width*0.8/2, well_data['borehole_17inch_top']), 
                                borehole_width*0.8, well_data['borehole_17inch_bottom'] - well_data['borehole_17inch_top'],
                                facecolor='#B0B0B0', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_17_rect)
    
    # Plot 14.75-inch borehole (390-515 ft)
    borehole_14_75_rect = Rectangle((x_pos - borehole_width*0.7/2, well_data['borehole_14_75inch_top']), 
                                   borehole_width*0.7, well_data['borehole_14_75inch_bottom'] - well_data['borehole_14_75inch_top'],
                                   facecolor='#A9A9A9', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_14_75_rect)
    
    # Plot 10.625-inch borehole (515-805 ft)
    borehole_10_625_rect = Rectangle((x_pos - borehole_width*0.5/2, well_data['borehole_10_625inch_top']), 
                                    borehole_width*0.5, well_data['borehole_10_625inch_bottom'] - well_data['borehole_10_625inch_top'],
                                    facecolor='#808080', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_10_625_rect)
    
    # Add borehole diameter labels
    ax.text(x_pos + borehole_width/2 + 5, 10, '22"', ha='left', va='center', 
            fontsize=8, fontweight='bold', color='red')
    ax.text(x_pos + borehole_width*0.8/2 + 5, 205, '17"', ha='left', va='center', 
            fontsize=8, fontweight='bold', color='red')
    ax.text(x_pos + borehole_width*0.7/2 + 5, 452, '14.75"', ha='left', va='center', 
            fontsize=8, fontweight='bold', color='red')
    ax.text(x_pos + borehole_width*0.5/2 + 5, 660, '10.625"', ha='left', va='center', 
            fontsize=8, fontweight='bold', color='red')

def plot_pt01c_well(ax, well_data):
    """Plot PT-01c well with detailed as-built construction"""
    
    x_pos = well_data['position']
    well_width = 10  # Make it clearly visible
    
    # Plot 22-inch borehole (0-20 ft)
    borehole_22_rect = Rectangle((x_pos - well_width, well_data['borehole_22inch_top']), 
                                well_width * 2, well_data['borehole_22inch_bottom'] - well_data['borehole_22inch_top'],
                                facecolor='#D3D3D3', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_22_rect)
    
    # Plot 14.75-inch borehole (20-320 ft)
    borehole_14_75_rect = Rectangle((x_pos - well_width*0.7, well_data['borehole_14_75inch_top']), 
                                   well_width * 1.4, well_data['borehole_14_75inch_bottom'] - well_data['borehole_14_75inch_top'],
                                   facecolor='#A9A9A9', edgecolor='black', linewidth=1, alpha=0.3)
    ax.add_patch(borehole_14_75_rect)
    
    # Plot cement-bentonite grout (0-240 ft)
    grout_rect = Rectangle((x_pos - well_width*0.6, well_data['cement_bentonite_grout_top']), 
                          well_width * 1.2, well_data['cement_bentonite_grout_bottom'] - well_data['cement_bentonite_grout_top'],
                          facecolor='#F0E68C', edgecolor='black', linewidth=1, alpha=0.8)
    ax.add_patch(grout_rect)
    
    # Plot bentonite seal (240-250 ft)
    seal_rect = Rectangle((x_pos - well_width*0.6, well_data['bentonite_seal_top']), 
                         well_width * 1.2, well_data['bentonite_seal_bottom'] - well_data['bentonite_seal_top'],
                         facecolor='#D2691E', edgecolor='black', linewidth=1, alpha=0.9)
    ax.add_patch(seal_rect)
    
    # Plot filter pack (250-320 ft)
    filter_rect = Rectangle((x_pos - well_width*0.6, well_data['filter_pack_top']), 
                           well_width * 1.2, well_data['filter_pack_bottom'] - well_data['filter_pack_top'],
                           facecolor='#DEB887', edgecolor='black', linewidth=1, alpha=0.7)
    ax.add_patch(filter_rect)
    
    # Plot casing (6-inch PVC)
    casing_rect = Rectangle((x_pos - well_width/4, well_data['top_casing']), 
                           well_width/2, well_data['bottom_casing'] - well_data['top_casing'],
                           facecolor='#2F2F2F', edgecolor='black', linewidth=2)
    ax.add_patch(casing_rect)
    
    # Plot screen (260-310 ft)
    screen_rect = Rectangle((x_pos - well_width/4, well_data['top_screen']), 
                           well_width/2, well_data['bottom_screen'] - well_data['top_screen'],
                           facecolor='#0000FF', edgecolor='blue', linewidth=2, 
                           linestyle='--', alpha=0.7)
    ax.add_patch(screen_rect)
    
    # Plot sump (310-320 ft)
    sump_rect = Rectangle((x_pos - well_width/4, well_data['sump_depth']), 
                         well_width/2, well_data['sump_bottom'] - well_data['sump_depth'],
                         facecolor='#000000', edgecolor='black', linewidth=2)
    ax.add_patch(sump_rect)
    
    # Add center line
    ax.plot([x_pos, x_pos], [well_data['top_casing'], well_data['bottom_casing']], 
            'k-', linewidth=3)
    
    # Add borehole diameter labels
    ax.text(x_pos + well_width/2 + 5, 10, '22"', ha='left', va='center', 
            fontsize=9, fontweight='bold', color='red')
    ax.text(x_pos + well_width*0.7/2 + 5, 170, '14.75"', ha='left', va='center', 
            fontsize=9, fontweight='bold', color='red')
    
    # Add depth labels
    ax.text(x_pos + well_width/2 + 15, well_data['top_casing'], '0 ft', 
            ha='left', va='center', fontsize=11, fontweight='bold')
    ax.text(x_pos + well_width/2 + 15, well_data['bottom_casing'], 
            f'{well_data["bottom_casing"]} ft', 
            ha='left', va='center', fontsize=11, fontweight='bold')
    ax.text(x_pos + well_width/2 + 15, well_data['top_screen'], 
            f'{well_data["top_screen"]} ft', 
            ha='left', va='center', fontsize=11, fontweight='bold', color='blue')
    ax.text(x_pos + well_width/2 + 15, well_data['bottom_screen'], 
            f'{well_data["bottom_screen"]} ft', 
            ha='left', va='center', fontsize=11, fontweight='bold', color='blue')
    ax.text(x_pos + well_width/2 + 15, well_data['sump_depth'], 
            f'{well_data["sump_depth"]} ft', 
            ha='left', va='center', fontsize=11, fontweight='bold', color='black')

if __name__ == "__main__":
    create_cross_section_python()
