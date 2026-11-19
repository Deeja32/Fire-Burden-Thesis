%% Reading and Saving Tables from Principal Diagnoses AIHW
table201718 = readtable("excel tables\Principal Diagnoses\Principal_diagnosis_data_cube_2017-18.xlsx", "Sheet", "5-character PDx counts Summary");
save('PD201718.mat', 'table201718');
table201819 = readtable("excel tables\Principal Diagnoses\aihw-web-216-Principal-Diagnosis-Cube-2018-19.xlsx", "Sheet", "5-character PDx Counts Summary");
save('PD201819.mat', 'table201819');
table201920 = readtable("excel tables\Principal Diagnoses\aihw-web-216-Principal-Diagnosis-Cube-2019-20.xlsx", "Sheet", "5-character PDx Counts Summary");
save('PD201920.mat', 'table201920');
table202021 = readtable("excel tables\Principal Diagnoses\Principal-Diagnosis-Cube-2020-21.xlsx", "Sheet", "5-character PDx Counts Summary");
save('PD202021.mat', 'table202021');
table202122 = readtable("excel tables\Principal Diagnoses\Principal_diagnosis_data_cube_2021-22.xlsx", "Sheet", "5-character PDx Counts Summary");
save('PD202122.mat', 'table202122');
table202223 = readtable("excel tables\Principal Diagnoses\Principal-Diagnosis-Cube-2022-23.xlsx", "Sheet", "PDx Counts Summary July-June");
save('PD202223.mat', 'table202223');
table202324 = readtable("excel tables\Principal Diagnoses\Principal-Diagnosis-Cube-2023-24.xlsx", "Sheet", "PDx Counts Summary July-June");
save('PD202324.mat', 'table202324');
%% Load and Average Life Tables (for morbidity long-term YLD)
LifeTableNSW = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables NSW", [8, Inf]);
LifeTableVIC = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Victoria", [8, Inf]);
LifeTableQLD = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Queensland", [8, Inf]);
LifeTableSA = importLifeTables("excel tables\Fire Burden Data2.xlsx","Life Tables South Australia", [8, Inf]);
LifeTableWA = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Western Australia", [8, Inf]);
LifeTableTAS = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Tasmania", [8, Inf]);
LifeTableNT = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables Northern Territory", [8, Inf]);
LifeTableACT = importLifeTables("excel tables\Fire Burden Data2.xlsx", "Life Tables ACT", [8, Inf]);

lifeTables = {LifeTableNSW, LifeTableVIC, LifeTableQLD, LifeTableSA, ...
              LifeTableWA, LifeTableTAS, LifeTableNT, LifeTableACT};

ages = LifeTableNSW.Ages;  % assumes all tables share the same age vector

lxMales_all = cellfun(@(t) t.lxMales, lifeTables, 'UniformOutput', false);
lxFemales_all = cellfun(@(t) t.lxFemales, lifeTables, 'UniformOutput', false);

lxMales_avg = mean(cat(2, lxMales_all{:}), 2);
lxFemales_avg = mean(cat(2, lxFemales_all{:}), 2);

lx_national = mean([lxMales_avg, lxFemales_avg], 2);
%% Filtering Tables based on ICD10 Code
clc;
% loading tables into the workspace
load("PD201718.mat", "table201718");
load("PD201819.mat", "table201819");
load("PD201920.mat", "table201920");
load("PD202021.mat", "table202021");
load("PD202122.mat", "table202122");
load("PD202223.mat", "table202223");
load("PD202324.mat", "table202324");

% Defining target codes to filter
targetCodes = ["T20.0","T20.1","T20.2","T20.3", ...
               "T21.0","T21.1","T21.2","T21.3", ...
               "T22.0","T22.1","T22.2","T22.3", ...
               "T23.0","T23.1","T23.2","T23.3", ...
               "T24.0","T24.1","T24.2","T24.3", ...
               "T25.0","T25.1","T25.2","T25.3", ...
               "T26","T27","T28","T29","T30","T31", ...
               "T58", "T59.8"];

