// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BVPToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    constructor(address treasury) 
        ERC20("Big Vision Pictures Token", "BVP") 
        Ownable(msg.sender) 
    {
        _mint(msg.sender, MAX_SUPPLY);
    }

    // — override removed entirely —
}
