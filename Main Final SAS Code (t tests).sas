%let path = C:\Users\zzhong13\Downloads;
libname final "&path";

ods pdf file = "&path\CEO.pdf";
proc import datafile="&path\CEO Dismissal 2021.03.18.xlsx"
        out=ceo
        dbms= xlsx
        replace;
    

     getnames=yes;
run;

/*proc contents data = ceo; run;*/
/*proc contents data = final.crsp_comp; run;*/

data crsp_comp;

  set final.crsp_comp (rename=(GVKEY= GVKEY_CHAR));

  GVKEY = int(GVKEY_CHAR);

  drop GVKEY_CHAR;

run;


proc sql; *Merge CEO turnover and monthly returns and implied vol and trading volume;
	create table final.ceo_return as 
    select unique i.gvkey, i.leftofc, i.fyear_gone, i.coname,i.departure_code, i.ceo_dismissal, j.mthprcdt, j.mthret,j.mthvol, j.OPTVOL
	from ceo i,  crsp_comp j
	where i.gvkey= j.GVKEY
	and -15<=(intck("months", i.leftofc, j.mthprcdt))<=15;
/*	*group by i.gvkey, i.leftofc;*/
quit;  	

data ceo_return;
set  final.ceo_return;
if mthprcdt>=leftofc then post_event =1;
else post_event = 0;
run;

proc sort data=ceo_return; by departure_code ; run;
proc ttest data = ceo_return H0 = 0 SIDES =2;where departure_code <>. and departure_code <>9;
  by  departure_code;
  class post_event;
  var OPTVOL mthret mthvol;
run;







/*Implied Vol Shift*/

proc sql;
	create table ceo_return_vol as 
    select unique  departure_code, mean(OPTVOL) as implied_vol, intck("months", leftofc, mthprcdt) as t
	from final.ceo_return 
	where OPTVOL<>. and departure_code <>. 
	group by departure_code,t;
quit;


/*proc sort data=ceo_return_vol; by t ; run;*/

data ceo_return_vol;
set ceo_return_vol;
if t>=0 then post_event =1;
else post_event = 0;
run;

proc sort data=ceo_return_vol; by departure_code ; run;
proc ttest data = ceo_return_vol H0 = 0 SIDES =2;where departure_code <>. and departure_code <>9;
  by  departure_code;
  class post_event;
  var implied_vol;
run;



proc sort data=ceo_return_vol; by t ; run;
proc transpose data=ceo_return_vol 
out = final.ceo_retunr_vol_transpose(Rename=(_1=death _2=ill  _3= dismissed_for_performance   _4=dismissed_for_legal_violation
_5 =retired   _6 = new_opportunity  _7= other  _8= missing   _9= error ));  
	by t;  
 	id departure_code;  
* 	id sur_rank;  
	var implied_vol; 	
run;







ods noproctitle;

PROC SGPLOT DATA = final.ceo_retunr_vol_transpose; 
	where _NAME_="implied_vol";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = death/ LEGENDLABEL = "death";
	SERIES X = t Y = ill/ LEGENDLABEL = "ill";
/*    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";*/
/*	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";*/
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE1 "Implied Vol Shift based on CEO death/illness";
*	TITLE "PEAD based on raw return";
RUN;
title;

PROC SGPLOT DATA = final.ceo_retunr_vol_transpose; 
	where _NAME_="implied_vol";
*	where _NAME_="cum_ar_med";

/*	SERIES X = t Y = death/ LEGENDLABEL = "death";*/
/*	SERIES X = t Y = ill/ LEGENDLABEL = "ill";*/
    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";
	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE2 "Implied Vol based on CEO Involuntary Dismissal";
*	TITLE "PEAD based on raw return";
RUN;
title;


PROC SGPLOT DATA = final.ceo_retunr_vol_transpose; 
	where _NAME_="implied_vol";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = retired/ LEGENDLABEL = "retired";
	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";


	TITLE3 "Implied Vol based on CEO Voluntary Turnover";
*	TITLE "PEAD based on raw return";
RUN;

title;


/*Trading Volume*/


proc sql;
	create table ceo_return_volume as 
    select unique  departure_code, mean(mthvol) as trading_volume, intck("months", leftofc, mthprcdt) as t
	from final.ceo_return 
	where mthvol<>. and departure_code <>. 
	group by departure_code,t
    having -15<=t <=15;
quit;
data ceo_return_volume;
set ceo_return_volume;
if t>=0 then post_event=1;
else post_event =0;
run;

proc sort data=ceo_return_volume; by departure_code ; run;
proc ttest data = ceo_return_volume H0=0 SIDES=2;where departure_code <>. and departure_code <>9;
by departure_code;
class post_event;
var trading_volume;
run;



