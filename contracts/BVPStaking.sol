// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title BVP Staking Contract
/// @notice Allows users to stake BVP tokens with fixed lock periods to gain tier-based access privileges.
/// @dev This contract supports three staking durations (3m, 6m, 12m) and maps stake amounts to predefined tiers.
contract BVPStaking is ReentrancyGuard {
    IERC20 public immutable bvpToken;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 lockTime;
        bool unlocked;
    }

    mapping(address => Stake) private stakes;

    uint256 public constant LOCK_TIME_3M  = 90 days;
    uint256 public constant LOCK_TIME_6M  = 180 days;
    uint256 public constant LOCK_TIME_12M = 365 days;

    uint256 private constant TH_BRONZE   = 20_000   * 1e18;
    uint256 private constant TH_SILVER   = 100_000  * 1e18;
    uint256 private constant TH_GOLD     = 500_000  * 1e18;
    uint256 private constant TH_PLATINUM = 1_000_000 * 1e18;
    uint256 private constant TH_DIAMOND  = 2_000_000 * 1e18;

    event Staked(address indexed user, uint256 amount, uint256 lockTime, uint256 unlockAt);
    event Unlocked(address indexed user, uint256 when);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _bvpToken) {
        require(_bvpToken != address(0), "Zero token");
        bvpToken = IERC20(_bvpToken);
    }

    function _stake(uint256 amount, uint256 lockTime) internal nonReentrant {
        require(amount > 0, "Zero amount");

        Stake storage s = stakes[msg.sender];
        require(s.amount == 0, "Already staked");

        s.amount = amount;
        s.timestamp = block.timestamp;
        s.lockTime = lockTime;
        s.unlocked = false;

        require(bvpToken.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");

        emit Staked(msg.sender, amount, lockTime, block.timestamp + lockTime);
    }

    function stake3Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_3M);
    }

    function stake6Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_6M);
    }

    function stake12Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_12M);
    }

    function unlock() external nonReentrant {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(!s.unlocked, "Already unlocked");
        require(block.timestamp >= s.timestamp + s.lockTime, "Still locked");

        s.unlocked = true;
        emit Unlocked(msg.sender, block.timestamp);
    }

    function unstake() external nonReentrant {
        Stake memory s = stakes[msg.sender];
        require(s.unlocked, "Not unlocked");

        delete stakes[msg.sender];
        require(bvpToken.transfer(msg.sender, s.amount), "TRANSFER_FAILED");

        emit Unstaked(msg.sender, s.amount);
    }

    function getStake(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 timestamp,
            uint256 lockTime,
            bool unlocked,
            uint256 unlockAt
        )
    {
        Stake storage s = stakes[user];
        amount = s.amount;
        timestamp = s.timestamp;
        lockTime = s.lockTime;
        unlocked = s.unlocked;
        unlockAt = s.timestamp + s.lockTime;
    }

    function getTierCode(address user) public view returns (uint8) {
        uint256 a = stakes[user].amount;
        if (a >= TH_DIAMOND) return 5;
        if (a >= TH_PLATINUM) return 4;
        if (a >= TH_GOLD) return 3;
        if (a >= TH_SILVER) return 2;
        if (a >= TH_BRONZE) return 1;
        return 0;
    }

    function getTierName(address user) external view returns (string memory) {
        uint8 code = getTierCode(user);
        if (code == 1) return "Bronze";
        if (code == 2) return "Silver";
        if (code == 3) return "Gold";
        if (code == 4) return "Platinum";
        if (code == 5) return "Diamond";
        return "None";
    }

}
