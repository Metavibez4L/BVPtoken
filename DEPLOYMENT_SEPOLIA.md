## Arbitrum Sepolia Deployment Runbook

This runbook describes how to safely deploy and operate the BVP contracts on **Arbitrum Sepolia**.

---

### 1. Prerequisites & Environment

#### 1.1 Tooling
- Node.js 20+
- `npm` or `yarn`
- Hardhat (via local `node_modules`)
- (Optional) Foundry (`forge`) for Solidity tests

#### 1.2 `.env` Variables (local dev)
Create `BVPtoken/.env` with:

```bash
ARB_SEPOLIA_RPC_URL=your-arbitrum-sepolia-rpc-url
PRIVATE_KEY=your_deployer_private_key_without_0x

ARBISCAN_API_KEY=your_arbiscan_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key   # optional fallback
```

#### 1.3 CI / Secrets
- Store the same values in:
  - GitHub Actions secrets (`ARB_SEPOLIA_RPC_URL`, `PRIVATE_KEY`, `ARBISCAN_API_KEY`).
  - Or another secret manager (1Password, Vault).
- Never commit `.env` or raw keys to the repo.

---

### 2. Pre-Deployment Checks

Run from `BVPtoken/`:

```bash
npm install              # first time only
npm run compile          # Hardhat compile
npm test                 # Hardhat tests

forge test -vv           # Foundry tests (root)
cd subchain && forge test -vv && cd ..
```

All tests must pass with no unexpected warnings before deployment.

---

### 3. Deploying to Arbitrum Sepolia

From `BVPtoken/`:

```bash
npm run deploy:arbitrum-sepolia
```

This will:
- Use `hardhat.config.ts` `arbitrumsepolia` network (RPC + `PRIVATE_KEY`).
- Deploy:
  - `BVPToken`
  - `BVPStaking`
- Attempt verification on Arbiscan using `ARBISCAN_API_KEY`.
- Write or overwrite `deployments/arbitrum-sepolia.json` with:
  - Network, chainId, deployer.
  - Contract addresses.
  - Allocation recipients.

#### 3.1 Post-deploy sanity check

1. Open `deployments/arbitrum-sepolia.json` and confirm:
   - `contracts.BVPToken.address` and `contracts.BVPStaking.address` are present.
2. Check Arbiscan:
   - Confirm contracts are verified.
   - Optionally run a small `totalSupply()` / `cap()` / `maxTx()` / `maxWallet()` query.

---

### 4. Role Assignment Checklist (Once Ops Contracts Are Deployed)

When you later deploy the operational contracts (`ProductionVault`, `GasRouter`, `LineItemRegistry`, `VendorPayment`) to Arbitrum Sepolia, use this checklist.

#### 4.1 Decide role holders (Sepolia phase)

For each contract:

- `DEFAULT_ADMIN_ROLE`:
  - Sepolia: typically an EOA controlled by the core team or a small multisig.
  - Mainnet: a hardened multisig with hardware wallets and clear governance.

- Operational roles:
  - `ProductionVault`: `ROLE_ADMIN` (studio treasury / ops multisig).
  - `GasRouter`: `DEFAULT_ADMIN_ROLE` (treasury governance), `ROLE_TREASURY` (treasury wallet).
  - `LineItemRegistry`: `ROLE_ADMIN` (finance ops), `ROLE_PRODUCER` (production leads).
  - `VendorPayment`: `ROLE_ADMIN`, `ROLE_PRODUCER`, `ROLE_TREASURY` (as per GOV docs).

#### 4.2 On-chain role assignment steps

1. From a `DEFAULT_ADMIN_ROLE` address:
   - Call `grantRole(ROLE_ADMIN, <adminAddress>)` where appropriate.
   - Call `grantRole(ROLE_PRODUCER, <producerAddress>)` / `grantRole(ROLE_TREASURY, <treasuryAddress>)` as needed.
2. (Optional, once confident) Remove direct EOAs:
   - Migrate roles from EOAs to multisig addresses.
   - Use `revokeRole` on old EOAs after verifying multisig control.

Record chosen addresses and role assignments in your internal ops documentation.

---

### 5. Verification & Regression Checklist

After each Sepolia deployment:

1. **Contracts verified** on Arbiscan:
   - `BVPToken`
   - `BVPStaking`
   - (Later) `ProductionVault`, `GasRouter`, `LineItemRegistry`, `VendorPayment`.
2. **Smoke tests** on Sepolia:
   - Transfer a small amount of BVP between two test wallets.
   - Stake and unstake a small amount with `BVPStaking`.
3. **Logs monitoring (basic)**:
   - Confirm expected events (`Transfer`, `Staked`, etc.) appear on Arbiscan.
4. **Update internal docs**:
   - Copy new addresses into any off-chain configs or integration environments.

This runbook is focused on Sepolia; for Arbitrum mainnet, repeat with stricter role holders (multisig only) and a full external audit completed beforehand.