%% Total Burn + Smoke Inhalation Hospitalisations
table201718filtered = filterCodeRows(table201718, targetCodes);
table201819filtered = filterCodeRows(table201819, targetCodes);
table201920filtered = filterCodeRows(table201920, targetCodes);
table202021filtered = filterCodeRows(table202021, targetCodes);
table202122filtered = filterCodeRows(table202122, targetCodes);
table202223filtered = filterCodeRows(table202223, targetCodes);
table202324filtered = filterCodeRows(table202324, targetCodes);

% Combine all years into one table (Code, Separations, Year)
allYears = [ ...
    summariseFilteredTable(table201718filtered, "2017-18"); ...
    summariseFilteredTable(table201819filtered, "2018-19"); ...
    summariseFilteredTable(table201920filtered, "2019-20"); ...
    summariseFilteredTable(table202021filtered, "2020-21"); ...
    summariseFilteredTable(table202122filtered, "2021-22"); ...
    summariseFilteredTable(table202223filtered, "2022-23"); ...
    summariseFilteredTable(table202324filtered, "2023-24") ...
];

%% Pivot to wide format: rows = codes, columns = years
wideTable = unstack(allYears, "Separations", "Year", "GroupingVariables", "Code");

codes = wideTable.Code;
yearLabels = wideTable.Properties.VariableNames(2:end);
barData = wideTable{:, 2:end};   % rows = codes, cols = years
nCodes = numel(codes);

%% Compute total LOS per code across all years (2017-18 to 2023-24)
totals = groupsummary(allYears, "Code", "sum", ["Separations","PatientDays"]);

totals.LOS = totals.sum_PatientDays ./ totals.sum_Separations;

% Rename for clarity
totals = renamevars(totals, ["sum_Separations","sum_PatientDays"], ...
                             ["TotalSeparations","TotalPatientDays"]);

%disp(totals(:, ["Code","TotalSeparations","TotalPatientDays","LOS"]));

%% Plotting - One figure per major code group (e.g. T20, T20.1, T20.2, T20.3 together)
% Group key = text before the "." (e.g. "T20.2" -> "T20").
% Codes with no "." (e.g. "T26", "T58") become their own single-code group.
majorKey = extractBefore(codes, ".");
noDot = ismissing(majorKey);       % codes without a "." return missing
majorKey(noDot) = codes(noDot);    % use the whole code as its own group key

groupKeys = unique(majorKey, 'stable');

for n = 1:numel(groupKeys)
    thisGroup = groupKeys(n);
    rowsInGroup = find(majorKey == thisGroup);

    figure;
    hold on;
    for r = rowsInGroup'
        plot(1:numel(yearLabels), barData(r, :), '-o', 'LineWidth', 1.5, ...
            'DisplayName', codes(r));
    end
    hold off;

    set(gca, 'XTick', 1:numel(yearLabels), 'XTickLabel', yearLabels);
    xtickangle(45);
    xlabel('Financial Year');
    ylabel('Separations');
    title(['Separations for ', char(thisGroup), ' codes, 2017–18 to 2023–24']);
    legend('Location', 'best');
    grid on;
end
%% Calculating YLD
% Formulating Disability Weight Table
severityGroup = ["Smoke Inhalation"; "Minor Burns"; "Moderate Burns"; "Severe Burns ST"; "Severe Burns LT"];
disabilityWeight = [0.376; 0.141; 0.141; 0.314; 0.135];
weightLowerBound = [0.24; 0.094; 0.094; 0.211; 0.092];
weightUpperBound = [0.524; 0.196; 0.196; 0.441; 0.19];

disabilityWeightTable = table(severityGroup, disabilityWeight, weightLowerBound, weightUpperBound);

%% Burns - INTEGRIS Method (TBSA Based Codes)
recoveryPeriods = ["0-1 months"; "1-6 months"; "6-12 months"; "12-24 months"; ">24 months"];
TBSAPercentage = ["<5% TBSA burned", "5-20% TBSA burned", ">20% TBSA burned"];
dwCase = "central";
integrisCentral = [0.173, 0.098, 0.082, 0.102, 0.046;
                   0.264, 0.139, 0.118, 0.108, 0.099;
                   0.497, 0.262, 0.231, 0.163, 0.122];
integrisLower   = [0.152, 0.090, 0.067, 0.080, 0.026;
                   0.238, 0.128, 0.104, 0.092, 0.077;
                   0.438, 0.235, 0.198, 0.134, 0.092];
