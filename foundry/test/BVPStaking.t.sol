// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/BVPToken.sol";
import "src/BVPStaking.sol";

/// @title BVPStakingTest
/// @notice Tests core staking behavior and tier logic of BVPStaking using Foundry.
contract BVPStakingTest is Test {
    BVPToken token;
    BVPStaking staking;

    address user = address(0xA0); // Test user who will stake BVP

    // Predefined token allocation addresses used for constructor
    address public publicSale        = address(0xA1);
    address public operations        = address(0xA2);
    address public presale           = address(0xA3);
    address public foundersAndTeam   = address(0xA4); // Founders + team combined
    address public marketing         = address(0xA5);
    address public advisors          = address(0xA6);
    address public treasury          = address(0xA7);
    address public liquidity         = address(0xA8);

    /// @notice Sets up test environment: deploys BVPToken, BVPStaking, and transfers stake funds to test user
    function setUp() public {
        // Deploy the token contract with initial allocations
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

        // Deploy the staking contract
        staking = new BVPStaking(address(token));

        // Transfer BVP tokens from public sale wallet to user
        vm.prank(publicSale);
        token.transfer(user, 1_000_000 ether);

        // Approve staking contract to spend user's tokens
        vm.prank(user);
        token.approve(address(staking), 1_000_000 ether);
    }

    /// @notice Tests staking for 3 months and checks that correct tier is assigned
    function testStakeAndTier() public {
        // User stakes 100k tokens for 3 months (90 days)
        vm.prank(user);
        staking.stake3Months(100_000 ether);

        // Fetch stake and validate amount and lock duration
        (uint256 amount,, uint256 lockTime,,) = staking.getStake(user);
        assertEq(amount, 100_000 ether);
        assertEq(lockTime, 90 days);

        // Confirm tier is correctly assigned as Silver
        string memory tier = staking.getTierName(user);
        assertEq(keccak256(bytes(tier)), keccak256("Silver"));
    }

    /// @notice Tests unlocking and unstaking after lock period
    function testUnlockAndUnstake() public {
        vm.startPrank(user);
        staking.stake3Months(100_000 ether);

        // Warp forward beyond the 3-month lock period
        vm.warp(block.timestamp + 91 days);

        // Unlock and then unstake tokens
        staking.unlock();
        staking.unstake();
        vm.stopPrank();

        // Verify that stake was cleared
        (uint256 amount,,,,) = staking.getStake(user);
        assertEq(amount, 0);
    }
}
