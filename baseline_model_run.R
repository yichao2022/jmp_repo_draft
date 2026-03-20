
library(mlogit)
library(dplyr)
library(texreg)

# 1. Load and Prepare Data
raw_data <- read.csv("/Users/cary/.openclaw/workspace/telegram-inbox/tg-282523157-data2_-_Copy.csv")

# Use full analytic sample (1,027 respondents)
df <- raw_data

# Standardization
# Reuse logic from refine_wait_time_main.R
mean_wait <- mean(df$WaitTime, na.rm = TRUE)
sd_wait <- sd(df$WaitTime, na.rm = TRUE)
df$WaitTime_std <- (df$WaitTime - mean_wait) / sd_wait
df$CashIncentives_std <- (df$CashIncentives - mean(df$CashIncentives, na.rm = TRUE)) / sd(df$CashIncentives, na.rm = TRUE)
df$VaccineEfficacy_std <- (df$VaccineEfficacy - mean(df$VaccineEfficacy, na.rm = TRUE)) / sd(df$VaccineEfficacy, na.rm = TRUE)
df$SideEffects_std <- (df$SideEffects - mean(df$SideEffects, na.rm = TRUE)) / sd(df$SideEffects, na.rm = TRUE)

# Other controls (Attributes)
# VaccineOrigin might be a factor
df$VaccineOrigin <- as.factor(df$VaccineOrigin)

# Individual controls
# Convert relevant columns to factors for MNL
df$Age <- as.factor(df$Age)
df$Gender <- as.factor(df$Gender)
df$Education <- as.factor(df$Education)
df$UrbanRural <- as.factor(df$UrbanRural)
df$MedicalConditions <- as.factor(df$MedicalConditions)

# Create dfidx
# idx = list(c(Unique Choice ID, Individual ID), Alternative ID)
df_mlogit <- dfidx(df, choice = "Choice", shape = "long", alt.var = "Alt", idx = list(c("chid", "RespondentID"), "Alt"))

# Model Specifications
# All models include ASC for alternatives relative to C? 
# Or just for C?
# Let's use | 1 for ASCs for A and B.

# Model 1: Conditional Logit (Attributes + ASC)
model1 <- mlogit(Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin | 1, data = df_mlogit)

# Model 2: Multinomial Logit (Attributes + ASC + Individual Controls)
# Only attributes vary by alternative. ASC and individual controls vary by individual (but influence probability of A, B vs C).
model2 <- mlogit(Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin | 
                  Age + Gender + Education + UrbanRural + MedicalConditions, 
                data = df_mlogit)

# Model 3: Mixed Logit (Attributes with random parameters + ASC)
# We use Model 1 as starting point, add random parameters for attributes.
# panel = TRUE accounts for multiple choices per person.
model3 <- mlogit(Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin | 1, 
                data = df_mlogit, 
                rpar = c(WaitTime_std = "n", VaccineEfficacy_std = "n", SideEffects_std = "n", CashIncentives_std = "n"),
                panel = TRUE, 
                R = 50, # Number of draws for Halton sequence (low for speed, maybe increase to 100)
                halton = NA)

# Formatting Table
# Use texreg to get results
tr1 <- model1
tr2 <- model2
tr3 <- model3

# Summary stats
n_indiv <- length(unique(df$RespondentID))
n_obs <- nrow(df) / 3 # Choice situations

cat("\nSummary Stats:\n")
cat("Individuals:", n_indiv, "\n")
cat("Total Choice Situations:", n_obs, "\n")

# Print table in text format
screenreg(list(tr1, tr2, tr3), custom.model.names = c("Cond. Logit", "MNL", "Mixed Logit"))

# Save to file
sink("baseline_model_results.txt")
cat("Individuals:", n_indiv, "\n")
cat("Total Choice Situations:", n_obs, "\n\n")
screenreg(list(tr1, tr2, tr3), custom.model.names = c("Cond. Logit", "MNL", "Mixed Logit"))
sink()
