// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPToken.sol";
import "src/BVPStaking.sol";

contract BVPStakingTest is Test {
    BVPToken token;
    BVPStaking staking;
    address user = address(0xA0);

    function setUp() public {
        address deployer = address(this);

        token = new BVPToken(
            deployer, deployer, deployer, deployer,
            deployer, deployer, deployer, deployer, deployer
        );

        staking = new BVPStaking(address(token));
        token.transfer(user, 1_000_000 ether);
        vm.prank(user);
        token.approve(address(staking), 1_000_000 ether);
    }

    function testStakeAndTier() public {
        vm.prank(user);
        staking.stake3Months(100_000 ether);

        (uint256 amount,, uint256 lockTime,,) = staking.getStake(user);
        assertEq(amount, 100_000 ether);
        assertEq(lockTime, 90 days);

        string memory tier = staking.getTierName(user);
        assertEq(keccak256(bytes(tier)), keccak256("Silver"));
    }

    function testUnlockAndUnstake() public {
        vm.startPrank(user);
        staking.stake3Months(100_000 ether);
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();
        vm.stopPrank();

        (uint256 amount,,,,) = staking.getStake(user);
        assertEq(amount, 0);
    }
}
