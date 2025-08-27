# BGWRP Data Processing Toolkit

A comprehensive MATLAB toolkit for processing and analyzing Distributed Acoustic Sensing (DAS) data from TDMS files to analysis-ready datasets. Features advanced noise reduction, signal processing, and diagnostic capabilities for groundwater monitoring applications.

## Architecture

### Directory Structure
```
BGWRP/
├── src/                    # Source code
│   ├── BGWRP_Toolkit.m    # Main processing script (unified entry point)
│   ├── config.m           # Configuration settings
│   ├── prepare/           # Data preparation functions
│   │   ├── Silixa_TDMSDataToPhysicalDispRate.m
│   │   ├── process_head_data.m
│   │   ├── process_mat_data.m
│   │   └── organize_workspace.m
│   ├── analyze/           # Analysis functions
│   │   ├── analyze_head_data.m
│   │   ├── analyze_das_data.m
│   │   ├── discover_datasets.m
│   │   └── save_timing_config.m
│   ├── plot/              # Plotting and visualization
│   │   ├── generate_plots.m
│   │   └── [chart generation functions]
│   ├── diagnostic/        # Diagnostic and quality assessment
│   │   ├── diagnose_file_boundaries.m
│   │   ├── diagnose_boundaries_enhanced.m
│   │   ├── diagnose_tdms_metadata.m
│   │   └── analyze_quantization.m
│   ├── modify/            # Advanced filtering and signal processing
│   │   ├── chen_denoising.m
│   │   ├── spatial_filtering.m
│   │   ├── temporal_filtering.m
│   │   └── ensemble_averaging.m
│   └── utils/             # Utility functions
├── data/
│   └── _BATCH/            # Processing workspace (configurable)
│       ├── [input_dirs]/  # Raw TDMS files organized by test
│       │   ├── _das/      # DAS TDMS files
│       │   └── _head/     # Head monitoring data
│       ├── _tdms_to_mat/  # Converted MAT files
│       ├── _combined_head/# Processed head data
│       ├── _concatenated/ # Concatenated and decimated datasets
│       ├── _active/       # Final analysis-ready data
│       │   └── [dataset]/ # Per-dataset directories
│       │       ├── _das/  # DAS data files
│       │       ├── _head/ # Head data files
│       │       └── _das_timing/ # Timing configuration
│       └── _configs/      # Global timing configurations
└── README.md
```

### Data Flow
1. **Raw TDMS** → `_tdms_to_mat/` → `_concatenated/` → `_active/`
2. **Head data processing**: `_head/` → `_combined_head/` → `_active/[dataset]/_head/`
3. **Directory names are authority** - all processing references parent directory names
4. **Flexible file discovery** - automatically detects any `.mat` files and timing configs
5. **Workspace organization** - automatic cleanup and archiving of intermediate files

## Configuration

