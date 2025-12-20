## Developer Integration Guide

### Contract Addresses (Example: Arbitrum Sepolia)

For the latest deployed addresses, see `deployments/arbitrum-sepolia.json`. Example fields:

- `contracts.BVPToken.address`
- `contracts.BVPStaking.address`

In production, you should maintain similar deployment files per network and load them into your client apps or scripts.

### BVPToken

- Standard ERC-20 interface with:
  - `cap()`: returns max supply.
  - `maxTx()`: per-transfer limit.
  - `maxWallet()`: per-address holding limit.
  - `isTxLimitExcluded(address)` / `isWalletLimitExcluded(address)`.
- EIP-2612 permit:
  - `permit(owner, spender, value, deadline, v, r, s)`.
  - `nonces(owner)` and `DOMAIN_SEPARATOR()` follow the standard.

**Usage tips**

- Handle `TX_LIMIT` and `WALLET_LIMIT` revert strings when building frontends or off-chain services.
- For large operational movements, use the exempted wallets documented in `ARCHITECTURE.md`.

### BVPStaking

- Core methods:
  - `stake3Months(amount)`, `stake6Months(amount)`, `stake12Months(amount)`.
  - `unlock()`, `unstake()`.
  - `getStake(user)` → `(amount, timestamp, lockTime, unlocked, unlockAt)`.
  - `getTierCode(user)` / `getTierName(user)`.

**Usage tips**

- Enforce UX that explains lock periods and non-yield staking.
- Do not attempt multiple concurrent stakes for the same user address.

### ProductionVault

- Project lifecycle:
  - `createProject(id, title, totalBudget, milestones[], producer, approvers[])` (admin only).
  - `approveMilestone(id)` (approvers only, 2-of-N).
  - `cancelProject(id)` (admin).
  - `withdrawRemaining(id)` (producer, after cancellation).
- Views:
  - `getProjectSummary(id)` and `getMilestones(id)`, `getApprovers(id)`.

**Usage tips**

- `id` should be a deterministic hash (e.g., `keccak256(abi.encodePacked(slug))`) generated off-chain.
- Ensure UI surfaces project status (active / canceled / all milestones complete).

### GasRouter

- `prepayGas(user, gasUsed)`: charges BVP from `user` and forwards to `treasury`.
- Admin methods:
  - `setTreasury(newTreasury)`.
  - `setGasPrice(newPrice)`.

**Usage tips**

- Off-chain services should calculate `gasUsed` honestly and align with on-chain `gasUnitPrice`.
- Monitor `GasPaid` events for accounting.

### LineItemRegistry & VendorPayment

- `LineItemRegistry`:
  - `addLineItem(projectId, accountCode, description, budgeted)` (admin).
  - `recordPayment(projectId, accountCode, vendor, amount)` (producer).
- `VendorPayment`:
  - `queuePayment(projectId, accountCode, recipient, amount)` (producer).
  - `executePayment(paymentId)` (treasury).

**Usage tips**

- Typical flow:
  1. Budget line items defined in `LineItemRegistry`.
  2. Vendor payments are queued in `VendorPayment`.
  3. On execution, the registry is updated and BVP is transferred.
- Use events and the registry state to drive back-office reporting and compliance checks.

---

## Example Code Snippets (Sepolia)

Assume you have loaded addresses from `deployments/arbitrum-sepolia.json` and are using **ethers v6**.

### Ethers setup

```ts
import { ethers } from "ethers";
import deployment from "./deployments/arbitrum-sepolia.json";
import BVPTokenAbi from "./hh-artifacts/contracts/BVPToken.sol/BVPToken.json";
import BVPStakingAbi from "./hh-artifacts/contracts/BVPStaking.sol/BVPStaking.json";

const provider = new ethers.JsonRpcProvider(process.env.ARB_SEPOLIA_RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

const token = new ethers.Contract(
  deployment.contracts.BVPToken.address,
  BVPTokenAbi.abi,
  wallet
);

const staking = new ethers.Contract(
  deployment.contracts.BVPStaking.address,
  BVPStakingAbi.abi,
  wallet
);
```

### Staking (happy path)

```ts
// Approve tokens and stake 100,000 BVP for 3 months
const amount = ethers.parseUnits("100000", 18);

await token.approve(staking.target, amount);
await staking.stake3Months(amount);
```

### Handling staking errors (UX)

Common revert messages:

- `"Zero amount"` – user entered `0` or too small.
- `"Already staked"` – user has an active stake.
- `"Still locked"` – user attempted `unlock()` early.
- `"No stake"` / `"Not unlocked"` – wrong sequence of actions.

Frontends should map these to clear messages, e.g.:

- “You already have an active stake. Unstake before staking again.”
- “Your lock period has not finished yet.”

### ProductionVault: creating and approving a project

```ts
import ProductionVaultAbi from "./subchain/out/ProductionVault.sol/ProductionVault.json";

const vault = new ethers.Contract(
  "0x...vaultAddressOnSepolia",
  ProductionVaultAbi.abi,
  wallet
);

// Admin creates a project
const id = ethers.keccak256(ethers.toUtf8Bytes("project1"));
const milestones = [
  ethers.parseUnits("300", 18),
  ethers.parseUnits("700", 18),
];
const approvers = ["0xApprover1", "0xApprover2"];

await vault.createProject(
  id,
  "Test Project",
  ethers.parseUnits("1000", 18),
  milestones,
  "0xProducer",
  approvers
);

// Approver confirms milestone
const approverSigner = wallet.connect(provider); // replace with approver key
const vaultAsApprover = vault.connect(approverSigner);
await vaultAsApprover.approveMilestone(id);
```

### VendorPayment: queue and execute

```ts
import VendorPaymentAbi from "./subchain/out/VendorPayment.sol/VendorPayment.json";

const vendorPayment = new ethers.Contract(
  "0x...vendorPaymentAddressOnSepolia",
  VendorPaymentAbi.abi,
  wallet
);

// Producer queues a payment
const projectId = ethers.keccak256(ethers.toUtf8Bytes("project1"));
const accountCode = 401; // e.g., Principal Cast
const recipient = "0xVendor";
const paymentAmount = ethers.parseUnits("100", 18);

await vendorPayment.queuePayment(projectId, accountCode, recipient, paymentAmount);

// Treasury executes a payment
await vendorPayment.executePayment(0n); // first queued payment
```

---

## UX Guidelines (Sepolia & Mainnet)

### Staking

- Clearly state:
  - Lock durations (3, 6, 12 months) and that funds are **illiquid** until unlock + unstake.
  - Staking provides **access/tiers only**, not yield or rewards.
- Show:
  - User’s current tier, staked amount, and exact unlock timestamp.
  - An explicit confirmation step before staking.

### Token limits

- When `TX_LIMIT` or `WALLET_LIMIT` reverts:
  - Explain that large transfers or holdings are capped to discourage concentration.
  - Offer tools to split transfers or reduce amounts.

### Production funding

- For each project, display:
  - Total budget, amount released, and remaining.
  - Current milestone index and status (pending/approved/released).
  - Cancelled status and any remaining budget withdrawn.

### Vendor payments

- Surface:
  - Whether a payment is queued vs executed.
  - The project and line item the payment is associated with.
  - Expected execution cadence (e.g., “executed by treasury within N hours/days”).



