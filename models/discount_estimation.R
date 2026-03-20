# Discount Rate Estimation and Comparison (JMP)

# This script replicates the estimation of structural discount parameters (Hyperbolic vs Exponential)
# for the paper: "How Waiting Time Shapes Preventive Health Behavior".
# 
# Author: Yichao Jin
# Date: 2026-03-17

library(ggplot2)

# 1. Observed Data (from DCE findings)
# t: delay in months
# D_obs: observed discount factor normalized to D(0)=1
t     <- c(0, 1, 3, 6)
D_obs <- c(1.00, 0.82, 0.61, 0.46)

# 2. Hyperbolic Model: D(t) = 1 / (1 + Kt)
# SSE function with log-reparameterization to enforce K > 0
SSE_logK <- function(logK) {
  K <- exp(logK)
  sum((D_obs - 1 / (1 + K * t))^2)
}

fit_hyp <- optim(log(0.1), SSE_logK, method = "Nelder-Mead",
                 control = list(maxit = 5000, reltol = 1e-12))
K_hat <- exp(fit_hyp$par)
rmse_h <- sqrt(fit_hyp$value / length(t))
t_half_h <- 1 / K_hat # "Half-value" time

# 3. Exponential Model: D(t) = exp(-rt)
# Using L-BFGS-B to enforce r >= 0
SSE_r <- function(r) {
  sum((D_obs - exp(-r * t))^2)
}

fit_exp <- optim(0.1, SSE_r, method = "L-BFGS-B", lower = 0)
r_hat <- fit_exp$par
rmse_e <- sqrt(fit_exp$value / length(t))
t_half_e <- log(2) / r_hat

# 4. Results Reporting
cat("--- Model Comparison Results ---\n")
cat(sprintf("Hyperbolic (K): %0.3f, RMSE: %0.3f, Half-life: %0.2f months\n", K_hat, rmse_h, t_half_h))
cat(sprintf("Exponential (r): %0.3f, RMSE: %0.3f, Half-life: %0.2f months\n", r_hat, rmse_e, t_half_e))

if (rmse_h < rmse_e) {
  cat("Result: Hyperbolic model provides a better fit (lower RMSE).\n")
} else {
  cat("Result: Exponential model provides a better fit.\n")
}

# 5. Visualization
t_grid <- seq(min(t), max(t), length.out = 200)
df_plot <- rbind(
  data.frame(t = t, D = D_obs, model = "Observed"),
  data.frame(t = t_grid, D = 1 / (1 + K_hat * t_grid), model = "Hyperbolic"),
  data.frame(t = t_grid, D = exp(-r_hat * t_grid), model = "Exponential")
)

plot_discounting <- ggplot() +
  geom_point(data = subset(df_plot, model == "Observed"), aes(t, D), size = 3, color = "black") +
  geom_line(data = subset(df_plot, model == "Hyperbolic"), aes(t, D, linetype = model), linewidth = 1) +
  geom_line(data = subset(df_plot, model == "Exponential"), aes(t, D, linetype = model), linewidth = 1) +
  scale_linetype_manual(values = c("Hyperbolic" = "solid", "Exponential" = "dashed")) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    x = "Delay (months)", 
    y = "Discount factor",
    title = "Structural Parameter Recovery: Hyperbolic vs. Exponential",
    subtitle = sprintf("Hyperbolic RMSE: %0.3f | Exponential RMSE: %0.3f", rmse_h, rmse_e)
  ) +
  theme_bw() +
  theme(legend.title = element_blank(), legend.position = "bottom")

# Save results
# ggsave("plots/discounting_fit.png", plot_discounting, width = 7, height = 5)
print("Analysis complete. Model script formatted for replication.")
