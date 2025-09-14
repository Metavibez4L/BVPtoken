// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";

contract BVPToken_Permit_Test is Test {
    BVPToken token;

    address sale  = makeAddr("SALE");
    address ops   = makeAddr("OPS");
    address pre   = makeAddr("PRESALE");
    address team  = makeAddr("TEAM");
    address mkt   = makeAddr("MARKETING");
    address adv   = makeAddr("ADVISORS");
    address tre   = makeAddr("TREASURY");
    address liq   = makeAddr("LIQUIDITY");

    uint256 ownerPk = 0xA11CE; // test private key
    address ownerAddr;
    address spender = makeAddr("SPENDER");

    function setUp() public {
        token = new BVPToken(sale, ops, pre, team, mkt, adv, tre, liq);
        ownerAddr = vm.addr(ownerPk);

        // fund ownerAddr so transferFrom has balance to move
        _fundToTarget(ownerAddr, 1_000 * 1e18);
    }

    function test_Permit_Allows_Spend_And_NonceIncrements() public {
        uint256 value = 123 * 1e18;
        uint256 nonceBefore = token.nonces(ownerAddr);
        uint256 deadline = block.timestamp + 3600;

        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            ownerPk,
            ownerAddr,
            spender,
            value,
            nonceBefore,
            deadline
        );

        token.permit(ownerAddr, spender, value, deadline, v, r, s);
        assertEq(token.nonces(ownerAddr), nonceBefore + 1, "nonce not incremented");
        assertEq(token.allowance(ownerAddr, spender), value, "allowance not set");

        // spender pulls tokens via transferFrom
        vm.prank(spender);
        token.transferFrom(ownerAddr, spender, value);
        assertEq(token.balanceOf(spender), value);
    }

    // ---- helpers ----

    function _signPermit(
        uint256 pk,
        address owner_,
        address spender_,
        uint256 value_,
        uint256 nonce_,
        uint256 deadline_
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        bytes32 PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner_,
                spender_,
                value_,
                nonce_,
                deadline_
            )
        );

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        (v, r, s) = vm.sign(pk, digest);
    }

    function _fundToTarget(address to, uint256 target) internal {
        if (token.balanceOf(to) >= target) return;
        // ensure multiple sources are tx-excluded
        address[4] memory srcs = [sale, ops, tre, liq];
        for (uint256 i; i < srcs.length; i++) {
            if (!token.isTxLimitExcluded(srcs[i])) token.setTxLimitExcluded(srcs[i], true);
        }
        for (uint256 rounds; rounds < 3 && token.balanceOf(to) < target; rounds++) {
            address[] memory ex = token.getTxLimitExcluded();
            for (uint256 i; i < ex.length; i++) {
                uint256 bal = token.balanceOf(ex[i]);
                if (bal == 0) continue;
                uint256 need = target - token.balanceOf(to);
                uint256 amt = bal < need ? bal : need;
                vm.prank(ex[i]);
                token.transfer(to, amt);
                if (token.balanceOf(to) >= target) break;
            }
        }
        require(token.balanceOf(to) >= target, "funding failed");
    }
}
