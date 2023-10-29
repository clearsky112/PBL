clear;clc;
get_x11colours; %this is just for loading more colors, no need
flnc='20180803_test2_CHM160162_000.nc';
rtimezone=-7;
Ht_o = double(nc_varget(flnc,'time'));      %UTC
ftunits = nc_attget(flnc,'time','units');
[ct_greg,ct_scale,ct_toto,ct_time] = parsetnc(ftunits);
Ht  = ct_time+Ht_o*ct_scale+rtimezone/24;   %localtime
pbs=nc_varget(flnc,'pbl');
beta_raw=nc_varget(flnc,'beta_raw');
range=nc_varget(flnc,'range');
cbh=nc_varget(flnc,'cbh');
cbh(cbh<0)=NaN;
pbs(pbs<=0)=NaN;


x=repmat(Ht,[1,1024]);
y=repmat(range,[1 5761]);

pcolor(x,y',beta_raw);shading flat; hold on;
caxis([0 10000]);

cc={c_pink,c_green4,c_blue};
for j=1:3
H(j)=plot(Ht, pbs(:,j),'o','color',cc{j}); hold on;
H(4)=plot(Ht, cbh(:,j),'rx'); hold on;


time=Ht(1:200:length(Ht)); %Ht(1):1:Ht(end);

dateform = 'HH:MM'; %'mm/DD';

dtstr = datestr(time,dateform);
ylim([0 15000]);
%xlim([datemin,datemax]);
xticks(time);
xticklabels(dtstr);
xtickangle(45);
%set(gca, 'YScale', 'log');
end

legend(H,'aerosol layer 1','aerosol layer 2','aerosol layer 3','cloud base layer');
xlabel('Time (Local)');
ylabel('Height (m)');