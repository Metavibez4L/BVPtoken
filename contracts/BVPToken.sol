// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, fixed allocations, EIP-2612 permits, and anti-whale limits.
/// @dev Decentralized/no-admin: there are **no** owner roles or setters. Exclusions are fixed at deploy.
///      No burn: does not include ERC20Burnable and provides no burn path.
contract BVPToken is ERC20, ERC20Capped, ERC20Permit {
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
        // Set anti-whale ceilings (can tune constants here, they are immutable after deploy)
        maxTx = 10_000_000 ether;     // 10,000,000 BVP
        maxWallet = 20_000_000 ether; // 20,000,000 BVP

        // ---- Initial allocations (sum to 100% of cap) ----
        _mint(publicSale_,       cap() * 30 / 100);
        _mint(operations_,       cap() * 20 / 100);
        _mint(presale_,          cap() * 10 / 100);
        _mint(foundersAndTeam_,  cap() * 10 / 100);
        _mint(marketing_,        cap() * 15 / 100);
        _mint(advisors_,         cap() *  5 / 100);
        _mint(treasury_,         cap() *  5 / 100);
        _mint(liquidity_,        cap() *  5 / 100);

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

        // Skip checks for mint/burn
        if (from == address(0) || to == address(0)) {
            return;
        }

        // Per-transfer ceiling
        if (!isTxLimitExcluded[from]) {
            require(amount <= maxTx, "TX_LIMIT");
        }

        // Per-wallet holding ceiling (post-transfer balance)
        if (!isWalletLimitExcluded[to]) {
            require(balanceOf(to) + amount <= maxWallet, "WALLET_LIMIT");
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
