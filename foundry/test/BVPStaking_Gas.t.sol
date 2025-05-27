// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

/// @title BVPStakingGasTest
/// @notice Gas benchmark tests for staking, unlocking, and unstaking operations
contract BVPStakingGasTest is Test {
    BVPStaking public staking;
    BVPToken public token;

    address public user = address(0x123); // Test user for staking actions

    // Token allocation addresses; only publicSale receives full supply
    address public publicSale       = address(this);
    address public operations       = address(0x1);
    address public presale          = address(0x2);
    address public foundersAndTeam  = address(0x3);
    address public marketing        = address(0x4);
    address public advisors         = address(0x5);
    address public treasury         = address(0x6);
    address public liquidity        = address(0x7);

    /// @notice Deploys token and staking contracts and funds the test user
    function setUp() public {
        // Deploy token and staking contracts
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

        staking = new BVPStaking(address(token));

        // Transfer test tokens to user and approve staking
        token.transfer(user, 1_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 1_000_000e18);
    }

    /// @notice Measures gas for a 3-month stake operation
    function testGasStake3M() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);
    }

    /// @notice Measures gas for unlocking and unstaking after the full lock period
    function testGasUnlockAndUnstake() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        // Advance time beyond 3-month lock
        vm.warp(block.timestamp + 91 days);

        vm.prank(user);
        staking.unlock();

        vm.prank(user);
        staking.unstake();
    }
}
