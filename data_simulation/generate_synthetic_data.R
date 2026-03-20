# Synthetic Data Generation for DCE JMP Repo

# This script generates a synthetic dataset that mirrors the statistical 
# properties of the original survey data (WaitTime sensitivity, 
# Urban/Rural interaction, etc.) for replication purposes.

set.seed(2026)
n_respondents <- 500
n_choicesets <- 6
n_alts <- 3

# Expand grid to create long format data
total_rows <- n_respondents * n_choicesets * n_alts
df <- data.frame(
  RespondentID = rep(1:n_respondents, each = n_choicesets * n_alts),
  ChoiceSet = rep(rep(1:n_choicesets, each = n_alts), n_respondents),
  Alt = rep(c("A", "B", "C"), n_respondents * n_choicesets)
)

# 1. Respondent Characteristics (Mirrors original distribution)
urban_prob <- 0.65
trust_mean <- 3.5 # 1-5 scale

df$UrbanRural <- rep(rbinom(n_respondents, 1, urban_prob), each = n_choicesets * n_alts)
df$Trust <- rep(round(rnorm(n_respondents, trust_mean, 1)), each = n_choicesets * n_alts)
df$Trust <- pmax(1, pmin(5, df$Trust)) # Clamp to 1-5

# 2. Attribute Generation (The Experimental Design)
df$WaitTime <- ifelse(df$Alt == "C", 0, sample(c(1, 2, 3, 6), total_rows, replace = TRUE))
df$VaccineOrigin <- ifelse(df$Alt == "C", 0, rbinom(total_rows, 1, 0.5)) # 0: Domestic, 1: Imported
df$Efficacy <- ifelse(df$Alt == "C", 0, sample(c(0.5, 0.7, 0.9, 0.95), total_rows, replace = TRUE))

# Define helper for Gumbel noise (standard GEV with shape=0)
rgev <- function(n) { -log(-log(runif(n))) }

# 3. Simulate Choices based on estimated coefficients
# Utility = b1*WaitTime + b2*WaitTime*Urban + b3*WaitTime*LowTrust + ...
b_wait <- -0.3
b_urban_interaction <- -0.1
b_trust_interaction <- 0.05
b_efficacy <- 2.0
b_asc_optout <- -1.5

# Calculate latent utility
df$utility <- b_wait * df$WaitTime + 
              b_urban_interaction * df$WaitTime * df$UrbanRural +
              b_trust_interaction * df$WaitTime * df$Trust +
              b_efficacy * df$Efficacy +
              ifelse(df$Alt == "C", b_asc_optout, 0) +
              rgev(total_rows) # Standard Gumbel error for Logit

# Determine Choice (Simple multinomial logit simulation)
# For each RespondentID-ChoiceSet, pick the one with max utility
df$Choice <- 0
for (i in seq(1, total_rows, by = n_alts)) {
  indices <- i:(i + n_alts - 1)
  df$Choice[indices[which.max(df$utility[indices])]] <- 1
}

# Clean up and export
df_final <- df[, c("RespondentID", "ChoiceSet", "Alt", "WaitTime", "UrbanRural", "Trust", "VaccineOrigin", "Efficacy", "Choice")]
write.csv(df_final, "jmp_repo_draft/data_simulation/synthetic_dce_data.csv", row.names = FALSE)

cat("Synthetic dataset created: jmp_repo_draft/data_simulation/synthetic_dce_data.csv\n")
