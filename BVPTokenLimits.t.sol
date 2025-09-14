// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";

contract BVPTokenLimitsTest is Test {
    BVPToken token;

    // Human-readable addresses
    address alice = makeAddr("ALICE");     // non-excluded
    address bob   = makeAddr("BOB");       // non-excluded
    address sale  = makeAddr("SALE");      // funded alloc
    address ops   = makeAddr("OPS");       // funded alloc
    address pre   = makeAddr("PRESALE");   // funded alloc
    address team  = makeAddr("TEAM");      // funded alloc
    address mkt   = makeAddr("MARKETING"); // funded alloc
    address adv   = makeAddr("ADVISORS");  // funded alloc
    address tre   = makeAddr("TREASURY");  // funded alloc
    address liq   = makeAddr("LIQUIDITY"); // funded alloc

    function setUp() public {
        token = new BVPToken(sale, ops, pre, team, mkt, adv, tre, liq);

        // Sanity
        assertEq(token.totalSupply(), 1_000_000_000 * 1e18, "bad total supply");
        assertGt(token.maxTx(), 0, "maxTx zero");
        assertGt(token.maxWallet(), 0, "maxWallet zero");

        // Ensure test actors are not excluded so limits apply to them
        assertFalse(token.isTxLimitExcluded(alice), "alice tx-excluded");
        assertFalse(token.isWalletLimitExcluded(alice), "alice wallet-excluded");
        assertFalse(token.isTxLimitExcluded(bob), "bob tx-excluded");
        assertFalse(token.isWalletLimitExcluded(bob), "bob wallet-excluded");

        // Seed ALICE to exactly maxTx using any excluded funded wallets (with fallback)
        _fundToTargetBalance(alice, token.maxTx());
        assertEq(token.balanceOf(alice), token.maxTx(), "alice not at maxTx");
    }

    // ------------------------------------------------------------
    // Tests
    // ------------------------------------------------------------

    /// transfers from EXCLUDED -> NON-EXCLUDED that would exceed recipient maxWallet MUST FAIL.
    function test_ExcludedSenderToNonExcluded_ExceedWallet_Fails() public {
        assertEq(token.balanceOf(bob), 0);

        address excludedSender = _getAnyExcludedWithBalance();
        require(excludedSender != address(0), "no excluded sender funded");

        // Try to overshoot bob's max wallet in one go
        uint256 exceed = token.maxWallet() + 1;

        vm.startPrank(excludedSender);
        vm.expectRevert(bytes("WALLET_LIMIT"));
        token.transfer(bob, exceed);
        vm.stopPrank();
    }

    /// large transfers from NON-EXCLUDED must fail if amount > maxTx
    function test_NonExcludedSender_ExceedMaxTx_Fails() public {
        // Ensure BOB has *at least* maxTx + 1 so balance isn't the reason we revert
        uint256 want = token.maxTx() + 1;
        _fundToTargetBalance(bob, want);
        assertGe(token.balanceOf(bob), want, "bob not sufficiently funded");

        // Now bob (non-excluded) attempts to send > maxTx — should revert with TX_LIMIT
        vm.prank(bob);
        vm.expectRevert(bytes("TX_LIMIT"));
        token.transfer(alice, want);
    }

    /// boundary conditions exactly equal to limits should pass.
    function test_Boundary_EqualToLimits_Passes() public {
        // Make sure ALICE can send exactly maxTx to BOB
        if (token.balanceOf(alice) < token.maxTx()) {
            _fundToTargetBalance(alice, token.maxTx());
        }
        uint256 aliceBefore = token.balanceOf(alice);

        // Non-excluded -> exactly maxTx should pass
        vm.prank(alice);
        token.transfer(bob, token.maxTx());
        assertEq(token.balanceOf(alice), aliceBefore - token.maxTx(), "alice post-send wrong");
        assertEq(token.balanceOf(bob), token.maxTx(), "bob after equal maxTx send wrong");

        // Now bring BOB to exactly maxWallet (aggregate across sources; expand sources if needed)
        _fundToTargetBalance(bob, token.maxWallet());
        assertEq(token.balanceOf(bob), token.maxWallet(), "bob not at exact maxWallet");
    }

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------

    /// @dev Fund `to` up to `targetBalance` by aggregating from any tx-excluded wallets.
    ///      If the existing excluded set cannot fully cover the target, we (as owner)
    ///      temporarily add additional funded allocation wallets to the tx-exclusion list
    ///      to complete the top-up, then proceed.
    function _fundToTargetBalance(address to, uint256 targetBalance) internal {
        // Quick exit
        uint256 current = token.balanceOf(to);
        if (current >= targetBalance) return;

        // 1) Try current excluded set (multiple passes in case balances change mid-loop)
        _aggregateFromExcluded(to, targetBalance);
        if (token.balanceOf(to) >= targetBalance) return;

        // 2) Not enough? As owner, extend sources by marking more alloc wallets tx-excluded.
        //    This does not affect the semantics under test (recipient wallet limit).
        address[4] memory moreAlloc = [mkt, adv, team, pre];
        for (uint256 i = 0; i < moreAlloc.length; i++) {
            if (!token.isTxLimitExcluded(moreAlloc[i])) {
                token.setTxLimitExcluded(moreAlloc[i], true); // owner is this test contract
            }
        }

        // 3) Try again after expanding the source pool
        _aggregateFromExcluded(to, targetBalance);

        require(
            token.balanceOf(to) >= targetBalance,
            "could not reach target even after expanding excluded pool"
        );
    }

    /// @dev Aggregate from *current* excluded set up to `targetBalance`.
    function _aggregateFromExcluded(address to, uint256 targetBalance) internal {
        uint256 current = token.balanceOf(to);
        if (current >= targetBalance) return;

        address[] memory ex = token.getTxLimitExcluded();
        if (ex.length == 0) return;

        uint256 remaining = targetBalance - current;

        // Do a couple of sweeps; each sweep is O(n) over the excluded list.
        // This avoids any single address "exceeds balance" by always min(bal, remaining).
        for (uint256 sweep = 0; sweep < 3 && remaining > 0; sweep++) {
            for (uint256 i = 0; i < ex.length && remaining > 0; i++) {
                address src = ex[i];
                uint256 bal = token.balanceOf(src);
                if (bal == 0) continue;

                uint256 sendAmt = bal < remaining ? bal : remaining;

                vm.prank(src);
                token.transfer(to, sendAmt);

                remaining -= sendAmt;
            }
        }
    }

    /// @dev Return any excluded wallet that currently holds some balance.
    function _getAnyExcludedWithBalance() internal view returns (address fundedExcluded) {
        address[] memory ex = token.getTxLimitExcluded();
        for (uint256 i = 0; i < ex.length; i++) {
            if (token.balanceOf(ex[i]) > 0) return ex[i];
        }
        return address(0);
    }
}
