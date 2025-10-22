# PM-07 / PT-01c DAS Pump-Test Schematics

## Files
- `DAS_well_pump_test.svg`: Generic DAS-in-well concept diagram
- `PM07_PT01c_pump_test_schematic.svg`: **Site-specific cross section** with accurate well construction details

## PM-07 Well Construction (as-built)

| Zone | Depth (ft bgs) | Component |
|------|----------------|-----------|
| Zone 1 | 0-645 | Steel casing (DAS fiber strapped to outside) |
| Zone 1 | 645-665 | Screen |
| Zone 2 | 0-485 | Steel casing |
| Zone 2 | 485-505 | Screen |
| Zone 3 | 0-420 | Steel casing |
| Zone 3 | 420-440 | Screen |
| Zone 4 | 0-360 | Steel casing |
| Zone 4 | 360-380 | Screen |
| Zone 5 | 0-290 | Steel casing |
| Zone 5 | 290-310 | Screen |

## Editing the SVG

### Scale
- **1.2 pixels per foot** vertically
- 50 ft grid lines are 60 px apart
- To adjust: find the well rectangles and multiply depths by 1.2

### Structure (named groups)
- `#grid`: depth axis and horizontal gridlines
- `#formations`: geological layers (rectangles with gradients)
- `#PM-07`: all 5 nested zones (zone1–zone5)
  - Each zone has casing + screen rectangles
  - Zone 1 includes red fiber strip on the outside
- `#PT-01c`: extraction well with casing, screen, pump
- `#callouts`: temperature and strain annotations with arrows
- `#legend`: symbol key at bottom

### Quick Edits
- **Change depths**: Edit `y` and `height` attributes in zone rectangles (remember 1.2 px/ft)
- **Formation colors**: Modify `<linearGradient>` definitions at top
- **Labels**: Search for `<text>` elements and edit content
- **Colors**:
  - Temperature callouts: `#0aa` (cyan)
  - Strain callouts: `#8e44ad` (purple)
  - Fiber: `#ff2c55` (red)
  - PT-01c screen: `#2563eb` (blue)

### Export Options
- **PNG**: Open in Inkscape → File → Export PNG → set width (e.g., 3000 px for high-res)
- **PDF**: Inkscape → Save As → PDF (for LaTeX/papers)
- **Edit online**: Upload to [Figma](https://figma.com) or [SVG Editor](https://svgedit.netlify.app/)

## Usage in Papers/Presentations
- Cite as schematic/conceptual diagram (not to scale horizontally)
- Vertical scale is accurate (1.2 px/ft)
- Consider adding your institution logo or project ID in the title bar

## Notes
- Formations are approximate based on typical LA Basin stratigraphy
- Adjust layer thicknesses to match actual site logs
- PT-01c screen depth is approximate (~400-550 ft); update as needed
- Commit changes to preserve history alongside analyses

