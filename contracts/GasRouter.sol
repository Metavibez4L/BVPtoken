// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GasRouter is Ownable {
    IERC20 public immutable bvpToken;
    address public treasury;

    event GasHandled(address indexed user, uint256 amount, uint256 toTreasury, uint256 refunded);

    constructor(address _bvpToken, address _treasury) Ownable(msg.sender) {
        bvpToken = IERC20(_bvpToken);
        treasury = _treasury;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function handleGas(uint256 amount) external {
        require(amount > 0, "Zero amount");

        require(bvpToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 toTreasury = (amount * 20) / 100;
        uint256 rebate = amount - toTreasury;

        require(bvpToken.transfer(treasury, toTreasury), "Treasury transfer failed");
        require(bvpToken.transfer(msg.sender, rebate), "Rebate transfer failed");

        emit GasHandled(msg.sender, amount, toTreasury, rebate);
    }
}
