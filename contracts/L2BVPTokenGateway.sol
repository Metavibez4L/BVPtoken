// contracts/L2BVPTokenGateway.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IL1CustomGateway.sol";

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface ArbSys {
    function sendTxToL1(address dest, bytes calldata data) external payable returns (uint256);
}

contract L2BVPTokenGateway {
    IERC20Mintable public immutable bvpToken;
    address        public immutable l1Gateway;
    ArbSys         private constant arbsys = ArbSys(address(100));

    constructor(address _bvpToken, address _l1Gateway) {
        require(_bvpToken != address(0) && _l1Gateway != address(0), "Invalid addr");
        bvpToken  = IERC20Mintable(_bvpToken);
        l1Gateway = _l1Gateway;
    }

    function inboundTransfer(
        address, address to, uint256 amount, bytes calldata
    )
        external payable returns (bytes memory)
    {
        require(msg.sender == l1Gateway, "L2: only L1 gateway");
        bvpToken.mint(to, amount);
        return abi.encode(to, amount);
    }

    function outboundTransfer(
        address token, address to, uint256 amount, bytes calldata data
    )
        external payable returns (bytes memory)
    {
        require(token == address(bvpToken), "L2: token not supported");
        bvpToken.burn(msg.sender, amount);
        bytes memory payload = abi.encodeWithSelector(
            IL1CustomGateway.outboundTransfer.selector,
            token, to, amount, data
        );
        arbsys.sendTxToL1{ value: msg.value }(l1Gateway, payload);
        return payload;
    }
}
