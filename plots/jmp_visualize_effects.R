# jmp_visualize_effects.R
# This script generates the core visualizations for the Job Market Paper:
# "How Waiting Time Shapes Preventive Health Behavior"

library(ggplot2)
library(dplyr)

# Load synthetic data
df <- read.csv("data_simulation/synthetic_dce_data.csv")

# 1. Visualization of Urban vs Rural Wait Time Sensitivity
# Aggregate choice by WaitTime and UrbanRural
urban_rural_agg <- df %>%
  group_by(WaitTime, UrbanRural) %>%
  summarize(Uptake = mean(Choice), .groups = "drop")

p1 <- ggplot(urban_rural_agg, aes(x = WaitTime, y = Uptake, color = factor(UrbanRural))) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_discrete(name = "Region", labels = c("Rural", "Urban")) +
  labs(title = "Wait Time Sensitivity by Urban/Rural Status",
       subtitle = "Urban residents show steeper decline in uptake as wait time increases",
       x = "Wait Time (Hours)", y = "Vaccination Uptake Rate") +
  theme_minimal()

ggsave("plots/urban_rural_sensitivity.png", p1, width = 8, height = 6)

# 2. Visualization of Trust as a Buffer
# Aggregate choice by WaitTime and Trust
trust_agg <- df %>%
  group_by(WaitTime, Trust) %>%
  summarize(Uptake = mean(Choice), .groups = "drop")

p2 <- ggplot(trust_agg, aes(x = WaitTime, y = Uptake, color = factor(Trust))) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_viridis_d(name = "Trust Level") +
  labs(title = "Trust as a Psychological Buffer to Wait Time Friction",
       subtitle = "Higher trust levels mitigate the negative impact of long wait times",
       x = "Wait Time (Hours)", y = "Vaccination Uptake Rate") +
  theme_minimal()

ggsave("plots/trust_buffer_effect.png", p2, width = 8, height = 6)

cat("Visualizations generated successfully in plots/ folder.\n")
