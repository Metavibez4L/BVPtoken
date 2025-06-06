// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IBVPToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract L2BVPReceiver {
    IBVPToken public immutable token;
    address public immutable escrow;

    event BridgeFulfilled(address indexed recipient, uint256 amount);

    constructor(address _bvp, address _escrow) {
        require(_bvp != address(0), "BVP: zero address");
        require(_escrow != address(0), "Escrow: zero address");
        token = IBVPToken(_bvp);
        escrow = _escrow;
    }

    function releaseBVP(address recipient, uint256 amount) external {
        require(token.transferFrom(escrow, recipient, amount), "Transfer failed");
        emit BridgeFulfilled(recipient, amount);
    }
}
