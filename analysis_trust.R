# Trust Analysis for Vaccination DCE
library(mlogit)
library(ggplot2)
library(data.table)

# 1. Load data
data <- fread("telegram-inbox/tg-282523157-data2_-_Copy.csv")

# 2. Recode trust variable
# GoverTrust: -2 to 2, "Prefer not to say"
# low_trust = {-2, -1}
# high_trust = {1, 2}
# exclude 0 (neutral) and "Prefer not to say"

data[, trust_group := as.character(NA)]
data[GoverTrust %in% c("-2", "-1"), trust_group := "Low trust"]
data[GoverTrust %in% c("1", "2"), trust_group := "High trust"]

# Keep original as numeric for robustness check
data[, GoverTrust_num := as.numeric(as.character(GoverTrust))] # "Prefer not to say" becomes NA

# 3. Data Prep for mlogit
# Types & Checks
if (!is.factor(data$alt)) data$alt <- factor(data$alt, levels = c("A","B","C"))
data$alt <- stats::relevel(data$alt, ref = "A")
if (!is.factor(data$VaccineOrigin)) data$VaccineOrigin <- factor(data$VaccineOrigin)
if ("Domestic" %in% levels(data$VaccineOrigin)) {
  data$VaccineOrigin <- stats::relevel(data$VaccineOrigin, ref = "Domestic")
}

# Subgroup samples
subgroup_data <- data[!is.na(trust_group)]
high_trust_data <- subgroup_data[trust_group == "High trust"]
low_trust_data <- subgroup_data[trust_group == "Low trust"]

cat("Sample sizes (choices):\n")
cat("High trust:", nrow(high_trust_data), "\n")
cat("Low trust:", nrow(low_trust_data), "\n")
cat("Total in subgroup analysis:", nrow(subgroup_data), "\n")

# mlogit conversion helper
fit_model <- function(df) {
  mld <- mlogit.data(df, choice = "Choice", shape = "long", chid.var = "chid", alt.var = "alt", id.var = "RespondentID")
  mlogit(Choice ~ WaitTime_std + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout | 0, data = mld)
}

# 4. Estimation
cat("\nFitting model for High Trust group...\n")
m_high <- fit_model(high_trust_data)
cat("Fitting model for Low Trust group...\n")
m_low <- fit_model(low_trust_data)

# Interaction model
subgroup_data[, trust_is_low := as.numeric(trust_group == "Low trust")]
mld_inter <- mlogit.data(subgroup_data, choice = "Choice", shape = "long", chid.var = "chid", alt.var = "alt", id.var = "RespondentID")
cat("Fitting interaction model...\n")
m_inter <- mlogit(Choice ~ WaitTime_std + WaitTime_std:trust_is_low + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout | 0, data = mld_inter)

# 5. Extract coefficients for plot
res <- data.frame(
  Group = c("High trust", "Low trust"),
  Point = c(coef(m_high)["WaitTime_std"], coef(m_low)["WaitTime_std"]),
  SE = c(sqrt(diag(vcov(m_high)))["WaitTime_std"], sqrt(diag(vcov(m_low)))["WaitTime_std"])
)
res$CI_low <- res$Point - 1.96 * res$SE
res$CI_high <- res$Point + 1.96 * res$SE

# 6. Coefficient Plot
p <- ggplot(res, aes(x = Point, y = Group)) +
  geom_point(size = 4, color = "darkblue") +
  geom_errorbarh(aes(xmin = CI_low, xmax = CI_high), height = 0.2, color = "darkblue") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Effect of Waiting Time on Vaccine Choice by Trust Group",
       subtitle = "Point estimates with 95% Confidence Intervals",
       x = "Coefficient (Waiting Time std)",
       y = "Trust Group") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))
ggsave("trust_coefficient_plot.png", p, width = 8, height = 5)

# 7. MWTA with Confidence Intervals (Delta Method)
sd_wait <- sd(data$WaitTime, na.rm = TRUE)
sd_cash <- sd(data$CashIncentives, na.rm = TRUE)

get_mwta_stats <- function(m) {
  b <- coef(m)
  vc <- vcov(m)
  
  b_w <- b["WaitTime_std"]
  b_c <- b["CashIncentives_std"]
  
  # Point Estimate
  mwta <- - (b_w * sd_cash) / (b_c * sd_wait)
  
  # Delta Method
  # f = - (b_w * sd_cash) / (b_c * sd_wait)
  # df/db_w = - sd_cash / (b_c * sd_wait)
  # df/db_c = (b_w * sd_cash) / (b_c^2 * sd_wait)
  
  grad <- c(
    - sd_cash / (b_c * sd_wait),
    (b_w * sd_cash) / (b_c^2 * sd_wait)
  )
  names(grad) <- c("WaitTime_std", "CashIncentives_std")
  
  # Sub-matrix of vcov for the two variables
  vars <- c("WaitTime_std", "CashIncentives_std")
  v_sub <- vc[vars, vars]
  
  # Variance of MWTA
  var_mwta <- t(grad) %*% v_sub %*% grad
  se_mwta <- sqrt(as.numeric(var_mwta))
  
  data.frame(
    MWTA = mwta,
    SE = se_mwta,
    CI_low = mwta - 1.96 * se_mwta,
    CI_high = mwta + 1.96 * se_mwta
  )
}

mwta_high <- get_mwta_stats(m_high)
mwta_low <- get_mwta_stats(m_low)

cat("\nMWTA Statistics (RMB per month of waiting):\n")
cat("High trust group:\n")
print(mwta_high)
cat("\nLow trust group:\n")
print(mwta_low)

# 8. Robustness check: Interaction with full scale
data_rob <- data[!is.na(GoverTrust_num)]
mld_rob <- mlogit.data(data_rob, choice = "Choice", shape = "long", chid.var = "chid", alt.var = "alt", id.var = "RespondentID")
cat("Fitting robustness model (full scale interaction)...\n")
m_rob <- mlogit(Choice ~ WaitTime_std + WaitTime_std:GoverTrust_num + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout | 0, data = mld_rob)

cat("\nRobustness Check (Interaction with full GoverTrust scale):\n")
print(summary(m_rob)$CoefTable["WaitTime_std:GoverTrust_num",])

# Summary of results
cat("\nMain Interaction Effect (WaitTime_std : trust_is_low):\n")
print(summary(m_inter)$CoefTable["WaitTime_std:trust_is_low",])

# Output tables
write.csv(res, "trust_analysis_results.csv", row.names = FALSE)
cat("\nAnalysis complete. Results saved to trust_analysis_results.csv and trust_coefficient_plot.png\n")
