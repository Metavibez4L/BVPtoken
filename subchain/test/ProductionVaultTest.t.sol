// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { AccessControl } from "openzeppelin-contracts/access/AccessControl.sol";
import { IERC20Metadata } from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";


/// @title ProductionVault
/// @notice Manages on-chain funding for film productions using milestone-based disbursement logic.
contract ProductionVault is AccessControl {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    IERC20Metadata public immutable bvpToken;

    struct Project {
        string title;
        uint256 totalBudget;
        uint256 released;
        address producer;
        address[] approvers;
        mapping(address => bool) hasApproved;
        uint256 approvals;
        uint256[] milestones;
        uint256 currentMilestone;
        bool isActive;
        bool isCanceled;
    }

    mapping(bytes32 => Project) private projects;
    mapping(bytes32 => bool) private projectExists;

    event ProjectCreated(bytes32 indexed projectId, string title, uint256 totalBudget);
    event MilestoneApproved(bytes32 indexed projectId, address indexed approver, uint256 approvals);
    event MilestoneReleased(bytes32 indexed projectId, uint256 milestoneIndex, uint256 amount);
    event ProjectCanceled(bytes32 indexed projectId);
    event RemainderWithdrawn(bytes32 indexed projectId, address recipient, uint256 amount);

    constructor(address _bvpToken) {
        require(_bvpToken != address(0), "Invalid token address");
        bvpToken = IERC20Metadata(_bvpToken);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_ADMIN, msg.sender);
    }

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
        require(approvers.length >= 2, "Require >= 2 approvers");
        require(producer != address(0), "Invalid producer");

        uint256 sum;
        for (uint i = 0; i < milestones.length; i++) {
            sum += milestones[i];
        }
        require(sum == totalBudget, "Milestone total != budget");

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

    function cancelProject(bytes32 id) external onlyRole(ROLE_ADMIN) {
        Project storage p = projects[id];
        require(p.isActive && !p.isCanceled, "Already canceled");
        p.isCanceled = true;

        emit ProjectCanceled(id);
    }

    function withdrawRemaining(bytes32 id) external {
        Project storage p = projects[id];
        require(p.isCanceled, "Project not canceled");
        require(msg.sender == p.producer, "Not producer");

        uint256 remaining = p.totalBudget - p.released;
        p.released = p.totalBudget;

        require(bvpToken.transfer(msg.sender, remaining), "Withdraw failed");

        emit RemainderWithdrawn(id, msg.sender, remaining);
    }

    function isApprover(bytes32 id, address user) public view returns (bool) {
        Project storage p = projects[id];
        for (uint i = 0; i < p.approvers.length; i++) {
            if (p.approvers[i] == user) return true;
        }
        return false;
    }

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

    function getMilestones(bytes32 id) external view returns (uint256[] memory) {
        return projects[id].milestones;
    }

    function getApprovers(bytes32 id) external view returns (address[] memory) {
        return projects[id].approvers;
    }
}
