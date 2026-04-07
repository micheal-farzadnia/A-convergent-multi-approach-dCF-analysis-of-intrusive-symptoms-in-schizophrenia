clc; clear;
rng(1,'twister');

%% ============================================================
% USER SETTINGS
%% ============================================================
StateID=input("Enter the state number you want me to work on: ");

%% ============================================================
% Load all window-level FC matrices
%% ============================================================
dFNC = [];
subject_ids = 90:172;

for s = 1:83
    subj_id = subject_ids(s);
    if subj_id < 100
        file_name = sprintf('gr_dfnc_sub_0%d_sess_001_results.mat', subj_id);
    else
        file_name = sprintf('gr_dfnc_sub_%d_sess_001_results.mat', subj_id);
    end
    tmp = load(file_name);
    dFNC = [dFNC; tmp.FNCdyn];
end

%% ============================================================
% Load state labels
%% ============================================================
data = load("seq1.mat");
x = data.x;

%% ============================================================
% Indexing
%% ============================================================
Nsub = 83;
Nwin = 130;
indices = reshape(1:(Nsub*Nwin), Nwin, Nsub)';

%% ============================================================
% Compute subject-wise mean FC for chosen state
%% ============================================================
cm = zeros(Nsub, size(dFNC,2));

for s = 1:Nsub
    rows = indices(s,:);
    w = (x(s,:) == StateID);
    cm(s,:) = mean(dFNC(rows(w),:),1);
end

%% ============================================================
% Defining Hypothesis-driven edges selection
%% ============================================================
orange_edges = [ ...
147:153,169:175,190:196,210:216,229:235,247:253, ...
264:270,280:286,295:301,309:315,322:328,334:340, ...
345:351,355:361,364:370,372:378,379:385 ];

OrangeGrid = reshape(orange_edges,[7 17])';

%% ============================================================
% Column / Row selection
%% ============================================================

if StateID == 3
    row_sets = {[2 14]};
    col_inx = {1:7};
elseif StateID == 4
    row_sets = {[2 5 12 14 17]};
    col_inx = {[3 4 5 7]};
end

%% ============================================================
% Load behavioral variable
%% ============================================================
T = readtable("targets.csv");
labels = {'abs','min','mild','mod','mods','sev','ext'};

if StateID == 3
    Y = categorical(T{:,2},labels,'Ordinal',true);
elseif StateID == 4
    Y = categorical(T{:,8},labels,'Ordinal',true);
end

Y = grp2idx(Y);

%% ============================================================
% Permutation parameters
%% ============================================================
n_pem = 10000;
alpha_fdr = 0.05;

results = struct();
iter = 0;

%% ============================================================
% MAIN LOOP
%% ============================================================
for r = 1:length(row_sets)
    rows = row_sets{r};

    for c = 1:length(col_inx)
        cols = col_inx{c};
        iter = iter + 1;

        selected_edges = OrangeGrid(rows,cols);
        selected_edges = selected_edges(:)';

        cmSub = cm(:,selected_edges);
        E = size(cmSub,2);

        rho_obs = zeros(1,E);
        rho_ci_low = zeros(1,E);
        rho_ci_high = zeros(1,E);
        cohens_d = zeros(1,E);

        %% --- Effect sizes and CIs ---
        for e = 1:E
            r_val = corr(cmSub(:,e),Y,'type','Spearman');
            rho_obs(e) = r_val;

            % Fisher Z CI
            z = atanh(r_val);
            se = 1/sqrt(Nsub - 3);
            z_low = z - 1.96*se;
            z_high = z + 1.96*se;

            rho_ci_low(e) = tanh(z_low);
            rho_ci_high(e) = tanh(z_high);

            % Cohen's d equivalent
            cohens_d(e) = 2*r_val / sqrt(1 - r_val^2);
        end

        %% --- Permutation p-values ---
        p_perm = zeros(1,E);
        rho_p = zeros(1,E);

        for p = 1:n_pem
            Yp = Y(randperm(Nsub));
            for e = 1:E
                rho_p(e) = corr(cmSub(:,e),Yp,'type','Spearman');
                p_perm(e) = p_perm(e) + (abs(rho_p(e)) >= abs(rho_obs(e)));
            end
        end
        p_perm = (p_perm + 1) ./ (n_pem + 1);

        p_fdr = mafdr(p_perm,'BHFDR',true);

        %% --- Store ---
        results(iter).Edges = selected_edges;
        results(iter).rho = rho_obs;
        results(iter).rho_ci_low = rho_ci_low;
        results(iter).rho_ci_high = rho_ci_high;
        results(iter).cohens_d = cohens_d;
        results(iter).p_fdr = p_fdr;

        %% --- Print (Effect-Size Focused Reporting) ---
        fprintf('\nState %d ',StateID);
        fprintf('Edge\t rho\t 95%% CI\t\t Cohen_d\t p_FDR\n');

        for k = 1:E
            fprintf('%d\t %.3f\t [%.3f, %.3f]\t %.3f\t %.4f\n', ...
                selected_edges(k), ...
                rho_obs(k), ...
                rho_ci_low(k), ...
                rho_ci_high(k), ...
                cohens_d(k), ...
                p_fdr(k));
        end
    end
end

fprintf('\nTOTAL ITERATIONS: %d\n',iter);
fprintf('State %d analysis complete.\n',StateID);

%% ============================================================
% PLOTTING (Effect size + CI emphasized)
%% ============================================================

for iter = 1:length(results)

    edges = results(iter).Edges;
    rho = results(iter).rho;
    ci_low = results(iter).rho_ci_low;
    ci_high = results(iter).rho_ci_high;
    p_fdr = results(iter).p_fdr;

    x_labels = strings(1,length(edges));
    for k = 1:length(edges)
        [r,c] = find(OrangeGrid == edges(k));
        x_labels(k) = sprintf('R%dC%d(%d)', r, c, edges(k));
    end

    figure('Color','w','Position',[100 100 1400 600]);

    %% --- Plot rho with 95% CI ---
    errorbar(1:length(edges), rho, ...
        rho - ci_low, ...
        ci_high - rho, ...
        'o','LineWidth',1.5);


    hold on
    yline(0,'--k');
    grid on

    ylabel('Spearman rho (95% CI)');
    xticks(1:length(edges));
    xticklabels(x_labels);
    xtickangle(45);
    xlabel('Edge');

    title(sprintf('Effect Sizes with 95%% CI'));

    hold off

    %% --- Separate figure for p-values (not privileged) ---
    figure('Color','w','Position',[200 200 1400 400]);
    scatter(1:length(edges), -log10(p_fdr), 70, 'filled');
    yline(-log10(0.05),'--r','FDR 0.05');
    grid on
    xticks(1:length(edges));
    xticklabels(x_labels);
    xtickangle(45);
    ylabel('-log_{10}(p_{FDR})');
    title(sprintf('Permutation-based FDR values'));
end


% --- Set-level statistic (observed) ---
S_obs = sum(rho_obs);   % or mean(rho_obs)
S_null = zeros(n_pem,1);

for p = 1:n_pem
    Yp = Y(randperm(Nsub));

    rho_p = zeros(1,E);

    for e = 1:E
        rho_p(e) = corr(cmSub(:,e),Yp,'type','Spearman');
    end

    % Set-level statistic for this permutation
    S_null(p) = sum(rho_p);   % same as S_obs definition
end

p_set = (sum(abs(S_null) >= abs(S_obs)) + 1) / (n_pem + 1);

fprintf('\nSET-LEVEL RESULT:\n');
fprintf('S_obs = %.4f, p = %.5f\n', S_obs, p_set);