integrisUpper   = [0.195, 0.106, 0.097, 0.123, 0.067;
                   0.289, 0.150, 0.133, 0.124, 0.122;
                   0.557, 0.290, 0.263, 0.191, 0.152];
if dwCase == "lower"
    integrisDWData = integrisLower;
elseif dwCase == "upper"
    integrisDWData = integrisUpper;
else
    integrisDWData = integrisCentral;
end

integrisDataTable = array2table(integrisDWData, "RowNames", cellstr(TBSAPercentage), "VariableNames", cellstr(recoveryPeriods));

% Calculating LOS
T27table = allYears(allYears.Code == "T27", :);
T27table.LOS_days = T27table.PatientDays ./ T27table.Separations;
T27table.LOS_years = T27table.LOS_days / 365.25;

% Smoke Inhalation Disability Weight
smokeWeight = disabilityWeightTable.disabilityWeight(disabilityWeightTable.severityGroup == "Smoke Inhalation");

% Mapping TBSA and Burn Severity 

regionMap = containers.Map( ...
    ["T20","T21","T22","T23","T24","T25"], ...
    ["T20","T21","T22","T22","T24","T24"]);

bodyRegionCode = ["T20"; "T21"; "T22"; "T24"];
ruleOfNinesPct = [9; 36; 9; 18];
regionTBSATable = table(bodyRegionCode, ruleOfNinesPct);

% Bucket each combined region into a TBSA group
regionTBSATable.TBSAGroup = strings(height(regionTBSATable),1);
regionTBSATable.TBSAGroup(regionTBSATable.ruleOfNinesPct < 5) = "<5% TBSA burned";
regionTBSATable.TBSAGroup(regionTBSATable.ruleOfNinesPct >= 5 & regionTBSATable.ruleOfNinesPct <= 20) = "5-20% TBSA burned";
regionTBSATable.TBSAGroup(regionTBSATable.ruleOfNinesPct > 20) = ">20% TBSA burned";

% Extract category prefix (e.g. "T20.1" -> "T20") and remap via regionMap
categoryCode = extractBefore(allYears.Code, ".");
noDot = ismissing(categoryCode);
categoryCode(noDot) = allYears.Code(noDot);

combinedRegion = strings(height(allYears),1);
for i = 1:height(allYears)
    if isKey(regionMap, categoryCode(i))
        combinedRegion(i) = regionMap(categoryCode(i));
    end
end

allYears.CombinedRegion = combinedRegion;

% Drop rows that aren't burn-site codes (e.g. T26-T31, T58, T59.8 aren't in regionMap)
burnsOnly = allYears(combinedRegion ~= "", :);

% Join TBSA group onto burns data
burnsOnly = join(burnsOnly, regionTBSATable, ...
    "LeftKeys", "CombinedRegion", ...
    "RightKeys", "bodyRegionCode");

tbsaByYear = groupsummary(burnsOnly, ["TBSAGroup","Year"], "sum", "Separations");
%% Proportion of burns in residential fires vs thermal causes
burnsYr = groupsummary(burnsOnly, "Year", "sum", "Separations");
burnsYr = renamevars(burnsYr(:, ["Year","sum_Separations"]), "sum_Separations", "BurnsSeps");
smokeYr = groupsummary(T27table, "Year", "sum", "Separations");
smokeYr = renamevars(smokeYr(:, ["Year","sum_Separations"]), "sum_Separations", "SmokeSeps");

Year = ["2017-18"; "2018-19"; "2019-20"; "2020-21"; "2021-22"; "2022-23"; "2023-24"];
H18  = [1754; 1654; 1785; 1763; 1676; 1513; 1537];
h18Table = table(Year, H18);
pTable = join(join(burnsYr, smokeYr, "Keys", "Year"), h18Table, "Keys", "Year");
pTable.p = (pTable.H18 * 5/9) ./ (pTable.BurnsSeps + pTable.SmokeSeps);
disp(pTable)

pYear = pTable(:, ["Year","p"]);
tbsaByYear = join(tbsaByYear, pYear, "Keys", "Year");
T27table   = join(T27table,   pYear, "Keys", "Year");
burnsOnly  = join(burnsOnly,  pYear, "Keys", "Year");

