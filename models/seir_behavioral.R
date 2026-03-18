library(deSolve)
library(ggplot2)

# --- Parameters ---
N <- 1000000
beta <- 0.3
sigma <- 1/5.2
gamma <- 1/10

# Behavioral Parameters (Locked from JMP)
kappa <- 0.225
alpha <- 0.005

# Policy Parameters
v_cap <- 0.005
delay <- 1.0
incentive <- 0

# --- SEIR Equations ---
seir_model <- function(t, state, parameters) {
  with(as.list(c(state, parameters)), {
    # Endogenized Uptake Probability
    utility <- alpha * incentive - kappa * delay
    p_uptake <- exp(utility) / (1 + exp(utility))
    
    # Effective vaccination rate
    v_eff <- v_cap * p_uptake
    
    dS <- -beta * S * I / N - v_eff * S
    dE <- beta * S * I / N - sigma * E
    dI <- sigma * E - gamma * I
    dR <- gamma * I
    dV <- v_eff * S
    
    list(c(dS, dE, dI, dR, dV))
  })
}

# --- Initial Conditions ---
initial_state <- c(S = N - 10, E = 0, I = 10, R = 0, V = 0)
times <- seq(0, 200, by = 1)

# --- Scenario 1: Supply-only (P = 1) ---
params_no_delay <- list(beta = beta, sigma = sigma, gamma = gamma, v_cap = v_cap, 
                        alpha = alpha, incentive = 1000, kappa = 0, delay = 0)
out_no_delay <- as.data.frame(ode(y = initial_state, times = times, func = seir_model, parms = params_no_delay))

# --- Scenario 2: With Behavioral Delay (kappa = 0.225) ---
params_with_delay <- list(beta = beta, sigma = sigma, gamma = gamma, v_cap = v_cap, 
                          alpha = alpha, incentive = 0, kappa = kappa, delay = delay)
out_with_delay <- as.data.frame(ode(y = initial_state, times = times, func = seir_model, parms = params_with_delay))

# --- Visualization ---
out_no_delay$Scenario <- "Supply-only"
out_with_delay$Scenario <- "With Behavioral Delay"
combined <- rbind(out_no_delay, out_with_delay)

ggplot(combined, aes(x = time, y = I, color = Scenario, linetype = Scenario)) +
  geom_line(size = 1) +
  labs(title = "Epidemiological Impact of Behavioral Delay",
       subtitle = paste("kappa =", kappa),
       x = "Days", y = "Infected Population") +
  theme_minimal()
