library(mlogit)
library(dplyr)
library(knitr)
library(kableExtra)

# 1. Load data
data_path <- "/Users/cary/.openclaw/workspace/telegram-inbox/tg-282523157-data2_-_Copy.csv"
raw_data <- read.csv(data_path, stringsAsFactors=FALSE)

# 2. Pre-process Moderators
raw_data <- raw_data %>%
  mutate(
    # low_trust: -2, -1, 0 -> 1 (low); 1, 2 -> 0 (high)
    low_trust = case_when(
      GoverTrust %in% c("-2", "-1", "0") ~ 1,
      GoverTrust %in% c("1", "2") ~ 0,
      TRUE ~ NA_real_
    ),
    # chronic_yes: 1 -> 1 (Yes); 0 -> 0 (No)
    chronic_yes = case_when(
      MedicalConditions == "1" ~ 1,
      MedicalConditions == "0" ~ 0,
      TRUE ~ NA_real_
    ),
    # irregular_pa: Assuming 0=Rare -> 1; 1, 2=Sometimes/Quite often -> 0
    irregular_pa = case_when(
      PhysicalActivities == "0" ~ 1,
      PhysicalActivities %in% c("1", "2") ~ 0,
      TRUE ~ NA_real_
    ),
    # smoker_any: 1, 2 -> 1 (Sometimes/Often); 0 -> 0 (Never)
    smoker_any = case_when(
      SmokingStatus %in% c("1", "2") ~ 1,
      SmokingStatus == "0" ~ 0,
      TRUE ~ NA_real_
    )
  )

# If any row has NA in the moderators, mlogit might drop it entirely, reducing sample size.
# Since we have "Prefer not to say" in GoverTrust/MedicalConditions, we should just let mlogit handle NAs 
# or impute them to 0 if we don't want to lose the whole panel? Wait, mlogit drops NAs listwise. 
# The prompt asks to "construct these 4 binary moderators". NA handling is implicit (they get dropped).
# Wait, if we drop NAs, we lose those respondents entirely.
# Let's fill NAs with 0 (reference group) or keep as NA. Keeping as NA is statistically safer.
# Let's keep as NA, mlogit will drop NAs automatically.

# 3. Prepare mlogit data
# The idx argument structure for panel data in long format: list(c(choice_set_id, individual_id), alternative_id)
df_mlogit <- dfidx(raw_data, 
                   idx = list(c("chid", "RespondentID"), "alt"), 
                   choice = "Choice", 
                   shape = "long")

# 4. Run Mixed Logit Model
model_formula <- as.formula("Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout + WaitTime_std:low_trust + WaitTime_std:chronic_yes + WaitTime_std:irregular_pa + WaitTime_std:smoker_any | 0")

mod <- mlogit(model_formula, 
              data = df_mlogit, 
              rpar = c(WaitTime_std = "n"), 
              panel = TRUE, 
              R = 300, 
              halton = NA)

# 5. Extract Results and Build Table
sum_mod <- summary(mod)
coefs <- sum_mod$CoefTable

get_interaction_row <- function(mod_name, ref_group, comp_group, interaction_term) {
  # Estimate slopes
  beta_main <- coefs["WaitTime_std", "Estimate"]
  se_main <- coefs["WaitTime_std", "Std. Error"]
  
  beta_inter <- coefs[interaction_term, "Estimate"]
  se_inter <- coefs[interaction_term, "Std. Error"]
  z_inter <- coefs[interaction_term, "z-value"]
  p_inter <- coefs[interaction_term, "Pr(>|z|)"]
  
  # Covariance matrix for SE computation
  cov_mat <- vcov(mod)
  var_main <- cov_mat["WaitTime_std", "WaitTime_std"]
  var_inter <- cov_mat[interaction_term, interaction_term]
  cov_main_inter <- cov_mat["WaitTime_std", interaction_term]
  
  # Composite comparison group slope
  comp_slope <- beta_main + beta_inter
  comp_se <- sqrt(max(0, var_main + var_inter + 2 * cov_main_inter))
  
  # Return data frame row
  data.frame(
    Moderator = mod_name,
    Reference_group = ref_group,
    Comparison_group = comp_group,
    interaction_beta = beta_inter,
    interaction_se = se_inter,
    z_value = z_inter,
    p_value = p_inter,
    ref_slope = beta_main,
    comp_slope = comp_slope,
    ref_lwr = beta_main - 1.96 * se_main,
    ref_upr = beta_main + 1.96 * se_main,
    comp_lwr = comp_slope - 1.96 * comp_se,
    comp_upr = comp_slope + 1.96 * comp_se
  )
}

table_rows <- list(
  get_interaction_row("Trust", "High Trust", "Low Trust", "WaitTime_std:low_trust"),
  get_interaction_row("Chronic Disease", "No", "Yes", "WaitTime_std:chronic_yes"),
  get_interaction_row("Physical Activity", "Regular", "Rare", "WaitTime_std:irregular_pa"),
  get_interaction_row("Smoking", "Never", "Sometimes/Often", "WaitTime_std:smoker_any")
)

full_table <- bind_rows(table_rows)

# Clean up decimal places for easier reading
full_table_rounded <- full_table %>%
  mutate(across(where(is.numeric), ~ round(., 4)))

# 6. Save Outputs
write.csv(full_table_rounded, "interaction_test_table_full.csv", row.names = FALSE)
write.csv(as.data.frame(coefs), "interaction_model_coefficients.csv")
saveRDS(mod, "mod_interact.rds")

# HTML Output
html_content <- kable(full_table_rounded, "html") %>% kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
writeLines(as.character(html_content), "interaction_test_table_full.html")

print(full_table_rounded)
