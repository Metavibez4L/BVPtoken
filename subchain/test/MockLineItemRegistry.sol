// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ILineItemRegistry {
    function addLineItem(bytes32, uint256, uint256, address[] memory) external;
}

contract MockLineItemRegistry is ILineItemRegistry {
    event LineItemAdded(bytes32 projectId, uint256 accountCode, uint256 budget, address[] vendors);

    function addLineItem(
        bytes32 projectId,
        uint256 accountCode,
        uint256 budget,
        address[] memory vendors
    ) external override {
        emit LineItemAdded(projectId, accountCode, budget, vendors);
    }
}
