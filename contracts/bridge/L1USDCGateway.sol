// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract L1USDCGateway {
    address public immutable usdc;
    address public immutable inbox;
    address public immutable l2Target;

    constructor(address _usdc, address _inbox, address _l2Target) {
        usdc = _usdc;
        inbox = _inbox;
        l2Target = _l2Target;
    }

    function bridgeToBVP(
        uint256 amount,
        uint256 maxSubmissionCost,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) external payable {
        require(amount > 0, "Amount must be > 0");
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);

        bytes memory message = abi.encodeWithSignature(
            "releaseBVP(address,uint256)",
            msg.sender,
            amount
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
