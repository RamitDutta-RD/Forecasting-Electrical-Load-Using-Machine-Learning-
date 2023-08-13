clc
clear all
close all

%% Import Load Data

[num, text] = xlsread('LoadDataFINAL.xlsx');
% total = [];
% 
% for i=1:length(text(1,:))
%     labels = cell2mat(text(1,i));
%     if i>1
%         total = [total ' ' labels];
%     else
%         total = [total labels];
%     end   
% end

dates = cell2mat(text(2:end,1));
date_num = datenum(dates);

data.Hour = num(:,1);
data.DryBulb = num(:,2);
data.SYSLoad = num(:,3);
data.NumDate = date_num;

%% Generating Predictor variables

[X, dates, labels] = mygenPredictors(data);

%% Split the dataset to create a Training and Test set

% Create training set
trainInd = data.NumDate <= datenum('04-20-2019');
trainX = X(trainInd,:);
trainY = data.SYSLoad(trainInd);

% Create test set
testInd = data.NumDate >= datenum('04-21-2019') & data.NumDate <= datenum('04-30-2019'); 
testX = X(testInd,:);
testY = data.SYSLoad(testInd);
testDates = dates(testInd);

% save for later
save testSet testDates testX testY
%clear X data trainInd testInd dates date_num num text

%% Initialize and Train Network

reTrain = false;
if reTrain || ~exist('NNModel.mat', 'file')
    net = newfit(trainX', trainY', 20);
    net.performFcn = 'mse';
    net = train(net, trainX', trainY');
    save NNModel.mat net
else
    load NNModel.mat
end

%% Forecast using Neural Network Model
% Once the model is built, perform a forecast on the independent test set.

load testSet
forecastLoad = sim(net, testX')';

%% Compare Forecast Load and Actual Load

err = testY-forecastLoad;
%figure(1),fitPlot(testDates, [testY forecastLoad], err);

errpct = abs(err)./testY*100;

fL = reshape(forecastLoad, 16, length(forecastLoad)/16)';
tY = reshape(testY, 16, length(testY)/16)';
peakerrpct = abs(max(tY,[],2) - max(fL,[],2))./max(tY,[],2) * 100;

MAE = mean(abs(err));
MAPE = mean(errpct(~isinf(errpct)));

fprintf('Mean Absolute Percent Error (MAPE): %0.2f%% \nMean Absolute Error (MAE): %0.2f KWh\nDaily Peak MAPE: %0.2f%%\n',...
    MAPE, MAE, mean(peakerrpct))


%% Examine Distribution of Errors

figure(1),subplot(3,1,1); 
hist(err, min(err): (max(err)-min(err))/100 : max(err) ); title('Error distribution'); xlim([min(err) max(err)]);
subplot(3,1,2); 
hist(abs(err), min(abs(err)): (max(abs(err))-min(abs(err)))/100 : max(abs(err)) ); title('Absolute Error distribution'); xlim([min(abs(err)) max(abs(err))]);
line([MAE MAE], ylim); legend('Errors', 'MAE');
subplot(3,1,3);
hist(errpct, min(errpct): (max(errpct)-min(errpct)/100 : max(errpct) )); title('Absolute Percent Error distribution'); 
xlim([min(errpct) max(errpct)]);
line([MAPE MAPE], ylim); legend('Errors', 'MAPE');

%% Group Analysis of Errors

[yr, mo, da, hr] = datevec(testDates);

% By Hour
figure(3)
for i=0:9
    for j=1:16
        hr(i*16+j) = j+7;
    end
end
boxplot(errpct, hr);
xlabel('Hour'); ylabel('Percent Error Statistics');
title('Breakdown of forecast error statistics by hour');

% By Weekday
figure(4)
boxplot(errpct, weekday(floor(testDates)), 'labels', {'Sun','Mon','Tue','Wed','Thu','Fri','Sat'});
ylabel('Percent Error Statistics');
title('Breakdown of forecast error statistics by weekday');



%% forcasting load
forecastData = [];
for i=1:7
    disp(labels(i))
    forecastData = [forecastData str2num(input('','s'))];
end
save forecastData.mat forecastData
format long g
demandedLoad = sim(net, forecastData')'
format short





















demandedLoad = mean(forecastData(end-2:end))+7.45;