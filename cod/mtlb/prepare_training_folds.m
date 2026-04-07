%% step1 - the preparation of training folds' parameters used for N times of clustering

s = input('Please enter the number of samples:');
disp(['The number of samples entered is: ',num2str(s)]);

if dfncInfo.userInput.numOfSub == 172
        load('gr_dfnc.mat');
        dfncInfo.userInput.ica_param_file=[];
        dfncInfo.userInput.numOfSub = s - 1;
        dfncInfo.TR(1:s+7)=[];
        dfncInfo.best_lambda(1:s+7) = [];
        dfncInfo.outputFiles(1:s+6) = [];
        save('gr_dfnc.mat');
end

for i=1:s
        load('gr_dfnc.mat');
        dfncInfo.outputFiles(:,i)=[];
        save([num2str(i),'.mat']);
end