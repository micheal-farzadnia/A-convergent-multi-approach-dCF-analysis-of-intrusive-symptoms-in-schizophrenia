clc;
clear all;

subject_ids = 90:172;                 % All subject numbers
n_subjects = length(subject_ids);     % 83
allFolds = cell(n_subjects, 1);       % To store 83 folds (normalized)

for i = 1:n_subjects
    excluded_id = subject_ids(i);     % This subject is excluded
    combined_dFNC = [];               % Accumulate 130×406 per subject

    for j = 1:n_subjects
        subj_id = subject_ids(j);
        if subj_id == excluded_id
            continue;  % Skip excluded subject
        end

        % Build file name
        if subj_id < 100
            file_name = sprintf('gr_dfnc_sub_0%d_sess_001_results.mat', subj_id);
        else
            file_name = sprintf('gr_dfnc_sub_%d_sess_001_results.mat', subj_id);
        end

        % Load and append
        if isfile(file_name)
            tmp = load(file_name);  % Expects FNCdyn inside
            combined_dFNC = [combined_dFNC; tmp.FNCdyn];  % 130×406 per subject
        else
            warning('File %s not found.', file_name);
        end
    end


    % Store normalized fold
    allFolds{i} = combined_dFNC;
    %allFolds{i} = normalized_dFNC;

end

%% average edges of each domain.
for i = 1:n_subjects
    fold_data = allFolds{i};  % 10660 x 406
    n_rows = size(fold_data, 1);

    mdn = zeros(n_rows, 3);  % For 3 ICN means

    for j = 1:n_rows
        row_vec = fold_data(j, :);  % 1x406

        % --- median ---
        mdn(j,1) = mean([row_vec(5:21),row_vec(32:48),row_vec(58:74),row_vec(83:99),row_vec(107:123)]);

        mdn(j,2) = mean([row_vec(22:28),row_vec(49:55),row_vec(75:81),row_vec(100:106),row_vec(124:130)]);

        mdn(j,3) = mean([row_vec(147:153),row_vec(169:175),row_vec(190:196), ...
            row_vec(210:216), row_vec(229:235),row_vec(247:253), ...
             row_vec(264:270), row_vec(280:286), row_vec(295:301), row_vec(309:315),...
                             row_vec(322:328), row_vec(334:340), row_vec(345:351), row_vec(355:361),...
                             row_vec(364:370), row_vec(372:378), row_vec(379:385)]);

     end

    % Store result: [mean1 mean2 mean3]
    allFolds{i,2} = mdn;  % Size: n_rows x 3
    
    if i == n_subjects
       save('allFolds');
    end
end
