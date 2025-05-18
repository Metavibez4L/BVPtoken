// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BVPStaking is Ownable, ReentrancyGuard {
    IERC20 public bvpToken;
    uint256 public constant LOCK_TIME = 90 days;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        bool unlocked;
    }

    mapping(address => Stake) public stakes;

    constructor(address _bvp) Ownable(msg.sender) {
        bvpToken = IERC20(_bvp);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(stakes[msg.sender].amount == 0, "Already staked");

        bool success = bvpToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        stakes[msg.sender] = Stake(amount, block.timestamp, false);
    }

    function unlock() external {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(!s.unlocked, "Already unlocked");
        require(block.timestamp >= s.timestamp + LOCK_TIME, "Stake still locked");

        s.unlocked = true;
    }

    function unstake() external nonReentrant {
        Stake storage s = stakes[msg.sender];
        require(s.unlocked, "Not unlocked");

        uint256 amt = s.amount;
        delete stakes[msg.sender];

        bool success = bvpToken.transfer(msg.sender, amt);
        require(success, "Transfer failed");
    }

    function emergencyWithdraw(address staker) external onlyOwner nonReentrant {
        Stake storage s = stakes[staker];
        require(s.amount > 0, "Nothing staked");

        uint256 amt = s.amount;
        delete stakes[staker];

        bool success = bvpToken.transfer(owner(), amt);
        require(success, "Transfer failed");
    }

    function getTier(address user) external view returns (string memory) {
        uint256 amt = stakes[user].amount;

        if (amt >= 2_000_000 ether) return "Diamond";
        if (amt >= 1_000_000 ether) return "Platinum";
        if (amt >= 500_000 ether) return "Gold";
        if (amt >= 100_000 ether) return "Silver";
        if (amt >= 20_000 ether) return "Bronze";
        return "None";
    }
}
