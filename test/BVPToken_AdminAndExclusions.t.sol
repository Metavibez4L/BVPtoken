// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";

contract BVPToken_AdminAndExclusions_Test is Test {
    BVPToken token;

    // Re-declare events locally so we can expectEmit against address(token)
    event TxLimitExclusionUpdated(address indexed account, bool isExcluded);
    event WalletLimitExclusionUpdated(address indexed account, bool isExcluded);

    // Constructor allocation wallets (funded at deploy by your token)
    address sale  = makeAddr("SALE");
    address ops   = makeAddr("OPS");
    address pre   = makeAddr("PRESALE");
    address team  = makeAddr("TEAM");
    address mkt   = makeAddr("MARKETING");
    address adv   = makeAddr("ADVISORS");
    address tre   = makeAddr("TREASURY");
    address liq   = makeAddr("LIQUIDITY");

    // Non-excluded test actors
    address userA = makeAddr("USER_A");
    address userB = makeAddr("USER_B");

    function setUp() public {
        token = new BVPToken(sale, ops, pre, team, mkt, adv, tre, liq);

        // Sanity
        assertEq(token.totalSupply(), 1_000_000_000 * 1e18);
        assertGt(token.maxTx(), 0);
        assertGt(token.maxWallet(), 0);

        // Our lab actors should start non-excluded
        assertFalse(token.isTxLimitExcluded(userA));
        assertFalse(token.isWalletLimitExcluded(userA));
        assertFalse(token.isTxLimitExcluded(userB));
        assertFalse(token.isWalletLimitExcluded(userB));
    }

    // -------------------------------------------------------------------------
    // Ownership + admin wiring
    // -------------------------------------------------------------------------

    function test_Ownable2Step_TransferAndAccept() public {
        address newOwner = makeAddr("NEW_OWNER");

        token.transferOwnership(newOwner);

        // Wrong caller cannot accept
        vm.expectRevert("Ownable2Step: caller is not the new owner");
        token.acceptOwnership();

        // Pending owner accepts
        vm.prank(newOwner);
        token.acceptOwnership();

        // Only owner can call admin
        vm.expectRevert("Ownable: caller is not the owner");
        token.setTxLimitExcluded(userA, true);

        vm.prank(newOwner);
        token.setTxLimitExcluded(userA, true);
        assertTrue(token.isTxLimitExcluded(userA));
    }

    function test_ExclusionEvents_Getters_Toggle() public {
        // Expect TxLimitExclusionUpdated(userA, true) emitted by token
        vm.expectEmit(true, false, false, true, address(token));
        emit TxLimitExclusionUpdated(userA, true);
        token.setTxLimitExcluded(userA, true);
        assertTrue(token.isTxLimitExcluded(userA));

        // Expect WalletLimitExclusionUpdated(userB, true) emitted by token
        vm.expectEmit(true, false, false, true, address(token));
        emit WalletLimitExclusionUpdated(userB, true);
        token.setWalletLimitExcluded(userB, true);
        assertTrue(token.isWalletLimitExcluded(userB));

        // Getters include live exclusions
        address[] memory txEx = token.getTxLimitExcluded();
        bool seenA;
        for (uint256 i; i < txEx.length; i++) if (txEx[i] == userA) { seenA = true; break; }
        assertTrue(seenA, "userA missing in tx-limit list");

        address[] memory wEx = token.getWalletLimitExcluded();
        bool seenB;
        for (uint256 i; i < wEx.length; i++) if (wEx[i] == userB) { seenB = true; break; }
        assertTrue(seenB, "userB missing in wallet-limit list");

        // Toggle off
        token.setTxLimitExcluded(userA, false);
        token.setWalletLimitExcluded(userB, false);
        assertFalse(token.isTxLimitExcluded(userA));
        assertFalse(token.isWalletLimitExcluded(userB));
    }

    // -------------------------------------------------------------------------
    // Positive-path limit bypass tests — split & balance-safe
    // -------------------------------------------------------------------------

    /// Sender is tx-excluded: > maxTx must be allowed (recipient wallet-limit neutralized).
    function test_SenderTxExcluded_BypassesMaxTx() public {
        uint256 overTx = token.maxTx() + 1;

        // Fund userA to exactly 'overTx' without tripping wallet limit on userA
        _fundUpTo(userA, overTx); // caps internally to maxWallet if needed
        assertGe(token.balanceOf(userA), overTx, "userA not funded");

        // Mark sender as tx-excluded and assert
        token.setTxLimitExcluded(userA, true);
        assertTrue(token.isTxLimitExcluded(userA), "userA not tx-excluded");

        // Wallet-exclude recipient to isolate tx-limit bypass
        address userC = makeAddr("USER_C");
        token.setWalletLimitExcluded(userC, true);
        assertTrue(token.isWalletLimitExcluded(userC), "userC not wallet-excluded");

        // Send > maxTx from tx-excluded sender; should NOT revert on TX_LIMIT
        vm.prank(userA);
        token.transfer(userC, overTx);

        assertEq(token.balanceOf(userC), overTx, "userC did not receive overTx");
    }

    /// Recipient is wallet-excluded: can receive > maxWallet (while sender respects maxTx).
    function test_RecipientWalletExcluded_BypassesMaxWallet() public {
        // Arrange: fresh recipient, mark wallet-excluded
        address userC = makeAddr("USER_C_WALLET_EXCL");
        token.setWalletLimitExcluded(userC, true);
        assertTrue(token.isWalletLimitExcluded(userC), "userC not wallet-excluded");

        // Ensure sender respects tx limit (explicitly non-excluded)
        token.setTxLimitExcluded(userA, false);
        assertFalse(token.isTxLimitExcluded(userA), "userA tx-excluded unexpectedly");

        // We want to push userC above maxWallet using <= maxTx chunks.
        uint256 targetC = token.maxWallet() + 1;
        uint256 remaining = targetC - token.balanceOf(userC);

        // Loop: for each chunk, fund userA just-in-time to 'amt' without ever exceeding userA's maxWallet.
        while (remaining > 0) {
            uint256 amt = remaining > token.maxTx() ? token.maxTx() : remaining;

            // Make sure userA has at least 'amt', but do not exceed userA's maxWallet when funding.
            uint256 need = amt > token.balanceOf(userA) ? (amt - token.balanceOf(userA)) : 0;
            if (need > 0) {
                // Target absolute balance for userA: min(current + need, maxWallet)
                uint256 targetBal = token.balanceOf(userA) + need;
                uint256 cap = token.maxWallet();
                if (targetBal > cap) targetBal = cap;
                _fundUpTo(userA, targetBal);
                // If still short (because cap == maxWallet), we'll send a smaller chunk first.
                if (token.balanceOf(userA) < amt) {
                    amt = token.balanceOf(userA); // never zero: funding guarantees some progress
                }
            }

            vm.prank(userA);
            token.transfer(userC, amt); // recipient is wallet-excluded, so no WALLET_LIMIT
            remaining -= amt;
        }

        assertGt(token.balanceOf(userC), token.maxWallet(), "userC did not exceed maxWallet");
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// Fund `to` up to `targetAbs` (absolute balance target) by sweeping from tx-excluded wallets.
    /// Never attempts to exceed `maxWallet()` on the recipient; caller should pass a sensible cap.
    function _fundUpTo(address to, uint256 targetAbs) internal {
        uint256 cap = token.maxWallet();
        if (targetAbs > cap) targetAbs = cap; // never try to exceed recipient wallet limit
        if (token.balanceOf(to) >= targetAbs) return;

        // Ensure multiple funded allocs are tx-excluded as sources
        address[8] memory srcs = [sale, ops, tre, liq, mkt, team, pre, adv];
        for (uint256 i; i < srcs.length; i++) {
            if (!token.isTxLimitExcluded(srcs[i])) token.setTxLimitExcluded(srcs[i], true);
        }

        // Sweep excluded sources until target reached
        for (uint256 rounds; rounds < 5 && token.balanceOf(to) < targetAbs; rounds++) {
            address[] memory ex = token.getTxLimitExcluded();
            for (uint256 i; i < ex.length && token.balanceOf(to) < targetAbs; i++) {
                uint256 bal = token.balanceOf(ex[i]);
                if (bal == 0) continue;
                uint256 need = targetAbs - token.balanceOf(to);
                uint256 amt = bal < need ? bal : need;
                vm.prank(ex[i]);
                token.transfer(to, amt);
            }
        }
        require(token.balanceOf(to) >= targetAbs, "funding failed");
    }
}
