/// Conceptual Move prototype for Algorithm 1:
/// Monthly Oracle-Prepared Settlement for Equal-Unit PRTs.
///
/// The oracle prepares the monthly settlement bundle off-chain.
/// The on-chain function routes settlement-asset payout according to each PRT's
/// yield_beneficiary field.
///
/// This module is not production-grade infrastructure. It is intended to
/// demonstrate the paper's settlement semantics.

module prt_framework::layer3_settlement {
    use sui::object::{UID, ID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};

    /// Layer 2: Equal-unit Programmable Rights Token.
    /// Each PRT represents one equal participation unit under the same asset anchor.
    struct PRT has key, store {
        id: UID,
        asset_anchor: ID,
        owner: address,
        yield_beneficiary: address,
        active: bool,
    }

    /// Capability proving that the caller is an authorized settlement oracle.
    struct OracleCap has key, store {
        id: UID,
    }

    /// Asset-level settlement state.
    /// This object stores the hash of the latest accepted settlement bundle.
    struct SettlementState has key, store {
        id: UID,
        asset_anchor: ID,
        last_accepted_bundle_hash: vector<u8>,
    }

    /// Minimal monthly settlement bundle prepared by the oracle.
    /// The oracle computes net distributable revenue and per-PRT monthly yield off-chain.
    struct MonthlySettlementBundle has key, store {
        id: UID,
        asset_anchor: ID,
        epoch_month: u64,
        batch_id: u64,

        previous_bundle_hash: vector<u8>,
        bundle_hash: vector<u8>,

        metered_generation_kwh: u64,
        fit_rate_cents: u64,
        approved_opex_cents: u64,
        tax_withholding_cents: u64,
        correction_cents: u64,

        net_distributable_cents: u64,
        active_prt_count: u64,
        monthly_yield_per_prt: u64,

        executed: bool,
    }

    /// Simple AML/KYC registry placeholder.
    /// In a real deployment this may be linked to a regulated transfer agent,
    /// identity registry, or jurisdiction-specific compliance provider.
    struct ComplianceRegistry has key, store {
        id: UID,
    }

    const E_ALREADY_EXECUTED: u64 = 1;
    const E_WRONG_ANCHOR: u64 = 2;
    const E_INACTIVE_PRT: u64 = 3;
    const E_ZERO_YIELD: u64 = 4;
    const E_WRONG_PREVIOUS_HASH: u64 = 5;
    const E_STATE_ANCHOR_MISMATCH: u64 = 6;

    /// Placeholder compliance check.
    /// Replace with registry lookup, transfer-agent check, or deny-list logic.
    fun passes_aml_kyc(
        _registry: &ComplianceRegistry,
        _beneficiary: address,
        _asset_anchor: ID,
        _epoch_month: u64
    ): bool {
        true
    }

    /// ALGORITHM 1:
    /// Monthly Oracle-Prepared Settlement for Equal-Unit PRTs.
    ///
    /// The oracle prepares the bundle off-chain:
    /// generation -> FIT revenue -> OPEX/tax/withholding deduction
    /// -> net distributable revenue -> monthly yield per equal-unit PRT.
    ///
    /// The bundle also carries previous_bundle_hash, which must match the
    /// last accepted settlement hash stored in SettlementState.
    public entry fun execute_prt_settlement<T>(
        _oracle_cap: &OracleCap,
        state: &SettlementState,
        registry: &ComplianceRegistry,
        bundle: &mut MonthlySettlementBundle,
        revenue_pool: &mut Coin<T>,
        prt: &PRT,
        ctx: &mut TxContext
    ) {
        // Replay protection.
        assert!(!bundle.executed, E_ALREADY_EXECUTED);

        // Settlement state and bundle must refer to the same asset anchor.
        assert!(
            state.asset_anchor == bundle.asset_anchor,
            E_STATE_ANCHOR_MISMATCH
        );

        // The PRT must be linked to the same asset anchor as the bundle.
        assert!(
            prt.asset_anchor == bundle.asset_anchor,
            E_WRONG_ANCHOR
        );

        // Previous accepted bundle hash must match.
        assert!(
            bundle.previous_bundle_hash == state.last_accepted_bundle_hash,
            E_WRONG_PREVIOUS_HASH
        );

        // PRT and yield checks.
        assert!(prt.active, E_INACTIVE_PRT);
        assert!(bundle.active_prt_count > 0, E_ZERO_YIELD);
        assert!(bundle.monthly_yield_per_prt > 0, E_ZERO_YIELD);

        let beneficiary = prt.yield_beneficiary;
        let amount = bundle.monthly_yield_per_prt;

        if (
            passes_aml_kyc(
                registry,
                beneficiary,
                bundle.asset_anchor,
                bundle.epoch_month
            )
        ) {
            let payout = coin::split(revenue_pool, amount, ctx);
            transfer::public_transfer(payout, beneficiary);
        } else {
            // In a full implementation, this branch should credit an escrow object
            // keyed by (asset_anchor, epoch_month, batch_id, prt_id, beneficiary).
            // It is left as a placeholder in this minimal prototype.
        };
    }

    /// Marks the monthly batch as executed after the off-chain or PTB-level
    /// batch process has completed.
    ///
    /// In a production implementation, this should be called only after all
    /// PRTs in the batch have been processed, or replaced by a batch-level
    /// settlement object with per-batch execution status.
    ///
    /// Once the batch is marked as executed, bundle_hash becomes the latest
    /// accepted settlement hash for the asset.
    public entry fun mark_batch_executed(
        _oracle_cap: &OracleCap,
        state: &mut SettlementState,
        bundle: &mut MonthlySettlementBundle
    ) {
        assert!(!bundle.executed, E_ALREADY_EXECUTED);

        assert!(
            state.asset_anchor == bundle.asset_anchor,
            E_STATE_ANCHOR_MISMATCH
        );

        assert!(
            bundle.previous_bundle_hash == state.last_accepted_bundle_hash,
            E_WRONG_PREVIOUS_HASH
        );

        bundle.executed = true;
        state.last_accepted_bundle_hash = copy bundle.bundle_hash;
    }
}
