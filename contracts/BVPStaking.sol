// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title BVP Staking Contract
/// @notice Allows users to stake BVP tokens with fixed lock periods to gain tier-based access privileges.
/// @dev This contract supports three staking durations (3m, 6m, 12m) and maps stake amounts to predefined tiers.
contract BVPStaking is ReentrancyGuard {
    IERC20 public immutable bvpToken;

    /// @dev Struct to hold individual staking data
    struct Stake {
        uint256 amount;     // Amount of BVP tokens staked
        uint256 timestamp;  // Timestamp when the stake was made
        uint256 lockTime;   // Lock duration in seconds
        bool    unlocked;   // Whether the stake has been unlocked
    }

    /// @dev Mapping of user address to their stake record
    mapping(address => Stake) private stakes;

    // Lock durations for different staking terms
    uint256 public constant LOCK_TIME_3M  = 90 days;
    uint256 public constant LOCK_TIME_6M  = 180 days;
    uint256 public constant LOCK_TIME_12M = 365 days;

    // Tier thresholds in token amount (scaled to 18 decimals)
    uint256 private constant TH_BRONZE   = 20_000   * 1e18;
    uint256 private constant TH_SILVER   = 100_000  * 1e18;
    uint256 private constant TH_GOLD     = 500_000  * 1e18;
    uint256 private constant TH_PLATINUM = 1_000_000 * 1e18;
    uint256 private constant TH_DIAMOND  = 2_000_000 * 1e18;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 lockTime, uint256 unlockAt);
    event Unlocked(address indexed user, uint256 when);
    event Unstaked(address indexed user, uint256 amount);

    /// @notice Constructor to initialize staking token
    /// @param _bvpToken ERC20 token address used for staking
    constructor(address _bvpToken) {
        require(_bvpToken != address(0), "Zero token");
        bvpToken = IERC20(_bvpToken);
    }

    /// @dev Internal staking logic with reentrancy protection
    /// @param amount Amount of BVP tokens to stake
    /// @param lockTime Lock duration in seconds (must match one of the constants)
    function _stake(uint256 amount, uint256 lockTime) internal nonReentrant {
        require(amount > 0, "Zero amount");

        Stake storage s = stakes[msg.sender];
        require(s.amount == 0, "Already staked"); // Only one active stake allowed

        s.amount    = amount;
        s.timestamp = block.timestamp;
        s.lockTime  = lockTime;
        s.unlocked  = false;

        require(bvpToken.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");

        emit Staked(msg.sender, amount, lockTime, block.timestamp + lockTime);
    }

    /// @notice Stake BVP tokens with a 3-month lock period
    function stake3Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_3M);
    }

    /// @notice Stake BVP tokens with a 6-month lock period
    function stake6Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_6M);
    }

    /// @notice Stake BVP tokens with a 12-month lock period
    function stake12Months(uint256 amount) external {
        _stake(amount, LOCK_TIME_12M);
    }

    /// @notice Unlock tokens after lock period has passed
    function unlock() external nonReentrant {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(!s.unlocked, "Already unlocked");
        require(block.timestamp >= s.timestamp + s.lockTime, "Still locked");

        s.unlocked = true;
        emit Unlocked(msg.sender, block.timestamp);
    }

    /// @notice Withdraw tokens after they have been unlocked
    function unstake() external nonReentrant {
        Stake memory s = stakes[msg.sender];
        require(s.unlocked, "Not unlocked");

        delete stakes[msg.sender];
        require(bvpToken.transfer(msg.sender, s.amount), "TRANSFER_FAILED");

        emit Unstaked(msg.sender, s.amount);
    }

    /// @notice View stake details for a user
    /// @param user The address of the user
    /// @return amount Staked amount
    /// @return timestamp Timestamp when the stake was made
    /// @return lockTime Lock duration
    /// @return unlocked Unlock status
    /// @return unlockAt Timestamp when funds become eligible for unlock
    function getStake(address user)
        external view
        returns (
            uint256 amount,
            uint256 timestamp,
            uint256 lockTime,
            bool unlocked,
            uint256 unlockAt
        )
    {
        Stake storage s = stakes[user];
        amount   = s.amount;
        timestamp= s.timestamp;
        lockTime = s.lockTime;
        unlocked = s.unlocked;
        unlockAt = s.timestamp + s.lockTime;
    }

    /// @notice Returns the tier code based on a user’s staked amount
    /// @dev Tier codes: 0=None, 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Diamond
    /// @param user The address to check tier for
    /// @return uint8 Tier code
    function getTierCode(address user) public view returns (uint8) {
        uint256 a = stakes[user].amount;
        if (a >= TH_DIAMOND)  return 5;
        if (a >= TH_PLATINUM) return 4;
        if (a >= TH_GOLD)     return 3;
        if (a >= TH_SILVER)   return 2;
        if (a >= TH_BRONZE)   return 1;
        return 0;
    }

    /// @notice Returns the name of the user’s tier based on their stake
    /// @param user The address to query
    /// @return string Human-readable tier name
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
