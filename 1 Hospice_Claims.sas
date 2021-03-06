/* Prepares hospice claims for analysis
1. Drops beneficiaries with first claim before Sept 2008
2. Totals revenue code days by revenue code type for each beneficiary
3. Collapses claims data into data for individual hospice stays
4. Restructures dataset so one row per beneficiary with details
about all their hospice stays as separate variables

Dataset saved as ccw.hs_stays_cleaned

Then using criteria defined in the mbs processing steps, save
hospice dataset with just mbs in sample. Dataset saved as:
ccw.final_hs
*/

/*********************************************************************/
/*********************************************************************/
/* Part 1 - Start with merged hospice claims base file 2007-10  */
/*********************************************************************/
/*********************************************************************/

libname ccw 'J:\Geriatrics\Geri\Hospice Project\Hospice\working';
libname merged 'J:\Geriatrics\Geri\Hospice Project\Hospice\Claims\merged_07_10'; 
libname hospices 'J:\Geriatrics\Geri\Hospice Project';
libname costs 'N:\Documents\Downloads\Melissa\Hospice_Cost_Data\data';


data work.hospice_base;
        set merged.hospice_base_claims_j;
run;        

/*********************************************************************/
/*********************************************************************/
/* Part 2 - Drop beneficiaries with first claim before Sept 2008     */
/*********************************************************************/
/*********************************************************************/

proc sort data=hospice_base out=hospice_base1;
        by bene_id CLM_FROM_DT;
run;

data hospice_base2; set hospice_base1;
        by bene_id;
        if first.bene_id then indic2=1;
        else indic2 + 1;
run; 


/*identifies beneficiaries with first claim prior to Sept 2008
these beneficiaries should be excluded from the sample*/
data indicator (keep = bene_id indic);
        set hospice_base2;
                if indic2 = 1 and clm_from_dt < '01SEP2008'd;
                indic = 1;
run;

/*assigns the date indicator for exclusion to all claims for the bid*/
proc sql;
	create table hospice_base3
    as select * 
    from hospice_base2 a
    left join indicator b
    on a.bene_id = b.bene_id
	where b.indic~= 1;
quit;

/*view frequencies of first claim start date by bid*/
proc sort data=hospice_base3;
        by bene_id clm_from_dt;
run;

/*********************************************************************/
/*********************************************************************/
/* Part 3 - Get revenue code day totals by type by bene id           */
/*********************************************************************/
/*********************************************************************/

data hospice_revenue;
        set merged.hospice_revenue_center_j;
run;


/*numerical conversion and drop revenue codes that aren't relevant (not hospice level of care)*/
data hospice_revenue1;
        set hospice_revenue;
        rev_code = REV_CNTR + 0;
		if rev_code > 649 and rev_code < 660;
		if REV_CNTR_DT < '01SEP2008'd then delete;
run;

proc sort data=hospice_revenue1 out=hospice_revenue2;
        by bene_id CLM_ID CLM_THRU_DT;
run;

/*Creates total days for each revenue code by claim id*/
data hospice_revenue3;
        set hospice_revenue2;
                retain tot_650 tot_651 tot_652 tot_655 tot_656 tot_657;
                        by bene_id CLM_id CLM_THRU_DT;
                                if first.CLM_ID then do;
                                        tot_650 = 0;
                                        tot_651 = 0;
                                        tot_652 = 0;
                                        tot_655 = 0;
                                        tot_656 = 0;
                                        tot_657 = 0;
										tot_659 = 0;
                                        if rev_code = 650 then tot_650 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 651 then tot_651 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 652 then tot_652 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 655 then tot_655 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 656 then tot_656 = REV_CNTR_UNIT_CNT;
                                        if rev_code = 657 then tot_657 = REV_CNTR_UNIT_CNT;
										if rev_code = 659 then tot_659 = REV_CNTR_UNIT_CNT;
                                        end;
                                else do;
                                        if rev_code = 650 then tot_650 = tot_650 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 651 then tot_651 = tot_651 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 652 then tot_652 = tot_652 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 655 then tot_655 = tot_655 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 656 then tot_656 = tot_656 + REV_CNTR_UNIT_CNT;
                                        if rev_code = 657 then tot_657 = tot_657 + REV_CNTR_UNIT_CNT;
										if rev_code = 659 then tot_659 = tot_659 + REV_CNTR_UNIT_CNT;
                                        end;
                /*converts hours to days for rev code 652*/
                tot_652_days = floor(tot_652/24);
                drop tot_652;
