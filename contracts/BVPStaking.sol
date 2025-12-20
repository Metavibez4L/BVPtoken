// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

/// @title BVP Staking Contract
/// @notice Allows users to stake BVP tokens with fixed lock periods to gain tier-based access privileges.
/// @dev Design notes:
///      - Each address may have **at most one active stake** at a time.
///      - Supports three fixed lock durations: 3, 6, and 12 months.
///      - Staked amounts map to fixed, non-upgradeable tiers (Bronze → Diamond).
///      - No rewards or yield are paid; staking is purely for access/eligibility.
///      - Optimized: custom errors, combined operations, efficient tier calculation.
///
/// @custom:security-contact security@bigvisionpictures.io
/// @custom:security-features
///      - ReentrancyGuard on all state-changing functions
///      - CEI (Checks-Effects-Interactions) pattern: state cleared before token transfers
///      - No admin functions: fully decentralized post-deployment
///      - Lock periods enforced by immutable constants and block.timestamp
/// @custom:invariants
///      - User can have 0 or 1 stake, never more
///      - If stake exists: stake.amount > 0
///      - If unlocked: block.timestamp >= stake.timestamp + stake.lockTime
///      - Contract balance >= sum of all active stake amounts
///      - Tier code always in range [0, 5] inclusive
/// @custom:assumptions
///      - BVP token address is valid ERC-20 (checked: non-zero, fails safely if invalid)
///      - block.timestamp is reliable (consensus-based, not manipulatable by single validator)
///      - No emergency unlock: users must wait full lock period (by design)
contract BVPStaking is ReentrancyGuard {
    // ---- Custom Errors ----
    error ZeroAddress();
    error ZeroAmount();
    error AlreadyStaked();
    error NoStake();
    error AlreadyUnlocked();
    error StillLocked();
    error NotUnlocked();
    error TransferFailed();
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
        if (_bvpToken == address(0)) revert ZeroAddress();
        bvpToken = IERC20(_bvpToken);
    }

    function _stake(uint256 amount, uint256 lockTime) internal nonReentrant {
        if (amount == 0) revert ZeroAmount();

        Stake storage s = stakes[msg.sender];
        if (s.amount != 0) revert AlreadyStaked();

        s.amount = amount;
        s.timestamp = block.timestamp;
        s.lockTime = lockTime;
        s.unlocked = false;

        if (!bvpToken.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        unchecked {
            emit Staked(msg.sender, amount, lockTime, block.timestamp + lockTime);
        }
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
        if (s.amount == 0) revert NoStake();
        if (s.unlocked) revert AlreadyUnlocked();
        
        unchecked {
            if (block.timestamp < s.timestamp + s.lockTime) revert StillLocked();
        }

        s.unlocked = true;
        emit Unlocked(msg.sender, block.timestamp);
    }

    function unstake() external nonReentrant {
        Stake memory s = stakes[msg.sender];
        if (!s.unlocked) revert NotUnlocked();

        delete stakes[msg.sender];
        if (!bvpToken.transfer(msg.sender, s.amount)) revert TransferFailed();

        emit Unstaked(msg.sender, s.amount);
    }

    /// @notice Combined unlock and unstake in a single transaction (gas-efficient)
    /// @dev Only works if lock period has expired; reverts otherwise
    function unlockAndUnstake() external nonReentrant {
        Stake memory s = stakes[msg.sender];
        if (s.amount == 0) revert NoStake();
        
        unchecked {
            if (block.timestamp < s.timestamp + s.lockTime) revert StillLocked();
        }

        delete stakes[msg.sender];
        if (!bvpToken.transfer(msg.sender, s.amount)) revert TransferFailed();

        emit Unlocked(msg.sender, block.timestamp);
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
        unchecked {
            unlockAt = s.timestamp + s.lockTime;
        }
    }

    /// @dev Optimized tier calculation using binary search pattern (descending)
    function getTierCode(address user) public view returns (uint8) {
        uint256 a = stakes[user].amount;
        // Binary search: check mid-tier first, then split
        if (a >= TH_GOLD) {
            // Upper half: Gold/Platinum/Diamond
            if (a >= TH_DIAMOND) return 5;
            if (a >= TH_PLATINUM) return 4;
            return 3;
        } else if (a >= TH_BRONZE) {
            // Lower half: Bronze/Silver
            if (a >= TH_SILVER) return 2;
            return 1;
        }
        return 0;
    }

    function getTierName(address user) external view returns (string memory) {
        uint8 code = getTierCode(user);
        if (code == 5) return "Diamond";
        if (code == 4) return "Platinum";
        if (code == 3) return "Gold";
        if (code == 2) return "Silver";
        if (code == 1) return "Bronze";
        return "None";
    }

}
