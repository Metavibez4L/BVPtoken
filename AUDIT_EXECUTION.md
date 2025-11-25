## External Audit Execution Plan

This document builds on `AUDIT_PREP.md` and focuses on how to **run** the audit process.

---

### 1. Audit Package for Firms

Prepare a single bundle (zip or shared folder) containing:

- `ARCHITECTURE.md` – overall system design and trust assumptions.
- `GOVERNANCE.md` – roles, upgradeability stance, and pausing controls.
- `AUDIT_PREP.md` – scope, invariants, build/test commands.
- `MONITORING.md` – how you plan to detect issues post-deploy.
- `deployments/arbitrum-sepolia.json` – current testnet addresses.
- A short **README for auditors** summarizing:
  - Intended networks: Arbitrum Sepolia (staging), Arbitrum mainnet (later).
  - Which contracts are immutable (`BVPToken`, `BVPStaking`) vs governed.
  - Non-goals (no on-chain KYC/AML, etc.).

---

### 2. Candidate Auditor Shortlist

When evaluating firms, prefer those who:

- Have **recent Arbitrum or L2 experience**, ideally with funding/staking or vault-style contracts.
- Provide **public reports** you can review for quality and thoroughness.
- Offer:
  - Clear methodology (manual review + tooling).
  - Reasonable timeline (e.g., 2–4 weeks for this scope).
  - Post-audit support (question time, differential review).

Suggested selection steps:

1. Identify 3–5 candidate firms.
2. Send each the package with:
   - Desired start date range.
   - Networks and target launch window.
   - Any constraints (e.g., budget range).
3. Compare:
   - Team composition and experience.
   - Proposed hours and depth.
   - Deliverables (report format, severity model).

---

### 3. Timeline Template

Assuming a **mainnet launch** is gated on audit completion:

1. **T-8 weeks**: Feature freeze for audited scope.
   - Only bug fixes and minor refactors allowed.
   - Tag commit/branch to be audited.
2. **T-7 to T-5 weeks**: Audit window (1–3 weeks).
   - Auditors run through code, ask clarifying questions.
   - Core devs are available for quick responses.
3. **T-5 to T-3 weeks**: Fix window.
   - Address findings by severity.
   - Add regression tests for each issue.
   - Optionally request a **differential review** on changed files.
4. **T-3 to T-1 weeks**: Stabilization.
   - No functional changes to audited contracts.
   - Ops rehearses deployments and role assignments.
5. **Launch window**: Arbitrum mainnet deployment.
   - Use the same artefacts and config that were audited.

Sepolia deployments can continue to be used for rehearsals and UX testing, but audited contracts should not diverge materially from the audited branch.

---

### 4. Post-Audit Follow-Up

For each finding:

- Track fields: severity, description, status, owner, fix PR, and test coverage.
- Include a brief **risk acceptance** rationale for any issues not fixed (if any).
- Publish a summarized version (or full report) for transparency once you’re ready.


