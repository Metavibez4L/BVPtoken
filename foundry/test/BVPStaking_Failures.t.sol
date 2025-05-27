// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

/// @title BVPStakingFailuresTest
/// @notice Negative test cases for BVPStaking contract to validate failure scenarios
contract BVPStakingFailuresTest is Test {
    BVPStaking public staking;
    BVPToken public token;

    address public user = address(0x123); // Test user who will interact with the contract

    // Allocation addresses used to initialize the BVP token
    address public publicSale       = address(0x1);
    address public operations       = address(0x2);
    address public presale          = address(0x3);
    address public foundersAndTeam  = address(0x4); // Founders + team combined
    address public marketing        = address(0x5);
    address public advisors         = address(0x6);
    address public treasury         = address(0x7);
    address public liquidity        = address(0x8);

    /// @notice Sets up token and staking contract with 1M tokens transferred and approved for user
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

        // Fund the user with BVP tokens
        vm.prank(publicSale);
        token.transfer(user, 1_000_000e18);

        // User approves staking contract to use full amount
        vm.prank(user);
        token.approve(address(staking), 1_000_000e18);
    }

    /// @notice Prevents staking zero tokens
    function testCannotStakeZeroAmount() public {
        vm.prank(user);
        vm.expectRevert("Zero amount");
        staking.stake3Months(0);
    }

    /// @notice Prevents multiple simultaneous stakes from the same user
    function testCannotStakeTwice() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.prank(user);
        vm.expectRevert("Already staked");
        staking.stake6Months(100_000e18);
    }

    /// @notice Prevents unlocking before the full lock period has expired
    function testCannotUnlockBeforeLockExpires() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        // Advance only 30 days into lock period
        vm.warp(block.timestamp + 30 days);

        vm.prank(user);
        vm.expectRevert("Still locked");
        staking.unlock();
    }

    /// @notice Prevents unlocking if no stake was ever made
    function testCannotUnlockIfNoStake() public {
        vm.prank(user);
        vm.expectRevert("No stake");
        staking.unlock();
    }

    /// @notice Prevents unlocking a stake more than once
    function testCannotUnlockTwice() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.warp(block.timestamp + 91 days);
        vm.prank(user);
        staking.unlock();

        vm.prank(user);
        vm.expectRevert("Already unlocked");
        staking.unlock();
    }

    /// @notice Prevents unstaking unless the stake has first been unlocked
    function testCannotUnstakeIfNotUnlocked() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.warp(block.timestamp + 91 days);

        vm.prank(user);
        vm.expectRevert("Not unlocked");
        staking.unstake();
    }

    /// @notice Prevents unstaking a second time (after already unstaked)
    function testCannotUnstakeTwice() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.warp(block.timestamp + 91 days);
        vm.prank(user);
        staking.unlock();
        vm.prank(user);
        staking.unstake();

        vm.prank(user);
        vm.expectRevert("Not unlocked");
        staking.unstake();
    }
}
