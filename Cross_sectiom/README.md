# Cross Section: PM-07 to PT-01c

This folder contains scripts to create geological cross sections between the PM-07 and PT-01c wells based on well construction data.

## Files

### MATLAB Versions
- `create_cross_section_PM07_PT01c.m` - Basic cross section visualization
- `create_enhanced_cross_section.m` - Enhanced cross section with geological layers
- `create_accurate_cross_section.m` - Accurate cross section with as-built PT-01c data
- `run_cross_section.m` - Main script to run the basic cross section creation
- `run_accurate_cross_section.m` - Script to run the accurate cross section

### Python Versions (Recommended)
- `create_cross_section_python.py` - **NEW** Full-featured Python cross section
- `create_simple_cross_section.py` - **NEW** Simplified Python cross section (works reliably)
- `run_python_cross_section.py` - Script to run the Python cross section
- `README.md` - This documentation file

### Output Files
- `cross_section_PM07_PT01c.png` - High-resolution cross section image
- `cross_section_PM07_PT01c_simple.png` - Simplified cross section image

## Well Construction Data

### PM-07 (As-Built Data - 5 Wells)
- **Total Depth:** 810 ft
- **Casing diameter:** 2.5 inches (PVC)
- **Screen slot size:** 0.020 inches
- **PM-07-01:** Screen 645-665 ft, Casing 0-665 ft
- **PM-07-02:** Screen 485-505 ft, Casing 0-505 ft
- **PM-07-03:** Screen 420-440 ft, Casing 0-440 ft
- **PM-07-04:** Screen 360-380 ft, Casing 0-380 ft
- **PM-07-05:** Screen 290-310 ft, Casing 0-310 ft
- **Borehole Reaming:** 22" (0-20 ft), 17" (20-390 ft), 14.75" (390-515 ft), 10.625" (515-805 ft)

### PT-01c (As-Built Data)
- **Total Depth:** 320 ft
- **Top of casing:** 0 ft
- **Bottom of Casing:** 320 ft
- **Top of Screen:** 260 ft
- **Bottom of Screen:** 310 ft
- **Casing diameter:** 6 inches (PVC)
- **Screen slot size:** 0.050 inches
- **Sump:** 310-320 ft
- **Cement-Bentonite Grout:** 0-240 ft
- **Bentonite Seal:** 240-250 ft
- **Filter Pack:** 250-320 ft
- **Borehole Reaming:** 22" diameter (0-20 ft), 14.75" diameter (20-320 ft)

## Usage

### Basic Cross Section
```matlab
cd('C:\Coding\BGWRP\Cross_sectiom')
create_cross_section_PM07_PT01c()
```

### Enhanced Cross Section (with geological layers)
```matlab
cd('C:\Coding\BGWRP\Cross_sectiom')
create_enhanced_cross_section()
```

### Run All Cross Sections
```matlab
cd('C:\Coding\BGWRP\Cross_sectiom')
run_cross_section()              % Basic cross section
run_accurate_cross_section()     % Accurate cross section with as-built data
```

### Python Cross Section (Recommended)
```python
cd('C:\Coding\BGWRP\Cross_sectiom')
python create_simple_cross_section.py  # Reliable, creates PNG file
# OR
python run_python_cross_section.py     # Full-featured version
```

### MATLAB Cross Section
```matlab
cd('C:\Coding\BGWRP\Cross_sectiom')
create_accurate_cross_section()  % MATLAB version with actual construction data
```

## Features

### Basic Cross Section
- Well construction visualization
- Casing and screen representation
- Depth markers and labels
- Well construction summary

### Enhanced Cross Section
- All basic features plus:
- Estimated geological layers
- Color-coded geological units
- Enhanced visualization
- Distance markers
- Professional formatting

### Accurate Cross Section (NEW - Recommended)
- All enhanced features plus:
- **Actual as-built PT-01c construction data**
- **Correct well spacing: 177 ft (PM-07 NW of PT-01c)**
- **Visible borehole reaming** (22" diameter 0-20 ft, 14.75" diameter 20-320 ft)
- **Color-coded construction materials** (cement-bentonite grout, bentonite seal, filter pack)
- 6-inch PVC casing with 0.050-inch slot screen details
- Sump construction visualization
- Comprehensive construction summary
- Professional engineering-grade visualization

## Geological Layers (Estimated)

The enhanced cross section includes estimated geological layers:
1. **Topsoil/Sand** (0-50 ft)
2. **Clay/Silt** (50-150 ft)
3. **Sand/Gravel** (150-300 ft) - Aquifer
4. **Clay** (300-450 ft) - Confining layer
5. **Sandstone** (450-600 ft) - Deeper aquifer
6. **Bedrock** (600-665 ft)

**Note:** These geological layers are estimated based on typical groundwater geology. Update with actual geological data when available.

## Customization

### Update Well Distance
The well distance is set to 177 feet (PM-07 is 177 ft NW of PT-01c). Modify the `well_distance` variable in the scripts if needed.

### Update Geological Layers
Edit the `geology_layers` array in `create_enhanced_cross_section.m` to match actual geological data.

### Add More Wells
Extend the scripts to include additional wells by adding their construction data and plotting functions.

## Output

The scripts generate MATLAB figures showing:
- Well construction details
- Geological cross section
- Depth and distance markers
- Construction summaries
- Professional formatting suitable for reports

## Integration with BGWRP Toolkit

These cross section scripts complement the main BGWRP data processing toolkit by providing:
- Visual context for DAS data analysis
- Well construction reference
- Geological framework for interpretation
- Professional visualization for reports

## Future Enhancements

Potential improvements:
- Integration with actual coordinate data
- 3D cross section visualization
- Integration with DAS data overlay
- Interactive well selection
- Export to various formats (PDF, PNG, etc.)
