#!/usr/bin/env python3
"""Preview LAS file with full depth range"""

import sys
from preview_las_data import preview_las_curves

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python preview_full_depth.py <las_file>")
        sys.exit(1)
    
    las_file = sys.argv[1]
    
    # Preview with full depth range (-500 to 1000 ft to capture everything)
    preview_las_curves(las_file, depth_min=-500, depth_max=1000)


