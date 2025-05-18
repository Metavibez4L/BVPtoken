// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface for Arbitrum’s L1 Gateway Router
interface IL1GatewayRouter {
    /// @notice Standard Arbitrum L1→L2 deposit call
    /// @param token  ERC20 token address on L1
    /// @param to     Recipient address on L2
    /// @param amount Amount to bridge
    /// @param data   Extra data forwarded to L2
    /// @return        ABI-encoded return data from L2 handler
    function outboundTransfer(
        address token,
        address to,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory);
}
