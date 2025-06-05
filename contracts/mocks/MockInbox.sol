// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MockInbox
/// @notice Mocks Arbitrum's Inbox contract for local testing
contract MockInbox {
    event RetryableTicketCreated(address to, bytes data);

    function createRetryableTicket(
        address to,
        uint256, uint256,
        address, address,
        uint256, uint256,
        bytes calldata data
    ) external payable returns (uint256) {
        emit RetryableTicketCreated(to, data);
        return 1;
    }
}
