// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, anti-whale TX/wallet limits, and fixed allocation
contract BVPToken is ERC20Capped {
    uint256 public immutable MAX_TX;
    uint256 public immutable MAX_WALLET;

    mapping(address => bool) public isExcludedFromLimits;

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
    {
        MAX_TX = 10_000_000 * 1e18;
        MAX_WALLET = 20_000_000 * 1e18;

        _update(address(0), publicSale_, cap() * 30 / 100);
        _update(address(0), operations_, cap() * 20 / 100);
        _update(address(0), presale_, cap() * 10 / 100);
        _update(address(0), foundersAndTeam_, cap() * 10 / 100);
        _update(address(0), marketing_, cap() * 15 / 100);
        _update(address(0), advisors_, cap() * 5 / 100);
        _update(address(0), treasury_, cap() * 5 / 100);
        _update(address(0), liquidity_, cap() * 5 / 100);

        isExcludedFromLimits[publicSale_] = true;
        isExcludedFromLimits[operations_] = true;
        isExcludedFromLimits[liquidity_] = true;
        isExcludedFromLimits[treasury_] = true;
    }

    /// @dev Required override to enforce cap and custom limits during transfers/mints
    function _update(address from, address to, uint256 amount) internal override {
        if (
            from != address(0) &&
            to != address(0) &&
            !isExcludedFromLimits[from] &&
            !isExcludedFromLimits[to]
        ) {
            require(amount <= MAX_TX, "TX_LIMIT: exceeds max tx");
            require(balanceOf(to) + amount <= MAX_WALLET, "WALLET_LIMIT: exceeds max wallet");
        }

        super._update(from, to, amount);
    }

    /// @notice Testnet helper to set excluded addresses (disable in production)
    function setExcluded(address account, bool excluded) external {
        isExcludedFromLimits[account] = excluded;
    }
}
