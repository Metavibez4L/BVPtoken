// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "bvp/BVPToken.sol";

/// @title BVPTokenTest
/// @notice Unit tests for verifying BVPToken initial distribution and basic transfers using Foundry.
contract BVPTokenTest is Test {
    BVPToken public token;

    // Allocation recipients per constructor
    address public publicSale        = address(0xA1);
    address public operations        = address(0xA2);
    address public presale           = address(0xA3);
    address public foundersAndTeam   = address(0xA4); // Founders and team share
    address public marketing         = address(0xA5);
    address public advisors          = address(0xA6);
    address public treasury          = address(0xA7);
    address public liquidity         = address(0xA8);

    address public user              = address(0xB0); // Mock user for transfers

    /// @notice Deploys token and sets up initial distribution for all recipients
    function setUp() public {
        token = new BVPToken(
            publicSale,
            operations,
            presale,
            foundersAndTeam,
            marketing,
            advisors,
            treasury,
            liquidity
        );
    }

    /// @notice Ensures total supply equals 1 billion BVP with 18 decimals
    /// @dev Marked as view to avoid Solidity 2018 warning since no state is modified
    function testTotalSupply() public view {
        uint256 supply = token.totalSupply();
        assertEq(supply, 1_000_000_000e18);
    }

    /// @notice Validates that each allocation address received its intended portion
    /// @dev View-only; checks balances against expected allocation percentages
    function testAllocations() public view {
        assertEq(token.balanceOf(publicSale),      300_000_000e18); // 30%
        assertEq(token.balanceOf(operations),      200_000_000e18); // 20%
        assertEq(token.balanceOf(presale),         100_000_000e18); // 10%
        assertEq(token.balanceOf(foundersAndTeam), 100_000_000e18); // 10%
        assertEq(token.balanceOf(marketing),       150_000_000e18); // 15%
        assertEq(token.balanceOf(advisors),         50_000_000e18); // 5%
        assertEq(token.balanceOf(treasury),         50_000_000e18); // 5%
        assertEq(token.balanceOf(liquidity),        50_000_000e18); // 5%
    }

    /// @notice Tests basic ERC-20 token transfer from publicSale to a user
    function testTransferWorks() public {
        vm.prank(publicSale); // Impersonate publicSale address
        token.transfer(user, 1_000e18); // Transfer 1,000 BVP to user

        assertEq(token.balanceOf(user), 1_000e18);
        assertEq(token.balanceOf(publicSale), 299_999_000e18); // Original balance - 1,000
    }
}
