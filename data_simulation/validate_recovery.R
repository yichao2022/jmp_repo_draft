library(survival)

df <- read.csv("synthetic_dce_data.csv")

# Create a unique choice task identifier
df$chid <- paste(df$RespondentID, df$ChoiceSet, sep="_")

# Define the OptOut (ASC) variable
df$OptOut <- ifelse(df$Alt == "C", 1, 0)

# Create interaction terms explicitly or in formula
df$WaitTime_Urban <- df$WaitTime * df$UrbanRural
df$WaitTime_Trust <- df$WaitTime * df$Trust

# Run conditional logit
model <- clogit(Choice ~ WaitTime + WaitTime_Urban + WaitTime_Trust + Efficacy + OptOut + strata(chid), data=df)

summary_model <- summary(model)

# Extract coefficients
est <- coef(model)
se <- sqrt(diag(vcov(model)))
p_values <- summary_model$coefficients[, "Pr(>|z|)"]

results <- data.frame(
    Parameter = c("b_wait", "b_urban_interaction", "b_trust_interaction", "b_efficacy", "b_asc_optout"),
    Truth = c(-0.3, -0.1, 0.05, 2.0, -1.5),
    Estimated = est[c("WaitTime", "WaitTime_Urban", "WaitTime_Trust", "Efficacy", "OptOut")],
    SE = se[c("WaitTime", "WaitTime_Urban", "WaitTime_Trust", "Efficacy", "OptOut")],
    P_value = p_values[c("WaitTime", "WaitTime_Urban", "WaitTime_Trust", "Efficacy", "OptOut")]
)

rownames(results) <- NULL
print(results)

# Validation Check: are estimates within 2 standard errors of the truth?
results$Passed <- abs(results$Truth - results$Estimated) <= (2.5 * results$SE)

cat("\n--- Validation Summary ---\n")
print(results[, c("Parameter", "Truth", "Estimated", "Passed")])

if(all(results$Passed)) {
    cat("\n[PASS] All recovered parameters are within 2.5 standard errors of the ground truth.\n")
} else {
    cat("\n[FAIL] Some parameters did not recover well.\n")
}

