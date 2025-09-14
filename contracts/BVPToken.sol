// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, fixed allocations, and anti-whale limits.
/// @dev Changes vs previous version:
///  - Correct anti-whale semantics:
///      • Enforce maxTx unless *sender* is tx-excluded
///      • Enforce maxWallet on *recipient* unless recipient is wallet-excluded
///  - Split exclusion sets: isTxLimitExcluded / isWalletLimitExcluded
///  - Events on exclusion changes + enumerable getters
///  - Use Ownable2Step (safer owner transfer)
///  - Add ERC20Permit (EIP-2612)
contract BVPToken is ERC20Capped, ERC20Permit, Ownable2Step {
    // ---- Limits ----
    uint256 public immutable maxTx;
    uint256 public immutable maxWallet;

    // ---- Exclusions (split) ----
    mapping(address => bool) public isTxLimitExcluded;
    mapping(address => bool) public isWalletLimitExcluded;

    // For transparent enumeration in UIs (read helpers build filtered lists)
    address[] private _txExclusionBook;
    address[] private _walletExclusionBook;

    // ---- Events ----
    event TxLimitExclusionUpdated(address indexed account, bool isExcluded);
    event WalletLimitExclusionUpdated(address indexed account, bool isExcluded);

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
        ERC20Capped(1_000_000_000 * 1e18)
        ERC20Permit("Big Vision Pictures Token")
    {
        // Limits (unchanged values)
        maxTx = 10_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;

        // Mint allocations at deploy
        _mint(publicSale_,       cap() * 30 / 100);
        _mint(operations_,       cap() * 20 / 100);
        _mint(presale_,          cap() * 10 / 100);
        _mint(foundersAndTeam_,  cap() * 10 / 100);
        _mint(marketing_,        cap() * 15 / 100);
        _mint(advisors_,         cap() * 5  / 100);
        _mint(treasury_,         cap() * 5  / 100);
        _mint(liquidity_,        cap() * 5  / 100);

        // Initialize sensible defaults:
        // - Public sale, ops, treasury, liquidity often need operational freedom.
        // - Exempt them from both tx and wallet limits to avoid operational dead-ends.
        _setTxLimitExcluded(publicSale_, true);
        _setTxLimitExcluded(operations_, true);
        _setTxLimitExcluded(treasury_,  true);
        _setTxLimitExcluded(liquidity_, true);

        _setWalletLimitExcluded(publicSale_, true);
        _setWalletLimitExcluded(operations_, true);
        _setWalletLimitExcluded(treasury_,  true);
        _setWalletLimitExcluded(liquidity_, true);

        // Set initial owner to deployer (Ownable2Step)
        _transferOwnership(msg.sender);
    }

    // -----------------------------
    // Exclusions: admin (owner)
    // -----------------------------

    /// @notice Update tx-limit exclusion for an account (owner only).
    function setTxLimitExcluded(address account, bool excluded) external onlyOwner {
        _setTxLimitExcluded(account, excluded);
    }

    /// @notice Update wallet-limit exclusion for an account (owner only).
    function setWalletLimitExcluded(address account, bool excluded) external onlyOwner {
        _setWalletLimitExcluded(account, excluded);
    }

    function _setTxLimitExcluded(address account, bool excluded) internal {
        if (isTxLimitExcluded[account] == excluded) {
            emit TxLimitExclusionUpdated(account, excluded); // still emit to reflect admin intent
            return;
        }
        isTxLimitExcluded[account] = excluded;
        // track for enumeration (store once)
        if (_notSeenInBook(_txExclusionBook, account)) {
            _txExclusionBook.push(account);
        }
        emit TxLimitExclusionUpdated(account, excluded);
    }

    function _setWalletLimitExcluded(address account, bool excluded) internal {
        if (isWalletLimitExcluded[account] == excluded) {
            emit WalletLimitExclusionUpdated(account, excluded);
            return;
        }
        isWalletLimitExcluded[account] = excluded;
        if (_notSeenInBook(_walletExclusionBook, account)) {
            _walletExclusionBook.push(account);
        }
        emit WalletLimitExclusionUpdated(account, excluded);
    }

    function _notSeenInBook(address[] storage book, address account) private view returns (bool) {
        // Dedup only on first insert; we don't compact on removal.
        // Getters build filtered lists based on the current mapping flags.
        for (uint256 i = 0; i < book.length; i++) {
            if (book[i] == account) return false;
        }
        return true;
    }

    /// @notice Enumerate current tx-limit excluded accounts (filtered).
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

    /// @notice Enumerate current wallet-limit excluded accounts (filtered).
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

    // -----------------------------
    // Transfer rules (anti-whale)
    // -----------------------------

    /// @dev Enforces anti-whale limits on regular transfers:
    ///      - Enforce maxTx unless sender is tx-excluded
    ///      - Enforce maxWallet on recipient unless recipient is wallet-excluded
    ///      - Mints/burns are not subject to limits
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // Ignore mints/burns
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

    // -----------------------------
    // Solidity inheritance plumbing
    // -----------------------------

    // ERC20Capped caps minting; ERC20Permit adds permits; no conflicting hooks in OZ 4.9.x
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