Edit `src/config.m` to set:
- `config.base_input` - Root data processing directory (default: `C:\Coding\BGWRP\data\_BATCH\`)
- Analysis windows, waterfall bounds, filtering options
- Decimation factors, calibration parameters
- Chart output settings and file paths
- Advanced filtering algorithm parameters (Chen, spatial, temporal, ensemble)
- MATLAB movmean filter parameters (`matlab_movmean_window`, etc.)

## Quick Start

### Setup
```matlab
cd('C:\Coding\BGWRP\src')
```

### Basic Commands

| Mode | Command | Description |
|------|---------|-------------|
| **Data Preparation** |
| `prep` | `mode = 'prep'; BGWRP_Toolkit` | Full prep: TDMS→MAT→concatenate→timing with cleanup |
| `prep_tdms` | `mode = 'prep_tdms'; BGWRP_Toolkit` | Convert TDMS to MAT files only |
| `prep_concat` | `mode = 'prep_concat'; BGWRP_Toolkit` | Concatenate existing MAT files only |
| `prep_timing` | `mode = 'prep_timing'; BGWRP_Toolkit` | Extract timing configuration only |
| `prep_no_decim` | `mode = 'prep_no_decim'; BGWRP_Toolkit` | Full prep preserving 100Hz (no decimation) |
| `prep_purge` | `mode = 'prep_purge'; BGWRP_Toolkit` | Full prep with purge of previous data |
| **Analysis** |
| `run` | `mode = 'run'; BGWRP_Toolkit` | Analyze data, display plots |
| `run_save` | `mode = 'run_save'; BGWRP_Toolkit` | Analyze data, save charts |
| **Advanced Filtering** |
| `run_filter_chen` | `mode = 'run_filter_chen'; BGWRP_Toolkit` | Chen et al. complete denoising framework |
| `run_filter_chen_fk` | `mode = 'run_filter_chen_fk'; BGWRP_Toolkit` | Chen F-K filter (grid pattern removal) |
| `run_filter_spatial` | `mode = 'run_filter_spatial'; BGWRP_Toolkit` | Spatial median filtering (BEST) |
| `run_filter_temporal` | `mode = 'run_filter_temporal'; BGWRP_Toolkit` | Temporal median filtering |
| `run_filter_ensemble` | `mode = 'run_filter_ensemble'; BGWRP_Toolkit` | Multi-channel ensemble averaging |
| `run_filter_grid` | `mode = 'run_filter_grid'; BGWRP_Toolkit` | Targeted grid pattern removal |
| `run_filter_movavg` | `mode = 'run_filter_movavg'; BGWRP_Toolkit` | Parameterized moving average filter |
| `run_filter_matlab_movmean` | `mode = 'run_filter_matlab_movmean'; BGWRP_Toolkit` | **NEW** MATLAB movmean filter (simple, direct) |
| `run_filter_baseline` | `mode = 'run_filter_baseline'; BGWRP_Toolkit` | Baseline (no filtering) |
| **Basic Filtering** |
| `run_detrend` | `mode = 'run_detrend'; BGWRP_Toolkit` | Analysis with detrend filtering |
| `run_highpass` | `mode = 'run_highpass'; BGWRP_Toolkit` | Analysis with highpass filtering |
| `run_median` | `mode = 'run_median'; BGWRP_Toolkit` | Analysis with median filtering |
| **Diagnostics** |
| `diagnostic_boundaries` | `mode = 'diagnostic_boundaries'; BGWRP_Toolkit` | Analyze file boundary artifacts |
| `diagnostic_enhanced` | `mode = 'diagnostic_enhanced'; BGWRP_Toolkit` | Enhanced boundary analysis |
| `diagnostic_tdms` | `mode = 'diagnostic_tdms'; BGWRP_Toolkit` | TDMS metadata analysis |
| `diagnostic_quantization` | `mode = 'diagnostic_quantization'; BGWRP_Toolkit` | Data quantization analysis |
| **Maintenance** |
| `purge_inactive` | `mode = 'purge_inactive'; BGWRP_Toolkit` | Clean up inactive intermediate directories |
| `purge_unraw` | `mode = 'purge_unraw'; BGWRP_Toolkit` | Archive non-underscore dirs and purge |
| **Complete Pipeline** |
| `all` | `mode = 'all'; BGWRP_Toolkit` | Full pipeline: prep + analysis |

## Adding New Data

### For Raw TDMS Data (Structured)
1. Create directory under `data/_BATCH/` (e.g., `data/_BATCH/MyNewTest/`)
2. Create subdirectories:
   - `_das/` for DAS TDMS files
   - `_head/` for head monitoring data (optional)
3. Place TDMS files in appropriate subdirectories
4. Run: `mode = 'prep'; BGWRP_Toolkit`
5. Results appear in `data/_BATCH/_active/MyNewTest/`

### For Raw TDMS Data (Flat Structure)
1. Create directory under `data/_BATCH/` (e.g., `data/_BATCH/MyNewTest/`)
2. Place TDMS files directly in this directory
3. Run: `mode = 'prep'; BGWRP_Toolkit`
4. Results appear in `data/_BATCH/_active/MyNewTest/`

### For Pre-processed Data
1. Create directory under `data/_BATCH/_active/` (e.g., `data/_BATCH/_active/MyAnalysis/`)
2. Create subdirectories:
   - `_das/` for processed DAS data
   - `_head/` for head data (optional)
   - `_das_timing/` for timing configuration
3. Place your `.mat` data file in `_das/` subdirectory
4. Add timing configuration file `get_timing_*.m` in `_das_timing/` subdirectory
5. Run: `mode = 'run'; BGWRP_Toolkit`

## Data Requirements

### TDMS Files
- Must contain DAS displacement rate data from Silixa iDAS system
- Filename pattern: `*UTC_YYYYMMDD_HHMMSS.mmm.tdms`
- Timestamps used for automatic timing extraction
- Automatically converted to physical displacement rates

### MAT Files  
- Must contain variable `decdata` (displacement rate matrix)
- Format: `[time_samples x channels]`
- Sampling rate: typically 100Hz (decimated to 1Hz by default)
- Units: physical displacement rate (nm/sample)

### Head Data Files
- CSV or MAT format with time series data
- Automatic zone combination and synchronization
- Optional but recommended for groundwater analysis

### Timing Configuration
- MATLAB function returning timing structure  
- Required fields: `start`, `end`, `num_files`
- Optional fields: calibration parameters, analysis windows
- Auto-generated from TDMS filenames or manually created

## Key Features

### Flexible File Discovery
- Directory name determines dataset identity (no hardcoded names)
- Automatic detection of any `.mat` files in data directories
- Timing config files matched by pattern `get_timing_*.m`
- Support for both structured and flat directory layouts

### Advanced Signal Processing
- **Chen et al. Denoising**: Complete framework from literature
- **Spatial/Temporal Filtering**: Multi-dimensional noise reduction  
- **Ensemble Averaging**: Multi-channel signal extraction
- **Grid Pattern Removal**: Targeted artifact suppression
- **MATLAB movmean Filter**: Direct MATLAB implementation for simple, fast smoothing
- **Phase Alignment**: Correction for file boundary discontinuities

### Mode Isolation
- Each mode completely resets configuration (no carryover)
- Clean separation of preprocessing vs analysis functions
- Configurable processing stages (skip/enable individual steps)

### Workspace Management
- Automatic organization of intermediate files
- Selective archiving and cleanup modes
- Purge modes for managing disk space
- Consistent `_underscore` naming convention

### Diagnostic Capabilities
- **Boundary Analysis**: File concatenation artifact detection
- **TDMS Metadata**: Raw file property extraction
- **Quantization Analysis**: Data quality assessment
- **Enhanced Diagnostics**: Focused analysis tools

### Automatic Calibration
- Built-in parameters for PT01a, PT01b, PT01c datasets
- Calibration auto-selected based on directory name patterns
- Fully configurable via timing configuration files
- Support for custom calibration parameters

## Troubleshooting

### Common Issues
- **"No TDMS files found"** - Check directory path, file permissions, and subdirectory structure
- **"No timing config found"** - Ensure `get_timing_*.m` file exists in `_das_timing/` subdirectory
- **"DAS data file not found"** - Verify `.mat` file exists in `_active/[dataset]/_das/` subdirectory
- **"Workspace organization failed"** - Check write permissions on base directory
- **Mode conflicts** - Each mode resets configuration completely (by design)
- **Filter errors** - Check input data format and sampling rate compatibility
- **Memory issues** - Use `prep_no_decim` mode sparingly; 100Hz data requires significant RAM

### Debug Modes
Test individual components:
```matlab
mode = 'prep_timing'; BGWRP_Toolkit     % Test timing extraction only
mode = 'diagnostic_tdms'; BGWRP_Toolkit % Check TDMS file integrity  
mode = 'diagnostic_boundaries'; BGWRP_Toolkit % Check concatenation quality
```

### Performance Tips
- Use `prep_purge` to clean workspace before major processing
- Monitor disk space during concatenation steps
- Use diagnostic modes to identify data quality issues early
- For large datasets, consider processing in smaller time windows

## Development

### Adding New Modes
1. Add case to switch statement in `BGWRP_Toolkit.m` (around line 34-432)
2. Set appropriate configuration flags for desired behavior
3. Add mode name to error message list (line 432)
4. Test isolation from other modes (no variable carryover)
5. Update README.md with new mode documentation

### Adding New Analysis Functions
1. Create function in appropriate subdirectory:
   - `prepare/` - Data preprocessing and conversion
   - `analyze/` - Core analysis algorithms
   - `plot/` - Visualization and chart generation  
   - `diagnostic/` - Quality assessment and debugging
   - `modify/` - Signal processing and filtering
   - `utils/` - General utility functions
2. Functions automatically available via `addpath(genpath(script_dir))`
3. Use `test_label` (directory name) as primary identifier
4. Avoid hardcoded dataset names or file patterns
5. Follow consistent error handling patterns with try-catch blocks

### Adding New Filtering Algorithms
1. Create filter function in `modify/` subdirectory
2. Add mode case in `BGWRP_Toolkit.m` switch statement
3. Set `config.smoothing_method` or `config.filter_method` appropriately
4. Document parameters in `config.m`
5. Test with diagnostic modes to verify effectiveness

### Code Style Guidelines
- Use descriptive variable names (avoid single letters)
- Include function documentation headers
- Use `fprintf` for user feedback during processing
- Implement proper error handling with meaningful messages
- Follow MATLAB naming conventions (camelCase for variables, PascalCase for functions)
