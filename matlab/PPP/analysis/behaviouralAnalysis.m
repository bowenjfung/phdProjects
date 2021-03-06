%% PPP Behavioural data analyses
% Bowen J Fung, 2016

%% Get data, setup and clean
participants = 1:52;
for tidiness = 1
    oldcd = cd('/Volumes/333-fbe/DATA/TIMEJUICE/PPP/behavioural');
    %     load('trialDataPilot.mat');
    %     trialDataPilot.flag(trialDataPilot.id == 10) = 1;
    %     load('trialDataJuice.mat');
    %     load('trialDataMoney.mat');
    %     load('trialDataWater.mat');
    [trialData, thirst] = getData(participants);
    cd(oldcd);
    % Add type (5/6) to data matrix depending on type:
    Aspartame = [9:16,26:35,44:52];
    Glucose = [1:8,17:25,36:43];
    T = table(ones(height(trialData),1),'VariableNames',{'type'});
    T.type(ismember(trialData.id,Glucose)) = T.type(ismember(trialData.id,Glucose)) + 4;
    T.type(ismember(trialData.id,Aspartame)) = T.type(ismember(trialData.id,Aspartame)) + 5;
    trialData = [T, trialData];
    
    % Merge data
    %     T = table(ones(height(trialDataJuice),1),'VariableNames',{'type'});
    %     trialDataJuice = [T,trialDataJuice];
    %     T.type = T.type + 1;
    %     trialDataMoney = [T,trialDataMoney];
    %     T.type = T.type + 1;
    %     trialDataWater = [T,trialDataWater];
    %     T = table(ones(height(trialDataPilot),1),'VariableNames',{'type'});
    %     T.type = T.type + 3;
    %     trialDataPilot = [T,trialDataPilot];
    %     trialData = [trialDataJuice;trialDataMoney;trialDataWater;trialDataPilot];
    
    % Remove missing and recode
    %     trialData(trialData.type == 1 & trialData.id == 18,:) = [];
    %     trialData.id(trialData.type == 1 & trialData.id > 18) = trialData.id(trialData.type == 1 & trialData.id > 18) - 1;
    %
    % Plot settings
    set(0,'DefaultAxesColorOrder',...
        [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556]);
    colormap = [0 0.447 0.741; 0.85 0.325 0.098; 0.443 0.82 0.6; 0.929 0.694 0.1250; 0.494 0.184 0.556];
    set(0,'DefaultFigureColor',[1 1 1]);
    set(0,'DefaultAxesFontSize',20);
    delays = unique(trialData.delay);
    %barColour = {[0.15 0.15 0.15],[.3 .3 .3],[.45 .45 .45],[.6 .6 .6],[0.75 0.75 0.75],[0.9 0.9 0.9]};
    barColour = {[0.6824 0.1961 0.3255],[0.8431 0.3412 0.2980],[0.9686 0.7294 0.4157],...
        [0.9490 0.8039 0.5686],[0.7647 0.6941 0.5961],[0.3255 0.5255 0.5647]};
    errorColour = [0.4 0.4 0.4];
    
    
    % Clean data
    trialData.flag = zeros(size(trialData,1),1);
    for x = participants
        for d = 1:numel(delays)
            missed(x,d) = sum(isnan(trialData.response(trialData.id == x & trialData.delay == delays(d))));
        end
    end
    trialData.flag(isnan(trialData.response)) = 1; % Mark missed responses as excluded
    TH = 2.5;
    ploton = 0;
    warning('off',char('MATLAB:legend:IgnoringExtraEntries'));
    for x = participants
        if ploton
            figure;
        end
        temp = trialData(trialData.id == x & trialData.flag == 0,:);
        for d = 1:numel(delays)
            temp2 = temp(temp.delay == delays(d),:);
            i = trialData.id == x & trialData.delay == delays(d) & trialData.flag == 0;
            
            % Get mean and std for each delay
            M(x,d) = mean(temp2.response);
            SD(x,d) = std(temp2.response);
            
            [N,X] = hist(temp2.response,10);
            try
                f1 = fit(X', N', ...
                    'gauss1', 'Exclude',...
                    X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d))); % Fit to included data
            catch
                fprintf('Could not fit gaussian, not enough data.\nThis may be because delays are ill-defined\n');
                continue;
            end
            if ploton
                subplot(2,2,d);
                h = plot(f1,X,N,X < (M(x,d) - TH.*SD(x,d)) | X > (M(x,d) + TH.*SD(x,d)));
                if size(h,1) == 3
                    set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o');...
                        set(h(2), 'Color', [0.443 0.82 0.6], 'Marker', '*');...
                        set(h(3), 'Color', [0.85 0.325 0.098]);
                    legend('Data','Excluded data','Fitted normal distribution');
                else
                    set(h(1), 'Color', [0 0.447 0.741], 'Marker', 'o');...
                        set(h(2), 'Color', [0.85 0.325 0.098]);
                    legend('Data','Fitted normal distribution');
                end
                hold on
                plot(repmat(delays(d)./2, 1, max(N) + 1), 0:max(N),...
                    'LineStyle', '--', 'Color', [0.85 0.325 0.098]);
                ylabel('Response frequency');
                xlabel('Response (secs)');
                title(sprintf('Participant %.0f, %.0f seconds', x, delays(d)));
            end
            trialData.flag(i) = trialData.flag(i) + temp2.response...
                < (M(x,d) - TH.*SD(x,d)) | temp2.response > (M(x,d) + TH.*SD(x,d)); % Create exclusion logical
            excluded(x,d) = sum(temp2.response < (M(x,d) - TH.*SD(x,d)) | temp2.response > (M(x,d) + TH.*SD(x,d)));
            fprintf('%.0f trials excluded for participant %.0f in delay %.0f.\n',...
                sum(temp2.response < (M(x,d) - TH.*SD(x,d)) | temp2.response > (M(x,d) + TH.*SD(x,d))),x,delays(d));
        end
        clearvars -except trialData amounts delays participants TH x exclude M SD ploton errorColour barColour trialDataJuice trialDataMoney thirst missed excluded Aspartame Glucose
    end
    fprintf('Total of %.0f trials excluded. %.0f were missed\n',sum(trialData.flag), sum(isnan(trialData.response)));
    warning('on',char('MATLAB:legend:IgnoringExtraEntries'))
    
    % Exclude first 5 trials
    trialData.flag(trialData.trial <=5) = 1;
    
    clearvars -except trialData amounts delays errorColour barColour participants trialDataJuice trialDataMoney thirst missed excluded Aspartame Glucose
    
    
    % Create new variables
    for tidiness2 = 1
        % Preallocate new variables
        % Response variables
        trialData.accuracy = trialData.response - trialData.delay./2;
        trialData.normResponse = nan(height(trialData),1); % Normalised by participant
        trialData.normAccuracy = nan(height(trialData),1); % Normalised by delay (within participant)
        trialData.lagResponse = nan(height(trialData),1);
        trialData.lagNormAccuracy = nan(height(trialData),1);
        trialData.lagReward = nan(height(trialData),1);
        trialData.lagReward2 = nan(height(trialData),1);
        trialData.lagReward3 = nan(height(trialData),1);
        trialData.lagReward21 = nan(height(trialData),1);
        trialData.lagDelay = nan(height(trialData),1);
        trialData.rewardRate = nan(height(trialData),1);
        trialData.lagRewardRate = nan(height(trialData),1);
        trialData.windowReward = nan(height(trialData),1);
        
            for x = participants
                for d = 1:numel(delays)
                    trialData.normAccuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response))...
                        = zscore(trialData.accuracy(trialData.id == x & trialData.delay == delays(d) & ~isnan(trialData.response)));
                end
                temp = trialData(trialData.id == x,:);
                trialData.normResponse(trialData.id == x & ~isnan(trialData.response))...
                    = zscore(trialData.response(trialData.id == x & ~isnan(trialData.response)));
                % Condition variables
                trialData.lagResponse(trialData.id == x) = lagmatrix(temp.response,1);
                trialData.lagNormAccuracy(trialData.id == x) = lagmatrix(temp.normAccuracy,1);
                trialData.lagReward(trialData.id == x) = lagmatrix(temp.reward,1);
                trialData.lagReward2(trialData.id == x) = lagmatrix(temp.reward,2);
                trialData.lagReward3(trialData.id == x) = lagmatrix(temp.reward,3);
                trialData.lagReward21(trialData.id == x) = lagmatrix(temp.reward,21);
                trialData.lagDelay(trialData.id == x) = lagmatrix(temp.delay,1);
                trialData.windowReward(trialData.id == x) = tsmovavg(trialData.reward(trialData.id == x),'s',3,1);
            end
            
        % Theoretically relevant condition variables
        trialData.rewardRate = trialData.reward ./ (trialData.delay);
        trialData.lagRewardRate = trialData.lagReward ./ (trialData.lagDelay);
        
    end
    clearvars -except trialData amounts delays errorColour barColour thirst participants missed excluded Aspartame Glucose
    initialVars = who;
    initialVars{end+1} = 'initialVars';
    clearvars('-except',initialVars{:});
