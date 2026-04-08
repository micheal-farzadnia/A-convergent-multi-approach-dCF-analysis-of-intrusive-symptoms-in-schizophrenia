load("folds.mat");
load("dfnc_ts.mat");
targets = readtable('targets.csv');

colnames = {'s1sc-cc', 's1sc-dm', 's1cc-dm', 's2sc-cc', 's2sc-dm', 's2cc-dm', 's3sc-cc', 's3sc-dm', 's3cc-dm', 's4sc-cc', 's4sc-dm', 's4cc-dm'};

for i=1:83
    [a,mu,sigma] = zscore(ds{i,1}(:,6:17));
    T = array2table(a, 'VariableNames', colnames);
    S = array2table(dfnc_ts{i,4}(:,6:17),'VariableNames',colnames);

    % assign target labels to training folds

    %T{:,18} = targets{[1:i-1, i+1:83],2}; % hallucinatory behavior
    %T{:,19} = targets{[1:i-1, i+1:83],3}; % hallucinatory behavior (categorized)
    %T{:,20} = targets{[1:i-1, i+1:83],5}; % unusual thoughts content
    %T{:,21} = targets{[1:i-1, i+1:83],6}; % unusual thoughts content (categorized)
    %T{:,22} = targets{[1:i-1, i+1:83],8}; % unusual thoughts content
    %T{:,23} = targets{[1:i-1, i+1:83],9}; % unusual thoughts content (categorized)    

    % assign target labels to testing folds

    %S{:,18} = targets{i,2}; % hallucinatory behavior
    %S{:,19} = targets{i,3}; % hallucinatory behavior (categorized)
    %S{:,20} = targets{i,5}; % unusual thoughts content
    %S{:,21} = targets{i,6}; % unusual thoughts content (categorized)
    %S{:,22} = targets{i,8}; % unusual thoughts content
    %S{:,23} = targets{i,9}; % unusual thoughts content (categorized)   


    %% 

    T{:,13} = targets{[1:i-1, i+1:83],2}; % hallucinatory behavior
    T{:,14} = targets{[1:i-1, i+1:83],3}; % hallucinatory behavior (categorized)
    T{:,15} = targets{[1:i-1, i+1:83],5}; % unusual thoughts content
    T{:,16} = targets{[1:i-1, i+1:83],6}; % unusual thoughts content (categorized)
    T{:,17} = targets{[1:i-1, i+1:83],8}; % unusual thoughts content
    T{:,18} = targets{[1:i-1, i+1:83],9}; % unusual thoughts content (categorized)    
    T{:,19} = targets{[1:i-1, i+1:83],10}; % unusual thoughts content (categorized)    

    % assign target labels to testing folds

    S{:,13} = targets{i,2}; % hallucinatory behavior
    S{:,14} = targets{i,3}; % hallucinatory behavior (categorized)
    S{:,15} = targets{i,5}; % unusual thoughts content
    S{:,16} = targets{i,6}; % unusual thoughts content (categorized)
    S{:,17} = targets{i,8}; % unusual thoughts content
    S{:,18} = targets{i,9}; % unusual thoughts content (categorized)  
    S{:,19} = targets{i,10}; % unusual thoughts content (categorized)  


    writetable(T, ['trn_',num2str(i),'.csv']);
    writetable(S, ['tst_',num2str(i),'.csv']);
end

