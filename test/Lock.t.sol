// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Lock.sol";

contract LockTest is Test {
    Lock public lock;
    address public owner = address(0x123);
    uint256 public futureTime;

    function setUp() public {
        futureTime = block.timestamp + 365 days;
        vm.deal(owner, 10 ether);
        
        vm.prank(owner);
        lock = new Lock{value: 1 ether}(futureTime);
    }

    function test_ConstructorSetsCorrectly() public view {
        assertEq(lock.unlockTime(), futureTime, "unlock time should be set");
        assertEq(lock.owner(), owner, "owner should be set");
        assertEq(address(lock).balance, 1 ether, "contract should have 1 ether");
    }

    function test_CannotCreateLockInPast() public {
        vm.prank(owner);
        vm.expectRevert(Lock.UnlockTimeInPast.selector);
        new Lock{value: 1 ether}(block.timestamp - 1);
    }

    function test_CannotWithdrawBeforeUnlockTime() public {
        vm.prank(owner);
        vm.expectRevert(Lock.StillLocked.selector);
        lock.withdraw();
    }

    function test_CannotWithdrawIfNotOwner() public {
        vm.warp(futureTime + 1);
        
        vm.prank(address(0x456)); // different address
        vm.expectRevert(Lock.Unauthorized.selector);
        lock.withdraw();
    }

    function test_WithdrawSuccessAfterUnlock() public {
        vm.warp(futureTime + 1);
        
        uint256 balBefore = owner.balance;
        
        vm.prank(owner);
        lock.withdraw();
        
        uint256 balAfter = owner.balance;
        assertEq(balAfter - balBefore, 1 ether, "owner should receive the locked ether");
        assertEq(address(lock).balance, 0, "contract balance should be 0");
    }

    function test_WithdrawToContractRecipient() public {
        // Deploy a new lock where owner is a contract (this test contract)
        vm.deal(address(this), 10 ether);
        Lock contractOwnedLock = new Lock{value: 2 ether}(block.timestamp + 100 days);
        
        vm.warp(block.timestamp + 101 days);
        
        uint256 balBefore = address(this).balance;
        contractOwnedLock.withdraw();
        
        uint256 balAfter = address(this).balance;
        assertEq(balAfter - balBefore, 2 ether, "contract owner should receive the locked ether");
    }

    // Receive function to accept ETH from Lock withdrawal
    receive() external payable {}
}
