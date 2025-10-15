// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/BVPToken.sol";

contract BVPToken_Permit_Test is Test {
    // Keys/addresses so we can sign EIP-2612 permits
    uint256 internal constant PK_FOUNDERS = 0xD0D; // will own tokens (10% allocation)
    uint256 internal constant PK_SPENDER  = 0xABCD;

    address internal founders = vm.addr(PK_FOUNDERS);
    address internal spender  = vm.addr(PK_SPENDER);
    address internal recipient = makeAddr("recipient");

    BVPToken internal token;

    function setUp() public {
        // Other allocation addresses can be arbitrary; only founders must be known for signing
        token = new BVPToken(
            makeAddr("publicSale"),
            makeAddr("operations"),
            makeAddr("presale"),
            founders,                 // founders receives 10%
            makeAddr("marketing"),
            makeAddr("advisors"),
            makeAddr("treasury"),
            makeAddr("liquidity")
        );
    }

    function test_Permit_Allows_Spend_And_NonceIncrements() public {
        uint256 amount = 1e18; // keep tiny to avoid whale limits
        uint256 deadline = block.timestamp + 1 days;

        // Build EIP-2612 permit digest
        bytes32 TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                TYPEHASH,
                founders,
                spender,
                amount,
                token.nonces(founders),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK_FOUNDERS, digest);

        // Permit
        token.permit(founders, spender, amount, deadline, v, r, s);

        // Nonce bumped
        assertEq(token.nonces(founders), 1);

        // Spend via transferFrom (still under maxTx and recipient << maxWallet)
        vm.prank(spender);
        token.transferFrom(founders, recipient, amount);

        assertEq(token.balanceOf(recipient), amount);
    }
}
