// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BVPStaking is Ownable {
    IERC20 public immutable bvpToken;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        bool unlocked;
    }

    mapping(address => Stake) public stakes;

    uint256 public constant LOCK_TIME = 90 days;

    constructor(IERC20 _token) Ownable(msg.sender) {
        bvpToken = _token;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(stakes[msg.sender].amount == 0, "Already staked");

        bvpToken.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = Stake(amount, block.timestamp, false);
    }

    function unlock() external {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(!s.unlocked, "Already unlocked");
        require(block.timestamp >= s.timestamp + LOCK_TIME, "Stake is still locked");

        s.unlocked = true;
    }

    function unstake() external {
        Stake storage s = stakes[msg.sender];
        require(s.unlocked, "Not unlocked");
        uint256 amt = s.amount;
        require(amt > 0, "No staked balance");

        s.amount = 0;
        bvpToken.transfer(msg.sender, amt);
    }

    function emergencyWithdraw(address user) external onlyOwner {
        Stake storage s = stakes[user];
        require(s.amount > 0, "Nothing to withdraw");

        uint256 amt = s.amount;
        s.amount = 0;
        bvpToken.transfer(owner(), amt);
    }

    function getTier(address user) public view returns (string memory) {
        uint256 amt = stakes[user].amount;
        if (amt >= 2_000_000 ether) return "Diamond";
        if (amt >= 1_000_000 ether) return "Platinum";
        if (amt >= 500_000 ether) return "Gold";
        if (amt >= 100_000 ether) return "Silver";
        if (amt >= 20_000 ether) return "Bronze";
        return "None";
    }
}
