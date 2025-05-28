// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @notice Minimal interface to interact with LineItemRegistry
interface ILineItemRegistry {
    function recordPayment(
        bytes32 projectId,
        uint256 accountCode,
        address vendor,
        uint256 amount
    ) external;
}

/// @title VendorPayment
/// @notice Handles registration and payments to vendors/cast/crew within budget limits.
contract VendorPayment is AccessControl {
    /// Role allowed to register vendors
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    /// Role allowed to queue payments (e.g., producers or department heads)
    bytes32 public constant ROLE_PRODUCER = keccak256("ROLE_PRODUCER");
    /// Role allowed to execute payments (e.g., finance or treasury signer)
    bytes32 public constant ROLE_TREASURY = keccak256("ROLE_TREASURY");

    /// ERC-20 token used to pay vendors
    IERC20Metadata public immutable bvpToken;

    /// Optional registry to record payments against budget lines
    ILineItemRegistry public immutable lineItemRegistry;

    /// Stores vendor registration info
    struct Vendor {
        address wallet;
        string role;         // e.g. "Gaffer", "Composer", "Hair Stylist"
        uint256 approvedRate;// Max allowed per payment
        bool active;
    }

    /// Individual payment request linked to a project + line item
    struct PaymentRequest {
        bytes32 projectId;
        uint256 accountCode;
        address recipient;
        uint256 amount;
        bool executed;
    }

    /// Registered vendors by wallet address
    mapping(address => Vendor) public vendors;

    /// All queued payments (index-based lookup)
    PaymentRequest[] public payments;

    // ---------------------
    // Events
    // ---------------------
    event VendorRegistered(address indexed wallet, string role, uint256 rate);
    event PaymentQueued(uint256 indexed id, bytes32 projectId, address recipient, uint256 amount);
    event PaymentExecuted(uint256 indexed id, address indexed recipient, uint256 amount);

    /// @notice Initializes the vendor payment contract
    /// @param _bvpToken Address of the BVP token
    /// @param _lineItemRegistry Address of the LineItemRegistry contract
    constructor(address _bvpToken, address _lineItemRegistry) {
        require(_bvpToken != address(0), "Invalid token");
        require(_lineItemRegistry != address(0), "Invalid registry");

        bvpToken = IERC20Metadata(_bvpToken);
        lineItemRegistry = ILineItemRegistry(_lineItemRegistry);

        // Default role setup
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_ADMIN, msg.sender);
        _grantRole(ROLE_TREASURY, msg.sender);
    }

    // ---------------------
    // VENDOR MANAGEMENT
    // ---------------------

    /// @notice Registers a new vendor with a spending cap and role label
    function registerVendor(address wallet, string memory role, uint256 rate) external onlyRole(ROLE_ADMIN) {
        require(wallet != address(0), "Invalid address");
        require(rate > 0, "Rate must be > 0");

        vendors[wallet] = Vendor({
            wallet: wallet,
            role: role,
            approvedRate: rate,
            active: true
        });

        emit VendorRegistered(wallet, role, rate);
    }

    // ---------------------
    // PAYMENT FLOW
    // ---------------------

    /// @notice Queue a vendor payment for a specific project/line item
    /// @param projectId Project ID the payment is tied to
    /// @param accountCode Budget line item (e.g., 401 Principal Cast)
    /// @param vendor Vendor to pay
    /// @param amount Amount of BVP to pay (must not exceed vendor's approved rate)
    function queuePayment(
        bytes32 projectId,
        uint256 accountCode,
        address vendor,
        uint256 amount
    ) external onlyRole(ROLE_PRODUCER) {
        Vendor memory v = vendors[vendor];
        require(v.active, "Vendor not registered");
        require(amount <= v.approvedRate, "Exceeds vendor rate");

        payments.push(PaymentRequest({
            projectId: projectId,
            accountCode: accountCode,
            recipient: vendor,
            amount: amount,
            executed: false
        }));

        emit PaymentQueued(payments.length - 1, projectId, vendor, amount);
    }

    /// @notice Executes a previously queued payment by ID
    /// @dev Also updates the LineItemRegistry
    /// @param paymentId Index of the queued payment
    function executePayment(uint256 paymentId) external onlyRole(ROLE_TREASURY) {
        require(paymentId < payments.length, "Invalid ID");
        PaymentRequest storage pr = payments[paymentId];
        require(!pr.executed, "Already paid");

        pr.executed = true;

        // Update budget tracking first (reverts if over budget)
        lineItemRegistry.recordPayment(
            pr.projectId,
            pr.accountCode,
            pr.recipient,
            pr.amount
        );

        // Transfer funds to vendor
        require(bvpToken.transfer(pr.recipient, pr.amount), "Token transfer failed");

        emit PaymentExecuted(paymentId, pr.recipient, pr.amount);
    }

    // ---------------------
    // VIEWS
    // ---------------------

    /// @notice Returns number of queued payments
    function getPaymentCount() external view returns (uint256) {
        return payments.length;
    }

    /// @notice Returns payment details for a specific ID
    function getPayment(uint256 id) external view returns (
        bytes32 projectId,
        uint256 accountCode,
        address recipient,
        uint256 amount,
        bool executed
    ) {
        PaymentRequest storage pr = payments[id];
        return (
            pr.projectId,
            pr.accountCode,
            pr.recipient,
            pr.amount,
            pr.executed
        );
    }
}
