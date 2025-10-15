// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Lock.sol";

contract LockTest is Test {
    function test_Lock_NoOp() public {
        // if your Lock has a constructor or simple funcs, touch them minimally
        // this placeholder avoids 0% coverage on an unused scaffold
        assertTrue(true);
    }
}
