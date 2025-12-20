## Sepolia Phase: Ecosystem Readiness & Feedback

This document outlines how to present the Sepolia deployment and gather early feedback before mainnet.

---

### 1. Minimal Public Touchpoints

- **Arbiscan**
  - Ensure all deployed contracts on Arbitrum Sepolia are:
    - Verified with correct source and compiler settings.
    - Labeled with clear names (e.g., `BVPToken (Sepolia)`, `BVPStaking (Sepolia)`).
  - Add links to `deployments/arbitrum-sepolia.json` in internal docs so addresses stay in sync.

- **Public README / Status Page**
  - Provide a short, testnet-focused README (e.g., GitHub `SEP0LIA_PHASE.md` link from main `README.md`) that includes:
    - Contract addresses on Sepolia.
    - High-level description of what’s safe to test (staking, production flows) and what is not (no real funds).
    - Links to developer docs (`INTEGRATION.md`, `ARCHITECTURE.md`).

---

### 2. Bridges and Exchanges (Planning Only)

For mainnet, likely integration points include:

- **Bridges**
  - Native Arbitrum bridge.
  - Third-party bridges that support custom tokens.
  - Requirements typically include:
    - Verified token contract on mainnet.
    - Documentation of total supply and tokenomics.
    - Admin/multisig details and upgradeability stance.

- **Exchanges / Liquidity Venues**
  - DEXs (e.g., Uniswap, Camelot, etc.).
  - CEXs (longer lead time).
  - Common technical asks:
    - Token contract address and ABI.
    - Confirmation of no blacklisting/pausing on transfers (or clear description if present).
    - Audit reports.

During the Sepolia phase, simply maintain a living list of target bridges/exchanges and their known requirements so you can respond quickly once audits are complete.

---

### 3. Feedback Loop for Builders and Testers

- **Channels**
  - Discord/Telegram: dedicated `#bvp-contracts` or `#testnet-feedback` channel.
  - GitHub Issues:
    - Template for “Integration Issue” including:
      - Network and contract addresses used.
      - Reproduction steps (tx hashes, RPC calls).
      - Expected vs actual behaviour.

- **What to ask for**
  - Integration friction:
    - ABI issues, confusing revert messages, missing events.
  - UX friction:
    - Where users are confused about staking locks, tiers, or budgets.
  - Monitoring needs:
    - Additional metrics or events that would help partners operate safely.

Use this feedback to refine docs and, if needed, propose non-breaking contract improvements for a later version.