run;
/*keeps just one entry per claim id with the total days 
for each rev code*/
data hospice_revenue4;
        set hospice_revenue3;
                by bene_id CLM_id CLM_THRU_DT;
                tot_652 = tot_652_days;
                if last.clm_id then output;
run;

/*Creates total days for each revenue code by beneficiary (across
all claims in the revenue code files*/
data hospice_revenue5;
        set hospice_revenue4;
                retain total_650 total_651 total_652 total_655 total_656 total_657;
                        by bene_id;
                                if first.bene_id then do;
                                        total_650 = 0;
                                        total_651 = 0;
                                        total_652 = 0;
                                        total_655 = 0;
                                        total_656 = 0;
                                        total_657 = 0;
                                        total_650 = tot_650;
                                        total_651 = tot_651;
                                        total_652 = tot_652;
                                        total_655 = tot_655;
                                        total_656 = tot_656;
                                        total_657 = tot_657;
										total_659 = tot_659;
                                        end;
                                else do;
                                        total_650 = total_650 + tot_650;
                                        total_651 = total_651 + tot_651;
                                        total_652 = total_652 + tot_652;
                                        total_655 = total_655 + tot_655;
                                        total_656 = total_656 + tot_656;
                                        total_657 = total_657 + tot_657;
										total_659 = total_659 + tot_659;
                                        end;
run;

/*keeps just the final observation with the totals*/
data hospice_revenue6;
        set hospice_revenue5;
                by bene_id CLM_id CLM_THRU_DT;
                if last.bene_id then output;
run;

/*creates dataset with just the beneficiary ID and revenue code day totals*/
data total_rev_center;
        set hospice_revenue6 (keep = bene_id total_650 total_651 total_652 total_655 total_656 total_657 total_659);
run;


/*********************************************************************/
/*********************************************************************/
/* Part 4 - Check claims for multiple claims spanning continuous
hospice stays, merge total costs and start/end dates to get a list 
of unique hospice stays       */
/*********************************************************************/
/*********************************************************************/

proc sort data=hospice_base3 out=hospice_base5;
        by bene_id clm_from_dt clm_thru_dt;
run;


/*create daydiff variable = start date of current claim to end date of
previous claim - if 0 or 1, then continous stay*/
data hospice_base6;
        set hospice_base5;
                by bene_id clm_from_dt clm_thru_dt;
                daydiff = CLM_FROM_DT - LAG(CLM_THRU_DT);
                if first.bene_id then daydiff = 999;
run;

/*merge costs, end dates for claims that are for cont. stays*/
data hospice_base7;
        set hospice_base6;
                retain totalcost start end;
                by bene_id clm_from_dt;
                        if daydiff > 1 or daydiff = 999 then do;
                                start = clm_from_dt;
                                end = clm_thru_dt;
                                totalcost = CLM_PMT_AMT;
                                end;
                        if daydiff <= 1 then do;
                                totalcost = CLM_PMT_AMT + totalcost;
                                end = clm_thru_dt;
                                end;
        format start date9. end date9.;
run;

/*
data hospice_base8;
        set hospice_base7;
        retain rev_total;
                by bene_id start;
                        rev_total = rev_total + rev_days;
                        if first.start then rev_total = rev_days;
                        if rev_dif ~= 0 then rev_total = rev_days;
run;
*/

/*assign indicator for final claim for the stay*/
data hospice_base9;
        set hospice_base7;
                retain j ;
                        by bene_id start;
                                /*
                                if first.bene_id or rev_dif >0 or daydiff ~=1 then i = 0;
                                else i = i + 1;
                                */
                                j = 0;
                                if last.start then j = j + 1;
