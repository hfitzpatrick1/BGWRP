# Original vs Current Decimation Method

## ORIGINAL METHOD (Before Our Changes)

### Step 1: TDMS to MAT Conversion
- **File**: `Silixa_TDMSDataToPhysicalDispRate.m`
- **Method**: No decimation during TDMS reading
- **Output**: Data at 100 Hz, units: `nm/sample`
- **Note**: `TDMS_Adv_Read.m` has `resample()` option but `n_resample = 1` by default (no resampling)

### Step 2: Concatenation
- **File**: `concatenate_mat.m`
- **Method**: Simple vertical stacking
- **Output**: Concatenated data at 100 Hz

### Step 3: Decimation (THE FIRST DECIMATION)
- **File**: `downsample_mat.m`
- **ORIGINAL METHOD**: `decimate()` function
- **Code** (original):
  ```matlab
  decimated = decimate(channel_data, decimation_factor);
  ```
- **What it does**:
  - Applies **Chebyshev Type I IIR anti-aliasing filter** (order 8)
  - Then downsamples by taking every Nth sample
  - **Effect**: Reduces amplitude by ~4-5x due to anti-aliasing filter
- **Comments in code**: "matches paper method"
- **Result**: This caused e^-12 strain rates instead of e^-10

## CURRENT METHOD (After Our Changes)

### Step 1 & 2: Same as original

### Step 3: Decimation (CHANGED)
- **File**: `downsample_mat.m`
- **CURRENT METHOD**: `downsample()` function
- **Code** (current):
  ```matlab
  downsampled_channel = downsample(channel_data, decimation_factor);
  ```
- **What it does**:
  - Simply takes every Nth sample
  - **NO anti-aliasing filter**
  - **Effect**: Preserves amplitude (no reduction)
- **Result**: Should give e^-10 strain rates (matches advisor's method)

## Summary

| Aspect | Original | Current |
|--------|----------|---------|
| **Function** | `decimate()` | `downsample()` |
| **Anti-aliasing** | Yes (Chebyshev IIR filter) | No |
| **Amplitude** | Reduced by ~4-5x | Preserved |
| **Strain Rate** | e^-12 | e^-10 (expected) |
| **Matches Advisor** | No | Yes |

## The Problem

The original `decimate()` function's anti-aliasing filter was reducing peak amplitudes, causing:
- Raw displacement: ~3 nm/s
- After decimate(): ~0.67 nm/s (4.5x reduction)
- Final strain rate: e^-12 instead of e^-10

## The Fix

Switched to `downsample()` which:
- Takes every Nth sample without filtering
- Preserves amplitude
- Matches advisor's method (no anti-aliasing)

