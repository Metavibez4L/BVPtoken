## External Audit Runbook (Core Contracts Only)

This runbook complements `AUDIT_PREP.md` and narrows the scope to the **core**
L2 contracts for this plan:

- `contracts/BVPToken.sol`
- `contracts/BVPStaking.sol`
- `contracts/Lock.sol`

Subchain contracts under `subchain/` should be handled under a separate audit
phase and are out of scope here.

---

### 1. Snapshot & Code Freeze

1. Create a git tag for the audit snapshot, e.g.:
   - `git tag core-audit-v1 && git push origin core-audit-v1`
2. No functional changes to `contracts/` after this tag until audit is complete,
   except for auditor-requested fixes.

---

### 2. Build & Test Commands (Core)

From `BVPtoken/`:

```bash
npm install
npm run compile
npm test

# Optional, requires Foundry:
forge test -vv
```

These commands should pass without failures or unexpected warnings before code
is sent to auditors.

> For the full test matrix (including subchain tests, coverage, and Windows/WSL notes), see `TESTING.md`.

---

### 3. Static Analysis

Assuming Slither/Mythril are installed globally:

```bash
npm run slither          # wrapper around: slither . --filter-paths 'lib|node_modules|out|hh-artifacts'
npm run mythril:token    # myth analyze contracts/BVPToken.sol
npm run mythril:staking  # myth analyze contracts/BVPStaking.sol
npm run mythril:lock     # myth analyze contracts/Lock.sol
```

Include any non-trivial findings, plus your assessment, in the audit
submission package.

Notes:
- On Windows, Slither is typically easiest to run from WSL. See `TESTING.md` for recommended commands.

---

### 4. Artifacts & Documentation for Auditors

Provide auditors with:

- Source tree:
  - `contracts/BVPToken.sol`
  - `contracts/BVPStaking.sol`
  - `contracts/Lock.sol`
  - `test/` (core tests) for reference.
- Key docs:
  - `ARCHITECTURE.md`
  - `SECURITY_ANALYSIS.md`
  - `SECURITY_SUMMARY.md`
  - `SECURITY_CHECKLIST.md`
  - `INTEGRATION.md` (for expected usage patterns).
- Invariants:
  - As listed in `AUDIT_PREP.md` and `SECURITY_ANALYSIS.md`.

---

### 5. Handling Findings

1. Triage each finding by severity (Critical/High/Medium/Low/Info).
2. For any required code changes:
   - Implement fixes on a dedicated branch.
   - Re-run tests and static analysis.
   - If changes are large, schedule a differential re-audit.
3. Update:
   - `SECURITY_ANALYSIS.md` with a brief summary of findings and fixes.
   - `SECURITY_CHECKLIST.md` §9 once the audit is complete and published.

---

### 6. Post-Audit

1. Publish:
   - Final audit report (PDF or link).
   - Short summary in `SECURITY_SUMMARY.md`.
2. Confirm:
   - The audited commit/tag matches what will be deployed to Arbitrum mainnet.
3. Proceed to mainnet deployment following `DEPLOYMENT_MAINNET.md` and
   `SECURITY_CHECKLIST.md`.


