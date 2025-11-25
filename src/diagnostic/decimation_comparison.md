# Decimation and Concatenation: Current vs Original Method

## Current Method (What We're Doing Now)

### 1. Concatenation (`concatenate_mat.m`)
- **Method**: Simple vertical concatenation
- **Code**: `rawdata = [rawdata; file_data];` (line 84)
- **Process**: 
  - Loads each MAT file sequentially
  - Stacks them vertically (time dimension)
  - No filtering or processing during concatenation
  - Preserves all data as-is

### 2. Decimation (`downsample_mat.m`)
- **Method**: MATLAB's `decimate()` function
- **Code**: `decimated = decimate(channel_data, decimation_factor);` (line 81)
- **Process**:
  - Applies **Chebyshev Type I IIR anti-aliasing filter** (order 8)
  - Then downsamples by taking every Nth sample
  - **Effect**: Anti-aliasing filter **reduces peak amplitudes** (~4-5x reduction)
  - This is why we see e^-12 instead of e^-10

## Original Method (Advisor's Approach)

Based on your comment: *"he used a different decimation code that doesn't have anti-aliasing"*

### Likely Original Method:
- **No anti-aliasing filter** applied
- Possible approaches:
  1. **Simple downsampling**: `downsample()` - takes every Nth sample without filtering
  2. **Resampling without anti-aliasing**: Custom implementation
  3. **Averaging**: `movmean()` then downsampling
  4. **Direct indexing**: `data(1:decimation_factor:end, :)`

### Key Difference:
- **Original**: Preserves amplitude (no filter reduction)
- **Current**: Reduces amplitude (anti-aliasing filter)

## Why This Matters

The anti-aliasing filter in `decimate()` is causing:
- Raw data: ~3 nm/s
- After decimate(): ~0.67 nm/s (4.5x reduction)
- After smoothing: Further reduction
- Final strain rate: e^-12 instead of e^-10

## Solution Options

1. **Switch to `downsample()`** (no anti-aliasing, preserves amplitude)
   - Risk: Aliasing artifacts in frequency domain
   - Benefit: Correct amplitude

2. **Use `resample()` with custom parameters** (better amplitude preservation)
   - Risk: Still some amplitude reduction
   - Benefit: Some anti-aliasing protection

3. **Custom decimation** (match advisor's method exactly)
   - Need to know advisor's exact code
   - Benefit: Matches expected results

4. **Keep `decimate()` but apply correction factor**
   - Current approach (4.5x correction)
   - You don't want this - need validation

