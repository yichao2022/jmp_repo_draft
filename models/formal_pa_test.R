library(mlogit)
library(data.table)

# 1. Load data
dat <- fread("/Users/cary/.openclaw/workspace/telegram-inbox/tg-282523157-data2_-_Copy.csv")

# 2. Construct binary moderator
# PhysicalActivities: 0=Rare, 1=Sometimes, 2=Quite often
dat[, irregular_pa := ifelse(PhysicalActivities == 0, 1, 0)]

# Hygiene
dat$alt <- factor(dat$alt)
dat$VaccineOrigin <- factor(dat$VaccineOrigin)
dat$Choice <- as.integer(dat$Choice)

# 3. Model Formatting
mld <- mlogit.data(dat, choice = "Choice", shape = "long", 
                  chid.var = "chid", alt.var = "alt", id.var = "RespondentID")

# Base Model (No Interaction)
fml_base <- Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + 
            CashIncentives_std + VaccineOrigin + ASC_optout | 0
fit_base <- mlogit(fml_base, data = mld, rpar = c(WaitTime_std = "n"), 
                  panel = TRUE, R = 300)

# Interaction Model
fml_inter <- Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + 
             CashIncentives_std + VaccineOrigin + ASC_optout + 
             WaitTime_std:irregular_pa | 0
fit_inter <- mlogit(fml_inter, data = mld, rpar = c(WaitTime_std = "n"), 
                   panel = TRUE, R = 300)

# 4. Extract Results
cf <- coef(fit_inter)
vc <- vcov(fit_inter)

inter_name <- "WaitTime_std:irregular_pa"
beta_inter <- cf[inter_name]
se_inter <- sqrt(vc[inter_name, inter_name])
z_inter <- beta_inter / se_inter
p_inter <- 2 * (1 - pnorm(abs(z_inter)))

slope_ref <- cf["WaitTime_std"]
se_ref <- sqrt(vc["WaitTime_std", "WaitTime_std"])
slope_comp <- slope_ref + beta_inter
se_comp <- sqrt(vc["WaitTime_std", "WaitTime_std"] + 
                vc[inter_name, inter_name] + 
                2 * vc["WaitTime_std", inter_name])

res_table <- data.frame(
  Moderator = "Physical Activity (Rare vs Rest)",
  Reference_group = "Sometimes/Quite often",
  Comparison_group = "Rare (irregular_pa=1)",
  interaction_beta = round(beta_inter, 4),
  interaction_se = round(se_inter, 4),
  z_value = round(z_inter, 4),
  p_value = round(p_inter, 4),
  ref_slope = round(slope_ref, 4),
  comp_slope = round(slope_comp, 4),
  ref_lwr = round(slope_ref - 1.96*se_ref, 4),
  ref_upr = round(slope_ref + 1.96*se_ref, 4),
  comp_lwr = round(slope_comp - 1.96*se_comp, 4),
  comp_upr = round(slope_comp + 1.96*se_comp, 4)
)

# 5. Likelihood Ratio Test
lrt <- lrtest(fit_base, fit_inter)

# Write outputs to files for safe retrieval
write.csv(res_table, "final_pa_table.csv", row.names = FALSE)
capture.output(print(lrt), file = "final_pa_lrt.txt")
