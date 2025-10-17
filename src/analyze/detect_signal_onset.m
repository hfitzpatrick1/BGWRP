function onset_time = detect_signal_onset(data, time, data_type)
    %DETECT_SIGNAL_ONSET Detect when signal begins in time series data
    %
    % Inputs:
    %   data      - Time series data
    %   time      - Time vector
    %   data_type - 'strain' or 'head'
    %
    % Outputs:
    %   onset_time - Datetime when signal begins
    
    % Calculate baseline (first 20% of data)
    baseline_length = round(0.2 * length(data));
    baseline = data(1:baseline_length);
    baseline_mean = mean(baseline);
    baseline_std = std(baseline);
    
    % Set threshold based on data type
    if strcmp(data_type, 'strain')
        threshold = baseline_mean + 3 * baseline_std;  % 3-sigma threshold
    elseif strcmp(data_type, 'head')
        threshold = baseline_mean - 3 * baseline_std;  % Negative for drawdown
    end
    
    % Find first point exceeding threshold
    onset_idx = find(abs(data - baseline_mean) > abs(threshold - baseline_mean), 1, 'first');
    
    if isempty(onset_idx)
        onset_time = time(1);  % No clear onset detected
    else
        onset_time = time(onset_idx);
    end
    end