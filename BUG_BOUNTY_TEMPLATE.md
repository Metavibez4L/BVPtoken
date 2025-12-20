## BVP Core Contracts Bug Bounty (Template)

> This is a template for a **testnet-focused** bug bounty program on the
> Arbitrum Sepolia deployment of BVP core contracts. Fill in reward amounts,
> dates, and program links before launch.

### 1. Scope

- **Networks**
  - Arbitrum Sepolia (testnet)
- **In-scope contracts (core only)**
  - `BVPToken` – address from `deployments/arbitrum-sepolia.json`
  - `BVPStaking` – address from `deployments/arbitrum-sepolia.json`
  - `Lock` – any deployed instances explicitly listed by the team

Subchain / operational contracts (`ProductionVault`, `GasRouter`, etc.) are
**out of scope** for this bounty and should be covered under a separate program.

### 2. Objectives

- Identify vulnerabilities that could:
  - Break token economics (cap, allocations, anti-whale limits).
  - Cause loss of staked funds or incorrect unlock/unstake behavior.
  - Violate documented invariants (see `SECURITY_ANALYSIS.md`).

### 3. Severity & Rewards (To Be Filled In)

- Critical: _[define reward range]_  
- High: _[define reward range]_  
- Medium: _[define reward range]_  
- Low / Informational: _[define policy]_  

Reward decisions should be based on:
- Impact (funds at risk, irreversible state changes).
- Exploitability (on-chain only vs. requiring off-chain conditions).

### 4. Reporting Process

- Preferred channels:
  - Email: `security@bigvisionpictures.io`
  - (Optional) Bug bounty platform link (Immunefi, HackenProof, etc.)
- Report contents:
  - Network and contract address.
  - PoC transactions or scripts.
  - Clear explanation of impact and exploit path.

### 5. Out of Scope

- Issues that require:
  - Compromised private keys.
  - Malicious or misconfigured frontends.
  - Third-party infrastructure failures (RPC nodes, indexers).
- Purely informational findings already documented as accepted risks in
  `SECURITY_ANALYSIS.md` §8.

### 6. Program Timeline

- Start date: _[YYYY-MM-DD]_  
- End date (if any): _[YYYY-MM-DD]_  
- Review SLA: _[e.g., initial triage within 5 business days]_  


