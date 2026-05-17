# TripleLayer-DSR-Lab
A Triple-Layer Framework for Programmable Asset-Level Participation — Conceptual Sui Move Prototype

This Move module is a conceptual prototype aligned with the paper's settlement algorithm.
It demonstrates oracle-prepared monthly yield distribution to the PRT yield_beneficiary field.
It is not a production-grade settlement engine. Batch orchestration, escrow accounting,
AML/KYC registry integration, multi-oracle validation, and gas-optimized PTB construction are left for implementation-level extensions.
The current prototype demonstrates per-PRT payout routing. Batch orchestration and exact batch-completion tracking are intentionally left outside this minimal Move module.


## Settlement Logic

The Move module implements a conceptual prototype of the paper's Algorithm 1:
**Monthly Oracle-Prepared Settlement for Equal-Unit PRTs**.

The settlement process is intentionally simple:

1. The oracle reads certified monthly generation data.
2. The FIT or regulated settlement price is applied.
3. OPEX, taxes, withholding, and corrections are deducted.
4. The oracle computes the monthly distributable amount per equal-unit PRT.
5. The on-chain settlement function routes stablecoin payment to each PRT's `yield_beneficiary`. If no separate beneficiary is designated, this field is set equal to the owner.
6. If the beneficiary is not eligible under AML/KYC rules, the amount should be routed to escrow in a production implementation.

See [`docs/Algorithm1_Monthly_Settlement.md`](docs/Algorithm1_Monthly_Settlement.md).