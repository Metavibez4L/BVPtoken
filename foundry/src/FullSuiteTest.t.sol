// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/BVPStaking.sol";
import "../../contracts/BVPToken.sol";
import "../../contracts/GasRouter.sol";

contract FullSuiteTest is Test {
    BVPToken token;
    BVPStaking staking;
    GasRouter gasRouter;
    address user = address(0x1234);

    function setUp() public {
        token = new BVPToken(address(this));
        staking = new BVPStaking(address(token));
        gasRouter = new GasRouter(address(token), address(this));
        token.transfer(user, 1_000_000 ether);
        vm.startPrank(user);
        token.approve(address(staking), type(uint256).max);
        token.approve(address(gasRouter), type(uint256).max);
    }

    function testStakeAndGasHandling() public {
        staking.stake(100_000 ether);
        vm.warp(block.timestamp + 91 days);
        staking.unlock();
        staking.unstake();

        gasRouter.handleGas(10_000 ether);

        // Expect user balance to be original minus 100k stake + unstake,
        // then minus 8k net cost from gas usage
        assertEq(token.balanceOf(user), 992_000 ether);
    }
}
