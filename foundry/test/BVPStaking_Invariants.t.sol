// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

/// @title BVPStakingInvariantsTest
/// @notice Minimal test suite for invariant checks on staking behavior
/// @dev Focuses on ensuring that preconditions (e.g., unlock before unstake) are enforced
contract BVPStakingInvariantsTest is Test {
    BVPStaking public staking;
    BVPToken public token;

    address public user = address(0x123); // User who performs stake/unstake operations

    // Token allocation wallets; only publicSale receives full supply in this context
    address public publicSale       = address(this);
    address public operations       = address(0x1);
    address public presale          = address(0x2);
    address public foundersAndTeam  = address(0x3);
    address public marketing        = address(0x4);
    address public advisors         = address(0x5);
    address public treasury         = address(0x6);
    address public liquidity        = address(0x7);

    /// @notice Deploys contracts, transfers tokens, and performs initial stake
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

        // Fund user and approve staking contract
        token.transfer(user, 1_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 1_000_000e18);

        // Stake 100,000 tokens for 3 months
        vm.prank(user);
        staking.stake3Months(100_000e18);
    }

    /// @notice Ensures a user cannot unstake before first unlocking their stake
    function testCannotUnstakeBeforeUnlock() public {
        vm.expectRevert("Not unlocked");
        vm.prank(user);
        staking.unstake();
    }
}
