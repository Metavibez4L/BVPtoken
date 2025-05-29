// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface for the LineItemRegistry used by VendorPayment
interface ILineItemRegistry {
    function recordPayment(bytes32 projectId, uint256 accountCode, address vendor, uint256 amount) external;
}
