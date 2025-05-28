// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, fixed initial allocations, and anti-whale limits.
/// @dev Enforces a 1B cap, 1% max TX size (10M), and 2% max wallet limit (20M), with exemptions.
contract BVPToken is ERC20Capped {
    /// @notice Max allowable tokens per transaction (10M BVP)
    uint256 public immutable MAX_TX;

    /// @notice Max allowable tokens per wallet (20M BVP)
    uint256 public immutable MAX_WALLET;

    /// @notice Mapping of addresses excluded from anti-whale transfer and wallet limits
    mapping(address => bool) public isExcludedFromLimits;

    /// @notice Deploys the BVPToken with fixed supply and predefined allocations
    /// @param publicSale_ Address to receive 30% allocation
    /// @param operations_ Address to receive 20% allocation
    /// @param presale_ Address to receive 10% allocation
    /// @param foundersAndTeam_ Address to receive 10% allocation
    /// @param marketing_ Address to receive 15% allocation
    /// @param advisors_ Address to receive 5% allocation
    /// @param treasury_ Address to receive 5% allocation
    /// @param liquidity_ Address to receive 5% allocation
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
        ERC20Capped(1_000_000_000 * 1e18) // Total supply cap of 1B tokens
    {
        MAX_TX = 10_000_000 * 1e18;     // Max transaction: 1% of cap
        MAX_WALLET = 20_000_000 * 1e18; // Max wallet: 2% of cap

        // Initial token allocations using _update() instead of _mint()
        _update(address(0), publicSale_,       cap() * 30 / 100); // 30%
        _update(address(0), operations_,       cap() * 20 / 100); // 20%
        _update(address(0), presale_,          cap() * 10 / 100); // 10%
        _update(address(0), foundersAndTeam_,  cap() * 10 / 100); // 10%
        _update(address(0), marketing_,        cap() * 15 / 100); // 15%
        _update(address(0), advisors_,         cap() * 5  / 100); // 5%
        _update(address(0), treasury_,         cap() * 5  / 100); // 5%
        _update(address(0), liquidity_,        cap() * 5  / 100); // 5%

        // Exclude strategic/system wallets from transfer/wallet limits
        isExcludedFromLimits[publicSale_] = true;
        isExcludedFromLimits[operations_] = true;
        isExcludedFromLimits[liquidity_]  = true;
        isExcludedFromLimits[treasury_]   = true;
    }

    /// @dev Custom override of OpenZeppelin's _update to enforce TX/wallet rules during transfers/mints
    function _update(address from, address to, uint256 amount) internal override {
        // Skip enforcement on mints/burns or if either party is excluded
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

    /// @notice Set or unset anti-whale exclusion for specific address
    /// @dev Use only in testnets/dev environments; disable in production
    /// @param account Address to update
    /// @param excluded True to exclude from limits, false to re-enable
    function setExcluded(address account, bool excluded) external {
        isExcludedFromLimits[account] = excluded;
    }
}
