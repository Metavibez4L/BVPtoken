// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GasRouterUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    IERC20Upgradeable public bvpToken;
    address public treasury; // 🔁 Retained for storage layout compatibility

    mapping(address => uint256) public gasBalances;

    event GasDeposited(address indexed user, uint256 amount);
    event GasWithdrawn(address indexed user, uint256 amount);

    function initialize(address tokenAddress) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        bvpToken = IERC20Upgradeable(tokenAddress);
    }

    function depositGas(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        bvpToken.transferFrom(msg.sender, address(this), amount);
        gasBalances[msg.sender] += amount;
        emit GasDeposited(msg.sender, amount);
    }

    function withdrawGas(uint256 amount) external nonReentrant {
        require(gasBalances[msg.sender] >= amount, "Insufficient gas balance");
        gasBalances[msg.sender] -= amount;
        bvpToken.transfer(msg.sender, amount);
        emit GasWithdrawn(msg.sender, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint256[49] private __gap; // Keep this size the same as previous version
}
