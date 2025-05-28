// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @title LineItemRegistry
/// @notice Tracks budgeted line items and actual spend for each project.
///         Allows producers to record vendor payments and prevents overspending.
contract LineItemRegistry is AccessControl {
    /// Role that can define budgeted line items
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    /// Role that can record spend events against line items
    bytes32 public constant ROLE_PRODUCER = keccak256("ROLE_PRODUCER");

    /// Struct for each line item budget entry
    struct LineItem {
        string description;         // Human-readable label (e.g., "Principal Cast")
        uint256 budgeted;           // Budget allocated for this line item
        uint256 spent;              // Total BVP spent so far
        address[] vendors;          // Vendors paid under this line item
    }

    /// projectId => accountCode => LineItem
    mapping(bytes32 => mapping(uint256 => LineItem)) private projectLineItems;

    /// projectId => accountCode => exists
    mapping(bytes32 => mapping(uint256 => bool)) public isLineItemSet;

    event LineItemAdded(bytes32 indexed projectId, uint256 accountCode, string description, uint256 budget);
    event PaymentRecorded(bytes32 indexed projectId, uint256 accountCode, address vendor, uint256 amount);

    /// @notice Sets up roles on deploy
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_ADMIN, msg.sender);
    }

    // -----------------------------
    // Admin Functions
    // -----------------------------

    /// @notice Adds a line item to a project’s budget
    /// @param projectId The keccak256 hash ID of the project
    /// @param accountCode Budget code (e.g., 401 for Principal Cast)
    /// @param description A text label for the line item
    /// @param budgeted Total BVP allocated to this line item
    function addLineItem(
        bytes32 projectId,
        uint256 accountCode,
        string calldata description,
        uint256 budgeted
    ) external onlyRole(ROLE_ADMIN) {
        require(!isLineItemSet[projectId][accountCode], "Line item already exists");

        LineItem storage item = projectLineItems[projectId][accountCode];
        item.description = description;
        item.budgeted = budgeted;

        isLineItemSet[projectId][accountCode] = true;

        emit LineItemAdded(projectId, accountCode, description, budgeted);
    }

    // -----------------------------
    // Producer Functions
    // -----------------------------

    /// @notice Records spending against a specific budget line item
    /// @dev Reverts if over budget
    function recordPayment(
        bytes32 projectId,
        uint256 accountCode,
        address vendor,
        uint256 amount
    ) external onlyRole(ROLE_PRODUCER) {
        require(isLineItemSet[projectId][accountCode], "Invalid line item");

        LineItem storage item = projectLineItems[projectId][accountCode];
        require(item.spent + amount <= item.budgeted, "Exceeds line item budget");

        item.spent += amount;
        item.vendors.push(vendor);

        emit PaymentRecorded(projectId, accountCode, vendor, amount);
    }

    // -----------------------------
    // View Functions
    // -----------------------------

    /// @notice Returns metadata for a line item
    function getLineItem(
        bytes32 projectId,
        uint256 accountCode
    ) external view returns (
        string memory description,
        uint256 budgeted,
        uint256 spent,
        address[] memory vendors
    ) {
        LineItem storage item = projectLineItems[projectId][accountCode];
        return (
            item.description,
            item.budgeted,
            item.spent,
            item.vendors
        );
    }
}