proc sort data=ceo_return_volume; by t ; run;
proc transpose data=ceo_return_volume 
out = final.ceo_retunr_volume_transpose(Rename=(_1=death _2=ill  _3= dismissed_for_performance   _4=dismissed_for_legal_violation
_5 =retired   _6 = new_opportunity  _7= other  _8= missing   _9= error ));  
	by t;  
 	id departure_code;  
* 	id sur_rank;  
	var trading_volume; 	
run;


ods noproctitle;

PROC SGPLOT DATA = final.ceo_retunr_volume_transpose; 
	where _NAME_="trading_volume";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = death/ LEGENDLABEL = "death";
	SERIES X = t Y = ill/ LEGENDLABEL = "ill";
/*    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";*/
/*	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";*/
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE1 "Trading Volume Shift based on CEO death/illness";
*	TITLE "PEAD based on raw return";
RUN;
title;

PROC SGPLOT DATA = final.ceo_retunr_volume_transpose; 
	where _NAME_="trading_volume";
*	where _NAME_="cum_ar_med";

/*	SERIES X = t Y = death/ LEGENDLABEL = "death";*/
/*	SERIES X = t Y = ill/ LEGENDLABEL = "ill";*/
    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";
	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE2 "Trading Volume based on CEO Involuntary Dismissal";
*	TITLE "PEAD based on raw return";
RUN;
title;


PROC SGPLOT DATA = final.ceo_retunr_volume_transpose; 
	where _NAME_="trading_volume";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = retired/ LEGENDLABEL = "retired";
	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";


	TITLE3 "Trading Volume based on CEO Voluntary Turnover";
*	TITLE "PEAD based on raw return";
RUN;

title;



/*Stock Returns shift*/



proc sql;
	create table ceo_return_mthret as 
    select unique  departure_code, mean(mthret) as monthly_return, intck("months", leftofc, mthprcdt) as t
	from final.ceo_return 
	where mthret<>. and departure_code <>. 
	group by departure_code,t
	having -15<=t <=15;
quit;


data ceo_return_mthret;
set ceo_return_mthret;
if t>=0 then post_event=1;
else post_event =0;
run;

proc sort data=ceo_return_mthret; by departure_code ; run;
proc ttest data = ceo_return_mthret H0=0 SIDES=2;where departure_code <>. and departure_code <>9;
by departure_code;
class post_event;
var monthly_return;
run;



proc sort data=ceo_return_mthret; by t ; run;
proc transpose data=ceo_return_mthret 
out = final.ceo_retunr_mthret_transpose(Rename=(_1=death _2=ill  _3= dismissed_for_performance   _4=dismissed_for_legal_violation
_5 =retired   _6 = new_opportunity  _7= other  _8= missing   _9= error ));  
	by t;  
 	id departure_code;   
	var monthly_return; 	
run;


PROC SGPLOT DATA = final.ceo_retunr_mthret_transpose; 
	where _NAME_="monthly_return";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = death/ LEGENDLABEL = "death";
	SERIES X = t Y = ill/ LEGENDLABEL = "ill";
/*    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";*/
/*	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";*/
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE1 "Stock Monthly Return Shift based on CEO death/illness";
*	TITLE "PEAD based on raw return";
RUN;
title;

PROC SGPLOT DATA = final.ceo_retunr_mthret_transpose; 
	where _NAME_="monthly_return";
*	where _NAME_="cum_ar_med";

/*	SERIES X = t Y = death/ LEGENDLABEL = "death";*/
/*	SERIES X = t Y = ill/ LEGENDLABEL = "ill";*/
    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";
	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE2 "Stock Monthly Return Shift based on CEO Involuntary Dismissal";
*	TITLE "PEAD based on raw return";
RUN;
title;


PROC SGPLOT DATA = final.ceo_retunr_mthret_transpose; 
	where _NAME_="monthly_return";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = retired/ LEGENDLABEL = "retired";
	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";


	TITLE3 "Stock Monthly Return Shift based on CEO Voluntary Turnover";
*	TITLE "PEAD based on raw return";
RUN;

title;





/*Accounting Ratios*/

proc sql; *Merge CEO turnover and monthly returns and implied vol;
	create table final.ceo_ratio as 
    select unique i.gvkey, i.leftofc, i.fyear_gone, i.coname,i.departure_code, i.ceo_dismissal, (j.NI/j.TEQ) as ROE,  (j.PRCC_F/j.OPREPSX) as PE_ratio,j.APDEDATE
	from ceo i,  crsp_comp j
	where i.gvkey= j.GVKEY
	and -5<=(intck("years", i.leftofc, j.APDEDATE))<=5;
/*	*group by i.gvkey, i.leftofc;*/
quit;

