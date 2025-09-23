// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";

contract BVPToken_AdminAndExclusions_Test is Test {
    // Constructor recipients (must line up with BVPToken’s constructor)
    address public deployer;
    address public publicSale;
    address public operations;
    address public presale;
    address public foundersAndTeam;
    address public marketing;
    address public advisors;
    address public treasury;
    address public liquidity;

    // Extra users for transfer tests
    address public userA;
    address public userB;

    BVPToken token;

    function setUp() public {
        // Deterministic helpful labels for traces
        deployer        = makeAddr("deployer");
        publicSale      = makeAddr("publicSale");
        operations      = makeAddr("operations");
        presale         = makeAddr("presale");
        foundersAndTeam = makeAddr("foundersAndTeam");
        marketing       = makeAddr("marketing");
        advisors        = makeAddr("advisors");
        treasury        = makeAddr("treasury");
        liquidity       = makeAddr("liquidity");

        userA = makeAddr("userA");
        userB = makeAddr("userB");

        vm.prank(deployer);
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

    // --- Helpers ---

    function _maxTx() internal view returns (uint256) {
        return token.maxTx();
    }

    function _maxWallet() internal view returns (uint256) {
        return token.maxWallet();
    }

    // --- Tests ---

    /// Ensures defaults match the “operational freedom” addresses
    /// you set during construction.
    function test_DefaultExclusions_AreSet_OnDeploy() public view {
        // Sender-side (tx) exclusions
        assertTrue(token.isTxLimitExcluded(publicSale),   "publicSale tx not excluded");
        assertTrue(token.isTxLimitExcluded(operations),   "operations tx not excluded");
        assertTrue(token.isTxLimitExcluded(treasury),     "treasury tx not excluded");
        assertTrue(token.isTxLimitExcluded(liquidity),    "liquidity tx not excluded");

        // Recipient-side (wallet) exclusions
        assertTrue(token.isWalletLimitExcluded(publicSale), "publicSale wallet not excluded");
        assertTrue(token.isWalletLimitExcluded(operations), "operations wallet not excluded");
        assertTrue(token.isWalletLimitExcluded(treasury),   "treasury wallet not excluded");
        assertTrue(token.isWalletLimitExcluded(liquidity),  "liquidity wallet not excluded");

        // A few non-excluded should be false
        assertFalse(token.isTxLimitExcluded(presale), "presale tx should NOT be excluded");
        assertFalse(token.isWalletLimitExcluded(presale), "presale wallet should NOT be excluded");
    }

    /// Non-excluded sender must respect maxTx.
    /// Choose amount = maxTx + 1 but <= maxWallet so only the tx check trips.
    function test_AntiWhale_MaxTx_Enforced_For_NonExcluded_Sender() public {
        uint256 amt = _maxTx() + 1;
        require(amt <= _maxWallet(), "test assumes maxTx < maxWallet");

        // presale is not tx-excluded and has balance from allocations
        vm.startPrank(presale);
        vm.expectRevert(bytes("TX_LIMIT"));
        token.transfer(userA, amt);
        vm.stopPrank();
    }

    /// Non-excluded recipient must respect maxWallet, even if sender is excluded.
    /// Send (maxWallet + 1) from an excluded sender => wallet check should trip.
    function test_AntiWhale_MaxWallet_Enforced_For_NonExcluded_Recipient() public {
        uint256 amt = _maxWallet() + 1;

        // publicSale is excluded and has large allocation; userA is not excluded
        vm.prank(publicSale);
        vm.expectRevert(bytes("WALLET_LIMIT"));
        token.transfer(userA, amt);
    }

    /// Excluded sender bypasses tx limit (but we still keep recipient under wallet limit).
    function test_Excluded_Sender_Bypasses_MaxTx() public {
        uint256 amt = _maxTx() + 1; // > maxTx, but <= maxWallet for recipient
        require(amt <= _maxWallet(), "test assumes maxTx < maxWallet");

        // publicSale is tx-excluded
        vm.prank(publicSale);
        token.transfer(userA, amt);

        assertEq(token.balanceOf(userA), amt, "recipient did not receive");
    }

    /// Excluded recipient bypasses wallet limit (sender must still respect maxTx).
    function test_Excluded_Recipient_Bypasses_MaxWallet() public {
        // Use a non-excluded sender (presale). Amount must be <= maxTx.
        uint256 amt = _maxTx(); // boundary, valid for non-excluded sender
        // Recipient is liquidity (wallet-excluded)
        vm.prank(presale);
        token.transfer(liquidity, amt);

        assertEq(token.balanceOf(liquidity), (token.cap() * 5) / 100 + amt, "excluded recipient did not receive");
    }
}
