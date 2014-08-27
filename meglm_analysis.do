capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\meglm_stata_work-LOG.txt", text replace

cd "`datapath'"
use ltd_vars_for_analysis.dta

compress

*********************************************************
local outcomes hosp_adm_ind ip_ed_visit_ind icu_stay_ind
foreach v in `outcomes'{
tab `v', missing
}

local xvars female agecat re_white cancer cc_grp ownership1 sizecat region1
foreach v in `xvars'{
tab `v', missing
}

gen agecat2 = .
forvalues i = 1/5{
replace agecat2 = `i' if agecat=="     `i'"
}
tab agecat2, missing

local xvars2 female agecat2 re_white cancer cc_grp ownership1 sizecat region1

logit hosp_adm_ind `xvars2' ,vce(cluster pos1)

//meglm 

*********************************************************
log close