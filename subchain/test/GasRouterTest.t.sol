// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import { GasRouter } from "../contracts/GasRouter.sol";
import { IERC20Metadata } from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MockERC20 is IERC20Metadata {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function totalSupply() external pure override returns (uint256) {
        return 1_000_000 ether;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }
}

contract GasRouterTest is Test {
    GasRouter router;
    MockERC20 bvp;
    address treasury = address(0xFEED);

    function setUp() public {
        bvp = new MockERC20();
        uint256 gasUnitPrice = 1e16; // 0.01 BVP per gas unit
        router = new GasRouter(address(bvp), treasury, gasUnitPrice);

        bvp.mint(address(this), 1000 ether);
        bvp.approve(address(router), type(uint256).max);
    }

    function testPrepayGas() public {
        router.prepayGas(address(this), 100);
        assertEq(bvp.balanceOf(treasury), 1 ether); // 100 * 0.01 BVP
    }

    function testUpdateTreasury() public {
        address newTreasury = address(0xDEAD);
        router.setTreasury(newTreasury);
        assertEq(router.treasury(), newTreasury);
    }

    function testUpdateGasPrice() public {
        router.setGasPrice(2e16); // 0.02 BVP
        assertEq(router.gasUnitPrice(), 2e16);
    }
}
