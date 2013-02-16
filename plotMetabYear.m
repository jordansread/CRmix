function plotMetabYear(year)

close all

if eq(nargin,0)
    year = '2011';
end

fontN = 'Times New Roman';
fontS = 15;
figW = 10;
figH = 7.5;
lM = 1;
bM = .5;
rM = .25;
tM = .25;
hSpc= .5;
W = figW-lM-rM;
H1 = 4;
H2 = figH-H1-hSpc-bM-tM;
tL = [.004 0];
axLw = 1;
yL2  = [80 120];
yTck2 = 80:10:140;

yL1  = [-25 48];
yTck1 = -40:10:40;

xL = [datenum([year '-03-20']) datenum([year '-11-20'])];
xTck = datenum(str2double(year),1:12,1);
    


fig_h = figure('Color','w','Units','inches','PaperSize',[figW figH],...
    'PaperPosition',[0 0 figW figH],'Position',[0 0 figW figH]);

movegui(fig_h,'center');

ax_top = axes('Parent',fig_h,'Position',[lM/figW (bM+H2+hSpc)/figH W/figW H1/figH],...
    'Box','on','XLim',xL,'TickDir','out','XTick',xTck,'XTickLabel',[],...
    'FontSize',fontS,'FontName',fontN,'LineWidth',axLw,...
    'TickLength',tL,'YLim',yL1,'YTick',yTck1);


hold on;
ax_bot = copyobj(ax_top,fig_h);
set(ax_bot,'Position',[lM/figW bM/figH W/figW H2/figH],...
    'XTickLabel',datestr(xTck,'mmm'),'YLim',yL2,'YTick',yTck2);
ylabel('Sunrise DO (% sat)','Parent',ax_bot);
ylabel('Net ecosystem production (\mumol O_{2} L^{-1} d^{-1})','Parent',ax_top);

%% now fill bottom plot

[time,DOsun] = getDOsunrise( 'Sparkling',year );

plot(time,DOsun,'k-','LineWidth',2,'Color',[.7 .7 .7],...
    'Parent',ax_bot);
pause(.5)

[time,DOsun] = getDOsunrise( 'Crystal',year );

plot(time,DOsun,'k-','LineWidth',2.5,'Color',[.5 0 0],...
    'Parent',ax_bot);
lg = legend(ax_bot,'Sparkling','Crystal','Location','NorthWest');
set(lg,'Box','off')
plot(xL,[100 100],'k-','LineWidth',.75,'Parent',ax_bot);

pause(.5)
%% now fill top plot
[time,NEP] = calcNEP2D(year);
plot(time,NEP,'ko','LineWidth',2.5,'Color',[.5 0 0],...
    'MarkerSize',9,'MarkerFaceColor','w','Parent',ax_top);

plot(xL,[0 0],'k-','LineWidth',.75,'Parent',ax_top);
print(['metabolism_' year],'-dpng','-r300')
pause(1.5);
close all;
end

