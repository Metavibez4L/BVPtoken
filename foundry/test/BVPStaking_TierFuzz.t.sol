// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

/// @title BVPStakingTierFuzzTest
/// @notice Fuzz test for verifying tier classification based on staked amount
/// @dev Uses Forge's `bound()` function to constrain input range between 0 and 2.5M tokens
contract BVPStakingTierFuzzTest is Test {
    BVPStaking public staking;
    BVPToken public token;

    address public user = address(0x123); // Fuzz test subject

    // Allocation recipients (only `publicSale` gets initial supply for test)
    address public publicSale       = address(this);
    address public operations       = address(0x1);
    address public presale          = address(0x2);
    address public foundersAndTeam  = address(0x3);
    address public marketing        = address(0x4);
    address public advisors         = address(0x5);
    address public treasury         = address(0x6);
    address public liquidity        = address(0x7);

    /// @notice Deploys contracts and transfers a large token balance to the test user
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

        staking = new BVPStaking(address(token));

        // Give user a large enough balance for fuzz testing
        token.transfer(user, 10_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 10_000_000e18);
    }

    /// @notice Fuzz test that stakes an arbitrary amount and asserts correct tier assignment
    /// @param amount Random fuzzed value bounded between 0 and 2,500,000 tokens (scaled)
    function testFuzzTierAssignment(uint256 amount) public {
        // Limit fuzzed input between 0 and 2.5M tokens
        amount = bound(amount, 0, 2_500_000e18);

        // Zero amount should revert before attempting tier logic
        if (amount == 0) {
            vm.prank(user);
            vm.expectRevert("Zero amount");
            staking.stake3Months(amount);
            return;
        }

        // Stake the fuzzed amount
        vm.prank(user);
        staking.stake3Months(amount);

        // Fetch user's assigned tier name
        string memory tier = staking.getTierName(user);

        // Assert that tier name matches expected based on amount
        if (amount >= 2_000_000e18)       assertEq(tier, "Diamond");
        else if (amount >= 1_000_000e18)  assertEq(tier, "Platinum");
        else if (amount >= 500_000e18)    assertEq(tier, "Gold");
        else if (amount >= 100_000e18)    assertEq(tier, "Silver");
        else if (amount >= 20_000e18)     assertEq(tier, "Bronze");
        else                              assertEq(tier, "None");
    }
}
