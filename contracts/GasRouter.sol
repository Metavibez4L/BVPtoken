// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GasRouter is Ownable, ReentrancyGuard {
    IERC20 public bvpToken;
    address public treasury;

    event GasHandled(address indexed user, uint256 amount, uint256 toTreasury, uint256 rebate);

    constructor(address _bvpToken, address _treasury) Ownable(msg.sender) {
        require(_treasury != address(0), "Invalid treasury");
        bvpToken = IERC20(_bvpToken);
        treasury = _treasury;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");
        treasury = newTreasury;
    }

    function handleGas(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid");

        uint256 toTreasury = (amount * 80) / 100;
        uint256 rebate = amount - toTreasury;

        bool pulled = bvpToken.transferFrom(msg.sender, address(this), amount);
        require(pulled, "Pull failed");

        bool sentToTreasury = bvpToken.transfer(treasury, toTreasury);
        require(sentToTreasury, "Treasury fail");

        bool refunded = bvpToken.transfer(msg.sender, rebate);
        require(refunded, "Rebate fail");

        emit GasHandled(msg.sender, amount, toTreasury, rebate);
    }
}
