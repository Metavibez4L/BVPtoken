// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { MockERC20 } from "./MockERC20.sol";
import { MockLineItemRegistry } from "./MockLineItemRegistry.sol";
import { VendorPayment } from "../contracts/VendorPayment.sol";

// Replace these with the actual values or interface if needed!
contract VendorPaymentTest is Test {
    VendorPayment vendorPayment;
    MockLineItemRegistry registry;
    MockERC20 bvp;

    // Role constants must match those in your VendorPayment.sol
    bytes32 constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 constant ROLE_PRODUCER = keccak256("ROLE_PRODUCER");
    bytes32 constant ROLE_TREASURY = keccak256("ROLE_TREASURY");

    function setUp() public {
        bvp = new MockERC20();
        registry = new MockLineItemRegistry();
        vendorPayment = new VendorPayment(address(bvp), address(registry));

        vendorPayment.grantRole(ROLE_ADMIN, address(this));
        vendorPayment.grantRole(ROLE_PRODUCER, address(this));
        vendorPayment.grantRole(ROLE_TREASURY, address(this));
    }

    function testQueueAndExecutePayment() public {
        bytes32 projectId = keccak256("project");
        uint256 accountCode = 123;
        address recipient = address(0xBEEF);
        uint256 amount = 100 ether;

        address[] memory vendors = new address[](1);
        vendors[0] = recipient;
        registry.addLineItem(projectId, accountCode, 200 ether, vendors);

        // Comment out if your VendorPayment does not require this:
        // vendorPayment.registerVendor(recipient, "Camera Op", 150 ether);

        bvp.mint(address(vendorPayment), 200 ether);

        vendorPayment.queuePayment(projectId, accountCode, recipient, amount);
        vendorPayment.executePayment(0);

        assertEq(bvp.balanceOf(recipient), amount);
    }
}
