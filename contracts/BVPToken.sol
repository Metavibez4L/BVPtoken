// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, fixed initial allocations, EIP-2612 permits, and anti-whale limits.
/// @dev Production configuration:
///      - Supply is capped at 1,000,000,000 BVP and fully minted at deployment.
///      - There are **no** owner/admin roles or setters; behaviour is immutable once deployed.
///      - Anti-whale limits are encoded as:
///          maxTx    = 1% of total supply  (10,000,000 BVP)
///          maxWallet = 2% of total supply (20,000,000 BVP)
///      - Exemptions from these limits are fixed at construction time only.
///      - No burn: does not include ERC20Burnable and provides no burn path.
///
/// @custom:security-contact security@bigvisionpictures.io
/// @custom:security-assumptions
///      - Immutability is intentional: no emergency stop, no parameter updates, no upgrade path
///      - Excluded addresses should be controlled by multisig or secure key management
///      - Total supply cannot exceed cap() due to ERC20Capped parent enforcement
///      - Balance overflow impossible: sum of all balances <= cap() < type(uint256).max
/// @custom:invariants
///      - totalSupply() == cap() (all tokens minted at deployment)
///      - totalSupply() <= type(uint256).max (enforced by ERC20)
///      - For non-excluded sender: transfer amount <= maxTx
///      - For non-excluded recipient: post-transfer balance <= maxWallet
contract BVPToken is ERC20, ERC20Capped, ERC20Permit {
    // ---- Custom Errors (gas-optimized) ----
    error TransferExceedsLimit();
    error WalletExceedsLimit();
    // ---- Limits (immutable after deploy) ----
    uint256 public immutable maxTx;     // per-transfer ceiling
    uint256 public immutable maxWallet; // per-wallet holding ceiling

    // ---- Exclusions (fixed at deploy; no mutability) ----
    mapping(address => bool) public isTxLimitExcluded;     // sender bypasses maxTx
    mapping(address => bool) public isWalletLimitExcluded; // recipient bypasses maxWallet

    /// @param publicSale_        allocation recipient (30%)
    /// @param operations_        allocation recipient (20%)
    /// @param presale_           allocation recipient (10%)
    /// @param foundersAndTeam_   allocation recipient (10%)
    /// @param marketing_         allocation recipient (15%)
    /// @param advisors_          allocation recipient (5%)
    /// @param treasury_          allocation recipient (5%)
    /// @param liquidity_         allocation recipient (5%) – typically LP/AMM wallet
    constructor(
        address publicSale_,
        address operations_,
        address presale_,
        address foundersAndTeam_,
        address marketing_,
        address advisors_,
        address treasury_,
        address liquidity_
    )
        ERC20("Big Vision Pictures Token", "BVP")
        ERC20Capped(1_000_000_000 ether)               // 1,000,000,000 * 1e18
        ERC20Permit("Big Vision Pictures Token")
    {
        // Set anti-whale ceilings (immutable after deploy; see README/ARCHITECTURE for rationale)
        maxTx = 10_000_000 ether;     // 10,000,000 BVP  (1% of total supply)
        maxWallet = 20_000_000 ether; // 20,000,000 BVP  (2% of total supply)

        // Cache cap for gas savings (called 8 times below)
        uint256 _cap = cap();

        // ---- Initial allocations (sum to 100% of cap) ----
        // Using unchecked: all divisions are safe (cap is 1B * 1e18, divisors are 100)
        unchecked {
            _mint(publicSale_,       _cap * 30 / 100);
            _mint(operations_,       _cap * 20 / 100);
            _mint(presale_,          _cap * 10 / 100);
            _mint(foundersAndTeam_,  _cap * 10 / 100);
            _mint(marketing_,        _cap * 15 / 100);
            _mint(advisors_,         _cap *  5 / 100);
            _mint(treasury_,         _cap *  5 / 100);
            _mint(liquidity_,        _cap *  5 / 100);
        }

        // ---- Fixed exclusions (no setters; encoded policy) ----
        // Liquidity/operational wallets often need to bypass maxTx & maxWallet.
        isTxLimitExcluded[publicSale_] = true;
        isTxLimitExcluded[operations_] = true;
        isTxLimitExcluded[treasury_]   = true;
        isTxLimitExcluded[liquidity_]  = true;

        isWalletLimitExcluded[publicSale_] = true;
        isWalletLimitExcluded[operations_] = true;
        isWalletLimitExcluded[treasury_]   = true;
        isWalletLimitExcluded[liquidity_]  = true;
    }

    // -----------------------------
    // Anti-whale enforcement
    // -----------------------------
    /// @dev Enforce:
    ///      - maxTx on the *sender* unless sender is tx-excluded
    ///      - maxWallet on the *recipient* unless recipient is wallet-excluded
    ///      - mints/burns are not subject to limits (no burn path provided in this contract)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // Skip checks for mint/burn (single check for both)
        if (from == address(0) || to == address(0)) return;

        // Per-transfer ceiling
        if (!isTxLimitExcluded[from] && amount > maxTx) {
            revert TransferExceedsLimit();
        }

        // Per-wallet holding ceiling (post-transfer balance)
        // Note: balanceOf(to) + amount cannot overflow due to capped supply
        if (!isWalletLimitExcluded[to]) {
            unchecked {
                if (balanceOf(to) + amount > maxWallet) {
                    revert WalletExceedsLimit();
                }
            }
        }
    }

    // -----------------------------
    // Required override for ERC20 + ERC20Capped
    // -----------------------------
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
