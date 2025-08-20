# Vertical Striping Artifact Analysis - DAS Data

## Problem Statement
DAS waterfall plots show prominent **vertical striping artifacts** appearing as 4 distinct bands within a 4-minute analysis window. The striping manifests as systematic discontinuities that significantly impact data visualization and potentially analysis quality.

## Investigation Timeline & Approach

### Phase 1: Initial Observations (Starting Point)
- **Observation:** 4 distinct vertical bands visible in waterfall plots during 4-minute recovery analysis window
- **Datasets:** PT01c_Recovery (2-hour dataset) and PT01c_Full_New (6+ hour dataset)
- **Initial Hypothesis:** Visual scaling artifacts due to different dataset sizes

### Phase 2: Diagnostic Development
**Tools Created:**
1. **Basic boundary diagnostic** - Detected 100/100 significant discontinuities at 60-sample intervals
2. **Enhanced diagnostic** - Revealed detailed artifact characteristics

**Key Diagnostic Findings:**
- **Jump Pattern:** Random jumps (mean=0.1091, std=0.2033) rather than systematic bias
- **Amplitude Scaling:** **66.5% RMS variation** between file segments (major finding)
- **Frequency Content:** **26.56x change** in high-frequency energy across boundaries
- **Spatial Coherence:** Coherent across channels (global, not channel-specific)
- **Recommendation:** Amplitude scaling correction

### Phase 3: Post-Processing Correction Attempts

**A. Time-Domain Filtering (FAILED)**
- Attempted: `detrend`, `highpass`, `median` filters
- **Result:** Minimal to no improvement, some methods made artifacts worse
- **Why Failed:** Addressed wrong artifact type (designed for noise, not systematic discontinuities)

**B. Phase Boundary Correction (FAILED)**
- Attempted: `phase_align`, `smooth_transition`, `local_detrend`
- **Result:** Made artifacts worse, enlarged bands rather than reducing them
- **Why Failed:** Applied additive corrections to what appeared to be multiplicative problems

**C. Amplitude Normalization (PARTIAL SUCCESS)**
- Attempted: `adaptive_normalize` with 5-point smoothing
- **Result:** 17% reduction in RMS variation (60.6% → 50.3%)
- **Why Limited:** Smoothing was too conservative, underlying artifacts remained

### Phase 4: Root Cause Investigation

**Current Working Theory:**
The vertical striping is **NOT** a post-processing fixable issue, but originates in the **preprocessing pipeline** itself.

**Evidence Points to Preprocessing Issues:**
1. **Fixed Scaling in TDMS Conversion:** 
   - `adc_scalar = 1/8192` (uniform across all files)
   - `data = 116*data` (fixed physical conversion)

2. **Decimation Artifacts in Concatenation:**
   - `decimate()` function applies different anti-aliasing filtering to different files
   - Files with different noise characteristics get filtered differently

3. **No Amplitude Normalization During Concatenation:**
   - Simple concatenation `decdata = [decdata; decmat]` with no amplitude consistency checks

## Current Status

### What We've Learned
- **Artifacts are systematic, not random** - occur at precise 60-sample intervals
- **Multiplicative nature** - amplitude scaling issues dominate over DC offsets  
- **Frequency domain involvement** - massive changes in spectral content across boundaries
- **Post-processing limitations** - corrections after concatenation are insufficient

### What We've Tried (Chronological)
1. **Visual analysis** → Led to systematic investigation
2. **Basic filtering** → Minimal impact, wrong approach
3. **Phase corrections** → Made worse, wrong artifact type
4. **Amplitude normalization** → Partial success, not enough
5. **Enhanced diagnostics** → Revealed amplitude scaling as primary issue
6. **Preprocessing examination** → Current focus on root cause

## Next Investigation: Preprocessing Pipeline
**Hypothesis:** Vertical striping originates during TDMS→MAT conversion and concatenation due to:
- File-to-file variations in recording conditions
- Fixed preprocessing parameters not accounting for per-file differences  
- Decimation filtering creating frequency domain artifacts

**Test Plan:**
- Examine individual TDMS file characteristics before conversion
- Test alternative decimation methods (simple downsampling vs. filtered decimation)
- Implement per-file amplitude normalization during preprocessing

## Conclusion
**Current Assessment:** Vertical striping is a **preprocessing artifact** requiring fixes at the TDMS conversion and concatenation stage, not post-processing corrections. The 66.5% RMS variation and 26.56x frequency changes indicate fundamental issues in how individual files are processed and combined.
