## Monitoring, Alerting, and Operations

### Core Metrics & Events

- **BVPToken**
  - Monitor:
    - Large transfers (`Transfer` events above a threshold, e.g., > 1% of supply).
    - Holder distribution and concentration (top wallets).
  - Use-case:
    - Detect whale movements, exchange deposits/withdrawals, and potential compromise of operational wallets.

- **BVPStaking**
  - Events: `Staked`, `Unlocked`, `Unstaked`.
  - Monitor:
    - Total staked balance and number of unique stakers.
    - Distribution across tiers (Bronze → Diamond).
    - Large unlock/unstake waves.

- **ProductionVault**
  - Events: `ProjectCreated`, `MilestoneApproved`, `MilestoneReleased`, `ProjectCanceled`, `RemainderWithdrawn`.
  - Monitor:
    - Number of active projects and their `totalBudget` / `released`.
    - Frequency and amounts of `MilestoneReleased`.
    - Cancellations and remaining budget withdrawals.
  - Invariants:
    - `released` should never exceed `totalBudget`.
    - `currentMilestone` must be `< milestones.length` for active projects.

- **GasRouter**
  - Events: `GasPaid`, `TreasuryUpdated`, `GasPriceUpdated`.
  - Monitor:
    - Aggregate gas prepayments per day/week.
    - Sudden spikes in `GasPaid` or unexpected `gasUnitPrice` changes.
    - Treasury address changes.

- **LineItemRegistry**
  - Events: `LineItemAdded`, `PaymentRecorded`.
  - Monitor:
    - Line item budget vs. spend per project/account code.
    - Rapid or repeated `PaymentRecorded` events approaching budget caps.

- **VendorPayment**
  - Events: `PaymentQueued`, `PaymentExecuted`, `VendorRegistered`.
  - Monitor:
    - Queue length (pending vs. executed payments).
    - Large or unusual payment recipients/amounts.
    - Any spikes in failed executions (on-chain reverts).

### Sepolia Implementation Notes

- **Data sources**
  - Use `deployments/arbitrum-sepolia.json` for contract addresses.
  - Network: Arbitrum Sepolia (`chainId = 421614`).

- **Example query ideas (Dune / SQL-style pseudocode)**
  - Large token transfers:
    - Filter `erc20_transfers` where:
      - `contract_address = <BVPToken>` and
      - `amount >= 0.01 * total_supply` (1% of supply) or parametric.
  - Staking activity:
    - Filter logs where `contract_address = <BVPStaking>` and `event_name IN ('Staked','Unlocked','Unstaked')`.
  - Project budgets and releases:
    - Filter `ProductionVault` events by `ProjectCreated`, `MilestoneReleased`, `ProjectCanceled` and group by `projectId`.
  - Router and vendor payments:
    - `GasRouter`: aggregate `GasPaid` by day, `gasUsed` and `cost`.
    - `VendorPayment`: compare count/volume of `PaymentQueued` vs `PaymentExecuted` per day.

### Dashboards

- Recommended tooling:
  - **Dune / Flipside / similar** for cross-chain analytics and historical views.
  - **Tenderly / Blockscout / Arbiscan** for transaction-level details and contract-level trace analysis.
- Suggested dashboard views:
  - Overview:
    - Total BVP supply, top holders, staked vs. liquid.
    - Number of active productions and aggregate production budgets.
  - Staking:
    - Tier distribution, staking/unstaking activity over time.
  - Production funding:
    - Per-project budget vs. released vs. remaining.
    - Milestone approvals/releases timeline.
  - Fees & routing:
    - Gas prepayments, fee flows to treasury, router activity.

#### Suggested concrete widgets (Sepolia)

- **Overview dashboard**
  - Card: total BVP token transfers (24h / 7d) on Sepolia.
  - Table: top 20 holders with labels for known allocation wallets.
  - Chart: total staked balance over time (from `Staked`/`Unstaked` deltas).

- **Production dashboard**
  - Table: active projects with `totalBudget`, `released`, `remaining`.
  - Timeline: `MilestoneReleased` events with amounts and project IDs.
  - Indicator: count of `ProjectCanceled` in last 24h.

- **Ops & fees dashboard**
  - Chart: `GasPaid.cost` sum per day.
  - Table: queued vs executed vendor payments by day.
  - Indicator: last `GasPriceUpdated` value and time.

### Alerting

- Examples of alerts:
  - **Critical**
    - Large BVP transfer from treasury or operational wallets.
    - Unexpected `pause()` invocation on `ProductionVault`, `GasRouter`, or `VendorPayment`.
    - `GasPriceUpdated` to an unusually high or low value.
  - **High**
    - Multiple project cancellations in a short window.
    - Rapid growth in `PaymentQueued` without corresponding `PaymentExecuted`.
  - **Medium**
    - Many small transfers to a previously unknown address.
    - `PaymentRecorded` repeatedly hitting line-item budget edges.

- Integration targets:
  - Pager/incident channels: Slack, Discord, Telegram, or Ops tools.
  - Use relays (e.g., Blocknative, Tenderly alerts, custom indexer) to route on-chain signals to these channels.

#### Concrete threshold suggestions (Sepolia)

- **BVPToken**
  - Critical: any transfer from `Treasury` or `Liquidity` > 1% of total supply.
  - High: more than 5 transfers > 0.5% of supply in 1 hour.

- **BVPStaking**
  - High: more than 10% of total staked amount unstaked within 1 hour.

- **ProductionVault**
  - High: ≥ 3 `ProjectCanceled` events in 24h.
  - Medium: any `RemainderWithdrawn` where `remaining / totalBudget > 0.5`.

- **GasRouter**
  - Critical: `GasPriceUpdated` outside an expected band (e.g., < 1e13 or > 1e18 wei per gas unit).
  - High: no `GasPaid` events for > 24h during expected active periods.

- **VendorPayment**
  - High: more than N (tunable, e.g., 10) `PaymentQueued` without any `PaymentExecuted` in the same 24h window.
  - Medium: any single `PaymentExecuted` above a configured treasury threshold.

### Incident Runbooks (High Level)

- **Suspected key compromise or abnormal transfers**
  1. Pause `ProductionVault`, `GasRouter`, and `VendorPayment`.
  2. Freeze any off-chain systems using compromised keys.
  3. Move remaining funds to secure multisig where appropriate.
  4. Communicate publicly with a brief incident statement and next steps.

- **Misconfiguration (e.g., wrong treasury, wrong gas price)**
  1. Pause affected contract(s) if there is active loss or risk.
  2. Use admin roles to correct configuration.
  3. Backfill and reconcile off-chain accounting based on logs.

- **Contract bug identified**
  1. Pause impacted flows (milestones, vendor payments, gas routing).
  2. Open an internal incident, triage severity, and engage auditors if needed.
  3. If required, deploy patched contracts (V2) and plan migration.
  4. Document root cause and mitigation steps for future reference.

### Implementation Notes (Configs)

- The file `monitoring.config.example.json` provides a minimal, structured
  configuration for:
  - Mapping networks to deployment JSON files (e.g., `deployments/arbitrum-sepolia.json`,
    `deployments/arbitrum-mainnet.json`).
  - Defining high-level thresholds for:
    - Large BVP transfers (as % of total supply).
    - Large unstake waves (as % of total staked).
  - Stubbing incident channels (Slack/Discord/email) to be filled in by ops.
- Use this file as a starting point for wiring your actual monitoring stack
  (Dune / Flipside / Tenderly / custom indexer) to real alert destinations.



