// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

contract BVPStakingTierFuzzTest is Test {
    BVPStaking public staking;
    BVPToken public token;
    address public user = address(0x123);

    address public publicSale = address(this);

    function setUp() public {
        token = new BVPToken(
            publicSale, publicSale, publicSale, publicSale, publicSale,
            publicSale, publicSale, publicSale, publicSale
        );
        staking = new BVPStaking(address(token));

        token.transfer(user, 10_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 10_000_000e18);
    }

    function testFuzzTierAssignment(uint256 amount) public {
        amount = bound(amount, 0, 2_500_000e18);

        if (amount == 0) {
            vm.prank(user);
            vm.expectRevert("Zero amount");
            staking.stake3Months(amount);
            return;
        }

        vm.prank(user);
        staking.stake3Months(amount);
        string memory tier = staking.getTierName(user);

        if (amount >= 2_000_000e18) assertEq(tier, "Diamond");
        else if (amount >= 1_000_000e18) assertEq(tier, "Platinum");
        else if (amount >= 500_000e18) assertEq(tier, "Gold");
        else if (amount >= 100_000e18) assertEq(tier, "Silver");
        else if (amount >= 20_000e18) assertEq(tier, "Bronze");
        else assertEq(tier, "None");
    }
}
