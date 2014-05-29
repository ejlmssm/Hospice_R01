libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

data tables;
set ccw.final_hosp_county;
run;

data table1;
set tables;
/*age recode*/
if age_at_enr < 65 then agecat = 0;
if age_at_enr >= 65 and age_at_enr < 70 then agecat = 1;
if age_at_enr >= 70 and age_at_enr < 75 then agecat = 2;
if age_at_enr >= 75 and age_at_enr < 80 then agecat = 3;
if age_at_enr >= 80 and age_at_enr < 85 then agecat = 4;
if age_at_enr >= 85 then agecat = 5;
/*race recode*/
if re_white = 1 then race = 1;
if re_black = 1 then race = 2;
if re_other = 1 then race = 3;
if re_asian = 1 then race = 4;
if re_hispanic = 1 then race = 5;
if re_na = 1 then race = 6;
if re_unknown = 1 then race = 7;
/*annual patients recode*/
if total_patient<20 then sizecat=1;
else if (total_patient>=20 and total_patient<50) then sizecat=2;
else if (total_patient>=50 and total_patient<100) then sizecat=3;
else if (total_patient>=100) then sizecat=4;
/*changing ownership stuff*/
ownership = 3;
if form_owner = 1 or form_owner = 2 then ownership = 1;
if form_owner = 3 then ownership = 2;
/*prim diag*/
prin_diag_cat = 0;
if substr(left(trim(primary_icd)),1,1) in ('V','E','v','e') then prin_diag_cat=17;*put "v,E" into the others group;
if substr(left(trim(primary_icd)),1,1) not in ('V','E','v','e') then do;
prim_diag_str = substr(primary_icd,1,3);
prim_diag = prim_diag_str+0;
end;
if (0<prim_diag<140) then prin_diag_cat=1;
if 240>prim_diag>=140 then prin_diag_cat=2;
if 280>prim_diag>=240 then prin_diag_cat=3;
if 290>prim_diag>=280 then prin_diag_cat=4;
if 320>prim_diag>=290 then prin_diag_cat=5;
if 390>prim_diag>=320 then prin_diag_cat=6;
if 460>prim_diag>=390 then prin_diag_cat=7;
if 520>prim_diag>=460 then prin_diag_cat=8;
if 580>prim_diag>=520 then prin_diag_cat=9;
if 630>prim_diag>=580 then prin_diag_cat=10;
if 678>prim_diag>=630 then prin_diag_cat=11;
if 710>prim_diag>=680 then prin_diag_cat=12;
if 740>prim_diag>=710 then prin_diag_cat=13;
if 760>prim_diag>=740 then prin_diag_cat=14;
if 780>prim_diag>=760 then prin_diag_cat=15;
if 800>prim_diag>=780 then prin_diag_cat=16;
if prim_diag>=800 then prin_diag_cat=17;
prin_diag_cat1 = 7;
if prin_diag_cat = 2 then prin_diag_cat1 = 1;
if prin_diag_cat = 5 then prin_diag_cat1 = 2;
if prin_diag_cat = 6 then prin_diag_cat1 = 3;
if prin_diag_cat = 7 then prin_diag_cat1 = 4;
if prin_diag_cat = 8 then prin_diag_cat1 = 5;
if prin_diag_cat = 16 then prin_diag_cat1 = 6;
/*CC*/
if TOT_GRP = 0 then CC_grp = 0;
if TOT_GRP = 1 then CC_grp = 1;
if TOT_GRP > 1 then CC_grp = 2;
run;

proc format;
value prindiagfmt
        1='NEOPLASMS'
        2='MENTAL DISORDERS'
        3='DISEASES OF THE NERVOUS SYSTEM AND SENSE ORGANS'
        4='DISEASES OF THE CIRCULATORY SYSTEM'
        5='DISEASES OF THE RESPIRATORY SYSTEM '
        6='SYMPTOMS, SIGNS, AND ILL-DEFINED CONDITIONS'
        7='Other'
;
run;

/*table 1 material: gender, age, race, */
proc freq data=table1;
format prin_diag_cat1 prindiagfmt.;
table female agecat race sizecat region ownership prin_diag_cat1 cc_grp;
run;

proc freq data=table1;
table Open_access;
run;

data table2;
set table1;
loglos = log(total_los + 1);
run;