% Recalculate T27 YLD
T27table.YLD = smokeWeight .* T27table.LOS_years .* T27table.Separations .* T27table.p;

%%
% Short-term window durations (years) for the 4 recovery periods
windowDurations = [1/12, 5/12, 6/12, 12/12];

% Proportion of patients with lifelong disability, by TBSA group
lifelongProportion = containers.Map( ...
    ["<5% TBSA burned","5-20% TBSA burned",">20% TBSA burned"], ...
    [0.20, 0.25, 0.39]);

% Middle age of each 5-year group: 0-4 -> 2, 5-9 -> 7, ..., 85+ -> 87
ageMid = [2 7 12 17 22 27 32 37 42 47 52 57 62 67 72 77 82 87];

% Burns separations in each age group (AIHW 2023-24)
burnCounts = [179 99 88 97 112 102 108 98 100 86 99 100 79 82 80 71 62 69];

% Share of burns patients in each age group (these add up to 1)
share = burnCounts / sum(burnCounts);

r = 0.03;  % discount rate, matching VLL mortality code
longTermPV_avg = 0;

for i = 1:length(ageMid)
    a = ageMid(i);        % age at injury
    pv = 0;               % running total for this age

    % add up each future year, starting 2 years after the injury
    for t = 2:(100 - a)
        survive  = lx_national(ages == a + t) / lx_national(ages == a);   % chance of still being alive
        discount = (1 + r)^(-t);                                          % worth less in the future
        pv = pv + survive * discount;
    end

    % add this age's result, weighted by how common the age is
    longTermPV_avg = longTermPV_avg + share(i) * pv;
end

% Midpoint (in years) of each short-term window, for discounting
windowMidpoints = [0.5/12, 3.5/12, 9/12, 18/12];   % 0-1, 1-6, 6-12, 12-24 months

% Discount factors for each short-term window
shortTermDiscountFactors = (1 + r) .^ (-windowMidpoints);

% Calculate YLD for each TBSA group/year row
tbsaByYear.YLD = zeros(height(tbsaByYear), 1);

tbsaByYear.YLD_ST = zeros(height(tbsaByYear), 1);
tbsaByYear.YLD_LT = zeros(height(tbsaByYear), 1);

for k = 1:height(tbsaByYear)
    group = tbsaByYear.TBSAGroup(k);
    cases = tbsaByYear.sum_Separations(k) * tbsaByYear.p(k);

    % Short-term: use column POSITION (1:4), since integrisDataTable's
    % actual column names got auto-converted from "0-1 months" etc.
    weights_shortTerm = integrisDataTable{group, 1:4};
    yld_shortTerm = sum(cases .* weights_shortTerm .* windowDurations .* shortTermDiscountFactors);

    % Long-term: column 5 is ">24 months"
    weight_longTerm = integrisDataTable{group, 5};
    proportion = lifelongProportion(group);
    yld_longTerm = cases * proportion * weight_longTerm * longTermPV_avg;

    tbsaByYear.YLD_ST(k) = yld_shortTerm;
    tbsaByYear.YLD_LT(k) = yld_longTerm;

    tbsaByYear.YLD(k) = yld_shortTerm + yld_longTerm;
end

disp(tbsaByYear);
%%
% Add LOS to your burns data (same pattern as T27table)
burnsOnly.LOS_days = burnsOnly.PatientDays ./ burnsOnly.Separations;
burnsOnly.LOS_years = burnsOnly.LOS_days / 365.25;

% Comorbidity parameters
p_comorbid = 0.11;          % primary estimate
% p_comorbid_lower = 0.048; % sensitivity bound, for later if needed

burnsOnly.YLD_hiddenComorbid = zeros(height(burnsOnly), 1);

for k = 1:height(burnsOnly)
    group = burnsOnly.TBSAGroup(k);
    cases = burnsOnly.Separations(k) * burnsOnly.p(k);
    LOS_years = burnsOnly.LOS_years(k);

    D_burns = integrisDataTable{group, 1};   % "0-1 months" column, acute phase
    incrementalWeight = smokeWeight * (1 - D_burns);

    l_hidden = cases * p_comorbid;
    burnsOnly.YLD_hiddenComorbid(k) = l_hidden * incrementalWeight * LOS_years;
end

