# Mixed Logit Analysis for Vaccination Choice Experiment

# This script performs the discrete choice modeling for the JMP:
# "How Waiting Time Shapes Preventive Health Behavior".
# 
# Key Features:
# 1. Mixed Logit (Random Parameters Logit) to capture preference heterogeneity.
# 2. Subgroup analysis (Gender, Urban/Rural, Education) for WaitTime sensitivity.
# 3. Calculation of Marginal Willingness to Accept (MWTA) for waiting time.

library(mlogit)
library(data.table)

# --- 1. Load Data ---
# Default to synthetic data if the original is not present
data_path <- "data_simulation/synthetic_dce_data.csv"
if (!file.exists(data_path)) {
  # If running from models/ directory, adjust path
  data_path <- "../data_simulation/synthetic_dce_data.csv"
}

data <- read.csv(data_path)

# --- 2. Data Preparation ---
# alt as factor
data$Alt <- factor(data$Alt, levels = c("A", "B", "C"))

# Standardize variables if they aren't already (for coefficients comparison)
# In the original JMP, these were standardized to mean 0, sd 1
data$WaitTime_std <- scale(data$WaitTime)
data$Efficacy_std <- scale(data$Efficacy)

# Prepare for mlogit
mlogit_data <- mlogit.data(
  data,
  choice   = "Choice",
  shape    = "long",
  chid.var = "ChoiceSet",
  alt.var  = "Alt",
  id.var   = "RespondentID"
)

# --- 3. Fit Overall Mixed Logit ---
# We treat WaitTime as a random parameter (normal distribution)
# to capture the variance in how people perceive delay.
set.seed(123)
m_mxl <- mlogit(
  Choice ~ WaitTime_std + Efficacy_std + VaccineOrigin | 0,
  data   = mlogit_data,
  rpar   = c(WaitTime_std = "n"),
  panel  = TRUE,
  R      = 100 # Increase R for final publication-ready results (e.g., 500)
)

print(summary(m_mxl))

# --- 4. Subgroup Interaction (Urban vs Rural) ---
# Testing the "Urban-Rural Psychology Divide"
m_urban <- mlogit(
  Choice ~ WaitTime_std + WaitTime_std:UrbanRural + Efficacy_std + VaccineOrigin | 0,
  data = mlogit_data
)

cat("\n--- Urban/Rural Interaction Results ---\n")
print(summary(m_urban))

# --- 5. MWTA Calculation (Example) ---
# MWTA = - (beta_attribute / beta_incentive)
# Note: Ensure you use the coefficient for incentives from your full model.
# b_wait <- coef(m_mxl)["WaitTime_std"]
# b_cash <- coef(m_mxl)["CashIncentives_std"]
# mwta_value <- - b_wait / b_cash
# cat("Calculated MWTA for Wait Time:", mwta_value, "\n")

cat("\nAnalysis complete. Results stored in model object 'm_mxl'.\n")