/*table 2 LOS*/
proc ttest data=table2;
class open_access;
var total_los;
run;
proc ttest data=table2;
class chemo;
var total_los;
run;
proc ttest data=table2;
class Tpn;
var total_los;
run;
proc ttest data=table2;
class trnsfusion;
var total_los;
run;
proc ttest data=table2;
class Intracath;
var total_los;
run;
proc ttest data=table2;
class Pall_radiat;
var total_los;
run;
proc ttest data=table2;
class No_fam_cg;
var total_los;
run;
proc ttest data=table2;
class Tube_feed;
var total_los;
run;

/*obtain the mean/median values*/
ods rtf body = "J:\Geriatrics\Geri\Hospice Project\meanandmedian.rtf";
proc means data=table2 n mean median;
	class open_access;
	var total_los;
run;
proc means data=table2 n mean median;
	class chemo;
	var total_los;
run;
proc means data=table2 n mean median;
	class tpn;
	var total_los;
run;
proc means data=table2 n mean median;
	class trnsfusion;
	var total_los;
run;
proc means data=table2 n mean median;
	class intracath;
	var total_los;
run;
proc means data=table2 n mean median;
	class pall_radiat;
	var total_los;
run;
proc means data=table2 n mean median;
	class no_fam_cg;
	var total_los;
run;
proc means data=table2 n mean median;
	class tube_feed;
	var total_los;
run;
ods rtf close;

/*table 2 wilcoxon p value*/
proc npar1way data=table2 wilcoxon;
	class open_access;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class chemo;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Tpn;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class trnsfusion;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Intracath;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Pall_radiat;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class No_fam_cg;
	var total_los;
run;
proc npar1way data=table2 wilcoxon;
	class Tube_feed;
	var total_los;
run;


/*table 2 disenrolled*/
proc freq data=table2;
table open_access*disenr / chisq;
run;
proc freq data=table2;
table chemo*disenr / chisq;
run;
proc freq data=table2;
table Tpn*disenr / chisq;
run;
proc freq data=table2;
table trnsfusion*disenr / chisq;
run;
proc freq data=table2;
table Intracath*disenr / chisq;
run;
proc freq data=table2;
table Pall_radiat*disenr / chisq;
run;
proc freq data=table2;
table No_fam_cg*disenr / chisq;
run;
proc freq data=table2;
table Tube_feed*disenr / chisq;
run;

/*Table 2 cancer*/
proc freq data=table2;
table open_access*CC_GRP_14 / chisq;
run;
proc freq data=table2;
table chemo*CC_GRP_14 / chisq;
run;
proc freq data=table2;
table Pall_radiat*CC_GRP_14 / chisq;
run;


/*table 3 information*/
data table3;
set table2;
totalcosts = sum(totalcost1, totalcost2, totalcost3, totalcost4, totalcost5, totalcost6, totalcost7, totalcost8, totalcost9, totalcost10, totalcost11, totalcost12, totalcost13, totalcost14,
totalcost15, totalcost16, totalcost17, totalcost18, totalcost19, totalcost20, totalcost21, dme_cost, hha_cost, carr_cost, ip_tot_cost, snf_cost, op_cost);

totalcosts_hospice = sum(totalcost1, totalcost2, totalcost3, totalcost4, totalcost5, totalcost6, totalcost7, totalcost8, totalcost9, totalcost10, totalcost11, totalcost12, totalcost13, totalcost14,
totalcost15, totalcost16, totalcost17, totalcost18, totalcost19, totalcost20, totalcost21);

totalcosts_nonhospice = sum(dme_cost, hha_cost, carr_cost, ip_tot_cost, snf_cost, op_cost);

