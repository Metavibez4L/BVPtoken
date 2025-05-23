// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "src/BVPToken.sol";

contract BVPTokenTest is Test {
    BVPToken token;
    address[9] recipients;

    function setUp() public {
        for (uint i = 0; i < 9; i++) {
            recipients[i] = address(uint160(i + 1));
        }

        token = new BVPToken(
            recipients[0], recipients[1], recipients[2], recipients[3],
            recipients[4], recipients[5], recipients[6], recipients[7],
            recipients[8]
        );
    }

    function testTotalSupply() public view {
        assertEq(token.totalSupply(), 1_000_000_000 ether);
    }

    function testAllocationShares() public view {
        assertEq(token.balanceOf(recipients[0]), 300_000_000 ether); // 30%
        assertEq(token.balanceOf(recipients[1]), 200_000_000 ether); // 20%
        assertEq(token.balanceOf(recipients[2]), 100_000_000 ether); // 10%
        assertEq(token.balanceOf(recipients[3]), 150_000_000 ether); // 15%
        assertEq(token.balanceOf(recipients[4]), 50_000_000 ether);  // 5%
    }

    function testTransfersWork() public {
        address sender = recipients[0];
        address receiver = recipients[8];
        uint256 before = token.balanceOf(receiver);

        vm.prank(sender);
        token.transfer(receiver, 1 ether);

        assertEq(token.balanceOf(receiver), before + 1 ether);
    }
}
