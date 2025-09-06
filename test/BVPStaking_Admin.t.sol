// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";
import "../contracts/BVPStaking.sol";

contract BVPStakingAdminTest is Test {
    BVPToken token;
    BVPStaking staking;

    address[5] internal users;
    uint256[5] internal amounts = [
        25_000 * 1e18,
        120_000 * 1e18,
        510_000 * 1e18,
        1_100_000 * 1e18,
        2_200_000 * 1e18
    ];

    function setUp() public {
        // Assign unique test users
        for (uint256 i = 0; i < users.length; i++) {
            users[i] = address(uint160(i + 1));
        }

        // Deploy token and allocate fixed supply
        token = new BVPToken(
            users[0],  // publicSale (30%)
            users[1],  // operations (20%)
            users[2],  // presale (10%)
            users[3],  // foundersAndTeam (10%)
            users[4],  // marketing (15%)
            address(6), // advisors
            address(7), // treasury
            address(8)  // liquidity
        );

        // Deploy staking contract
        staking = new BVPStaking(address(token));

        // Approve + stake from all 5 users with tier-triggering amounts
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(users[i]);
            token.approve(address(staking), type(uint256).max);

            vm.prank(users[i]);
            staking.stake3Months(amounts[i]);
        }
    }

    function testGetTierCodeAllLevels() public {
        uint8[5] memory expected = [1, 2, 3, 4, 5];

        for (uint256 i = 0; i < users.length; i++) {
            uint8 tier = staking.getTierCode(users[i]);
            assertEq(tier, expected[i], string.concat("Wrong tier for user ", vm.toString(i)));
        }
    }
}
