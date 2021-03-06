/*
Code merges the individual clean claims files together. Files merged are:
1. ccw.final_hs - hospice stay data, limited to sample from mbs processing
2. ccw.mb_final_cc - demo, cc and other information from master beneficiary files
3. cw.ip_snf - inpatient and snf claims
4. ccw.outpat_fin - outpatient claims
5. ccw.dmehhacarr - costs from dme, hh and carrier claims

Final data files saved in sas as ccw.final1 and in Stata as all_claims_clean.dta

*/

libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10';
libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';

/*drop unneeded variables from hospice dataset
many of these are beneficiary demo info that will be re-coded with mbs file data instead
of the claims data*/
data final_hs;
set ccw.final_hs;
run;

proc freq data=final_hs;
table start21;
run;

/*code race and ethnicity, gender, date of death variables from the mbs file*/
data final_mb_cc_dod;
set ccw.mb_final_cc;
run;
proc freq;
table re_: female dod_ndi_ind /missprint;
run;

data final_inpat;
set ccw.ip_snf;
run;

data final_outpat;
set ccw.outpat_fin;
run;

data final_dmehhacarr;
set ccw.dmehhacarr;
drop clm_id;
run;

/********************************************************************/
/******** Begin merging datasets                        *************/
/********************************************************************/

/*merge hospice and mbs datasets*/
proc sql;
create table final
as select *
from final_hs a
left join final_mb_cc(drop=NDI_DEATH_DT BENE_DEATH_DT) b
on a.bene_id = b.bene_id;
quit;


/********************************************************************/
/******** Continue merging datasets                     *************/
/********************************************************************/
/*add inpatient data to hospice+mbs dataset*/
proc sql;
create table final1
as select *
from final a
left join final_inpat b
on a.bene_id = b.bene_id;
quit;

/*quick check of merge - both freq tables should be the same*/
proc freq data=final_inpat;
	where IP_death1 ~= .;
	table IP_death1;
RUN;
proc freq data=final1;
	where IP_death1 ~= .;
	table IP_death1;
RUN;

/*merge in outpatient dataset*/
proc sql;
create table final2
as select *
from final1 a
left join final_outpat b
on a.bene_id = b.bene_id;
quit;

/*merge in dme, hha, carrier dataset - this is the last merge*/
proc sql;
create table final3
as select *
from final2 a
left join final_dmehhacarr b
on a.bene_id = b.bene_id;
quit;

/********************************************************************/
/******** Add variables for ed visits and age at hospice enrol ******/
/********************************************************************/

/*get total ed visits across IP and OP claims and age at first Hospice enrollment variables*/
data final3;
set final3;
/*ED visits total*/
ip_op_ed_cnt = ip_ed_visit_cnt + op_ed_count;
label ip_op_ed_cnt = "Total ED visits from IP and OP claims";
/*age at enrollment variable, calculated from dob and start date of first hospice stay */
age_at_enr = floor((start - BENE_BIRTH_DT) / 365.25);
label age_at_enr = "Age at first hospice enrollment";
run;

proc freq data=final3;
table ip_op_ed_cnt age_at_enr /missprint;
run;

/*save the dataset to the project working directory*/
data ccw.final;
set final3;
run;

/********************************************************************/
/******** Check race variable MBS vs hospice claims     *************/
/********************************************************************/
proc freq data=ccw.final_hs;
table BENE_RACE_CD;
run;

proc freq data=final_mb_cc;
table BENE_RACE_CD;
run;

