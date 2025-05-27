// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice ERC-20 token representing ownership and utility within the BVP ecosystem.
///         Upon deployment, mints a fixed supply of 1,000,000,000 BVP tokens (with 18 decimals)
///         and distributes them across predefined allocation categories:
///         - 30% Public Sale
///         - 20% Operations
///         - 10% Presale
///         - 10% Founders & Team
///         - 15% Marketing
///         -  5% Advisors
///         -  5% Treasury Hold
///         -  5% Liquidity
contract BVPToken is ERC20 {
    /// @dev Hard cap of total token supply (1 billion tokens, scaled to 18 decimals)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    /// @notice Deploys the BVP token and mints fixed allocations to given wallet addresses
    /// @param publicSale_ Address to receive the 30% public sale allocation
    /// @param operations_ Address to receive the 20% operations allocation
    /// @param presale_ Address to receive the 10% presale allocation
    /// @param foundersAndTeam_ Address to receive the 10% founders & team allocation
    /// @param marketing_ Address to receive the 15% marketing allocation
    /// @param advisors_ Address to receive the 5% advisor allocation
    /// @param treasury_ Address to receive the 5% treasury hold allocation
    /// @param liquidity_ Address to receive the 5% liquidity allocation
    constructor(
        address publicSale_,
        address operations_,
        address presale_,
        address foundersAndTeam_,
        address marketing_,
        address advisors_,
        address treasury_,
        address liquidity_
    ) ERC20("Big Vision Pictures Token", "BVP") {
        // Validate that all input addresses are non-zero to prevent misallocation
        require(
            publicSale_        != address(0) &&
            operations_        != address(0) &&
            presale_           != address(0) &&
            foundersAndTeam_   != address(0) &&
            marketing_         != address(0) &&
            advisors_          != address(0) &&
            treasury_          != address(0) &&
            liquidity_         != address(0),
            "ZERO_ADDRESS"
        );

        // Mint token allocations to each designated address
        _mint(publicSale_,       MAX_SUPPLY * 30 / 100);  // 30%
        _mint(operations_,       MAX_SUPPLY * 20 / 100);  // 20%
        _mint(presale_,          MAX_SUPPLY * 10 / 100);  // 10%
        _mint(foundersAndTeam_,  MAX_SUPPLY * 10 / 100);  // 10%
        _mint(marketing_,        MAX_SUPPLY * 15 / 100);  // 15%
        _mint(advisors_,         MAX_SUPPLY * 5  / 100);  // 5%
        _mint(treasury_,         MAX_SUPPLY * 5  / 100);  // 5%
        _mint(liquidity_,        MAX_SUPPLY * 5  / 100);  // 5%
    }
}
