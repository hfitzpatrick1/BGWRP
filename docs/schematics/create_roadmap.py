import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle, Ellipse
import numpy as np

# Create figure with better aspect ratio for presentation
fig, ax = plt.subplots(1, 1, figsize=(16, 9))
ax.set_xlim(0, 12)
ax.set_ylim(0, 11)
ax.axis('off')

# Title
ax.text(6, 10.2, 'Distributed Fiber Optic Sensing: Roadmap', 
        fontsize=22, fontweight='bold', ha='center')

# ========== SECTION 1: THE PROBLEM ==========
problem_box = FancyBboxPatch((0.8, 7), 3.2, 2.8, 
                             boxstyle="round,pad=0.15", 
                             edgecolor='#dc2626', facecolor='#fee2e2', linewidth=2.5)
ax.add_patch(problem_box)
ax.text(2.4, 9.3, 'THE PROBLEM', fontsize=15, fontweight='bold', ha='center', color='#991b1b')

# Brackish plume visualization
plume = Ellipse((2.4, 8.4), 1.8, 1.0, angle=0, 
                facecolor='#3b82f6', alpha=0.6, edgecolor='#1e40af', linewidth=1.5)
ax.add_patch(plume)
ax.text(2.4, 8.4, 'Brackish\nGroundwater\nPlume', fontsize=10, ha='center', va='center', 
        fontweight='bold', color='white')

# Seawater intrusion arrow (keep inside box)
arrow1 = FancyArrowPatch((3.5, 8.4), (3.9, 8.4), 
                        arrowstyle='->', mutation_scale=20, 
                        color='#1e40af', linewidth=2.5)
ax.add_patch(arrow1)
ax.text(3.7, 8.7, 'Seawater\nIntrusion', fontsize=9, ha='center', color='#1e40af', fontweight='bold')

ax.text(2.4, 7.5, '• 660,000 acre-feet\n• Trapped since 1960s\n• Needs remediation', 
        fontsize=9, ha='center', va='top')

# ========== SECTION 2: THE SETUP ==========
setup_box = FancyBboxPatch((4.4, 7), 3.2, 2.8, 
                          boxstyle="round,pad=0.15", 
                          edgecolor='#059669', facecolor='#d1fae5', linewidth=2.5)
ax.add_patch(setup_box)
ax.text(6, 9.3, 'THE SETUP', fontsize=15, fontweight='bold', ha='center', color='#047857')

# Observation well
well_obs = Rectangle((5.35, 7.7), 0.28, 0.95, facecolor='#6b7280', edgecolor='black', linewidth=1.5)
ax.add_patch(well_obs)
ax.text(5.49, 7.55, 'PM-07', fontsize=8, ha='center', fontweight='bold')

# Fiber optic cable in well
fiber = Rectangle((5.4, 7.7), 0.11, 0.95, facecolor='#fbbf24', edgecolor='#f59e0b', linewidth=1)
ax.add_patch(fiber)
ax.text(5.49, 8.8, 'Fiber Optic\nCable', fontsize=8, ha='center', fontweight='bold', 
        bbox=dict(boxstyle='round', facecolor='white', alpha=0.9, pad=0.2))

# Pumping well
well_pump = Rectangle((6.55, 7.85), 0.28, 0.8, facecolor='#dc2626', edgecolor='black', linewidth=1.5)
ax.add_patch(well_pump)
ax.text(6.69, 7.7, 'PT-01c', fontsize=8, ha='center', fontweight='bold', color='white')

# Flow arrows toward pumping well (fewer, better spaced)
for y in [8.1, 8.3, 8.5]:
    arrow_flow = FancyArrowPatch((5.63, y), (6.55, y), 
                                 arrowstyle='->', mutation_scale=12, 
                                 color='#3b82f6', linewidth=1.3, alpha=0.7)
    ax.add_patch(arrow_flow)

ax.text(6, 7.55, '• Observation well:\n  177 ft away\n• Continuous measurements\n• 0.25 m resolution', 
        fontsize=8.5, ha='center', va='top')

# ========== SECTION 3: THE TOOLS ==========
tools_box = FancyBboxPatch((8, 7), 3.2, 2.8, 
                          boxstyle="round,pad=0.15", 
                          edgecolor='#7c3aed', facecolor='#ede9fe', linewidth=2.5)
ax.add_patch(tools_box)
ax.text(9.6, 9.3, 'THE TOOLS', fontsize=15, fontweight='bold', ha='center', color='#6d28d9')

