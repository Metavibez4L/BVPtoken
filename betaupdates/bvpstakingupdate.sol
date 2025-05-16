// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BVPStaking is Ownable {
    IERC20 public immutable bvpToken;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 lockTime;
        bool    unlocked;
    }

    mapping(address => Stake) public stakes;

    uint256 public constant LOCK_TIME       = 90 days;
    uint256 public constant SIX_MONTHS      = 180 days;
    uint256 public constant TWELVE_MONTHS   = 365 days;

    constructor(IERC20 _token) Ownable(msg.sender) {
        bvpToken = _token;
    }

    /// @notice Stake with the default 90-day lock
    function stake(uint256 amount) external {
        _stake(amount, LOCK_TIME);
    }

    /// @notice Stake with a custom lock period (90d, 6m, or 12m)
    function stake(uint256 amount, uint256 lockPeriod) external {
        _stake(amount, lockPeriod);
    }

    function _stake(uint256 amount, uint256 lockPeriod) internal {
        require(amount > 0, "Invalid amount");
        require(stakes[msg.sender].amount == 0, "Already staked");
        require(
            lockPeriod == LOCK_TIME ||
            lockPeriod == SIX_MONTHS ||
            lockPeriod == TWELVE_MONTHS,
            "Invalid lock period"
        );

        // Pull tokens and record the stake
        bvpToken.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] = Stake({
            amount:    amount,
            timestamp: block.timestamp,
            lockTime:  lockPeriod,
            unlocked:  false
        });
    }

    /// @notice After lock elapses, mark unlocked
    function unlock() external {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");
        require(!s.unlocked, "Already unlocked");
        require(
            block.timestamp >= s.timestamp + s.lockTime,
            "Stake still locked"
        );
        s.unlocked = true;
    }

    /// @notice Withdraw your tokens once unlocked
    function unstake() external {
        Stake storage s = stakes[msg.sender];
        require(s.unlocked, "Not unlocked");

        uint256 amt = s.amount;
        require(amt > 0, "No stake");

        s.amount = 0;
        bvpToken.transfer(msg.sender, amt);
    }

    /// @notice Emergency rescue of a user's stake (owner only)
    function emergencyWithdraw(address user) external onlyOwner {
        Stake storage s = stakes[user];
        require(s.amount > 0, "Nothing staked");

        uint256 amt = s.amount;
        s.amount = 0;
        bvpToken.transfer(owner(), amt);
    }

    /// @notice Returns tier name based on staked amount
    function getTier(address user) public view returns (string memory) {
        uint256 amt = stakes[user].amount;
        if (amt >= 2_000_000 ether) return "Diamond";
        if (amt >= 1_000_000 ether) return "Platinum";
        if (amt >=   500_000 ether) return "Gold";
        if (amt >=   100_000 ether) return "Silver";
        if (amt >=    20_000 ether) return "Bronze";
        return "None";
    }
}
