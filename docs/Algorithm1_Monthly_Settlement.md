# Algorithm 1: Monthly Oracle-Prepared Settlement for Equal-Unit PRTs

This algorithm corresponds to the settlement logic implemented conceptually in
`sources/layer3_settlement.move`.

## Purpose

The algorithm separates oracle-side revenue preparation from on-chain batch execution.
The oracle calculates the monthly net distributable revenue and the per-PRT monthly yield.
The on-chain layer verifies the settlement bundle and distributes stablecoin payments according
to each PRT's current `yield_beneficiary` field.

## Pseudocode

```text
Input:
  Asset anchor A
  Monthly settlement epoch m
  Authorized oracle set O
  Active equal-unit PRT set P_A
  Stablecoin settlement pool B_pool
  Batch subset P_b ⊆ P_A

Oracle-side preparation:
  E_m ← certified metered generation of asset A during month m
  R_m ← applicable FIT or regulated settlement price
  O_m ← approved operating expenses
  T_m ← tax, withholding, and statutory deductions
  Δ_m ← prior-period correction, if any

  G_m ← E_m × R_m
  D_m ← G_m − O_m − T_m + Δ_m

  N_m ← number of active equal-unit PRTs linked to A
  y_m ← monthly distributable amount per PRT

  M_m ← {A, m, E_m, R_m, O_m, T_m, Δ_m, D_m, N_m, y_m}
  σ_o ← oracle signature over M_m

On-chain batch execution:
  Verify required settlement checks:
  - authorized oracle
  - replay protection
  - asset-anchor match
  - active PRT status
  - bundle validity

  If checks fail:
    reject

  If y_m ≤ 0:
    skip settlement

  For each PRT p_i in batch P_b:
    If p_i is inactive or not linked to asset anchor A:
      continue

    B_i ← p_i.yield_beneficiary

    If no separate beneficiary is designated, yield_beneficiary is set equal to owner before settlement.

    If B_i passes AML/KYC:
      transfer y_m stablecoin to B_i
    Else:
      credit y_m to escrow or pending distribution

    Record or emit settlement evidence in a production implementation.
  mark batch as executed