data final_hs_race;
set ccw.final_hs (keep=bene_id bene_race_cd);
race1 = bene_race_cd + 0;
drop bene_race_cd;
run;
data final_mb_race;
set final_mb_cc (keep=bene_id bene_race_cd);
race2 = bene_race_cd + 0;
drop bene_race_cd;
run;
proc sql;
create table race_diff
as select *
from final_hs_race a
left join final_mb_race b
on a.bene_id = b.bene_id;
quit;
data race_diff;
set race_diff;
diff = race2 - race1;
run;
/*sample = 149814 beficiaries, all beneficiaries have race/ethnicity coded in mbs file
7587 have missing race/ethnicity in the hospice claims
for non missing beneficiaries, 99.6% of sample has no conflict between the hospice claims and mbs
Just use mbs race/ethnicity variable in final dataset */
proc freq data=race_diff;
table diff race1*race2 race2 /missprint;
run;
data zzzztest;
set race_diff;
if diff ~= 0;
if race1 ~= .;
run;
data ccw.race;
set zzzztest;
run;

/********************************************************************/
/******** Recode negative IP and OP total costs         *************/
/********************************************************************/
/*Deal with negative IP and OP costs
Look at cases where ip total cost is negative*/
data costs;
set ccw.final;
if ip_tot_cost < 0;
run;

data medpar;
	set merged.medpar_all_file;
run;

data costs1;
set medpar;
if bene_id = 'ZZZZZZZ3IOZkyyk' or bene_id = 'ZZZZZZZ3OZIIOOu' or bene_id = 'ZZZZZZZ3pu9uyyy' or bene_id = 'ZZZZZZZOZuI3puu' or bene_id = 'ZZZZZZZOypO9pOI' or bene_id = 'ZZZZZZZypZZ9ku4';
run;

proc contents data=costs1 varnum;
run;

proc sort data=costs1;
by BENE_ID ADMSN_DT;
run;

proc sql;
create table costs2
as select a.*, b.start, b.end
from costs1 a
left join ccw.for_medpar b
on a.bene_id = b.bene_id;
run;

data costs2;
set costs2;
if admsn_dt >= start;
run;

proc freq data=base_cost;
table CLM_PMT_AMT;
run;

data costs_out;
set base_cost1;
if inhospice_cost1 < 0 or posthospice_cost1 < 0;
run;

data recode_cost;
set ccw.final;
ip_tot_cost_imp=0;
op_tot_cost_imp=0;
if ip_tot_cost < 0 then do;
   ip_tot_cost = 0;
   ip_tot_cost_imp=1;
end;
if op_cost < 0 then do;
   op_cost = 0;
   op_tot_cost_imp=1;
end;
label ip_tot_cost_imp="IP Neg. Cost Adjusted";
label op_tot_cost_imp="OP Neg. Cost Adjusted";
run;

proc freq data=recode_cost;
table ip_tot_cost_imp op_tot_cost_imp;
run;

/********************************************************************/
/******** Update disenrollment variable                 *************/
/********************************************************************/
/** Recode disenrollment from Hospice variable:
Changing those with DEC 31st Discharge date but coded as still patient*/

data hospice1;
set recode_cost;
if end = '31DEC2010'd then do;
if discharge = 30 then disenr = 0;
end;
run;

proc freq data=recode_cost;
table disenr;
run;
proc freq data=hospice1;
table disenr;
run;

/*****************************************************************/
/*** Save the final dataset - use this dataset for analysis ******/
/*****************************************************************/
data ccw.final1;
set hospice1;
run;

/*****************************************************************/
/*Output to stata for sum stats*/
/*****************************************************************/
proc export data=ccw.final1
outfile='J:\Geriatrics\Geri\Hospice Project\Hospice\working\all_claims_clean.dta'
replace;
run;


/*a few additional checks*/
data hospice3;
set ccw.final1;
if discharge = 1;
run;

proc freq data=hospice3;
table count_hs_stays;
run;
proc freq data=ccw.final1;
table count_hs_stays;
run;

data hospice3a;
set hospice3;
if count_hs_stays > 1 and hs1_death = 0;
hospice_death = 0;
run;

%macro death;
%do i = 2 %to 21;
	data hospice3a;
	set hospice3a;
	if discharge&i = 40 or discharge&i = 41 or discharge&i = 42 then hospice_death = 1;
	run;
%end;
%mend;
%death;

proc freq data=hospice3a;
table hospice_death;
run;

/*means for hospice*/

proc means data=ccw.final1;
var disenr;
run;
