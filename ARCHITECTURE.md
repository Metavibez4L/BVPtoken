## Big Vision Pictures On-Chain Architecture

### Core Contracts (L2 main chain)

- **`BVPToken`**
  - ERC-20 token with capped supply and fixed initial allocations.
  - Enforces **anti-whale limits** via `maxTx` (per-transfer) and `maxWallet` (per-address post-transfer).
  - Exemption mappings (`isTxLimitExcluded`, `isWalletLimitExcluded`) are **immutable after deployment** (no owner or admin). Only the addresses passed to the constructor can be excluded.
  - Integrates EIP-2612 (`ERC20Permit`) for gasless approvals.
  - **Trust assumptions**:
    - No privileged roles: behaviour is entirely determined at deployment.
    - Deployment parameters (allocation recipients and exclusions) must be carefully reviewed because they cannot be changed later.

- **`BVPStaking`**
  - Simple staking contract for BVP that grants **access tiers, not yield**.
  - Each address has at most **one active stake**; amount and lock duration determine tier.
  - Supports three lock durations (3, 6, 12 months) and tier thresholds from Bronze to Diamond.
  - Uses `ReentrancyGuard` for stake/unlock/unstake flows.
  - **Trust assumptions**:
    - Contract has no owner roles; logic is immutable.
    - Users must approve BVP to the staking contract before staking.
    - Tiers and durations are fixed in code; changing the staking model requires a new contract and migration.

### Subchain / Production Contracts (Orbit / L3 context)

- **`ProductionVault`**
  - Manages **milestone-based funding** for film projects using BVP as the accounting token.
  - Each project:
    - Has a `totalBudget`, milestone amounts, and a `producer`.
    - Requires a minimum number of **approver** confirmations before releasing each milestone.
    - Tracks `released` to ensure total disbursements never exceed `totalBudget`.
  - Uses `AccessControl`:
    - `DEFAULT_ADMIN_ROLE` – can manage other roles.
    - `ROLE_ADMIN` – can create/cancel projects and withdraw remaining funds after cancellation.
  - **Trust assumptions**:
    - `ROLE_ADMIN` is expected to be a **multisig** (e.g., studio treasury) on production.
    - Approvers are trusted to attest that a milestone is complete; a compromise of enough approvers can prematurely release funds.
    - The vault must hold enough BVP to cover all active project budgets; underfunding creates economic risk but not a direct contract bug.

- **`GasRouter`**
  - Pre-pays gas fees using BVP for L3 or subchain operations.
  - Holds an immutable reference to `bvpToken`, a mutable `treasury` address, and a BVP-denominated `gasUnitPrice`.
  - `prepayGas(user, gasUsed)` charges `user` and forwards BVP to the `treasury`.
  - Uses `AccessControl`:
    - `DEFAULT_ADMIN_ROLE` – can update treasury and gas price.
    - `ROLE_TREASURY` – currently unused beyond initial assignment but reserved for future granular permissions.
  - **Trust assumptions**:
    - Admin is expected to be a multisig. Misconfigured `treasury` or abusive `gasUnitPrice` can mis-price fees or mis-route funds.
    - Off-chain systems must measure `gasUsed` honestly; the contract does not verify this.

- **`LineItemRegistry`**
  - Tracks **budgeted vs. spent** amounts for line items per project.
  - `ROLE_ADMIN` defines line items (`projectId`, `accountCode`, description, `budgeted`).
  - `ROLE_PRODUCER` records spending against line items and enforces `spent + amount <= budgeted`.
  - Stores an array of vendor addresses per line item for auditability.
  - **Trust assumptions**:
    - Admin and producer roles are set by governance and represent production finance and producers.
    - Registry enforces budget ceilings but does **not** move tokens; it is an accounting layer that should mirror actual transfers (e.g., via `VendorPayment` or `ProductionVault`).

- **`VendorPayment` (current state: mock)**
  - Minimal payment queue used primarily for testing.
  - Stores queued payments (`recipient`, `amount`) and executes them by low-level `token.call("transfer")`.
  - Contains a generic `roles` mapping and `grantRole` helper but **no structured access control** or integration with `LineItemRegistry`.
  - **Trust assumptions & caveats**:
    - Current implementation is **not production-ready**; it is effectively a test harness.
    - No budget checks or registry integration; any caller can queue and execute payments if deployed as-is.
    - Will need to be replaced or heavily extended before mainnet/L2 deployment.

### Cross-Contract & Cross-Chain Flows

- **Token & Staking**
  - Users acquire BVP and can:
    - Transfer subject to anti-whale limits.
    - Approve `BVPStaking` and stake to reach a tier, then unlock/unstake after lock expiry.
  - No direct coupling between `BVPToken` and production contracts beyond using BVP as the accounting asset.

- **Production Funding**
  - Studio or treasury (with BVP holdings) funds `ProductionVault` by creating projects and transferring BVP into the vault.
  - Approvers confirm milestones; producers receive BVP disbursements to pay vendors and crew (on-chain or off-chain).
  - Separately, `LineItemRegistry` tracks detailed budget lines and spend but does not enforce actual token transfers yet.

- **Gas & Subchain Operations**
  - Apps calling into Orbit subchains or L3 modules can invoke `GasRouter.prepayGas` to pay BVP-denominated fees.
  - Off-chain infrastructure uses the `GasPaid` events and treasury balances to reconcile subchain gas economics.

### Trust & Governance Summary

- **Immutable components**: `BVPToken` and `BVPStaking` have no upgrade or admin role; any change requires deploying new contracts and migrating usage.
- **Governed components**: `ProductionVault`, `GasRouter`, `LineItemRegistry`, and any future production/payment contracts rely on `AccessControl` roles that should be held by multisigs and/or timelocked governance.
- **Key risks**:
  - Misconfigured roles or compromised multisig could misroute production funds or alter fee parameters.
  - `VendorPayment` as currently implemented is intentionally minimal and unsafe for real funds.
  - Off-chain processes (approvers, producers, gas metering) are integral to correct behaviour and must be operationally secured.

### BVPToken Allocations & Limit Exclusions

| Bucket             | % of Supply | Initial Recipient (constructor) | Tx-Limit Excluded? | Wallet-Limit Excluded? | Notes                                  |
|--------------------|------------:|---------------------------------|--------------------|------------------------|----------------------------------------|
| Public Sale        | 30%         | `publicSale_`                   | Yes                | Yes                    | Primary distribution / market making   |
| Operations         | 20%         | `operations_`                   | Yes                | Yes                    | Day-to-day operating liquidity         |
| Presale            | 10%         | `presale_`                      | No                 | No                     | Subject to whale limits                |
| Founders & Team    | 10%         | `foundersAndTeam_`              | No                 | No                     | Subject to whale limits                |
| Marketing          | 15%         | `marketing_`                    | No                 | No                     | Subject to whale limits                |
| Advisors           | 5%          | `advisors_`                     | No                 | No                     | Subject to whale limits                |
| Treasury           | 5%          | `treasury_`                     | Yes                | Yes                    | Strategic reserves / protocol runway   |
| Liquidity          | 5%          | `liquidity_`                    | Yes                | Yes                    | AMM / LP liquidity & market operations |

Anti-whale limits:
- `maxTx`    = 10,000,000 BVP (1% of cap)
- `maxWallet` = 20,000,000 BVP (2% of cap)

Only the four operational wallets (public sale, operations, treasury, liquidity) are exempted from one or both limits to avoid blocking liquidity provisioning and large operational rebalances.


