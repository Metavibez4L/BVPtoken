// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Big Vision Pictures Token (BVP)
/// @notice On deploy mints 1 000 000 000 BVP (×10¹⁸) split:
///         • 30% Public Sale  
///         • 20% Operations  
///         • 10% Presale  
///         • 15% Marketing  
///         •  5% Founders  
///         •  5% Start Team  
///         •  5% Advisors  
///         •  5% Treasury  
///         •  5% Liquidity
contract BVPToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    /// @param publicSale_  Recipient of 30%
    /// @param operations_  Recipient of 20%
    /// @param presale_     Recipient of 10%
    /// @param marketing_   Recipient of 15%
    /// @param founders_    Recipient of 5%
    /// @param startTeam_   Recipient of 5%
    /// @param advisors_    Recipient of 5%
    /// @param treasury_    Recipient of 5%
    /// @param liquidity_   Recipient of 5%
    constructor(
        address publicSale_,
        address operations_,
        address presale_,
        address marketing_,
        address founders_,
        address startTeam_,
        address advisors_,
        address treasury_,
        address liquidity_
    ) ERC20("Big Vision Pictures Token", "BVP") {
        require(
            publicSale_  != address(0) &&
            operations_  != address(0) &&
            presale_     != address(0) &&
            marketing_   != address(0) &&
            founders_    != address(0) &&
            startTeam_   != address(0) &&
            advisors_    != address(0) &&
            treasury_    != address(0) &&
            liquidity_   != address(0),
            "ZERO_ADDRESS"
        );

        _mint(publicSale_,   MAX_SUPPLY * 30 / 100);
        _mint(operations_,   MAX_SUPPLY * 20 / 100);
        _mint(presale_,      MAX_SUPPLY * 10 / 100);
        _mint(marketing_,    MAX_SUPPLY * 15 / 100);
        _mint(founders_,     MAX_SUPPLY *  5 / 100);
        _mint(startTeam_,    MAX_SUPPLY *  5 / 100);
        _mint(advisors_,     MAX_SUPPLY *  5 / 100);
        _mint(treasury_,     MAX_SUPPLY *  5 / 100);
        _mint(liquidity_,    MAX_SUPPLY *  5 / 100);
    }
}
