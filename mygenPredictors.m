function [X, dates, labels] = mygenPredictors(data)

dates = data.NumDate + (data.Hour-7)/16;

% % Short term forecasting inputs
% % Lagged load inputs
prevDaySameHourLoad = [NaN(16,1); data.SYSLoad(1:end-16)];
prevWeekSameHourLoad = [NaN(112,1); data.SYSLoad(1:end-112)];
prev16HrAveLoad = filter(ones(1,16)/16, 1, data.SYSLoad);

% Date predictors
dayOfWeek = weekday(dates);

% Non-business days
isWorkingDay = ~ismember(dayOfWeek,[6 7]);

X = [data.DryBulb data.Hour dayOfWeek isWorkingDay prevWeekSameHourLoad prevDaySameHourLoad prev16HrAveLoad];
labels = {'DryBulb', 'Hour', 'Weekday', 'IsWorkingDay', 'PrevWeekSameHourLoad', 'prevDaySameHourLoad', 'prev24HrAveLoad'};

%X = [data.DryBulb data.Hour dayOfWeek isWorkingDay];
%labels = {'DryBulb', 'Hour', 'Weekday', 'IsWorkingDay'};


end