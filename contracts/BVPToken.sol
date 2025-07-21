// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token with capped supply, fixed allocations, and anti-whale limits.
contract BVPToken is ERC20Capped {
    uint256 public immutable maxTx;
    uint256 public immutable maxWallet;

    mapping(address => bool) public isExcludedFromLimits;

    address private immutable _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

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
        _owner = msg.sender;

        maxTx = 10_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;

        _mint(publicSale_,       cap() * 30 / 100);
        _mint(operations_,       cap() * 20 / 100);
        _mint(presale_,          cap() * 10 / 100);
        _mint(foundersAndTeam_,  cap() * 10 / 100);
        _mint(marketing_,        cap() * 15 / 100);
        _mint(advisors_,         cap() * 5  / 100);
        _mint(treasury_,         cap() * 5  / 100);
        _mint(liquidity_,        cap() * 5  / 100);

        isExcludedFromLimits[publicSale_] = true;
        isExcludedFromLimits[operations_] = true;
        isExcludedFromLimits[liquidity_]  = true;
        isExcludedFromLimits[treasury_]   = true;
    }

    /// @dev Enforces anti-whale limits before transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (
            from != address(0) &&
            to != address(0) &&
            !isExcludedFromLimits[from] &&
            !isExcludedFromLimits[to]
        ) {
            require(amount <= maxTx, "TX_LIMIT: exceeds max tx");
            require(balanceOf(to) + amount <= maxWallet, "WALLET_LIMIT: exceeds max wallet");
        }
    }

    /// @notice Admin function to manage anti-whale exclusion list
    /// @dev Only callable by the original deployer
    function setExcluded(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }
}
