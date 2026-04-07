%% feature extraction m = k.(e+2) where e = 3 (i.e., sc-cc, sc-dmn, and cc-dmn) and k = 4, so m to be 20.
clc
clear
load('allFolds.mat');

fractional_win = [];
cm = [];
indices = 1:130:10790;

for i = 1:83
    filename = sprintf('seq%d.mat',i);
    if isfile(filename)
        data = load(filename);
        for j = 1:82
            %% temporal features: fractional windows and mean dwell time with #. of transitions
            state_vec = data.x(j,:);
            w = max(state_vec);
            fractional_win = zeros(1,w);
            for k = 1:w
                % fractional occupancy 
                fractional_win(k) = sum(state_vec == k) / length(state_vec);
                % mean dwell time
                mdt = compute_mdt(state_vec);
            end
            % total transitions
            total_transitions = sum(diff(state_vec) ~= 0);
            allFolds{i,3}(j,:) = [fractional_win, mdt, total_transitions]; 

            %% state-wise features
            % find indices
            a = find(data.x(j,:)==1);
                sc_cc = allFolds{i,1}(indices(j):indices(j)+129,1);
                cm{i}(j,1) = mean(sc_cc(a));
                sc_dmn = allFolds{i,1}(indices(j):indices(j)+129,2);
                cm{i}(j,2) = mean(sc_dmn(a));
                cc_dmn = allFolds{i,1}(indices(j):indices(j)+129,3);
                cm{i}(j,3) = mean(cc_dmn(a));                
            b = find(data.x(j,:)==2);
                sc_cc = allFolds{i,1}(indices(j):indices(j)+129,1);
                cm{i}(j,4) = mean(sc_cc(b));
                sc_dmn = allFolds{i,1}(indices(j):indices(j)+129,2);
                cm{i}(j,5) = mean(sc_dmn(b));
                cc_dmn = allFolds{i,1}(indices(j):indices(j)+129,3);
                cm{i}(j,6) = mean(cc_dmn(b));                            
            c = find(data.x(j,:)==3);
                sc_cc = allFolds{i,1}(indices(j):indices(j)+129,1);
                cm{i}(j,7) = mean(sc_cc(c));
                sc_dmn = allFolds{i,1}(indices(j):indices(j)+129,2);
                cm{i}(j,8) = mean(sc_dmn(c));
                cc_dmn = allFolds{i,1}(indices(j):indices(j)+129,3);
                cm{i}(j,9) = mean(cc_dmn(c));                
            d = find(data.x(j,:)==4);
                sc_cc = allFolds{i,1}(indices(j):indices(j)+129,1);
                cm{i}(j,10) = mean(sc_cc(d));
                sc_dmn = allFolds{i,1}(indices(j):indices(j)+129,2);
                cm{i}(j,11) = mean(sc_dmn(d));
                cc_dmn = allFolds{i,1}(indices(j):indices(j)+129,3);
                cm{i}(j,12) = mean(cc_dmn(d));                
            
        end
    else 
        warning('File %s not found', filename);
    end
end

%% concatenate temporal and state-wise features into a unified dataset

ds = [];
    for i = 1:83
        ds{i,1} = allFolds{i,3};
        ds{i,1}(:,10:21) = cm{i};
    end
ds = cellfun(@(x) x(:,5:end), ds, 'UniformOutput', false);

save('folds.mat','ds');