%%
comorbidByYear = groupsummary(burnsOnly, ["TBSAGroup","Year"], "sum", "YLD_hiddenComorbid");

tbsaByYear = join(tbsaByYear, comorbidByYear, "Keys", ["TBSAGroup","Year"]);
tbsaByYear.YLD_total = tbsaByYear.YLD + tbsaByYear.sum_YLD_hiddenComorbid;

% Step 1: Sum burns YLD (already includes comorbid correction) across TBSA groups, per year
burnsYearTotal = groupsummary(tbsaByYear, "Year", "sum", "YLD_total");
burnsYearTotal = renamevars(burnsYearTotal, "sum_YLD_total", "BurnsYLD");

% Step 2: Smoke inhalation YLD per year (already computed earlier)
smokeByYear = groupsummary(T27table, "Year", "sum", "YLD");
smokeByYear = renamevars(smokeByYear, "sum_YLD", "SmokeYLD");

% Step 3: Combine into one total morbidity table
totalMorbidityYLD = join(burnsYearTotal, smokeByYear, "Keys", "Year");
totalMorbidityYLD.TotalYLD = totalMorbidityYLD.BurnsYLD + totalMorbidityYLD.SmokeYLD;
VSLY = 253000;
load('annualProduction.mat');
totalMorbidityYLD.MorbidityHCA = totalMorbidityYLD.TotalYLD * annualProductionAvg;
totalMorbidityYLD.MorbidityWTP = totalMorbidityYLD.TotalYLD * VSLY / 1e6;
totalMorbidityYLD = removevars(totalMorbidityYLD, ["GroupCount_burnsYearTotal","GroupCount_smokeByYear"]);

totalMorbidityYLD.MorbidityHCA = totalMorbidityYLD.MorbidityHCA / 1e6;

comorbidYear = groupsummary(burnsOnly, "Year", "sum", "YLD_hiddenComorbid");
comorbidYear = comorbidYear(:, ["Year","sum_YLD_hiddenComorbid"]);   
totalMorbidityYLD = join(totalMorbidityYLD, comorbidYear, "Keys", "Year");
totalMorbidityYLD.ComorbidHCA = totalMorbidityYLD.sum_YLD_hiddenComorbid * annualProductionAvg / 1e6;   % $m

if dwCase == "central"
    save('morbidity.mat', 'totalMorbidityYLD')
else
    save('morbidity_' + dwCase + '.mat', 'totalMorbidityYLD')
end

stByYear = groupsummary(tbsaByYear, "Year", "sum", ["YLD_ST","YLD_LT"]);



yldTable = table(stByYear.Year, stByYear.sum_YLD_ST, stByYear.sum_YLD_LT, ...
    'VariableNames', ["Year","BurnsShortTerm","BurnsLongTerm"]);
yldTable = join(yldTable, smokeByYear(:, ["Year","SmokeYLD"]), "Keys", "Year");
yldTable = join(yldTable, comorbidYear, "Keys", "Year");
yldTable = renamevars(yldTable, "sum_YLD_hiddenComorbid", "Comorbid");
yldTable.Total = yldTable.BurnsShortTerm + yldTable.BurnsLongTerm + yldTable.SmokeYLD + yldTable.Comorbid;

yldTable = join(yldTable, pTable(:, ["Year", "BurnsSeps", "SmokeSeps", "p"]), "Keys", "Year");
yldTable.Nstar_burns = yldTable.BurnsSeps .* yldTable.p;
yldTable.Nstar_T27 = yldTable.SmokeSeps .* yldTable.p;
yldTable = movevars(yldTable, ["BurnsSeps", "SmokeSeps", "p", "Nstar_burns", "Nstar_T27"], "After", "Year");

disp(yldTable)
save('yldTable.mat', 'yldTable')

yldTableRounded = yldTable;
numVars = varfun(@isnumeric, yldTable, "OutputFormat", "uniform");   % find numeric columns
yldTableRounded{:, numVars} = round(yldTable{:, numVars}, 2);         % round to 2 d.p.

