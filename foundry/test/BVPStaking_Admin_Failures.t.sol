// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPStaking.sol";
import "src/BVPToken.sol";

error OwnableUnauthorizedAccount(address);

contract BVPStakingAdminFailuresTest is Test {
    BVPStaking public staking;
    BVPToken public token;
    address public user = address(0x123);
    address public attacker = address(0xdead);

    address public publicSale = address(this); // receives tokens

    function setUp() public {
        token = new BVPToken(
            publicSale, publicSale, publicSale, publicSale, publicSale,
            publicSale, publicSale, publicSale, publicSale
        );
        staking = new BVPStaking(address(token));

        token.transfer(user, 1_000_000e18);
        vm.prank(user);
        token.approve(address(staking), 1_000_000e18);
    }

    function testOnlyOwnerCanEmergencyWithdraw() public {
        vm.prank(user);
        staking.stake3Months(100_000e18);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        staking.emergencyWithdraw(user);
    }

    function testCannotEmergencyWithdrawIfNoStake() public {
        vm.expectRevert("Nothing staked");
        staking.emergencyWithdraw(user);
    }
}
