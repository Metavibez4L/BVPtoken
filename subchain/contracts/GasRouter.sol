// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { AccessControl } from "openzeppelin-contracts/access/AccessControl.sol";

/// @title BVPGasRouter
/// @notice Handles prepayment and accounting of gas fees in BVPToken for L3 transactions
contract GasRouter is AccessControl {
    bytes32 public constant ROLE_TREASURY = keccak256("ROLE_TREASURY");

    IERC20 public immutable bvpToken;
    address public treasury;
    uint256 public gasUnitPrice; // in wei per gas unit, e.g. 1e14 = 0.0001 BVP

    event GasPaid(address indexed user, uint256 gasUsed, uint256 cost);
    event TreasuryUpdated(address indexed newTreasury);
    event GasPriceUpdated(uint256 newPrice);

    constructor(address _bvpToken, address _treasury, uint256 _gasUnitPrice) {
        require(_bvpToken != address(0), "Invalid token");
        require(_treasury != address(0), "Invalid treasury");
        require(_gasUnitPrice > 0, "Invalid gas price");

        bvpToken = IERC20(_bvpToken);
        treasury = _treasury;
        gasUnitPrice = _gasUnitPrice;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_TREASURY, _treasury);
    }

    /// @notice Called by apps to prepay gas in BVP
    /// @param user User who is paying the gas
    /// @param gasUsed Estimated gas units
    function prepayGas(address user, uint256 gasUsed) external {
        uint256 totalCost = gasUsed * gasUnitPrice;
        require(bvpToken.transferFrom(user, treasury, totalCost), "BVP transfer failed");
        emit GasPaid(user, gasUsed, totalCost);
    }

    /// @notice Admin function to update treasury wallet
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Zero addr");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    /// @notice Admin function to update gas unit pricing
    function setGasPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPrice > 0, "Zero price");
        gasUnitPrice = newPrice;
        emit GasPriceUpdated(newPrice);
    }
}
