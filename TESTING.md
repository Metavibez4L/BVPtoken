## Testing Guide

This repo has **two primary test suites**:

- **Hardhat (TypeScript) tests** live in `hardhat-tests/` and run via `npm test`
- **Foundry (Solidity) tests** live in `test/` and run via `forge test`

If you work on Windows, it’s common to run **Hardhat in Windows** and **Foundry/Slither in WSL**.

---

### Quick start (recommended)

From the repo root:

```bash
npm install
npm test
```

From a WSL shell in the repo root (e.g. `/mnt/c/.../BVPtoken`):

```bash
forge test
```

---

### Hardhat tests (JavaScript/TypeScript)

- **Run all Hardhat tests**

```bash
npm test
```

- **Compile only**

```bash
npm run compile
```

Notes:
- Hardhat is configured to load tests from `hardhat-tests/` (see `hardhat.config.ts`).

---

### Foundry tests (Solidity)

- **Run all Foundry tests (root)**

```bash
forge test
```

- **Verbose**

```bash
forge test -vv
```

- **Run subchain tests**

```bash
cd subchain && forge test -vv && cd ..
```

Notes:
- Foundry is configured via `foundry.toml` (root) and `subchain/foundry.toml` (subchain).

---

### Coverage

- **Hardhat coverage**

```bash
npm run coverage
```

(Foundry coverage is optional; this repo primarily uses Hardhat’s `solidity-coverage` output under `coverage/`.)

---

### Static analysis (Slither)

Slither is recommended to run in **WSL/Linux**.

- **Install (WSL)**

```bash
python3 -m pip install --user slither-analyzer
```

- **Run on core contracts only (recommended)**

```bash
slither contracts --exclude-dependencies
```

- **Run on a single contract**

```bash
slither contracts/BVPToken.sol
```

---

### Common gotchas

- **Windows + Slither**: many commands in docs assume a POSIX shell; on Windows prefer WSL for Slither/Foundry.
- **Foundry toolchain**: `forge` must be installed (see Foundry book). If `forge` isn’t found, install Foundry and ensure it’s on your PATH.


