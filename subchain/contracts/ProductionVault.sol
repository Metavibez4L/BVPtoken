// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title ProductionVault
/// @notice Manages on-chain funding for film productions using milestone-based disbursement logic.
contract ProductionVault is AccessControl {
    /// Role that can create and cancel projects
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    /// The token used for funding (BVP Token)
    IERC20Metadata public immutable bvpToken;

    /// @dev Represents a funded production with milestone-based disbursement logic
    struct Project {
        string title;                         // Title of the production
        uint256 totalBudget;                 // Total BVP allocated
        uint256 released;                    // Amount already disbursed
        address producer;                    // Project recipient wallet
        address[] approvers;                 // List of multisig approvers
        mapping(address => bool) hasApproved;// Tracks approvals per milestone
        uint256 approvals;                   // Counter for milestone approvals
        uint256[] milestones;                // Milestone amounts in order
        uint256 currentMilestone;            // Current milestone index
        bool isActive;                       // Project is live
        bool isCanceled;                     // Project has been canceled
    }

    /// Storage for all projects by ID
    mapping(bytes32 => Project) private projects;

    /// Guard against reusing IDs
    mapping(bytes32 => bool) private projectExists;

    // ---------------------
    // Events
    // ---------------------
    event ProjectCreated(bytes32 indexed projectId, string title, uint256 totalBudget);
    event MilestoneApproved(bytes32 indexed projectId, address indexed approver, uint256 approvals);
    event MilestoneReleased(bytes32 indexed projectId, uint256 milestoneIndex, uint256 amount);
    event ProjectCanceled(bytes32 indexed projectId);
    event RemainderWithdrawn(bytes32 indexed projectId, address recipient, uint256 amount);

    /// @param _bvpToken Address of the BVP token (must implement IERC20Metadata)
    constructor(address _bvpToken) {
        require(_bvpToken != address(0), "Invalid token address");
        bvpToken = IERC20Metadata(_bvpToken);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_ADMIN, msg.sender);
    }

    // ---------------------------------------------------------
    // CREATE & MANAGE PROJECTS
    // ---------------------------------------------------------

    /// @notice Creates a new production project with defined milestone logic
    /// @param id Unique hash ID for the project (e.g., keccak256)
    /// @param title Human-readable title
    /// @param totalBudget Total BVP to commit (must equal sum of milestones)
    /// @param milestones List of milestone disbursement amounts
    /// @param producer Wallet that will receive milestone disbursements
    /// @param approvers Multisig wallets required for milestone release (must be ≥ 2)
    function createProject(
        bytes32 id,
        string memory title,
        uint256 totalBudget,
        uint256[] memory milestones,
        address producer,
        address[] memory approvers
    ) external onlyRole(ROLE_ADMIN) {
        require(!projectExists[id], "Project already exists");
        require(milestones.length > 0, "Must have at least 1 milestone");
        require(approvers.length >= 2, "Require ≥ 2 approvers");
        require(producer != address(0), "Invalid producer");

        uint256 sum;
        for (uint i = 0; i < milestones.length; i++) {
            sum += milestones[i];
        }
        require(sum == totalBudget, "Milestone total ≠ budget");

        Project storage p = projects[id];
        p.title = title;
        p.totalBudget = totalBudget;
        p.producer = producer;
        p.approvers = approvers;
        p.milestones = milestones;
        p.isActive = true;

        projectExists[id] = true;

        require(bvpToken.transferFrom(msg.sender, address(this), totalBudget), "Funding failed");

        emit ProjectCreated(id, title, totalBudget);
    }

    /// @notice Approves the current milestone for a project
    ///         Requires 2 unique approvals to release funds.
    function approveMilestone(bytes32 id) external {
        Project storage p = projects[id];
        require(p.isActive && !p.isCanceled, "Inactive or canceled");
        require(p.currentMilestone < p.milestones.length, "All milestones complete");
        require(isApprover(id, msg.sender), "Not approver");
        require(!p.hasApproved[msg.sender], "Already approved");

        p.hasApproved[msg.sender] = true;
        p.approvals++;

        emit MilestoneApproved(id, msg.sender, p.approvals);

        if (p.approvals >= 2) {
            _releaseMilestone(id);
        }
    }

    /// @dev Releases current milestone funds and resets approval state
    function _releaseMilestone(bytes32 id) internal {
        Project storage p = projects[id];

        uint256 amt = p.milestones[p.currentMilestone];
        p.released += amt;
        p.currentMilestone++;
        p.approvals = 0;

        for (uint i = 0; i < p.approvers.length; i++) {
            p.hasApproved[p.approvers[i]] = false;
        }

        require(bvpToken.transfer(p.producer, amt), "Transfer failed");

        emit MilestoneReleased(id, p.currentMilestone - 1, amt);
    }

    /// @notice Cancels a project and disables future milestone releases
    function cancelProject(bytes32 id) external onlyRole(ROLE_ADMIN) {
        Project storage p = projects[id];
        require(p.isActive && !p.isCanceled, "Already canceled");
        p.isCanceled = true;

        emit ProjectCanceled(id);
    }

    /// @notice Allows producer to withdraw remaining funds after cancellation
    function withdrawRemaining(bytes32 id) external {
        Project storage p = projects[id];
        require(p.isCanceled, "Project not canceled");
        require(msg.sender == p.producer, "Not producer");

        uint256 remaining = p.totalBudget - p.released;
        p.released = p.totalBudget;

        require(bvpToken.transfer(msg.sender, remaining), "Withdraw failed");

        emit RemainderWithdrawn(id, msg.sender, remaining);
    }

    // ---------------------------------------------------------
    // READ-ONLY VIEWS
    // ---------------------------------------------------------

    /// @notice Checks if a wallet is an authorized approver for a project
    function isApprover(bytes32 id, address user) public view returns (bool) {
        Project storage p = projects[id];
        for (uint i = 0; i < p.approvers.length; i++) {
            if (p.approvers[i] == user) return true;
        }
        return false;
    }

    /// @notice Returns project summary metadata
    function getProjectSummary(bytes32 id) external view returns (
        string memory title,
        uint256 totalBudget,
        uint256 released,
        uint256 currentMilestone,
        bool isActive,
        bool isCanceled,
        address producer
    ) {
        Project storage p = projects[id];
        return (
            p.title,
            p.totalBudget,
            p.released,
            p.currentMilestone,
            p.isActive,
            p.isCanceled,
            p.producer
        );
    }

    /// @notice Returns milestone array
    function getMilestones(bytes32 id) external view returns (uint256[] memory) {
        return projects[id].milestones;
    }

    /// @notice Returns multisig approver list
    function getApprovers(bytes32 id) external view returns (address[] memory) {
        return projects[id].approvers;
    }
}
