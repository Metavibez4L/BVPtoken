// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../contracts/BVPToken.sol";
import "../../contracts/BVPStaking.sol";
import "../../contracts/GasRouter.sol";

contract FullSuiteTest is Test {
    BVPToken    public token;
    BVPStaking  public staking;
    GasRouter   public router;
    address     public user = address(0x123);

    function setUp() public {
        // Deploy & mint entire supply to this contract
        token   = new BVPToken(user);

        // Move all tokens into `user`
        token.transfer(user, token.totalSupply());

        // Init staking (takes IERC20)
        staking = new BVPStaking(token);

        // Init router with this contract as Treasury
        router  = new GasRouter(address(token), address(this));
    }

    function testTotalSupply() external {
        assertEq(token.totalSupply(), 1_000_000_000 * 1e18, "wrong total supply");
    }

    function testUserInitialBalance() external {
        // user now holds the entire supply
        assertEq(token.balanceOf(user), token.totalSupply(), "wrong user balance");
    }

    function testHandleGasSplit() external {
        uint256 amount = 6_000 * 1e18;

        // User must approve router to pull `amount`
        vm.prank(user);
        token.approve(address(router), amount);

        // Call handleGas as the user
        vm.prank(user);
        router.handleGas(amount);

        // Router should end up with 0
        assertEq(token.balanceOf(address(router)), 0, "router should be drained");

        // Treasury (this contract) gets 20%
        uint256 expectedTreasury = (amount * 20) / 100;
        assertEq(token.balanceOf(address(this)), expectedTreasury, "wrong treasury balance");

        // User ends with supply - toTreasury
        uint256 expectedUser = token.totalSupply() - expectedTreasury;
        assertEq(token.balanceOf(user), expectedUser, "wrong user rebate");
    }

    function testDoubleStakeReverts() external {
        uint256 stakeAmt = 100 * 1e18;

        // User must approve staking
        vm.prank(user);
        token.approve(address(staking), stakeAmt);

        // First stake succeeds
        vm.prank(user);
        staking.stake(stakeAmt);

        // Second stake should revert with your message
        vm.prank(user);
        vm.expectRevert("Already staked");
        staking.stake(50 * 1e18);
    }

    function testTierBeforeUnlock() external {
        // No stake ⇒ getTier returns "None"
        string memory tier = staking.getTier(user);
        assertEq(tier, "None", "tier should start as None");
    }
}
