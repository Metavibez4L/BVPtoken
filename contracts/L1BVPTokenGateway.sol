// contracts/L1BVPTokenGateway.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IL1GatewayRouter.sol";

contract L1BVPTokenGateway {
    IERC20           public immutable bvpToken;
    IL1GatewayRouter public immutable gatewayRouter;

    constructor(address _bvpToken, address _gatewayRouter) {
        require(_bvpToken != address(0) && _gatewayRouter != address(0), "Invalid addr");
        bvpToken      = IERC20(_bvpToken);
        gatewayRouter = IL1GatewayRouter(_gatewayRouter);
    }

    function outboundTransfer(
        address token,
        address to,
        uint256 amount,
        bytes calldata data
    )
        external
        payable
        returns (bytes memory)
    {
        require(token == address(bvpToken), "L1: token not supported");
        bvpToken.transferFrom(msg.sender, address(this), amount);
        bvpToken.approve(address(gatewayRouter), amount);
        return gatewayRouter.outboundTransfer{ value: msg.value }(
            token, to, amount, data
        );
    }
}
