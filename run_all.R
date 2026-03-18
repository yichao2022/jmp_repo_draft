library(mlogit)
library(data.table)

# --- 1) Load Raw Data
# 找到原始处理脚本并加载数据。根据之前的记录，数据通常在 data2_Copy 中。
# 这里假设用户提供的数据在本地某个 RData 或 csv 中，或者我们需要 source 昨天的脚本来生成环境。
# 既然我没有 .RData，我尝试寻找 CSV。
if (file.exists("data2_Copy.csv")) {
    data2_Copy <- fread("data2_Copy.csv")
} else {
    # 如果没有 CSV，尝试从之前的代码逻辑中恢复
    # 这一步在后台运行比较受限，因为我无法直接获取用户 RStudio 内存中的对象
    stop("找不到 data2_Copy 数据对象。请确保已将数据保存为 data2_Copy.csv 放在工作目录中。")
}

# --- 2) Interaction Logic
run_interaction_loop <- function(df, grouping_var) {
  df[[grouping_var]] <- as.factor(df[[grouping_var]])
  lvls <- levels(df[[grouping_var]])
  ref_lvl <- lvls[1]
  other_lvls <- lvls[-1]
  
  formula_str <- "Choice ~ WaitTime_std"
  for (l in other_lvls) {
    clean_l <- gsub("[^A-Za-z0-9]+", "_", l)
    v_name <- paste0("WT_x_", clean_l)
    df[[v_name]] <- df$WaitTime_std * as.numeric(df[[grouping_var]] == l)
    formula_str <- paste0(formula_str, " + ", v_name)
  }
  
  formula_str <- paste0(formula_str, " + VaccineEfficacy_std + SideEffects_std + CashIncentives_std + VaccineOrigin + ASC_optout | 0")
  
  mld <- mlogit.data(df, choice = "Choice", shape = "long", 
                     chid.var = "chid", alt.var = "alt", id.var = "RespondentID")
  
  fit <- mlogit(as.formula(formula_str), data = mld)
  coefs <- summary(fit)$CoefTable
  
  results <- lapply(other_lvls, function(l) {
    clean_l <- gsub("[^A-Za-z0-9]+", "_", l)
    term_name <- paste0("WT_x_", clean_l)
    data.frame(
      Variable = grouping_var,
      Test_Group = l,
      Ref_Group = ref_lvl,
      Interaction_Effect = coefs[term_name, "Estimate"],
      p_value = coefs[term_name, "Pr(>|z|)"],
      Significance = ifelse(coefs[term_name, "Pr(>|z|)"] < 0.01, "***",
                     ifelse(coefs[term_name, "Pr(>|z|)"] < 0.05, "**",
                     ifelse(coefs[term_name, "Pr(>|z|)"] < 0.1, "*", "")))
    )
  })
  return(do.call(rbind, results))
}

test_vars <- c("Gender", "UrbanRural", "Education")
summary_list <- list()
for (v in test_vars) {
  summary_list[[v]] <- run_interaction_loop(data2_Copy, v)
}

interaction_table <- do.call(rbind, summary_list)
print(interaction_table)
write.csv(interaction_table, "interaction_test_summary.csv", row.names = FALSE)
