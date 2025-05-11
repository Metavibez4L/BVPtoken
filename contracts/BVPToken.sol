// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BVPToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    constructor() ERC20("Big Vision Pictures Token", "BVP") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
}
