// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../../contracts/BVPToken.sol";
import "../../contracts/BVPStaking.sol";

contract BVPStakingTest is Test {
    BVPToken token;
    BVPStaking staking;
    address user = address(0xABCD);

    function setUp() public {
        token = new BVPToken(address(this)); // treasury param is unused now
        staking = new BVPStaking(IERC20(address(token)));

        token.transfer(user, 2_000_000 ether);
        vm.prank(user);
        token.approve(address(staking), 2_000_000 ether);
    }

    function testStakeUnlockUnstake() public {
        vm.startPrank(user);
        staking.stake(10_000 ether);
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();
        vm.stopPrank();

        assertEq(token.balanceOf(user), 2_000_000 ether);
    }

    function testTierIsPlatinum() public {
        vm.prank(user);
        staking.stake(1_500_000 ether);
        string memory tier = staking.getTier(user);
        assertEq(tier, "Platinum");
    }

    function testEmergencyWithdraw() public {
        vm.prank(user);
        staking.stake(10_000 ether);

        uint256 beforeBalance = token.balanceOf(address(this));
        staking.emergencyWithdraw(user);
        uint256 afterBalance = token.balanceOf(address(this));

        assertEq(afterBalance - beforeBalance, 10_000 ether);
    }
}
