// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "bvp/BVPToken.sol";

/// @title BVPTokenLimitsFuzzTest
/// @notice Fuzz tests around BVPToken anti-whale limits (maxTx / maxWallet)
/// @dev Complements the more direct limit tests in BVPToken_AdminAndExclusions.t.sol
contract BVPTokenLimitsFuzzTest is Test {
    BVPToken internal token;

    // Constructor recipients (must align with BVPToken constructor)
    address internal publicSale      = address(0x1);
    address internal operations      = address(0x2);
    address internal presale         = address(0x3);
    address internal foundersAndTeam = address(0x4);
    address internal marketing       = address(0x5);
    address internal advisors        = address(0x6);
    address internal treasury        = address(0x7);
    address internal liquidity       = address(0x8);

    address internal alice = address(0xA1); // non-excluded
    address internal bob   = address(0xA2); // non-excluded

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

        // Sanity: anti-whale limits configured
        assertGt(token.maxTx(), 0);
        assertGt(token.maxWallet(), 0);

        // Non-excluded by design
        assertFalse(token.isTxLimitExcluded(alice));
        assertFalse(token.isWalletLimitExcluded(alice));
        assertFalse(token.isTxLimitExcluded(bob));
        assertFalse(token.isWalletLimitExcluded(bob));
    }

    /// @notice Fuzz: non-excluded sender can always transfer <= maxTx
    ///         provided the recipient stays under maxWallet.
    function testFuzz_NonExcluded_TransferWithinLimits(
        uint256 sendAmountRaw
    ) public {
        // Bound to a safe range: at most maxTx and at most half of maxWallet
        uint256 maxTx = token.maxTx();
        uint256 maxWallet = token.maxWallet();
        uint256 upper = maxTx < maxWallet / 2 ? maxTx : maxWallet / 2;
        uint256 sendAmount = bound(sendAmountRaw, 0, upper);

        // Seed alice with exactly sendAmount from an excluded wallet
        vm.prank(publicSale);
        token.transfer(alice, sendAmount);

        // bob starts from zero, so bob's post-balance will be <= maxWallet
        vm.prank(alice);
        token.transfer(bob, sendAmount);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), sendAmount);
    }

    /// @notice Non-excluded sender attempting to send strictly more than maxTx
    ///         should always hit the TransferExceedsLimit custom error.
    function test_NonExcluded_ExceedMaxTx_Reverts() public {
        uint256 maxTx = token.maxTx();

        // Give alice a balance comfortably above maxTx using an excluded wallet
        vm.prank(publicSale);
        token.transfer(alice, maxTx * 2);

        uint256 amount = maxTx + 1;

        vm.prank(alice);
        vm.expectRevert(BVPToken.TransferExceedsLimit.selector);
        token.transfer(bob, amount);
    }

    /// @notice Transfers from an excluded sender that would push a
    ///         non-excluded recipient above maxWallet should revert.
    function test_ExcludedSender_ExceedMaxWallet_Reverts() public {
        uint256 maxWallet = token.maxWallet();

        // First, bring bob close to maxWallet from an excluded wallet
        vm.prank(publicSale);
        token.transfer(bob, maxWallet);
        assertEq(token.balanceOf(bob), maxWallet);

        // Any strictly positive amount from an excluded sender should now fail
        vm.prank(publicSale);
        vm.expectRevert(BVPToken.WalletExceedsLimit.selector);
        token.transfer(bob, 1);
    }
}


