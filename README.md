# TripleLayer-DSR-Lab

A Triple-Layer Framework for Programmable Asset-Level Participation — Conceptual Sui Move Prototype

This repository contains a conceptual Sui Move prototype aligned with the paper:

**A Triple-Layer Blockchain Framework for Programmable Asset-Level Participation**

The prototype demonstrates the settlement semantics of a Programmable Rights Token (PRT) architecture. It focuses on oracle-prepared monthly settlement bundles, asset-anchor consistency, previous-bundle hash linkage, and payout routing according to each PRT's `yield_beneficiary` field.

This module is **not** a production-grade settlement engine. It is intended to demonstrate the paper's conceptual settlement logic and object-level rights representation. Production deployment would require batch orchestration, escrow accounting, AML/KYC registry integration, threshold-oracle validation, audit logging, access-control hardening, and gas-optimized Programmable Transaction Block (PTB) construction.

## Repository Purpose

The prototype supports the paper's Algorithm 1:

**Monthly Oracle-Prepared Settlement for Equal-Unit PRTs**

It illustrates how a rights-bearing participation unit can carry settlement-relevant state directly at the object level. In particular, the prototype shows how:

- a PRT object is linked to a stable asset anchor;
- each PRT carries a current `yield_beneficiary`;
- the oracle prepares a monthly settlement bundle off-chain;
- the on-chain function checks replay protection, asset-anchor consistency, active PRT status, and previous-bundle hash linkage;
- settlement-asset payout is routed according to the PRT's recorded rights state rather than ownership alone.

## Core Objects

The prototype defines the following conceptual objects.

### `PRT`

Represents one equal-unit Programmable Rights Token linked to an asset anchor.

Main fields:

- `asset_anchor`
- `owner`
- `yield_beneficiary`
- `active`

The `yield_beneficiary` field determines who receives the monthly payout. If no separate beneficiary is designated, this field is expected to be set equal to the owner before settlement.

### `MonthlySettlementBundle`

Represents the monthly oracle-prepared settlement bundle.

Main fields:

- `asset_anchor`
- `epoch_month`
- `batch_id`
- `previous_bundle_hash`
- `bundle_hash`
- `metered_generation_kwh`
- `fit_rate_cents`
- `approved_opex_cents`
- `tax_withholding_cents`
- `correction_cents`
- `net_distributable_cents`
- `active_prt_count`
- `monthly_yield_per_prt`
- `executed`

The oracle computes the monthly net distributable revenue and the per-PRT monthly yield off-chain. The bundle is then submitted to the on-chain settlement function.

### `SettlementState`

Stores the latest accepted settlement-bundle hash for a given asset anchor.

Main fields:

- `asset_anchor`
- `last_accepted_bundle_hash`

This object links each monthly bundle to the previously accepted bundle through `previous_bundle_hash`. This provides a simple replay and sequencing mechanism for the conceptual prototype.

### `OracleCap`

Represents authority to submit or finalize settlement-related operations.

In this conceptual prototype, possession of `OracleCap` stands in for oracle authorization. A production implementation should replace or extend this with threshold signatures, multi-oracle validation, role-based access control, and governance procedures.

### `ComplianceRegistry`

A placeholder object for AML/KYC eligibility checks.

In this prototype, the compliance check always returns `true`. A production implementation should replace this with a regulated identity registry, transfer-agent check, deny-list logic, or jurisdiction-specific compliance provider.

## Settlement Logic

The settlement process follows the paper's Algorithm 1.

### Oracle-side preparation

The oracle prepares the monthly settlement bundle off-chain:

1. Reads certified monthly generation data.
2. Applies the FIT or regulated settlement price.
3. Deducts approved OPEX, taxes, withholding, and corrections.
4. Computes gross project revenue.
5. Computes net distributable revenue.
6. Determines the active equal-unit PRT count.
7. Computes the monthly distributable amount per PRT.
8. Includes the previous accepted bundle hash.
9. Produces a new bundle hash and oracle authorization.

Conceptually:

```text
G_m = E_m × R_m
D_m = G_m − O_m − T_m + Δ_m
y_m = D_m / N_m

M_{m,b} = {
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

h_{m,b} = Hash(M_{m,b})
```

## Related Documentation

See `docs/Algorithm1_Monthly_Settlement.md` for the pseudocode version of the monthly settlement algorithm.
