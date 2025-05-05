// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LibBytes} from "../../src/libraries/LibBytes.sol";

contract LibBytesTest is Test {
    using LibBytes for bytes;

    function setUp() public {}

    function test_equal() public pure {
        assertTrue(bytes("").equal(bytes("")));
        assertTrue(new bytes(0x00001).equal(new bytes(0x00001)));
        assertTrue(new bytes(0x000100).equal(new bytes(0x000100)));
        assertFalse(new bytes(0x10).equal(new bytes(0x1000)));
        assertFalse(new bytes(0x00001).equal(new bytes(0x00002)));
        assertFalse(new bytes(0x000100).equal(new bytes(0x000101)));
    }
}