disp(yldTableRounded)
writetable(yldTableRounded, 'thesis_tables.xlsx', 'Sheet', 'YLD by Component');
%% Calculating Hospitalisation Costs
costYears = ["2023-24"; "2022-23"; "2021-22"; "2020-21"; "2019-20"; "2018-19"; "2017-18"];
costUpper = [28691.08; 28246.88; 24966.95; 27693.72; 24788.70; 26950.01; 25977.17];
costMiddle = [17289.02; 17230.23; 18093.41; 16368.10; 17797.85; 16521.34; 15948.44];
costLower = [12791.46; 12884.01; 13861.02; 11871.57; 12791.86; 12445.92; 11906.20];
costE75 = [4243.27; 4642.81; 4820.23; 4402.75; 4653.17; 4189.35; 4097.44];
costTable = table(costYears, costUpper, costMiddle, costLower, costE75, ...
    'VariableNames', ["Year","Upper","Middle","Lower","E75"]);

burnsPerYear = groupsummary(burnsOnly, "Year", "sum", "Separations");
burnsPerYear = renamevars(burnsPerYear, "sum_Separations", "BurnsSeps");
burnsPerYear = burnsPerYear(:, ["Year","BurnsSeps"]);

smokePerYear = T27table(:, ["Year","Separations"]);
smokePerYear = renamevars(smokePerYear, "Separations", "SmokeSeps");

hospital = innerjoin(costTable, burnsPerYear, "Keys", "Year");
hospital = innerjoin(hospital, smokePerYear, "Keys", "Year");
hospital = innerjoin(hospital, pYear, "Keys", "Year");

hospital.costUpper  = (hospital.p .* (hospital.BurnsSeps .* hospital.Upper  + hospital.SmokeSeps .* hospital.E75)) / 1e6;
hospital.costMiddle = (hospital.p .* (hospital.BurnsSeps .* hospital.Middle + hospital.SmokeSeps .* hospital.E75)) / 1e6;
hospital.costLower  = (hospital.p .* (hospital.BurnsSeps .* hospital.Lower  + hospital.SmokeSeps .* hospital.E75)) / 1e6;

fireServiceYears = ["2017-18"; "2018-19"; "2019-20"; "2020-21"; "2021-22"; "2022-23"; "2023-24"; "2024-25"];
fireServiceTotal = [120.2549497; 130.0212374; 189.9396747; 131.2920572; 114.6358879; 79.84710327; 81.32474077; 116.9613791];
fireService = table(fireServiceYears, fireServiceTotal, 'VariableNames', ["Year","FireServiceCost"]);

direct = innerjoin(hospital, fireService, "Keys", "Year");
direct.totalUpper = direct.costUpper + direct.FireServiceCost;
direct.totalMiddle = direct.costMiddle + direct.FireServiceCost;
direct.totalLower = direct.costLower + direct.FireServiceCost;
save('direct.mat', 'direct')
%%
morb = totalMorbidityYLD(:, ["Year","MorbidityHCA", "MorbidityWTP"]);
morb.MorbidityHCA_m = morb.MorbidityHCA / 1e6;
morb.MorbidityWTP_m = morb.MorbidityWTP / 1e6;
morb = morb(:, ["Year","MorbidityHCA_m", "MorbidityWTP_m"]);
%compare = innerjoin(direct, morb, "Keys", "Year");

%% Functions
% This function filters the necessary rows needed, according to the
% targetCodes provided.

function filteredTable = filterCodeRows(fullTable, targetCodes)
    labels = string(fullTable{:,1});
    keepMask = false(height(fullTable), 1);
    for i = 1:numel(targetCodes)
        prefix = targetCodes(i) + " ";
        isRealRow = startsWith(labels, prefix);
        isDuplicateRow = contains(labels, "no 5-character resolution") | ...
            contains(labels, "no 4-character resolution");
        keepMask = keepMask | (isRealRow & ~isDuplicateRow);
    end
    filteredTable = fullTable(keepMask, :);
end

% This function summarises the filtered table by removing the description
% and removing number of patient days
function summaryTable = summariseFilteredTable(filteredTable, yearLabel)
% Pulls just Code and Separations out of a filtered table, tags with year
    labels = string(filteredTable{:,1});
    Code = extractBefore(labels, " ");        % just "T20.0" not the full description
    Separations = filteredTable{:,2};          % adjust column index 
    PatientDays = filteredTable{:, 3};

    Year = repmat(string(yearLabel), height(filteredTable), 1);
    summaryTable = table(Code, Separations, PatientDays, Year);
end