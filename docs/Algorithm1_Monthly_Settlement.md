# Algorithm 1: Monthly Oracle-Prepared Settlement for Equal-Unit PRTs

This algorithm corresponds to the settlement logic implemented conceptually in
`sources/layer3_settlement.move`.

## Purpose

The algorithm separates oracle-side revenue preparation from on-chain batch execution.
The oracle calculates the monthly net distributable revenue and the per-PRT monthly yield. 
The on-chain layer verifies the settlement bundle, checks replay protection and previous-bundle hash linkage, 
and distributes settlement-asset payments according to each PRT's current yield_beneficiary field.

## Pseudocode

Pseudocode

Input:
  Asset anchor A
  Monthly settlement epoch m
  Batch identifier b
  Authorized oracle set O
  Active equal-unit PRT set P_A
  Settlement asset pool B_pool
  Batch subset P_b ⊆ P_A
  Previous accepted settlement-bundle hash h_{m-1}

Oracle-side preparation:
  E_m ← certified metered generation of asset A during month m
  R_m ← applicable FIT or regulated settlement price
  O_m ← approved operating expenses
  T_m ← tax, withholding, and statutory deductions
  Δ_m ← prior-period correction, if any

  G_m ← E_m × R_m
  D_m ← G_m − O_m − T_m + Δ_m

  N_m ← number of active equal-unit PRTs linked to A
  y_m ← D_m / N_m

  M_{m,b} ← {
      A,
      m,
      b,
      h_{m-1},
      E_m,
      R_m,
      O_m,
      T_m,
      Δ_m,
      D_m,
      N_m,
      y_m
  }

  h_{m,b} ← Hash(M_{m,b})
  σ_o ← oracle signature over M_{m,b}

On-chain batch execution:
  Verify required settlement checks:
  - authorized oracle capability is present
  - bundle has not already been executed
  - settlement state and bundle refer to the same asset anchor A
  - previous_bundle_hash equals the last accepted settlement-bundle hash
  - each processed PRT is linked to asset anchor A
  - each processed PRT is active
  - active PRT count is greater than zero
  - monthly yield per PRT is greater than zero
  - bundle validity checks pass

  If checks fail:
    reject

  If y_m ≤ 0:
    mark batch as skipped
    record or retain h_{m,b} according to the settlement-state policy
    return skip

  For each PRT p_i in batch P_b:
    If p_i is inactive or not linked to asset anchor A:
      continue

    B_i ← p_i.yield_beneficiary

    If no separate beneficiary is designated:
      B_i ← p_i.owner

    If B_i passes AML/KYC:
      transfer y_m settlement asset from B_pool to B_i
    Else:
      credit y_m to escrow or pending distribution
      keyed by (A, m, b, p_i.id, B_i)

    Emit settlement event:
      (A, m, b, p_i.id, B_i, y_m)

  Mark batch as executed
  Update last accepted settlement-bundle hash:
      last_accepted_bundle_hash ← h_{m,b}

  return success
