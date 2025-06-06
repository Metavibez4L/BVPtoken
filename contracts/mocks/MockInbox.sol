// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../bridge/IInbox.sol";

/// @notice Mock Arbitrum Inbox used for testing retryable tickets
contract MockInbox is IInbox {
    event RetryableTicketCreated(address to, bytes data);

    function createRetryableTicket(
        address to,
        uint256,
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external payable override returns (uint256) {
        emit RetryableTicketCreated(to, data);
        return 1;
    }

    /// @dev Testing-only manual withdrawal. Not used in production.
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
