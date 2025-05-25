// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice On deploy mints 1,000,000,000 BVP (×10¹⁸) split:
///         • 30% Public Sale  
///         • 20% Operations  
///         • 10% Presale  
///         • 10% Founders & Team  
///         • 15% Marketing  
///         •  5% Advisors  
///         •  5% Treasury Hold  
///         •  5% Liquidity
contract BVPToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

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

        _mint(publicSale_,       MAX_SUPPLY * 30 / 100);
        _mint(operations_,       MAX_SUPPLY * 20 / 100);
        _mint(presale_,          MAX_SUPPLY * 10 / 100);
        _mint(foundersAndTeam_,  MAX_SUPPLY * 10 / 100);
        _mint(marketing_,        MAX_SUPPLY * 15 / 100);
        _mint(advisors_,         MAX_SUPPLY * 5  / 100);
        _mint(treasury_,         MAX_SUPPLY * 5  / 100);
        _mint(liquidity_,        MAX_SUPPLY * 5  / 100);
    }
}