logtotalcosts = log(totalcosts + 1);
logtotalcosts_hospice = log(totalcosts_hospice + 1);
logtotalcosts_nonhospice = log(totalcosts_nonhospice + 1);
end_date = BENE_DEATH_DATE;
if end_date = . then end_date = '31DEC2010'd;
num_of_days = end_date - start + 1;
avg_exp_perday = totalcosts/total_los;
log_avg_exp = log(avg_exp_perday + 1);
avg_exp_tilldeath = totalcosts/num_of_days;
log_exp_tilldeath = log(avg_exp_tilldeath + 1);
num_of_days_nonhospice = num_of_days - total_los;
hospice_exp = totalcosts_hospice / total_los;
other_exp = totalcosts_nonhospice / num_of_days_nonhospice;
run;
data table3_test;
set table3;
humpnumber = 1;
if avg_exp_tilldeath > 450 then humpnumber = 2;
nonhospice = 0;
if logtotalcosts_nonhospice > 0 then nonhospice = 1;
less_than_normal = 0;
if avg_exp_tilldeath < 150 then less_than_normal = 1;
less_than_normal1 = 0;
if avg_exp_perday < 150 then less_than_normal1 = 1;
run;
data table3_test1;
set table3;
if avg_exp_tilldeath > 1000;
run;
proc freq data=table3;
table num_of_days;
run;
ods rtf body = "J:\Geriatrics\Geri\Hospice Project\exp.rtf";
proc univariate data=table3;
var totalcosts;
histogram;
run;
proc univariate data=table3;
var logtotalcosts;
histogram;
run;
ods rtf close;
ods rtf body = "N:\Documents\Downloads\Melissa\avgcost.rtf";
proc univariate data=table3;
var avg_exp_perday;
histogram;
run;
proc univariate data=table3;
var log_avg_exp;
histogram;
run;
ods rtf close;
ods rtf body = "N:\Documents\Downloads\Melissa\avgexp_disenr.rtf";
proc univariate data=table3;
class disenr;
var avg_exp_tilldeath;
histogram;
run;
proc univariate data=table3;
class disenr;
where avg_exp_tilldeath < 150;
var avg_exp_tilldeath;
histogram;
run;
ods rtf close;

proc ttest data=table3_test;
class humpnumber;
var logtotalcosts_hospice;
run;
proc freq data=table3_test;
table humpnumber*region / chisq;
run;
proc freq data=table3_test;
table less_than_normal1;
run;
data not_normal;
set table3_test;
if less_than_normal1 = 1;
if avg_exp_tilldeath < 120 then i = 1;
run;
proc univariate data=not_normal;
var avg_exp_tilldeath;
histogram;
run;



/*obtaining the mean and median of costs*/
proc means data=table3 n mean median;
class open_access;
var totalcosts;
run;
/*t test of the costs*/
proc ttest data=table3;
class open_access;
var logtotalcosts;
run;
/* running the nonparametric test of costs*/
proc npar1way data=table3 wilcoxon;
class open_access;
var totalcosts;
run;

proc means data=table3 n mean median;
class open_access;
var avg_exp_perday;
run;
proc ttest data=table3;
class open_access;
var log_avg_exp;
run;
proc npar1way data=table3 wilcoxon;
class open_access;
var totalcosts;
run;

/*2x2 table for those who have ED visits greater or equal to 1*/
proc freq data=table3;
table open_access*ip_ed_visit_ind / chisq;
run;
/*doing a poisson regression on the number of visits. Crude model*/
proc genmod data=table3;
class open_access / param = glm;
model ip_ed_visit_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for ED visit count*/
proc npar1way data=table3 wilcoxon;
class open_access;
var ip_ed_visit_cnt;
run;
/*number of stays in ED without zeros*/
proc means data = table3 n mean median min max;
class open_access;
where ip_ed_visit_cnt ~= 0;
var ip_ed_visit_cnt;
run;
proc npar1way data=table3 wilcoxon;
where ip_ed_visit_cnt ~=0;
class open_access;
var ip_ed_visit_cnt;
run;
/*2x2 table for those have have ICU visits greater or equal to 1*/
proc freq data=table3;
table open_access*icu_stay_ind / chisq;
run;
/*doing a poisson regression on the number of ICU stays*/
proc genmod data=table3;
where icu_stay_cnt ~= 0;
class open_access / param = glm;
model icu_stay_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric test for # of ICU stays*/
proc npar1way data=table3 wilcoxon;
class open_access;
var icu_stay_cnt;
run;
/*number of stays in ICU without zero*/
proc means data = table3 n mean median min max;
class open_access;
where icu_stay_cnt ~= 0;
var icu_stay_cnt;
run;
proc npar1way data=table3 wilcoxon;
where icu_stay_cnt ~=0;
class open_access;
var icu_stay_cnt;
run;
/*number of stays in hospital poisson regression*/
proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_cnt = open_access / type3 dist=poisson;
run;
/*non-parametric for # of hosp stays*/
proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_cnt;
run;
/*number of stays in the Hosp without zeroes*/
proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_cnt~= 0;
var hosp_adm_cnt;
run;
proc npar1way data=table3 wilcoxon;
where hosp_adm_cnt ~=0;
class open_access;
var hosp_adm_cnt;
run;
proc freq data=table3;
table open_access*hosp_adm_ind / chisq;
run;
data missing;
set table3;
if open_access = .;
run;
proc freq data=missing;
table POS1;
run;
/*poisson for the number of days a person was in the hospital*/
proc genmod data=table3;
class open_access / param = glm;
model hosp_adm_days = open_access / type3 dist=poisson;
run;
/*non-parametric for the number of days in the hospital*/
proc npar1way data=table3 wilcoxon;
class open_access;
var hosp_adm_days;
run;

