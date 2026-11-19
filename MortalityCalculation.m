%% Section 1 - Importing Data
% This section reads in the life table data from the Excel Sheet and
% imports it as a table in MATLAB. 
% Input Arguments:
%   filename
%   Sheet Name
%   Data Lines

LifeTableNSW = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables NSW", [8, Inf]);
LifeTableVIC = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Victoria", [8, Inf]);
LifeTableQLD = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Queensland", [8, Inf]);
LifeTableSA = importLifeTables("excel tables\Fire Burden Data2.xlsx","Life Tables South Australia", [8, Inf]);
LifeTableWA = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Western Australia", [8, Inf]);
LifeTableTAS = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Tasmania", [8, Inf]);
LifeTableNT = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Northern Territory", [8, Inf]);
LifeTableACT = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables ACT", [8, Inf]);

%% Section 1.1 - Importing Variables
% This section contains importing other variables required to calculate
% present value market production such as Labour Force Participation Rates,
% Weekly Earnings and Unpaid Work

% Labour Force Participation Rate by Age
LFbATable = readtable("excel tables\Fire Burden Data2.xlsx", "Sheet", "Labour Force by Age");

% Labour Force Participation Rate by State
LFbSTable = readtable("excel tables\Fire Burden Data2.xlsx", "Sheet", "Labour Force by State");

% Weekly Earnings
WeeklyEarningsTable = readtable("excel tables\Fire Burden Data2.xlsx", "Sheet", "Average Earnings");

% Unpaid Work
UnpaidWorkTable = readtable("excel tables\Fire Burden Data2.xlsx", "Sheet", "UnpaidWork");

%% Calculation for NSW
% Data from Preventable Residential Fire Fatalities (old data)
% crcCounts is the number of deaths in each 5-year age group
% crcTotal is the total number of deaths 
% crcWeights is the weighting of each age group

crcCounts = [70; 26; 20; 21; 28; 31; 37; 38; 61; 63; 62; 60; 53; 67; 59; 67;
    56; 54; 21; 6];
crcTotal = sum(crcCounts);
crcWeights = crcCounts / crcTotal;
ageGroups = { 0:4; 5:9; 10:14; 15:19; 20:24; 25:29; 30:34; 35:39; 40:44; 45:49;
    50:54; 55:59; 60:64; 65:69; 70:74; 75:79; 80:84; 85:89; 90:94; 95:100};

stateNames = {'NSW','VIC','QLD','SA','WA','TAS','NT','ACT'};
lifeTables = {LifeTableNSW, LifeTableVIC, LifeTableQLD, LifeTableSA, ...
              LifeTableWA, LifeTableTAS, LifeTableNT, LifeTableACT};

VLL_male_all = zeros(length(stateNames),1);
VLL_female_all = zeros(length(stateNames),1);

prodMale   = zeros(length(stateNames), 1);
prodFemale = zeros(length(stateNames), 1);

% using cell to contain the data necessary for plotting
curves_male = cell(length(stateNames),1);
curves_female = cell(length(stateNames),1);

maleCounts   = [39;19;5;13;21;22;29;27;35;49;45;45;37;45;29;40;30;36;11;2];
femaleCounts = [31;7;15;8;7;9;8;11;26;14;17;15;16;22;30;27;26;18;10;4];

weightsMale = maleCounts/sum(maleCounts);
weightsFemale = femaleCounts/sum(femaleCounts);

% looping through each state/territory and computing the state VLL, saving
% the outputs:
%   - VLL_male
%   - VLL_female
%   - plotting data (curves)

for i = 1:length(stateNames)
    [VLL_male_all(i), curves_male{i}, ages, annualProdMale] = computeStateVLL(lifeTables{i}, ...
        WeeklyEarningsTable, UnpaidWorkTable, LFbATable, LFbSTable, stateNames{i}, ...
        weightsMale, ageGroups, "male");
    [VLL_female_all(i), curves_female{i}, ~, annualProdFemale] = computeStateVLL(lifeTables{i}, ...
        WeeklyEarningsTable, UnpaidWorkTable, LFbATable, LFbSTable, stateNames{i}, ...
        weightsFemale, ageGroups, "female");
    prodMale(i)   = mean(annualProdMale(ages >= 15 & ages <= 64));
    prodFemale(i) = mean(annualProdFemale(ages >= 15 & ages <= 64));
