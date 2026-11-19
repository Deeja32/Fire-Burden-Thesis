load("direct.mat");
load("morbidity.mat");
load("mortality.mat");
integrisL = load("morbidity_lower.mat");
integrisU = load("morbidity_upper.mat");

direct = renamevars(direct, ["totalLower", "totalMiddle", "totalUpper"], ["DirectLower ($m)", "DirectCentral ($m)", "DirectUpper ($m)"]);
directCostsTableFiltered = direct(:, {'Year', 'DirectLower ($m)', 'DirectCentral ($m)', 'DirectUpper ($m)'});
mortalityCostsTableFiltered = MortalityResultsTable(:, {'Year', 'MortalityVSL ($m)', 'MortalityVLL ($m)'});
totalMorbidityYLD = renamevars(totalMorbidityYLD, ["MorbidityHCA","MorbidityWTP"], ["MorbidityHCA ($m)","MorbidityWTP ($m)"]);
morbidityCostsTableFiltered = totalMorbidityYLD(:, {'Year','MorbidityHCA ($m)','MorbidityWTP ($m)'});

morbidity_mortality = innerjoin(mortalityCostsTableFiltered, morbidityCostsTableFiltered, 'Keys', 'Year');
costsTable = innerjoin(directCostsTableFiltered, morbidity_mortality, 'Keys', 'Year');

costsTable.TotalHCA = costsTable.("MortalityVLL ($m)") + costsTable.("MorbidityHCA ($m)") + costsTable.("DirectCentral ($m)");
costsTable.TotalWTP = costsTable.("MortalityVSL ($m)") + costsTable.("MorbidityWTP ($m)") + costsTable.("DirectCentral ($m)");
costsTable.morbidityShareHCA = costsTable.("MorbidityHCA ($m)") ./ costsTable.TotalHCA * 100;
costsTable.mortalityShareHCA = costsTable.("MortalityVLL ($m)") ./ costsTable.TotalHCA * 100;
costsTable.directShareHCA    = costsTable.("DirectCentral ($m)") ./ costsTable.TotalHCA * 100;

display(costsTable)
%%
wtpBase = sum(costsTable.TotalWTP) / 7;
VSL_base = 5.87e6;
VSL_high = 7e6 * 100/78.5;
mortVSL = sum(costsTable.("MortalityVSL ($m)"));
wtpHigh = (sum(costsTable.TotalWTP) + mortVSL * (VSL_high/VSL_base - 1)) / 7;
pctVSL = 100 * (wtpHigh - wtpBase) / wtpBase;
%%
morbLow = sum(integrisL.totalMorbidityYLD.MorbidityHCA);
morbHigh = sum(integrisU.totalMorbidityYLD.MorbidityHCA);
morbBase = sum(costsTable.("MorbidityHCA ($m)"));
hospBase = sum(direct.costMiddle);
crcAffected = sum(costsTable.("MortalityVLL ($m)")) + morbBase + hospBase;

baseShare = 5/9;
scenario = ["Baseline"; 
            "DirectLow"; 
            "DirectHigh"; 
            "WTP basis (VSL + VLY)"; 
            "Disability Weights (95% CI, lower)";
            "Disability Weights (95% CI, upper)";
            "CRC Residential Share = 0.53";
            "CRC Residential Share = 0.62";
            "Comorbidity rate = 4.8%"
            ];
total = [sum(costsTable.TotalHCA);
         sum(costsTable.TotalHCA) - sum(costsTable.("DirectCentral ($m)")) + sum(costsTable.("DirectLower ($m)"));
         sum(costsTable.TotalHCA) - sum(costsTable.("DirectCentral ($m)")) + sum(costsTable.("DirectUpper ($m)"));
         sum(costsTable.TotalWTP);
         sum(costsTable.TotalHCA) - morbBase + morbLow;
         sum(costsTable.TotalHCA) - morbBase + morbHigh;
         sum(costsTable.TotalHCA) + (0.53/baseShare - 1) * crcAffected;
         sum(costsTable.TotalHCA) + (0.62/baseShare - 1) * crcAffected; 
         sum(costsTable.TotalHCA) - sum(totalMorbidityYLD.ComorbidHCA) * (1-0.048/0.11)
         ];
total = total / 7; % annual average, $m
change = total - total(1);
pct = 100 * change ./ total(1);

