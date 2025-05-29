// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract VendorPayment {
    address public token;
    address public registry;

    mapping(bytes32 => mapping(uint256 => address)) public vendors;
    mapping(uint256 => bool) public paid;
    uint256 public paymentCount;
    mapping(uint256 => address) public paymentRecipients;
    mapping(uint256 => uint256) public paymentAmounts;

    mapping(bytes32 => mapping(address => bool)) public roles;

    constructor(address _token, address _registry) {
        token = _token;
        registry = _registry;
    }

    function grantRole(bytes32 role, address account) public {
        roles[role][account] = true;
    }

    function registerVendor(address /*vendor*/, string memory /*role*/, uint256 /*maxAmount*/) public {
        // No-op for mock
    }

    function queuePayment(bytes32 /*projectId*/, uint256 /*accountCode*/, address recipient, uint256 amount) public {
        paymentRecipients[paymentCount] = recipient;
        paymentAmounts[paymentCount] = amount;
        paid[paymentCount] = false;
        paymentCount++;
    }

    function executePayment(uint256 paymentIndex) public {
        require(!paid[paymentIndex], "Already paid");
        paid[paymentIndex] = true;
        (bool s, ) = token.call(abi.encodeWithSignature("transfer(address,uint256)", paymentRecipients[paymentIndex], paymentAmounts[paymentIndex]));
        require(s, "Transfer failed");
    }
}
