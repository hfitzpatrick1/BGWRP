# BGWRP Organization Summary

**Date:** February 6, 2026

## What Was Done

Reorganized 60+ loose scripts from the root directory into logical subdirectories for better maintainability and discoverability.

## New Directory Structure

### `/scripts/` (Root Level)
**Purpose:** Main analysis runner scripts that users actually execute

**Contents:**
- `run_PT01a_thesis_analysis.m` ⭐ - Primary thesis analysis script
- `run_roi_analysis.m` - Region of Interest regression analysis  
- All other `run_*.m` files - Various analysis workflows

**Files Moved:** 17 runner scripts

---

### `/src/experiments/`
**Purpose:** Experimental, test, and diagnostic scripts

**Contents:**
- `test_*.m` - Test scripts
- `check_*.m` - Verification/validation scripts
- `debug_*.m` - Debugging utilities
- `quick_*.m` - Quick test scripts
- `optimize_*.m` - Optimization experiments
- `diagnose_*.m` - Diagnostic tools
- `diagnostic_*.m` - Diagnostic analysis
- `example_*.m` - Example scripts
- `combined_filtering_approach.m`
- `denoise_steps.m`

**Files Moved:** 25+ experimental/test scripts

---

### `/src/processing/`
**Purpose:** Data processing pipelines and workflows

**Contents:**
- `process_*.m` - Processing workflows (PM7, aquatroll, etc.)
- `batch_*.m` - Batch processing scripts
- `extract_*.m` - Data extraction utilities
- `migrate_*.m` - Data migration tools
- `find_*.m` - File finding utilities
- `setup_*.m` - Setup scripts

**Files Moved:** 15+ processing scripts

---

### `/src/export/`
**Purpose:** Export utilities for various formats

**Contents:**
- `export_*.m` - Export functions (CSV, pump schedules, etc.)
- `create_pump_schedule*.m` - Pump schedule creation

**Files Moved:** 5 export scripts

---

### `/src/weight_adjustment/`
**Purpose:** Temporal weighting functions for regression optimization

**Contents:**
- `add_*_weights.m` - Weight adding functions
- `weight_*.m` - Weighting utilities
- `add_weights_to_data.m`

**Files Moved:** 5 weight adjustment scripts

---

### `/src/correction/`
**Purpose:** Data correction and normalization utilities

**Contents:**
- `flatten_*.m` - Flattening operations
- `shift_*.m` - Time/data shifting
- `renormalize_*.m` - Renormalization utilities
- `fix_*.m` - Data fixing/correction

**Files Moved:** 6 correction scripts

---

### `/src/plot/`
**Purpose:** Plotting and visualization (existing directory, added files)

**New Contents:**
- `plot_csv_quick.m`
- `plot_depth_range_260_310.m`
- `plot_pumping_well.m`

**Files Added:** 3 plotting scripts

---

## Files Remaining in Root

Only essential top-level files remain:
- `config.m` - Root configuration
- `README.md` - Project documentation  
- `AQUATROLL_PROCESSING_GUIDE.md` - Processing guide
- `.gitignore` - Git configuration
- `nul` - (likely can be deleted)

## Benefits of This Organization

1. **Clearer Structure:** Related functionality grouped together
2. **Easier Discovery:** Know where to look for specific types of scripts
3. **Better Maintainability:** Easier to manage and update code
4. **Reduced Clutter:** Clean root directory with only essentials
5. **Logical Separation:** 
   - What you run (`/scripts/`)
   - How it works (`/src/`)
   - Experiments (`/src/experiments/`)
   - Processing (`/src/processing/`)

## Usage Impact

### Before:
```matlab
cd('C:\Coding\BGWRP')
run_PT01a_thesis_analysis  % In root with 60+ other files
```

### After:
```matlab
cd('C:\Coding\BGWRP\scripts')
run_PT01a_thesis_analysis  % Clear purpose directory
```

## Next Steps (Optional)

Consider:
1. Review `src/experiments/` for scripts that can be archived or deleted
2. Move `_ref/` directory contents to a proper archive location
3. Review and potentially remove `nul` file from root
4. Consider adding README files to other subdirectories

## Documentation Updated

- ✅ Main README.md updated with new structure
- ✅ Created `scripts/README.md` for runner scripts
- ✅ All file moves completed successfully

---

**Total Files Organized:** 70+ scripts
**Directories Created:** 6 new directories
**Time Taken:** ~5 minutes
