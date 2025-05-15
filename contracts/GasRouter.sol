// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "hardhat/console.sol"; // ✅ Required for console logging
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GasRouter is Ownable {
    IERC20 public immutable bvpToken;
    address public treasury;

    event GasHandled(address indexed user, uint256 amount, uint256 toTreasury, uint256 refunded);

    constructor(address _bvpToken, address _treasury) Ownable(msg.sender) {
        bvpToken = IERC20(_bvpToken);
        treasury = _treasury;

        // ✅ Will show in Hardhat output
        console.log("GasRouter deployed. Treasury address is:", treasury);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function handleGas(uint256 amount) external {
        require(amount > 0, "Zero amount");

        bool pulled = bvpToken.transferFrom(msg.sender, address(this), amount);
        require(pulled, "TransferFrom failed");

        uint256 toTreasury = (amount * 20) / 100;
        uint256 rebate = amount - toTreasury;

        bool sentToTreasury = bvpToken.transfer(treasury, toTreasury);
        require(sentToTreasury, "Treasury transfer failed");

        bool refunded = bvpToken.transfer(msg.sender, rebate);
        require(refunded, "Rebate transfer failed");

        emit GasHandled(msg.sender, amount, toTreasury, rebate);
    }
}
