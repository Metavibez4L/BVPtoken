// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Matches the selector used by the L1 gateway’s `outboundTransfer`
interface IL1CustomGateway {
    function outboundTransfer(
        address token,
        address to,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory);
}
