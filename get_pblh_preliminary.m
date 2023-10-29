clear;
clc;
%merged all April netcdf files together to a mat file:
load 04_fre.mat
rhour = round(rem(tottime,1)*24);
%%% only select the daytime period
index0=find(rhour>=8 & rhour<=16); 
pbltime=tottime(index0);
pblheight=totpbl(index0,:);
cloudheight=totcbh(index0,:);
betanew=totbeta(index0,:);


for day=22:29  % just read several days
    
dateminall = datenum(2019,4,day,00,0,0);
datemaxall = datenum(2019,4,day,23,0,0);
index1= (pbltime>=dateminall & pbltime<=datemaxall);

daytime=pbltime(index1);
daypbl=pblheight(index1,:);
daycloud=cloudheight(index1,:);
daybeta=betanew(index1,:);

daypbl(daypbl<0)=NaN;
daycloud(daycloud<=0)=NaN;

lowcloud=daycloud(:,1);

datemin = datenum(2019,4,day,06,0,0);
datemax = datenum(2019,4,day,11,0,0);
index2= (daytime>=datemin & daytime<=datemax);
firstpbs=daypbl(index2,1);

spts=find(firstpbs<=prctile(firstpbs,2.5));
sptindex=spts(1);

daypbl=daypbl(sptindex:end,:);   %dimension: time, height
daytime=daytime(sptindex:end,:);
daybeta=daybeta(sptindex:end,:);

daypbltemp=daypbl;

%%%Below is the code to determine pblh%%%%%%
%%%I assumed the first layer (lowest) usually represents the boundary layer
%%%And I give some creteria to screen the data


for j=1:length(daypbl(:,1))-1    
    
    if(abs(daypbltemp(j+1,1)-daypbltemp(j,1))>abs(daypbltemp(j+1,2)-daypbltemp(j,1)))   % check the delta h between the 1st and 2nd time step
        daypbltemp(j+1,1)=daypbltemp(j+1,2);
    end
    
    if((daypbl(j+1,1)-daypbl(j,1))<-100)  % set a critical height=100m (arbitrary) 
         daypbltemp(j+1,1)=NaN;
    end
     
    if(abs(daypbl(j+1,1)-daypbl(j,1))>50) % set a critical height=50m (arbitrary) 
        badpbl=daypbl(j+1,1);
        badpblidx=j;
        daypbltemp(j+1,1)=NaN;

        if (badpblidx+30<length(daypbl))  % set a critical delta t=30 (arbitrary)
            badpblidxed=badpblidx+30;
        else
            badpblidxed=length(daypbl);
        end
        
        for k=badpblidx:badpblidxed
            if(k-badpblidx<100)
                if(abs(daypbl(k,1)-badpbl)<50)
                    daypbltemp(k,1)=NaN;
                end
            else
                if(abs(daypbl(k,1)-badpbl)<100)
                    daypbltemp(k,1)=NaN;
                end
            end
        end
        
    end
    
end

x=repmat(daytime,[1,400]);
y=repmat(range(1:400),[1 length(daytime)]);

pcolor(x,y',log10(daybeta(:,1:400)));shading flat; colorbar; hold on;
caxis([5.3 6.5]);
colormap('jet');
pbldetermine=daypbltemp(:,1);
pbldetermineavg=movmean(pbldetermine,10);

plot(daytime,pbldetermineavg(:,1),'ko');

%%%Below are wrf outputs
flnc='FRE_2019040100_2019050100_unstag_a1.nc';
rtimezone=-8;
utct = nc_varget(flnc,'Times');      %UTC
lt  = datenum(utct)+rtimezone/24;   %localtime
pblh=nc_varget(flnc,'PBLH');
index1= (lt>=dateminall & lt<=datemaxall);
pblh_day_a1=pblh(index1);
H(1)=plot(lt(index1),pblh_day_a1,'m','linewidth',2); hold on;

flnc='FRE_2019040100_2019050100_unstag_a2.nc';
utct = nc_varget(flnc,'Times');      %UTC
lt  = datenum(utct)+rtimezone/24;   %localtime
pblh=nc_varget(flnc,'PBLH');
index1= (lt>=dateminall & lt<=datemaxall);
pblh_day_a1=pblh(index1);
H(2)=plot(lt(index1),pblh_day_a1,'y','linewidth',2); hold on;

legend(H,'PLX-YSU','Noah-MYJ','Location','northwest');


timemin=daytime(1);%+1/24;
time=timemin:1/24:daytime(end);
dateform = 'mm-DD HH'; %'mm/DD';
dtstr = datestr(time,dateform);
ylim([0 2000]);
xticks(time);
xticklabels(dtstr);
xtickangle(45);
ylabel('Height [m]');
set(gca,'fontsize',15);
flout=['2019_04',sprintf('%2.2d',day)];
floutpng=[flout,'_fre.png'];
print('-r100','-dpng', [floutpng]);
clf;

towrite1=cellstr(datestr(daytime));
pblh=pbldetermineavg(:,1);

for i=1:length(pblh)
    towrite{i}=[towrite1{i},',',num2str(pblh(i))];
end

fid=fopen(['pblh_fre_04',num2str(day),'.csv'],'w');
fprintf(fid,'%s\n',towrite{:});
status=fclose(fid);
end

%end
