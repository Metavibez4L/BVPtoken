## External Audit Preparation

### Scope

Contracts in scope for the initial audit:

- `contracts/BVPToken.sol`
- `contracts/BVPStaking.sol`
- `subchain/contracts/ProductionVault.sol`
- `subchain/contracts/GasRouter.sol`
- `subchain/contracts/LineItemRegistry.sol`
- `subchain/contracts/VendorPayment.sol`

Libraries and test helpers (`forge-std`, mocks, etc.) are considered out of scope except where explicitly integrated.

### Build & Test Commands

- See `TESTING.md` for the canonical commands (Hardhat + Foundry + subchain + coverage + Slither).

Minimum expected before audit handoff:

- `npm run compile`
- `npm test`
- `forge test -vv`
- `cd subchain && forge test -vv`
- `npm run coverage` (optional but recommended)

Auditors should run all of the above and confirm there are no failing tests or unexpected warnings.

### Suggested Static Analysis

See `TESTING.md` for Slither install/run guidance (WSL recommended on Windows).

### Key Invariants (per Contract)

- **BVPToken**
  - Total supply equals `cap()` and is fully minted at deployment.
  - Anti-whale:
    - Non-exempt senders cannot transfer more than `maxTx` in a single transfer.
    - Non-exempt recipients cannot hold more than `maxWallet` after a transfer.
  - Exemptions are fixed at construction and cannot be modified.

- **BVPStaking**
  - Each address has at most one active stake at a time.
  - Unlock requires `block.timestamp >= timestamp + lockTime`.
  - Unstake requires `unlocked == true` and returns the full `amount`, then clears the stake.
  - Tier codes/names map deterministically from the staked amount.

- **ProductionVault**
  - For each project, `released` must never exceed `totalBudget`.
  - Sum of `milestones` equals `totalBudget` at creation.
  - Each milestone release requires at least `MIN_APPROVALS` distinct approver confirmations.
  - Canceled projects cannot release further milestones; remaining funds can only be withdrawn once by the producer.

- **GasRouter**
  - `prepayGas` transfers `gasUsed * gasUnitPrice` from `user` to `treasury`.
  - Only admin can update `treasury` or `gasUnitPrice`.

- **LineItemRegistry**
  - For each `(projectId, accountCode)`, `spent` never exceeds `budgeted`.
  - Only `ROLE_ADMIN` can add line items; only `ROLE_PRODUCER` can record payments.

- **VendorPayment**
  - Each `paymentId` is executed at most once.
  - `executePayment`:
    - Records the spend via `recordPayment` on `LineItemRegistry`.
    - Transfers tokens to the intended recipient.
  - Roles:
    - `ROLE_PRODUCER` queues payments.
    - `ROLE_TREASURY` executes payments.

### Assumptions & Non-Goals

- BVPToken and BVPStaking are immutable and not upgradeable.
- Operational contracts (vault, router, registry, vendor payments) are governed via multisig-held roles but not currently proxied.
- Economic and business-model analysis (token pricing, market risk, DAO governance processes) is out of scope for the code audit.


