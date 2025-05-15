# Big Vision Pictures Token (BVPTOKEN)

## Overview

BVPTOKEN is the native utility token powering Big Vision Pictures, a crypto-funded film and television studio. It grants holders access to exclusive events, behind-the-scenes experiences, and creative participation in BVP productions.

## Token Details

*1. Supply & Allocation

Max Supply: 1 000 000 000 BVP

Circulating Supply (Year 1): 775 000 000 BVP (77.5 %)

Locked – Corporate Treasury: 225 000 000 BVP (22.5 %)

Cliff-locked for 60–90 days before any spending

2. L1 Taxes Removed

Buy Tax: 8 % → 0 %

Sell Tax: 13 % → 0 %

No more on-chain purchase or sale levies—simplifies ERC-20 transfers and improves DEX onboarding.

3. Rebate-Only Fee Mechanisms

Activity	Fee to Treasury	Refund to User
L2 & L3 Gas Fees	20 % of each BVP gas payment	80 % refunded immediately
Cross-Chain Bridge (In/Out)	0.1 % of bridged amount	99.9 % credited/redeemed
BVP → USDC Swap	0.1 % of swapped BVP	99.9 % USDC delivered

No burns, no extra “reward” tokens—every fee point either locks value in treasury or returns it.

4. Treasury Accrual & Lock-Ups

All subchain-collected fees (gas slices, bridge fees, swap fees) flow into the L2 Corporate Treasury.

Cliff-Lock Window: 60–90 days after receipt before any disbursement.

Weekly Sweeps: Unspent BVP moved back to an L1 Reserve Vault for long-term hold.

DAO Governance: On-chain votes set release schedules, re-allocation for projects, and fee parameters.

5. Effective “Tax” Comparison

Scenario	Old Model	New Effective Fee
Token Buy / Sell	8 % / 13 %	0 %
L2 / L3 Transactions	N/A	GasFee × 20 %
Bridge In / Out	N/A	0.1 %
BVP → USDC Swap	N/A	0.1 %

6. Net Impact

Usage-Driven Demand: Fees only when the network is used—governance, payments, swaps.

Temporary Supply Compression: Treasury lock-ups withdraw tokens from liquid supply without burning.

Max Supply Intact: No tokens are destroyed; 1 BVP ceiling remains fixed.

No Inflationary Rewards: Rebate-only model prevents uncontrolled token issuance.

Adaptive Governance: Fee slices, bridge fees, and lock periods can be tweaked by DAO as needs evolve.

Transparent UX: Users pay clear, rebate-backed fees—no hidden charges at mint or burn.


## Utility

* **Tiered Access Staking**: Stake BVP tokens to unlock tiered perks such as red-carpet invites, set visits, and cameo opportunities. No token rewards—staking solely grants access.

## Architecture

* **Layer 2 Chain**: Deployed on Arbitrum L2, leveraging the Nitro upgrade for high throughput and fast finality.
* **Gas Abstraction**: Supports gasless meta-transactions via ERC-4337 for seamless user experience.

## Subchain Strategy

* **Programmable Subchains**: Launch franchise-specific rollups via Arbitrum Orbit, inheriting mainnet security and liquidity with custom parameters.
* **Custom Gas Tokens**: Subchains can utilize BVPTOKEN or dedicated gas tokens to optimize costs, governance, and user experience.

#In‑House Rebate‑Only Subchain Overview

Based on our internal rebate‑only subchain mechanism—no burns, no rewards—this corporate chain architecture maximizes BVP value through transparent fee slices and refunds citeturn1file0:

Architecture & Flow: Ethereum L1 → Arbitrum Mainnet; L2 corporate chain with a GasRouter splitting 20% fees to treasury and 80% flows to core modules (Budget, Payroll, Revenue, Treasury, Governance).

L3 Micro‑Chains:

Production Ops: 0.005 BVP/tx (20% retained, 80% refunded)

Marketing & Distribution: Revenue→BVP (15% retained, 85% refunded)

Post‑Production & VFX: 10 BVP/mint (100% retained)

Finance & Compliance: Swap BVP→USDC (0.1% retained, net USDC refunded)

Treasury Management: Accumulates all fee slices and bridge fees, cliff‑locks funds for 60–90 days, and executes weekly sweeps to the L1 reserve vault.

Governance & Protections: DAO votes can tune fee slices, entry/exit fees, and lock durations in real time; on‑chain dashboards and quarterly attestations ensure full transparency and auditability.
## License

MIT
