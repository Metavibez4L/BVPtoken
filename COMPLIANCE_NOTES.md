## Compliance & Risk Notes (Non-Legal Summary)

> This document is **not** legal advice. It is a technical summary to help bridge between the smart contracts and your compliance/legal teams.

### Token & Staking Model

- `BVPToken`:
  - Fixed supply and no on-chain mint/burn controls.
  - No built-in blacklisting, whitelisting, or KYC/AML checks.
- `BVPStaking`:
  - Staking is for **access and experiences only**, not yield.
  - No interest, rewards, or emissions; users simply lock BVP for tiered perks.

### Operational Flows

- Production funding:
  - `ProductionVault` and `VendorPayment` move BVP between studio-owned wallets and vendors/partners.
  - Fine-grained budget controls are enforced by `LineItemRegistry`, but KYC/AML on recipients remains an off-chain responsibility.
- Gas and fee routing:
  - `GasRouter` collects gas/fees in BVP and routes them to a treasury wallet.

### Off-Chain Responsibilities

Areas that must be handled off-chain or in higher layers:

- KYC/AML for investors, counterparties, and vendors.
- Sanctions screening and restricted jurisdictions.
- Tax reporting and characterization of BVP (utility vs. other classifications).
- Any regulatory filings or approvals related to token sales or profit-sharing.

### On-Chain Configuration That May Reflect Compliance Decisions

- Choice of allocation wallets for `BVPToken` (e.g., sale contracts, treasury, reserves).
- Role assignments for:
  - `ROLE_ADMIN`, `ROLE_PRODUCER`, `ROLE_TREASURY` (may map to regulated entities or supervised signers).
- Optional L2/L3 whitelisting or gating at higher layers (e.g., frontends or gateways that restrict who can interact with certain contracts).

### Suggested Collaboration Steps

1. Share `ARCHITECTURE.md`, `GOVERNANCE.md`, and this file with legal/compliance.
2. Confirm:
   - Whether any additional on-chain controls (whitelists, caps, jurisdiction filters) are required.
   - Whether specific disclosures must be reflected in user-facing UIs and terms of service.
3. Reflect those decisions in:
   - Deployment choices (e.g., which addresses hold admin roles).
   - Off-chain onboarding flows and frontends.


