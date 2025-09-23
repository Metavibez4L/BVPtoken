// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice Capped ERC20 with fixed genesis allocations, anti-whale limits, split exclusion lists, and EIP-2612.
/// @dev No burn functionality is exposed (no ERC20Burnable; `_burn` never called).
contract BVPToken is ERC20, ERC20Capped, ERC20Permit, Ownable2Step {
    // ---------- Limits ----------
    uint256 public immutable maxTx;
    uint256 public immutable maxWallet;

    // ---------- Exclusions (split) ----------
    mapping(address => bool) public isTxLimitExcluded;      // sender-based tx limit bypass
    mapping(address => bool) public isWalletLimitExcluded;  // recipient-based wallet cap bypass

    // For transparent enumeration in UIs (we don't compact; we filter on read)
    address[] private _txExclusionBook;
    address[] private _walletExclusionBook;

    // ---------- Events ----------
    event TxLimitExclusionUpdated(address indexed account, bool isExcluded);
    event WalletLimitExclusionUpdated(address indexed account, bool isExcluded);

    // ---------- Errors ----------
    error ZeroAddress();

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
        ERC20Capped(1_000_000_000 ether)
        ERC20Permit("Big Vision Pictures Token")
    {
        // Basic input hygiene (defense-in-depth)
        if (
            publicSale_ == address(0) ||
            operations_ == address(0) ||
            presale_ == address(0) ||
            foundersAndTeam_ == address(0) ||
            marketing_ == address(0) ||
            advisors_ == address(0) ||
            treasury_ == address(0) ||
            liquidity_ == address(0)
        ) revert ZeroAddress();

        // Anti-whale limits
        maxTx = 10_000_000 ether;     // 1% of cap per tx
        maxWallet = 20_000_000 ether; // 2% of cap per wallet

        // Genesis allocations (sum = 100% of cap)
        _mint(publicSale_,       cap() * 30 / 100);
        _mint(operations_,       cap() * 20 / 100);
        _mint(presale_,          cap() * 10 / 100);
        _mint(foundersAndTeam_,  cap() * 10 / 100);
        _mint(marketing_,        cap() * 15 / 100);
        _mint(advisors_,         cap() * 5  / 100);
        _mint(treasury_,         cap() * 5  / 100);
        _mint(liquidity_,        cap() * 5  / 100);

        // Sensible defaults: let operational wallets bypass limits to avoid dead-ends.
        _setTxLimitExcluded(publicSale_, true);
        _setTxLimitExcluded(operations_, true);
        _setTxLimitExcluded(treasury_,  true);
        _setTxLimitExcluded(liquidity_, true);

        _setWalletLimitExcluded(publicSale_, true);
        _setWalletLimitExcluded(operations_, true);
        _setWalletLimitExcluded(treasury_,  true);
        _setWalletLimitExcluded(liquidity_, true);

        // Ownable2Step initial owner = deployer (handoff to multisig/timelock recommended)
        _transferOwnership(msg.sender);
    }

    // ----------
    // Admin (owner)
    // ----------

    /// @notice Update tx-limit exclusion for an account (owner only).
    function setTxLimitExcluded(address account, bool excluded) external onlyOwner {
        _setTxLimitExcluded(account, excluded);
    }

    /// @notice Update wallet-limit exclusion for an account (owner only).
    function setWalletLimitExcluded(address account, bool excluded) external onlyOwner {
        _setWalletLimitExcluded(account, excluded);
    }

    /// @notice Safer ownership transfer (defense-in-depth): disallow zero address as pending owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        super.transferOwnership(newOwner);
    }

    // ----------
    // Views (enumeration helpers for UIs)
    // ----------

    /// @notice Enumerate current tx-limit excluded accounts (filtered by live mapping).
    function getTxLimitExcluded() external view returns (address[] memory live) {
        uint256 n;
        for (uint256 i = 0; i < _txExclusionBook.length; i++) {
            if (isTxLimitExcluded[_txExclusionBook[i]]) n++;
        }
        live = new address[](n);
        uint256 k;
        for (uint256 i = 0; i < _txExclusionBook.length; i++) {
            address a = _txExclusionBook[i];
            if (isTxLimitExcluded[a]) live[k++] = a;
        }
    }

    /// @notice Enumerate current wallet-limit excluded accounts (filtered by live mapping).
    function getWalletLimitExcluded() external view returns (address[] memory live) {
        uint256 n;
        for (uint256 i = 0; i < _walletExclusionBook.length; i++) {
            if (isWalletLimitExcluded[_walletExclusionBook[i]]) n++;
        }
        live = new address[](n);
        uint256 k;
        for (uint256 i = 0; i < _walletExclusionBook.length; i++) {
            address a = _walletExclusionBook[i];
            if (isWalletLimitExcluded[a]) live[k++] = a;
        }
    }

    // ----------
    // Internal helpers
    // ----------

    function _setTxLimitExcluded(address account, bool excluded) internal {
        if (isTxLimitExcluded[account] != excluded) {
            isTxLimitExcluded[account] = excluded;
            emit TxLimitExclusionUpdated(account, excluded);
        } else {
            // still emit to reflect admin intent (useful for off-chain sync)
            emit TxLimitExclusionUpdated(account, excluded);
        }
        if (_notSeenInBook(_txExclusionBook, account)) {
            _txExclusionBook.push(account);
        }
    }

    function _setWalletLimitExcluded(address account, bool excluded) internal {
        if (isWalletLimitExcluded[account] != excluded) {
            isWalletLimitExcluded[account] = excluded;
            emit WalletLimitExclusionUpdated(account, excluded);
        } else {
            emit WalletLimitExclusionUpdated(account, excluded);
        }
        if (_notSeenInBook(_walletExclusionBook, account)) {
            _walletExclusionBook.push(account);
        }
    }

    function _notSeenInBook(address[] storage book, address account) private view returns (bool) {
        for (uint256 i = 0; i < book.length; i++) {
            if (book[i] == account) return false;
        }
        return true;
    }

    // ----------
    // Transfer rules (anti-whale)
    // ----------

    /// @dev Enforces anti-whale limits on regular transfers:
    ///      - Enforce maxTx unless sender is tx-excluded
    ///      - Enforce maxWallet on recipient unless recipient is wallet-excluded
    ///      - Mints/Burns are not subject to limits (no burn paths exposed)
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        // skip checks for mints/burns
        if (from == address(0) || to == address(0)) return;

        // Max TX: check unless sender is excluded
        if (!isTxLimitExcluded[from]) {
            require(amount <= maxTx, "TX_LIMIT");
        }

        // Max Wallet: enforce on recipient unless recipient is excluded
        if (!isWalletLimitExcluded[to]) {
            require(balanceOf(to) + amount <= maxWallet, "WALLET_LIMIT");
        }
    }

    // ----------
    // Inheritance plumbing
    // ----------

    /// @dev Required by Solidity because ERC20Capped overrides ERC20._mint.
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
