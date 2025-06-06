// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title L2BVPReceiver
/// @notice L2 receiver that unlocks BVP tokens from escrow to recipients
contract L2BVPReceiver {
    address public immutable escrow;
    IERC20 public immutable token;

    address public immutable authorizedCaller;

    event BridgeFulfilled(address recipient, uint256 amount);

    constructor(address _bvp, address _escrow) {
        require(_bvp != address(0), "Invalid BVP address");
        require(_escrow != address(0), "Invalid escrow address");

        token = IERC20(_bvp);
        escrow = _escrow;
        authorizedCaller = msg.sender; // Arbitrum bridge or gateway
    }

    /// @notice Only allow the original authorized L1 bridge caller
    modifier onlyBridge() {
        require(msg.sender == authorizedCaller, "Unauthorized caller");
        _;
    }

    function releaseBVP(address recipient, uint256 amount) external onlyBridge {
        emit BridgeFulfilled(recipient, amount);
        require(token.transferFrom(escrow, recipient, amount), "Transfer failed");
    }
}
