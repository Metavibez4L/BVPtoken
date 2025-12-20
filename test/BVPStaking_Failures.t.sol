// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "bvp/BVPStaking.sol";
import "bvp/BVPToken.sol";

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
        vm.expectRevert(BVPStaking.ZeroAmount.selector);
        staking.stake3Months(0);
    }

    /// @notice Prevents multiple simultaneous stakes from the same user
    function testCannotStakeTwice() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.prank(user);
        vm.expectRevert(BVPStaking.AlreadyStaked.selector);
        staking.stake6Months(100_000e18);
    }

    /// @notice Prevents unlocking before the full lock period has expired
    function testCannotUnlockBeforeLockExpires() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        // Advance only 30 days into lock period
        vm.warp(block.timestamp + 30 days);

        vm.prank(user);
        vm.expectRevert(BVPStaking.StillLocked.selector);
        staking.unlock();
    }

    /// @notice Prevents unlocking if no stake was ever made
    function testCannotUnlockIfNoStake() public {
        vm.prank(user);
        vm.expectRevert(BVPStaking.NoStake.selector);
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
        vm.expectRevert(BVPStaking.AlreadyUnlocked.selector);
        staking.unlock();
    }

    /// @notice Prevents unstaking unless the stake has first been unlocked
    function testCannotUnstakeIfNotUnlocked() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.warp(block.timestamp + 91 days);

        vm.prank(user);
        vm.expectRevert(BVPStaking.NotUnlocked.selector);
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
        vm.expectRevert(BVPStaking.NotUnlocked.selector);
        staking.unstake();
    }

    /// @notice Tests the new combined unlockAndUnstake function (happy path)
    function testUnlockAndUnstake_Success() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        // Advance past lock period
        vm.warp(block.timestamp + 91 days);

        uint256 balBefore = token.balanceOf(user);

        vm.prank(user);
        staking.unlockAndUnstake();

        uint256 balAfter = token.balanceOf(user);
        assertEq(balAfter - balBefore, 100_000e18, "user should receive full stake back");

        // Verify stake is cleared
        (uint256 amount,,,, ) = staking.getStake(user);
        assertEq(amount, 0, "stake should be cleared");
    }

    /// @notice Tests that unlockAndUnstake reverts if lock period hasn't expired
    function testUnlockAndUnstake_RevertsIfStillLocked() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.warp(block.timestamp + 30 days); // Only 30 days in

        vm.prank(user);
        vm.expectRevert(BVPStaking.StillLocked.selector);
        staking.unlockAndUnstake();
    }

    /// @notice Tests that unlockAndUnstake reverts if no stake exists
    function testUnlockAndUnstake_RevertsIfNoStake() public {
        vm.prank(user);
        vm.expectRevert(BVPStaking.NoStake.selector);
        staking.unlockAndUnstake();
    }
}
