// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Time-Locked ETH Contract
/// @notice Simple timelock mechanism that holds ETH until a specified unlock time
/// @dev Immutable owner and unlock time set at deployment
///
/// @custom:security-contact security@bigvisionpictures.io
/// @custom:security-features
///      - Immutable owner and unlockTime (set once in constructor)
///      - Uses .call{value} instead of .transfer for better recipient compatibility
///      - Access control: only owner can withdraw
/// @custom:invariants
///      - unlockTime > deployment timestamp (enforced in constructor)
///      - Only owner address can successfully call withdraw()
///      - Withdrawal only possible when block.timestamp >= unlockTime
/// @custom:assumptions
///      - Owner address should be EOA or contract with payable receive/fallback
///      - No emergency unlock mechanism (by design - true timelock)
///      - block.timestamp is reliable for time-based conditions
/// @custom:warnings
///      - If unlockTime is set far in future, funds are locked indefinitely
///      - No upgrade path or admin override
///      - Test with short periods before locking large amounts
contract Lock is ReentrancyGuard {
    // ---- Custom Errors ----
    error UnlockTimeInPast();
    error StillLocked();
    error Unauthorized();

    /// @notice Timestamp after which the funds can be withdrawn
    /// @dev Marked as immutable to save gas (set once during construction)
    uint public immutable unlockTime;

    /// @notice Owner of the contract, authorized to withdraw after unlock
    /// @dev Marked as immutable for gas efficiency
    address payable public immutable owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        if (block.timestamp >= _unlockTime) revert UnlockTimeInPast();

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public nonReentrant {
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        if (block.timestamp < unlockTime) revert StillLocked();
        if (msg.sender != owner) revert Unauthorized();

        uint256 amount = address(this).balance;
        emit Withdrawal(amount, block.timestamp);

        // Use sendValue (uses .call under the hood) for better compatibility with contract recipients
        Address.sendValue(owner, amount);
    }
}