data ceo_ratio_t;
set  final.ceo_ratio;
if APDEDATE>=leftofc then post_event =1;
else post_event = 0;
run;

proc sort data=ceo_ratio_t; by departure_code ; run;
proc ttest data = ceo_ratio_t H0 = 0 SIDES =2;where departure_code <>. and departure_code <>9;
  by  departure_code;
  class post_event;
  var ROE PE_ratio;
run;








proc sql;
	create table ceo_ratios as 
    select unique departure_code, mean(ROE) as average_ROE, mean(PE_ratio) as average_PE, intck("years", leftofc, APDEDATE) as t
	from final.ceo_ratio 
	where ROE^=. and PE_ratio^=.
	group by departure_code, t ;
quit;

data ceo_ratios;
set ceo_ratios;
if t>=0 then post_event=1;
else post_event =0;
run;

proc sort data=ceo_ratios; by departure_code ; run;
proc ttest data = ceo_ratios H0=0 SIDES=2;where departure_code <>. and departure_code <>9;
by departure_code;
class post_event;
var average_ROE average_PE;
run;


proc sort data=ceo_ratios; by t ; run;
proc transpose data=ceo_ratios
out = final.ceo_roe_transpose(Rename=(_1=death _2=ill  _3= dismissed_for_performance   _4=dismissed_for_legal_violation
_5 =retired   _6 = new_opportunity  _7= other  _8= missing   _9= error ));  
	by t;  
 	id departure_code;   
	var average_ROE; 	
run;

PROC SGPLOT DATA = final.ceo_roe_transpose; 
	where _NAME_="average_ROE";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = death/ LEGENDLABEL = "death";
	SERIES X = t Y = ill/ LEGENDLABEL = "ill";
/*    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";*/
/*	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";*/
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE1 "ROE Shift based on CEO death/illness";
*	TITLE "PEAD based on raw return";
RUN;
title;

PROC SGPLOT DATA = final.ceo_roe_transpose; 
	where _NAME_="average_ROE";
*	where _NAME_="cum_ar_med";

/*	SERIES X = t Y = death/ LEGENDLABEL = "death";*/
/*	SERIES X = t Y = ill/ LEGENDLABEL = "ill";*/
    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";
	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE2 "ROE Shift based on CEO Involuntary Dismissal";
*	TITLE "PEAD based on raw return";
RUN;
title;


PROC SGPLOT DATA = final.ceo_roe_transpose; 
	where _NAME_="average_ROE";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = retired/ LEGENDLABEL = "retired";
	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";


	TITLE3 "ROE Shift based on CEO Voluntary Turnover";
*	TITLE "PEAD based on raw return";
RUN;

title;


proc sort data=ceo_ratios; by t ; run;
proc transpose data=ceo_ratios
out = final.ceo_PE_transpose(Rename=(_1=death _2=ill  _3= dismissed_for_performance   _4=dismissed_for_legal_violation
_5 =retired   _6 = new_opportunity  _7= other  _8= missing   _9= error ));  
	by t;  
 	id departure_code;   
	var average_PE; 	
run;

PROC SGPLOT DATA = final.ceo_PE_transpose; 
	where _NAME_="average_PE";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = death/ LEGENDLABEL = "death";
	SERIES X = t Y = ill/ LEGENDLABEL = "ill";
/*    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";*/
/*	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";*/
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE1 "P/E Shift based on CEO death/illness";
*	TITLE "PEAD based on raw return";
RUN;
title;

PROC SGPLOT DATA = final.ceo_PE_transpose; 
	where _NAME_="average_PE";
*	where _NAME_="cum_ar_med";

/*	SERIES X = t Y = death/ LEGENDLABEL = "death";*/
/*	SERIES X = t Y = ill/ LEGENDLABEL = "ill";*/
    SERIES X = t Y = dismissed_for_performance/ LEGENDLABEL = "dismissed_for_performance";
	SERIES X = t Y = dismissed_for_legal_violation/ LEGENDLABEL = "dismissed_for_legal_violation";
/*	SERIES X = t Y = retired/ LEGENDLABEL = "retired";*/
/*	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";*/



	TITLE2 "P/E Shift based on CEO Involuntary Dismissal";
*	TITLE "PEAD based on raw return";
RUN;
title;


PROC SGPLOT DATA = final.ceo_PE_transpose; 
	where _NAME_="average_PE";
*	where _NAME_="cum_ar_med";

	SERIES X = t Y = retired/ LEGENDLABEL = "retired";
	SERIES X = t Y = new_opportunity/ LEGENDLABEL = "new_opportunity";


	TITLE3 "P/E Shift based on CEO Voluntary Turnover";
*	TITLE "PEAD based on raw return";
RUN;

title;

ods pdf close;

















