end
annualProductionAvg = mean([prodMale; prodFemale]);
maleShare = sum(maleCounts)/sum(crcCounts);
femaleShare = sum(femaleCounts)/sum(crcCounts);
ELPD = maleShare .* VLL_male_all + femaleShare .* VLL_female_all;

stateShare = [0.28345627; 0.27081138; 0.214963119; 0.057955743; 0.090621707; 0.04004215; 0.024236038; 0.017913593];
L = sum(stateShare .* ELPD);

% Creating a table for results
ResultsTable = table(stateNames', VLL_male_all, VLL_female_all, ELPD,  ...
    'VariableNames', {'State','VLL_Male','VLL_Female', 'Expected Loss per Death'});
disp(ResultsTable)
writetable(ResultsTable, 'thesis_tables.xlsx', 'Sheet', 'VLL and Expected Loss per Death');

% Setting plotting figures to be in one window
set(0, 'DefaultFigureWindowStyle', 'docked')

% Looping through each state/territory and plotting VLL data
for i = 1:length(stateNames)
    figure;
    plot(ages, curves_male{i}, 'b-', 'LineWidth', 1.5); hold on;
    plot(ages, curves_female{i}, 'r-', 'LineWidth', 1.5);
    xlabel('Age'); ylabel('VLL ($AUD)');
    title(['VLL by Age — ' stateNames{i}]);
    legend('Male','Female','Location','best');
    grid on;
end

%% All-States Comparison Plots (Male vs Female separately)

% Use a colormap so each state gets a distinct, consistent colour
colours = lines(length(stateNames));

% --- Male: all states on one graph ---
figure;
hold on;
for i = 1:length(stateNames)
    plot(ages, curves_male{i}, 'Color', colours(i,:), 'LineWidth', 1.5);
end
xlabel('Age'); ylabel('VLL ($AUD)');
title('VLL by Age — Male (All States/Territories)');
legend(stateNames, 'Location', 'best');
grid on;
hold off;

% --- Female: all states on one graph ---
figure;
hold on;
for i = 1:length(stateNames)
    plot(ages, curves_female{i}, 'Color', colours(i,:), 'LineWidth', 1.5);
end
xlabel('Age'); ylabel('VLL ($AUD)');
title('VLL by Age — Female (All States/Territories)');
legend(stateNames, 'Location', 'best');
grid on;
hold off;
%%
VSL_case = [5870000, 7e6*(100/78.5)];
VSL = 5.87e6;
VLL = L;
Years = ["2017-18"; "2018-19"; "2019-20"; "2020-21"; "2021-22"; "2022-23"; "2023-24"];
residentialDeaths = [48.88888889; 50; 45.27777778; 65.27777778; 66.38888889; 73.33333333; 71.66666667];
MortalityVLL = residentialDeaths .* VLL / 1e6;
MortalityVSL = residentialDeaths .* VSL / 1e6;
MortalityVSL_cases = residentialDeaths .* VSL_case / 1e6;
MortalityResultsTable = table(Years, residentialDeaths, MortalityVSL, MortalityVLL, ...
    'VariableNames', {'Year','Residential Deaths','MortalityVSL ($m)', 'MortalityVLL ($m)'});
save('mortality.mat', 'MortalityResultsTable');
save('annualProduction.mat', 'annualProductionAvg');
%%

