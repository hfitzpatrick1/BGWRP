# BGWRP Data Processing Toolkit

A MATLAB toolkit for processing and analyzing Distributed Acoustic Sensing (DAS) data from TDMS files to analysis-ready datasets.

## Architecture

### Directory Structure
```
BGWRP/
├── src/                    # Source code
│   ├── BGWRP_Toolkit.m    # Main processing script
│   ├── config.m           # Configuration settings
│   ├── prepare/           # Data preparation functions
│   ├── analyze/           # Analysis functions
│   ├── plot/              # Plotting functions
│   ├── diagnostic/        # Diagnostic tools
│   └── modify/            # Data filtering functions
├── data/
│   └── _BATCH/            # Processing workspace (configurable)
│       ├── [input_dirs]/  # Raw TDMS files
│       ├── _tdms_to_mat/  # Converted MAT files
│       ├── _concatenated/ # Concatenated datasets
│       ├── _active/       # Final analysis-ready data
│       └── _configs/      # Timing configurations
└── README.md
```

### Data Flow
1. **Raw TDMS** → `_tdms_to_mat/` → `_concatenated/` → `_active/`
2. **Directory names are authority** - all processing references parent directory names
3. **Flexible file discovery** - finds any `.mat` files regardless of naming

## Configuration

Edit `src/config.m` to set:
- `config.base_input` - Root data processing directory (default: `C:\Coding\BGWRP\data\_BATCH\`)
- Analysis windows, waterfall bounds, filtering options

## Quick Start

### Setup
```matlab
cd('C:\Coding\BGWRP\src')
```

### Basic Commands

| Mode | Command | Description |
|------|---------|-------------|
| **Data Preparation** |
| `prep` | `mode = 'prep'; BGWRP_Toolkit` | Full prep: TDMS→MAT→concatenate→timing |
| `prep_tdms` | `mode = 'prep_tdms'; BGWRP_Toolkit` | Convert TDMS to MAT files only |
| `prep_concat` | `mode = 'prep_concat'; BGWRP_Toolkit` | Concatenate existing MAT files only |
| `prep_timing` | `mode = 'prep_timing'; BGWRP_Toolkit` | Extract timing configuration only |
| **Analysis** |
| `run` | `mode = 'run'; BGWRP_Toolkit` | Analyze data, display plots |
| `run_save` | `mode = 'run_save'; BGWRP_Toolkit` | Analyze data, save charts |
| **Diagnostics** |
| `diagnostic_boundaries` | `mode = 'diagnostic_boundaries'; BGWRP_Toolkit` | Analyze file boundary artifacts |
| **Filtering** |
| `run_detrend` | `mode = 'run_detrend'; BGWRP_Toolkit` | Analysis with detrend filtering |
| `run_highpass` | `mode = 'run_highpass'; BGWRP_Toolkit` | Analysis with highpass filtering |
| **Complete Pipeline** |
| `all` | `mode = 'all'; BGWRP_Toolkit` | Full pipeline: prep + analysis |

## Adding New Data

### For Raw TDMS Data
1. Create directory under `data/_BATCH/` (e.g., `data/_BATCH/MyNewTest/`)
2. Place TDMS files in this directory
3. Run: `mode = 'prep'; BGWRP_Toolkit`
4. Results appear in `data/_BATCH/_active/MyNewTest/`

### For Pre-processed Data
1. Create directory under `data/_BATCH/_active/` (e.g., `data/_BATCH/_active/MyAnalysis/`)
2. Place your `.mat` data file in this directory
3. Add timing configuration file `get_timing_*.m` (any name starting with `get_timing_`)
4. Run: `mode = 'run'; BGWRP_Toolkit`

## Data Requirements

### TDMS Files
- Must contain DAS displacement rate data
- Filename pattern: `*UTC_YYYYMMDD_HHMMSS.mmm.tdms`
- Timestamps used for automatic timing extraction

### MAT Files  
- Must contain variable `decdata` (displacement rate matrix)
- Format: `[time_samples x channels]`
- Sampling rate: typically 100Hz (decimated to 1Hz)

### Timing Configuration
- MATLAB function returning timing structure
- Required fields: `start`, `end`, `num_files`
- Optional fields: calibration parameters, analysis windows

## Key Features

### Flexible File Discovery
- Directory name determines dataset identity
- Any `.mat` file in directory is automatically detected
- Timing config files matched by pattern `get_timing_*.m`

### Mode Isolation
- Each mode completely resets configuration
- No carryover between different analysis modes
- Clean separation of prep vs analysis functions

### Automatic Calibration
- PT01a, PT01b, PT01c parameters built-in
- Calibration selected based on directory name pattern
- Configurable via timing configuration files

## Troubleshooting

### Common Issues
- **"No TDMS files found"** - Check directory path and file permissions
- **"No timing config found"** - Ensure `get_timing_*.m` file exists in dataset directory  
- **"DAS data file not found"** - Verify `.mat` file exists in `_active/` subdirectory
- **Mode conflicts** - Each mode resets configuration completely

### Debug Mode
Add `fprintf` statements or examine workspace variables:
```matlab
mode = 'prep_timing'; BGWRP_Toolkit  % Test timing extraction only
```

## Development

### Adding New Modes
1. Add case to switch statement in `BGWRP_Toolkit.m`
2. Set configuration flags for desired behavior
3. Add mode to error message list
4. Test isolation from other modes

### Adding New Analysis Functions
1. Create function in appropriate subdirectory (`analyze/`, `plot/`, etc.)
2. Functions are automatically available via `addpath(genpath(script_dir))`
3. Use `test_label` (directory name) as primary identifier
4. Avoid hardcoded dataset names or file patterns