run;

proc sort data=hospice_base9 out=hospice_base10;
by bene_id end;
run;

/*
data hospice_base11;
        set hospice_base10;
                retain tot_650 tot_651 tot_652 tot_655 tot_656 tot_657;
                        by bene_id end;
                                if first.bene_id then do;
                                        if rev_code = 650 then tot_650 = rev_days;
                                        if rev_code = 651 then tot_651 = rev_days;
                                        if rev_code = 652 then tot_652 = rev_days;
                                        if rev_code = 655 then tot_655 = rev_days;
                                        if rev_code = 656 then tot_656 = rev_days;
                                        if rev_code = 657 then tot_657 = rev_days;
                                        end;
                                else do;
                                        if rev_code = 650 then tot_650 = tot_650 + rev_days;
                                        if rev_code = 651 then tot_651 = tot_651 + rev_days;
                                        if rev_code = 652 then tot_652 = tot_652 + rev_days;
                                        if rev_code = 655 then tot_655 = tot_655 + rev_days;
                                        if rev_code = 656 then tot_656 = tot_656 + rev_days;
                                        if rev_code = 657 then tot_657 = tot_657 + rev_days;
                                        end;
run;

data total_rev_centers;
        set hospice_base11(keep = bene_id tot_650 tot_651 tot_652 tot_655 tot_656 tot_657);
                by bene_id;
                if last.bene_id;
run;
*/
/**************************************************************/
/**************************************************************/
/***********************ICD 9 CODE*****************************/
/**************************************************************/
/**************************************************************/

/*just keep first 5 diagnosis codes for the first claim for a hospice stay*/
proc sort data=hospice_base10 out=icd; by bene_id start; run;
data ICD1;
        set icd (keep = bene_id PRNCPAL_DGNS_CD start ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 ICD_DGNS_CD5);
                by bene_id start;
                        if first.start;
run;
data icd_final;
        set icd1;
                primary_icd = PRNCPAL_DGNS_CD;
                icd_1 = ICD_DGNS_CD1;
                icd_2 = ICD_DGNS_CD2;
                icd_3 = ICD_DGNS_CD3;
                icd_4 = ICD_DGNS_CD4;
                icd_5 = ICD_DGNS_CD5;
                drop ICD_DGNS_CD1 ICD_DGNS_CD2 ICD_DGNS_CD3 ICD_DGNS_CD4 ICD_DGNS_CD5 PRNCPAL_DGNS_CD;
run;


/**************************************************************/
/**************************************************************/
/***********************Provider Code**************************/
/**************************************************************/
/**************************************************************/

proc sort data=hospice_base10 out=provider; by bene_id start; run;
proc freq data=hospice_base;
	table PRVDR_NUM / out=providers;
run;	
data providers1;
set providers;
pos1 = PRVDR_NUM + 0;
x = substr(PRVDR_NUM, 3,2);
run;
proc freq data=providers1;
table x;
run;
/*I think this in itself shows that all of the Provider IDs are 
in fact Hospice IDs. Not Hospital IDs. */

/*All Hospices from the Survey*/
data survey_indic;
set ccw.hsurvey_total (keep = pos1);
i = 1;
run;
data hospice_base_test;
set hospice_base;
pos1 = PRVDR_NUM + 0;
run;
proc sql;
create table hospice_base_test1
as select a.*, b.i
from hospice_base_test a
left join survey_indic b
on a.pos1 = b.pos1;
quit;
proc sort data=hospice_base_test1;
by bene_id CLM_FROM_DT;
run;

