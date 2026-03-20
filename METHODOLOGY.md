# Methodology: Structural Estimation & Behavioral Discounting

## Mixed Logit (MXL) Specification
We employ a Mixed Logit model to account for unobserved preference heterogeneity in vaccination timing. Unlike standard Multinomial Logit (MNL), the MXL allows parameters (e.g., waiting time penalty, cost sensitivity) to vary across individuals according to a specified distribution (Normal/Log-normal).

## Marginal Willingness to Accept (MWTA)
The MWTA for a one-month reduction in vaccination delay is calculated as the ratio of the time coefficient ($\beta_{wait}$) to the price coefficient ($\beta_{cost}$):

$$MWTA = \frac{\beta_{wait}}{\beta_{cost}}$$

In our JMP, we find an average MWTA of approximately **47 RMB**, indicating a significant valuation of time during a health crisis.

## Policy Implications
The "Behavioral Delay Multiplier" (BDM) introduced in this paper links individual time preferences to aggregate epidemic outcomes. Simulations show that interventions targeting "Wait-and-See" populations are most cost-effective in the early stages of a pandemic.
