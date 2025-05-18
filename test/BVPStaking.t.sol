// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";
import "../contracts/BVPStakingUpgradeable.sol";

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

    function testStakeDefaultLockPeriod() public {
        staking.stake(100_000 ether); // default 90d
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();

        assertEq(token.balanceOf(user), 1_000_000 ether);
    }

    function testStakeCustomLockPeriod6mo() public {
        staking.stake(100_000 ether, 180 days);
        vm.warp(block.timestamp + 180 days);
        staking.unlock();
        staking.unstake();

        assertEq(token.balanceOf(user), 1_000_000 ether);
    }

    function testEmergencyWithdraw() public {
        staking.stake(100_000 ether); // 90d lock
        uint256 before = token.balanceOf(address(this));
        vm.stopPrank();

        staking.emergencyWithdraw(user);
        uint256 afterBal = token.balanceOf(address(this));

        assertGt(afterBal, before); // balance increased as expected
    }

    function testTierLabel() public {
        staking.stake(1_000_000 ether, 90 days);
        string memory tier = staking.getTier(user);
        assertEq(keccak256(abi.encodePacked(tier)), keccak256("Platinum"));
    }
}