data hospice_base_test2;
set hospice_base_test1;
by bene_id CLM_FROM_DT;
retain surveyed;
if first.bene_id then do;
if i = 1 then surveyed = 1;
if i = . then surveyed = 0;
end;
if i = 1 then surveyed = 1;
run;
proc freq data=hospice_base_test2;
table surveyed;
run;
data hospice_base_test3;
set hospice_base_test2;
by bene_id;
if i = . then delete;
run;
proc sort data=hospice_base_test3;
by bene_id descending CLM_FROM_DT;
run;
proc sort data=hospice_base_test3 out=hospice_base_test4 nodupkey;
by bene_id pos1;
run;
proc transpose data=hospice_base_test4 prefix=provider out=provider_id;
by bene_id;
var pos1;
run;
data provider_id1;
set provider_id;
provider = provider1;
drop provider1-provider4 _name_;
run;
data ccw.providers1;
set provider_id1;
run;

/*************************************************************/
/*************************************************************/
/*********************Discharge Codes*************************/
/*************************************************************/
/*************************************************************/

/*create indicator for change in discharge code for claims that span
a continuous hospice stay*/
data discharge;
        set hospice_base10 (keep = bene_id start PTNT_DSCHRG_STUS_CD j);
                by bene_id start;
                retain i;
                        discharge_num = PTNT_DSCHRG_STUS_CD + 0;
                        discharge_diff = discharge_num - lag(discharge_num);
                        if first.start then do;
                        i = 1;
                        discharge_diff = 0;
                        end;
                        if last.start then do;
                        discharge = PTNT_DSCHRG_STUS_CD + 0;
                        end;
                        if discharge_diff ~=0 then i = i + 1;
                        drop PTNT_DSCHRG_STUS_CD;
                        discharge_i= i;
run;
/*just keep discharge code for last claim and assign it to the whole stay*/
data discharge1;
        set discharge;
        if j = 1;
        drop discharge_num discharge_diff i j;
run;


/**********************************************************************************/
/* Bring in overall stay details */
/**********************************************************************************/

/*First - create dataset that is a list of stays, not claims */
data hospice_base11;
set hospice_base10;
if j=1;
drop CLM_ID  CLM_FROM_DT CLM_THRU_DT NCH_WKLY_PROC_DT FI_CLM_PROC_DT CLM_FREQ_CD
                 CLM_MDCR_NON_PMT_RSN_CD CLM_PMT_AMT NCH_PRMRY_PYR_CLM_PD_AMT NCH_PRMRY_PYR_CD   
                PTNT_DSCHRG_STUS_CD CLM_TOT_CHRG_AMT NCH_PTNT_STATUS_IND_CD CLM_UTLZTN_DAY_CNT NCH_BENE_DSCHRG_DT PRNCPAL_DGNS_CD PRNCPAL_DGNS_VRSN_CD
                ICD_DGNS_CD1-ICD_DGNS_CD25 ICD_DGNS_VRSN_CD1-ICD_DGNS_VRSN_CD25 CLM_HOSPC_START_DT_ID BENE_HOSPC_PRD_CNT  CLM_LINE_NUM REV_CNTR REV_CNTR_DT 
                 REV_CNTR_UNIT_CNT REV_CNTR_RATE_AMT REV_CNTR_PRVDR_PMT_AMT REV_CNTR_BENE_PMT_AMT REV_CNTR_PMT_AMT_AMT REV_CNTR_TOT_CHRG_AMT REV_CNTR_NCVRD_CHRG_AMT REV_CNTR_DDCTBL_COINSRNC_CD
                REV_CNTR_NDC_QTY REV_CNTR_NDC_QTY_QLFR_CD 
                FST_DGNS_E_CD FST_DGNS_E_VRSN_CD ICD_DGNS_E_CD1-ICD_DGNS_E_CD12 ICD_DGNS_E_VRSN_CD1-ICD_DGNS_E_VRSN_CD12; 
run;

/*bring in discharge destination code to base hospice stays dataset
this hospice base dataset still has multiple lines per stay based on claims*/
proc sql;
        create table hospice_base12a
        as select a.*,b.discharge,b.discharge_i
        from hospice_base11 a
        left join discharge1 b
        on a.bene_id = b.bene_id and a.start = b.start;
quit;