# DTS icon
dts_circle = Circle((8.7, 8.5), 0.28, facecolor='#3b82f6', edgecolor='#1e40af', linewidth=2.5)
ax.add_patch(dts_circle)
ax.text(8.7, 8.5, 'DTS', fontsize=9.5, ha='center', va='center', color='white', fontweight='bold')
ax.text(8.7, 7.85, 'Temperature\nSensing', fontsize=8.5, ha='center', va='top', fontweight='bold')

# DAS icon
das_circle = Circle((10.5, 8.5), 0.28, facecolor='#10b981', edgecolor='#047857', linewidth=2.5)
ax.add_patch(das_circle)
ax.text(10.5, 8.5, 'DAS', fontsize=9.5, ha='center', va='center', color='white', fontweight='bold')
ax.text(10.5, 7.85, 'Strain Rate\nSensing', fontsize=8.5, ha='center', va='top', fontweight='bold')

ax.text(9.6, 7.5, '• Distributed sensing\n• One cable, two measurements\n• Real-time monitoring', 
        fontsize=9, ha='center', va='top')

# ========== ARROWS CONNECTING SECTIONS ==========
arrow1 = FancyArrowPatch((4, 8.5), (4.4, 8.5), 
                        arrowstyle='->', mutation_scale=30, 
                        color='#6b7280', linewidth=3.5)
ax.add_patch(arrow1)

arrow2 = FancyArrowPatch((7.6, 8.5), (8, 8.5), 
                        arrowstyle='->', mutation_scale=30, 
                        color='#6b7280', linewidth=3.5)
ax.add_patch(arrow2)

# ========== SECTION 4: THE GOALS ==========
goals_box = FancyBboxPatch((2.5, 4), 7, 2.2, 
                          boxstyle="round,pad=0.2", 
                          edgecolor='#f59e0b', facecolor='#fef3c7', linewidth=3)
ax.add_patch(goals_box)
ax.text(6, 5.8, 'WHAT WE LEARN', fontsize=17, fontweight='bold', ha='center', color='#92400e')

# Goal items
goals = [
    'Vertical connectivity',
    'Storage properties',
    'Aquifer heterogeneity',
    'Flow paths'
]

x_positions = [3.5, 5, 6.5, 8]
for i, (goal, x) in enumerate(zip(goals, x_positions)):
    circle = Circle((x, 4.8), 0.3, facecolor='#f59e0b', edgecolor='#d97706', linewidth=2.5)
    ax.add_patch(circle)
    ax.text(x, 4.8, '✓', fontsize=16, ha='center', va='center', color='white', fontweight='bold')
    ax.text(x, 4.2, goal, fontsize=11, ha='center', va='top', fontweight='bold')

# Arrow from tools to goals
arrow3 = FancyArrowPatch((9.6, 7), (6, 6.2), 
                        arrowstyle='->', mutation_scale=35, 
                        color='#6b7280', linewidth=3.5, linestyle='--')
ax.add_patch(arrow3)

# ========== BOTTOM SUMMARY ==========
summary_box = FancyBboxPatch((1.5, 0.8), 9, 2.5, 
                            boxstyle="round,pad=0.25", 
                            edgecolor='#1f2937', facecolor='#f9fafb', linewidth=2.5)
ax.add_patch(summary_box)

ax.text(6, 2.8, 'Research Question:', fontsize=16, fontweight='bold', ha='center', color='#1f2937')
ax.text(6, 2.3, 'How can distributed fiber optic sensing characterize aquifer connectivity', 
        fontsize=14, ha='center', style='italic', color='#374151')
ax.text(6, 2, 'and storage properties during pump tests?', 
        fontsize=14, ha='center', style='italic', color='#374151')

ax.text(3, 1.3, 'Problem:\nBrackish\nplume', fontsize=13, ha='center', color='#dc2626', fontweight='bold')
ax.text(6, 1.3, 'Method:\nDTS + DAS\nobservation well', fontsize=13, ha='center', color='#7c3aed', fontweight='bold')
ax.text(9, 1.3, 'Goal:\nAquifer\ncharacterization', fontsize=13, ha='center', color='#059669', fontweight='bold')

plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
plt.savefig('C:/Coding/BGWRP/docs/schematics/roadmap_schematic.png', dpi=300, bbox_inches='tight', pad_inches=0.1)
plt.savefig('C:/Coding/BGWRP/docs/schematics/roadmap_schematic.svg', format='svg', bbox_inches='tight', pad_inches=0.1)
print("Roadmap schematic saved!")

