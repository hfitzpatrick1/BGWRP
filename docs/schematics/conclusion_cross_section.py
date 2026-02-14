"""
Generate Conclusion Slide: Annotated cross-section with key findings.
Left: PM-07 cross-section with geological layers and wells
Right: Dark panel with storage results and key findings
Bottom: Gold banner with takeaway
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Rectangle
import numpy as np

fig = plt.figure(figsize=(20, 11), facecolor='white', dpi=150)

# ============================================================================
# TITLE
# ============================================================================
fig.text(0.5, 0.975, 'Conclusion: DAS + DTS Results at PM-07 Across Three Pump Tests',
         ha='center', va='top', fontsize=22, fontweight='bold',
         fontfamily='sans-serif',
         bbox=dict(boxstyle='square,pad=0.4', facecolor='#2D2D2D', edgecolor='none'),
         color='white')

# ============================================================================
# LEFT PANEL: Cross-Section (~55%)
# ============================================================================
ax = fig.add_axes([0.02, 0.08, 0.54, 0.85])
ax.set_xlim(0, 100)
ax.set_ylim(175, 0)  # Depth increases downward
ax.set_ylabel('Depth (m)', fontsize=14, fontweight='bold')
ax.tick_params(axis='y', labelsize=11)
ax.set_xticks([])
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['bottom'].set_visible(False)

# --- Geological layers ---
# Bellflower Aquiclude: 0-52 m
ax.axhspan(0, 52, color='#e9b3b3', alpha=0.7, zorder=0)
ax.text(85, 26, 'Bellflower\nAquiclude', ha='center', va='center', fontsize=11,
        fontweight='bold', color='#5a2020', style='italic')

# Gage-Gardena Aquifer: 52-91 m
ax.axhspan(52, 91, color='#ffe792', alpha=0.7, zorder=0)
ax.text(85, 71.5, 'Gage-Gardena\nAquifer', ha='center', va='center', fontsize=11,
        fontweight='bold', color='#7a6520', style='italic')

# Lynwood/Silverado Aquifer: 91-140 m
ax.axhspan(91, 140, color='#97b7ff', alpha=0.5, zorder=0)
ax.text(85, 115, 'Lynwood/\nSilverado\nAquifer', ha='center', va='center', fontsize=11,
        fontweight='bold', color='#2a4080', style='italic')

# Lynwood/Silverado Brackish: 140-170 m
ax.axhspan(140, 170, color='#6e6c97', alpha=0.5, zorder=0)
ax.text(85, 155, 'Lynwood/\nSilverado\nBrackish', ha='center', va='center', fontsize=10,
        fontweight='bold', color='#2a2850', style='italic')

# Formation boundaries
for depth in [52, 91, 140]:
    ax.axhline(depth, color='#888888', linewidth=1.0, linestyle='-', alpha=0.6, zorder=1)

# --- DAS Response Zones (highlighted bands) ---
# PT-01c response zone (79-94 m)
ax.axhspan(79, 94, color='#ff6b35', alpha=0.15, zorder=1)
ax.plot([5, 72], [79, 79], '--', color='#ff6b35', linewidth=1.2, alpha=0.6)
ax.plot([5, 72], [94, 94], '--', color='#ff6b35', linewidth=1.2, alpha=0.6)

# PT-01b response zone (107-122 m)
ax.axhspan(107, 122, color='#ff6b35', alpha=0.12, zorder=1)
ax.plot([5, 72], [107, 107], '--', color='#ff6b35', linewidth=1.0, alpha=0.5)
ax.plot([5, 72], [122, 122], '--', color='#ff6b35', linewidth=1.0, alpha=0.5)

# PT-01a response zone (137-155 m)
ax.axhspan(137, 155, color='#ff6b35', alpha=0.12, zorder=1)
ax.plot([5, 72], [137, 137], '--', color='#ff6b35', linewidth=1.0, alpha=0.5)
ax.plot([5, 72], [155, 155], '--', color='#ff6b35', linewidth=1.0, alpha=0.5)

# --- Wells ---
well_width = 3.5
casing_color = '#6b7280'
screen_color = '#c8e0ff'

# PM-07
pm07_x = 18
ax.add_patch(Rectangle((pm07_x - 1.5, 0), 3, 170, facecolor=casing_color, edgecolor='#374151', linewidth=1.5, zorder=3))
# Fiber optic line
ax.plot([pm07_x + 1.8, pm07_x + 1.8], [0, 170], color='#ff2c55', linewidth=2.5, zorder=4)
ax.text(pm07_x, -3, 'PM-07', ha='center', va='bottom', fontsize=13, fontweight='bold', zorder=5)
ax.text(pm07_x, -0.5, '(5-zone)', ha='center', va='bottom', fontsize=9, color='#666666', zorder=5)

# PT-01c (x=38)
pt01c_x = 38
ax.add_patch(Rectangle((pt01c_x - well_width/2, 0), well_width, 79, facecolor=casing_color, edgecolor='#374151', linewidth=1.5, zorder=3))
ax.add_patch(Rectangle((pt01c_x - well_width/2, 79), well_width, 15, facecolor=screen_color, edgecolor='#4a5661', linewidth=1.5, zorder=3, hatch='//'))
ax.text(pt01c_x, 3, 'PT-01c', ha='center', va='top', fontsize=12, fontweight='bold', color='white', zorder=5,
        bbox=dict(boxstyle='round,pad=0.2', facecolor='#374151', alpha=0.9, edgecolor='none'))
ax.text(pt01c_x + 4, 86.5, '79-94 m', ha='left', va='center', fontsize=10, fontweight='bold', zorder=5)

# PT-01a (x=52)
pt01a_x = 52
ax.add_patch(Rectangle((pt01a_x - well_width/2, 0), well_width, 137, facecolor=casing_color, edgecolor='#374151', linewidth=1.5, zorder=3))
ax.add_patch(Rectangle((pt01a_x - well_width/2, 137), well_width, 18, facecolor=screen_color, edgecolor='#4a5661', linewidth=1.5, zorder=3, hatch='//'))
ax.text(pt01a_x, 3, 'PT-01a', ha='center', va='top', fontsize=12, fontweight='bold', color='white', zorder=5,
        bbox=dict(boxstyle='round,pad=0.2', facecolor='#374151', alpha=0.9, edgecolor='none'))
ax.text(pt01a_x + 4, 146, '137-155 m', ha='left', va='center', fontsize=10, fontweight='bold', zorder=5)

# PT-01b (x=66)
pt01b_x = 66
ax.add_patch(Rectangle((pt01b_x - well_width/2, 0), well_width, 107, facecolor=casing_color, edgecolor='#374151', linewidth=1.5, zorder=3))
ax.add_patch(Rectangle((pt01b_x - well_width/2, 107), well_width, 15, facecolor=screen_color, edgecolor='#4a5661', linewidth=1.5, zorder=3, hatch='//'))
ax.text(pt01b_x, 3, 'PT-01b', ha='center', va='top', fontsize=12, fontweight='bold', color='white', zorder=5,
        bbox=dict(boxstyle='round,pad=0.2', facecolor='#374151', alpha=0.9, edgecolor='none'))
ax.text(pt01b_x + 4, 114.5, '107-122 m', ha='left', va='center', fontsize=10, fontweight='bold', zorder=5)

# --- DTS null result annotations (X marks between pumped zones) ---
# Between PT-01c (94m) and PT-01b (107m): X at 100m
# Between PT-01b (122m) and PT-01a (137m): X at 130m
# Below PT-01a (155m) at Lynwood-Silverado/Brackish boundary: X at 158m
# X marks to the LEFT of PM-07, labels centered between pumped zones
dts_annotations = [
    # X at PT-01c depth (86.5m), label between PT-01c and PT-01b (~100m)
    {'x_depth': 86.5, 'label_depth': 100},
    # X at PT-01b depth (114.5m), label between PT-01b and PT-01a (~130m)
    {'x_depth': 114.5, 'label_depth': 130},
    # X at PT-01a depth (146m), label below PT-01a (~158m)
    {'x_depth': 146, 'label_depth': 158},
]

for ann in dts_annotations:
    # X mark to the left of PM-07 (PM-07 is at x=18)
    x_pos = 8
    depth = ann['x_depth']
    size = 4
    ax.plot([x_pos - size, x_pos + size], [depth - size, depth + size], '-', color='#dc2626', linewidth=3.5, zorder=5)
    ax.plot([x_pos - size, x_pos + size], [depth + size, depth - size], '-', color='#dc2626', linewidth=3.5, zorder=5)

    # Label below the X, left-aligned under it
    ax.text(8, ann['label_depth'], 'No vertical\nflow (DTS)', ha='center', va='center', fontsize=8,
            color='#dc2626', fontweight='bold', zorder=5,
            bbox=dict(boxstyle='round,pad=0.2', facecolor='white', alpha=0.85, edgecolor='#dc2626', linewidth=0.8))

# --- Legend ---
legend_elements = [
    mpatches.Patch(facecolor=casing_color, edgecolor='#374151', label='Casing'),
    mpatches.Patch(facecolor=screen_color, edgecolor='#4a5661', hatch='//', label='Screen'),
    mpatches.Patch(facecolor='#ff2c55', edgecolor='none', label='Fiber Optic'),
    mpatches.Patch(facecolor='#ff6b35', alpha=0.2, edgecolor='#ff6b35', linestyle='--', label='DAS Response Zone'),
]
ax.legend(handles=legend_elements, loc='lower left', fontsize=9, framealpha=0.9,
          edgecolor='#cccccc', fancybox=True, ncol=2)

# ============================================================================
# RIGHT PANEL: Results & Key Findings (~42%)
# ============================================================================
ax_r = fig.add_axes([0.58, 0.08, 0.40, 0.85])
ax_r.set_xlim(0, 1)
ax_r.set_ylim(0, 1)
ax_r.axis('off')

# Dark background
bg = FancyBboxPatch((-0.02, -0.02), 1.04, 1.04,
                    boxstyle="round,pad=0.02",
                    facecolor='#2D2D2D', edgecolor='none')
ax_r.add_patch(bg)

# --- Storage Results Header ---
ax_r.text(0.5, 0.99, 'Storage Parameter Results',
          ha='center', va='top', fontsize=19, fontweight='bold', color='#FFD700')

# --- PT-01c Result Box ---
box_c = FancyBboxPatch((0.03, 0.84), 0.94, 0.13,
                       boxstyle="round,pad=0.015",
                       facecolor='#3a3a3a', edgecolor='#ff6b35', linewidth=2)
ax_r.add_patch(box_c)
ax_r.text(0.05, 0.955, 'PT-01c  (Gage-Gardena, 79\u201394 m)',
          fontsize=14, fontweight='bold', color='#ffe792', va='center')
ax_r.text(0.05, 0.905, '$S_s$ = 1.05 $\\times$ 10$^{-7}$ 1/m',
          fontsize=13, color='white', va='center')
ax_r.text(0.48, 0.905, '$R^2$ = 0.941', fontsize=13, color='white', va='center')
ax_r.text(0.05, 0.858, 'Slope: 3.17 \u00d7 10\u207b\u2078  |  Zone 5 piezometer',
          fontsize=10, color='#9ca3af', va='center', style='italic')

# --- PT-01b Result Box ---
box_b = FancyBboxPatch((0.03, 0.68), 0.94, 0.13,
                       boxstyle="round,pad=0.015",
                       facecolor='#3a3a3a', edgecolor='#6a93f0', linewidth=2)
ax_r.add_patch(box_b)
ax_r.text(0.05, 0.795, 'PT-01b  (Lynwood-Silverado, 107\u2013122 m)',
          fontsize=14, fontweight='bold', color='#97b7ff', va='center')
ax_r.text(0.05, 0.745, '$S_s$ = 7.10 $\\times$ 10$^{-8}$ 1/m',
          fontsize=13, color='white', va='center')
ax_r.text(0.48, 0.745, '$R^2$ = 0.976', fontsize=13, color='white', va='center')
ax_r.text(0.05, 0.698, 'Slope: 2.16 \u00d7 10\u207b\u2078  |  Zone 4 piezometer',
          fontsize=10, color='#9ca3af', va='center', style='italic')

# --- PT-01a Result Box ---
box_a = FancyBboxPatch((0.03, 0.52), 0.94, 0.13,
                       boxstyle="round,pad=0.015",
                       facecolor='#3a3a3a', edgecolor='#6a93f0', linewidth=2)
ax_r.add_patch(box_a)
ax_r.text(0.05, 0.635, 'PT-01a  (Lynwood-Silverado, 137\u2013155 m)',
          fontsize=14, fontweight='bold', color='#97b7ff', va='center')
ax_r.text(0.05, 0.585, '$S_s$ = 7.05 $\\times$ 10$^{-8}$ 1/m',
          fontsize=13, color='white', va='center')
ax_r.text(0.48, 0.585, '$R^2$ = 0.971', fontsize=13, color='white', va='center')
ax_r.text(0.05, 0.538, 'Slope: 2.15 \u00d7 10\u207b\u2078  |  Zone 2 piezometer',
          fontsize=10, color='#9ca3af', va='center', style='italic')

# --- Divider ---
ax_r.plot([0.06, 0.94], [0.49, 0.49], '-', color='#555555', linewidth=1.5)

# --- Key Findings Header ---
ax_r.text(0.5, 0.46, 'Key Findings',
          ha='center', va='top', fontsize=19, fontweight='bold', color='#FFD700')

# Finding 1
ax_r.text(0.05, 0.41, '\u2713', fontsize=16, color='#22c55e', fontweight='bold', va='center')
ax_r.text(0.09, 0.41, 'Vertical stratification confirmed',
          fontsize=14, color='white', fontweight='bold', va='center')
ax_r.text(0.09, 0.38, 'DAS strain confined to pumped zones  |  DTS: no vertical flow',
          fontsize=10.5, color='#9ca3af', va='center')

# Finding 2
ax_r.text(0.05, 0.33, '\u2713', fontsize=16, color='#22c55e', fontweight='bold', va='center')
ax_r.text(0.09, 0.33, 'Consistent storage across 76 m vertical span',
          fontsize=14, color='white', fontweight='bold', va='center')
ax_r.text(0.09, 0.30, '$S_s$ range: 7.05 $\\times$ 10$^{-8}$ to 1.05 $\\times$ 10$^{-7}$ 1/m  (1.5\u00d7 variation)',
          fontsize=10.5, color='#9ca3af', va='center')

# Finding 3
ax_r.text(0.05, 0.25, '\u2713', fontsize=16, color='#22c55e', fontweight='bold', va='center')
ax_r.text(0.09, 0.25, 'Strong linear correlations ($R^2$ = 0.94\u20130.98)',
          fontsize=14, color='white', fontweight='bold', va='center')
ax_r.text(0.09, 0.22, 'Poroelastic response validated against independent piezometers',
          fontsize=10.5, color='#9ca3af', va='center')

# Finding 4
ax_r.text(0.05, 0.17, '\u26a1', fontsize=14, color='#fbbf24', fontweight='bold', va='center')
ax_r.text(0.09, 0.17, '2,600+ DAS points vs. 5 piezometer zones',
          fontsize=14, color='white', fontweight='bold', va='center')
ax_r.text(0.09, 0.14, 'Continuous strain profile at 0.25 m spacing across 665 ft',
          fontsize=10.5, color='#9ca3af', va='center')

# --- Divider ---
ax_r.plot([0.06, 0.94], [0.10, 0.10], '-', color='#555555', linewidth=1.5)

# AQTESOLV comparison
ax_r.text(0.05, 0.06, '\u26a0', fontsize=14, color='#ff6b6b', va='center')
ax_r.text(0.09, 0.06, 'AQTESOLV discrepancy: 243\u2013391\u00d7 higher $S_s$',
          fontsize=13, color='#ff6b6b', fontweight='bold', va='center')
ax_r.text(0.09, 0.03, 'DAS = elastic skeletal storage  |  AQTESOLV = integrated hydraulic response',
          fontsize=10, color='#9ca3af', va='center')

# ============================================================================
# BOTTOM BANNER
# ============================================================================
banner = fig.add_axes([0.02, 0.005, 0.96, 0.06])
banner.set_xlim(0, 1)
banner.set_ylim(0, 1)
banner.axis('off')
banner_box = FancyBboxPatch((0.0, 0.0), 1.0, 1.0,
                            boxstyle="round,pad=0.02",
                            facecolor='#FFD700', edgecolor='#DAA520', linewidth=2)
banner.add_patch(banner_box)
banner.text(0.5, 0.5,
            'One fiber optic cable turned a 5-point pressure profile into a continuous picture of aquifer response',
            ha='center', va='center', fontsize=16, fontweight='bold', color='#1f2937')

# ============================================================================
# Save
# ============================================================================
plt.savefig('C:/Coding/BGWRP/docs/schematics/conclusion_cross_section.png',
            dpi=300, bbox_inches='tight', facecolor='white')
plt.savefig('C:/Coding/BGWRP/docs/schematics/conclusion_cross_section.pdf',
            bbox_inches='tight', facecolor='white')

print("Conclusion slide generated!")
print("  - PNG: conclusion_cross_section.png (300 DPI)")
print("  - PDF: conclusion_cross_section.pdf (vector)")
