// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPToken.sol";

contract BVPTokenTest is Test {
    BVPToken public token;

    address public publicSale        = address(0xA1);
    address public operations        = address(0xA2);
    address public presale           = address(0xA3);
    address public foundersAndTeam   = address(0xA4); // merged founders + team
    address public marketing         = address(0xA5);
    address public advisors          = address(0xA6);
    address public treasury          = address(0xA7);
    address public liquidity         = address(0xA8);
    address public user              = address(0xB0);

    function setUp() public {
        token = new BVPToken(
            publicSale,
            operations,
            presale,
            foundersAndTeam,
            marketing,
            advisors,
            treasury,
            liquidity
        );
    }

    function testTotalSupply() public {
        uint256 supply = token.totalSupply();
        assertEq(supply, 1_000_000_000e18);
    }

    function testAllocations() public {
        assertEq(token.balanceOf(publicSale),      300_000_000e18);
        assertEq(token.balanceOf(operations),      200_000_000e18);
        assertEq(token.balanceOf(presale),         100_000_000e18);
        assertEq(token.balanceOf(foundersAndTeam), 100_000_000e18);
        assertEq(token.balanceOf(marketing),       150_000_000e18);
        assertEq(token.balanceOf(advisors),         50_000_000e18);
        assertEq(token.balanceOf(treasury),         50_000_000e18);
        assertEq(token.balanceOf(liquidity),        50_000_000e18);
    }

    function testTransferWorks() public {
        vm.prank(publicSale);
        token.transfer(user, 1_000e18);

        assertEq(token.balanceOf(user), 1_000e18);
        assertEq(token.balanceOf(publicSale), 299_999_000e18);
    }
}
