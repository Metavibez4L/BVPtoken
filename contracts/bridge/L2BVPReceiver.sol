// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBVPToken is IERC20 {
    function isExcludedFromLimits(address account) external view returns (bool);
    function MAX_WALLET() external view returns (uint256);
}

contract L2BVPReceiver {
    address public immutable bvp;
    address public immutable escrow;
    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    event BridgeFulfilled(address indexed recipient, uint256 amount);

    constructor(address _bvp, address _escrow) {
        bvp = _bvp;
        escrow = _escrow;
        owner = msg.sender;
    }

    function releaseBVP(address recipient, uint256 amount) external {
        IBVPToken token = IBVPToken(bvp);

        if (!token.isExcludedFromLimits(recipient)) {
            uint256 balance = token.balanceOf(recipient);
            require(balance + amount <= token.MAX_WALLET(), "WALLET_LIMIT: exceeds max");
        }

        require(token.transferFrom(escrow, recipient, amount), "Transfer failed");
        emit BridgeFulfilled(recipient, amount);
    }

    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        require(IERC20(bvp).transfer(to, amount), "Withdraw failed");
    }
}
