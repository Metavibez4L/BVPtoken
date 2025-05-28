// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/LineItemRegistry.sol";

contract LineItemRegistryTest is Test {
    LineItemRegistry public registry;

    bytes32 public constant projectId = keccak256("TestProduction");
    uint256 public constant accountCode = 401;
    address public producer = address(0xABCD);

    function setUp() public {
        registry = new LineItemRegistry();

        // Grant necessary roles to this test contract
        registry.grantRole(registry.ROLE_ADMIN(), address(this));
        registry.grantRole(registry.ROLE_PRODUCER(), address(this));
    }

    function testAddLineItemAndRecordSpend() public {
        // Add a new budget line item for "Principal Cast"
        registry.addLineItem(projectId, accountCode, "Principal Cast", 10000e18);

        // Fetch values to validate the budget setup
        (
            string memory desc,
            uint256 budgeted,
            uint256 spent,
            
        ) = registry.getLineItem(projectId, accountCode);

        assertEq(desc, "Principal Cast");
        assertEq(budgeted, 10000e18);
        assertEq(spent, 0);

        // Record a payment of 2500 BVP
        registry.recordPayment(projectId, accountCode, producer, 2500e18);

        // Validate updated state
        (, , uint256 updatedSpent, address[] memory updatedVendors) = registry.getLineItem(projectId, accountCode);
        assertEq(updatedSpent, 2500e18);
        assertEq(updatedVendors.length, 1);
        assertEq(updatedVendors[0], producer);
    }

    function testCannotOverspendLineItem() public {
        registry.addLineItem(projectId, accountCode, "Principal Cast", 5000e18);

        // This spend is within budget
        registry.recordPayment(projectId, accountCode, producer, 4000e18);

        // This spend exceeds budget — should revert
        vm.expectRevert("Exceeds line item budget");
        registry.recordPayment(projectId, accountCode, producer, 2000e18);
    }
}