/*those who have no costs*/
data zerocost;
set table3;
if totalcosts = 0;
run;
/*these people have charges. Total of 308*/

/*total patients column*/
proc means data=table3 n mean median min max;
var totalcosts;
run;
proc means data=table3 n mean median min max;
var avg_costs;
run;
proc freq data=table3;
table ip_ed_visit_ind / chisq;
run;
proc means data = table3 n mean median min max;
where ip_ed_visit_cnt ~= 0;
var ip_ed_visit_cnt;
run;
proc freq data=table3;
table icu_stay_ind / chisq;
run;
proc means data = table3 n mean median min max;
where icu_stay_cnt ~= 0;
var icu_stay_cnt;
run;
proc freq data=table3;
table hosp_adm_ind / chisq;
run;
proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_cnt~= 0;
var hosp_adm_cnt;
run;
proc means data = table3 n mean median min max;
class open_access;
where hosp_adm_days~= 0;
var hosp_adm_days;
run;

proc univariate data=table3;
var num_of_days;
histogram;
run;




data table4;
set table3;
run;

proc contents data=table4;
run;
proc contents data=table4 varnum;
run;

ods rtf body = "N:\Documents\Downloads\Melissa\preferredPractice.rtf";
proc freq data=table4;
table crisis_mgt;
run;
proc freq data=table_crisis_miss;
table POS1;
run;
proc freq data=table4;
table monitor_pan;
run;
proc freq data=missing_pan;
table POS1;
run;
proc freq data=table4;
table monitor_ax;
run;
proc freq data=missing_ax;
table pos1;
run;
proc freq data=table4;
table monitor_con;
run;
proc freq data=missing_con;
table pos1;
run;
proc freq data=table4;
table monitor_del;
run;
proc freq data=missing_del;
table pos1;
run;
proc freq data=table4;
table monitor_dep;
run;
proc freq data=missing_dep;
table pos1;
run;
proc freq data=table4;
table monitor_dys;
run;
proc freq data=missing_dys;
table pos1 ;
run;
proc freq data=table4;
table monitor_fat;
run;
proc freq data=missing_fat;
table pos1;
run;
proc freq data=table4;
table monitor_nau;
run;
proc freq data=missing_nau;
table pos1;
run;
proc freq data=table4;
table fampref goalscare;
run;
proc freq data=table4;
table advancedir legsurrogate patpref;
run;
ods rtf close;

data table_crisis_miss;
set table4;
if crisis_mgt = .;
run;
proc freq data=table_crisis_miss;
table POS1;
run;
data missing_pan;
set table4;
if monitor_pan = .;
run;
proc freq data=missing_pan;
table POS1;
run;
data missing_ax;
set table4;
if monitor_ax = .;
run;
proc freq data=missing_ax;
table POS1;
run;
data missing_con;
set table4;
if monitor_con = .;
run;
proc freq data=missing_con;
table POS1;
run;
data missing_del;
set table4;
if monitor_del = .;
run;
proc freq data=missing_del;
table POS1;
run;
data missing_dep;
set table4;
if monitor_dep = .;
run;
proc freq data=missing_dep;
table pos1;
run;
data missing_dys;
set table4;
if monitor_dys = .;
run;
proc freq data=missing_dys;
table POS1;
run;
data missing_fat;
set table4;
if monitor_fat = .;
run;
proc freq data=missing_fat;
table POS1;
run;
data missing_nau;
set table4;
if monitor_nau = .;
run;
proc freq data=missing_nau;
table POS1;
run;

