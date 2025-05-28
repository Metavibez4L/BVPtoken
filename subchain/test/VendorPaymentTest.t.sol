// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/VendorPayment.sol";

contract VendorPaymentTest is Test {
    VendorPayment public vendorPayment;
    MockERC20 public token;
    MockLineItemRegistry public registry;

    address deployer = address(0x1);
    address producer = address(0x2);
    address treasury = address(0x3);
    address vendor1 = address(0x10);

    function setUp() public {
        token = new MockERC20();
        registry = new MockLineItemRegistry();
        token.mint(address(this), 1_000_000e18);

        vendorPayment = new VendorPayment(address(token), address(registry));
        vendorPayment.grantRole(vendorPayment.ROLE_ADMIN(), address(this));
        vendorPayment.grantRole(vendorPayment.ROLE_PRODUCER(), address(this));
        vendorPayment.grantRole(vendorPayment.ROLE_TREASURY(), address(this));

        token.approve(address(vendorPayment), type(uint256).max);
        token.mint(address(vendorPayment), 500_000e18);

        vendorPayment.registerVendor(vendor1, "Gaffer", 10_000e18);
    }

    function testQueueAndExecutePayment() public {
        bytes32 projectId = keccak256("TestFilm");
        uint256 accountCode = 401;

        vendorPayment.queuePayment(projectId, accountCode, vendor1, 5_000e18);

        // Correctly destructure all returned values
        (
            bytes32 _pid,
            uint256 _acc,
            address recipient,
            uint256 _amt,
            bool _exec
        ) = vendorPayment.getPayment(0);

        assertEq(recipient, vendor1);

        vendorPayment.executePayment(0);

        assertEq(token.balanceOf(vendor1), 5_000e18);
        assertTrue(registry.wasCalled());
    }
}

// --------------------------------------------
// Mock ERC20 for Testing
// --------------------------------------------
contract MockERC20 is IERC20Metadata {
    string public name = "Mock BVP";
    string public symbol = "MBVP";
    uint8 public override decimals = 18;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }

    function totalSupply() external pure returns (uint256) {
        return 1_000_000e18;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(allowances[sender][msg.sender] >= amount, "Not allowed");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
}

// --------------------------------------------
// Mock LineItemRegistry for Testing
// --------------------------------------------
contract MockLineItemRegistry is ILineItemRegistry {
    bool public called;

    function recordPayment(
        bytes32,
        uint256,
        address,
        uint256
    ) external override {
        called = true;
    }

    function wasCalled() external view returns (bool) {
        return called;
    }
}
