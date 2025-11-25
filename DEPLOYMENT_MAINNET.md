## Arbitrum Mainnet Deployment Runbook (Core Contracts Only)

This runbook describes how to safely deploy the core BVP contracts (`BVPToken`, `BVPStaking`, and optionally `Lock`) on **Arbitrum mainnet**.

---

### 1. Prerequisites & Environment

#### 1.1 Tooling
- Node.js 20+
- `npm`
- Hardhat (via local `node_modules`)
- (Optional) Foundry (`forge`) for Solidity tests

#### 1.2 `.env` Variables (local dev)
Create `BVPtoken/.env` with:

```bash
ARB_MAINNET_RPC_URL=your-arbitrum-mainnet-rpc-url
MAINNET_PRIVATE_KEY=your_mainnet_deployer_private_key_without_0x

ETHERSCAN_API_KEY=your_arbiscan_or_etherscan_api_key
```

Security recommendations:
- Use a hardware wallet–backed key for `MAINNET_PRIVATE_KEY` if possible.
- NEVER commit `.env` or raw keys to the repo.

#### 1.3 CI / Secrets
- Store the same values in:
  - GitHub Actions secrets (`ARB_MAINNET_RPC_URL`, `MAINNET_PRIVATE_KEY`, `ETHERSCAN_API_KEY`).
  - Or another secret manager (1Password, Vault).

---

### 2. Pre-Deployment Checks (Repeat from Sepolia, Final Run on Mainnet)

From `BVPtoken/`:

```bash
npm install              # ensure dependencies are up to date
npm run compile          # Hardhat compile
npm test                 # Hardhat tests

# Optional, requires Foundry installed locally:
forge test -vv           # Foundry tests (root)
```

All tests must pass with no unexpected warnings before mainnet deployment.

---

### 3. Deploying to Arbitrum Mainnet

From `BVPtoken/`:

```bash
npm run deploy:arbitrum-mainnet
```

This will:
- Use `hardhat.config.ts` `arbitrumOne` network (RPC + `MAINNET_PRIVATE_KEY`).
- Deploy:
  - `BVPToken`
  - `BVPStaking`
- Attempt verification on Arbiscan using `ETHERSCAN_API_KEY`.
- Write or overwrite `deployments/arbitrum-mainnet.json` with:
  - Network, chainId, deployer.
  - Contract addresses.
  - Allocation recipients.
  - Arbiscan verification URLs.

> **Important**: Before running this command, review and, if necessary, update the allocation addresses in `script/deploy_arbitrum.ts` so they match your final production multisigs and treasuries.

#### 3.1 Post-deploy sanity check

1. Open `deployments/arbitrum-mainnet.json` and confirm:
   - `contracts.BVPToken.address` and `contracts.BVPStaking.address` are present.
2. Check Arbiscan:
   - Confirm contracts are verified.
   - Optionally run small `totalSupply()`, `cap()`, `maxTx()`, and `maxWallet()` queries.
3. Record final addresses in:
   - `README.md`
   - `INTEGRATION.md`
   - Any off-chain configs (frontends, backend services).

---

### 4. Key Management & Role Holders (L2 Core)

For the core contracts:

- `BVPToken`:
  - No admin/owner roles.
  - All configuration is fixed at deployment (allocation addresses and limit exclusions).
  - Ensure allocation wallets are multisigs where appropriate (treasury, liquidity, operations).

- `BVPStaking`:
  - No admin/owner roles.
  - Only dependency is the `BVPToken` address passed to the constructor.

For operational / subchain contracts (handled in a separate plan), follow `GOVERNANCE.md` for role assignments and multisig setup.

---

### 5. Final Verification & Handoff

After mainnet deployment:

1. Run through the relevant items in `SECURITY_CHECKLIST.md` for mainnet:
   - Deployment parameters verified.
   - Addresses recorded and cross-checked.
   - Monitoring configured (see `MONITORING.md`).
2. Run basic smoke tests on mainnet with very small amounts:
   - Transfer a tiny amount of BVP between two wallets.
   - Stake and unstake a minimal amount to confirm `BVPStaking` works.
3. Publish:
   - Final token and staking contract addresses on official channels.
   - Links to security docs (`SECURITY_ANALYSIS.md`, `SECURITY_SUMMARY.md`).
   - Any applicable audit reports.

Once this is complete, your core L2 contracts are live on Arbitrum mainnet and ready to integrate with the broader BVP ecosystem.