/*bring in the provider id and count to  base hospice dataset*/
/*proc sql;
        create table hospice_base12b
        as select a.*,b.provider,b.provider_i
        from hospice_base12a a
        left join provider3 b
        on a.bene_id = b.bene_id and a.start= b.start;
quit;*/

/*bring in first 5 diagnoses for each stay*/
proc sql;
        create table hospice_base12c
        as select *
        from hospice_base12a a
        left join icd_final b
        on a.bene_id = b.bene_id and a.start=b.start;
quit;

/********************************************************************************/
/********************************************************************************/
/* Restructure dataset so one observation per bene id, with details
on each claim as separate variables    */
/********************************************************************************/
/********************************************************************************/
/*create count variable of each stay by bene id*/
data hospice_base13; set hospice_base12c;
        by bene_id;
        if first.bene_id then indic3 = 1;
        else indic3 + 1;
        drop indic2 indic;
run; 

proc freq data=hospice_base13;
        table indic3;
run;

/*get table of count of stays for each beneficary id*/
proc sort data=hospice_base13 out=hs_stay_ct1;
by bene_id indic3;
run;

data hs_stay_ct2;
set hs_stay_ct1;
by bene_id;
if last.bene_id then k=1;
keep bene_id indic3 k;
run;

data hs_stay_ct3;
set hs_stay_ct2(rename=(indic3=count_hs_stays));
if k=1;
drop k;
run;

proc freq data=hs_stay_ct3;
table count_hs_stays;
run;

/*add los variable for individual stays*/
data hospice_base13a;
set hospice_base13;
stay_los=end-start;
if stay_los=0 then stay_los=1;
run;

proc freq;
table stay_los;
run;

/*macro to create set of variables for each hospice stay, up to max of 21 stays
keep detailed information for first 3 stays, then limited information for any
remaining stays
Resulting dataset = macro1
Has 1 row per beneficiary ID with details on multiple hospice stays*/
option nospool;
%macro test;
        %do j = 1 %to 21;
                data macro&j;
                set hospice_base13a;
                        if indic3 = &j;
                run;
                %if &j >= 1 and &j < 4 %then %do;
                        option nospool;
                        data macro1_&j;
                                set macro&j (keep = BENE_ID start end stay_los totalcost discharge discharge_i primary_icd icd_1 icd_2 icd_3 icd_4 icd_5);
                        run;
						%if &j ~=1 %then %do;
                        proc datasets nolist;
                                delete macro&j;
                        run;
						%end;
                        data macro2_&j;
                                set macro1_&j;
                                        start&j = start;
                                        end&j = end;
										stay_los&j = stay_los;
                                        totalcost&j = totalcost;
                                        discharge&j = discharge;
                                        discharge_i_&j = discharge_i;
                                        primary_icd&j = primary_icd;
                                        icd_1_&j = icd_1;
                                        icd_2_&j = icd_2;
                                        icd_3_&j = icd_3;
                                        icd_4_&j = icd_4;
                                        icd_5_&j = icd_5;
                                        label start&j = "Start Date (Stay &j)";
                                        label end&j = "End Date (Stay &j)";
										label stay_los&j = "Length of Stay (Stay &j)";
                                        label totalcost&j = "Total Cost Spent (Stay &j)";
                                        label discharge&j = "Discharge Code (Stay &j)";
                                        label discharge_i_&j = "If Greater than 1, Discharge Codes changes with Stay (Stay &j)";
                                        label primary_icd&j = "Primary Diagnosis Code (Stay &j)";
                                        label icd_1_&j = "Diagnosis Code I (Stay &j)";
                                        label icd_2_&j = "Diagnosis Code II (Stay &j)";
                                        label icd_3_&j = "Diagnosis Code III (Stay &j)";
                                        label icd_4_&j = "Diagnosis Code IV (Stay &j)";
                                        label icd_5_&j = "Diagnosis Code V (Stay &j)";
                                        format start&j date9. end&j date9.;
                        run;
                        proc datasets nolist;
                                delete macro1_&j;
                        run;        
                        data macro3_&j;
                                set macro2_&j (keep = BENE_ID start&j end&j stay_los&j totalcost&j discharge&j primary_icd&j discharge_i_&j icd_1_&j icd_2_&j icd_3_&j icd_4_&j icd_5_&j);
                        run;
                        proc datasets nolist;
                                delete macro2_&j;
                        run;
                                         
                %end;
                %if &j >= 4 %then %do;
                        option nospool;
                        data macro1_&j;
                                set macro&j (keep = BENE_ID start end stay_los totalcost discharge);
                        run;
                        proc datasets nolist;
                                delete macro&j;
                        run;
                        data macro2_&j;
                                set macro1_&j;
                                        start&j = start;
                                        end&j = end;
										stay_los&j = stay_los;
                                        totalcost&j = totalcost;
                                        discharge&j = discharge;
                                        label start&j = "Start Date (Stay &j)";
                                        label end&j = "End Date (Stay &j)";
										label stay_los&j = "Length of Stay (Stay &j)";
                                        label totalcost&j = "Total Cost Spent (Stay &j)";
                                        label discharge&j = "Discharge Code (Stay &j)";
                                        format start&j date9. end&j date9.;
                        run;
                        proc datasets nolist;
                                delete macro1_&j;
                        run;        
                        data macro3_&j;
                                set macro2_&j (keep = BENE_ID start&j end&j stay_los&j totalcost&j discharge&j);
                        run;
                        proc datasets nolist;
                                delete macro2_&j;
                        run;
                        %end;

                        proc sql;
                        create table macro1
                         as select *
                         from macro1 a
                                  left join macro3_&j b
                                          on a.bene_id = b.bene_id;
                        quit;
                        proc datasets nolist;
                                delete macro3_&j;
                        run;
                        quit;
        %end;