end

%%  Remove trouble participants (see participant notes)
toExclude = find(sum(missed,2) > 19.2); % i.e. 10 percent of all trials
toExclude = [10, toExclude']; % 10 did not drink liquid
trialData.flag(ismember(trialData.id, toExclude)) = 1;
participants(ismember(participants, toExclude)) = [];

%% Load preprocessed data
cd('/Users/Bowen/Documents/MATLAB/PPP');
load('trialData.mat');

%% Output text file for R (must do without changing reward variable coding)
writetable(trialData(trialData.type == 5 & trialData.flag == 0,:),'/Users/Bowen/Documents/R/PPP/trialDataGlucose(clean)');
writetable(trialData(trialData.type == 6 & trialData.flag == 0,:),'/Users/Bowen/Documents/R/PPP/trialDataAspartame(clean)');
writetable(trialData,'/Users/Bowen/Documents/R/PPP/trialDataPPP');

% Output means for R
for p = 1:52
    temp = trialData(trialData.id == p,:);
    [timeData(p,1:21)] = durationReproductionStats(temp.delay./2, temp.response);
    
    fit1 = fitlm([temp.delay./2],temp.response,'linear');
    timeData(p,22) = fit1.Coefficients{2,1};
    
    stevens =  'k*(x^b)'; % 3 parameter power function
    ft = fittype(stevens);
    [xData, yData] = prepareCurveData(temp.delay./2, temp.response);
    [FO, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    
    timeData(p,23) = FO.k;
    timeData(p,24) = FO.b;
    timeData(p,25) = G.rsquare;
    
    weber = 'a.*log(x)+c';
    
    ft = fittype(weber);
    [xData, yData] = prepareCurveData(temp.delay./2, temp.response);
    [F1, G] = fit(xData, yData, ft, 'StartPoint', [1 1], 'Robust', 'on');
    
    timeData(p,26) = F1.a;
    timeData(p,27) = F1.c;
    timeData(p,28) = G.rsquare;
end

timeData = array2table(timeData,'VariableNames',{'meanReproduction','stdReproduction','cvReproduction',...
        'meanDiff','stdDiff','cvDiff','meanAbsDiff','stdAbsDiff','cvAbsDiff',...
        'meanRelReproduction','stdRelReproduction','cvRelReproduction',...
        'meanSR','stdSR','cvSR','meanRelDiff','stdRelDiff','cvRelDiff',...
        'meanAbsError','stdAbsError','cvAbsError','delayCoef','stevens1','stevens2','stevensR',...
        'weber1','weber2','weberR'});

    % Stevens fits 46 better (88.5%), mean Rsquare 0.6710
    
writetable(timeData,'/Users/Bowen/Documents/R/PPP/timeData');

%% Check accuracies
t = 5; % Analyse either juice (1) or money (2) or water (3)
for tidiness = 1
    C = unique((trialData.id(trialData.type == t)))';
    for x = C
        temp = trialData(trialData.type == t & trialData.id == x,:); % Select participant WITH outliers
        temp = sortrows(temp,[2 3]); % Make sure data is in chronological order
        figure;
        plot(temp.accuracy);
        hold on
        plot(1:size(temp.accuracy,1), zeros(1,size(temp.accuracy,1)), 'LineStyle','--');
        xlim([0 size(temp.accuracy,1)]);
        ylim([-5 5]);
        ylabel('Devation (secs)');
        xlabel('Trial number');
        title(sprintf('Participant %.0f',x));
        
        allTrials = 1:size(temp.session);
        
        for s = [1, 2, 3]
            temp2 = temp(temp.session == s,:);
            subTrials = allTrials(temp.session == s);
            accuracy = temp2.response - (temp2.delay./2);
            plot(subTrials,accuracy);
        end
    end
    clearvars('-except',initialVars{:});
end

%% Individual regression stats (must do without changing reward variable coding)
t = 6; % Analyse either juice (1) or money (2) or water (3)
for tidiness = 1
    vars = {'reward','delay','lagReward','lagDelay','totalvolume','lagResponse'};
    plotVar = 2;
    C = unique((trialData.id(trialData.type == t)))';
    for x = C
        temp = trialData(trialData.id == x & trialData.type == t & trialData.flag == 0 & trialData.session == 2,:);
        for v = 1:numel(vars)
            predMatrix(:,v) = table2array(temp(:,vars{v}));
        end
        [beta{x},~,stats{x}] = glmfit(predMatrix,temp.response);
        clearvars predMatrix
    end
    c = 1;
    for x = C
        coeffs(c,:) = beta{x};
        probs(c,:) = stats{x}.p;
        se(c,:) = stats{x}.se;
        c = c + 1;
    end
    % Plot coefficients
    for plotVar = 2:numel(vars)+1
        figure;
        [dBar] = bar(coeffs(:,plotVar));
        set(dBar,'FaceColor',[0.85 0.325 0.098],'EdgeColor',[1 1 1]);
        hold on
        [hBar] = errorbar(coeffs(:,plotVar),se(:,plotVar));
        set(hBar,'LineStyle','none');
        for t = 1:numel(probs(:,plotVar))
            if probs(t,plotVar) < 0.1
                text(t - 0.1,0,'*','fontSize',25);
            end
        end
        xlim([0 26]);
        title(sprintf('%s beta coefficients',vars{plotVar-1}));
        xlabel('Participant');
        [h,p] = ttest(coeffs(:,plotVar)); % Print ttest results
        fprintf('%s\nh: %.0f\np: %.3f\n',vars{plotVar-1},h,p);
    end
    % Plot residuals
    % figure;
    % c = 1;
    % for x = participants
    %     subplot(5,5,c);
    %     plot(stats{x}.resid);
    %     xlim([0 160]);
    %     title(sprintf('Participant %.0f',x));
    %     c = c + 1;
    % end
    clearvars('-except',initialVars{:});
end

%% Change reward coding
for tidiness = 1
    trialData.lagReward(isnan(trialData.lagReward)) = 0;
    for t = 1:height(trialData)
        switch trialData.reward(t)
            case 0
                T{t} = 'no reward';
            case {0.5, 5}
                T{t} = 'small reward';
            case {1.2, 15}
                T{t} = 'medium reward';
            case {2.3, 30}
                T{t} = 'large reward';
        end
        switch trialData.lagReward(t)
            case 0
                T2{t} = 'no reward';
            case {0.5, 5}
                T2{t} = 'small reward';
            case {1.2, 15}
                T2{t} = 'medium reward';
            case {2.3, 30}
                T2{t} = 'large reward';
        end
    end
    trialData.reward = T';
    trialData.lagReward = T2';
    a = unique(trialData.reward);
    amounts(1) = a(3);
    amounts(2) = a(4);
    amounts(3) = a(2);
    amounts(4) = a(1);
    clearvars -except trialData amounts delays errorColour barColour
    initialVars = who;
    initialVars{end+1} = 'initialVars';
    clearvars('-except',initialVars{:});
end

%% Histograms
for tidiness = 1
    delayStrings = {'4 seconds','6 seconds','8 seconds','10 seconds'};
    temp = trialData(trialData.flag == 0,:);
    for d = 1:numel(delays)
        temp2 = temp(temp.delay == delays(d),:);
        D{d} = temp2.response;
    end
    
    % Plot responses split by delay
    figure;
    nhist(D,'smooth','legend',delayStrings,...
        'pdf','decimalplaces',0,'xlabel','Response (secs)','ylabel','Probability density function','color','colormap','fsize',25);
    objs = findobj;
    objs(4).XGrid = 'on';
    % clearvars('-except',initialVars{:});
end

%% CV and SD
t = 1;
for tidiness = 1
    %CV
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'response'};
    groupVar = {'delay','id'};
    STD = varfun(@nanstd, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    for d = 1:numel(delays)
        CV(:,d) = STD.nanstd_response(STD.delay == delays(d)) ./ M.nanmean_response(M.delay == delays(d));
    end
    [h,p,~,stats] = ttest2(CV(:,1),CV(:,2));
    fprintf('CV1 vs CV2, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(CV(:,1),CV(:,3));
    fprintf('CV1 vs CV3, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(CV(:,1),CV(:,4));
    fprintf('CV1 vs CV4, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(CV(:,2),CV(:,3));
    fprintf('CV2 vs CV3, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(CV(:,2),CV(:,4));
    fprintf('CV2 vs CV4, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(CV(:,3),CV(:,4));
    fprintf('CV3 vs CV4, t(%.0f) = %.3f, p = %.3f.\n\n',stats.df,stats.tstat,p);
    
    [p,table,stats] = anova1(CV,[],'off');
    fprintf('F(3,%.0f) = %.3f, p = %.3f\n',stats.df,table{2,5},p);
    
    M = mean(CV);
    SD = std(CV) ./ sqrt(length(CV));
    
    % Logarithmic regression
    lm = fitlm(delays./2,M,'linear')
    lm = fitlm(log(delays./2),M,'linear')
    
    subplot(2,1,1);
    hBar = plot(M);
    set(hBar(1),'Color',[0 0 0],...
        'LineStyle',':',...
        'Marker','o');
    set(gca,'XTick',1:4);
    set(gca,'XTickLabel',...
        {'4 seconds','6 seconds','8 seconds','10 seconds'});
    ylim([0.16 0.28]);
    ylabel('Coefficient of variation');
    hold on
    h = errorbar(M,SD);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', errorColour);
    %      CV = array2table([(1:75)',CV],'VariableNames',{'id','cv1','cv2','cv3','cv4'});
    %      writetable(CV, 'cvALL');
    clearvars('-except',initialVars{:});
    
    % SD
    t = 1;
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'response'};
    groupVar = {'id','type','delay'};
    M = varfun(@nanstd, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for a = 1:numel(delays)
        ME(:,a) = M.nanstd_response(M.type == t & M.delay == delays(a));
        means(t,a) = nanmean(ME(:,a));
        sems(t,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
    end
    [p,table,stats] = anova1(ME,[],'off');
    if t == 1
        fprintf('Juice: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    elseif t == 2
        fprintf('Money: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    elseif t == 3
        fprintf('Water: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
    end
    [h,p,~,stats] = ttest2(ME(:,1),ME(:,2));
    fprintf('None vs small, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(ME(:,1),ME(:,3));
    fprintf('None vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(ME(:,1),ME(:,4));
    fprintf('None vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(ME(:,2),ME(:,3));
    fprintf('Small vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(ME(:,2),ME(:,4));
    fprintf('Small vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
    [h,p,~,stats] = ttest2(ME(:,3),ME(:,4));
    fprintf('Medium vs Large, t(%.0f) = %.3f, p = %.3f.\n\n',stats.df,stats.tstat,p);
    clearvars ME
    
    
    subplot(2,1,2);
    hBar = plot(means);
    set(hBar(1),'Color',[0 0 0],...
        'LineStyle',':',...
        'Marker','o');
    set(gca,'XTick',1:4);
    set(gca,'XTickLabel',...
        {'4 seconds','6 seconds','8 seconds','10 seconds'});
    
    
    hold on;
    h = errorbar(means,sems);
    set(h,'linestyle','none','linewidth',1.5);
    set(h, 'Color', errorColour);
    
    ylabel('Standard deviation');
    % ylim([-.05 .25]);
    clearvars('-except',initialVars{:});
end

%% Central tendency
for tidiness = 1
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'accuracy'};
    groupVar = {'delay','id'};
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for d = 1:numel(delays)
        A(:,d) = M.nanmean_accuracy(M.delay == delays(d));
        ME(d) = nanmean(M.nanmean_accuracy(M.delay == delays(d)));
        SEM(d) = nanstd(A(:,d)) ./ sqrt(numel(A(:,d)));
        [h,p,~,~] = ttest(A(:,d));
        if h == 1
            fprintf('Accuracies at the %.0f second delay are significantly different from 0, p = %.5f.\n',delays(d),p);
        else
            fprintf('Accuracies at the %.0f second delay are not significantly different from 0, p = %.5f\n',delays(d),p);
        end
    end
    
    figure;
    hBar = bar(ME);
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    set(gca,'XTick',1:4);
    set(gca,'XTickLabel',...
        {'4 seconds','6 seconds','8 seconds','10 seconds'});
    %title('Central tendency');
    ylabel('Deviation (seconds)');
    hold on
    h = errorbar(ME,SEM);
    set(h,'linestyle','none');
    set(h, 'Color', errorColour);
    clearvars('-except',initialVars{:});
end

%% Baseline vs main task
for tidiness = 1
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'normAccuracy'};
    groupVar = {'session','id','type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 5:6
        for s = 1:3
            ME(:,s) = M.nanmean_normAccuracy(M.session == s & M.type == t);
            SD(t,s) = nanstd(ME(:,s)) ./ sqrt(numel(ME(:,s)));
            MEANS(t,s) = nanmean(ME(:,s));
        end
        if t == 1
            [h,p,~,stats] = ttest(ME(:,1),ME(:,2));
            fprintf('First baseline vs main task (juice), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest(ME(:,2),ME(:,3));
            fprintf('Second baseline vs main task (juice), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest(ME(:,1),ME(:,3));
            fprintf('First baseline vs second baseline (juice), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        elseif t == 2
            [h,p,~,stats] = ttest(ME(:,1),ME(:,2));
            fprintf('First baseline vs main task (money), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest(ME(:,2),ME(:,3));
            fprintf('Second baseline vs main task (money), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        elseif t == 3
            [h,p,~,stats] = ttest(ME(:,1),ME(:,2));
            fprintf('First baseline vs main task (water), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
            [h,p,~,stats] = ttest(ME(:,2),ME(:,3));
            fprintf('Second baseline vs main task (water), t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        end
        clearvars ME
    end
    
    % multcompare(STATS,'ctype','bonferroni')
    % rm_anova2(temp.response,temp.id,temp.delay,temp.session,{'Delay','Session'})
    
    
    figure;
    hBar = bar(MEANS');
    set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
    set(hBar(3),'FaceColor',barColour{3},'EdgeColor','none');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',...
        {'First baseline','Main Task','Second baseline'});
    ylabel('Deviation (secs)');
    hold on
    legend({'Juice','Money','Water'});
    for e = 1:size(SD,2)
        h = errorbar(e - 0.22, MEANS(1,e), SD(1,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e, MEANS(2,e), SD(2,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e + 0.22, MEANS(3,e), SD(3,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    ylim([-0.35, 0.3]);
    
    %
    % % Draw brackets
    % x1 = 1;
    % x2 = 3;
    % y = 0.12;
    % height = 0.01;
    % % Make some x-data and y-data
    % line_y = y  + [0, 0.5, 0.5, 1, 0.5, 0.5, 0] * height;
    % line_x = x1 + [0, 0.02, 0.48, 0.5, 0.52, 0.98, 1]*(x2-x1);
    % % Draw the brace and some text, too, for fun.
    % line(line_x, line_y, 'Color', 'k')
    %
    % text(1-0.04, mean(ME(:,1))-SD(1)-0.03, '*','FontSize',50);
    
    % clearvars('-except',initialVars{:});
end

%% Visualize regression results (by delay)
IV = 'reward';
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2,:);
    inputVar = {'normAccuracy'};
    groupVar = {'delay','id','type',IV};
    
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:3
        for d = 1:numel(delays)
            for r = 1:numel(amounts)
                ME(t,d,r) = nanmean(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r))));
                SD(t,d,r) = nanstd(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r))))...
                    ./ sqrt(numel(M.nanmean_normAccuracy(M.type == t & M.delay == delays(d) & strcmp(M{:,IV}, amounts(r)))));
            end
        end
    end
    for d = 1:numel(delays)
        subplot(2,2,d);
        means = [ME(1,d,1), ME(1,d,2), ME(1,d,3), ME(1,d,4);...
            ME(2,d,1), ME(2,d,2), ME(2,d,3), ME(2,d,4);...
            ME(3,d,1), ME(3,d,2), ME(3,d,3), ME(3,d,4)];
        sems = [SD(1,d,1), SD(1,d,2), SD(1,d,3), SD(1,d,4);...
            SD(2,d,1), SD(2,d,2), SD(2,d,3), SD(2,d,4);...
            SD(3,d,1), SD(3,d,2), SD(3,d,3), SD(3,d,4)];
        hBar = bar(means');
        set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
        set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
        set(hBar(3),'FaceColor',barColour{3},'EdgeColor','none');
        hold on;
        for e = 1:size(sems,2)
            h = errorbar(e - 0.22, means(1,e), sems(1,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e, means(2,e), sems(2,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e + 0.22, means(3,e), sems(3,e));
            set(h,'linestyle','none','Color', errorColour);
        end
        set(gca,'XTick',1:numel(amounts),'XTickLabel',{'No reward','Small','Medium','Large'});
        ylabel('Normalised deviation');
        title(sprintf('%.0f seconds',delays(d)));
        ylim([-.2 .4]);
        if d == 1
            legend({'Juice','Money','Water'});
        end
    end
    clearvars('-except',initialVars{:});
end

%% Visualize regression results (collapsed)
IV = 'lagDelay';
factor = delays;
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2, :);
    inputVar = {'normAccuracy'};
    groupVar = {'id',IV,'type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:3
        for a = 1:numel(factor)
            if strcmp(factor,amounts)
                ME(:,a) = M.nanmean_normAccuracy(M.type == t & strcmp(M{:,IV}, factor(a)));
            elseif factor == delays
                ME(:,a) = M.nanmean_normAccuracy(M.type == t & M{:,IV} == factor(a));
            end
            means(t,a) = nanmean(ME(:,a));
            sems(t,a) = std(ME(:,a)) ./ sqrt(numel(ME(:,a)));
        end
        [p,table,stats] = anova1(ME,[],'off');
        if t == 1
            fprintf('Juice: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
        elseif t == 2
            fprintf('Money: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
        elseif t == 3
            fprintf('Water: F(3,%.0f) = %.3f, p = %.3f.\n',stats.df,table{2,5},p);
        end
        [h,p,~,stats] = ttest2(ME(:,1),ME(:,2));
        fprintf('None vs small, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        [h,p,~,stats] = ttest2(ME(:,1),ME(:,3));
        fprintf('None vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        [h,p,~,stats] = ttest2(ME(:,1),ME(:,4));
        fprintf('None vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        [h,p,~,stats] = ttest2(ME(:,2),ME(:,3));
        fprintf('Small vs medium, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        [h,p,~,stats] = ttest2(ME(:,2),ME(:,4));
        fprintf('Small vs large, t(%.0f) = %.3f, p = %.3f.\n',stats.df,stats.tstat,p);
        [h,p,~,stats] = ttest2(ME(:,3),ME(:,4));
        fprintf('Medium vs Large, t(%.0f) = %.3f, p = %.3f.\n\n',stats.df,stats.tstat,p);
        clearvars ME
    end
    
    figure;
    hBar = bar(means');
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{3},'EdgeColor','none');
    set(hBar(3),'FaceColor',barColour{4},'EdgeColor','none');
    hold on;
    for e = 1:size(sems,2)
        h = errorbar(e - 0.22, means(1,e), sems(1,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e, means(2,e), sems(2,e));
        set(h,'linestyle','none','Color', errorColour);
        h = errorbar(e + 0.22, means(3,e), sems(3,e));
        set(h,'linestyle','none','Color', errorColour);
    end
    if strcmp(factor,amounts)
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'No reward','Small','Medium','Large'});
    elseif factor == delays
        set(gca,'XTick',1:numel(factor),'XTickLabel',{'4 secs','6 secs','8 secs','10 secs'});
    end
    ylabel('Normalised deviation');
    % ylim([-.05 .25]);
    legend({'Juice','Money','Water'});
    clearvars('-except',initialVars{:});
end

%% Identify time lag of effect
for tidiness = 1
    window = 1;
    for T = 5:6
        C = unique((trialData.id(trialData.flag == 0 & trialData.type == T)))';
        c = 1;
        for x = C
            temp = trialData(trialData.id == x & trialData.type == T & trialData.session == 2,:);
            temp = sortrows(temp,3);
            
            %acc = tsmovavg(temp.normAccuracy,'s',window,1); % 's' is static, 'e' is exponential decay
            acc = temp.normAccuracy;
            rew = tsmovavg(temp.lagReward,'s',window,1); % 's' is static, 'e' is exponential decay
            acc(isnan(acc)) = 0;
            rew(isnan(rew)) = 0;
            
            [r{T}(c,:), lags{T}(c,:)] = xcorr(rew(window:end),acc(window:end));
            
            % Create randomised correlation for comparison
            randReward = Shuffle(rew(window:end));            
            [perR{T}(c,:), ~] = xcorr(randReward,acc(window:end));

            c = c + 1;
        end
    end
    
    for T = 5:6
        for x = 1:size(r{T},2)
                comparisons = mean(lags{T});
                comparisons = comparisons(comparisons<1); % Assume causal effect
                testVec = r{T}(:,x);
                randVec = perR{T}(:,x);
                
                [h{T}(x),p{T}(x)] = ttest(testVec, 0, 'alpha', 0.05/size(comparisons,2),'tail','right');
                
                % Test random vectors
                [h1{T}(x),p1{T}(x)] = ttest(randVec, 0, 'alpha', 0.05/size(comparisons,2));

            if h{T}(x) && lags{T}(1,x) < 1 
              %  fprintf('%.3f at lag %.0f in group %.0f\n',p,lags{T}(1,x),T);
            end
            
             if h1{T}(x)
                fprintf('%.3f at lag %.0f in group %.0f\n',p1{T}(x),lags{T}(1,x),T);
             end
            
        end
       figure;
       plot(lags{T}(1,:),p{T}); hold on
       plot(lags{T}(1,:),p1{T});
    end
     clearvars('-except',initialVars{:});
end

%% Plot all participants average accuracy + average reward
for tidiness = 1
window = 3;
for T = 5:6
    temp = trialData(trialData.type == T & trialData.flag == 0 & trialData.session == 2,:);
    c = 1;
    for t = min(temp.trial):max(temp.trial)
        i = temp.trial == t;
        M(T,c) = nanmean(temp.normAccuracy(i));
        R(T,c) = nanmean(temp.reward(i));
        c = c + 1;
    end
end
averageMal = tsmovavg(M(5,:),'s',window,2); % 's' is static, 'e' is exponential decay
averageAsp = tsmovavg(M(6,:),'s',window,2); % 's' is static, 'e' is exponential decay
averageRewardMal = tsmovavg(R(5,:),'s',window,2); % 's' is static, 'e' is exponential decay
averageRewardAsp = tsmovavg(R(6,:),'s',window,2); % 's' is static, 'e' is exponential decay

figure;
subplot(2,1,1);
yyaxis left
p1 = plot(1:size(averageMal,2),averageMal);
yyaxis right
p3 = plot(1:size(averageRewardMal,2),averageRewardMal);
legend({'Accuracy','Reward'});
title('Maltodextrin');
subplot(2,1,2);
yyaxis left
p2 = plot(1:size(averageAsp,2),averageAsp);
yyaxis right
p4 = plot(1:size(averageRewardAsp,2),averageRewardAsp);
legend({'Accuracy','Reward'});
title('Aspartame');

figure;
[r, lags] = xcov(averageRewardMal(window:end),averageMal(window:end));
plot(lags,r);
[~,I] = max(abs(r));
lagDiff = lags(I); % Identify lag with maximum correlation (negative means reward comes before)
disp(lagDiff);
hold on
[r, lags] = xcov(averageRewardAsp(window:end),averageAsp(window:end));
plot(lags,r);
[~,I] = max(abs(r));
lagDiff = lags(I); % Identify lag with maximum correlation (negative means reward comes before)
disp(lagDiff);

figure;
crosscorr(averageRewardMal(window:end),averageMal(window:end),25);
figure;
crosscorr(averageRewardAsp(window:end),averageAsp(window:end),25);


temp = trialData((trialData.flag == 0 & trialData.session == 2),:);
[r,p] = corr(temp.normAccuracy, temp.lagReward21);

for x = 1:20
    laggedRewards(:,x) = lagmatrix(temp.lagReward,x);
end
fitlm([temp.reward, temp.lagReward, laggedRewards],temp.response)

clearvars('-except',initialVars{:});
end

%% Raw response descriptions (means and variances)
for tidiness = 1
    temp = trialData(trialData.flag == 0 & trialData.session == 2 & trialData.type == 1,:);
    inputVar = {'response'};
    groupVar = {'reward','delay','type'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for p = 1:25
        for a = 1:numel(amounts)
            for d = 1:numel(delays)
                aM(a,d,p) = nanmean(temp.response(temp.id == p & temp.delay == delays(d) & strcmp(amounts(a),temp.reward)));
                aSD(a,d,p) = nanstd(temp.response(temp.id == p & temp.delay == delays(d) & strcmp(amounts(a),temp.reward)));
                lM(a,d,p) = nanmean(temp.response(temp.id == p & temp.delay == delays(d) & strcmp(amounts(a),temp.lagReward)));
                lSD(a,d,p) = nanstd(temp.response(temp.id == p & temp.delay == delays(d) & strcmp(amounts(a),temp.lagReward)));
            end
        end
    end
    ant = mean(aM,3)';
    antSD = std(aM,0,3)';
    lag = mean(lM,3)';
    lagSD = std(lM,0,3)';
    antVar = mean(aSD,3)';
    antVarSD = std(aSD,0,3)';
    lagVar = mean(lSD,3)';
    lagVarSD = std(lSD,0,3)';
    
    % Mean responses
    anticipated = reshape([ant(:) antSD(:)]',2*size(ant,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/anticipated.csv',anticipated);
    consumed = reshape([lag(:) lagSD(:)]',2*size(lag,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/consumed.csv',consumed);
    % Variance responses
    anticipatedVar = reshape([antVar(:) antVarSD(:)]',2*size(antVar,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/anticipatedVar.csv',anticipatedVar);
    consumedVar = reshape([lagVar(:) lagVarSD(:)]',2*size(lagVar,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/consumedVar.csv',consumedVar);
    clearvars('-except',initialVars{:});
    
    
    
    for p = 1:25
        for a = 1:numel(amounts)
            aM(p,a) = nanmean(temp.response(temp.id == p & temp.delay == delays(1) & strcmp(amounts(a),temp.reward)));
        end
    end
    ant = mean(aM,3)';
    antSD = std(aM,0,3)';
    lag = mean(lM,3)';
    lagSD = std(lM,0,3)';
    antVar = mean(aSD,3)';
    antVarSD = std(aSD,0,3)';
    lagVar = mean(lSD,3)';
    lagVarSD = std(lSD,0,3)';
    
    % Mean responses
    anticipated = reshape([ant(:) antSD(:)]',2*size(ant,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/anticipated.csv',anticipated);
    consumed = reshape([lag(:) lagSD(:)]',2*size(lag,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/consumed.csv',consumed);
    % Variance responses
    anticipatedVar = reshape([antVar(:) antVarSD(:)]',2*size(antVar,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/anticipatedVar.csv',anticipatedVar);
    consumedVar = reshape([lagVar(:) lagVarSD(:)]',2*size(lagVar,1), [])';
    csvwrite('/Users/Bowen/Documents/MATLAB/PIPW/data/consumedVar.csv',consumedVar);
    clearvars('-except',initialVars{:});
end

%% Baseline vs main task grouped by delay
for tidiness = 1
    temp = trialData(trialData.flag == 0,:);
    inputVar = {'normAccuracy'};
    groupVar = {'session','id','type','delay'};
    M = varfun(@nanmean, temp, ...
        'InputVariables', inputVar,...
        'GroupingVariables',groupVar);
    
    for t = 1:3
        for s = 1:3
            for d = 1:4
                ME{d,s} = M.nanmean_normAccuracy(M.session == s & M.type == t & M.delay == delays(d));
                SD{t}(d,s) = nanstd(ME{d,s}) ./ sqrt(numel(ME{d,s}));
                MEANS{t}(d,s) = nanmean(ME{d,s});
            end
        end
        clearvars ME
    end
    
    for t = 1:3
        figure;
        hBar = bar(MEANS{t}');
        set(hBar(1),'FaceColor',barColour{1},'EdgeColor','none');
        set(hBar(2),'FaceColor',barColour{2},'EdgeColor','none');
        set(hBar(3),'FaceColor',barColour{3},'EdgeColor','none');
        set(hBar(4),'FaceColor',barColour{4},'EdgeColor','none');
        set(gca,'XTick',1:3);
        set(gca,'XTickLabel',...
            {'First baseline','Main Task','Second baseline'});
        ylabel('Deviation (secs)');
        hold on
        legend({'4 secs','6 secs','8 secs','10 secs'});
        for e = 1:size(SD{t},2)
            h = errorbar(e - 0.27, MEANS{t}(1,e), SD{t}(1,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e - 0.09, MEANS{t}(2,e), SD{t}(2,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e + 0.09, MEANS{t}(3,e), SD{t}(3,e));
            set(h,'linestyle','none','Color', errorColour);
            h = errorbar(e + 0.27, MEANS{t}(4,e), SD{t}(4,e));
            set(h,'linestyle','none','Color', errorColour);
        end
        ylim([-0.5, 0.5]);
    end
    
    clearvars('-except',initialVars{:});
end


%% Decision carry over (previous response)
%figure;
c = 1;
for p = participants
    temp = trialData(trialData.id == p& trialData.flag == 0,:);
    lm = fitlm([temp.delay, temp.lagResponse],temp.response,'linear');
    coefs(c,1) = table2array(lm.Coefficients(3,1));
    sds(c,1) = table2array(lm.Coefficients(3,2));
    %subplot(5,5,p);
    %plot(lm);
    %legend('off');
    c = c + 1;
end
[h p ci stats] = ttest(coefs);
figure;
bar(coefs); hold on;
errorbar(coefs,sds,'linestyle','none');

%% Perecptual carry over (previous delay)
%figure;
c = 1;
for p = participants
    temp = trialData(trialData.id == p & trialData.flag == 0,:);
    lm = fitlm([temp.delay, temp.lagDelay],temp.response,'linear');
    coefs(c,1) = table2array(lm.Coefficients(3,1));
    sds(c,1) = table2array(lm.Coefficients(3,2));
%     subplot(5,5,p);
%     plot(lm);
%     legend('off');
    c = c + 1;
end
[h p ci stats] = ttest(coefs);
figure;
bar(coefs); hold on;
errorbar(coefs,sds,'linestyle','none');

%% Both perceptual and decisional carry-over effects
for tidiness = 1
    %clearvars('-except',initialVars{:});
    temp = trialData(trialData.flag == 0 & ~isnan(trialData.lagResponse) & ~isnan(trialData.lagDelay),:);
    collintest([temp.lagResponse,temp.lagDelay]);
    
    figure;
    for p = participants
        disp(p)
        temp = trialData(trialData.id == p & trialData.flag == 0,:);
        X = [temp.delay, temp.lagResponse, temp.lagDelay];
        lm = fitlm(X,temp.response,'linear');
        coefs(p,1:4) = table2array(lm.Coefficients(1:4,1));
        sds(p,1:4) = table2array(lm.Coefficients(1:4,2));
        rsqu(p,1) = lm.Rsquared.Ordinary;
        %subplot(5,5,p);
        %plot(lm);
        %legend('off');
        collintest([ones(size(X(~any(isnan(X),2),:),1),1),X(~any(isnan(X),2),:)]);
    end
    [h p ci stats] = ttest(coefs);
    hBar = bar(coefs(:,3:4)); hold on;
    h = errorbar([1:size(sds,1)] - 0.14, coefs(:,3), sds(:,3));
    set(h,'linestyle','none','Color', errorColour);
    h2 = errorbar([1:size(sds,1)] + 0.14, coefs(:,4), sds(:,4));
    set(h2,'linestyle','none','Color', errorColour);
    set(hBar(1),'FaceColor',barColour{2},'EdgeColor','none');
    set(hBar(2),'FaceColor',barColour{6},'EdgeColor','none');
    legend({'Decisional carry-over estimates','Perceptual carry-over estimates'});
    [r,p] = corr(coefs(:,3),coefs(:,4),'type','pearson')
    figure;
    scatter(coefs(:,3),coefs(:,4));
    
    xlabel('Decisional carry-over estimate');
    ylabel('Perceptual carry-over estimate');
    
end
%clearvars('-except',initialVars{:});

%% Central tendency (delay)
figure;
for p = 1:25
    temp = trialData(trialData.id == p & trialData.type == 1 & trialData.flag == 0,:);
    lm = fitlm(temp.delay,temp.accuracy,'linear');
    coefs(p,1) = table2array(lm.Coefficients(2,1));
    subplot(5,5,p);
    plot(lm);
    legend('off');
end
figure;
bar(coefs);
[h p ci stats] = ttest(coefs)
clearvars('-except',initialVars{:});

%%

