# Data Access Information

## Restricted Data
The primary empirical analysis in the paper "How Humans Value Time in a Crisis" (Job Market Paper) relies on individual-level experimental data from a Discrete Choice Experiment (DCE) conducted in Mainland China. 

Due to privacy restrictions and Institutional Review Board (IRB) compliance, the raw individual-level responses are **restricted** and cannot be hosted publicly in this repository.

## Synthetic Data
To ensure **reproducibility** and to demonstrate the robustness of our structural estimation pipeline, this repository provides a **synthetic dataset**.

- **Location**: `/data_simulation/synthetic_responses.csv`
- **Purpose**: This dataset is generated based on the true structural parameters recovered in the paper (e.g., waiting time penalty, cost sensitivity).
- **Functionality**: Users can run the scripts in `/models/` to:
    1.  Replicate the parameter recovery logic.
    2.  Validate the Mixed Logit (MXL) estimation procedure.
    3.  Confirm the calculation of Marginal Willingness to Accept (MWTA).

## Access Request
Researchers interested in verifying results using the restricted dataset for peer review or replication purposes may contact the author at:
**Yichao Jin** (Yichao.Jin@UTDallas.edu)