%mend;
%test;        

proc contents data=macro1 varnum;
run;
proc sort data=macro1 out=macro2;
        by bene_id;
run;
proc sort data = Total_rev_center;
        by bene_id;
run;
proc sort data = provider_id;
		by bene_id;
run;		

/*bring in total revenue center days by type for each beneficiary*/
proc sql;
        create table macro3
        as select *
        from macro2 a
        left join total_rev_center b
        on a.bene_id = b.bene_id;
quit;
proc sql;
		create table macro3a
		as select *
		from macro3 a
		left join provider_id1 b
		on a.bene_id = b.bene_id;
quit;

/*bring in count of hospice stays for each beneficiary*/
proc sort data=macro3a;
by bene_id;
run;
proc sort data=hs_stay_ct3;
by bene_id;
run;

proc sql;
create table macro3b
as select a.*,b.count_hs_stays
from macro3a a
left join hs_stay_ct3 b
on a.bene_id = b.bene_id;
quit; 

/*cleans up final dataset by dropping unneeded variables*/
data macro4;
        set macro3b;
        drop NCH_NEAR_LINE_REC_IDENT_CD NCH_CLM_TYPE_CD FI_NUM PRVDR_STATE_CD AT_PHYSN_UPIN AT_PHYSN_NPI
          CLM_MDCL_REC daydiff j indic3 PRVDR_NUM ;
                label start = "Start Date (Stay 1)";
                label end = "End Date (Stay 1)";
				label stay_los = "Length of Stay (Stay 1)";
                label totalcost = "Total Cost Spent (Stay 1)";
                label provider = "Provider ID";
                label discharge = "Discharge Code (Stay 1)";
                label discharge_i = "If Greater than 1, Discharge Codes changes with Stay (Stay 1)";
                label primary_icd = "Primary Diagnosis Code (Stay 1)";
                label icd_1 = "Diagnosis Code I (Stay 1)";
                label icd_2 = "Diagnosis Code II (Stay 1)";
                label icd_3 = "Diagnosis Code III (Stay 1)";
                label icd_4 = "Diagnosis Code IV (Stay 1)";
                label icd_5 = "Diagnosis Code V (Stay 1)";
				label count_hs_stays = "Count of hospice stays";
