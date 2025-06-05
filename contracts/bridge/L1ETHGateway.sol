// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

contract L1ETHGateway {
    address public immutable inbox;
    address public immutable l2Target;

    constructor(address _inbox, address _l2Target) {
        inbox = _inbox;
        l2Target = _l2Target;
    }

    function bridgeETH(
        uint256 maxSubmissionCost,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) external payable {
        require(msg.value > 0, "No ETH sent");

        bytes memory message = abi.encodeWithSignature(
            "releaseBVP(address,uint256)",
            msg.sender,
            msg.value
        );

        IInbox(inbox).createRetryableTicket{ value: msg.value }(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            gasLimit,
            maxFeePerGas,
            message
        );
    }
}
