// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/BVPStaking.sol";
import "../../contracts/BVPToken.sol";

contract BVPStakingTest is Test {
    BVPStaking staking;
    BVPToken token;
    address user = address(0xABCD);

    function setUp() public {
        token = new BVPToken(address(this));
        staking = new BVPStaking(address(token));
        token.transfer(user, 1_000_000 ether);
        vm.startPrank(user);
        token.approve(address(staking), type(uint256).max);
    }

    function testStakeUnstakeFlow() public {
        staking.stake(100_000 ether);
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();
        assertEq(token.balanceOf(user), 1_000_000 ether);
    }
}
