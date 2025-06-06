// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IInbox {
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);
}

/// @title L1ETHGateway
/// @notice Bridges ETH to BVP via retryable ticket
contract L1ETHGateway {
    address public immutable inbox;
    address public immutable l2Target;

    constructor(address _inbox, address _l2Target) {
        require(_inbox != address(0), "Inbox is zero");
        require(_l2Target != address(0), "L2 is zero");
        inbox = _inbox;
        l2Target = _l2Target;
    }

    function bridgeETH(
        uint256 maxSubmissionCost,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) external payable {
        bytes memory message = abi.encodeWithSignature("releaseBVP(address,uint256)", msg.sender, msg.value);
        uint256 ticketID = IInbox(inbox).createRetryableTicket{ value: msg.value }(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            gasLimit,
            maxFeePerGas,
            message
        );
        require(ticketID != 0, "Retryable ticket failed");
    }
}