% This function computes the VLL by State
function [VLL_weighted, VLL, ages, annualProduction] = computeStateVLL(LifeTable, WeeklyEarnings, UnpaidWork, LFbATable, LFbSTable, stateName, crcWeights, ageGroups, sex)
    ages = LifeTable.Ages;                % vector containing ages 1 - 100
    stateRow = strcmp(LFbSTable.State, stateName);
        
    if strcmp(sex, 'male')                % if-loop, condition is 'sex'
        lx = LifeTable.lxMales;           % Extracting data for males
        stateWeight = LFbSTable.WeightingMale(stateRow);
        
        E = (LFbATable.EmploymentRatioMale / 100) * stateWeight;
        w = WeeklyEarnings.Males * 52;
        H = UnpaidWork.Males * 365;
    elseif strcmp(sex, 'female')          % Extracting data for females
        lx = LifeTable.lxFemales;
        stateWeight = LFbSTable.WeightingFemale(stateRow);
        
        E = (LFbATable.EmploymentRatioFemale / 100) * stateWeight;
        w = WeeklyEarnings.Females * 52;
        H = UnpaidWork.Females * 365;
    end
    w_rep = UnpaidWork.HourlyRate(1);    % ensures that replacement wage is a scalar value

    % Pad vectors
    % Creating vectors which contain values for ages from 1 - 100
    % as some data only contains value from 15 onwards
    
    E_full = zeros(size(ages));
    w_full = w * ones(size(ages));
    H_full = zeros(size(ages));

    % Importing data containing values for ages 15 and onwards into the
    % respective vectors
    
    E_full(ages >= 15) = E;
    H_full(ages >= 15) = H;
    annualProduction = w_full .* E_full + H_full .* w_rep;
    
    r = 0.03;   % discount rate
    R = 63.8;   % average retirement age (ABS: 2024/25)
    T = 100;    % maximum age

    VLL = zeros(size(ages));    % create an empty vector for the values of VLL
    % loop through ages 1 - 100
    for i = 1:length(ages)
        a = ages(i);
        % computing the VLL for each age 
        VLL(i) = computeVLL(a, ages, lx, w_full, E_full, H_full, w_rep, r, R, T);
    end

    % Build full CRC weights
    fullWeights = zeros(size(ages));    % zero vector
    % taking age-group weights from CRC (5 year age-groups) and spreading
    % them across all ages 
    for i = 1:length(ageGroups)
        fullWeights(ageGroups{i} + 1) = crcWeights(i)/numel(ageGroups{i});
    end

    % Weighted average VLL
    VLL_weighted = sum(VLL .* fullWeights);
end

% This function calculates the present value of future market production
% the individual would have contributed, discounted back to the age of
% death.
% Input Arguments
%   - a         : age of the individual at death
%   - ages      : a vector of all the ages examined (1 - 100, inclusive)
%   - lx        : number of people (out of 100,000) to survive at a
%                 specific age
%   - wage      : full time annual earnings at age 'a'
%   - eR        : employment ratio at age 'a'
%   - d         : discount Rate
%   - retireAge : age of retirement (average for 2024-45 was 63.8 years)

function PV_M = PVMarket(a, ages, lx, wage, eR, dR, retireAge)
    idx = ages >= a & ages <= retireAge;
        % idx is a vector of indexes of the ages between current age (a) and retirement age
    futureAges = ages(idx);
        % futureAges is a vector of ages between 'a' and retirement age
    
    % Survival Rate
    la = lx(ages == a);     % number of survivors at age 'a'
    lt = lx(idx);           % vector of survivors at all future ages greater than 'a'
    S = lt ./ la;           % vector of the survival probabilities
   
    % Discount Factors
    yearsFuture = futureAges - a;   % a vector containing the numner of years 
                                    % between age 'a' and each future age
    DF = (1 + dR).^(-yearsFuture);  % discounts the value of future production 
                                    % into a present value
    % Market Production
    % LoP is the expected market production at each future age
    LoP = wage(idx) .* eR(idx);

    % result is calculated by summing the multiplication of expected market
    % production, survival rate probability and discount rate.
    PV_M = sum(LoP .* S .* DF);
    
end

% This function calculates the present value of future non-market production
% the individual would have contributed, discounted back to the age of
% death.
% Input Arguments
%   - a         : age of the individual at death
%   - ages      : a vector of all the ages examined (1 - 100, inclusive)
%   - lx        : number of people (out of 100,000) to survive at a
%                 specific age
%   - H         : number of unpaid hours
%   - w_rep     : replacement wage
%   - r         : discount Rate
%   - T         : maximum age (100)

function PV_NM = PVNonMarket(a, ages, lx, H, w_rep, r, T)
    % 1. Survival
    idx = ages >= a & ages <= T;
    futureAges = ages(idx);

    la = lx(ages == a);
    lt = lx(idx);
    S = lt ./ la;

    % 2. Discount factors
    yearsAhead = futureAges - a;
    DF = (1 + r).^(-yearsAhead);

    % 3. Non-market production LoHCP_t
    LoHCP = H(idx) .* w_rep;

    % 4. Present value
    PV_NM = sum(LoHCP .* S .* DF);
end

% This function sums the present value of market and non-market productions
function VLL = computeVLL(a, ages, lx, w, E, H, w_rep, r, R, T)
    PV_M  = PVMarket(a, ages, lx, w, E, r, R);
    PV_NM = PVNonMarket(a, ages, lx, H, w_rep, r, T);
    VLL = PV_M + PV_NM;
end