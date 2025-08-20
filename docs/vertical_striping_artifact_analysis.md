# Vertical Striping Artifact Analysis - DAS Data

## Observed Issue
**Recovery dataset** shows pronounced vertical banding/striping artifacts compared to **Full dataset** for the same 4-minute time window. Analysis reveals both datasets show the same striping pattern, but with different visual prominence.

## Key Findings
- **Processing is consistent:** Both datasets use identical Silixa and concatenation scripts
- **Visual scaling effect:** Recovery dataset's narrow dynamic range (`[-0.134, 0.012]`) vs Full dataset's wide range (`[-1.313, -0.011]`) makes same artifacts appear more pronounced
- **Striping alignment confirmed:** Artifacts align between datasets but are visually compressed in Full dataset

## Root Cause Analysis (by likelihood)

### 1. **File Concatenation Discontinuities** ⭐⭐⭐⭐⭐ **PRIMARY CAUSE**
- **Evidence:** Simple concatenation `decdata = [decdata; decmat]` with no boundary smoothing
- **Mechanism:** Each TDMS file (~1 minute) creates micro-gaps/phase jumps at boundaries
- **Impact:** Recovery dataset has 119 file boundaries in 2 hours vs distributed boundaries in 6+ hour Full dataset
- **Likelihood:** **VERY HIGH** - directly observable at 1-minute intervals

### 2. **Visual/Statistical Scaling Effects** ⭐⭐⭐⭐ **SECONDARY FACTOR**
- **Evidence:** Dynamic color bounds amplify noise visibility in Recovery dataset
- **Mechanism:** Same underlying artifacts appear more prominent with tighter color scaling
- **Impact:** Recovery dataset's shorter time span provides less statistical averaging
- **Likelihood:** **HIGH** - confirmed by visual analysis

### 3. **Temporal Coherence Differences** ⭐⭐ **MINOR FACTOR**
- **Evidence:** Different file boundary densities between datasets
- **Mechanism:** Shorter extraction windows don't average out systematic errors as effectively
- **Likelihood:** **MODERATE** - secondary effect

## Mitigation Strategy

### **Primary Fix: Boundary Smoothing in Concatenation**
```matlab
% Replace simple concatenation with overlap smoothing
overlap_samples = min(10, size(decdata,1), size(decmat,1));
window = hann(2*overlap_samples);
fade_out = window(1:overlap_samples);
fade_in = window(overlap_samples+1:end);

decdata(end-overlap_samples+1:end,:) = ...
    decdata(end-overlap_samples+1:end,:) .* fade_out + ...
    decmat(1:overlap_samples,:) .* fade_in;
```

### **Alternative: Post-processing Detrending**
```matlab
% Remove linear trends after concatenation
for ch = 1:size(decdata,2)
    decdata(:,ch) = detrend(decdata(:,ch), 'linear');
end
```

## Conclusion
**Vertical striping is real data artifact requiring engineering solutions, not visual adjustments.** File concatenation discontinuities are the primary cause, with visual scaling effects making them more apparent in shorter datasets.
