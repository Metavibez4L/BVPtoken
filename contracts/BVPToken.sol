// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BVPToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    uint256 public buyTax = 10;   // 10%
    uint256 public sellTax = 15;  // 15%

    address public treasury;
    mapping(address => bool) public isTaxExempt;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(address _treasury) ERC20("Big Vision Pictures Token", "BVP") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
        treasury = _treasury;
        isTaxExempt[msg.sender] = true;
    }

    function setTaxExempt(address account, bool exempt) external onlyOwner {
        isTaxExempt[account] = exempt;
    }

    function setAMMPair(address pair, bool isPair) external onlyOwner {
        automatedMarketMakerPairs[pair] = isPair;
    }

    function setBuyTax(uint256 newBuyTax) external onlyOwner {
        buyTax = newBuyTax;
    }

    function setSellTax(uint256 newSellTax) external onlyOwner {
        sellTax = newSellTax;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (isTaxExempt[from] || isTaxExempt[to] || treasury == address(0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 taxAmount = 0;
        if (automatedMarketMakerPairs[from]) {
            taxAmount = (amount * buyTax) / 100; // BUY
        } else if (automatedMarketMakerPairs[to]) {
            taxAmount = (amount * sellTax) / 100; // SELL
        }

        if (taxAmount > 0) {
            super._transfer(from, treasury, taxAmount);
            amount -= taxAmount;
        }

        super._transfer(from, to, amount);
    }
}
