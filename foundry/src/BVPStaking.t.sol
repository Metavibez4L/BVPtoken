// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/BVPToken.sol";
import "../../contracts/BVPStakingUpgradeable.sol";

contract BVPStakingTest is Test {
    BVPToken token;
    BVPStakingUpgradeable staking;
    address user = address(0xABCD);

    function setUp() public {
        token = new BVPToken(address(this));
        staking = new BVPStakingUpgradeable();
        staking.initialize(address(token));

        token.transfer(user, 1_000_000 ether);
        vm.startPrank(user);
        token.approve(address(staking), type(uint256).max);
    }

    function testStakeWithCustomLockPeriod() public {
        staking.stake(100_000 ether, 180 days); // 6-month lock
        vm.warp(block.timestamp + 180 days);
        staking.unlock();
        staking.unstake();

        assertEq(token.balanceOf(user), 1_000_000 ether);
    }

    function testStakeDefaultLockPeriod() public {
        staking.stake(100_000 ether); // default 90-day lock
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();

        assertEq(token.balanceOf(user), 1_000_000 ether);
    }
}
