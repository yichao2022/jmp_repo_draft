# How Waiting Time Shapes Preventive Health Behavior: Evidence from Vaccination Decisions

[![R-Version](https://img.shields.io/badge/R-4.0%2B-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![JMP](https://img.shields.io/badge/Status-Job%20Market%20Paper-red.svg)](https://yichao2022.github.io/)

**Author:** [Yichao Jin](https://yichao2022.github.io/) (University of Texas at Dallas)  
**Co-authors:** Dohyeong Kim, Zhen Tian

---

## 📌 Research Overview

While traditional models of preventive health focus on *whether* individuals vaccinate, this paper investigates **when** they vaccinate. We conceptualize and quantify waiting time as a **"behavioral tax"** on public health implementation.

### Key Contributions:
- **Structural Estimation:** Recovered behavioral discounting parameters (κ=0.225) using a large-scale Discrete Choice Experiment (DCE).
- **MWTA Discovery:** Identified a Median Marginal Willingness to Accept (MWTA) of ≈ **47 RMB/hour** for reducing vaccination delay.
- **Trust as a Buffer:** Found that high institutional trust significantly mitigates the deterrent effect of wait times ($p < 0.05$).
- **Epidemic Impact:** Integrated behavioral parameters into SEIR models, demonstrating that time-sensitive incentives flatten the curve more effectively than flat subsidies.

---

## 📊 Key Results

![Main Effect of Waiting Time](plots/wait_time_main_effect_publication.png)
*Figure 1: Survival analysis of vaccine uptake showing the deterrent effect of waiting time (Behavioral Tax).*

| Feature | Finding | Impact |
| :--- | :--- | :--- |
| **Discounting (κ)** | 0.225 (Hyperbolic) | Strong evidence of present-bias in health timing |
| **MWTA** | 47 RMB/hour | Quantifies the financial value of time-saving |
| **Institutional Trust** | Positive Interaction | Trust reduces the perceived "cost" of waiting |

---

## 📂 Repository Structure

```bash
├── models/             # Structural Parameter Recovery & Mixed Logit models
│   ├── discount_estimation.R  # Replicates κ=0.225 finding (Hyperbolic vs Exponential)
│   ├── logit_analysis.R       # Mixed Logit & MWTA Calculation
│   └── seir_behavioral.R      # Behavioral-SEIR integration
├── data_simulation/    # Synthetic data generation (Privacy compliant)
│   └── generate_synthetic_data.R # Mirroring original survey statistics
├── plots/              # High-resolution publication figures
├── docs/               # Full Paper PDF & Methodology Deep-dive
└── run_all.R           # Master script for one-click replication
```

---

## 🚀 Quick Start (Replication)

This repository provides a **validated synthetic dataset** that preserves the exact structural properties of the original restricted data.

### 1. Requirements
Ensure you have R installed with the following packages:
```r
install.packages(c("mlogit", "tidyverse", "ggplot2", "deSolve"))
```

### 2. One-Click Replication
To replicate the main findings, parameter recovery, and plots:
```bash
Rscript run_all.R
```
*This script will: (1) Generate synthetic data, (2) Estimate the Mixed Logit model, and (3) Re-generate all figures in the `/plots` folder.*

---

## 🛡 Data Privacy Note
Primary experimental data are restricted due to Institutional Review Board (IRB) compliance. The provided synthetic data replicates the structural covariance and behavioral coefficients of the original sample for validation purposes. See [data_access.md](data_access.md) for full details.

---

## 📖 Citation

If you find this research or code useful for your work, please cite:

```bibtex
@article{jin2026waiting,
  title={How Waiting Time Shapes Preventive Health Behavior: Evidence from Vaccination Decisions},
  author={Jin, Yichao and Kim, Dohyeong and Tian, Zhen},
  year={2026},
  journal={Working Paper (Job Market Paper)},
  url={https://yichao2022.github.io/}
}
```

---

**Contact:** [Yichao.Jin@UTDallas.edu](mailto:Yichao.Jin@UTDallas.edu) | [Website](https://yichao2022.github.io/)