sensitivityTable = table(scenario, total, change, pct, 'VariableNames', ["Scenario", "AnnualAvg", "Change", "Change%"]);
writetable(sensitivityTable, 'thesis_tables.xlsx', 'Sheet', 'Sensitivity');
%%
cMortality = [0 0.447 0.741];      % blue
cMorbidity = [0.850 0.325 0.098];  % orange
cDirect    = [0.929 0.694 0.125];  % yellow
cMortalityVLL = [0.30 0.75 0.93];  % lighter blue for the VLL variant

names = ["Hospital Cost"; "Disability Weights (95% CI)"; "CRC residential share"];
lows  = [pct(2); pct(5); pct(7)];
highs = [pct(3); pct(6); pct(8)];

[~, idx] = sort(highs - lows);
names = names(idx);
lows = lows(idx); 
highs = highs(idx);
figure(100)
h = barh(categorical(names, names), [lows highs], 'stacked');
h(1).FaceColor = [0.55 0.55 0.55];   % gray
h(2).FaceColor = [0.25 0.25 0.25];   % dark gray
xline(0)
ax = gca;
ax.XAxis.Exponent = 0;
xtickformat('%.0f%%');
xlabel('Change from HCA Baseline Annual Average Total (%)')
title('Sensitivity of Annual Average Total Cost (HCA) to Key Parameters')
legend({'Low Case', 'High Case'}, 'Location','southeast')

figure(101)
stackedBarData = costsTable{:, ["MortalityVLL ($m)", "MorbidityHCA ($m)", "DirectCentral ($m)"]};
barTotals = sum(stackedBarData, 2);
allBarTotal = sum(barTotals);
meanBarTotal = mean(barTotals);

b = bar(categorical(costsTable.Year), stackedBarData, 'stacked');
b(1).FaceColor = cMortality;
b(2).FaceColor = cMorbidity;
b(3).FaceColor = cDirect;

hold on;
text(categorical(costsTable.Year), barTotals, num2str(barTotals, '%.1f'), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

meanLine = yline(meanBarTotal, '--m', 'LineWidth', 1.5);
meanLine.Label = ['Average: $' num2str(meanBarTotal, '%.1f') 'm'];
meanLine.LabelHorizontalAlignment = 'right';
meanLine.LabelVerticalAlignment = 'top';

hold off;

ylim([0, 500]);
xlabel('Financial Years');
ylabel("$m, 2024-2025 AUD");
legend({'Mortality (VLL)', 'Morbidity', ...
       'Direct costs (hospital + fire service)'}, 'Location', ...
       'southoutside', 'Orientation', 'horizontal');
title('Annual Cost of Residential Fire Injury and Death by Component')
ax = gca;
ax.FontSize = 12;

figure(102)
b = bar(categorical(costsTable.Year), costsTable.("DirectCentral ($m)"));
b.FaceColor = cDirect;
hold on;
plot(categorical(costsTable.Year), costsTable.("MortalityVLL ($m)"), '-o', 'Color', cMortality, 'LineWidth', 2);
plot(categorical(costsTable.Year), costsTable.("MortalityVSL ($m)"), '--s', 'Color', cMortality,'LineWidth', 2);
hold off;
xlabel("Financial Year");
ylabel("$m, 2024-25 dollars");
legend({'Direct costs (hospital + fire service)', 'Mortality (VLL)', 'Mortality (VSL, comparison)'});
title("Direct Costs and Mortality Value of Residential Fires");

figure(103)
b = bar(categorical(costsTable.Year), MortalityResultsTable.("Residential Deaths"));
b.FaceColor = 'flat';
b.CData(1:4, :) = repmat(cMortality, 4, 1);
b.CData(5:7, :) = repmat(0.5*cMortality + 0.5*[1 1 1], 3, 1);
xlabel("Financial Year");
ylabel('Estimated Number of Deaths');
title("Estimated Number of Deaths in Residential Fires");
ax = gca;
ax.FontSize = 12;

figure(104)
lower   = costsTable.("DirectLower ($m)");
central = costsTable.("DirectCentral ($m)");
upper   = costsTable.("DirectUpper ($m)");
fill([1:7 fliplr(1:7)], [lower' fliplr(upper')], cDirect, 'FaceAlpha', 0.25, 'EdgeColor', 'none')
hold on
plot(1:7, central, '-o', 'Color', cDirect, 'LineWidth', 2)
hold off
xticks(1:7)
xticklabels(costsTable.Year);
xlabel("Financial Year");
ylabel("$m, 2024-25 dollars");
title("Direct Costs (Hospital + Fire Service): Low, Central and High Scenarios");
xlim([0.5 7.5]);
ylim([0 250]);
