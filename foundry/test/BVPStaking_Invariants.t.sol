// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

contract BVPStakingInvariantsTest is Test {
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

        token.transfer(user, 1_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 1_000_000e18);

        vm.prank(user);
        staking.stake3Months(100_000e18);
    }

    function testCannotUnstakeBeforeUnlock() public {
        vm.expectRevert("Not unlocked");
        vm.prank(user);
        staking.unstake();
    }
}
