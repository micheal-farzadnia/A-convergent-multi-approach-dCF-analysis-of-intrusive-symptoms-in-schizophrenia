%% just after clustering ...

load('gr_dfnc_post_process.mat');
ipt = input('Please enter which iteration of LOO you are in: ');

x = {};
for i=1:130
    x{i} = clusterInfo.states(:, :, i); 
end
x=cell2mat(x);

y=0;
numMissing = zeros(size(x, 1), 1);

userInput = 4;

for i=1:size(x, 1)
    if std(x(i,:))==0
        y=y+1;
    end
    niqueValues = unique(x(i, :));
    numMissing(i) = userInput - sum(ismember(1:userInput, niqueValues));

end
gr
mx = max(numMissing);
sm = sum(numMissing);
disp(mx);
disp(sm);

%% saving seq of states of training folds with cluster centroid of the current run

if mx==0 && sm==0
    files = dir('seq*.mat');  
    count = numel(files);      % Count how many such files
    if count == 0 && ipt == 1
            c = clusterInfo.Call;
            save(['seq',num2str(count+1),'.mat'],'x','c');
    elseif count == ipt 

    elseif count < ipt
            c = clusterInfo.Call;
            save(['seq',num2str(count+1),'.mat'],'x','c');        
    end
end