run;
data macro5;
        retain BENE_ID CLM_FAC_TYPE_CD CLM_SRVC_CLSFCTN_TYPE_CD ORG_NPI_NUM DOB_DT GNDR_CD BENE_RACE_CD BENE_CNTY_CD BENE_STATE_CD BENE_MLG_CNTCT_ZIP_CD;
        set macro4;
        label total_650 = "Total Days in Hospice General Services";
        label total_651 = "Total Days in Routine Home Care";
        label total_652 = "Total Days in Continuous Home Care";
        label total_655 = "Total Days in Inpatient Hospice Care";
        label total_656 = "Total Days in General Inpatient Care under Hospice services (non-Respite)";
        label total_657 = "Total Number of Procedures in Hospice Physician Services";
		label total_659 = "Total Days in Hospice Services (Other)";
run;
/*create variable for total hospice length of stay*/
data total_los;
set macro5;
total_los=stay_los;
array stays stay_los2-stay_los21;
do over stays;
if stays=. then stays=0;
total_los=total_los + stays;
end;
run;

data test444;
set total_los;
if stay_los21>0;
run;

proc freq data=total_los;
table total_los;
run;
proc means data=total_los;
var total_los;
run;
proc freq data=total_los;
table discharge;
run;

/*create clean gender, age and race, ethnicity variables
These variables will be replaced using the mbs dataset, just here to look
at demographics before merge with mbs is complete*/
data clean_1;
set total_los;
/*female*/
female = .;
if gndr_cd=1 then female=0;
if gndr_cd=2 then female=1;
label female = "Female";
/*age*/
age_at_enr = floor((start - dob_dt) / 365.25);
label age_at_enr = "Age at 1st Hospice Enrollment";
/*race*/
re_white = 0;
if  bene_race_cd=1 then re_white = 1;
re_black = 0;
if bene_race_cd=2 then re_black = 1;
re_other = 0;
if bene_race_cd=3 then re_other = 1;
re_asian = 0;
if bene_race_cd=4 then re_asian = 1;
re_hispanic = 0;
if bene_race_cd=5 then re_hispanic = 1;
re_na = 0;
if bene_race_cd=6 then re_na = 1;
re_unknown = 0;
if bene_race_cd=0 then re_unknown = 1;
if bene_race_cd=. then re_unknown = 1;
label re_white = "White race / ethnicity";
label re_black = "Black race / ethnicity";
label re_other = "Other race / ethnicity";
label re_asian = "Asian race / ethnicity";
label re_hispanic = "Hispanic race / ethnicity";
label re_na = "North American Native race / ethnicity";
label re_unknown = "Unknown race / ethnicity";
run;

proc freq data=clean_1;
table bene_race_cd;
run;

/*saves final dataset*/
data ccw.hs_stays_cleaned;
        set clean_1;
		drop stay_los2-stay_los21; 
run;
ods rtf body = '\\home\users$\leee20\Documents\Downloads\Melissa\hospice.rtf';
proc contents data=ccw.hs_stays_cleaned varnum;
run;
ods rtf close;

/*Check - drops all but the one observation with 21 stays*/
data test;
        set macro5;
         if totalcost21=. then delete;
run;

/*Check to confirm one row per beneficiary id - no observations dropped*/
data unique;
	set macro5;
	by bene_id;
	if first.bene_id;
run;

/*****************************************************************/
/*Output frequency tables*/
/*****************************************************************/
ods rtf file="J:\Geriatrics\Geri\Hospice Project\output\hs_freq_tab.rtf";
proc freq data=ccw.hs_stays_cleaned;
table count_hs_stays discharge discharge_i provider_i;
run;
ods rtf close;

/*****************************************************************/
/*Convert dataset to stata to get additional summary statistics*/
/*****************************************************************/
proc export data=ccw.hs_stays_cleaned
	outfile='J:\Geriatrics\Geri\Hospice Project\Hospice\working\hs_stays_cleaned.dta'
	replace;
	run;
