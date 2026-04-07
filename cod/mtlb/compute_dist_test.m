%% Compute minimum distances from the centroids to determine which state each window from the dFNC test belongs to

clc
clear

dis = [];
mn_ds = [];
count = [];
counts = [];
dfnc_ts = [];
q = 0;

load('folds.mat');

%% Assign windows to states
for i = 1:83
    load(['seq', num2str(i), '.mat']);
    
    if i <= 10
        load(['gr_dfnc_sub_0', num2str(i + 89), '_sess_001_results.mat']);
    else
        load(['gr_dfnc_sub_', num2str(i + 89), '_sess_001_results.mat']);
    end

    for j = 1:130
        for k = 1:4
            dis(k) = icatb_corr2(c(k, :), FNCdyn(j, :));
        end
        [~, mn_ds] = min(dis);
        dfnc_ts{i, 1}(j) = mn_ds;  % state sequence of dFNC test
    end

    % Check if all 4 states are present
    unique_states = unique(dfnc_ts{i, 1});
    if numel(unique_states) < 4
        disp(['The test sample ', num2str(i), ' includes less than 4 states --> ', num2str(unique_states)]);
        q = q + 1;

        % Count the occurrences of each state
        state_counts = zeros(1, 4);
        for state = 1:4
            state_counts(state) = sum(dfnc_ts{i, 1} == state);
        end

        counts = [counts; state_counts, i];
        disp(counts);
    end
end

%% Temporal and State-wise Features
for i = 1:83

    %% Temporal features
    fractional_win = zeros(1, 4);
    mdt = compute_mdt(dfnc_ts{i});
    mdt_full = zeros(1, 4);

    for k = 1:4
        fractional_win(k) = sum(dfnc_ts{i} == k) / length(dfnc_ts{i});
    end

    mdt_idx = 1;
    for k = 1:4
        if fractional_win(k) > 0
            if mdt_idx <= length(mdt)
                mdt_full(k) = mdt(mdt_idx);
                mdt_idx = mdt_idx + 1;
            end
        else
            mdt_full(k) = 0;
        end
    end

    total_transitions = sum(diff(dfnc_ts{i}) ~= 0);
    dfnc_ts{i, 2} = [fractional_win, mdt_full, total_transitions];

    %% State-wise mean features
    if i <= 10
        load(['gr_dfnc_sub_0', num2str(i + 89), '_sess_001_results.mat']);
    else
        load(['gr_dfnc_sub_', num2str(i + 89), '_sess_001_results.mat']);
    end

    meanMat = zeros(130, 3);

    for j = 1:130
        meanMat(j, 1) = mean([FNCdyn(j, 5:21), FNCdyn(j, 32:48), FNCdyn(j, 58:74), FNCdyn(j, 83:99), FNCdyn(j, 107:123)]);
        meanMat(j, 2) = mean([FNCdyn(j, 22:28), FNCdyn(j, 49:55), FNCdyn(j, 75:81), FNCdyn(j, 100:106), FNCdyn(j, 124:130)]);
        meanMat(j, 3) = mean([FNCdyn(j, 147:153), FNCdyn(j, 169:175), FNCdyn(j, 190:196), FNCdyn(j, 210:216), ...
                              FNCdyn(j, 229:235), FNCdyn(j, 247:253), FNCdyn(j, 264:270), FNCdyn(j, 280:286), ...
                              FNCdyn(j, 295:301), FNCdyn(j, 309:315), FNCdyn(j, 322:328), FNCdyn(j, 334:340), ...
                              FNCdyn(j, 345:351), FNCdyn(j, 355:361), FNCdyn(j, 364:370), FNCdyn(j, 372:378), ...
                              FNCdyn(j, 379:385)]);
    end

    cm = zeros(12, 1); % 4 states × 3 features

    % State 1
    idx = find(dfnc_ts{i} == 1);
    if ~isempty(idx)
        cm(1) = mean(meanMat(idx, 1));
        cm(2) = mean(meanMat(idx, 2));
        cm(3) = mean(meanMat(idx, 3));
    end

    % State 2
    idx = find(dfnc_ts{i} == 2);
    if ~isempty(idx)
        cm(4) = mean(meanMat(idx, 1));
        cm(5) = mean(meanMat(idx, 2));
        cm(6) = mean(meanMat(idx, 3));
    end

    % State 3
    idx = find(dfnc_ts{i} == 3);
    if ~isempty(idx)
        cm(7) = mean(meanMat(idx, 1));
        cm(8) = mean(meanMat(idx, 2));
        cm(9) = mean(meanMat(idx, 3));
    end

    % State 4
    idx = find(dfnc_ts{i} == 4);
    if ~isempty(idx)
        cm(10) = mean(meanMat(idx, 1));
        cm(11) = mean(meanMat(idx, 2));
        cm(12) = mean(meanMat(idx, 3));
    end

    dfnc_ts{i, 3} = cm;

    %% Zero out features if fractional occupancy is zero
    fractional_win = dfnc_ts{i, 2}(1:4);
    for state_idx = 1:4
        if fractional_win(state_idx) == 0
            start_idx = (state_idx - 1) * 3 + 1;
            end_idx = start_idx + 2;
            dfnc_ts{i, 3}(start_idx:end_idx) = 0;
        end
    end

    %% Final feature vector
    dfnc_ts{i, 4} = [dfnc_ts{i, 2}(5:9), transpose(dfnc_ts{i, 3})];
end

save('dfnc_ts.mat', 'dfnc_ts');
