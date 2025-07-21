// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "bvp/BVPToken.sol";

/// @title BVPTokenLimitsTest
/// @notice Tests max TX (1%) and max wallet (2%) limits for BVPToken
contract BVPTokenLimitsTest is Test {
    BVPToken token;

    // Allocation addresses
    address publicSale = address(0x1);
    address operations = address(0x2);
    address presale = address(0x3);
    address founders = address(0x4);
    address marketing = address(0x5);
    address advisors = address(0x6);
    address treasury = address(0x7);
    address liquidity = address(0x8);

    // Users for testing
    address alice = address(0x101);
    address bob   = address(0x102);

    function setUp() public {
        // Deploy BVP token with fixed allocations
        token = new BVPToken(
            publicSale,
            operations,
            presale,
            founders,
            marketing,
            advisors,
            treasury,
            liquidity
        );

        // Fund Alice and Bob from publicSale account
        vm.startPrank(publicSale);
        token.transfer(alice, 9_000_000 ether);  // 0.9% of supply (below TX + wallet cap)
        token.transfer(bob,   1_000_000 ether);  // 0.1% of supply
        vm.stopPrank();
    }

    /// @notice Ensures transfers above 1% (10M tokens) revert
    function testCannotTransferMoreThanMaxTxLimit() public {
        vm.prank(alice);
        vm.expectRevert("TX_LIMIT: exceeds max tx");
        token.transfer(bob, 11_000_000 ether); // Fails: exceeds 10M max TX
    }

    /// @notice Ensures wallet can't exceed 2% (20M tokens)
    function testCannotReceiveMoreThanMaxWalletLimit() public {
    // Bob starts with 19M
    vm.prank(publicSale);
    token.transfer(bob, 19_000_000 ether);

    // Alice will try to send 2M (total = 21M > 20M cap)
    // 2M is under TX cap (10M), so should hit WALLET_LIMIT
    vm.prank(alice);
    vm.expectRevert("WALLET_LIMIT: exceeds max wallet");
    token.transfer(bob, 2_000_000 ether);
}

    /// @notice Excluded address can bypass wallet limit
    function testExcludedAddressCanReceiveAboveMaxWallet() public {
        address exempt = address(0x200);

        // Set exempt as excluded from limits
        token.setExcluded(exempt, true);

        // Transfer from Alice (9M) to exempt (allowed above cap)
        vm.prank(alice);
        token.transfer(exempt, 9_000_000 ether); // Should succeed

        // Transfer again (another 15M) from publicSale
        vm.prank(publicSale);
        token.transfer(exempt, 15_000_000 ether); // Total 24M (bypasses 20M cap)
    }

    /// @notice Excluded address can bypass TX limit
    function testExcludedAddressCanSendAboveMaxTx() public {
        address exempt = address(0x201);

        // Give exempt 25M tokens from publicSale
        vm.prank(publicSale);
        token.transfer(exempt, 25_000_000 ether);

        // Exclude from TX/wallet caps
        token.setExcluded(exempt, true);

        // Transfer 20M tokens (over 10M TX limit)
        vm.prank(exempt);
        token.transfer(bob, 20_000_000 ether); // Should succeed
    }
}
