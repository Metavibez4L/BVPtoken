## Governance, Roles, and Upgradeability

### Upgradeability Strategy

- **Immutable contracts**
  - `BVPToken` and `BVPStaking` are intentionally immutable:
    - No owner/admin roles, no setters, and no upgrade hooks.
    - Any change to tokenomics or staking rules requires deploying new contracts and migrating usage.

- **Operational contracts**
  - `ProductionVault`, `GasRouter`, `LineItemRegistry`, and `VendorPayment` are operational and governed via `AccessControl`.
  - For the initial rollout, these contracts are deployed directly (no proxy) to keep complexity low.
  - Future upgrades should be done via **versioned deployments** (V2, V3, …) with:
    - Clear migration scripts for moving roles and balances where applicable.
    - Decommissioning flow for older versions (e.g., pausing, draining unused funds, and updating frontends/ops).

### Role Model (L2)

- **Global roles**
  - `DEFAULT_ADMIN_ROLE`:
    - Held by an L2 multisig (e.g., 2-of-3 or 3-of-5) operated by the studio.
    - Can grant/revoke all other roles; should be protected with hardware wallets and, ideally, a timelock.
  - `ROLE_ADMIN` (per-contract):
    - Day-to-day protocol operations (creating projects, configuring router parameters, etc.).
    - Also held by a multisig, potentially distinct from the global admin.

- **Contract-specific roles**
  - `ProductionVault`
    - `DEFAULT_ADMIN_ROLE`: governance multisig, manages `ROLE_ADMIN`.
    - `ROLE_ADMIN`: can create/cancel projects and withdraw remaining budgets on cancellation.
  - `GasRouter`
    - `DEFAULT_ADMIN_ROLE`: governance multisig.
    - `ROLE_TREASURY`: treasury wallet that receives gas prepayments (currently informational).
  - `LineItemRegistry`
    - `ROLE_ADMIN`: sets up budget line items.
    - `ROLE_PRODUCER`: records spend against line items.
  - `VendorPayment`
    - `ROLE_ADMIN`: configures vendor metadata (and, in future, limits and permissions).
    - `ROLE_PRODUCER`: queues payments for vendors against specific projects/accounts.
    - `ROLE_TREASURY`: executes queued payments and moves funds.

### Pausing & Emergency Controls

- **Circuit breakers**
  - `ProductionVault`, `GasRouter`, and `VendorPayment` expose pause/unpause functionality (see contracts) controlled by governance roles.
  - Typical incident flow:
    1. Pause `ProductionVault` milestone releases and new project creation.
    2. Pause `GasRouter` and/or `VendorPayment` to halt new spend/fee flows.
    3. Diagnose and, if required, deploy and migrate to a patched contract version.
    4. Unpause once the system is safe and audits are complete.

- **Key rotation**
  - Admin and treasury addresses are not hard-coded; they are configurable through `AccessControl` role management and contract-specific setters.
  - Rotate signers on multisigs using their native admin flows; then update on-chain roles to reference the new multisig addresses.


