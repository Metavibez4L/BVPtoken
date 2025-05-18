// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GasRouterUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    IERC20Upgradeable public bvpToken;
    address public treasury;

    event GasHandled(address indexed user, uint256 amount, uint256 toTreasury, uint256 rebate);

    function initialize(address _bvpToken, address _treasury) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_treasury != address(0), "Invalid treasury");
        bvpToken = IERC20Upgradeable(_bvpToken);
        treasury = _treasury;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
