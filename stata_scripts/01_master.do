* Master Execution Script
* Project: Vaccination Timing DCE
* Author: Yichao Jin

clear all
do "stata_scripts/02_cleaning.do"
do "stata_scripts/03_mixed_logit.do"
do "stata_scripts/04_plots.do"
