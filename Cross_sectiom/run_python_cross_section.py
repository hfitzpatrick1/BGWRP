#!/usr/bin/env python3
"""
Run Python Cross Section: PM-07 to PT-01c Wells (As-Built Data)
"""

import sys
import os

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import and run the cross section creation
from create_cross_section_python import create_cross_section_python

if __name__ == "__main__":
    print("Creating accurate cross section from PM-07 to PT-01c using Python...")
    print("This version provides better control over visualization and more realistic well construction representation.")
    print()
    
    try:
        create_cross_section_python()
        print()
        print("Python cross section complete!")
        print("Features:")
        print("  - Accurate 177 ft spacing between wells")
        print("  - Visible PM-07 well with proper casing and screen")
        print("  - Detailed PT-01c construction with all materials")
        print("  - Realistic borehole reaming visualization")
        print("  - Color-coded geological layers")
        print("  - Professional engineering visualization")
    except Exception as e:
        print(f"Error creating cross section: {e}")
        print("Make sure you have matplotlib installed: pip install matplotlib")


