library(mlogit)
library(data.table)

# --- 0) Load Data (Assumes data2_Copy exists in environment, but since this is a new script, we use the saved path)
# In this environment, we'll assume the user has the data ready as 'data2_Copy' 
# or we read it if we had a dump. Since I can't access the live R environment, 
# I will provide a script that the user can run.

# --- 1) Data Prep Helper
# (WaitTime_std should already be in the data based on previous files)

run_interaction <- function(df, grouping_var) {
  cat("\n--- Running Interaction: WaitTime_std x", grouping_var, "---\n")
  
  # Ensure the grouping var is a factor and find levels
  df[[grouping_var]] <- as.factor(df[[grouping_var]])
  lvls <- levels(df[[grouping_var]])
  ref_lvl <- lvls[1]
  other_lvls <- lvls[-1]
  
  # Create interaction terms for non-reference levels
  formula_str <- "Choice ~ WaitTime_std"
  for (l in other_lvls) {
    clean_l <- gsub("[^A-Za-z0-9]+", "_", l)
    v_name <- paste0("WT_x_", grouping_var, "_", clean_l)
    df[[v_name]] <- df$WaitTime_std * as.numeric(df[[grouping_var]] == l)
    formula_str <- paste0(formula_str, " + ", v_name)
  }
  
  # Add other attributes
  formula_str <- paste0(formula_str, " + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout | 0")
  
  # Format data for mlogit
  mld <- mlogit.data(df, choice = "Choice", shape = "long", 
                     chid.var = "chid", alt.var = "alt", id.var = "RespondentID")
  
  # Fit Model
  fit <- mlogit(as.formula(formula_str), data = mld)
  
  # Extract results for interactions
  sum_fit <- summary(fit)
  coefs <- sum_fit$CoefTable
  
  results <- list()
  for (l in other_lvls) {
    clean_l <- gsub("[^A-Za-z0-9]+", "_", l)
    term_name <- paste0("WT_x_", grouping_var, "_", clean_l)
    
    results[[l]] <- data.frame(
      Group_Variable = grouping_var,
      Comparison = paste0(l, " vs ", ref_lvl),
      Interaction_Effect = coefs[term_name, "Estimate"],
      Std_Error = coefs[term_name, "Std. Error"],
      z_value = coefs[term_name, "z-value"],
      p_value = coefs[term_name, "Pr(>|z|)"],
      Significance = ifelse(coefs[term_name, "Pr(>|z|)"] < 0.01, "***",
                     ifelse(coefs[term_name, "Pr(>|z|)"] < 0.05, "**",
                     ifelse(coefs[term_name, "Pr(>|z|)"] < 0.1, "*", "")))
    )
  }
  return(do.call(rbind, results))
}

# --- 2) Main Execution
# We use data2_Copy which is the user's primary dataframe
target_data <- data2_Copy

# Cleanup data2_Copy logic for specific variables if needed
target_data$Gender <- factor(target_data$Gender)
target_data$UrbanRural <- factor(target_data$UrbanRural)
target_data$Education <- factor(target_data$Education)

# List of tests to run
test_vars <- c("Gender", "UrbanRural", "Education")

final_results <- list()
for (v in test_vars) {
  tryCatch({
    final_results[[v]] <- run_interaction(target_data, v)
  }, error = function(e) {
    cat("Error in", v, ":", e$message, "\n")
  })
}

# --- 3) Summary Table
interaction_summary_table <- do.call(rbind, final_results)
rownames(interaction_summary_table) <- NULL

print(interaction_summary_table)

# Save results
write.csv(interaction_summary_table, "interaction_test_summary.csv", row.names = FALSE)
cat("\n✔ Interaction summary table saved to: interaction_test_summary.csv\n")
